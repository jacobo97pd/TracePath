import 'package:cloud_firestore/cloud_firestore.dart';

enum InboxItemType {
  friendRequest,
  friendAccept,
  friendChallenge,
  levelChallenge,
  liveDuelInvite,
  systemReward,
  systemNews,
  unknown,
}

class InboxItem {
  const InboxItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.status,
    required this.read,
    required this.createdAt,
    required this.fromUid,
    required this.fromUsername,
    required this.fromPlayerName,
    required this.fromAvatarId,
    required this.ctaType,
    required this.ctaPayload,
    required this.relatedType,
    required this.subtype,
    required this.rewardCoins,
    required this.claimed,
  });

  final String id;
  final InboxItemType type;
  final String title;
  final String body;
  final String status;
  final bool read;
  final DateTime? createdAt;
  final String fromUid;
  final String fromUsername;
  final String fromPlayerName;
  final String fromAvatarId;
  final String ctaType;
  final String ctaPayload;
  final String relatedType;
  final String subtype;
  final int rewardCoins;
  final bool claimed;

  bool get isPendingFriendRequest =>
      type == InboxItemType.friendRequest && status == 'pending';

  bool get hasCta =>
      ctaType.isNotEmpty &&
      relatedType.trim().toLowerCase() != 'live_duel_invite';

  bool get isAllAchievementsReward =>
      type == InboxItemType.systemReward &&
      subtype.trim().toLowerCase() == 'all_achievements_completed';

  bool get canClaimAllAchievementsReward =>
      isAllAchievementsReward && !claimed && rewardCoins > 0;

  String get senderDisplayName {
    if (fromUsername.trim().isNotEmpty) return fromUsername.trim();
    if (fromPlayerName.trim().isNotEmpty) return fromPlayerName.trim();
    return 'Player';
  }

  factory InboxItem.fromFirestore(String id, Map<String, dynamic> data) {
    final rawType = (data['type'] as String?)?.trim().toLowerCase() ?? '';
    final ts = data['createdAt'];
    return InboxItem(
      id: id,
      type: _typeFromRaw(rawType),
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : 'Message',
      body: (data['body'] as String?)?.trim() ?? '',
      status: (data['status'] as String?)?.trim().toLowerCase() ?? 'active',
      read: data['read'] == true,
      createdAt: ts is Timestamp ? ts.toDate() : null,
      fromUid: (data['fromUid'] as String?)?.trim() ?? '',
      fromUsername: (data['fromUsername'] as String?)?.trim() ?? '',
      fromPlayerName: (data['fromPlayerName'] as String?)?.trim() ?? '',
      fromAvatarId: (data['fromAvatarId'] as String?)?.trim() ?? 'default',
      ctaType: (data['ctaType'] as String?)?.trim() ?? '',
      ctaPayload: (data['ctaPayload'] as String?)?.trim() ?? '',
      relatedType: (data['relatedType'] as String?)?.trim() ?? '',
      subtype: (data['subtype'] as String?)?.trim() ?? '',
      rewardCoins: _readInt(data['rewardCoins']),
      claimed: data['claimed'] == true,
    );
  }

  static InboxItemType _typeFromRaw(String raw) {
    switch (raw) {
      case 'friend_request':
        return InboxItemType.friendRequest;
      case 'friend_accept':
        return InboxItemType.friendAccept;
      case 'friend_challenge':
        return InboxItemType.friendChallenge;
      case 'level_challenge':
        return InboxItemType.levelChallenge;
      case 'live_duel_invite':
        return InboxItemType.liveDuelInvite;
      case 'system_reward':
        return InboxItemType.systemReward;
      case 'system_news':
        return InboxItemType.systemNews;
      default:
        return InboxItemType.unknown;
    }
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}
