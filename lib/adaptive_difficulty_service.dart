import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EndlessOutcome {
  const EndlessOutcome({
    required this.timeMs,
    required this.hintsUsed,
    required this.rewindsUsed,
    required this.difficulty,
    required this.timestamp,
  });

  final int timeMs;
  final int hintsUsed;
  final int rewindsUsed;
  final int difficulty;
  final int timestamp;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'timeMs': timeMs,
      'hintsUsed': hintsUsed,
      'rewindsUsed': rewindsUsed,
      'difficulty': difficulty,
      'timestamp': timestamp,
    };
  }

  factory EndlessOutcome.fromJson(Map<String, dynamic> json) {
    return EndlessOutcome(
      timeMs: json['timeMs'] as int,
      hintsUsed: json['hintsUsed'] as int,
      rewindsUsed: json['rewindsUsed'] as int,
      difficulty: json['difficulty'] as int,
      timestamp: json['timestamp'] as int,
    );
  }
}

class AdaptiveParams {
  const AdaptiveParams({
    required this.difficultyOffset,
    required this.sizeDelta,
    required this.numberReduction,
  });

  final int difficultyOffset;
  final int sizeDelta;
  final int numberReduction;
}

class AdaptiveDifficultyService extends ChangeNotifier {
  AdaptiveDifficultyService(this._prefs);

  static const int _windowSize = 5;
  final SharedPreferences _prefs;

  List<EndlessOutcome> recentOutcomes(int difficulty) {
    final raw = _prefs.getStringList(_outcomesKey(difficulty)) ?? const <String>[];
    return raw
        .map((value) {
          try {
            return EndlessOutcome.fromJson(
              jsonDecode(value) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<EndlessOutcome>()
        .toList();
  }

  Future<void> recordOutcome(EndlessOutcome outcome) async {
    final current = recentOutcomes(outcome.difficulty);
    final next = <EndlessOutcome>[...current, outcome];
    if (next.length > _windowSize) {
      next.removeRange(0, next.length - _windowSize);
    }
    await _prefs.setStringList(
      _outcomesKey(outcome.difficulty),
      next.map((e) => jsonEncode(e.toJson())).toList(),
    );
    notifyListeners();
  }

  AdaptiveParams paramsForDifficulty(int difficulty) {
    final recent = recentOutcomes(difficulty);
    if (recent.length < 3) {
      return const AdaptiveParams(
        difficultyOffset: 0,
        sizeDelta: 0,
        numberReduction: 0,
      );
    }

    final avgTimeMs =
        recent.fold<int>(0, (sum, o) => sum + o.timeMs) / recent.length;
    final avgHints =
        recent.fold<int>(0, (sum, o) => sum + o.hintsUsed) / recent.length;
    final avgRewinds =
        recent.fold<int>(0, (sum, o) => sum + o.rewindsUsed) / recent.length;

    final fastAndClean =
        avgTimeMs < 60000 && avgHints <= 0.5 && avgRewinds <= 2.0;
    final struggling =
        avgTimeMs > 170000 || avgHints >= 2.0 || avgRewinds >= 8.0;

    if (fastAndClean) {
      return const AdaptiveParams(
        difficultyOffset: 1,
        sizeDelta: 0,
        numberReduction: 1,
      );
    }

    if (struggling) {
      return const AdaptiveParams(
        difficultyOffset: -1,
        sizeDelta: -1,
        numberReduction: 0,
      );
    }

    return const AdaptiveParams(
      difficultyOffset: 0,
      sizeDelta: 0,
      numberReduction: 0,
    );
  }

  String _outcomesKey(int difficulty) => 'endless_outcomes_difficulty_$difficulty';
}
