import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_data.dart';
import 'engine/seed_random.dart';

class ProgressService extends ChangeNotifier {
  ProgressService(this._prefs) {
    _completed = _prefs.getStringList(_completedKey)?.toSet() ?? <String>{};
  }

  static const String _completedKey = 'completed_levels';
  static const String _dailyLastCompletedKey = 'daily_last_completed_date';
  static const String _dailyStreakKey = 'daily_streak';
  static const String _dailyBestStreakKey = 'best_daily_streak';
  static const String _dailySolvedCountKey = 'daily_solved_count';
  static const String _endlessSolvedCountKey = 'endless_solved_count';
  static const String _totalHintsUsedKey = 'total_hints_used';
  static const String _totalRewindsUsedKey = 'total_rewinds_used';

  final SharedPreferences _prefs;
  late Set<String> _completed;
  Map<int, int>? _solvedByDifficultyCache;

  UnmodifiableSetView<String> get completedKeys {
    return UnmodifiableSetView(_completed);
  }

  bool isCompleted(String packId, int levelIndex) {
    return _completed.contains(_key(packId, levelIndex));
  }

  Future<void> markCompleted(String packId, int levelIndex) async {
    final key = _key(packId, levelIndex);
    if (_completed.contains(key)) {
      return;
    }

    _completed = {..._completed, key};
    await _prefs.setStringList(_completedKey, _completed.toList()..sort());
    _solvedByDifficultyCache = null;
    notifyListeners();
  }

  String? get lastDailyCompletedDate {
    return _prefs.getString(_dailyLastCompletedKey);
  }

  int get totalDailySolved {
    return _prefs.getInt(_dailySolvedCountKey) ?? 0;
  }

  int get totalEndlessSolved {
    return _prefs.getInt(_endlessSolvedCountKey) ?? 0;
  }

  int get totalHintsUsed {
    return _prefs.getInt(_totalHintsUsedKey) ?? 0;
  }

  int get totalRewindsUsed {
    return _prefs.getInt(_totalRewindsUsedKey) ?? 0;
  }

  int get bestDailyStreak {
    return _prefs.getInt(_dailyBestStreakKey) ?? 0;
  }

  int get totalCampaignSolved {
    return _completed.length;
  }

  int get classicSolvedCount {
    return _completed.where((key) => key.startsWith('classic:')).length;
  }

  Map<int, int> get solvedByDifficultyCounts {
    final cached = _solvedByDifficultyCache;
    if (cached != null) {
      return Map<int, int>.from(cached);
    }
    final counts = <int, int>{};
    for (final key in _completed) {
      final parts = key.split(':');
      if (parts.length != 2) {
        continue;
      }
      final levelIndex = int.tryParse(parts[1]);
      if (levelIndex == null) {
        continue;
      }
      final difficulty = campaignLevelDifficulty(parts[0], levelIndex);
      counts[difficulty] = (counts[difficulty] ?? 0) + 1;
    }
    _solvedByDifficultyCache = Map<int, int>.from(counts);
    return counts;
  }

  int solvedAtOrAboveDifficultyCount(int threshold) {
    var total = 0;
    final byDifficulty = solvedByDifficultyCounts;
    for (final entry in byDifficulty.entries) {
      if (entry.key >= threshold) {
        total += entry.value;
      }
    }
    return total;
  }

  bool isPackUnlocked(String packId) {
    final pack = getPackById(packId);
    if (pack == null) {
      return false;
    }
    final req = pack.unlockRequirements;
    if (req.isAlwaysUnlocked) {
      return true;
    }
    final classicOk = classicSolvedCount >= req.requiredClassicLevels;
    final totalOk = totalCampaignSolved >= req.requiredTotalCampaignLevels;
    final difficultyOk =
        solvedAtOrAboveDifficultyCount(req.difficultyThreshold) >=
            req.requiredAtOrAboveDifficulty;
    return classicOk && totalOk && difficultyOk;
  }

  String packUnlockRequirementText(String packId) {
    final pack = getPackById(packId);
    if (pack == null) {
      return 'Pack not available';
    }
    if (isPackUnlocked(packId)) {
      return 'Unlocked';
    }
    final req = pack.unlockRequirements;
    final parts = <String>[];
    if (req.requiredClassicLevels > 0) {
      parts.add('Classic $classicSolvedCount/${req.requiredClassicLevels}');
    }
    if (req.requiredTotalCampaignLevels > 0) {
      parts.add(
        'Campaign $totalCampaignSolved/${req.requiredTotalCampaignLevels}',
      );
    }
    if (req.requiredAtOrAboveDifficulty > 0) {
      final solvedAtThreshold =
          solvedAtOrAboveDifficultyCount(req.difficultyThreshold);
      parts.add(
        'D${req.difficultyThreshold}+ $solvedAtThreshold/${req.requiredAtOrAboveDifficulty}',
      );
    }
    return 'Unlock: ${parts.join(' | ')}';
  }

  int getDailyStreak({DateTime? now}) {
    final last = lastDailyCompletedDate;
    if (last == null) {
      return 0;
    }

    final lastDate = _parseDate(last);
    if (lastDate == null) {
      return 0;
    }

    final today = _dateOnly(now ?? DateTime.now());
    final diffDays = today.difference(lastDate).inDays;
    final stored = _prefs.getInt(_dailyStreakKey) ?? 0;
    if (diffDays <= 1) {
      return stored;
    }
    if (stored != 0) {
      _prefs.setInt(_dailyStreakKey, 0);
    }
    return 0;
  }

  bool isDailyCompleted({DateTime? now}) {
    return lastDailyCompletedDate == getTodayString(now: now);
  }

  Future<void> markDailyCompleted({DateTime? now}) async {
    final date = _dateOnly(now ?? DateTime.now());
    final todayKey = getTodayString(now: date);
    if (lastDailyCompletedDate == todayKey) {
      return;
    }

    var nextStreak = 1;
    final previous = lastDailyCompletedDate;
    if (previous != null) {
      final previousDate = _parseDate(previous);
      if (previousDate != null && date.difference(previousDate).inDays == 1) {
        nextStreak = (_prefs.getInt(_dailyStreakKey) ?? 0) + 1;
      }
    }

    await _prefs.setString(_dailyLastCompletedKey, todayKey);
    await _prefs.setInt(_dailyStreakKey, nextStreak);
    if (nextStreak > bestDailyStreak) {
      await _prefs.setInt(_dailyBestStreakKey, nextStreak);
    }
    await _prefs.setInt(_dailySolvedCountKey, totalDailySolved + 1);
    notifyListeners();
  }

  Future<void> incrementEndlessSolved() async {
    await _prefs.setInt(_endlessSolvedCountKey, totalEndlessSolved + 1);
    notifyListeners();
  }

  Future<void> addHintsUsed(int count) async {
    if (count <= 0) return;
    await _prefs.setInt(_totalHintsUsedKey, totalHintsUsed + count);
    notifyListeners();
  }

  Future<void> addRewindsUsed(int count) async {
    if (count <= 0) return;
    await _prefs.setInt(_totalRewindsUsedKey, totalRewindsUsed + count);
    notifyListeners();
  }

  int? getEndlessRunSeed(int difficulty) {
    return _prefs.getInt(_endlessSeedKey(difficulty));
  }

  int getEndlessRunIndex(int difficulty) {
    return _prefs.getInt(_endlessIndexKey(difficulty)) ?? 1;
  }

  int getEndlessBestIndex(int difficulty) {
    return _prefs.getInt(_endlessBestKey(difficulty)) ?? 0;
  }

  Future<int> ensureEndlessRun(int difficulty) async {
    final existing = getEndlessRunSeed(difficulty);
    if (existing != null) {
      return existing;
    }

    final runSeed = hashString(
      'endless-run-$difficulty-${DateTime.now().microsecondsSinceEpoch}',
    );
    await _prefs.setInt(_endlessSeedKey(difficulty), runSeed);
    await _prefs.setInt(_endlessIndexKey(difficulty), 1);
    notifyListeners();
    return runSeed;
  }

  Future<int> restartEndlessRun(int difficulty) async {
    final runSeed = hashString(
      'endless-run-$difficulty-${DateTime.now().microsecondsSinceEpoch}',
    );
    await _prefs.setInt(_endlessSeedKey(difficulty), runSeed);
    await _prefs.setInt(_endlessIndexKey(difficulty), 1);
    notifyListeners();
    return runSeed;
  }

  Future<void> setEndlessRunIndex(int difficulty, int index) async {
    await _prefs.setInt(_endlessIndexKey(difficulty), index);
    final best = getEndlessBestIndex(difficulty);
    if (index > best) {
      await _prefs.setInt(_endlessBestKey(difficulty), index);
    }
    notifyListeners();
  }

  String _key(String packId, int levelIndex) {
    return '$packId:$levelIndex';
  }

  String _endlessSeedKey(int difficulty) {
    return 'endless_run_seed_$difficulty';
  }

  String _endlessIndexKey(int difficulty) {
    return 'endless_run_index_$difficulty';
  }

  String _endlessBestKey(int difficulty) {
    return 'endless_best_index_$difficulty';
  }

  int getBestScore(String packId, int levelIndex) {
    return getBestCampaignScore(packId, levelIndex);
  }

  Future<bool> setBestScoreIfHigher(
    String packId,
    int levelIndex,
    int score,
  ) async {
    return setBestCampaignScoreIfHigher(packId, levelIndex, score);
  }

  int getBestCampaignScore(String packId, int levelIndex) {
    final key = _bestScoreKey('campaign', '$packId:$levelIndex');
    return _prefs.getInt(key) ?? 0;
  }

  Future<bool> setBestCampaignScoreIfHigher(
    String packId,
    int levelIndex,
    int score,
  ) async {
    final key = _bestScoreKey('campaign', '$packId:$levelIndex');
    final current = _prefs.getInt(key) ?? 0;
    if (score <= current) {
      return false;
    }
    await _prefs.setInt(key, score);
    notifyListeners();
    return true;
  }

  int getBestDailyScore(String dateKey) {
    final key = _bestScoreKey('daily', dateKey);
    return _prefs.getInt(key) ?? 0;
  }

  Future<bool> setBestDailyScoreIfHigher(String dateKey, int score) async {
    final key = _bestScoreKey('daily', dateKey);
    final current = _prefs.getInt(key) ?? 0;
    if (score <= current) {
      return false;
    }
    await _prefs.setInt(key, score);
    notifyListeners();
    return true;
  }

  int getBestEndlessScore(int difficulty, int levelIndex) {
    final key = _bestScoreKey('endless', '$difficulty:$levelIndex');
    return _prefs.getInt(key) ?? 0;
  }

  Future<bool> setBestEndlessScoreIfHigher(
    int difficulty,
    int levelIndex,
    int score,
  ) async {
    final key = _bestScoreKey('endless', '$difficulty:$levelIndex');
    final current = _prefs.getInt(key) ?? 0;
    if (score <= current) {
      return false;
    }
    await _prefs.setInt(key, score);
    notifyListeners();
    return true;
  }

  String _bestScoreKey(String mode, String runId) {
    return 'best_score:$mode:$runId';
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }
}
