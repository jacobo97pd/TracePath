import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'app_data.dart';
import 'achievements_service.dart';
import 'celebration_overlay.dart';
import 'coins_service.dart';
import 'engine/level.dart';
import 'game_board.dart';
import 'game_theme.dart';
import 'leaderboard_service.dart';
import 'models/leaderboard_entry.dart';
import 'puzzle_attempt.dart';
import 'progress_service.dart';
import 'score_calculator.dart';
import 'stats_service.dart';
import 'victory_screen.dart';
import 'pack_level_repository.dart';
import 'services/leaderboard_service.dart' as social_lb;
import 'services/streak_service.dart';
import 'trail/trail_catalog.dart';
import 'trail/trail_skin.dart';
import 'services/wallet_history_service.dart';
import 'ui/avatar_utils.dart';
import 'ui/components/game_toast.dart';
import 'services/rewarded_ad_service.dart';
import 'ui/components/rewarded_ad_offer_dialog.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.packId,
    required this.levelIndex,
    required this.progressService,
    required this.statsService,
    required this.achievementsService,
    required this.leaderboardService,
    required this.coinsService,
  });

  final String packId;
  final int levelIndex;
  final ProgressService progressService;
  final StatsService statsService;
  final AchievementsService achievementsService;
  final LeaderboardService leaderboardService;
  final CoinsService coinsService;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxHintsPerLevel = 3;
  static const bool _unlimitedHintsForTesting = true;
  static const String _firestoreDatabaseId = 'tracepath-database';

  final GameBoardController _boardController = GameBoardController();
  final social_lb.SocialLeaderboardService _socialLeaderboardService =
      social_lb.SocialLeaderboardService();
  final StreakService _streakService = StreakService();
  final WalletHistoryService _walletHistoryService = WalletHistoryService();
  final RewardedAdService _rewardedAdService = RewardedAdService.instance;
  final Map<String, String?> _rankingSkinPreviewUrlCache = <String, String?>{};
  late final AnimationController _pathColorController;
  Level? _level;
  int? _themeSeed;
  GameBoardStatus _status = const GameBoardStatus(
    path: [],
    nextRequiredNumber: 1,
    lastSequentialNumber: 0,
    maxNumber: 0,
    solved: false,
  );
  bool _isLevelLoading = true;
  Object? _levelLoadError;
  int _levelLoadGeneration = 0;
  int _levelRetryNonce = 0;
  Color? _pathColorFrom;
  Color? _pathColorTo;
  bool _completionHandled = false;
  bool _showCelebration = false;
  HintDirection _hintDirection = HintDirection.none;
  bool _hintVisible = false;
  int _hintsUsed = 0;
  int _rewindsUsed = 0;
  int _mistakesUsed = 0;
  DateTime? _runStartedAt;
  Duration? _elapsedAtSolve;
  Timer? _hintTimer;
  Timer? _clockTimer;
  Timer? _coinRewardTimer;
  bool _coinRewardVisible = false;
  int _coinRewardAmount = 0;
  Offset _coinRewardOffset = const Offset(-1.2, 0);

  @override
  void initState() {
    super.initState();
    _pathColorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..value = 1;
    _loadLevelAsync(
      brightnessOverride:
          WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packId != widget.packId ||
        oldWidget.levelIndex != widget.levelIndex) {
      _loadLevelAsync();
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _clockTimer?.cancel();
    _coinRewardTimer?.cancel();
    _pathColorController.dispose();
    _boardController.dispose();
    super.dispose();
  }

  Future<void> _loadLevelAsync({Brightness? brightnessOverride}) async {
    final generation = ++_levelLoadGeneration;
    final brightness = brightnessOverride ?? Theme.of(context).brightness;
    final previousColor = _currentPathColor(brightness);
    setState(() {
      _isLevelLoading = true;
      _levelLoadError = null;
    });

    try {
      final level = await loadCampaignLevelAsync(
        widget.packId,
        widget.levelIndex,
        retryNonce: _levelRetryNonce,
      ).timeout(const Duration(seconds: 12));
      if (!mounted || generation != _levelLoadGeneration) {
        return;
      }
      _level = level;
      _themeSeed = ThemeGenerator.seedFromLevelId(level.id);
      _status = GameBoardStatus.fromPath(level, const []);
      _completionHandled = false;
      _hintsUsed = 0;
      _rewindsUsed = 0;
      _runStartedAt = DateTime.now();
      _elapsedAtSolve = null;

      final nextColor = ThemeGenerator.generateTheme(
        seed: _themeSeed!,
        brightness: brightness,
      ).pathColor;

      if (previousColor == null) {
        _pathColorFrom = nextColor;
        _pathColorTo = nextColor;
        _pathColorController.value = 1;
      } else {
        _pathColorFrom = previousColor;
        _pathColorTo = nextColor;
        _pathColorController
          ..value = 0
          ..forward();
      }

      _clockTimer?.cancel();
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
      });
      _clearHint();
      setState(() {
        _isLevelLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _levelLoadGeneration) {
        return;
      }
      setState(() {
        _isLevelLoading = false;
        _levelLoadError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportsPack = getPackById(widget.packId) != null ||
        PackLevelRepository.instance.isPrecomputedPack(widget.packId);
    if (!supportsPack) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Pack not found')),
      );
    }
    if (_isLevelLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading level')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_levelLoadError != null || _level == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Level unavailable')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load this level.'),
                if (kDebugMode && _levelLoadError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _levelLoadError.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _levelRetryNonce++;
                    });
                    _loadLevelAsync();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final level = _level!;

    final brightness = Theme.of(context).brightness;
    final gameTheme = ThemeGenerator.generateTheme(
      seed: _themeSeed!,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _GameplayAtmosphereBackground()),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GameplayHeader(
                    levelText: 'Level ${widget.levelIndex} / $_packLevelCount',
                    timerText: _elapsedText,
                    onBack: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    walletCoins: widget.coinsService.coins,
                    onRankingTap: _openFriendsRankingSheet,
                    onWalletTap: () => context.go('/shop'),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: _GlassBoardShell(
                          isDark: isDark,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: AnimatedBuilder(
                                animation: _pathColorController,
                                builder: (context, child) {
                                  final pathColor =
                                      _currentPathColor(brightness) ??
                                          gameTheme.pathColor;
                                  return GameBoard(
                                    controller: _boardController,
                                    level: level,
                                    gameTheme: gameTheme,
                                    pathColorOverride: pathColor,
                                    trailSkin: _activeTrailSkin,
                                    pointerAssetPath:
                                        widget.coinsService.selectedSkinAssetPath,
                                    hintDirection: _hintDirection,
                                    hintVisible: _hintVisible,
                                    onStatusChanged: _handleStatusChanged,
                                    onChange: _handleBoardChange,
                                    onInvalidMove: (_) {
                                      setState(() {
                                        _mistakesUsed++;
                                      });
                                      _clearHint();
                                      HapticFeedback.mediumImpact();
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _GameActionButton(
                          label: 'Undo',
                          onTap: _handleUndo,
                          backgroundColor: isDark
                              ? const Color(0xFF2B2B2F)
                              : const Color(0xFFEDEDED),
                          foregroundColor: isDark
                              ? const Color(0xFFE8E8EB)
                              : const Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GameActionButton(
                          label: 'Restart',
                          onTap: _handleReset,
                          outlined: true,
                          borderColor: const Color(0xFF6B6E76),
                          foregroundColor: isDark
                              ? const Color(0xFFE8E8EB)
                              : const Color(0xFF222222),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GameActionButton(
                          label:
                              _unlimitedHintsForTesting ? 'Hint (INF)' : 'Hint ($_hintsLeft)',
                          onTap: _handleHint,
                          outlined: true,
                          visuallyEnabled:
                              _unlimitedHintsForTesting || _hintsLeft > 0,
                          borderColor: gameTheme.pathColor,
                          foregroundColor: gameTheme.pathColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: CelebrationOverlay(
                visible: _showCelebration,
                duration: const Duration(milliseconds: 1150),
                accentColor: gameTheme.pathColor,
                isDark: isDark,
                loop: true,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.center,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: _coinRewardVisible ? 1 : 0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        offset: _coinRewardOffset,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF14532D).withOpacity(0.96),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF4ADE80)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22C55E).withOpacity(0.28),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFFD1FAE5),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'LEVEL COMPLETE! ${_coinRewardAmount >= 0 ? '+' : ''}$_coinRewardAmount',
                                style: const TextStyle(
                                  color: Color(0xFFEFFEF5),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFriendsRankingSheet() async {
    final levelId = '${widget.packId}_${widget.levelIndex}';
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.74,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              border: Border.fromBorderSide(
                BorderSide(color: Color(0xFF334155), width: 1),
              ),
            ),
            child: FutureBuilder<List<_InLevelRankRowData>>(
              future: _loadFriendsRankingRows(levelId),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const _InLevelRankingEmpty(
                    title: 'Ranking unavailable',
                    subtitle: 'Try again in a moment.',
                  );
                }
                final rows = snapshot.data ?? const <_InLevelRankRowData>[];
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B4D73),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFFFFD166),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Friends Ranking',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            'Level ${widget.levelIndex}',
                            style: const TextStyle(
                              color: Color(0xFF9FB0D3),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF29374F)),
                    Expanded(
                      child: rows.isEmpty
                          ? const _InLevelRankingEmpty(
                              title: 'No friends have played this level yet.',
                              subtitle:
                                  'Complete the level and invite friends to compete.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                              itemCount: rows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final row = rows[index];
                                return _InLevelRankRow(
                                  rank: index + 1,
                                  data: row,
                                  highlighted: row.entry.uid == currentUid,
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<List<_InLevelRankRowData>> _loadFriendsRankingRows(String levelId) async {
    final entries = await _socialLeaderboardService.getFriendsTopScores(levelId);
    final rows = <_InLevelRankRowData>[];
    for (final entry in entries) {
      final skinPreview = await _resolveRankingSkinPreviewUrl(entry.equippedSkinId);
      rows.add(
        _InLevelRankRowData(
          entry: entry,
          photoUrl: _resolveEntryPhotoUrl(entry),
          skinPreviewUrl: (skinPreview ?? '').trim(),
          preferSkin: !isDefaultSkinId(entry.equippedSkinId),
        ),
      );
    }
    rows.sort((a, b) {
      final byTime = a.entry.bestTimeMs.compareTo(b.entry.bestTimeMs);
      if (byTime != 0) return byTime;
      final aMoves = a.entry.moves <= 0 ? 1 << 30 : a.entry.moves;
      final bMoves = b.entry.moves <= 0 ? 1 << 30 : b.entry.moves;
      final byMoves = aMoves.compareTo(bMoves);
      if (byMoves != 0) return byMoves;
      return a.entry.uid.compareTo(b.entry.uid);
    });
    return rows;
  }

  Future<String?> _resolveRankingSkinPreviewUrl(String skinId) async {
    final normalized = skinId.trim();
    if (normalized.isEmpty ||
        normalized == 'default' ||
        normalized == 'pointer_default') {
      return null;
    }
    if (_rankingSkinPreviewUrlCache.containsKey(normalized)) {
      return _rankingSkinPreviewUrlCache[normalized];
    }

    try {
      var snap = await _db().collection('skins_catalog').doc(normalized).get();
      Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
      if (!snap.exists || data.isEmpty) {
        final q = await _db()
            .collection('skins_catalog')
            .where('id', isEqualTo: normalized)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          data = q.docs.first.data();
        }
      }
      final imageRaw = data['image'];
      Map<String, dynamic>? imageMap;
      if (imageRaw is Map<String, dynamic>) {
        imageMap = imageRaw;
      } else if (imageRaw is Map) {
        imageMap = Map<String, dynamic>.from(imageRaw);
      }
      final rawPath = _readString(imageMap?['previewPath']) ??
          _readString(data['thumbPath']) ??
          _readString(data['thumbnailPath']) ??
          _readString(imageMap?['iconPath']) ??
          _readString(imageMap?['fullPath']) ??
          _readString(data['imagePath']);
      final resolved = await _resolveToDownloadUrl(rawPath);
      _rankingSkinPreviewUrlCache[normalized] = resolved;
      return resolved;
    } catch (_) {
      _rankingSkinPreviewUrlCache[normalized] = null;
      return null;
    }
  }

  String _resolveEntryPhotoUrl(LeaderboardEntry entry) {
    final current = _normalizeAvatarPath(entry.photoUrl);
    if (current.isNotEmpty) return current;
    if (entry.uid == FirebaseAuth.instance.currentUser?.uid) {
      final authUser = FirebaseAuth.instance.currentUser;
      final candidates = <String>[
        (authUser?.photoURL ?? '').trim(),
        if (authUser != null)
          ...authUser.providerData
              .map((p) => (p.photoURL ?? '').trim())
              .where((v) => v.isNotEmpty),
      ];
      for (final c in candidates) {
        final normalized = _normalizeAvatarPath(c);
        if (normalized.isNotEmpty) return normalized;
      }
    }
    return '';
  }

  String _normalizeAvatarPath(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:image') ||
        value.startsWith('assets/')) {
      return value;
    }
    if (value.startsWith('gs://')) {
      final withoutPrefix = value.replaceFirst('gs://', '');
      final slash = withoutPrefix.indexOf('/');
      if (slash <= 0 || slash >= withoutPrefix.length - 1) return '';
      final bucket = withoutPrefix.substring(0, slash);
      final objectPath = withoutPrefix.substring(slash + 1);
      return 'https://firebasestorage.googleapis.com/v0/b/'
          '$bucket/o/${Uri.encodeComponent(objectPath)}?alt=media';
    }
    return '';
  }

  Future<String?> _resolveToDownloadUrl(String? rawPath) async {
    final raw = (rawPath ?? '').trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('assets/') ||
        raw.startsWith('data:image')) {
      return raw;
    }
    if (raw.startsWith('gs://')) {
      try {
        return await FirebaseStorage.instance.refFromURL(raw).getDownloadURL();
      } catch (_) {
        return _toRenderableImageUrl(raw);
      }
    }
    final objectPath = raw.replaceAll('\\', '/');
    if (!objectPath.contains('/')) return null;
    try {
      return await FirebaseStorage.instance.ref(objectPath).getDownloadURL();
    } catch (_) {
      return _toRenderableImageUrl(objectPath);
    }
  }

  String? _toRenderableImageUrl(String rawPath) {
    final raw = rawPath.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('assets/') ||
        raw.startsWith('data:image')) {
      return raw;
    }
    if (raw.startsWith('gs://')) {
      final withoutPrefix = raw.replaceFirst('gs://', '');
      final slash = withoutPrefix.indexOf('/');
      if (slash <= 0 || slash >= withoutPrefix.length - 1) return null;
      final bucket = withoutPrefix.substring(0, slash);
      final objectPath = withoutPrefix.substring(slash + 1);
      return 'https://firebasestorage.googleapis.com/v0/b/'
          '$bucket/o/${Uri.encodeComponent(objectPath)}?alt=media';
    }
    final bucket = Firebase.app().options.storageBucket?.trim() ?? '';
    if (bucket.isEmpty) return null;
    final objectPath = raw.replaceAll('\\', '/');
    if (!objectPath.contains('/')) return null;
    return 'https://firebasestorage.googleapis.com/v0/b/'
        '$bucket/o/${Uri.encodeComponent(objectPath)}?alt=media';
  }

  FirebaseFirestore _db() {
    try {
      return FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: _firestoreDatabaseId,
      );
    } catch (_) {
      return FirebaseFirestore.instance;
    }
  }

  String? _readString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  Color? _currentPathColor(Brightness brightness) {
    final seed = _themeSeed;
    if (seed == null) {
      return _pathColorTo ?? _pathColorFrom;
    }
    final fallback = ThemeGenerator.generateTheme(
      seed: seed,
      brightness: brightness,
    ).pathColor;
    final begin = _pathColorFrom ?? fallback;
    final end = _pathColorTo ?? fallback;
    return Color.lerp(begin, end, _pathColorController.value);
  }

  void _handleReset() {
    HapticFeedback.selectionClick();
    setState(() {
      _hintsUsed = 0;
      _rewindsUsed = 0;
      _mistakesUsed = 0;
      _runStartedAt = DateTime.now();
      _elapsedAtSolve = null;
    });
    _clearHint();
    _boardController.reset();
  }

  void _handleUndo() {
    HapticFeedback.selectionClick();
    _clearHint();
    _boardController.undo();
  }

  void _handleHint() {
    final level = _level;
    if (level == null) {
      return;
    }
    if (!_unlimitedHintsForTesting && _hintsUsed >= _maxHintsPerLevel) {
      HapticFeedback.mediumImpact();
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.info,
          title: 'Hint',
          message: 'No hints left',
          duration: const Duration(milliseconds: 1400),
        ),
      );
      return;
    }

    final direction = computeHintDirection(level, _status.path);
    if (direction == HintDirection.none) {
      HapticFeedback.selectionClick();
      return;
    }

    HapticFeedback.selectionClick();
    setState(() {
      _hintsUsed++;
      _hintDirection = direction;
      _hintVisible = true;
    });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _hintVisible = false;
      });
    });
  }

  void _handleBoardChange(GameBoardChange change) {
    _clearHint();
    switch (change.type) {
      case GameBoardChangeType.add:
        HapticFeedback.selectionClick();
        break;
      case GameBoardChangeType.backtrack:
      case GameBoardChangeType.rewind:
      case GameBoardChangeType.undo:
        setState(() {
          _rewindsUsed++;
        });
        HapticFeedback.selectionClick();
        break;
      case GameBoardChangeType.reset:
        break;
    }
  }

  void _clearHint() {
    final hadHint = _hintVisible;
    _hintTimer?.cancel();
    _hintTimer = null;
    if (hadHint && mounted) {
      setState(() {
        _hintVisible = false;
      });
    }
  }

  void _showCoinDelta(int amount) {
    if (amount <= 0) {
      return;
    }
    _coinRewardTimer?.cancel();
    setState(() {
      _coinRewardAmount = amount;
      _coinRewardVisible = true;
      _coinRewardOffset = const Offset(-1.2, 0);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _coinRewardOffset = Offset.zero;
      });
    });
    _coinRewardTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _coinRewardOffset = const Offset(1.2, 0);
      });
      _coinRewardTimer = Timer(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        setState(() {
          _coinRewardVisible = false;
        });
      });
    });
  }

  void _handleStatusChanged(GameBoardStatus status) {
    final becameSolved = !_status.solved && status.solved;

    setState(() {
      _status = status;
      if (becameSolved) {
        _elapsedAtSolve = _currentElapsedDuration;
      }
      if (!status.solved) {
        _completionHandled = false;
        _elapsedAtSolve = null;
      }
    });

    if (becameSolved && !_completionHandled) {
      final level = _level;
      if (kEnableSolvedDebugLogs) {
        if (level == null) {
          return;
        }
        final debug = GameBoardRules.solvedDebugData(level, status.path);
        debugPrint(
          '[SolvedDebug][${widget.packId}:${widget.levelIndex}] '
          'totalCells=${debug['totalCells']} '
          'pathLength=${debug['pathLength']} '
          'noDuplicates=${debug['noDuplicates']} '
          'maxNumber=${debug['maxNumber']} '
          'lastSequentialNumber=${debug['lastSequentialNumber']} '
          'encountered=${debug['encounteredNumbers']}',
        );
      }
      _completionHandled = true;
      HapticFeedback.heavyImpact();
      _startCelebrationAndShowDialog();
    }
  }

  Future<void> _startCelebrationAndShowDialog() async {
    setState(() {
      _showCelebration = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1050));
    if (!mounted) {
      return;
    }
    await _showCompletionDialog();
  }

  Future<void> _showCompletionDialog() async {
    final level = _level;
    if (level == null) {
      return;
    }
    final levelId = '${widget.packId}_${widget.levelIndex}';
    await widget.progressService
        .markCompleted(widget.packId, widget.levelIndex);
    await widget.progressService.markDailyCompleted();
    final perfectCompletion = _mistakesUsed == 0;
    final levelReward = await widget.coinsService.rewardLevelCompletionOncePerLevel(
      levelId: levelId,
      perfectCompletion: perfectCompletion,
    );
    var rewardTotal = levelReward.coinsAwarded;
    var rewardedAdBonus = 0;
    if (mounted && !levelReward.firstCompletion) {
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.info,
          title: 'Level already completed',
          message: 'No coin reward on replay',
          duration: const Duration(milliseconds: 2000),
        ),
      );
    }
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid.trim().isNotEmpty) {
      try {
        final streak = await _streakService.registerCompletedLevel(
          uid: currentUid,
        );
        if (kDebugMode) {
          debugPrint(
            '[game] streak result uid=$currentUid current=${streak.currentStreak} '
            'best=${streak.bestStreak} increased=${streak.streakIncreased} '
            'reset=${streak.streakReset} alreadyToday=${streak.alreadyUpdatedToday} '
            'milestone=${streak.milestoneReached ?? 0} reward=${streak.rewardCoins ?? 0}',
          );
        }
        final streakReward = streak.rewardCoins ?? 0;
        if (streakReward > 0) {
          await widget.coinsService.addCoins(streakReward);
          rewardTotal += streakReward;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[game] streak update failed: $e');
        }
      }
    }
    if (mounted) {
      rewardedAdBonus = await _maybeGrantRewardedAdBonus();
      rewardTotal += rewardedAdBonus;
      _showCoinDelta(rewardTotal);
    }
    await widget.statsService.recordLevelCompleted(
      mode: SolveMode.campaign,
      difficulty: level.difficulty,
      solveTimeMs: _currentElapsedDuration.inMilliseconds,
      hintsUsed: _hintsUsed,
      rewindsUsed: _rewindsUsed,
    );
    await widget.coinsService.updateProfileProgress(
      highestLevelReached: widget.levelIndex,
      playTimeSecondsDelta: _currentElapsedDuration.inSeconds,
      gameWon: true,
      solveMs: _currentElapsedDuration.inMilliseconds,
    );
    final unlocked = await widget.achievementsService.evaluateAfterCompletion(
      mode: SolveMode.campaign,
      difficulty: level.difficulty,
      solveTimeMs: _currentElapsedDuration.inMilliseconds,
      hintsUsed: _hintsUsed,
      rewindsUsed: _rewindsUsed,
    );
    if (!mounted) {
      return;
    }
    if (unlocked.isNotEmpty) {
      final first = unlocked.first;
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.achievement,
          title: 'Achievement Unlocked',
          message: first.title,
          duration: const Duration(milliseconds: 2300),
        ),
      );
    }

    final breakdown = ScoreCalculator.calculate(
      ScoreInput(
        difficulty: level.difficulty,
        elapsedMs: _currentElapsedDuration.inMilliseconds,
        hintsUsed: _hintsUsed,
        rewindsUsed: _rewindsUsed,
      ),
    );
    await widget.progressService.setBestScoreIfHigher(
      widget.packId,
      widget.levelIndex,
      breakdown.finalScore,
    );
    await widget.leaderboardService.addPuzzleAttempt(
      PuzzleAttempt(
        runId: widget.leaderboardService.createRunId(),
        packId: widget.packId,
        levelIndex: widget.levelIndex,
        timeMs: _currentElapsedDuration.inMilliseconds,
        hintsUsed: _hintsUsed,
        rewindsUsed: _rewindsUsed,
        score: breakdown.finalScore,
        createdAtIso: DateTime.now().toIso8601String(),
        playerName: 'You',
      ),
    );
    final stars = _computeStars();
    try {
      await _socialLeaderboardService.submitLevelResult(
        levelId: levelId,
        bestTimeMs: _currentElapsedDuration.inMilliseconds,
        moves: _status.path.length,
        stars: stars,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[game] submitLevelResult failed for $levelId: $e');
      }
    }
    try {
      await _socialLeaderboardService.persistCompletedLevel(
        levelId: levelId,
        bestTimeMs: _currentElapsedDuration.inMilliseconds,
        moves: _status.path.length,
        stars: stars,
        highestLevelReached: widget.levelIndex,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[game] persistCompletedLevel failed for $levelId: $e');
      }
    }

    if (currentUid.trim().isNotEmpty && rewardTotal > 0) {
      try {
        await _walletHistoryService.addTransaction(
          uid: currentUid,
          type: 'reward',
          amount: rewardTotal,
          source: 'level_complete',
          referenceId: levelId,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[game] wallet history write failed for $levelId: $e');
        }
      }
    }
    if (!mounted) {
      return;
    }

    final brightness = Theme.of(context).brightness;
    final gameTheme = ThemeGenerator.generateTheme(
      seed: _themeSeed!,
      brightness: brightness,
    );
    final average = widget.statsService
        .averageTimeMsForDifficulty(level.difficulty)
        ?.round();
    final hasNext = widget.levelIndex < _packLevelCount;
    final action = await context.push<String>(
      '/victory',
      extra: VictoryScreenArgs(
        zipNumber: widget.levelIndex,
        headline: defaultVictoryHeadline(breakdown.finalScore),
        timeText: _elapsedText,
        averageText: _formatMs(average),
        streak: widget.progressService.getDailyStreak(),
        primaryLabel: hasNext ? 'Next Level' : 'Play Again',
        primaryActionId: hasNext ? 'next' : 'replay',
        accentColor: gameTheme.pathColor,
        coinsEarned: rewardTotal,
        adBonusCoins: rewardedAdBonus,
        levelId: levelId,
        shareText:
            'I solved Zip #${widget.levelIndex} in $_elapsedText. Score ${breakdown.finalScore}.',
        copyText:
            'Zip #${widget.levelIndex} - $_elapsedText - Streak ${widget.progressService.getDailyStreak()} 🔥',
      ),
    );

    if (!mounted) {
      return;
    }

    switch (action) {
      case 'next':
        setState(() {
          _showCelebration = false;
        });
        context.go('/play/${widget.packId}/${widget.levelIndex + 1}');
        break;
      case 'replay':
        _boardController.reset();
        setState(() {
          _completionHandled = false;
          _status = GameBoardStatus.fromPath(level, const []);
          _hintVisible = false;
          _hintsUsed = 0;
          _rewindsUsed = 0;
          _mistakesUsed = 0;
          _runStartedAt = DateTime.now();
          _elapsedAtSolve = null;
          _showCelebration = false;
        });
        break;
      default:
        setState(() {
          _showCelebration = false;
        });
        if (hasNext) {
          context.go('/play');
        }
        break;
    }
  }

  Future<int> _maybeGrantRewardedAdBonus() async {
    const bonusCoins = 15;
    final eligible = widget.levelIndex % 3 == 0;
    if (!eligible || !mounted) {
      return 0;
    }

    final offerAction = await RewardedAdOfferDialog.show(
      context,
      bonusCoins: bonusCoins,
    );
    if (!mounted || offerAction != RewardedAdOfferAction.watch) {
      return 0;
    }

    final outcome = await _rewardedAdService.showRewardedAd(context);
    if (!mounted) return 0;

    if (!outcome.available || !outcome.shown) {
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.info,
          title: 'Rewarded ad unavailable',
          message: 'Continuing without bonus.',
          duration: const Duration(milliseconds: 1800),
        ),
      );
      return 0;
    }
    if (!outcome.earned) {
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.info,
          title: 'Bonus not earned',
          message: 'Ad was not completed.',
          duration: const Duration(milliseconds: 1800),
        ),
      );
      return 0;
    }

    await widget.coinsService.addCoins(bonusCoins);
    if (!mounted) return bonusCoins;
    unawaited(
      GameToast.show(
        context,
        type: GameToastType.coins,
        title: 'Bonus reward',
        message: '+$bonusCoins coins',
        duration: const Duration(milliseconds: 2000),
      ),
    );
    return bonusCoins;
  }

  int get _hintsLeft {
    final left = _maxHintsPerLevel - _hintsUsed;
    return left < 0 ? 0 : left;
  }

  int get _packLevelCount {
    final precomputed = PackLevelRepository.instance.totalLevelsSync(widget.packId);
    if (precomputed > 0) {
      return precomputed;
    }
    return displayedLevelCount;
  }

  String get _elapsedText {
    final elapsed = _currentElapsedDuration;
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatMs(int? ms) {
    if (ms == null || ms <= 0) {
      return '--:--';
    }
    final seconds = (ms / 1000).round();
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Duration get _currentElapsedDuration {
    final solvedElapsed = _elapsedAtSolve;
    if (solvedElapsed != null) {
      return solvedElapsed;
    }
    final startedAt = _runStartedAt;
    if (startedAt == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(startedAt);
  }

  TrailSkinConfig get _activeTrailSkin {
    return TrailCatalog.resolveByTrailId(widget.coinsService.selectedTrail);
  }

  int _computeStars() {
    if (_hintsUsed == 0 && _rewindsUsed == 0 && _mistakesUsed == 0) {
      return 3;
    }
    if (_hintsUsed <= 1 && _rewindsUsed <= 1 && _mistakesUsed <= 1) {
      return 2;
    }
    return 1;
  }
}

class _InLevelRankRowData {
  const _InLevelRankRowData({
    required this.entry,
    required this.photoUrl,
    required this.skinPreviewUrl,
    required this.preferSkin,
  });

  final LeaderboardEntry entry;
  final String photoUrl;
  final String skinPreviewUrl;
  final bool preferSkin;
}

class _InLevelRankingEmpty extends StatelessWidget {
  const _InLevelRankingEmpty({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              color: Color(0xFF8FA6CF),
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9FB0D3),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InLevelRankRow extends StatelessWidget {
  const _InLevelRankRow({
    required this.rank,
    required this.data,
    required this.highlighted,
  });

  final int rank;
  final _InLevelRankRowData data;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final medalColor = rank == 1
        ? const Color(0xFFFFD166)
        : rank == 2
            ? const Color(0xFFD5E3FB)
            : rank == 3
                ? const Color(0xFFC7935F)
                : const Color(0xFF8FA6CF);
    final displayName = data.entry.username.trim().isNotEmpty
        ? data.entry.username.trim()
        : (data.entry.playerName.trim().isNotEmpty
            ? data.entry.playerName.trim()
            : 'Player');
    final timeText = _formatRankingMs(data.entry.bestTimeMs);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0x1A4A7CFF) : const Color(0xFF1A2538),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? const Color(0xFF5D8CFF) : const Color(0xFF32445F),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: medalColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _InLevelRankAvatar(
            photoUrl: data.photoUrl,
            skinUrl: data.skinPreviewUrl,
            preferSkin: data.preferSkin,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeText,
            style: const TextStyle(
              color: Color(0xFF9BB4FF),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRankingMs(int ms) {
    if (ms <= 0) return '--:--';
    final seconds = (ms / 1000).round();
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class _InLevelRankAvatar extends StatefulWidget {
  const _InLevelRankAvatar({
    required this.photoUrl,
    required this.skinUrl,
    required this.preferSkin,
  });

  final String photoUrl;
  final String skinUrl;
  final bool preferSkin;

  @override
  State<_InLevelRankAvatar> createState() => _InLevelRankAvatarState();
}

class _InLevelRankAvatarState extends State<_InLevelRankAvatar> {
  int _index = 0;

  List<String> get _sources {
    return orderedAvatarCandidates(
      photoUrl: widget.photoUrl,
      skinUrl: widget.skinUrl,
      preferSkin: widget.preferSkin,
    );
  }

  @override
  void didUpdateWidget(covariant _InLevelRankAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl ||
        oldWidget.skinUrl != widget.skinUrl ||
        oldWidget.preferSkin != widget.preferSkin) {
      _index = 0;
    }
  }

  void _next() {
    final sources = _sources;
    if (_index < sources.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _index += 1;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = _sources;
    Widget child = const ColoredBox(
      color: Color(0xFF182234),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: Color(0xFF9EB0D2),
          size: 18,
        ),
      ),
    );
    if (_index < sources.length) {
      final url = sources[_index];
      if (url.startsWith('assets/')) {
        child = Image.asset(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InLevelRankAvatarFail(onFail: _next),
        );
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        child = Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _InLevelRankAvatarFail(onFail: _next),
        );
      } else {
        child = _InLevelRankAvatarFail(onFail: _next);
      }
    }
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF182234),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _InLevelRankAvatarFail extends StatefulWidget {
  const _InLevelRankAvatarFail({required this.onFail});

  final VoidCallback onFail;

  @override
  State<_InLevelRankAvatarFail> createState() => _InLevelRankAvatarFailState();
}

class _InLevelRankAvatarFailState extends State<_InLevelRankAvatarFail> {
  bool _fired = false;

  @override
  Widget build(BuildContext context) {
    if (!_fired) {
      _fired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onFail();
      });
    }
    return const ColoredBox(
      color: Color(0xFF182234),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: Color(0xFF9EB0D2),
          size: 18,
        ),
      ),
    );
  }
}

HintDirection computeHintDirection(Level level, List<int> path) {
  final solution = level.solution;
  if (solution.length < 2) return HintDirection.none;
  if (path.length == solution.length && path.isNotEmpty) {
    return HintDirection.none;
  }

  var prefix = 0;
  final limit = path.length < solution.length ? path.length : solution.length;
  while (prefix < limit && path[prefix] == solution[prefix]) {
    prefix++;
  }

  if (path.isEmpty) {
    return _directionBetweenCells(level.width, solution[0], solution[1]);
  }

  final aligned = prefix == path.length;
  if (aligned) {
    if (path.length >= solution.length - 1) return HintDirection.none;
    return _directionBetweenCells(
        level.width, path.last, solution[path.length]);
  }

  if (path.length < 2) return HintDirection.none;
  return _directionBetweenCells(level.width, path.last, path[path.length - 2]);
}

HintDirection _directionBetweenCells(int width, int from, int to) {
  final fromRow = from ~/ width;
  final fromCol = from % width;
  final toRow = to ~/ width;
  final toCol = to % width;

  if (toRow == fromRow - 1 && toCol == fromCol) return HintDirection.up;
  if (toRow == fromRow + 1 && toCol == fromCol) return HintDirection.down;
  if (toCol == fromCol - 1 && toRow == fromRow) return HintDirection.left;
  if (toCol == fromCol + 1 && toRow == fromRow) return HintDirection.right;
  return HintDirection.none;
}

class _GlassBoardShell extends StatelessWidget {
  const _GlassBoardShell({required this.child, required this.isDark});

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(30);
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4C6FFF).withOpacity(isDark ? 0.12 : 0.07),
                    blurRadius: 52,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: const Color(0xFF1B2442).withOpacity(isDark ? 0.42 : 0.2),
                    blurRadius: 70,
                    spreadRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isDark ? 1.5 : 3.5,
              sigmaY: isDark ? 1.5 : 3.5,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color(0xFF202635),
                    Color(0xFF171C27),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.075 : 0.16),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.62 : 0.22),
                    blurRadius: 34,
                    spreadRadius: 2,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.white.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GameplayAtmosphereBackground extends StatelessWidget {
  const _GameplayAtmosphereBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF0B0F18),
            Color(0xFF090C14),
            Color(0xFF05070C),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 70,
            left: -40,
            right: -40,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 560,
                  height: 560,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        const Color(0xFF4C6FFF).withOpacity(0.14),
                        const Color(0xFF4C6FFF).withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: const <double>[0.0, 0.38, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameplayHeader extends StatelessWidget {
  const _GameplayHeader({
    required this.levelText,
    required this.timerText,
    required this.onBack,
    required this.walletCoins,
    required this.onRankingTap,
    required this.onWalletTap,
  });

  final String levelText;
  final String timerText;
  final VoidCallback onBack;
  final int walletCoins;
  final VoidCallback onRankingTap;
  final VoidCallback onWalletTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF222734),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                levelText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timerText,
                style: const TextStyle(
                  color: Color(0xFF9FB0D3),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onRankingTap,
          tooltip: 'Friends ranking',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF243044),
            foregroundColor: const Color(0xFFFFD166),
          ),
          icon: const Icon(Icons.emoji_events_rounded),
        ),
        const SizedBox(width: 8),
        _WalletPill(coins: walletCoins, onTap: onWalletTap),
      ],
    );
  }
}

class _WalletPill extends StatelessWidget {
  const _WalletPill({
    required this.coins,
    required this.onTap,
  });

  final int coins;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF243044),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Image.asset(
                'assets/branding/coin_tracepath.png',
                width: 18,
                height: 18,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '$coins',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameActionButton extends StatefulWidget {
  const _GameActionButton({
    required this.label,
    required this.onTap,
    this.outlined = false,
    this.visuallyEnabled = true,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.borderColor,
  });

  final String label;
  final VoidCallback onTap;
  final bool outlined;
  final bool visuallyEnabled;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  State<_GameActionButton> createState() => _GameActionButtonState();
}

class _GameActionButtonState extends State<_GameActionButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final background = widget.outlined
        ? Colors.transparent
        : widget.backgroundColor.withOpacity(widget.visuallyEnabled ? 1 : 0.56);
    final foreground = widget.foregroundColor.withOpacity(
      widget.visuallyEnabled ? 1 : 0.42,
    );
    final border = widget.borderColor ?? widget.foregroundColor;

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 90),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: widget.outlined
              ? BorderSide(
                  color: border.withOpacity(widget.visuallyEnabled ? 1 : 0.35),
                  width: 1.5,
                )
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _scale = 0.97),
          onTapUp: (_) => setState(() => _scale = 1),
          onTapCancel: () => setState(() => _scale = 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
