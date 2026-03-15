class ScoreInput {
  const ScoreInput({
    required this.difficulty,
    required this.elapsedMs,
    required this.hintsUsed,
    required this.rewindsUsed,
  });

  final int difficulty;
  final int elapsedMs;
  final int hintsUsed;
  final int rewindsUsed;
}

class ScoreBreakdown {
  const ScoreBreakdown({
    required this.basePoints,
    required this.timePenalty,
    required this.hintPenalty,
    required this.rewindPenalty,
    required this.perfectBonus,
    required this.finalScore,
  });

  final int basePoints;
  final int timePenalty;
  final int hintPenalty;
  final int rewindPenalty;
  final int perfectBonus;
  final int finalScore;

  Map<String, int> toMap() {
    return <String, int>{
      'basePoints': basePoints,
      'timePenalty': timePenalty,
      'hintPenalty': hintPenalty,
      'rewindPenalty': rewindPenalty,
      'perfectBonus': perfectBonus,
      'finalScore': finalScore,
    };
  }
}

class ScoreCalculator {
  const ScoreCalculator._();

  static ScoreBreakdown calculate(ScoreInput input) {
    final difficulty = input.difficulty.clamp(1, 5);
    final basePoints = _basePointsForDifficulty(difficulty);
    final seconds = (input.elapsedMs / 1000).floor();
    final timePenalty = seconds * _timePenaltyPerSecond(difficulty);
    final hintPenalty = input.hintsUsed * _hintPenalty(difficulty);
    final rewindPenalty = input.rewindsUsed * _rewindPenalty(difficulty);
    final perfectBonus = (input.hintsUsed == 0 && input.rewindsUsed == 0)
        ? _perfectBonus(difficulty)
        : 0;
    final finalScore = (basePoints -
            timePenalty -
            hintPenalty -
            rewindPenalty +
            perfectBonus)
        .clamp(0, 1 << 30);

    return ScoreBreakdown(
      basePoints: basePoints,
      timePenalty: timePenalty,
      hintPenalty: hintPenalty,
      rewindPenalty: rewindPenalty,
      perfectBonus: perfectBonus,
      finalScore: finalScore,
    );
  }

  static int _basePointsForDifficulty(int difficulty) {
    const values = <int>[100, 250, 600, 1500, 4000];
    return values[difficulty - 1];
  }

  static int _timePenaltyPerSecond(int difficulty) {
    const values = <int>[2, 3, 4, 5, 6];
    return values[difficulty - 1];
  }

  static int _hintPenalty(int difficulty) {
    const values = <int>[200, 300, 400, 500, 600];
    return values[difficulty - 1];
  }

  static int _rewindPenalty(int difficulty) {
    const values = <int>[5, 8, 12, 16, 20];
    return values[difficulty - 1];
  }

  static int _perfectBonus(int difficulty) {
    const values = <int>[60, 120, 240, 400, 700];
    return values[difficulty - 1];
  }
}

class ScoreRecord {
  const ScoreRecord({
    required this.packId,
    required this.levelIndex,
    required this.score,
    required this.elapsedMs,
    required this.hintsUsed,
    required this.rewindsUsed,
    required this.difficulty,
  });

  final String packId;
  final int levelIndex;
  final int score;
  final int elapsedMs;
  final int hintsUsed;
  final int rewindsUsed;
  final int difficulty;

  Map<String, Object> toMap() {
    return <String, Object>{
      'packId': packId,
      'levelIndex': levelIndex,
      'score': score,
      'elapsedMs': elapsedMs,
      'hintsUsed': hintsUsed,
      'rewindsUsed': rewindsUsed,
      'difficulty': difficulty,
    };
  }
}
