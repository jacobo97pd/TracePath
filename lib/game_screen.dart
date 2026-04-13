import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_data.dart';
import 'achievements_service.dart';
import 'celebration_overlay.dart';
import 'coins_service.dart';
import 'engine/level.dart';
import 'game_board.dart';
import 'game_theme.dart';
import 'leaderboard_service.dart';
import 'models/leaderboard_entry.dart';
import 'models/live_match.dart';
import 'models/friend_challenge.dart';
import 'puzzle_attempt.dart';
import 'progress_service.dart';
import 'score_calculator.dart';
import 'stats_service.dart';
import 'victory_screen.dart';
import 'pack_level_repository.dart';
import 'services/ghost_service.dart';
import 'services/leaderboard_service.dart' as social_lb;
import 'services/live_duel_service.dart';
import 'services/friend_challenge_service.dart';
import 'services/level_report_service.dart';
import 'services/streak_service.dart';
import 'services/energy_service.dart';
import 'services/onboarding_service.dart';
import 'trail/trail_catalog.dart';
import 'trail/trail_skin.dart';
import 'services/wallet_history_service.dart';
import 'ui/avatar_utils.dart';
import 'ui/components/game_toast.dart';
import 'services/ads_service.dart';
import 'ui/components/ghost_replay_overlay.dart';
import 'ui/components/rewarded_ad_offer_dialog.dart';
import 'l10n/l10n.dart';

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
    required this.energyService,
    this.liveDuelArgs,
    this.friendChallengeArgs,
  });

  final String packId;
  final int levelIndex;
  final ProgressService progressService;
  final StatsService statsService;
  final AchievementsService achievementsService;
  final LeaderboardService leaderboardService;
  final CoinsService coinsService;
  final EnergyService energyService;
  final LiveDuelGameArgs? liveDuelArgs;
  final FriendChallengeGameArgs? friendChallengeArgs;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxHintsPerLevel = 3;
  static const bool _unlimitedHintsForTesting = false;
  static const int _minSecondsBeforeReport = 20;
  static const String _firestoreDatabaseId = 'tracepath-database';
  static const bool _showLiveEmoteDebugHud = false;
  static bool _ghostModeSessionEnabled = true;

  final GameBoardController _boardController = GameBoardController();
  final social_lb.SocialLeaderboardService _socialLeaderboardService =
      social_lb.SocialLeaderboardService();
  final StreakService _streakService = StreakService();
  final WalletHistoryService _walletHistoryService = WalletHistoryService();
  final GhostService _ghostService = GhostService();
  final LiveDuelService _liveDuelService = LiveDuelService();
  final FriendChallengeService _friendChallengeService =
      FriendChallengeService();
  final LevelReportService _levelReportService = LevelReportService();
  final AdsService _adsService = AdsService.instance;
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
  List<int> _initialPath = const <int>[];
  GhostRun? _ghostRun;
  DateTime? _ghostPlaybackStartedAt;
  List<GhostFrame> _recordedGhostFrames = <GhostFrame>[];
  int _lastRecordedGhostSampleMs = -1;
  Offset? _lastRecordedGhostPos;
  bool _ghostEnabled = _ghostModeSessionEnabled;
  StreamSubscription<LiveMatch?>? _liveMatchSub;
  StreamSubscription<LiveMatchRealtimeTrail?>? _liveTrailSub;
  StreamSubscription<List<LiveMatchEmote>>? _liveEmoteSub;
  String _duelOpponentName = 'Opponent';
  String _duelOpponentState = 'Waiting...';
  String _liveTrailSubscribedUid = '';
  List<int> _duelOpponentPath = const <int>[];
  bool _liveFinishReported = false;
  String _liveWinnerAnnouncementKey = '';
  bool _liveWinnerResolved = false;
  bool _liveLostBeforeFinish = false;
  bool _liveResultOverlayVisible = false;
  String _liveResultOverlayTitle = '';
  String _liveResultOverlaySubtitle = '';
  String _liveResultOverlayEmoji = '';
  bool _liveResultOverlayWin = false;
  Timer? _liveResultOverlayTimer;
  Timer? _liveTrailPublishTimer;
  int _liveTrailPublishVersion = 0;
  int _lastLiveTrailPublishedAtMs = 0;
  String _lastLiveTrailPublishedSignature = '';
  String _pendingLiveTrailSignature = '';
  List<int> _pendingLiveTrailPath = const <int>[];
  String _pendingLiveTrailState = 'drawing';
  bool _liveInteractionLocked = false;
  String _liveResultSheetShownKey = '';
  bool _liveResultSheetOpen = false;
  String _liveIncomingEmoteMatchId = '';
  String _liveIncomingEmoteLastId = '';
  bool _liveIncomingEmotePrimed = false;
  Timer? _liveIncomingEmoteTimer;
  OverlayEntry? _liveIncomingEmoteEntry;
  final List<String> _liveEmoteDebugLines = <String>[];
  final Map<String, int> _duelEmoteLastSentAtMs = <String, int>{};
  String? _lastNearCompleteFeedbackKey;
  int _manualAdsWatchedToday = 0;
  int _manualAdsDailyLimit = AdsService.maxDailyManualAds;
  bool _manualAdsLimitReached = false;
  bool _manualAdBusy = false;
  Duration _manualAdCooldownRemaining = Duration.zero;
  bool _isLevelReported = false;
  bool _reportStatusLoading = false;
  bool _reportSubmitting = false;
  bool _attemptEnergyConsumed = false;
  bool _energyConsumeInFlight = false;
  bool _energyGateLocked = false;
  int _lastSelectionHapticAtMs = 0;

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
    _attachLiveMatchListener();
    if (_isLiveDuelMode) {
      unawaited(
        _liveDuelService.ensurePlaying(widget.liveDuelArgs!.matchId),
      );
    }
    unawaited(_adsService.loadRewardedAd());
    unawaited(_refreshManualAdQuota());
    unawaited(_loadReportStatus());
    widget.energyService.addListener(_handleEnergyChanged);
    if (_usesEnergySystem) {
      unawaited(widget.energyService.refresh());
    }
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packId != widget.packId ||
        oldWidget.levelIndex != widget.levelIndex) {
      _loadLevelAsync();
      unawaited(_loadReportStatus());
    }
  }

  @override
  void dispose() {
    widget.energyService.removeListener(_handleEnergyChanged);
    _hintTimer?.cancel();
    _clockTimer?.cancel();
    _coinRewardTimer?.cancel();
    _liveResultOverlayTimer?.cancel();
    _clearLiveIncomingEmoteOverlay(log: false);
    _liveTrailPublishTimer?.cancel();
    _pathColorController.dispose();
    _boardController.dispose();
    _liveMatchSub?.cancel();
    _liveTrailSub?.cancel();
    _liveEmoteSub?.cancel();
    if (_isLiveDuelMode) {
      unawaited(
        _liveDuelService.clearRealtimeTrail(
          matchId: widget.liveDuelArgs!.matchId,
          state: _completionHandled ? 'finished' : 'stopped',
        ),
      );
    }
    if (_isLiveDuelMode && !_completionHandled) {
      unawaited(
        _liveDuelService.markAbandoned(widget.liveDuelArgs!.matchId),
      );
    }
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
      final savedInProgress = widget.progressService.getInProgressLevel(
        widget.packId,
        widget.levelIndex,
      );
      final restoredPath = savedInProgress?.path ?? const <int>[];
      final restoredStartMs = savedInProgress?.startedAtMs ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final restoredStartTime = restoredStartMs > 0 && restoredStartMs <= nowMs
          ? DateTime.fromMillisecondsSinceEpoch(restoredStartMs)
          : DateTime.now();
      _initialPath = restoredPath;
      _status = GameBoardStatus.fromPath(level, restoredPath);
      _completionHandled = false;
      _hintsUsed = savedInProgress?.hintsUsed ?? 0;
      _rewindsUsed = savedInProgress?.rewindsUsed ?? 0;
      _mistakesUsed = savedInProgress?.mistakesUsed ?? 0;
      _attemptEnergyConsumed = savedInProgress?.energyConsumed ?? false;
      _energyConsumeInFlight = false;
      _runStartedAt = restoredStartTime;
      _ghostPlaybackStartedAt = restoredStartTime;
      _recordedGhostFrames = <GhostFrame>[];
      _lastRecordedGhostSampleMs = -1;
      _lastRecordedGhostPos = null;
      _liveFinishReported = false;
      _liveWinnerAnnouncementKey = '';
      _duelOpponentPath = const <int>[];
      _liveTrailSubscribedUid = '';
      _lastLiveTrailPublishedAtMs = 0;
      _lastLiveTrailPublishedSignature = '';
      _pendingLiveTrailSignature = '';
      _pendingLiveTrailPath = const <int>[];
      _pendingLiveTrailState = 'drawing';
      _liveWinnerResolved = false;
      _liveLostBeforeFinish = false;
      _liveResultOverlayVisible = false;
      _liveResultOverlayTitle = '';
      _liveResultOverlaySubtitle = '';
      _liveResultOverlayEmoji = '';
      _liveResultOverlayWin = false;
      _clearLiveIncomingEmoteOverlay(log: false);
      _liveIncomingEmoteLastId = '';
      _liveIncomingEmotePrimed = false;
      _liveIncomingEmoteMatchId = '';
      _liveEmoteDebugLines.clear();
      _liveInteractionLocked = _isLiveDuelMode;
      _liveResultSheetShownKey = '';
      _liveResultSheetOpen = false;
      _isLevelReported = false;
      _reportStatusLoading = false;
      _elapsedAtSolve = null;
      _energyGateLocked = _usesEnergySystem &&
          !_attemptEnergyConsumed &&
          widget.energyService.snapshot.current <= 0;
      if (!_isLiveDuelMode && !_isFriendChallengeMode) {
        _recordGhostFrame(_status.path, force: true);
        unawaited(_loadGhostRunForLevel(_currentLevelId));
      } else {
        _ghostRun = null;
      }

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
        setState(() {
          if (_manualAdCooldownRemaining > Duration.zero) {
            final next =
                _manualAdCooldownRemaining - const Duration(seconds: 1);
            _manualAdCooldownRemaining =
                next > Duration.zero ? next : Duration.zero;
          }
        });
      });
      _clearHint();
      setState(() {
        _isLevelLoading = false;
      });
      _persistInProgressLevel(_status.path);
      if (_usesEnergySystem) {
        unawaited(_syncEnergyGateAfterLoad());
      }
      unawaited(_maybeShowVariantTutorial(level));
      unawaited(_maybeShowCoreTutorial(level));
      unawaited(_loadReportStatus());
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

  Future<void> _maybeShowVariantTutorial(Level level) async {
    final variant = _variantFromLevelId(level.id);
    if (variant == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'variant_tutorial_shown_$variant';
    final alreadyShown = prefs.getBool(key) ?? false;
    if (alreadyShown || !mounted) return;

    final info = _variantTutorialInfo(context, variant);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.$1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  info.$2,
                  style: const TextStyle(
                    color: Color(0xFFB6C2DA),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.gameVariantExample(info.$3),
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(context.l10n.gameGotIt),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    await prefs.setBool(key, true);
  }

  Future<void> _maybeShowCoreTutorial(Level level) async {
    if (!_isTutorialPack || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    const key = 'core_tutorial_intro_shown_v1';
    final shown = prefs.getBool(key) ?? false;
    if (shown) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF355687)),
          ),
          title: Text(
            context.l10n.gameHowToPlayTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            context.l10n.gameCoreTutorialBody,
            style: TextStyle(
              color: Color(0xFFD6E4FF),
              height: 1.35,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.gameLetsGo),
            ),
          ],
        );
      },
    );
    await prefs.setBool(key, true);
  }

  String? _variantFromLevelId(String levelId) {
    final id = levelId.trim().toLowerCase();
    if (id.contains('alphabet_reverse')) return 'alphabet_reverse';
    if (id.contains('multiples_roman')) return 'multiples_roman';
    if (id.contains('alphabet')) return 'alphabet';
    if (id.contains('multiples')) return 'multiples';
    if (id.contains('roman')) return 'roman';
    return null;
  }

  (String, String, String) _variantTutorialInfo(
    BuildContext context,
    String variant,
  ) {
    final l10n = context.l10n;
    switch (variant) {
      case 'alphabet':
        return (
          l10n.gameVariantAlphabetTitle,
          l10n.gameVariantAlphabetBody,
          'A -> B -> C -> D',
        );
      case 'alphabet_reverse':
        return (
          l10n.gameVariantAlphabetReverseTitle,
          l10n.gameVariantAlphabetReverseBody,
          'Z -> Y -> X -> W',
        );
      case 'multiples':
        return (
          l10n.gameVariantMultiplesTitle,
          l10n.gameVariantMultiplesBody,
          '3, 6, 9, 12 ...',
        );
      case 'multiples_roman':
        return (
          l10n.gameVariantRomanMultiplesTitle,
          l10n.gameVariantRomanMultiplesBody,
          'III, VI, IX, XII ...',
        );
      case 'roman':
        return (
          l10n.gameVariantRomanTitle,
          l10n.gameVariantRomanBody,
          'I -> II -> III -> IV',
        );
      default:
        return (
          l10n.gameVariantDefaultTitle,
          l10n.gameVariantDefaultBody,
          '1 -> 2 -> 3',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final supportsPack = getPackById(widget.packId) != null ||
        PackLevelRepository.instance.isPrecomputedPack(widget.packId);
    if (!supportsPack) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.l10n.gamePackNotFound)),
      );
    }
    if (_isLevelLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.gameLoadingLevel)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_levelLoadError != null || _level == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.gameLevelUnavailable)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.gameCouldNotLoadLevel),
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
                  child: Text(context.l10n.commonRetry),
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
    final duelControlsLocked = _isLiveDuelMode && _liveInteractionLocked;
    final energyControlsLocked =
        _usesEnergySystem && (_energyGateLocked || _energyConsumeInFlight);
    final controlsLocked = duelControlsLocked || energyControlsLocked;

    return Scaffold(
      backgroundColor: const Color(0xFF05070C),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final liveCompact = _isLiveDuelMode &&
                (constraints.maxHeight < 860 || constraints.maxWidth < 420);
            final liveDense = _isLiveDuelMode &&
                (constraints.maxHeight < 760 || constraints.maxWidth < 380);
            final contentHorizontalPadding = liveCompact ? 14.0 : 18.0;
            final contentTopPadding =
                liveDense ? 8.0 : (_isLiveDuelMode ? 10.0 : 14.0);
            final contentBottomPadding = liveCompact ? 14.0 : 18.0;
            final sectionGap = liveCompact ? 10.0 : 14.0;
            final compactGap = liveCompact ? 8.0 : 10.0;
            final actionButtonGap = liveCompact ? 8.0 : 12.0;
            final boardPadding = liveCompact ? 11.0 : 14.0;
            final infoGap = liveCompact ? 4.0 : 6.0;
            final overlayTopMargin = liveDense ? 0.0 : 0.0;
            final overlayMaxWidth = liveCompact ? 320.0 : 380.0;
            final overlayEmoji = _liveResultOverlayEmoji.trim().isNotEmpty
                ? _liveResultOverlayEmoji
                : (_liveResultOverlayWin ? '\u{1F3C6}' : '\u{1F622}');
            final overlayBorder = _liveResultOverlayWin
                ? const Color(0xFF59E0B0)
                : const Color(0xFFFF86AE);
            final overlayGlow = _liveResultOverlayWin
                ? const Color(0xFF3FD8AE)
                : const Color(0xFFFF6B9A);
            final overlayGradientColors = _liveResultOverlayWin
                ? const [Color(0xFF15363F), Color(0xFF102730)]
                : const [Color(0xFF3A1C33), Color(0xFF2A1425)];
            return Stack(
              children: [
                const Positioned.fill(child: _GameplayAtmosphereBackground()),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    contentHorizontalPadding,
                    contentTopPadding,
                    contentHorizontalPadding,
                    contentBottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _GameplayHeader(
                        levelText: context.l10n.gameLevelProgress(
                          widget.levelIndex,
                          _packLevelCount,
                        ),
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
                        showRanking: !_isFriendChallengeMode,
                        compact: liveCompact,
                        energyText: _usesEnergySystem
                            ? context.l10n.gameEnergyCounter(
                                widget.energyService.snapshot.current,
                                widget.energyService.snapshot.max,
                              )
                            : null,
                        energySubtext: _usesEnergySystem
                            ? context.l10n.gameEnergyResetIn(
                                _formatDurationShort(
                                  widget.energyService.snapshot
                                      .timeUntilReset(),
                                ),
                              )
                            : null,
                      ),
                      SizedBox(height: sectionGap),
                      if (_isFriendChallengeMode) ...[
                        const _FriendChallengeInfoBar(),
                        SizedBox(height: compactGap),
                      ],
                      if (_isLiveDuelMode) ...[
                        _LiveDuelStatusBar(
                          opponentName: _duelOpponentName,
                          opponentState: _duelOpponentState,
                          compact: liveCompact,
                        ),
                        if (_liveLostBeforeFinish) ...[
                          SizedBox(height: liveCompact ? 6 : 8),
                          _LiveDuelResolvedBanner(
                            text: context.l10n.gameDuelFinishedBoardLocked,
                            compact: liveCompact,
                          ),
                        ],
                        SizedBox(height: compactGap),
                      ],
                      if (_usesEnergySystem &&
                          !_attemptEnergyConsumed &&
                          _energyGateLocked) ...[
                        _EnergyLockedBanner(
                          remainingText: _formatDurationShort(
                            widget.energyService.snapshot.timeUntilReset(),
                          ),
                          onOpenShop: () => context.go('/shop'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (!_isLiveDuelMode && !_isFriendChallengeMode) ...[
                        if (_ghostRun != null)
                          _GhostRaceInfoBar(
                            bestTimeText:
                                _formatGhostTime(_ghostRun!.totalTimeMs),
                            enabled: _ghostEnabled,
                            onToggle: _toggleGhostMode,
                          )
                        else
                          _GhostPendingInfoBar(
                            enabled: _ghostEnabled,
                            onToggle: _toggleGhostMode,
                          ),
                        const SizedBox(height: 10),
                      ],
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: _GlassBoardShell(
                              isDark: isDark,
                              child: Padding(
                                padding: EdgeInsets.all(boardPadding),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: AnimatedBuilder(
                                    animation: _pathColorController,
                                    builder: (context, child) {
                                      final pathColor =
                                          _currentPathColor(brightness) ??
                                              gameTheme.pathColor;
                                      return RepaintBoundary(
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            GameBoard(
                                              controller: _boardController,
                                              level: level,
                                              initialPath: _initialPath,
                                              gameTheme: gameTheme,
                                              pathColorOverride: pathColor,
                                              trailSkin: _activeTrailSkin,
                                              pointerAssetPath: widget
                                                  .coinsService
                                                  .selectedSkinAssetPath,
                                              hintDirection: _hintDirection,
                                              hintVisible: _hintVisible,
                                              onStatusChanged:
                                                  _handleStatusChanged,
                                              onChange: _handleBoardChange,
                                              opponentPath: _isLiveDuelMode
                                                  ? _duelOpponentPath
                                                  : const <int>[],
                                              opponentTrailColor:
                                                  const Color(0xFFE2538A),
                                              isInteractionLocked:
                                                  (_isLiveDuelMode &&
                                                          _liveInteractionLocked) ||
                                                      energyControlsLocked,
                                              onInvalidMove: (_) {
                                                _mistakesUsed++;
                                                _clearHint();
                                                HapticFeedback.mediumImpact();
                                              },
                                            ),
                                            if (_ghostRun != null &&
                                                _ghostPlaybackStartedAt !=
                                                    null &&
                                                _ghostEnabled &&
                                                _isGhostEnabledForLevel(
                                                  _currentLevelId,
                                                ))
                                              Positioned.fill(
                                                child: GhostReplayOverlay(
                                                  run: _ghostRun!,
                                                  startedAt:
                                                      _ghostPlaybackStartedAt!,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      Row(
                        children: [
                          Expanded(
                            child: _GameActionButton(
                              label: context.l10n.gameUndo,
                              onTap: controlsLocked ? null : _handleUndo,
                              backgroundColor: isDark
                                  ? const Color(0xFF2B2B2F)
                                  : const Color(0xFFEDEDED),
                              foregroundColor: isDark
                                  ? const Color(0xFFE8E8EB)
                                  : const Color(0xFF222222),
                            ),
                          ),
                          SizedBox(width: actionButtonGap),
                          Expanded(
                            child: _GameActionButton(
                              label: context.l10n.gameRestart,
                              onTap: controlsLocked ? null : _handleReset,
                              outlined: true,
                              borderColor: const Color(0xFF6B6E76),
                              foregroundColor: isDark
                                  ? const Color(0xFFE8E8EB)
                                  : const Color(0xFF222222),
                            ),
                          ),
                          SizedBox(width: actionButtonGap),
                          Expanded(
                            child: _GameActionButton(
                              label: _unlimitedHintsForTesting
                                  ? context.l10n.gameHintInfinite
                                  : context.l10n.gameHintCount(_hintsLeft),
                              onTap: controlsLocked ? null : _handleHint,
                              outlined: true,
                              visuallyEnabled:
                                  _unlimitedHintsForTesting || _hintsLeft > 0,
                              borderColor: gameTheme.pathColor,
                              foregroundColor: gameTheme.pathColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compactGap),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: (duelControlsLocked ||
                                  _reportStatusLoading ||
                                  _reportSubmitting ||
                                  _isLevelReported ||
                                  _isLiveDuelMode ||
                                  _isFriendChallengeMode)
                              ? null
                              : () => unawaited(_handleReportLevel()),
                          icon: Icon(
                            _isLevelReported
                                ? Icons.flag_circle_rounded
                                : Icons.flag_outlined,
                            size: 16,
                          ),
                          label: Text(
                            _reportSubmitting
                                ? context.l10n.gameReporting
                                : (_isLevelReported
                                    ? context.l10n.gameReported
                                    : context.l10n.gameReportLevel),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF9FB4D6),
                            disabledForegroundColor:
                                const Color(0xFF6A7D99).withOpacity(0.9),
                          ),
                        ),
                      ),
                      SizedBox(height: compactGap),
                      Row(
                        children: [
                          Expanded(
                            child: _GameActionButton(
                              label: context.l10n.gameWatchAd,
                              onTap: (_manualAdBusy ||
                                      _manualAdsLimitReached ||
                                      _manualAdCooldownRemaining >
                                          Duration.zero)
                                  ? null
                                  : () => unawaited(_handleManualWatchAd()),
                              outlined: true,
                              borderColor: const Color(0xFFFFD166),
                              foregroundColor: const Color(0xFFFFD166),
                              visuallyEnabled: !_manualAdsLimitReached &&
                                  _manualAdCooldownRemaining <= Duration.zero,
                            ),
                          ),
                          SizedBox(width: actionButtonGap),
                          Expanded(
                            child: _GameActionButton(
                              label: context.l10n.gameAdStatus,
                              onTap: () => unawaited(_showAdDiagnostics()),
                              outlined: true,
                              borderColor: const Color(0xFF60A5FA),
                              foregroundColor: const Color(0xFF93C5FD),
                            ),
                          ),
                        ],
                      ),
                      if (_manualAdsLimitReached) ...[
                        SizedBox(height: infoGap),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            context.l10n.gameDailyAdLimitReached,
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ] else if (_manualAdCooldownRemaining >
                          Duration.zero) ...[
                        SizedBox(height: infoGap),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            context.l10n.gameNextAdIn(
                              _formatDurationShort(_manualAdCooldownRemaining),
                            ),
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned.fill(
                  child: CelebrationOverlay(
                    visible: _showCelebration,
                    duration: const Duration(milliseconds: 2800),
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
                                color:
                                    const Color(0xFF14532D).withOpacity(0.96),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFF4ADE80)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF22C55E)
                                        .withOpacity(0.28),
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
                                    context.l10n.gameLevelCompleteReward(
                                      _coinRewardAmount >= 0
                                          ? '+$_coinRewardAmount'
                                          : '$_coinRewardAmount',
                                    ),
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
                Positioned.fill(
                  child: IgnorePointer(
                    child: SafeArea(
                      child: Stack(
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 170),
                            opacity: _liveResultOverlayVisible ? 1 : 0,
                            child: Container(
                              color: Colors.black.withOpacity(0.22),
                            ),
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: AnimatedSlide(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutBack,
                              offset: _liveResultOverlayVisible
                                  ? Offset.zero
                                  : const Offset(0, 0.24),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 180),
                                opacity: _liveResultOverlayVisible ? 1 : 0,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: overlayMaxWidth + 34,
                                  ),
                                  child: Container(
                                    margin:
                                        EdgeInsets.only(top: overlayTopMargin),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: liveCompact ? 20 : 26,
                                      vertical: liveCompact ? 14 : 18,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        liveCompact ? 20 : 24,
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: overlayGradientColors,
                                      ),
                                      border: Border.all(color: overlayBorder),
                                      boxShadow: [
                                        BoxShadow(
                                          color: overlayGlow.withOpacity(0.36),
                                          blurRadius: liveCompact ? 26 : 34,
                                          spreadRadius: 3,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        BounceInDown(
                                          key: ValueKey<String>(
                                            'live_overlay_emoji_${_liveResultOverlayTitle}_$overlayEmoji',
                                          ),
                                          duration:
                                              const Duration(milliseconds: 460),
                                          child: Text(
                                            overlayEmoji,
                                            style: TextStyle(
                                              fontSize: liveCompact ? 92 : 114,
                                              height: 1,
                                              shadows: [
                                                Shadow(
                                                  color: overlayGlow
                                                      .withOpacity(0.52),
                                                  blurRadius:
                                                      liveCompact ? 22 : 30,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: liveCompact ? 2 : 4),
                                        FadeInUp(
                                          key: ValueKey<String>(
                                            'live_overlay_title_${_liveResultOverlayTitle}',
                                          ),
                                          duration:
                                              const Duration(milliseconds: 340),
                                          delay:
                                              const Duration(milliseconds: 80),
                                          from: 12,
                                          child: Text(
                                            _liveResultOverlayTitle,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: liveCompact ? 30 : 36,
                                              height: 1.08,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                        if (_liveResultOverlaySubtitle
                                            .isNotEmpty)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top: liveCompact ? 3 : 6,
                                            ),
                                            child: FadeInUp(
                                              key: ValueKey<String>(
                                                'live_overlay_subtitle_${_liveResultOverlayTitle}',
                                              ),
                                              duration: const Duration(
                                                milliseconds: 320,
                                              ),
                                              delay: const Duration(
                                                milliseconds: 140,
                                              ),
                                              from: 10,
                                              child: Text(
                                                _liveResultOverlaySubtitle,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xFFD7E6FF),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize:
                                                      liveCompact ? 13 : 14,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildLiveEmoteDebugHud(),
              ],
            );
          },
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
                  return _InLevelRankingEmpty(
                    title: context.l10n.gameRankingUnavailable,
                    subtitle: context.l10n.gameTryAgainMoment,
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
                          Expanded(
                            child: Text(
                              context.l10n.gameFriendsRanking,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            context.l10n.gameLevelLabel(widget.levelIndex),
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
                          ? _InLevelRankingEmpty(
                              title: context.l10n.gameNoFriendsRankingTitle,
                              subtitle: context.l10n.gameNoFriendsRankingBody,
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 14, 16),
                              itemCount: rows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final row = rows[index];
                                final rank = _rankAtIndexByTime(
                                  rows
                                      .map((r) => r.entry.bestTimeMs)
                                      .toList(growable: false),
                                  index,
                                );
                                return _InLevelRankRow(
                                  rank: rank,
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

  Future<List<_InLevelRankRowData>> _loadFriendsRankingRows(
      String levelId) async {
    final entries =
        await _socialLeaderboardService.getFriendsTopScores(levelId);
    final rows = <_InLevelRankRowData>[];
    for (final entry in entries) {
      final skinPreview =
          await _resolveRankingSkinPreviewUrl(entry.equippedSkinId);
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

  int _rankAtIndexByTime(List<int> timesMs, int index) {
    if (index <= 0) return 1;
    var rank = index + 1;
    for (var j = index - 1; j >= 0; j--) {
      if (timesMs[j] == timesMs[index]) {
        rank = j + 1;
      } else {
        break;
      }
    }
    return rank;
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

  Future<void> _loadReportStatus() async {
    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLevelReported = false;
        _reportStatusLoading = false;
      });
      return;
    }
    setState(() => _reportStatusLoading = true);
    try {
      final userSnap = await _db().collection('users').doc(uid).get();
      final userData = userSnap.data() ?? const <String, dynamic>{};
      final reported = _isLevelAlreadyReportedInUserData(
        userData: userData,
        levelId: _currentLevelId,
      );
      if (!mounted) return;
      setState(() {
        _isLevelReported = reported;
        _reportStatusLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _reportStatusLoading = false);
    }
  }

  Future<void> _handleReportLevel() async {
    if (!mounted) return;
    if (_isLiveDuelMode || _isFriendChallengeMode) return;
    if (_isLevelReported || _reportSubmitting) return;

    final started = _runStartedAt;
    final elapsedSec =
        started == null ? 0 : DateTime.now().difference(started).inSeconds;
    if (elapsedSec < _minSecondsBeforeReport) {
      await GameToast.show(
        context,
        title: context.l10n.gameReportUnavailableTitle,
        message: context.l10n.gameReportUnavailableBody(
          _minSecondsBeforeReport,
        ),
        type: GameToastType.info,
      );
      return;
    }

    final shouldReport = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF111827),
            title: Text(
              context.l10n.gameReportConfirmTitle,
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              context.l10n.gameReportConfirmBody,
              style: const TextStyle(color: Color(0xFFB6C2DA)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.l10n.commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.l10n.gameReportAndSkip),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldReport || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid.trim() ?? '';
    if (uid.isEmpty) {
      await GameToast.show(
        context,
        title: context.l10n.gameSignInRequiredTitle,
        message: context.l10n.gameSignInRequiredBody,
        type: GameToastType.info,
      );
      return;
    }

    final levelId = _currentLevelId;
    final nextLevel = (widget.levelIndex + 1).clamp(1, _packLevelCount).toInt();
    final nextLevelId = _buildNextLevelId(widget.packId, nextLevel);

    final userRef = _db().collection('users').doc(uid);

    setState(() => _reportSubmitting = true);
    try {
      final userSnap = await userRef.get();
      final userData = userSnap.data() ?? const <String, dynamic>{};
      final alreadyReportedFromUserDoc = _isLevelAlreadyReportedInUserData(
        userData: userData,
        levelId: levelId,
      );
      if (alreadyReportedFromUserDoc) {
        if (mounted) {
          setState(() => _isLevelReported = true);
        }
        await GameToast.show(
          context,
          title: context.l10n.gameAlreadyReportedTitle,
          message: context.l10n.gameAlreadyReportedBody,
          type: GameToastType.info,
        );
        return;
      }

      final result = await _levelReportService.reportLevelAndUnlockNext(
        levelId: levelId,
        nextLevelId: nextLevelId,
        nextLevelIndex: nextLevel,
        reason: 'unsolvable_or_bugged',
      );

      if (kDebugMode) {
        debugPrint(
          '[report-level] callable ok uid=$uid level=$levelId next=$nextLevelId reportCreated=${result.reportCreated} emailSent=${result.emailSent}',
        );
      }

      await widget.progressService
          .setCurrentLevelForPack(widget.packId, nextLevel);

      if (!mounted) return;
      setState(() => _isLevelReported = true);

      await GameToast.show(
        context,
        title: context.l10n.gameLevelReportedTitle,
        message: context.l10n.gameLevelReportedBody,
        type: GameToastType.info,
      );

      if (!mounted) return;
      if (nextLevel > widget.levelIndex) {
        context.go('/play/${widget.packId}/$nextLevel');
      } else {
        context.go('/play');
      }
    } on LevelReportException catch (e, st) {
      if (kDebugMode) {
        debugPrint(
          '[report-level] callable error code=${e.code} message=${e.message}',
        );
        debugPrint('$st');
      }
      if (!mounted) return;
      await GameToast.show(
        context,
        title: context.l10n.gameCouldNotReportTitle,
        message: _friendlyReportError(
          context: context,
          code: e.code,
          fallbackMessage: e.message,
        ),
        type: GameToastType.info,
      );
    } on FirebaseException catch (e, st) {
      if (kDebugMode) {
        debugPrint('[report-level] firestore error code=${e.code}');
        debugPrint('[report-level] message=${e.message}');
        debugPrint('$st');
      }
      if (!mounted) return;
      await GameToast.show(
        context,
        title: context.l10n.gameCouldNotReportTitle,
        message: _friendlyReportError(
          context: context,
          code: e.code,
          fallbackMessage: e.message,
        ),
        type: GameToastType.info,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[report-level] unexpected error: $e');
        final boxed = _extractWrappedReportError(e);
        if (boxed != null) {
          debugPrint(
              '[report-level] wrapped code=${boxed.$1} message=${boxed.$2}');
        }
        debugPrint('$st');
      }
      final wrapped = _extractWrappedReportError(e);
      if (!mounted) return;
      await GameToast.show(
        context,
        title: context.l10n.gameCouldNotReportTitle,
        message: _friendlyReportError(
          context: context,
          code: wrapped?.$1,
          fallbackMessage: wrapped?.$2 ?? e.toString(),
        ),
        type: GameToastType.info,
      );
    } finally {
      if (mounted) {
        setState(() => _reportSubmitting = false);
      }
    }
  }

  bool _isLevelAlreadyReportedInUserData({
    required Map<String, dynamic> userData,
    required String levelId,
  }) {
    final idsRaw = userData['reportedLevelIds'];
    if (idsRaw is Iterable) {
      for (final item in idsRaw) {
        if (item is String && item.trim() == levelId) {
          return true;
        }
      }
    }

    final mapRaw = userData['reportedLevels'];
    if (mapRaw is Map) {
      final value = mapRaw[levelId];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        return normalized == '1' || normalized == 'true' || normalized == 'yes';
      }
    }
    return false;
  }

  String _buildNextLevelId(String packId, int levelIndex) {
    final normalizedPack = packId.trim().isEmpty ? 'pack' : packId.trim();
    return '$normalizedPack:$levelIndex';
  }

  String _friendlyReportError({
    required BuildContext context,
    required String? code,
    String? fallbackMessage,
  }) {
    final l10n = context.l10n;
    final normalized = (code ?? '').trim().toLowerCase();
    if (normalized == 'permission-denied') {
      return l10n.gameReportErrorPermissionDenied;
    }
    if (normalized == 'endpoint-not-configured') {
      return l10n.gameReportErrorEndpointNotConfigured;
    }
    if (normalized == 'invalid-endpoint') {
      return l10n.gameReportErrorInvalidEndpoint;
    }
    if (normalized == 'timeout') {
      return l10n.gameReportErrorTimeout;
    }
    if (normalized == 'network-failed') {
      return l10n.gameReportErrorNetwork;
    }
    if (normalized.startsWith('http-')) {
      return l10n.gameReportErrorServerRejected;
    }
    if (normalized == 'unavailable' || normalized == 'network-request-failed') {
      return l10n.gameReportErrorNetwork;
    }
    if (normalized == 'unauthenticated') {
      return l10n.gameReportErrorUnauthenticated;
    }
    final fb = (fallbackMessage ?? '').trim();
    final fbLower = fb.toLowerCase();
    if (fbLower.contains('permission-denied')) {
      return l10n.gameReportErrorPermissionDenied;
    }
    if (fbLower.contains('network') || fbLower.contains('unavailable')) {
      return l10n.gameReportErrorNetwork;
    }
    if (fb.isNotEmpty && fb.length < 120) return fb;
    return l10n.gameReportErrorGeneric;
  }

  (String?, String?)? _extractWrappedReportError(Object error) {
    try {
      final dynamic d = error;
      final dynamic inner = d.error;
      if (inner == null) return null;
      String? code;
      String? message;
      try {
        code = (inner.code as String?)?.trim();
      } catch (_) {}
      try {
        message = (inner.message as String?)?.trim();
      } catch (_) {}
      return (code, message);
    } catch (_) {
      return null;
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

  void _handleEnergyChanged() {
    if (!mounted || !_usesEnergySystem) return;
    final wasLocked = _energyGateLocked;
    final nextLocked =
        !_attemptEnergyConsumed && widget.energyService.snapshot.current <= 0;
    setState(() {
      _energyGateLocked = nextLocked;
      if (wasLocked && !nextLocked && !_attemptEnergyConsumed) {
        // User recovered energy (daily reset / battery): do not count locked time.
        _runStartedAt = DateTime.now();
        _ghostPlaybackStartedAt = _runStartedAt;
      }
    });
  }

  void _handleReset() {
    HapticFeedback.selectionClick();
    setState(() {
      _hintsUsed = 0;
      _rewindsUsed = 0;
      _mistakesUsed = 0;
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
          title: context.l10n.gameHintTitle,
          message: context.l10n.gameNoHintsLeft,
          duration: const Duration(milliseconds: 1400),
        ),
      );
      return;
    }

    final direction = computeHintDirection(level, _status.path);
    if (direction == HintDirection.none) {
      HapticFeedback.selectionClick();
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.info,
          title: context.l10n.gameHintTitle,
          message: _localizedHintUnavailableMessage(),
          duration: const Duration(milliseconds: 1400),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _hintsUsed++;
      _hintDirection = direction;
      _hintVisible = true;
    });
    unawaited(
      GameToast.show(
        context,
        type: GameToastType.info,
        title: context.l10n.gameHintTitle,
        message: _localizedHintAppliedMessage(direction),
        duration: const Duration(milliseconds: 1400),
      ),
    );
    _persistInProgressLevel(_status.path);
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      setState(() {
        _hintVisible = false;
      });
    });
  }

  String _localizedHintUnavailableMessage() {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'es') {
      return 'No hay pista disponible ahora mismo. Vuelve al punto correcto.';
    }
    return 'No hint is available right now. Return to the correct point.';
  }

  String _localizedHintAppliedMessage(HintDirection direction) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'es') {
      switch (direction) {
        case HintDirection.up:
          return 'Pista aplicada: sigue hacia arriba.';
        case HintDirection.down:
          return 'Pista aplicada: sigue hacia abajo.';
        case HintDirection.left:
          return 'Pista aplicada: sigue hacia la izquierda.';
        case HintDirection.right:
          return 'Pista aplicada: sigue hacia la derecha.';
        case HintDirection.none:
          return 'Pista aplicada.';
      }
    }
    switch (direction) {
      case HintDirection.up:
        return 'Hint applied: move up.';
      case HintDirection.down:
        return 'Hint applied: move down.';
      case HintDirection.left:
        return 'Hint applied: move left.';
      case HintDirection.right:
        return 'Hint applied: move right.';
      case HintDirection.none:
        return 'Hint applied.';
    }
  }

  void _handleBoardChange(GameBoardChange change) {
    _clearHint();
    if (_usesEnergySystem &&
        !_attemptEnergyConsumed &&
        _energyGateLocked &&
        change.type == GameBoardChangeType.add) {
      _boardController.reset();
      return;
    }
    if (_usesEnergySystem &&
        !_attemptEnergyConsumed &&
        _energyConsumeInFlight &&
        change.type == GameBoardChangeType.add) {
      return;
    }
    switch (change.type) {
      case GameBoardChangeType.add:
        _triggerSelectionHaptic();
        if (_usesEnergySystem && !_attemptEnergyConsumed) {
          unawaited(_consumeEnergyForAttempt(change.path));
        }
        break;
      case GameBoardChangeType.backtrack:
      case GameBoardChangeType.rewind:
      case GameBoardChangeType.undo:
        _rewindsUsed++;
        _triggerSelectionHaptic();
        break;
      case GameBoardChangeType.reset:
        break;
    }
    _scheduleLiveTrailPublish(
      change.path,
      state: _completionHandled ? 'finished' : 'drawing',
    );
  }

  void _triggerSelectionHaptic({int minIntervalMs = 35}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if ((now - _lastSelectionHapticAtMs) < minIntervalMs) return;
    _lastSelectionHapticAtMs = now;
    HapticFeedback.selectionClick();
  }

  Future<void> _syncEnergyGateAfterLoad() async {
    if (!_usesEnergySystem) return;
    final snapshot = await widget.energyService.refresh();
    if (!mounted || _status.solved) return;
    setState(() {
      _energyGateLocked = !_attemptEnergyConsumed && snapshot.current <= 0;
    });
    if (_energyGateLocked) {
      unawaited(_showEnergyDepletedDialog());
    }
  }

  Future<void> _consumeEnergyForAttempt(List<int> latestPath) async {
    if (!_usesEnergySystem ||
        _attemptEnergyConsumed ||
        _energyConsumeInFlight) {
      return;
    }
    setState(() {
      _energyConsumeInFlight = true;
    });
    final result = await widget.energyService.consumeForNormalPuzzle();
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _attemptEnergyConsumed = true;
        _energyConsumeInFlight = false;
        _energyGateLocked = false;
      });
      _persistInProgressLevel(latestPath);
      return;
    }
    setState(() {
      _energyConsumeInFlight = false;
      _energyGateLocked = true;
    });
    _boardController.reset();
    _persistInProgressLevel(const <int>[]);
    unawaited(_showEnergyDepletedDialog());
  }

  Future<void> _showEnergyDepletedDialog() async {
    if (!mounted || !_usesEnergySystem) return;
    final snapshot = await widget.energyService.refresh();
    if (!mounted) return;
    final canUseBattery = snapshot.batteryCount > 0;
    final offer = EnergyService.batteryOffers.first;
    final resetText = _formatDurationShort(snapshot.timeUntilReset());
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF131E31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withOpacity(0.10)),
          ),
          title: Text(
            context.l10n.energyNoEnergyTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            canUseBattery
                ? context.l10n.energyOutWithBattery(resetText)
                : context.l10n.energyOutWithoutBattery(resetText),
            style: const TextStyle(color: Color(0xFFB8C7E6), height: 1.3),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.commonClose),
            ),
            if (canUseBattery)
              FilledButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final useResult =
                      await widget.energyService.useBatteryAndRefill();
                  if (!mounted) return;
                  if (!useResult.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.energyCouldNotUseBattery),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _energyGateLocked = false;
                    _runStartedAt = DateTime.now();
                    _ghostPlaybackStartedAt = _runStartedAt;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.energyRestored(
                          useResult.snapshot.current,
                          useResult.snapshot.max,
                        ),
                      ),
                    ),
                  );
                },
                child: Text(context.l10n.energyUseBattery),
              )
            else
              FilledButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  final purchaseResult =
                      await widget.energyService.buyBatteryPackWithCoins(
                    offer: offer,
                  );
                  if (!mounted) return;
                  if (!purchaseResult.success) {
                    final text = purchaseResult.failureReason ==
                            EnergyBatteryPurchaseFailureReason.notEnoughCoins
                        ? context.l10n.energyNotEnoughCoinsBattery
                        : context.l10n.energyBatteryPurchaseFailed;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(text)),
                    );
                    return;
                  }
                  if (purchaseResult.newCoinsBalance != null) {
                    await widget.coinsService
                        .syncCoinsFromRemote(purchaseResult.newCoinsBalance!);
                  }
                  final refill =
                      await widget.energyService.useBatteryAndRefill();
                  if (!mounted) return;
                  if (refill.success) {
                    setState(() {
                      _energyGateLocked = false;
                      _runStartedAt = DateTime.now();
                      _ghostPlaybackStartedAt = _runStartedAt;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.energyBatteryPurchasedAndUsed(
                            refill.snapshot.current,
                            refill.snapshot.max,
                          ),
                        ),
                      ),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.l10n.energyBatteryPurchasedCount(
                          purchaseResult.snapshot.batteryCount,
                        ),
                      ),
                    ),
                  );
                },
                child: Text(context.l10n.energyBuyBattery(offer.coinCost)),
              ),
          ],
        );
      },
    );
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
    final wasSolved = _status.solved;
    final becameSolved = !wasSolved && status.solved;
    _status = status;

    if (becameSolved) {
      _elapsedAtSolve = _currentElapsedDuration;
    } else if (wasSolved && !status.solved) {
      _completionHandled = false;
      _elapsedAtSolve = null;
    }

    if (status.solved) {
      unawaited(
        widget.progressService.clearInProgressLevel(
          widget.packId,
          widget.levelIndex,
        ),
      );
    } else {
      _persistInProgressLevel(status.path);
    }
    _recordGhostFrame(status.path);
    _scheduleLiveTrailPublish(
      status.path,
      state: status.solved ? 'finished' : 'drawing',
    );
    _maybeShowNearCompleteFeedback(status);

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
      if (_isLiveDuelMode) {
        unawaited(_showCompletionDialog());
      } else {
        _startCelebrationAndShowDialog();
      }
    }
  }

  void _maybeShowNearCompleteFeedback(GameBoardStatus status) {
    final level = _level;
    if (level == null || !mounted || status.solved) {
      _lastNearCompleteFeedbackKey = null;
      return;
    }

    final totalCells = level.width * level.height;
    final isPathFull = status.path.length == totalCells;
    final isSequenceComplete = status.lastSequentialNumber == status.maxNumber;
    final endCell = GameBoardRules.endCell(level);
    if (endCell == null) {
      _lastNearCompleteFeedbackKey = null;
      return;
    }
    final endsAtFinal = status.path.isNotEmpty && status.path.last == endCell;

    if (!(isPathFull && isSequenceComplete && !endsAtFinal)) {
      _lastNearCompleteFeedbackKey = null;
      return;
    }

    final key = '${status.path.last}_${endCell}_${status.path.length}';
    if (_lastNearCompleteFeedbackKey == key) {
      return;
    }
    _lastNearCompleteFeedbackKey = key;

    final finalCell = endCell;
    final finalLabel = level.displayLabels[finalCell]?.trim().isNotEmpty == true
        ? level.displayLabels[finalCell]!.trim()
        : '${level.numbers[finalCell] ?? status.maxNumber}';
    unawaited(
      GameToast.show(
        context,
        type: GameToastType.info,
        title: context.l10n.gameAlmostThereTitle,
        message: context.l10n.gameAlmostThereBody(finalLabel),
        duration: const Duration(milliseconds: 1800),
      ),
    );
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
    if (_isLiveDuelMode) {
      final elapsedMs = _currentElapsedDuration.inMilliseconds;
      await _runCompletionStep(
        'liveDuel.reportFinish',
        () => _reportLiveDuelFinish(elapsedMs),
      );
      if (!mounted) return;
      setState(() {
        _showCelebration = false;
      });
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.social,
          title: context.l10n.gameTimeTitle,
          message: context.l10n.gameWaitingForDuelResult,
          duration: const Duration(milliseconds: 1400),
        ),
      );
      return;
    }
    if (_isFriendChallengeMode) {
      await _runCompletionStep(
        'friendChallenge.markCompleted',
        () => _friendChallengeService.markCompleted(
          challengeId: widget.friendChallengeArgs!.challengeId,
          elapsedMs: _currentElapsedDuration.inMilliseconds,
        ),
      );
      if (!mounted) return;
      final brightness = Theme.of(context).brightness;
      final gameTheme = ThemeGenerator.generateTheme(
        seed: _themeSeed!,
        brightness: brightness,
      );
      final action = await _runCompletionStep<String?>(
            'navigation.pushVictory.friendChallenge',
            () => context.push<String>(
              '/victory',
              extra: VictoryScreenArgs(
                zipNumber: widget.levelIndex,
                headline: context.l10n.gameFriendlyChallengeCompleteHeadline,
                timeText: _elapsedText,
                averageText: '--:--',
                streak: widget.progressService.getDailyStreak(),
                primaryLabel: context.l10n.gameReplay,
                primaryActionId: 'replay',
                accentColor: gameTheme.pathColor,
                coinsEarned: 0,
                adBonusCoins: 0,
                levelId: levelId,
                shareText:
                    context.l10n.gameFriendlyChallengeShare(_elapsedText),
                copyText: context.l10n.gameFriendlyChallengeCopy(_elapsedText),
              ),
            ),
          ) ??
          'back';
      if (!mounted) return;
      switch (action) {
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
            _ghostPlaybackStartedAt = _runStartedAt;
            _recordedGhostFrames = <GhostFrame>[];
            _lastRecordedGhostSampleMs = -1;
            _lastRecordedGhostPos = null;
            _elapsedAtSolve = null;
            _showCelebration = false;
          });
          break;
        default:
          setState(() {
            _showCelebration = false;
          });
          context.go('/social');
          break;
      }
      return;
    }
    final perfectCompletion = _mistakesUsed == 0;
    final previousGhostBestMs =
        _isLiveDuelMode ? 0 : (_ghostRun?.totalTimeMs ?? 0);
    final levelReward = await _runCompletionStep<LevelRewardGrantResult>(
          'coins.rewardLevelCompletionOncePerLevel',
          () => widget.coinsService.rewardLevelCompletionOncePerLevel(
            levelId: levelId,
            perfectCompletion: perfectCompletion,
          ),
          fallback: const LevelRewardGrantResult(
            coinsAwarded: 0,
            firstCompletion: false,
          ),
        ) ??
        const LevelRewardGrantResult(
          coinsAwarded: 0,
          firstCompletion: false,
        );
    await _runCompletionStep(
      'progress.markCompleted',
      () => widget.progressService
          .markCompleted(widget.packId, widget.levelIndex),
    );
    if (_isTutorialPack) {
      unawaited(OnboardingService.instance.markFirstLevelCompleted());
    }
    await _runCompletionStep(
      'progress.clearInProgress',
      () => widget.progressService.clearInProgressLevel(
        widget.packId,
        widget.levelIndex,
      ),
    );
    await _runCompletionStep(
      'progress.markDailyCompleted',
      () => widget.progressService.markDailyCompleted(),
    );
    if (!_isLiveDuelMode) {
      await _runCompletionStep(
        'ghost.persistIfBest',
        () => _persistGhostIfBest(
          levelId: levelId,
          elapsedMs: _currentElapsedDuration.inMilliseconds,
        ),
      );
    }
    var rewardTotal = levelReward.coinsAwarded;
    var rewardedAdBonus = 0;
    if (mounted && !levelReward.firstCompletion) {
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.info,
          title: context.l10n.gameLevelAlreadyCompletedTitle,
          message: context.l10n.gameNoCoinRewardReplay,
          duration: const Duration(milliseconds: 2000),
        ),
      );
    }
    if (mounted &&
        previousGhostBestMs > 0 &&
        _currentElapsedDuration.inMilliseconds < previousGhostBestMs) {
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.achievement,
          title: context.l10n.gameNewBestTitle,
          message: context.l10n.gameBeatYourGhost,
          duration: const Duration(milliseconds: 2100),
        ),
      );
    }
    final didBeatGhost = previousGhostBestMs > 0 &&
        _currentElapsedDuration.inMilliseconds < previousGhostBestMs;
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
      rewardedAdBonus = await _runCompletionStep<int>(
            'ads.rewardedBonus',
            () => _maybeGrantRewardedAdBonus(),
            fallback: 0,
          ) ??
          0;
      rewardTotal += rewardedAdBonus;
      _showCoinDelta(rewardTotal);
    }
    await _runCompletionStep(
      'stats.recordLevelCompleted',
      () => widget.statsService.recordLevelCompleted(
        mode: SolveMode.campaign,
        difficulty: level.difficulty,
        solveTimeMs: _currentElapsedDuration.inMilliseconds,
        hintsUsed: _hintsUsed,
        rewindsUsed: _rewindsUsed,
      ),
    );
    await _runCompletionStep(
      'coins.updateProfileProgress',
      () => widget.coinsService.updateProfileProgress(
        highestLevelReached: widget.levelIndex,
        playTimeSecondsDelta: _currentElapsedDuration.inSeconds,
        gameWon: true,
        solveMs: _currentElapsedDuration.inMilliseconds,
      ),
    );
    final unlocked = await _runCompletionStep<List<AchievementDef>>(
          'achievements.evaluateAfterCompletion',
          () => widget.achievementsService.evaluateAfterCompletion(
            mode: SolveMode.campaign,
            difficulty: level.difficulty,
            solveTimeMs: _currentElapsedDuration.inMilliseconds,
            hintsUsed: _hintsUsed,
            rewindsUsed: _rewindsUsed,
          ),
          fallback: const <AchievementDef>[],
        ) ??
        const <AchievementDef>[];
    AchievementDef? ghostAchievementUnlocked;
    if (didBeatGhost) {
      ghostAchievementUnlocked = await _runCompletionStep<AchievementDef?>(
        'achievements.unlockById(beat_the_ghost)',
        () => widget.achievementsService.unlockById('beat_the_ghost'),
      );
    }
    final ghostDef = ghostAchievementUnlocked;
    final unlockedNow = <AchievementDef>[
      ...unlocked,
      if (ghostDef != null && !unlocked.any((a) => a.id == ghostDef.id))
        ghostDef,
    ];
    if (!mounted) {
      return;
    }
    if (unlockedNow.isNotEmpty) {
      final first = unlockedNow.first;
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.achievement,
          title: context.l10n.gameAchievementUnlocked,
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
    await _runCompletionStep(
      'progress.setBestScoreIfHigher',
      () => widget.progressService.setBestScoreIfHigher(
        widget.packId,
        widget.levelIndex,
        breakdown.finalScore,
      ),
    );
    await _runCompletionStep(
      'leaderboard.addPuzzleAttempt',
      () => widget.leaderboardService.addPuzzleAttempt(
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
      ),
    );
    final stars = _computeStars();
    if (!_isLiveDuelMode) {
      await _runCompletionStep(
        'socialLeaderboard.submitLevelResult',
        () => _socialLeaderboardService.submitLevelResult(
          levelId: levelId,
          bestTimeMs: _currentElapsedDuration.inMilliseconds,
          moves: _status.path.length,
          stars: stars,
        ),
      );
      await _runCompletionStep(
        'socialLeaderboard.persistCompletedLevel',
        () => _socialLeaderboardService.persistCompletedLevel(
          levelId: levelId,
          bestTimeMs: _currentElapsedDuration.inMilliseconds,
          moves: _status.path.length,
          stars: stars,
          highestLevelReached: widget.levelIndex,
        ),
      );
    }

    if (currentUid.trim().isNotEmpty && rewardTotal > 0) {
      await _runCompletionStep(
        'walletHistory.addTransaction',
        () => _walletHistoryService.addTransaction(
          uid: currentUid,
          type: 'reward',
          amount: rewardTotal,
          source: 'level_complete',
          referenceId: levelId,
        ),
      );
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
    final hasNext = _isTutorialPack || widget.levelIndex < _packLevelCount;
    final action = await _runCompletionStep<String?>(
          'navigation.pushVictory',
          () => context.push<String>(
            '/victory',
            extra: VictoryScreenArgs(
              zipNumber: widget.levelIndex,
              headline: defaultVictoryHeadline(context, breakdown.finalScore),
              timeText: _elapsedText,
              averageText: _formatMs(average),
              streak: widget.progressService.getDailyStreak(),
              primaryLabel: _isTutorialPack
                  ? context.l10n.gameContinueTutorial
                  : (hasNext
                      ? context.l10n.victoryPrimaryNextLevel
                      : context.l10n.victoryPrimaryPlayAgain),
              primaryActionId: hasNext ? 'next' : 'replay',
              accentColor: gameTheme.pathColor,
              coinsEarned: rewardTotal,
              adBonusCoins: rewardedAdBonus,
              levelId: levelId,
              shareText: context.l10n.gameVictoryShareText(
                widget.levelIndex,
                _elapsedText,
                breakdown.finalScore,
              ),
              copyText: context.l10n.gameVictoryCopyText(
                widget.levelIndex,
                _elapsedText,
                widget.progressService.getDailyStreak(),
              ),
            ),
          ),
        ) ??
        'fallback_nav';

    if (!mounted) {
      return;
    }

    switch (action) {
      case 'next':
        setState(() {
          _showCelebration = false;
        });
        if (_isTutorialPack) {
          context.go('/shop');
          break;
        }
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
          _ghostPlaybackStartedAt = _runStartedAt;
          _recordedGhostFrames = <GhostFrame>[];
          _lastRecordedGhostSampleMs = -1;
          _lastRecordedGhostPos = null;
          _elapsedAtSolve = null;
          _showCelebration = false;
          _attemptEnergyConsumed = false;
          _energyConsumeInFlight = false;
          _energyGateLocked =
              _usesEnergySystem && widget.energyService.snapshot.current <= 0;
        });
        _persistInProgressLevel(const <int>[]);
        if (!_isLiveDuelMode && !_isFriendChallengeMode) {
          _recordGhostFrame(const <int>[], force: true);
          unawaited(_loadGhostRunForLevel(_currentLevelId));
        }
        break;
      case 'fallback_nav':
        setState(() {
          _showCelebration = false;
        });
        context.go('/play');
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
    const bonusCoins = AdsService.automaticAdRewardCoins;
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

    final earned = await _adsService.showRewardedAd(() async {
      await widget.coinsService.addCoins(bonusCoins);
    });
    if (!mounted) return 0;

    if (!earned) {
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.info,
          title: context.l10n.gameRewardedAdUnavailableTitle,
          message: context.l10n.gameContinuingWithoutBonus,
          duration: const Duration(milliseconds: 1800),
        ),
      );
      return 0;
    }
    if (!mounted) return bonusCoins;
    unawaited(
      GameToast.show(
        context,
        type: GameToastType.coins,
        title: context.l10n.gameBonusRewardTitle,
        message: context.l10n.gameBonusCoins(bonusCoins),
        duration: const Duration(milliseconds: 2000),
      ),
    );
    return bonusCoins;
  }

  Future<void> _handleManualWatchAd() async {
    const bonusCoins = AdsService.manualAdRewardCoins;
    if (!mounted) return;
    if (_manualAdBusy) return;
    setState(() {
      _manualAdBusy = true;
    });
    try {
      final quota = await _adsService.getManualAdQuota();
      if (!mounted) return;
      if (quota.limitReached) {
        await _refreshManualAdQuota();
        unawaited(
          GameToast.show(
            context,
            type: GameToastType.info,
            title: context.l10n.gameDailyLimitReachedTitle,
            message: context.l10n.gameNoMoreAdsToday,
            duration: const Duration(milliseconds: 1800),
          ),
        );
        return;
      }
      if (quota.cooldownActive) {
        await _refreshManualAdQuota();
        unawaited(
          GameToast.show(
            context,
            type: GameToastType.info,
            title: context.l10n.gamePleaseWaitTitle,
            message: context.l10n.gameNextAdIn(
              _formatDurationShort(quota.cooldownRemaining),
            ),
            duration: const Duration(milliseconds: 1800),
          ),
        );
        return;
      }

      final earned = await _adsService.showRewardedAd(() async {
        final grant = await _adsService.grantManualAdReward();
        await widget.coinsService.syncCoinsFromRemote(grant.newCoinsBalance);
      });
      if (!mounted) return;
      await _refreshManualAdQuota();

      if (!earned) {
        unawaited(
          GameToast.show(
            context,
            type: GameToastType.info,
            title: context.l10n.gameRewardedAdUnavailableTitle,
            message: context.l10n.gameTryAgainMoment,
            duration: const Duration(milliseconds: 1800),
          ),
        );
        return;
      }

      unawaited(
        GameToast.show(
          context,
          type: GameToastType.coins,
          title: context.l10n.gameAdRewardTitle,
          message: context.l10n.gameBonusCoins(bonusCoins),
          duration: const Duration(milliseconds: 1900),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _manualAdBusy = false;
        });
      }
    }
  }

  Future<void> _showAdDiagnostics() async {
    if (!mounted) return;
    final hasAd = _adsService.hasRewardedAd;
    final isLoading = _adsService.isLoadingRewardedAd;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          title: Text(
            context.l10n.gameRewardedAdStatusTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            context.l10n.gameRewardedAdStatusBody(
              hasAd ? context.l10n.commonYes : context.l10n.commonNo,
              isLoading ? context.l10n.commonYes : context.l10n.commonNo,
            ),
            style: const TextStyle(color: Color(0xFFCBD5E1)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.commonClose),
            ),
            FilledButton(
              onPressed: () async {
                await _adsService.loadRewardedAd();
                if (!context.mounted) return;
                Navigator.of(context).pop();
                if (!mounted) return;
                unawaited(
                  GameToast.show(
                    this.context,
                    type: GameToastType.info,
                    title: this.context.l10n.gameAdReloadRequestedTitle,
                    message: this.context.l10n.gameAdReloadRequestedBody,
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              },
              child: Text(context.l10n.commonReload),
            ),
          ],
        );
      },
    );
  }

  Future<void> _refreshManualAdQuota() async {
    try {
      final quota = await _adsService.getManualAdQuota();
      if (!mounted) return;
      setState(() {
        _manualAdsWatchedToday = quota.watchedToday;
        _manualAdsDailyLimit = quota.maxDailyAds;
        _manualAdsLimitReached = quota.limitReached;
        _manualAdCooldownRemaining = quota.cooldownRemaining;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ADS] quota refresh failed: $e');
      }
    }
  }

  String _formatDurationShort(Duration value) {
    final totalSeconds = value.inSeconds < 0 ? 0 : value.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get _hintsLeft {
    final left = _maxHintsPerLevel - _hintsUsed;
    return left < 0 ? 0 : left;
  }

  int get _packLevelCount {
    final precomputed =
        PackLevelRepository.instance.totalLevelsSync(widget.packId);
    if (precomputed > 0) {
      return precomputed;
    }
    return displayedLevelCount;
  }

  Future<T?> _runCompletionStep<T>(
    String name,
    Future<T> Function() action, {
    T? fallback,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      return await action().timeout(timeout);
    } on TimeoutException catch (e, st) {
      debugPrint('[game][complete] step=$name timeout: $e');
      if (kDebugMode) {
        debugPrintStack(stackTrace: st);
      }
      return fallback;
    } catch (e, st) {
      debugPrint('[game][complete] step=$name failed: $e');
      if (kDebugMode) {
        debugPrintStack(stackTrace: st);
      }
      return fallback;
    }
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
    if (_usesEnergySystem && !_attemptEnergyConsumed && _energyGateLocked) {
      return Duration.zero;
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

  bool get _isLiveDuelMode => widget.liveDuelArgs != null;

  bool get _isFriendChallengeMode => widget.friendChallengeArgs != null;

  bool get _isTutorialPack =>
      widget.packId.trim().toLowerCase() == OnboardingService.tutorialPackId;

  bool get _usesEnergySystem =>
      !_isLiveDuelMode && !_isFriendChallengeMode && !_isTutorialPack;

  String get _currentLevelId => '${widget.packId}_${widget.levelIndex}';

  String get _ghostUid {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isNotEmpty) return uid;
    return 'guest';
  }

  bool _isGhostEnabledForLevel(String levelId) {
    return levelId.trim().isNotEmpty;
  }

  void _toggleGhostMode() {
    setState(() {
      _ghostEnabled = !_ghostEnabled;
      _ghostModeSessionEnabled = _ghostEnabled;
    });
  }

  String _formatGhostTime(int ms) {
    if (ms <= 0) return '--.--s';
    final seconds = ms / 1000.0;
    return '${seconds.toStringAsFixed(2)}s';
  }

  Future<void> _loadGhostRunForLevel(String levelId) async {
    if (_isLiveDuelMode) return;
    if (!_isGhostEnabledForLevel(levelId)) {
      if (mounted) {
        setState(() {
          _ghostRun = null;
        });
      }
      return;
    }
    final run =
        await _ghostService.loadBestRun(uid: _ghostUid, levelId: levelId);
    if (!mounted) return;
    setState(() {
      _ghostRun = run;
    });
  }

  void _recordGhostFrame(List<int> path, {bool force = false}) {
    if (_isLiveDuelMode) return;
    final level = _level;
    if (level == null || path.isEmpty) return;
    final startedAt = _runStartedAt;
    if (startedAt == null) return;
    if (!_isGhostEnabledForLevel(_currentLevelId)) return;

    final nowMs = DateTime.now().difference(startedAt).inMilliseconds;
    final pos = _normalizedCellCenter(path.last, level.width, level.height);
    final minDeltaMs = force ? 0 : 24;
    final elapsedDelta = nowMs - _lastRecordedGhostSampleMs;
    final movedEnough = _lastRecordedGhostPos == null ||
        (pos - _lastRecordedGhostPos!).distance > 0.0005;
    if (!force && elapsedDelta < minDeltaMs && !movedEnough) {
      return;
    }

    _recordedGhostFrames.add(
      GhostFrame(
        timeMs: nowMs,
        x: pos.dx,
        y: pos.dy,
      ),
    );
    _lastRecordedGhostSampleMs = nowMs;
    _lastRecordedGhostPos = pos;
  }

  Offset _normalizedCellCenter(int cellIndex, int width, int height) {
    final row = cellIndex ~/ width;
    final col = cellIndex % width;
    final x = (col + 0.5) / width;
    final y = (row + 0.5) / height;
    return Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
  }

  Future<void> _persistGhostIfBest({
    required String levelId,
    required int elapsedMs,
  }) async {
    if (!_isGhostEnabledForLevel(levelId) || elapsedMs <= 0) return;
    if (_recordedGhostFrames.length < 2) {
      final fallbackPath = _status.path;
      if (fallbackPath.isEmpty) return;
      _recordGhostFrame(fallbackPath, force: true);
    }
    if (_recordedGhostFrames.length < 2) return;

    final run = GhostRun(
      levelId: levelId,
      totalTimeMs: elapsedMs,
      boardWidth: _level?.width ?? 0,
      boardHeight: _level?.height ?? 0,
      frames: List<GhostFrame>.unmodifiable(_recordedGhostFrames),
    );
    final improved = await _ghostService.saveBestRunIfBetter(
      uid: _ghostUid,
      run: run,
    );
    if (improved && mounted) {
      setState(() {
        _ghostRun = run;
      });
    }
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

  void _persistInProgressLevel(List<int> path) {
    final startedAt = _runStartedAt ?? DateTime.now();
    final snapshot = InProgressLevelSnapshot(
      path: List<int>.unmodifiable(path),
      startedAtMs: startedAt.millisecondsSinceEpoch,
      hintsUsed: _hintsUsed,
      rewindsUsed: _rewindsUsed,
      mistakesUsed: _mistakesUsed,
      energyConsumed: _attemptEnergyConsumed,
    );
    unawaited(
      widget.progressService.saveInProgressLevel(
        packId: widget.packId,
        levelIndex: widget.levelIndex,
        snapshot: snapshot,
      ),
    );
  }

  void _attachLiveMatchListener() {
    if (!_isLiveDuelMode) return;
    final args = widget.liveDuelArgs!;
    _liveMatchSub?.cancel();
    _liveMatchSub = _liveDuelService.watchMatch(args.matchId).listen((match) {
      if (!mounted) return;
      if (match == null) return;
      final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
      final opponentUid = match.opponentUid(uid);
      final opponent = opponentUid.isEmpty ? null : match.players[opponentUid];
      final opponentName = (opponent?.username.trim().isNotEmpty == true)
          ? opponent!.username.trim()
          : 'Opponent';
      final opponentState = _duelStateLabel(opponent?.state);
      final winnerUid = match.winnerUid.trim();
      final interactionLocked = match.status != LiveMatchStatus.playing ||
          winnerUid.isNotEmpty ||
          match.isTerminal;
      setState(() {
        _duelOpponentName = opponentName;
        _duelOpponentState = opponentState;
        _liveWinnerResolved = winnerUid.isNotEmpty;
        _liveLostBeforeFinish =
            _liveWinnerResolved && winnerUid != uid && !_completionHandled;
        _liveInteractionLocked = interactionLocked;
      });
      _attachLiveTrailListener(opponentUid);
      if (match.isTerminal) {
        unawaited(
          _liveDuelService.clearRealtimeTrail(
            matchId: args.matchId,
            state: 'stopped',
          ),
        );
      }
      if (match.status == LiveMatchStatus.finished) {
        _pushLiveEmoteDebug('match finished: emotes enabled');
        _attachLiveIncomingEmoteListener(matchId: match.id);
      } else {
        _pushLiveEmoteDebug('match status=${match.status.name}: emotes off');
        _detachLiveIncomingEmoteListener(clearUi: true);
      }
      if (match.status == LiveMatchStatus.finished) {
        unawaited(_handleLiveMatchFinished(match));
      }
    });
  }

  void _pushLiveEmoteDebug(String message) {
    if (!_showLiveEmoteDebugHud || !mounted) return;
    final now = DateTime.now();
    final stamp =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final line = '[$stamp] $message';
    setState(() {
      _liveEmoteDebugLines.add(line);
      if (_liveEmoteDebugLines.length > 6) {
        _liveEmoteDebugLines.removeRange(0, _liveEmoteDebugLines.length - 6);
      }
    });
  }

  Widget _buildLiveEmoteDebugHud() {
    if (!_showLiveEmoteDebugHud || _liveEmoteDebugLines.isEmpty) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: IgnorePointer(
        child: SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xCC0B1220),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF4A6A94)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'LIVE EMOTE DEBUG',
                      style: TextStyle(
                        color: Color(0xFF9FD0FF),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._liveEmoteDebugLines.map(
                      (line) => Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE2EEFF),
                          fontSize: 10.5,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _attachLiveIncomingEmoteListener({
    required String matchId,
  }) {
    if (!_isLiveDuelMode) return;
    final normalizedMatch = matchId.trim();
    if (normalizedMatch.isEmpty) return;
    if (_liveIncomingEmoteMatchId == normalizedMatch && _liveEmoteSub != null) {
      _pushLiveEmoteDebug('listener already attached match=$normalizedMatch');
      return;
    }
    _detachLiveIncomingEmoteListener(clearUi: false);
    _liveIncomingEmoteMatchId = normalizedMatch;
    _liveIncomingEmotePrimed = false;
    _pushLiveEmoteDebug('attach listener match=$normalizedMatch');
    _liveEmoteSub = _liveDuelService
        .watchMatchEmotes(normalizedMatch, limit: 6)
        .listen((items) {
      if (!mounted) return;
      final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
      if (uid.isEmpty) return;
      _pushLiveEmoteDebug(
        'snapshot items=${items.length} winnerResolved=$_liveWinnerResolved',
      );
      if (!_liveWinnerResolved) return;
      final firstSnapshot = !_liveIncomingEmotePrimed;
      if (firstSnapshot) {
        _liveIncomingEmotePrimed = true;
      }
      if (items.isEmpty) return;
      LiveMatchEmote? latestIncoming;
      for (final item in items) {
        final senderUid = item.sentByUid.trim();
        if (senderUid.isEmpty || senderUid == uid) continue;
        latestIncoming = item;
        break;
      }
      if (latestIncoming == null) {
        _pushLiveEmoteDebug('incoming skipped: all emotes are mine/empty');
        return;
      }
      if (firstSnapshot) {
        _liveIncomingEmoteLastId = latestIncoming.id;
        _pushLiveEmoteDebug(
            'primed with existing emote id=${latestIncoming.id}');
        return;
      }
      if (latestIncoming.id == _liveIncomingEmoteLastId) {
        _pushLiveEmoteDebug('incoming duplicate id=${latestIncoming.id}');
        return;
      }
      _liveIncomingEmoteLastId = latestIncoming.id;
      _pushLiveEmoteDebug(
        'incoming emote id=${latestIncoming.id} from=${latestIncoming.sentByUid.trim()}',
      );
      _showIncomingLiveEmote(latestIncoming);
    });
  }

  void _detachLiveIncomingEmoteListener({bool clearUi = false}) {
    _liveEmoteSub?.cancel();
    _liveEmoteSub = null;
    _liveIncomingEmoteMatchId = '';
    _liveIncomingEmotePrimed = false;
    _pushLiveEmoteDebug('detach listener clearUi=$clearUi');
    if (clearUi) {
      _clearLiveIncomingEmoteOverlay(log: false);
    }
  }

  void _showIncomingLiveEmote(LiveMatchEmote emote) {
    if (!mounted) return;
    final def = _duelEmoteById(emote.emoteId);
    final sender = emote.senderUsername.trim().isNotEmpty
        ? emote.senderUsername.trim()
        : _duelOpponentName;
    _pushLiveEmoteDebug('show overlay glyph=${def.glyph} sender=$sender');
    _showIncomingLiveEmoteOverlay(
      glyph: def.glyph,
      sender: sender,
      eventId: _liveIncomingEmoteLastId,
    );
  }

  void _showIncomingLiveEmoteOverlay({
    required String glyph,
    required String sender,
    required String eventId,
  }) {
    if (!mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _clearLiveIncomingEmoteOverlay();
    _liveIncomingEmoteEntry = OverlayEntry(
      builder: (overlayContext) {
        final shortest =
            MediaQuery.of(overlayContext).size.shortestSide.clamp(320.0, 560.0);
        final compact = shortest < 390;
        final emojiSize = compact ? 120.0 : 148.0;
        return Positioned.fill(
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black.withOpacity(0.46)),
                  Center(
                    child: ZoomIn(
                      key: ValueKey<String>('incoming_live_emote_$eventId'),
                      duration: const Duration(milliseconds: 260),
                      child: BounceInDown(
                        duration: const Duration(milliseconds: 420),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: compact ? 24 : 34,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 22 : 28,
                            vertical: compact ? 16 : 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E1E33).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(
                              compact ? 22 : 26,
                            ),
                            border: Border.all(
                              color: const Color(0xFF71E1FF),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF5FD8FF).withOpacity(0.42),
                                blurRadius: compact ? 24 : 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                glyph,
                                style: TextStyle(
                                  fontSize: emojiSize,
                                  height: 1,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0xFF79E7FF),
                                      blurRadius: 22,
                                    ),
                                  ],
                                ),
                              ),
                              if (sender.trim().isNotEmpty) ...[
                                SizedBox(height: compact ? 6 : 8),
                                Text(
                                  context.l10n.gameReacted(sender),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFFD8EEFF),
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 15 : 17,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_liveIncomingEmoteEntry!);
    _liveIncomingEmoteTimer = Timer(const Duration(milliseconds: 1450), () {
      _clearLiveIncomingEmoteOverlay();
    });
  }

  void _clearLiveIncomingEmoteOverlay({bool log = true}) {
    _liveIncomingEmoteTimer?.cancel();
    _liveIncomingEmoteTimer = null;
    _liveIncomingEmoteEntry?.remove();
    _liveIncomingEmoteEntry = null;
    if (log) {
      _pushLiveEmoteDebug('overlay hidden');
    }
  }

  Future<void> _handleLiveMatchFinished(LiveMatch match) async {
    if (!mounted) return;
    if (_liveResultSheetOpen) return;
    final key = '${match.id}:${match.winnerUid.trim()}:${match.reason.trim()}';
    if (_liveResultSheetShownKey == key) return;
    _liveResultSheetShownKey = key;
    final countedVersus = await _runCompletionStep<bool>(
          'progress.recordVersusMatchPlayed',
          () => widget.progressService.recordVersusMatchPlayed(match.id),
          fallback: false,
        ) ??
        false;
    if (countedVersus) {
      final versusUnlocked = await _runCompletionStep<AchievementDef?>(
        'achievements.unlockById(versus_20)',
        () => widget.achievementsService.unlockById('versus_20'),
      );
      if (versusUnlocked != null && mounted) {
        unawaited(
          GameToast.show(
            context,
            type: GameToastType.achievement,
            title: context.l10n.gameAchievementUnlocked,
            message: versusUnlocked.title,
            duration: const Duration(milliseconds: 2300),
          ),
        );
      }
    }
    await _maybeAnnounceLiveWinner(match);
    if (!mounted) return;
    _liveResultSheetOpen = true;
    try {
      await _showLiveDuelResultSheet(
        match,
        _currentElapsedDuration.inMilliseconds,
      );
    } finally {
      _liveResultSheetOpen = false;
    }
  }

  void _attachLiveTrailListener(String opponentUid) {
    if (!_isLiveDuelMode) return;
    final normalizedOpponent = opponentUid.trim();
    if (normalizedOpponent.isEmpty) {
      _liveTrailSub?.cancel();
      _liveTrailSub = null;
      _liveTrailSubscribedUid = '';
      if (_duelOpponentPath.isNotEmpty && mounted) {
        setState(() {
          _duelOpponentPath = const <int>[];
        });
      }
      return;
    }
    if (_liveTrailSubscribedUid == normalizedOpponent &&
        _liveTrailSub != null) {
      return;
    }
    _liveTrailSub?.cancel();
    _liveTrailSubscribedUid = normalizedOpponent;
    _liveTrailSub = _liveDuelService
        .watchRealtimeTrail(
      matchId: widget.liveDuelArgs!.matchId,
      uid: normalizedOpponent,
    )
        .listen((trail) {
      if (!mounted) return;
      final nextPath = trail?.pathCells ?? const <int>[];
      if (listEquals(nextPath, _duelOpponentPath)) return;
      setState(() {
        _duelOpponentPath = List<int>.unmodifiable(nextPath);
      });
    });
  }

  void _scheduleLiveTrailPublish(
    List<int> path, {
    String state = 'drawing',
  }) {
    if (!_isLiveDuelMode) return;
    final signature = path.join(',');
    if (signature == _lastLiveTrailPublishedSignature &&
        state == _pendingLiveTrailState) {
      return;
    }
    _pendingLiveTrailPath = List<int>.unmodifiable(path);
    _pendingLiveTrailState = state;
    _pendingLiveTrailSignature = signature;
    _liveTrailPublishTimer ??=
        Timer(const Duration(milliseconds: 120), _flushLiveTrailPublish);

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastLiveTrailPublishedAtMs >= 120) {
      _flushLiveTrailPublish();
    }
  }

  void _flushLiveTrailPublish([Timer? _]) {
    if (!_isLiveDuelMode) return;
    _liveTrailPublishTimer?.cancel();
    _liveTrailPublishTimer = null;

    final signature = _pendingLiveTrailSignature;
    if (signature.isEmpty) return;
    if (signature == _lastLiveTrailPublishedSignature) return;

    _lastLiveTrailPublishedAtMs = DateTime.now().millisecondsSinceEpoch;
    _lastLiveTrailPublishedSignature = signature;
    _liveTrailPublishVersion++;

    unawaited(
      _liveDuelService.publishRealtimeTrail(
        matchId: widget.liveDuelArgs!.matchId,
        pathCells: _pendingLiveTrailPath,
        state: _pendingLiveTrailState,
        pathVersion: _liveTrailPublishVersion,
      ),
    );
  }

  Future<void> _maybeAnnounceLiveWinner(LiveMatch match) async {
    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) return;
    final winnerUid = match.winnerUid.trim();
    if (winnerUid.isEmpty) return;
    final key = '${match.id}:$winnerUid';
    if (_liveWinnerAnnouncementKey == key) return;
    _liveWinnerAnnouncementKey = key;
    final won = winnerUid == uid;
    final l10n = context.l10n;
    final title = won ? l10n.gameDuelYouWonTitle : l10n.gameDuelYouLostTitle;
    final subtitle =
        won ? l10n.gameDuelYouFinishedFirst : l10n.gameDuelFriendFinishedFirst;
    _showLiveResultOverlay(
      title,
      subtitle: subtitle,
      emoji: won ? '\u{1F3C6}' : '\u{1F622}',
      won: won,
    );
    await GameToast.show(
      context,
      type: GameToastType.social,
      title: title,
      message: subtitle,
      duration: const Duration(milliseconds: 2200),
    );
  }

  void _showLiveResultOverlay(
    String title, {
    String subtitle = '',
    String emoji = '',
    required bool won,
  }) {
    _liveResultOverlayTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _liveResultOverlayTitle = title;
      _liveResultOverlaySubtitle = subtitle;
      _liveResultOverlayEmoji = emoji;
      _liveResultOverlayWin = won;
      _liveResultOverlayVisible = true;
    });
    _liveResultOverlayTimer = Timer(const Duration(milliseconds: 1950), () {
      if (!mounted) return;
      setState(() {
        _liveResultOverlayVisible = false;
      });
    });
  }

  Future<void> _reportLiveDuelFinish(int elapsedMs) async {
    if (!_isLiveDuelMode || _liveFinishReported || elapsedMs <= 0) return;
    try {
      await _liveDuelService.reportFinish(
        matchId: widget.liveDuelArgs!.matchId,
        elapsedMsFromStart: elapsedMs,
      );
      _liveFinishReported = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[duel] report finish failed match=${widget.liveDuelArgs!.matchId}: $e');
      }
    }
  }

  Future<void> _showLiveDuelResultSheet(LiveMatch match, int elapsedMs) async {
    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (match.status != LiveMatchStatus.finished) {
      await GameToast.show(
        context,
        type: GameToastType.info,
        title: context.l10n.liveDuelTitle,
        message: context.l10n.gameLiveDuelFinishedWaiting(
          _formatGhostTime(elapsedMs),
        ),
        duration: const Duration(milliseconds: 1900),
      );
      return;
    }
    final opponentUid = match.opponentUid(uid);
    final myPlayer = match.players[uid];
    final opponentPlayer = match.players[opponentUid];
    final winnerUid = match.winnerUid.trim();
    final reason = match.reason.trim();
    final myAbandoned = myPlayer?.state == LiveMatchPlayerState.abandoned;
    final oppAbandoned =
        opponentPlayer?.state == LiveMatchPlayerState.abandoned;

    final l10n = context.l10n;
    String title = l10n.gameLiveDuelResultTitle;
    String message = l10n.liveDuelDraw;
    if (myAbandoned) {
      title = l10n.liveDuelDefeat;
      message = l10n.liveDuelYouAbandoned;
    } else if (oppAbandoned) {
      title = l10n.liveDuelYouWonSmiley;
      message = l10n.gameOpponentAbandoned;
    } else if (winnerUid.isEmpty) {
      title = l10n.liveDuelDraw;
      message = reason == 'both_abandoned'
          ? l10n.liveDuelCancelled
          : l10n.liveDuelDraw;
    } else if (winnerUid == uid) {
      title = l10n.liveDuelYouWonSmiley;
      message = l10n.liveDuelYouWonDuel;
    } else {
      title = l10n.liveDuelDefeat;
      message = l10n.liveDuelYouLost;
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var rematchBusy = false;
        var sendingEmote = false;
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A2A45), Color(0xFF111C33)],
                  ),
                  border: Border.all(color: const Color(0xFF355687)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFAED2FF),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _duelResultRow(
                      l10n.liveDuelYourTime,
                      _formatGhostTime(
                        (myPlayer?.finishedAtMsFromStart ?? 0) > 0
                            ? (myPlayer?.finishedAtMsFromStart ?? 0)
                            : elapsedMs,
                      ),
                    ),
                    _duelResultRow(
                      l10n.liveDuelOpponentTime,
                      _formatGhostTime(
                          opponentPlayer?.finishedAtMsFromStart ?? 0),
                    ),
                    _duelResultRow(l10n.gameLevel, match.levelId),
                    _duelResultRow(
                      l10n.liveDuelOpponent,
                      opponentPlayer?.username.trim().isNotEmpty == true
                          ? opponentPlayer!.username.trim()
                          : l10n.gamePlayer,
                    ),
                    const SizedBox(height: 12),
                    _buildDuelEmoteTray(
                      matchId: match.id,
                      sending: sendingEmote,
                      onSendingChanged: (value) =>
                          setLocalState(() => sendingEmote = value),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: rematchBusy
                          ? null
                          : () async {
                              setLocalState(() => rematchBusy = true);
                              try {
                                final created =
                                    await _liveDuelService.createRematch(
                                  previousMatchId: match.id,
                                );
                                if (!sheetContext.mounted) return;
                                Navigator.of(sheetContext).pop();
                                if (!mounted) return;
                                context.go('/live-duel/${created.matchId}');
                              } catch (e) {
                                if (!sheetContext.mounted) return;
                                setLocalState(() => rematchBusy = false);
                                var err = l10n.liveDuelCouldNotCreateRematch;
                                final txt = e.toString();
                                if (txt.contains('ALREADY_IN_ACTIVE_DUEL')) {
                                  err = l10n.liveDuelFinishActiveFirst;
                                } else if (txt
                                    .contains('TARGET_IN_ACTIVE_DUEL')) {
                                  err = l10n.liveDuelOpponentBusyAnother;
                                }
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(content: Text(err)),
                                );
                              }
                            },
                      child: Text(
                        rematchBusy
                            ? l10n.liveDuelCreatingRematch
                            : l10n.liveDuelRematch,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        if (!mounted) return;
                        context.go('/play');
                      },
                      child: Text(l10n.liveDuelLeave),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDuelEmoteTray({
    required String matchId,
    required bool sending,
    required ValueChanged<bool> onSendingChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _duelEmotes.map((emote) {
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: sending
              ? null
              : () async {
                  onSendingChanged(true);
                  try {
                    await _sendDuelEmote(matchId: matchId, emoteId: emote.id);
                  } finally {
                    onSendingChanged(false);
                  }
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A43),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3F5E88)),
            ),
            child: Text(
              '${emote.glyph} ${emote.label}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  Future<void> _sendDuelEmote({
    required String matchId,
    required String emoteId,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastMs = _duelEmoteLastSentAtMs[matchId] ?? 0;
    if (lastMs > 0 && nowMs - lastMs < 1600) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.liveDuelEmoteCooldown),
          duration: const Duration(milliseconds: 900),
        ),
      );
      return;
    }
    try {
      await _liveDuelService.sendMatchEmote(
        matchId: matchId,
        emoteId: emoteId,
      );
      _duelEmoteLastSentAtMs[matchId] = nowMs;
      final def = _duelEmoteById(emoteId);
      _showIncomingLiveEmoteOverlay(
        glyph: def.glyph,
        sender: '',
        eventId: 'local_${nowMs}_$emoteId',
      );
      _pushLiveEmoteDebug('send emote ok id=$emoteId');
    } catch (e) {
      _pushLiveEmoteDebug('send emote fail id=$emoteId error=$e');
      if (!mounted) return;
      var msg = context.l10n.liveDuelCouldNotSendEmote;
      if (e.toString().contains('EMOTE_COOLDOWN')) {
        msg = context.l10n.liveDuelEmoteCooldown;
      } else if (e.toString().contains('EMOTES_DISABLED')) {
        msg = context.l10n.gameEmotesAfterDuelResult;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  List<_DuelEmoteDef> get _duelEmotes {
    final l10n = context.l10n;
    return <_DuelEmoteDef>[
      _DuelEmoteDef(
        id: 'laugh',
        label: l10n.gameEmoteLaugh,
        glyph: '\u{1F602}',
      ),
      _DuelEmoteDef(id: 'cool', label: l10n.gameEmoteCool, glyph: '\u{1F60E}'),
      _DuelEmoteDef(id: 'wow', label: l10n.gameEmoteWow, glyph: '\u{1F62E}'),
      _DuelEmoteDef(id: 'cry', label: l10n.gameEmoteCry, glyph: '\u{1F622}'),
      _DuelEmoteDef(
        id: 'clap',
        label: l10n.gameEmoteClap,
        glyph: '\u{1F44F}',
      ),
      _DuelEmoteDef(
        id: 'heart',
        label: l10n.gameEmoteHeart,
        glyph: '\u{2764}\u{FE0F}',
      ),
    ];
  }

  _DuelEmoteDef _duelEmoteById(String id) {
    for (final item in _duelEmotes) {
      if (item.id == id) return item;
    }
    return _DuelEmoteDef(
      id: 'wow',
      label: context.l10n.gameEmoteWow,
      glyph: '\u{1F62E}',
    );
  }

  Widget _duelResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9FB4D7),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _duelStateLabel(LiveMatchPlayerState? state) {
    final l10n = context.l10n;
    switch (state) {
      case LiveMatchPlayerState.finished:
        return l10n.liveDuelStateFinished;
      case LiveMatchPlayerState.abandoned:
        return l10n.liveDuelStateAbandoned;
      case LiveMatchPlayerState.playing:
        return l10n.liveDuelStatePlaying;
      case LiveMatchPlayerState.ready:
        return l10n.liveDuelStateReady;
      case LiveMatchPlayerState.joined:
        return l10n.liveDuelStateJoined;
      case LiveMatchPlayerState.invited:
        return l10n.liveDuelStateInvited;
      case null:
        return l10n.liveDuelWaitingPlayer;
    }
  }
}

class _DuelEmoteDef {
  const _DuelEmoteDef({
    required this.id,
    required this.label,
    required this.glyph,
  });

  final String id;
  final String label;
  final String glyph;
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
          color:
              highlighted ? const Color(0xFF5D8CFF) : const Color(0xFF32445F),
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
                    color: const Color(0xFF4C6FFF)
                        .withOpacity(isDark ? 0.12 : 0.07),
                    blurRadius: 52,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: const Color(0xFF1B2442)
                        .withOpacity(isDark ? 0.42 : 0.2),
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
    this.showRanking = true,
    this.compact = false,
    this.energyText,
    this.energySubtext,
  });

  final String levelText;
  final String timerText;
  final VoidCallback onBack;
  final int walletCoins;
  final VoidCallback onRankingTap;
  final VoidCallback onWalletTap;
  final bool showRanking;
  final bool compact;
  final String? energyText;
  final String? energySubtext;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 20.0 : 24.0;
    final levelFont = compact ? 14.0 : 15.0;
    final timerFont = compact ? 12.0 : 13.0;
    final gap = compact ? 8.0 : 10.0;
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF222734),
            foregroundColor: Colors.white,
            visualDensity: compact
                ? const VisualDensity(horizontal: -2, vertical: -2)
                : null,
          ),
          icon: Icon(Icons.arrow_back_rounded, size: iconSize),
        ),
        SizedBox(width: gap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                levelText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: levelFont,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: compact ? 1 : 2),
              Text(
                timerText,
                style: TextStyle(
                  color: Color(0xFF9FB0D3),
                  fontSize: timerFont,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if ((energyText ?? '').isNotEmpty) ...[
                SizedBox(height: compact ? 1 : 2),
                Text(
                  energyText!,
                  style: TextStyle(
                    color: const Color(0xFF9EE3B8),
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if ((energySubtext ?? '').isNotEmpty) ...[
                SizedBox(height: compact ? 1 : 2),
                Text(
                  energySubtext!,
                  style: TextStyle(
                    color: const Color(0xFF7FB89C),
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: compact ? 6 : 8),
        if (showRanking)
          IconButton(
            onPressed: onRankingTap,
            tooltip: context.l10n.gameFriendsRanking,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF243044),
              foregroundColor: const Color(0xFFFFD166),
              visualDensity: compact
                  ? const VisualDensity(horizontal: -2, vertical: -2)
                  : null,
            ),
            icon: Icon(Icons.emoji_events_rounded, size: compact ? 20 : 24),
          )
        else
          SizedBox(width: compact ? 34 : 40),
        SizedBox(width: compact ? 6 : 8),
        _WalletPill(coins: walletCoins, onTap: onWalletTap),
      ],
    );
  }
}

class _EnergyLockedBanner extends StatelessWidget {
  const _EnergyLockedBanner({
    required this.remainingText,
    required this.onOpenShop,
  });

  final String remainingText;
  final VoidCallback onOpenShop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1630),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFF8AA2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.battery_alert_rounded,
            size: 16,
            color: Color(0xFFFF98AE),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.gameEnergyEmptyResetIn(remainingText),
              style: const TextStyle(
                color: Color(0xFFFFD6DF),
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          TextButton(
            onPressed: onOpenShop,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFFC7D4),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(context.l10n.gameBatteries),
          ),
        ],
      ),
    );
  }
}

class _GhostRaceInfoBar extends StatelessWidget {
  const _GhostRaceInfoBar({
    required this.bestTimeText,
    required this.enabled,
    required this.onToggle,
  });

  final String bestTimeText;
  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF182338),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_rounded,
            size: 16,
            color: Color(0xFF8FB5FF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.gameGhostBest(bestTimeText),
              style: const TextStyle(
                color: Color(0xFFD7E5FF),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onToggle,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(86, 30),
            ),
            child: Text(
              enabled ? context.l10n.gameGhostOn : context.l10n.gameGhostOff,
              style: TextStyle(
                color:
                    enabled ? const Color(0xFF6DD6FF) : const Color(0xFF8FA6CF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GhostPendingInfoBar extends StatelessWidget {
  const _GhostPendingInfoBar({
    required this.enabled,
    required this.onToggle,
  });

  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF182338),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_rounded,
            size: 16,
            color: Color(0xFF8FB5FF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.gameGhostAvailableAfterFirst,
              style: const TextStyle(
                color: Color(0xFFB8C8E8),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
          TextButton(
            onPressed: onToggle,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(86, 30),
            ),
            child: Text(
              enabled ? context.l10n.gameGhostOn : context.l10n.gameGhostOff,
              style: TextStyle(
                color:
                    enabled ? const Color(0xFF6DD6FF) : const Color(0xFF8FA6CF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendChallengeInfoBar extends StatelessWidget {
  const _FriendChallengeInfoBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF28314C), Color(0xFF1B2238)],
        ),
        border: Border.all(color: const Color(0xFF4A5E8A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.sports_score_rounded,
            color: Color(0xFF89E6FF),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.friendChallengeTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            context.l10n.gameNoRankingImpact,
            style: const TextStyle(
              color: Color(0xFFB8CAE8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDuelStatusBar extends StatelessWidget {
  const _LiveDuelStatusBar({
    required this.opponentName,
    required this.opponentState,
    this.compact = false,
  });

  final String opponentName;
  final String opponentState;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173152), Color(0xFF112640)],
        ),
        border: Border.all(color: const Color(0xFF2F5D93)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_martial_arts_rounded,
            color: Color(0xFF7DE2FF),
            size: compact ? 16 : 18,
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Text(
              context.l10n.duelVersusOpponent(opponentName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 13 : 14,
              ),
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            opponentState,
            style: TextStyle(
              color: Color(0xFFA6D8FF),
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDuelResolvedBanner extends StatelessWidget {
  const _LiveDuelResolvedBanner({
    required this.text,
    this.compact = false,
  });

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF20293B),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: const Color(0xFF4C5E7D)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: compact ? 14 : 15,
            color: const Color(0xFFB8CAE8),
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Color(0xFFD6E4FF),
                fontSize: compact ? 11.5 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
  final VoidCallback? onTap;
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
          onTap: widget.visuallyEnabled ? widget.onTap : null,
          onTapDown: widget.visuallyEnabled
              ? (_) => setState(() => _scale = 0.97)
              : null,
          onTapUp:
              widget.visuallyEnabled ? (_) => setState(() => _scale = 1) : null,
          onTapCancel:
              widget.visuallyEnabled ? () => setState(() => _scale = 1) : null,
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
