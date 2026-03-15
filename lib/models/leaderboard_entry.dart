import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.playerName,
    required this.username,
    required this.photoUrl,
    required this.avatarId,
    required this.equippedSkinId,
    required this.equippedTrailId,
    required this.levelId,
    required this.bestTimeMs,
    required this.moves,
    required this.stars,
    required this.updatedAt,
  });

  final String uid;
  final String playerName;
  final String username;
  final String photoUrl;
  final String avatarId;
  final String equippedSkinId;
  final String equippedTrailId;
  final String levelId;
  final int bestTimeMs;
  final int moves;
  final int stars;
  final DateTime? updatedAt;

  String get displayName => username.trim().isNotEmpty ? username : playerName;

  factory LeaderboardEntry.fromFirestore(Map<String, dynamic> data) {
    final ts = data['updatedAt'];
    final legacyPhoto = (data['photoURL'] as String?)?.trim() ??
        (data['avatarUrl'] as String?)?.trim() ??
        (data['avatarURL'] as String?)?.trim() ??
        '';
    final legacyEquippedSkin = (data['equippedSkin'] as String?)?.trim() ?? '';
    return LeaderboardEntry(
      uid: (data['uid'] as String?)?.trim() ?? '',
      playerName: (data['playerName'] as String?)?.trim().isNotEmpty == true
          ? (data['playerName'] as String).trim()
          : 'Player',
      username: (data['username'] as String?)?.trim() ?? '',
      photoUrl: (data['photoUrl'] as String?)?.trim().isNotEmpty == true
          ? (data['photoUrl'] as String).trim()
          : legacyPhoto,
      avatarId: (data['avatarId'] as String?)?.trim().isNotEmpty == true
          ? (data['avatarId'] as String).trim()
          : 'default',
      equippedSkinId: (data['equippedSkinId'] as String?)?.trim().isNotEmpty ==
              true
          ? (data['equippedSkinId'] as String).trim()
          : (legacyEquippedSkin.isNotEmpty ? legacyEquippedSkin : 'default'),
      equippedTrailId:
          (data['equippedTrailId'] as String?)?.trim().isNotEmpty == true
              ? (data['equippedTrailId'] as String).trim()
              : 'none',
      levelId: (data['levelId'] as String?)?.trim() ?? '',
      bestTimeMs: readInt(data['bestTimeMs']),
      moves: readInt(data['moves']),
      stars: readInt(data['stars']),
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  static int readInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}
