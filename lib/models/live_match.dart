import 'package:cloud_firestore/cloud_firestore.dart';

enum LiveMatchStatus {
  pending,
  countdown,
  playing,
  finished,
  cancelled,
}

enum LiveMatchPlayerState {
  invited,
  joined,
  ready,
  playing,
  finished,
  abandoned,
}

class LiveMatchPlayer {
  const LiveMatchPlayer({
    required this.uid,
    required this.username,
    required this.avatarId,
    required this.state,
    required this.joinedAt,
    required this.finishedAtMsFromStart,
    required this.completed,
    required this.resultPlace,
  });

  final String uid;
  final String username;
  final String avatarId;
  final LiveMatchPlayerState state;
  final DateTime? joinedAt;
  final int finishedAtMsFromStart;
  final bool completed;
  final int resultPlace;

  factory LiveMatchPlayer.fromFirestore(Map<String, dynamic> data) {
    final joinedAtTs = data['joinedAt'];
    return LiveMatchPlayer(
      uid: (data['uid'] as String?)?.trim() ?? '',
      username: (data['username'] as String?)?.trim() ?? '',
      avatarId: (data['avatarId'] as String?)?.trim().isNotEmpty == true
          ? (data['avatarId'] as String).trim()
          : 'default',
      state: _playerStateFromRaw((data['state'] as String?)?.trim() ?? ''),
      joinedAt: joinedAtTs is Timestamp ? joinedAtTs.toDate() : null,
      finishedAtMsFromStart: _readInt(data['finishedAtMsFromStart']),
      completed: data['completed'] == true,
      resultPlace: _readInt(data['resultPlace']),
    );
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static LiveMatchPlayerState _playerStateFromRaw(String raw) {
    switch (raw.toLowerCase()) {
      case 'invited':
        return LiveMatchPlayerState.invited;
      case 'joined':
        return LiveMatchPlayerState.joined;
      case 'ready':
        return LiveMatchPlayerState.ready;
      case 'playing':
        return LiveMatchPlayerState.playing;
      case 'finished':
        return LiveMatchPlayerState.finished;
      case 'abandoned':
        return LiveMatchPlayerState.abandoned;
      default:
        return LiveMatchPlayerState.joined;
    }
  }
}

class LiveMatch {
  const LiveMatch({
    required this.id,
    required this.levelId,
    required this.packId,
    required this.levelIndex,
    required this.createdByUid,
    required this.invitedUid,
    required this.playerUids,
    required this.status,
    required this.countdownSeconds,
    required this.createdAt,
    required this.acceptedAt,
    required this.startAtMs,
    required this.winnerUid,
    required this.loserUid,
    required this.playerATimeMs,
    required this.playerBTimeMs,
    required this.finishedAt,
    required this.resultResolvedAt,
    required this.reason,
    required this.players,
  });

  final String id;
  final String levelId;
  final String packId;
  final int levelIndex;
  final String createdByUid;
  final String invitedUid;
  final List<String> playerUids;
  final LiveMatchStatus status;
  final int countdownSeconds;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final int startAtMs;
  final String winnerUid;
  final String loserUid;
  final int playerATimeMs;
  final int playerBTimeMs;
  final DateTime? finishedAt;
  final DateTime? resultResolvedAt;
  final String reason;
  final Map<String, LiveMatchPlayer> players;

  bool get isTerminal =>
      status == LiveMatchStatus.finished || status == LiveMatchStatus.cancelled;

  String opponentUid(String currentUid) {
    for (final uid in playerUids) {
      if (uid != currentUid) return uid;
    }
    return '';
  }

  factory LiveMatch.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
    required Map<String, LiveMatchPlayer> players,
  }) {
    final createdAtTs = data['createdAt'];
    final acceptedAtTs = data['acceptedAt'];
    final finishedAtTs = data['finishedAt'];
    final resolvedAtTs = data['resultResolvedAt'];
    final rawPlayerUids = (data['playerUids'] as List?)
            ?.whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    return LiveMatch(
      id: id,
      levelId: (data['levelId'] as String?)?.trim() ?? '',
      packId: (data['packId'] as String?)?.trim() ?? '',
      levelIndex: _readInt(data['levelIndex']),
      createdByUid: (data['createdByUid'] as String?)?.trim() ?? '',
      invitedUid: (data['invitedUid'] as String?)?.trim() ?? '',
      playerUids: rawPlayerUids,
      status: _statusFromRaw((data['status'] as String?)?.trim() ?? ''),
      countdownSeconds: _readInt(data['countdownSeconds']) <= 0
          ? 3
          : _readInt(data['countdownSeconds']),
      createdAt: createdAtTs is Timestamp ? createdAtTs.toDate() : null,
      acceptedAt: acceptedAtTs is Timestamp ? acceptedAtTs.toDate() : null,
      startAtMs: _readInt(data['startAtMs']),
      winnerUid: (data['winnerUid'] as String?)?.trim() ?? '',
      loserUid: (data['loserUid'] as String?)?.trim() ?? '',
      playerATimeMs: _readInt(data['playerATimeMs']),
      playerBTimeMs: _readInt(data['playerBTimeMs']),
      finishedAt: finishedAtTs is Timestamp ? finishedAtTs.toDate() : null,
      resultResolvedAt:
          resolvedAtTs is Timestamp ? resolvedAtTs.toDate() : null,
      reason: (data['reason'] as String?)?.trim() ?? '',
      players: players,
    );
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static LiveMatchStatus _statusFromRaw(String raw) {
    switch (raw.toLowerCase()) {
      case 'pending':
        return LiveMatchStatus.pending;
      case 'countdown':
        return LiveMatchStatus.countdown;
      case 'playing':
        return LiveMatchStatus.playing;
      case 'finished':
        return LiveMatchStatus.finished;
      case 'cancelled':
        return LiveMatchStatus.cancelled;
      default:
        return LiveMatchStatus.pending;
    }
  }
}

class LiveDuelGameArgs {
  const LiveDuelGameArgs({
    required this.matchId,
    required this.levelId,
    required this.opponentUid,
  });

  final String matchId;
  final String levelId;
  final String opponentUid;
}

class LevelRouteInfo {
  const LevelRouteInfo({
    required this.packId,
    required this.levelIndex,
  });

  final String packId;
  final int levelIndex;
}

class LiveMatchRealtimeTrail {
  const LiveMatchRealtimeTrail({
    required this.uid,
    required this.pathCells,
    required this.state,
    required this.updatedAt,
    required this.pathVersion,
  });

  final String uid;
  final List<int> pathCells;
  final String state;
  final DateTime? updatedAt;
  final int pathVersion;

  factory LiveMatchRealtimeTrail.fromFirestore(Map<String, dynamic> data) {
    final rawCells = (data['pathCells'] as List?)
            ?.whereType<num>()
            .map((e) => e.toInt())
            .where((e) => e >= 0)
            .toList(growable: false) ??
        const <int>[];
    final updatedAtTs = data['updatedAt'];
    return LiveMatchRealtimeTrail(
      uid: (data['uid'] as String?)?.trim() ?? '',
      pathCells: rawCells,
      state: (data['state'] as String?)?.trim() ?? 'drawing',
      updatedAt: updatedAtTs is Timestamp ? updatedAtTs.toDate() : null,
      pathVersion: _readInt(data['pathVersion']),
    );
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

class LiveMatchEmote {
  const LiveMatchEmote({
    required this.id,
    required this.emoteId,
    required this.sentByUid,
    required this.createdAt,
    required this.senderUsername,
  });

  final String id;
  final String emoteId;
  final String sentByUid;
  final DateTime? createdAt;
  final String senderUsername;

  factory LiveMatchEmote.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final createdAtTs = data['createdAt'];
    return LiveMatchEmote(
      id: id,
      emoteId: (data['emoteId'] as String?)?.trim() ?? '',
      sentByUid: (data['sentByUid'] as String?)?.trim() ?? '',
      createdAt: createdAtTs is Timestamp ? createdAtTs.toDate() : null,
      senderUsername: (data['senderUsername'] as String?)?.trim() ?? '',
    );
  }
}
