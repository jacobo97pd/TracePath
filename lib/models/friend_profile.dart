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
  });

  final String uid;
  final String playerName;
  final String username;
  final String photoUrl;
  final String avatarId;
  final String equippedSkinId;
  final String equippedTrailId;
  final DateTime? addedAt;

  String get displayName => username.trim().isNotEmpty ? username : playerName;

  factory FriendProfile.fromFirestore(
    String uid,
    Map<String, dynamic> data,
  ) {
    final ts = data['addedAt'];
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
    );
  }
}
