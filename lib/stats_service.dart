import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_data.dart';
import 'pack_level_repository.dart';
import 'progress_service.dart';

enum SolveMode {
  campaign,
  daily,
  endless,
}

class DailyAttempt {
  const DailyAttempt({
    required this.timeMs,
    required this.hintsUsed,
    required this.rewindsUsed,
    required this.score,
    required this.timestamp,
  });

  final int timeMs;
  final int hintsUsed;
  final int rewindsUsed;
  final int score;
  final int timestamp;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'timeMs': timeMs,
      'hintsUsed': hintsUsed,
      'rewindsUsed': rewindsUsed,
      'score': score,
      'timestamp': timestamp,
    };
  }

  factory DailyAttempt.fromJson(Map<String, dynamic> json) {
    final rawScore = json['score'];
    return DailyAttempt(
      timeMs: json['timeMs'] as int,
      hintsUsed: json['hintsUsed'] as int,
      rewindsUsed: json['rewindsUsed'] as int,
      score: rawScore is int ? rawScore : 0,
      timestamp: json['timestamp'] as int,
    );
  }
}

class EndlessDifficultyBest {
  const EndlessDifficultyBest({
    required this.bestScore,
    required this.bestIndexReached,
    this.bestAvgTimeMs,
  });

  final int bestScore;
  final int bestIndexReached;
  final double? bestAvgTimeMs;
}

class DailyLeaderboardUpdate {
  const DailyLeaderboardUpdate({
    required this.attempt,
    required this.isPersonalBest,
    required this.rank,
  });

  final DailyAttempt attempt;
  final bool isPersonalBest;
  final int? rank;
}

class StatsService extends ChangeNotifier {
  StatsService(this._prefs, this._progressService) {
    _progressService.addListener(_onProgressChanged);
  }

  final SharedPreferences _prefs;
  final ProgressService _progressService;

  @override
  void dispose() {
    _progressService.removeListener(_onProgressChanged);
    super.dispose();
  }

  int get totalCampaignSolved {
    var count = 0;
    for (final key in _progressService.completedKeys) {
      final parts = key.split(':');
      if (parts.length != 2) continue;
      if (PackLevelRepository.instance.isPrecomputedPack(parts[0]) ||
          appPacks.any((pack) => pack.id == parts[0])) {
        count++;
      }
    }
    return count;
  }

  int get totalDailySolved => _progressService.totalDailySolved;

  int get totalEndlessSolved => _progressService.totalEndlessSolved;

  int get totalHintsUsed => _progressService.totalHintsUsed;

  int get totalRewindsUsed => _progressService.totalRewindsUsed;

  int get currentDailyStreak => _progressService.getDailyStreak();

  int get bestDailyStreak => _progressService.bestDailyStreak;

  int? bestTimeMsForDifficulty(int difficulty) {
    return _prefs.getInt(_bestTimeKey(difficulty));
  }

  double? averageTimeMsForDifficulty(int difficulty) {
    final total = _prefs.getInt(_totalTimeKey(difficulty)) ?? 0;
    final count = _prefs.getInt(_solveCountKey(difficulty)) ?? 0;
    if (count <= 0) {
      return null;
    }
    return total / count;
  }

  int endlessBestIndex(int difficulty) {
    final progressBest = _progressService.getEndlessBestIndex(difficulty);
    final localBest = _prefs.getInt(_endlessBestIndexKey(difficulty)) ?? 0;
    return progressBest > localBest ? progressBest : localBest;
  }

  EndlessDifficultyBest endlessBestForDifficulty(int difficulty) {
    return EndlessDifficultyBest(
      bestScore: _prefs.getInt(_endlessBestScoreKey(difficulty)) ?? 0,
      bestIndexReached: endlessBestIndex(difficulty),
      bestAvgTimeMs: _prefs.getDouble(_endlessBestAvgTimeKey(difficulty)),
    );
  }

  List<DailyAttempt> getDailyLeaderboard(String dateKey) {
    final raw =
        _prefs.getStringList(_dailyLeaderboardKey(dateKey)) ?? const <String>[];
    return raw
        .map((entry) {
          try {
            final decoded = jsonDecode(entry) as Map<String, dynamic>;
            return DailyAttempt.fromJson(decoded);
          } catch (_) {
            return null;
          }
        })
        .whereType<DailyAttempt>()
        .toList();
  }

  Future<DailyLeaderboardUpdate> recordDailyAttempt({
    required String dateKey,
    required DailyAttempt attempt,
  }) async {
    final attempts = <DailyAttempt>[
      ...getDailyLeaderboard(dateKey),
      attempt,
    ]..sort(_dailyAttemptCompare);

    final rankIndex =
        attempts.indexWhere((a) => a.timestamp == attempt.timestamp);
    final top10 = attempts.take(10).toList();
    await _prefs.setStringList(
      _dailyLeaderboardKey(dateKey),
      top10.map((a) => jsonEncode(a.toJson())).toList(),
    );

    notifyListeners();
    return DailyLeaderboardUpdate(
      attempt: attempt,
      isPersonalBest: rankIndex == 0,
      rank: rankIndex >= 0 && rankIndex < 10 ? rankIndex + 1 : null,
    );
  }

  Future<void> resetDailyLeaderboard(String dateKey) async {
    await _prefs.remove(_dailyLeaderboardKey(dateKey));
    notifyListeners();
  }

  Future<void> recordLevelCompleted({
    required SolveMode mode,
    required int difficulty,
    required int solveTimeMs,
    required int hintsUsed,
    required int rewindsUsed,
  }) async {
    await _progressService.addHintsUsed(hintsUsed);
    await _progressService.addRewindsUsed(rewindsUsed);

    final bestTimeKey = _bestTimeKey(difficulty);
    final currentBest = _prefs.getInt(bestTimeKey);
    if (currentBest == null || solveTimeMs < currentBest) {
      await _prefs.setInt(bestTimeKey, solveTimeMs);
    }

    final totalTime =
        (_prefs.getInt(_totalTimeKey(difficulty)) ?? 0) + solveTimeMs;
    final solveCount = (_prefs.getInt(_solveCountKey(difficulty)) ?? 0) + 1;
    await _prefs.setInt(_totalTimeKey(difficulty), totalTime);
    await _prefs.setInt(_solveCountKey(difficulty), solveCount);

    if (mode == SolveMode.endless) {
      await _progressService.incrementEndlessSolved();
    }

    notifyListeners();
  }

  Future<void> recordEndlessResult({
    required int difficulty,
    required int indexReached,
    required int score,
    required int solveTimeMs,
  }) async {
    final bestScoreKey = _endlessBestScoreKey(difficulty);
    final currentBestScore = _prefs.getInt(bestScoreKey) ?? 0;
    if (score > currentBestScore) {
      await _prefs.setInt(bestScoreKey, score);
    }

    final bestIndexKey = _endlessBestIndexKey(difficulty);
    final currentBestIndex = _prefs.getInt(bestIndexKey) ?? 0;
    if (indexReached > currentBestIndex) {
      await _prefs.setInt(bestIndexKey, indexReached);
    }

    final totalKey = _endlessTotalTimeKey(difficulty);
    final countKey = _endlessSolveCountKey(difficulty);
    final nextTotal = (_prefs.getInt(totalKey) ?? 0) + solveTimeMs;
    final nextCount = (_prefs.getInt(countKey) ?? 0) + 1;
    final nextAvg = nextTotal / nextCount;
    await _prefs.setInt(totalKey, nextTotal);
    await _prefs.setInt(countKey, nextCount);

    final bestAvgKey = _endlessBestAvgTimeKey(difficulty);
    final bestAvg = _prefs.getDouble(bestAvgKey);
    if (bestAvg == null || nextAvg < bestAvg) {
      await _prefs.setDouble(bestAvgKey, nextAvg);
    }

    notifyListeners();
  }

  String _bestTimeKey(int difficulty) => 'best_time_difficulty_$difficulty';

  String _totalTimeKey(int difficulty) => 'total_time_difficulty_$difficulty';

  String _solveCountKey(int difficulty) => 'solve_count_difficulty_$difficulty';

  String _dailyLeaderboardKey(String dateKey) => 'daily_leaderboard_$dateKey';

  String _endlessBestScoreKey(int difficulty) =>
      'endless_best_score_difficulty_$difficulty';

  String _endlessBestIndexKey(int difficulty) =>
      'endless_best_index_difficulty_$difficulty';

  String _endlessTotalTimeKey(int difficulty) =>
      'endless_total_time_difficulty_$difficulty';

  String _endlessSolveCountKey(int difficulty) =>
      'endless_solve_count_difficulty_$difficulty';

  String _endlessBestAvgTimeKey(int difficulty) =>
      'endless_best_avg_time_difficulty_$difficulty';

  int _dailyAttemptCompare(DailyAttempt a, DailyAttempt b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byTime = a.timeMs.compareTo(b.timeMs);
    if (byTime != 0) return byTime;
    final byHints = a.hintsUsed.compareTo(b.hintsUsed);
    if (byHints != 0) return byHints;
    return a.timestamp.compareTo(b.timestamp);
  }

  void _onProgressChanged() {
    notifyListeners();
  }
}
