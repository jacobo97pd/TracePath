class FriendChallenge {
  const FriendChallenge({
    required this.challengeId,
    required this.challengerUserId,
    required this.challengedUserId,
    required this.puzzleId,
    required this.packId,
    required this.levelIndex,
    required this.mode,
    required this.createdAtMs,
    required this.status,
    required this.puzzleDifficulty,
    required this.gridWidth,
    required this.gridHeight,
  });

  final String challengeId;
  final String challengerUserId;
  final String challengedUserId;
  final String puzzleId;
  final String packId;
  final int levelIndex;
  final String mode;
  final int createdAtMs;
  final String status;
  final int puzzleDifficulty;
  final int gridWidth;
  final int gridHeight;

  bool involvesUser(String uid) {
    final value = uid.trim();
    if (value.isEmpty) return false;
    return challengerUserId == value || challengedUserId == value;
  }

  factory FriendChallenge.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    int readInt(Object? value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value.trim()) ?? 0;
      return 0;
    }

    String readString(Object? value) {
      return value is String ? value.trim() : '';
    }

    return FriendChallenge(
      challengeId: id,
      challengerUserId: readString(data['challengerUserId']),
      challengedUserId: readString(data['challengedUserId']),
      puzzleId: readString(data['puzzleId']),
      packId: readString(data['packId']),
      levelIndex: readInt(data['levelIndex']),
      mode: readString(data['mode']),
      createdAtMs: readInt(data['createdAtMs']),
      status: readString(data['status']),
      puzzleDifficulty: readInt(data['puzzleDifficulty']),
      gridWidth: readInt(data['gridWidth']),
      gridHeight: readInt(data['gridHeight']),
    );
  }
}

class FriendChallengeGameArgs {
  const FriendChallengeGameArgs({
    required this.challengeId,
    required this.challengerUserId,
    required this.challengedUserId,
    required this.puzzleId,
    this.mode = 'friend_challenge',
  });

  final String challengeId;
  final String challengerUserId;
  final String challengedUserId;
  final String puzzleId;
  final String mode;
}
