import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'app_data.dart';
import 'achievements_service.dart';
import 'celebration_overlay.dart';
import 'engine/level.dart';
import 'engine/seed_random.dart';
import 'game_board.dart';
import 'game_header.dart';
import 'game_theme.dart';
import 'progress_service.dart';
import 'score_calculator.dart';
import 'stats_service.dart';
import 'victory_screen.dart';
import 'ui/components/game_toast.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({
    super.key,
    required this.progressService,
    required this.statsService,
    required this.achievementsService,
  });

  final ProgressService progressService;
  final StatsService statsService;
  final AchievementsService achievementsService;

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
  late final String _dailyDateKey;
  late final int _themeSeed;
  Brightness? _cachedBrightness;
  GameTheme? _cachedTheme;
  Timer? _clockTimer;
  DailyLeaderboardUpdate? _lastLeaderboardUpdate;

  @override
  void initState() {
    super.initState();
    _dailyDateKey = getTodayString();
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
    try {
      final level = await loadDailyLevelAsync(
        retryNonce: _retryNonce,
      ).timeout(
        const Duration(seconds: 12),
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
        setState(() {});
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null || level == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load daily puzzle.'),
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
                  child: const Text('Retry'),
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
        final completedToday = widget.progressService.isDailyCompleted();
        final leaderboard =
            widget.statsService.getDailyLeaderboard(_dailyDateKey);
        final bestAttempt = leaderboard.isEmpty ? null : leaderboard.first;

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: GameHeader(
                        timerText:
                            _formatMs(_currentElapsedDuration.inMilliseconds),
                        chipText: 'D1',
                        nextText: _status.nextRequiredNumber.toString(),
                        starsText: '★★★',
                        onBack: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                        onHome: () => context.go('/'),
                        onClear: _handleReset,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Streak: $streak'),
                    ),
                    if (completedToday || _status.solved)
                      const Text('Completed Today'),
                    Text(
                      bestAttempt == null
                          ? "Today's best: --"
                          : "Today's best: ${bestAttempt.score} (${_formatMs(bestAttempt.timeMs)})",
                    ),
                    if (_lastLeaderboardUpdate?.isPersonalBest == true)
                      const Text('Personal best!'),
                    if (_status.path.length == level.width * level.height &&
                        !_status.solved)
                      const Text('Not solved yet'),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _handleUndo,
                          child: const Text('Undo'),
                        ),
                      ],
                    ),
                    if (leaderboard.isNotEmpty)
                      SizedBox(
                        height: 150,
                        child: ListView.builder(
                          itemCount: leaderboard.length,
                          itemBuilder: (context, index) {
                            final attempt = leaderboard[index];
                            final isBest = index == 0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Text(
                                '#${index + 1} ${attempt.score} pts  '
                                '${_formatMs(attempt.timeMs)}  '
                                'h:${attempt.hintsUsed} r:${attempt.rewindsUsed}'
                                '${isBest ? "  (PB)" : ""}',
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: AspectRatio(
                            aspectRatio: 1,
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
                  ],
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
    await _showCompletionDialog();
  }

  Future<void> _showCompletionDialog() async {
    final level = _level;
    if (level == null) {
      return;
    }
    await widget.progressService.markDailyCompleted();
    await widget.statsService.recordLevelCompleted(
      mode: SolveMode.daily,
      difficulty: level.difficulty,
      solveTimeMs: _currentElapsedDuration.inMilliseconds,
      hintsUsed: 0,
      rewindsUsed: _rewindsUsed,
    );
    final unlocked = await widget.achievementsService.evaluateAfterCompletion(
      mode: SolveMode.daily,
      difficulty: level.difficulty,
      solveTimeMs: _currentElapsedDuration.inMilliseconds,
      hintsUsed: 0,
      rewindsUsed: _rewindsUsed,
    );
    final score = ScoreCalculator.calculate(
      ScoreInput(
        difficulty: level.difficulty,
        elapsedMs: _currentElapsedDuration.inMilliseconds,
        hintsUsed: 0,
        rewindsUsed: _rewindsUsed,
      ),
    ).finalScore;
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
        headline: defaultVictoryHeadline(score),
        timeText: _formatMs(_currentElapsedDuration.inMilliseconds),
        averageText: _formatMs(average),
        streak: streak,
        primaryLabel: 'Play Again',
        primaryActionId: 'replay',
        accentColor: gameTheme.pathColor,
        shareText:
            'Daily complete in ${_formatMs(_currentElapsedDuration.inMilliseconds)}.',
        copyText:
            'Zip #${DateTime.now().day} - ${_formatMs(_currentElapsedDuration.inMilliseconds)} - Streak $streak 🔥',
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
