class UserModel {
  const UserModel({
    required this.uid,
    required this.playerName,
    required this.username,
    required this.usernameLowercase,
    required this.usernameChangeCount,
    required this.avatarId,
    required this.country,
    required this.coins,
    required this.lifetimeCoinsEarned,
    required this.lifetimeCoinsPurchased,
    required this.totalLevelsCompleted,
    required this.highestLevelReached,
    required this.totalPlayTimeSeconds,
    required this.equippedSkinId,
    required this.equippedTrailId,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.fastestSolveMs,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String playerName;
  final String username;
  final String usernameLowercase;
  final int usernameChangeCount;
  final String avatarId;
  final String country;
  final int coins;
  final int lifetimeCoinsEarned;
  final int lifetimeCoinsPurchased;
  final int totalLevelsCompleted;
  final int highestLevelReached;
  final int totalPlayTimeSeconds;
  final String equippedSkinId;
  final String equippedTrailId;
  final int gamesPlayed;
  final int gamesWon;
  final int fastestSolveMs;
  final Object createdAt;
  final Object updatedAt;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'uid': uid,
      'playerName': playerName,
      'username': username,
      'usernameLowercase': usernameLowercase,
      'usernameChangeCount': usernameChangeCount,
      'avatarId': avatarId,
      'country': country,
      'coins': coins,
      'lifetimeCoinsEarned': lifetimeCoinsEarned,
      'lifetimeCoinsPurchased': lifetimeCoinsPurchased,
      'totalLevelsCompleted': totalLevelsCompleted,
      'highestLevelReached': highestLevelReached,
      'totalPlayTimeSeconds': totalPlayTimeSeconds,
      'equippedSkinId': equippedSkinId,
      'equippedTrailId': equippedTrailId,
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'fastestSolveMs': fastestSolveMs,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  static Map<String, dynamic> defaultFirestore({
    required String uid,
    required Object createdAt,
    required Object updatedAt,
  }) {
    return UserModel(
      uid: uid,
      playerName: 'Player',
      username: '',
      usernameLowercase: '',
      usernameChangeCount: 0,
      avatarId: 'default',
      country: '',
      coins: 0,
      lifetimeCoinsEarned: 0,
      lifetimeCoinsPurchased: 0,
      totalLevelsCompleted: 0,
      highestLevelReached: 1,
      totalPlayTimeSeconds: 0,
      equippedSkinId: 'default',
      equippedTrailId: 'none',
      gamesPlayed: 0,
      gamesWon: 0,
      fastestSolveMs: 0,
      createdAt: createdAt,
      updatedAt: updatedAt,
    ).toFirestore();
  }

  static Map<String, dynamic> missingFieldsForExisting({
    required String uid,
    required Map<String, dynamic> existing,
    required Object updatedAt,
  }) {
    final defaults = defaultFirestore(
      uid: uid,
      createdAt: updatedAt,
      updatedAt: updatedAt,
    );
    final missing = <String, dynamic>{};
    for (final entry in defaults.entries) {
      if (!existing.containsKey(entry.key) || existing[entry.key] == null) {
        if (entry.key == 'createdAt' && existing.containsKey('createdAt')) {
          continue;
        }
        missing[entry.key] = entry.value;
      }
    }
    return missing;
  }
}
