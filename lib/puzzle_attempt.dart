class PuzzleAttempt {
  const PuzzleAttempt({
    required this.runId,
    required this.packId,
    required this.levelIndex,
    required this.timeMs,
    required this.hintsUsed,
    required this.rewindsUsed,
    required this.score,
    required this.createdAtIso,
    required this.playerName,
  });

  final String runId;
  final String packId;
  final int levelIndex;
  final int timeMs;
  final int hintsUsed;
  final int rewindsUsed;
  final int? score;
  final String createdAtIso;
  final String playerName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'runId': runId,
      'packId': packId,
      'levelIndex': levelIndex,
      'timeMs': timeMs,
      'hintsUsed': hintsUsed,
      'rewindsUsed': rewindsUsed,
      'score': score,
      'createdAt': createdAtIso,
      'playerName': playerName,
    };
  }

  factory PuzzleAttempt.fromJson(Map<String, dynamic> json) {
    return PuzzleAttempt(
      runId: json['runId'] as String,
      packId: json['packId'] as String,
      levelIndex: json['levelIndex'] as int,
      timeMs: json['timeMs'] as int,
      hintsUsed: json['hintsUsed'] as int,
      rewindsUsed: json['rewindsUsed'] as int,
      score: json['score'] as int?,
      createdAtIso: json['createdAt'] as String,
      playerName: (json['playerName'] as String?) ?? 'You',
    );
  }
}
