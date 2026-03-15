import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'puzzle_attempt.dart';

class LeaderboardService extends ChangeNotifier {
  LeaderboardService(this._prefs);

  static const int _maxAttemptsPerPuzzle = 10;
  final SharedPreferences _prefs;
  final Random _random = Random();

  Future<List<PuzzleAttempt>> getPuzzleLeaderboard(
    String packId,
    int levelIndex,
  ) async {
    final raw = _prefs.getStringList(_key(packId, levelIndex)) ?? const <String>[];
    final attempts = raw
        .map((entry) {
          try {
            return PuzzleAttempt.fromJson(
              jsonDecode(entry) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<PuzzleAttempt>()
        .toList();
    attempts.sort(_compareAttempts);
    return attempts;
  }

  Future<void> addPuzzleAttempt(PuzzleAttempt attempt) async {
    final current = await getPuzzleLeaderboard(attempt.packId, attempt.levelIndex);
    final next = <PuzzleAttempt>[...current, attempt]..sort(_compareAttempts);
    final top = next.take(_maxAttemptsPerPuzzle).toList();
    await _prefs.setStringList(
      _key(attempt.packId, attempt.levelIndex),
      top.map((a) => jsonEncode(a.toJson())).toList(),
    );
    notifyListeners();
  }

  Future<void> clearPuzzleLeaderboard(String packId, int levelIndex) async {
    await _prefs.remove(_key(packId, levelIndex));
    notifyListeners();
  }

  String createRunId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final nonce = _random.nextInt(1 << 30);
    return 'run-$now-$nonce';
  }

  String _key(String packId, int levelIndex) => 'lb:$packId:$levelIndex';

  int _compareAttempts(PuzzleAttempt a, PuzzleAttempt b) {
    final byTime = a.timeMs.compareTo(b.timeMs);
    if (byTime != 0) return byTime;
    final byHints = a.hintsUsed.compareTo(b.hintsUsed);
    if (byHints != 0) return byHints;
    final byRewinds = a.rewindsUsed.compareTo(b.rewindsUsed);
    if (byRewinds != 0) return byRewinds;
    return a.createdAtIso.compareTo(b.createdAtIso);
  }
}
