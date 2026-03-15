import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'network_burst_overlay.dart';
import 'models/leaderboard_entry.dart';
import 'services/leaderboard_service.dart';
import 'ui/avatar_utils.dart';
import 'ui/components/game_button.dart';
import 'ui/components/game_card.dart';
import 'ui/components/network_image_compat.dart';
import 'ui/components/stat_item.dart';

class VictoryScreenArgs {
  const VictoryScreenArgs({
    required this.zipNumber,
    required this.headline,
    required this.timeText,
    required this.averageText,
    required this.streak,
    required this.primaryLabel,
    required this.primaryActionId,
    required this.accentColor,
    required this.shareText,
    required this.copyText,
    this.coinsEarned = 0,
    this.adBonusCoins = 0,
    this.levelId = '',
  });

  final int zipNumber;
  final String headline;
  final String timeText;
  final String averageText;
  final int streak;
  final String primaryLabel;
  final String primaryActionId;
  final Color accentColor;
  final String shareText;
  final String copyText;
  final int coinsEarned;
  final int adBonusCoins;
  final String levelId;
}

String defaultVictoryHeadline(int seed) {
  const headlines = <String>[
    "You're on fire!",
    'Crushing it!',
    'Perfect run!',
    'Sharp move!',
  ];
  return headlines[seed.abs() % headlines.length];
}

class VictoryScreen extends StatefulWidget {
  const VictoryScreen({super.key, required this.args});

  final VictoryScreenArgs args;

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen>
    with TickerProviderStateMixin {
  static const String _firestoreDatabaseId = 'tracepath-database';
  final SocialLeaderboardService _socialLeaderboardService =
      SocialLeaderboardService();
  final Map<String, String?> _skinPreviewUrlCache = <String, String?>{};
  late Future<List<_VictoryRankRowData>> _friendsRankingFuture;
  late final AnimationController _introController;
  late final AnimationController _ctaPulseController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _headlineScale;

  @override
  void initState() {
    super.initState();
    _friendsRankingFuture = _loadFriendsRanking();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ctaPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _headerFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.34, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.34, curve: Curves.easeOutCubic),
      ),
    );
    _headlineScale = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.92, end: 1.04)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 55,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.04, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 45,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.12, 0.48),
      ),
    );
    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _ctaPulseController.dispose();
    super.dispose();
  }

  Future<List<_VictoryRankRowData>> _loadFriendsRanking() async {
    final levelId = widget.args.levelId.trim();
    if (levelId.isEmpty) {
      return const <_VictoryRankRowData>[];
    }
    try {
      final entries = await _socialLeaderboardService.getFriendsTopScores(levelId);
      final rows = <_VictoryRankRowData>[];
      for (final entry in entries) {
        final skinUrl = await _resolveSkinPreviewUrl(entry.equippedSkinId);
        rows.add(
          _VictoryRankRowData(
            entry: entry,
            photoUrl: _resolveEntryPhotoUrl(entry),
            skinPreviewUrl: skinUrl ?? '',
            preferSkin: !isDefaultSkinId(entry.equippedSkinId),
          ),
        );
      }
      rows.sort((a, b) {
        final byTime = a.entry.bestTimeMs.compareTo(b.entry.bestTimeMs);
        if (byTime != 0) return byTime;
        final byMoves = a.entry.moves.compareTo(b.entry.moves);
        if (byMoves != 0) return byMoves;
        return a.entry.uid.compareTo(b.entry.uid);
      });
      return rows;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[victory] friends ranking load failed for $levelId: $e');
      }
      try {
        final me = await _socialLeaderboardService.getCurrentUserScore(levelId);
        if (me == null) return const <_VictoryRankRowData>[];
        final skinUrl = await _resolveSkinPreviewUrl(me.equippedSkinId);
        return <_VictoryRankRowData>[
          _VictoryRankRowData(
            entry: me,
            photoUrl: _resolveEntryPhotoUrl(me),
            skinPreviewUrl: skinUrl ?? '',
            preferSkin: !isDefaultSkinId(me.equippedSkinId),
          ),
        ];
      } catch (inner) {
        if (kDebugMode) {
          debugPrint(
            '[victory] fallback current user score failed for $levelId: $inner',
          );
        }
        return const <_VictoryRankRowData>[];
      }
    }
  }

  Future<String?> _resolveSkinPreviewUrl(String skinId) async {
    final id = skinId.trim();
    if (id.isEmpty || id == 'default' || id == 'pointer_default') return null;
    if (_skinPreviewUrlCache.containsKey(id)) return _skinPreviewUrlCache[id];

    try {
      var snap = await _db().collection('skins_catalog').doc(id).get();
      Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
      if (!snap.exists || data.isEmpty) {
        final q = await _db()
            .collection('skins_catalog')
            .where('id', isEqualTo: id)
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
      _skinPreviewUrlCache[id] = resolved;
      return resolved;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[victory] failed skin preview for $id: $e');
      }
      _skinPreviewUrlCache[id] = null;
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

  String _displayName(LeaderboardEntry entry) {
    final username = entry.username.trim();
    if (username.isNotEmpty) return username;
    final playerName = entry.playerName.trim();
    if (playerName.isNotEmpty) return playerName;
    return 'Player';
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final stats = <({String label, String value})>[
      (label: 'Time', value: args.timeText),
      (label: 'Best time', value: args.averageText),
      (
        label: args.adBonusCoins > 0 ? 'Coins (+${args.adBonusCoins} ad)' : 'Coins reward',
        value: '+${args.coinsEarned}',
      ),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned.fill(
            child: NetworkBurstOverlay(
              visible: true,
              duration: const Duration(milliseconds: 2200),
              accentColor: args.accentColor,
              isDark: true,
              loop: true,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/');
                              }
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF243044),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                          Text(
                            'LEVEL COMPLETE',
                            style: TextStyle(
                              color: args.accentColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeTransition(
                    opacity: _headerFade,
                    child: ScaleTransition(
                      scale: _headlineScale,
                      child: Text(
                        args.headline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var i = 0; i < stats.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _StaggerIn(
                            parent: _introController,
                            start: 0.34 + i * 0.06,
                            end: 0.6 + i * 0.06,
                            child: GameCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              child: StatItem(
                                label: stats[i].label,
                                value: stats[i].value,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StaggerIn(
                    parent: _introController,
                    start: 0.52,
                    end: 0.78,
                    child: GameCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFFF8A4A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Current streak: ${args.streak}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (args.levelId.trim().isNotEmpty) ...[
                    _StaggerIn(
                      parent: _introController,
                      start: 0.58,
                      end: 0.86,
                      child: GameCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Friends ranking',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            FutureBuilder<List<_VictoryRankRowData>>(
                              future: _friendsRankingFuture,
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      'Friends ranking unavailable right now.',
                                      style: TextStyle(color: Color(0xFF9EB0D2)),
                                    ),
                                  );
                                }
                                final rows = snapshot.data;
                                if (rows == null) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                }
                                if (rows.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      'No friends scores yet for this level.',
                                      style: TextStyle(color: Color(0xFF9EB0D2)),
                                    ),
                                  );
                                }
                                return Column(
                                  children: [
                                    for (var i = 0; i < rows.length; i++) ...[
                                      _StaggerIn(
                                        parent: _introController,
                                        start: 0.7 + i * 0.04,
                                        end: 0.92 + i * 0.04,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: rows[i].entry.uid == currentUid
                                                ? const Color(0x1A4A7CFF)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 28,
                                                child: Text(
                                                  '#${i + 1}',
                                                  style: TextStyle(
                                                    color: i == 0
                                                        ? const Color(0xFFFFD166)
                                                        : i == 1
                                                            ? const Color(0xFFD7E3F4)
                                                            : i == 2
                                                                ? const Color(0xFFC7935F)
                                                                : const Color(
                                                                    0xFF8FA6CF,
                                                                  ),
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              _VictoryAvatar(
                                                photoUrl: rows[i].photoUrl,
                                                skinUrl: rows[i].skinPreviewUrl,
                                                preferSkin: rows[i].preferSkin,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  _displayName(rows[i].entry),
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
                                                _formatMs(rows[i].entry.bestTimeMs),
                                                style: const TextStyle(
                                                  color: Color(0xFF9BB4FF),
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (i < rows.length - 1) const SizedBox(height: 2),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Spacer(),
                  _StaggerIn(
                    parent: _introController,
                    start: 0.82,
                    end: 1.0,
                    child: AnimatedBuilder(
                      animation: _ctaPulseController,
                      builder: (context, child) {
                        final pulse = 0.45 + (_ctaPulseController.value * 0.55);
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: args.accentColor.withOpacity(0.18 * pulse),
                                blurRadius: 24 + (8 * pulse),
                                spreadRadius: 0.5 + pulse,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: GameButton(
                        label: args.primaryLabel,
                        icon: Icons.skip_next_rounded,
                        expanded: true,
                        prominent: true,
                        onTap: () => Navigator.of(context).pop(args.primaryActionId),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StaggerIn(
                    parent: _introController,
                    start: 0.86,
                    end: 1.0,
                    child: Row(
                      children: [
                        Expanded(
                          child: GameButton(
                            label: 'Replay',
                            outlined: true,
                            expanded: true,
                            onTap: () => Navigator.of(context).pop('replay'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GameButton(
                            label: 'Challenge Friend',
                            outlined: true,
                            expanded: true,
                            onTap: () async {
                              await Clipboard.setData(
                                ClipboardData(text: args.shareText),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Challenge text copied'),
                                  duration: Duration(milliseconds: 900),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggerIn extends StatelessWidget {
  const _StaggerIn({
    required this.parent,
    required this.start,
    required this.end,
    required this.child,
  });

  final AnimationController parent;
  final double start;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final safeStart = start.clamp(0.0, 1.0);
    final safeEnd = end.clamp(safeStart + 0.001, 1.0);
    final curve = CurvedAnimation(
      parent: parent,
      curve: Interval(safeStart, safeEnd, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}

String _formatMs(int ms) {
  if (ms <= 0) return '--:--';
  final seconds = (ms / 1000).round();
  final mm = (seconds ~/ 60).toString().padLeft(2, '0');
  final ss = (seconds % 60).toString().padLeft(2, '0');
  return '$mm:$ss';
}

class _VictoryRankRowData {
  const _VictoryRankRowData({
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

class _VictoryAvatar extends StatefulWidget {
  const _VictoryAvatar({
    required this.photoUrl,
    required this.skinUrl,
    required this.preferSkin,
  });

  final String photoUrl;
  final String skinUrl;
  final bool preferSkin;

  @override
  State<_VictoryAvatar> createState() => _VictoryAvatarState();
}

class _VictoryAvatarState extends State<_VictoryAvatar> {
  int _index = 0;

  List<String> get _candidates {
    return orderedAvatarCandidates(
      photoUrl: widget.photoUrl,
      skinUrl: widget.skinUrl,
      preferSkin: widget.preferSkin,
    );
  }

  @override
  void didUpdateWidget(covariant _VictoryAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl ||
        oldWidget.skinUrl != widget.skinUrl ||
        oldWidget.preferSkin != widget.preferSkin) {
      _index = 0;
    }
  }

  void _next() {
    final candidates = _candidates;
    if (_index < candidates.length - 1) {
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
    final candidates = _candidates;
    Widget child = const _VictoryAvatarPlaceholder();
    if (_index < candidates.length) {
      final path = candidates[_index];
      if (path.startsWith('assets/')) {
        child = Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _VictoryAvatarFallback(onFailed: _next),
        );
      } else if (path.startsWith('http://') || path.startsWith('https://')) {
        child = buildNetworkImageCompat(
          url: path,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          fallback: _VictoryAvatarFallback(onFailed: _next),
        );
      } else {
        child = _VictoryAvatarFallback(onFailed: _next);
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

class _VictoryAvatarFallback extends StatefulWidget {
  const _VictoryAvatarFallback({required this.onFailed});

  final VoidCallback onFailed;

  @override
  State<_VictoryAvatarFallback> createState() => _VictoryAvatarFallbackState();
}

class _VictoryAvatarFallbackState extends State<_VictoryAvatarFallback> {
  bool _fired = false;

  @override
  Widget build(BuildContext context) {
    if (!_fired) {
      _fired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onFailed();
      });
    }
    return const _VictoryAvatarPlaceholder();
  }
}

class _VictoryAvatarPlaceholder extends StatelessWidget {
  const _VictoryAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
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
