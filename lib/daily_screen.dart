import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'app_data.dart';
import 'achievements_service.dart';
import 'celebration_overlay.dart';
import 'coins_service.dart';
import 'engine/level.dart';
import 'engine/seed_random.dart';
import 'game_board.dart';
import 'game_theme.dart';
import 'progress_service.dart';
import 'score_calculator.dart';
import 'services/daily_puzzle_service.dart';
import 'stats_service.dart';
import 'victory_screen.dart';
import 'l10n/l10n.dart';
import 'ui/components/game_toast.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({
    super.key,
    required this.progressService,
    required this.statsService,
    required this.achievementsService,
    this.coinsService,
  });

  final ProgressService progressService;
  final StatsService statsService;
  final AchievementsService achievementsService;
  final CoinsService? coinsService;

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final GameBoardController _boardController = GameBoardController();
  Level? _level;
  GameBoardStatus _status = const GameBoardStatus(
    path: [],
    nextRequiredNumber: 1,
    lastSequentialNumber: 0,
    maxNumber: 0,
    solved: false,
  );
  bool _isLoading = true;
  Object? _loadError;
  int _retryNonce = 0;
  bool _completionHandled = false;
  DateTime? _runStartedAt;
  Duration? _elapsedAtSolve;
  int _rewindsUsed = 0;
  bool _showCelebration = false;
  late String _dailyDateKey;
  late int _themeSeed;
  Brightness? _cachedBrightness;
  GameTheme? _cachedTheme;
  Timer? _clockTimer;
  DailyLeaderboardUpdate? _lastLeaderboardUpdate;
  static const int _autoRetryAttempts = 2;
  final DailyPuzzleService _dailyPuzzleService = DailyPuzzleService();

  @override
  void initState() {
    super.initState();
    _dailyDateKey = DailyPuzzleService.currentDailyKey();
    _themeSeed = hashString('daily-theme-$_dailyDateKey');
    _loadDailyLevel();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _boardController.dispose();
    super.dispose();
  }

  Future<void> _loadDailyLevel() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    Object? lastError;
    for (var attempt = 0; attempt < _autoRetryAttempts; attempt++) {
      try {
        final level = await loadDailyLevelAsync(
          retryNonce: _retryNonce + attempt,
        ).timeout(
          Duration(seconds: 12 + (attempt * 4)),
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _level = level;
          _status = GameBoardStatus.fromPath(level, const []);
          _runStartedAt = DateTime.now();
          _elapsedAtSolve = null;
          _completionHandled = false;
          _rewindsUsed = 0;
          _isLoading = false;
        });
        _clockTimer?.cancel();
        _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          final nextKey = DailyPuzzleService.currentDailyKey();
          if (nextKey != _dailyDateKey) {
            _handleDailyCycleRollover(nextKey);
            return;
          }
          setState(() {});
        });
        return;
      } catch (error) {
        lastError = error;
        if (attempt < _autoRetryAttempts - 1) {
          await Future<void>.delayed(const Duration(milliseconds: 450));
        }
      }
    }
    try {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = lastError ?? context.l10n.dailyUnknownLoadError;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.dailyTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null || level == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.dailyTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.dailyLoadError),
                if (kDebugMode && _loadError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _loadError.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _retryNonce++;
                    });
                    _loadDailyLevel();
                  },
                  child: Text(context.l10n.dailyRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final gameTheme = _resolveTheme(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation:
          Listenable.merge([widget.progressService, widget.statsService]),
      builder: (context, child) {
        final streak = widget.progressService.getDailyStreak();
        final completedToday =
            widget.progressService.isDailyCompletedForKey(_dailyDateKey);
        final leaderboard =
            widget.statsService.getDailyLeaderboard(_dailyDateKey);
        final bestAttempt = leaderboard.isEmpty ? null : leaderboard.first;

        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final nextPuzzleIn = _timeUntilNextDailyPuzzle();
                final formattedDate = _formatDailyDate(
                  DateTime.now(),
                  Localizations.localeOf(context).languageCode,
                );

                return Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF0B1430),
                            Color(0xFF0A1B3C),
                            Color(0xFF071128),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color(0xFF14284D),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/');
                                  }
                                },
                                icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.dailyChallengeTitle,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        color: Color(0xFF9EB2D9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14274A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF335B9B),
                                width: 1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2A4B8FFF),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Text(
                              context.l10n.dailyNextPuzzleIn(
                                _formatCountdown(nextPuzzleIn),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _DailyInfoCard(
                                  label: context.l10n.dailyRewardLabel,
                                  value: context.l10n.dailyCoinsReward(
                                    DailyPuzzleService.dailyRewardCoins,
                                  ),
                                  accent: const Color(0xFF4E8CFF),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DailyInfoCard(
                                  label: context.l10n.dailyStreakLabel,
                                  value: '$streak',
                                  accent: const Color(0xFF4AE0C5),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DailyInfoCard(
                                  label: context.l10n.dailyBestTimeLabel,
                                  value: _formatMs(bestAttempt?.timeMs),
                                  accent: const Color(0xFF6E8BFF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 620),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0E1D3A),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: const Color(0xFF2F4E80),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: gameTheme.pathColor
                                              .withOpacity(0.2),
                                          blurRadius: 26,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: GameBoard(
                                        controller: _boardController,
                                        level: level,
                                        gameTheme: gameTheme,
                                        onStatusChanged: _handleStatusChanged,
                                        onChange: _handleBoardChange,
                                        onInvalidMove: (_) =>
                                            HapticFeedback.mediumImpact(),
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
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: const Color(0xFF4E8CFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    if (completedToday || _status.solved) {
                                      _handleReset();
                                    }
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: Text(
                                    completedToday || _status.solved
                                        ? context.l10n.dailyPlayAgain
                                        : context.l10n.dailyPlayDaily,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(
                                      color: Color(0xFF3E5A87)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _handleUndo,
                                child: const Icon(
                                  Icons.undo_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            context.l10n.dailyAttemptsSummary(
                              leaderboard.length,
                              '${bestAttempt?.score ?? '--'}',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF9EB2D9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_lastLeaderboardUpdate?.isPersonalBest == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                context.l10n.dailyNewPersonalBestToday,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF89E2C8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _handleReset() {
    HapticFeedback.selectionClick();
    setState(() {
      _runStartedAt = DateTime.now();
      _elapsedAtSolve = null;
      _rewindsUsed = 0;
    });
    _boardController.reset();
  }

  void _handleUndo() {
    HapticFeedback.selectionClick();
    _boardController.undo();
  }

  void _handleBoardChange(GameBoardChange change) {
    switch (change.type) {
      case GameBoardChangeType.add:
        HapticFeedback.selectionClick();
        break;
      case GameBoardChangeType.backtrack:
      case GameBoardChangeType.rewind:
        setState(() {
          _rewindsUsed++;
        });
        HapticFeedback.selectionClick();
        break;
      case GameBoardChangeType.undo:
        HapticFeedback.selectionClick();
        break;
      case GameBoardChangeType.reset:
        break;
    }
  }

  void _handleDailyCycleRollover(String newKey) {
    if (kDebugMode) {
      debugPrint('[daily] cycle rollover old=$_dailyDateKey new=$newKey');
    }
    setState(() {
      _dailyDateKey = newKey;
      _themeSeed = hashString('daily-theme-$_dailyDateKey');
      _completionHandled = false;
      _showCelebration = false;
      _elapsedAtSolve = null;
      _rewindsUsed = 0;
    });
    unawaited(_loadDailyLevel());
  }

  void _handleStatusChanged(GameBoardStatus status) {
    final level = _level;
    if (level == null) {
      return;
    }
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
      if (kEnableSolvedDebugLogs) {
        final debug = GameBoardRules.solvedDebugData(level, status.path);
        debugPrint(
          '[SolvedDebug][daily] '
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
    try {
      await _showCompletionDialog();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[daily] completion flow crashed: $e');
        debugPrint('$st');
      }
      if (!mounted) return;
      setState(() {
        _showCelebration = false;
      });
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.info,
          title: context.l10n.dailyCompletedTitle,
          message: context.l10n.dailySavedWithPartialSync,
          duration: const Duration(milliseconds: 2600),
        ),
      );
    }
  }

  Future<void> _showCompletionDialog() async {
    final level = _level;
    if (level == null) {
      return;
    }
    var rewardResult = const DailyRewardClaimResult(
      granted: false,
      alreadyClaimed: false,
    );
    try {
      await widget.progressService.markDailyCompletedForKey(_dailyDateKey);
      rewardResult = await _dailyPuzzleService.claimDailyRewardOnce(
        dailyKey: _dailyDateKey,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[daily] reward/persist error key=$_dailyDateKey error=$e');
        debugPrint('$st');
      }
      if (mounted) {
        unawaited(
          GameToast.show(
            context,
            type: GameToastType.info,
            title: context.l10n.dailyCompletedTitle,
            message: context.l10n.dailyRewardSyncFailed,
            duration: const Duration(milliseconds: 2400),
          ),
        );
      }
    }
    if (rewardResult.granted &&
        rewardResult.newCoinsBalance != null &&
        widget.coinsService != null) {
      await widget.coinsService!.syncCoinsFromRemote(
        rewardResult.newCoinsBalance!,
      );
    }
    var unlocked = <dynamic>[];
    try {
      await widget.statsService.recordLevelCompleted(
        mode: SolveMode.daily,
        difficulty: level.difficulty,
        solveTimeMs: _currentElapsedDuration.inMilliseconds,
        hintsUsed: 0,
        rewindsUsed: _rewindsUsed,
      );
      unlocked = await widget.achievementsService.evaluateAfterCompletion(
        mode: SolveMode.daily,
        difficulty: level.difficulty,
        solveTimeMs: _currentElapsedDuration.inMilliseconds,
        hintsUsed: 0,
        rewindsUsed: _rewindsUsed,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
            '[daily] stats/achievements error key=$_dailyDateKey error=$e');
        debugPrint('$st');
      }
    }
    final score = ScoreCalculator.calculate(
      ScoreInput(
        difficulty: level.difficulty,
        elapsedMs: _currentElapsedDuration.inMilliseconds,
        hintsUsed: 0,
        rewindsUsed: _rewindsUsed,
      ),
    ).finalScore;
    try {
      await widget.progressService
          .setBestDailyScoreIfHigher(_dailyDateKey, score);
      final leaderboardUpdate = await widget.statsService.recordDailyAttempt(
        dateKey: _dailyDateKey,
        attempt: DailyAttempt(
          timeMs: _currentElapsedDuration.inMilliseconds,
          hintsUsed: 0,
          rewindsUsed: _rewindsUsed,
          score: score,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      if (mounted) {
        setState(() {
          _lastLeaderboardUpdate = leaderboardUpdate;
        });
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint(
            '[daily] leaderboard write error key=$_dailyDateKey error=$e');
        debugPrint('$st');
      }
    }
    if (!mounted) {
      return;
    }
    if (unlocked.isNotEmpty) {
      final first = unlocked.first;
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.achievement,
          title: context.l10n.dailyAchievementUnlocked,
          message: first.title,
          duration: const Duration(milliseconds: 2300),
        ),
      );
    }
    if (rewardResult.granted) {
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.coins,
          title: context.l10n.dailyRewardToastTitle,
          message: context.l10n.dailyRewardToastMessage(
            DailyPuzzleService.dailyRewardCoins,
          ),
          duration: const Duration(milliseconds: 1900),
        ),
      );
    }

    final streak = widget.progressService.getDailyStreak();
    final average = widget.statsService
        .averageTimeMsForDifficulty(level.difficulty)
        ?.round();
    final gameTheme = ThemeGenerator.generateTheme(
      seed: _themeSeed,
      brightness: Theme.of(context).brightness,
    );
    final action = await context.push<String>(
      '/victory',
      extra: VictoryScreenArgs(
        zipNumber: level.difficulty * 100 + DateTime.now().day,
        headline: defaultVictoryHeadline(context, score),
        timeText: _formatMs(_currentElapsedDuration.inMilliseconds),
        averageText: _formatMs(average),
        streak: streak,
        primaryLabel: context.l10n.dailyPlayAgain,
        primaryActionId: 'replay',
        accentColor: gameTheme.pathColor,
        shareText: context.l10n.dailyShareText(
          _formatMs(_currentElapsedDuration.inMilliseconds),
        ),
        copyText: context.l10n.dailyCopyText(
          DateTime.now().day,
          _formatMs(_currentElapsedDuration.inMilliseconds),
          streak,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    switch (action) {
      case 'home':
        setState(() {
          _showCelebration = false;
        });
        context.go('/');
        break;
      case 'replay':
        _boardController.reset();
        setState(() {
          _completionHandled = false;
          _status = GameBoardStatus.fromPath(level, const []);
          _runStartedAt = DateTime.now();
          _elapsedAtSolve = null;
          _rewindsUsed = 0;
          _showCelebration = false;
        });
        break;
      default:
        setState(() {
          _showCelebration = false;
        });
        context.go('/');
        break;
    }
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

  String _formatMs(int? ms) {
    if (ms == null || ms <= 0) {
      return '--:--';
    }
    final seconds = (ms / 1000).round();
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Duration _timeUntilNextDailyPuzzle() {
    return DailyPuzzleService.timeUntilNextReset();
  }

  String _formatCountdown(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hh = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final mm = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final ss = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  String _formatDailyDate(DateTime date, String locale) {
    return DateFormat.yMMMMd(locale).format(date);
  }

  GameTheme _resolveTheme(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (_cachedTheme != null && _cachedBrightness == brightness) {
      return _cachedTheme!;
    }
    final next = ThemeGenerator.generateTheme(
      seed: _themeSeed,
      brightness: brightness,
    );
    _cachedBrightness = brightness;
    _cachedTheme = next;
    return next;
  }
}

class _DailyInfoCard extends StatelessWidget {
  const _DailyInfoCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF152746),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2E4973), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFA7B9DA),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
