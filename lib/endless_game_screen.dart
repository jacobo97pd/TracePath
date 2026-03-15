import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'adaptive_difficulty_service.dart';
import 'app_data.dart';
import 'achievements_service.dart';
import 'celebration_overlay.dart';
import 'engine/level.dart';
import 'game_board.dart';
import 'game_header.dart';
import 'game_theme.dart';
import 'progress_service.dart';
import 'score_calculator.dart';
import 'stats_service.dart';
import 'victory_screen.dart';
import 'ui/components/game_toast.dart';

class EndlessGameScreen extends StatefulWidget {
  const EndlessGameScreen({
    super.key,
    required this.difficulty,
    required this.index,
    required this.progressService,
    required this.statsService,
    required this.achievementsService,
    required this.adaptiveDifficultyService,
  });

  final int difficulty;
  final int index;
  final ProgressService progressService;
  final StatsService statsService;
  final AchievementsService achievementsService;
  final AdaptiveDifficultyService adaptiveDifficultyService;

  @override
  State<EndlessGameScreen> createState() => _EndlessGameScreenState();
}

class _EndlessGameScreenState extends State<EndlessGameScreen> {
  final GameBoardController _boardController = GameBoardController();
  Level? _level;
  late GameBoardStatus _status;
  int? _runSeed;
  bool _completionHandled = false;
  bool _showCelebration = false;
  DateTime? _runStartedAt;
  Duration? _elapsedAtSolve;
  int _rewindsUsed = 0;
  bool _isLoading = true;
  Object? _loadError;
  int _retryNonce = 0;
  Brightness? _cachedBrightness;
  GameTheme? _cachedTheme;
  String? _cachedThemeLevelId;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _status = const GameBoardStatus(
      path: [],
      nextRequiredNumber: 1,
      lastSequentialNumber: 0,
      maxNumber: 0,
      solved: false,
    );
    _initialize();
  }

  @override
  void didUpdateWidget(covariant EndlessGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.difficulty != widget.difficulty ||
        oldWidget.index != widget.index) {
      _initialize();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _boardController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final runSeed =
          await widget.progressService.ensureEndlessRun(widget.difficulty);
      await widget.progressService.setEndlessRunIndex(
        widget.difficulty,
        widget.index,
      );
      final adaptive = widget.adaptiveDifficultyService
          .paramsForDifficulty(widget.difficulty);
      final request = EndlessLevelRequest(
        difficulty: widget.difficulty,
        index: widget.index,
        runSeed: runSeed,
        difficultyOffset: adaptive.difficultyOffset,
        sizeDelta: adaptive.sizeDelta,
        numberReduction: adaptive.numberReduction,
        retryNonce: _retryNonce,
      );
      unawaited(
        endlessLevelRepository.warmUpPool(request),
      );
      final level = await endlessLevelRepository
          .getCurrentLevel(request)
          .timeout(const Duration(seconds: 12));
      if (!mounted) {
        return;
      }
      setState(() {
        _runSeed = runSeed;
        _level = level;
        _status = GameBoardStatus.fromPath(level, const []);
        _completionHandled = false;
        _runStartedAt = DateTime.now();
        _elapsedAtSolve = null;
        _rewindsUsed = 0;
        _cachedTheme = null;
        _cachedThemeLevelId = null;
        _isLoading = false;
      });
      _clockTimer?.cancel();
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
      });
      unawaited(
        endlessLevelRepository.warmUpPool(request),
      );
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
        appBar: AppBar(title: const Text('Endless')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null || level == null || _runSeed == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Endless')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load endless puzzle.'),
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
                    _initialize();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final gameTheme = _resolveTheme(context, level.id);
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
                    chipText: 'E${widget.difficulty}',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Run seed: $_runSeed'),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _handleUndo,
                      child: const Text('Undo'),
                    ),
                  ],
                ),
                if (_status.solved) const Text('Solved!'),
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
                          onInvalidMove: (_) => HapticFeedback.mediumImpact(),
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
                isDark: Theme.of(context).brightness == Brightness.dark,
                loop: true,
              ),
            ),
          ],
        ),
      ),
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
      if (kEnableSolvedDebugLogs && level != null) {
        final debug = GameBoardRules.solvedDebugData(level, status.path);
        debugPrint(
          '[SolvedDebug][endless:${widget.difficulty}:${widget.index}] '
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
    final breakdown = ScoreCalculator.calculate(
      ScoreInput(
        difficulty: level.difficulty,
        elapsedMs: _currentElapsedDuration.inMilliseconds,
        hintsUsed: 0,
        rewindsUsed: _rewindsUsed,
      ),
    );
    await widget.progressService.setBestEndlessScoreIfHigher(
      widget.difficulty,
      widget.index,
      breakdown.finalScore,
    );
    await widget.statsService.recordEndlessResult(
      difficulty: widget.difficulty,
      indexReached: widget.index,
      score: breakdown.finalScore,
      solveTimeMs: _currentElapsedDuration.inMilliseconds,
    );
    await widget.statsService.recordLevelCompleted(
      mode: SolveMode.endless,
      difficulty: level.difficulty,
      solveTimeMs: _currentElapsedDuration.inMilliseconds,
      hintsUsed: 0,
      rewindsUsed: _rewindsUsed,
    );
    await widget.adaptiveDifficultyService.recordOutcome(
      EndlessOutcome(
        timeMs: _currentElapsedDuration.inMilliseconds,
        hintsUsed: 0,
        rewindsUsed: _rewindsUsed,
        difficulty: widget.difficulty,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    final unlocked = await widget.achievementsService.evaluateAfterCompletion(
      mode: SolveMode.endless,
      difficulty: level.difficulty,
      solveTimeMs: _currentElapsedDuration.inMilliseconds,
      hintsUsed: 0,
      rewindsUsed: _rewindsUsed,
    );
    await widget.progressService.setEndlessRunIndex(
      widget.difficulty,
      widget.index + 1,
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

    final average = widget.statsService
        .averageTimeMsForDifficulty(level.difficulty)
        ?.round();
    final gameTheme = ThemeGenerator.generateTheme(
      seed: ThemeGenerator.seedFromLevelId(level.id),
      brightness: Theme.of(context).brightness,
    );
    final action = await context.push<String>(
      '/victory',
      extra: VictoryScreenArgs(
        zipNumber: widget.index,
        headline: defaultVictoryHeadline(breakdown.finalScore),
        timeText: _formatMs(_currentElapsedDuration.inMilliseconds),
        averageText: _formatMs(average),
        streak: widget.progressService.getDailyStreak(),
        primaryLabel: 'Next Level',
        primaryActionId: 'next',
        accentColor: gameTheme.pathColor,
        shareText:
            'Endless D${widget.difficulty} #${widget.index} in ${_formatMs(_currentElapsedDuration.inMilliseconds)}.',
        copyText:
            'Zip #${widget.index} - ${_formatMs(_currentElapsedDuration.inMilliseconds)} - Streak ${widget.progressService.getDailyStreak()} 🔥',
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
        context.go('/endless/${widget.difficulty}/${widget.index + 1}');
        break;
      case 'endless':
        setState(() {
          _showCelebration = false;
        });
        context.go('/endless');
        break;
      case 'replay':
        _boardController.reset();
        setState(() {
          _completionHandled = false;
          _status = GameBoardStatus.fromPath(_level!, const []);
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
        context.go('/endless');
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

  GameTheme _resolveTheme(BuildContext context, String levelId) {
    final brightness = Theme.of(context).brightness;
    if (_cachedTheme != null &&
        _cachedBrightness == brightness &&
        _cachedThemeLevelId == levelId) {
      return _cachedTheme!;
    }
    final next = ThemeGenerator.generateTheme(
      seed: ThemeGenerator.seedFromLevelId(levelId),
      brightness: brightness,
    );
    _cachedBrightness = brightness;
    _cachedThemeLevelId = levelId;
    _cachedTheme = next;
    return next;
  }
}
