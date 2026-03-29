import 'package:cloud_firestore/cloud_firestore.dart';

class FriendProfile {
  const FriendProfile({
    required this.uid,
    required this.playerName,
    required this.username,
    required this.photoUrl,
    required this.avatarId,
    required this.equippedSkinId,
    required this.equippedTrailId,
    required this.addedAt,
    required this.isOnline,
    required this.lastSeenAt,
  });

  final String uid;
  final String playerName;
  final String username;
  final String photoUrl;
  final String avatarId;
  final String equippedSkinId;
  final String equippedTrailId;
  final DateTime? addedAt;
  final bool isOnline;
  final DateTime? lastSeenAt;

  String get displayName => username.trim().isNotEmpty ? username : playerName;

  factory FriendProfile.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    final ts = data['addedAt'];
    final lastSeen = data['lastSeenAt'];
    final onlineRaw = data['isOnline'];
    return FriendProfile(
      uid: uid,
      playerName: (data['playerName'] as String?)?.trim().isNotEmpty == true
          ? (data['playerName'] as String).trim()
          : 'Player',
      username: (data['username'] as String?)?.trim() ?? '',
      photoUrl: (data['photoUrl'] as String?)?.trim() ?? '',
      avatarId: (data['avatarId'] as String?)?.trim().isNotEmpty == true
          ? (data['avatarId'] as String).trim()
          : 'default',
      equippedSkinId:
          (data['equippedSkinId'] as String?)?.trim().isNotEmpty == true
              ? (data['equippedSkinId'] as String).trim()
              : 'default',
      equippedTrailId:
          (data['equippedTrailId'] as String?)?.trim().isNotEmpty == true
              ? (data['equippedTrailId'] as String).trim()
              : 'none',
      addedAt: ts is Timestamp ? ts.toDate() : null,
      isOnline: onlineRaw == true ||
          (onlineRaw is String && onlineRaw.trim().toLowerCase() == 'true'),
      lastSeenAt: lastSeen is Timestamp ? lastSeen.toDate() : null,
    );
  }
}
