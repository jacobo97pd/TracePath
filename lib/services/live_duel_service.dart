import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/live_match.dart';
import 'inbox_service.dart';

class LiveDuelCreateResult {
  const LiveDuelCreateResult({
    required this.matchId,
    required this.levelId,
  });

  final String matchId;
  final String levelId;
}

class LiveDuelService {
  static const String _firestoreDatabaseId = 'tracepath-database';
  static const int _maxActiveMatchAgeHours = 6;
  static const Duration _pendingTtl = Duration(minutes: 15);
  static const Duration _countdownTtl = Duration(seconds: 25);
  static const Duration _playingTtl = Duration(minutes: 40);
  static const int _emoteCooldownMs = 1600;
  final InboxService _inboxService = InboxService();

  Future<LiveDuelCreateResult> createInvite({
    required String toUid,
    required String levelId,
  }) async {
    final fromUid = await _requireUid();
    final targetUid = toUid.trim();
    final normalizedLevelId = levelId.trim();
    if (targetUid.isEmpty || targetUid == fromUid) {
      throw StateError('INVALID_DUEL_TARGET');
    }
    if (normalizedLevelId.isEmpty) {
      throw StateError('INVALID_LEVEL_ID');
    }
    final levelInfo = parseLevelRouteInfo(normalizedLevelId);
    if (levelInfo == null) {
      throw StateError('INVALID_LEVEL_ROUTE');
    }
    final active = await _findActiveMatchBetween(
      uidA: fromUid,
      uidB: targetUid,
      levelId: normalizedLevelId,
    );
    if (active != null) {
      return LiveDuelCreateResult(
        matchId: active.id,
        levelId: normalizedLevelId,
      );
    }

    if (await _hasActiveMatch(fromUid)) {
      throw StateError('ALREADY_IN_ACTIVE_DUEL');
    }
    try {
      if (await _hasActiveMatch(targetUid)) {
        throw StateError('TARGET_IN_ACTIVE_DUEL');
      }
    } on FirebaseException catch (e) {
      // Rules may prevent reading another user's active matches.
      // In that case, continue and let the invite flow proceed.
      if (e.code != 'permission-denied') {
        rethrow;
      }
      if (kDebugMode) {
        debugPrint(
          '[live-duel] target busy-check skipped (permission-denied) '
          'targetUid=$targetUid',
        );
      }
    }

    final fromUserRef = _db().collection('users').doc(fromUid);
    final fromSnap = await fromUserRef.get();
    final fromData = fromSnap.data() ?? <String, dynamic>{};
    final fromUsername = _readString(fromData['username']);
    final fromPlayerName = _readString(
      fromData['playerName'],
      fallback: 'Player',
    );
    final fromAvatarId = _readString(fromData['avatarId'], fallback: 'default');

    final matchRef = _db().collection('liveMatches').doc();
    final matchId = matchRef.id;
    final creatorPlayerRef = matchRef.collection('players').doc(fromUid);
    final invitedPlayerRef = matchRef.collection('players').doc(targetUid);
    final challengerLabel =
        fromUsername.isNotEmpty ? '@$fromUsername' : fromPlayerName;

    await matchRef.set(<String, dynamic>{
      'levelId': normalizedLevelId,
      'packId': levelInfo.packId,
      'levelIndex': levelInfo.levelIndex,
      'createdByUid': fromUid,
      'invitedUid': targetUid,
      'playerAUid': fromUid,
      'playerBUid': targetUid,
      'playerAName': fromUsername.isNotEmpty ? fromUsername : fromPlayerName,
      'playerBName': '',
      'playerUids': <String>[fromUid, targetUid],
      'status': 'pending',
      'readyA': false,
      'readyB': false,
      'countdownSeconds': 3,
      'createdAt': FieldValue.serverTimestamp(),
      'winnerUid': '',
      'loserUid': '',
      'playerATimeMs': 0,
      'playerBTimeMs': 0,
      'resultResolvedAt': null,
      'reason': '',
    });
    await creatorPlayerRef.set(<String, dynamic>{
      'uid': fromUid,
      'username': fromUsername,
      'avatarId': fromAvatarId,
      'state': 'joined',
      'joinedAt': FieldValue.serverTimestamp(),
      'finishedAtMsFromStart': 0,
      'completed': false,
      'resultPlace': 0,
    });
    await invitedPlayerRef.set(<String, dynamic>{
      'uid': targetUid,
      'username': '',
      'avatarId': 'default',
      'state': 'invited',
      'joinedAt': FieldValue.serverTimestamp(),
      'finishedAtMsFromStart': 0,
      'completed': false,
      'resultPlace': 0,
    });

    await _inboxService.addInboxItem(
      uid: targetUid,
      type: 'live_duel_invite',
      title: 'Live duel invite',
      body: '$challengerLabel challenged you to a live duel.',
      status: 'pending',
      extraData: <String, dynamic>{
        'fromUid': fromUid,
        'fromUsername': fromUsername,
        'fromPlayerName': fromPlayerName,
        'fromAvatarId': fromAvatarId,
        'ctaType': 'open_live_duel',
        'ctaPayload': matchId,
        'liveMatchId': matchId,
        'levelId': normalizedLevelId,
      },
      messageId: 'live_duel_invite_$matchId',
    );

    return LiveDuelCreateResult(matchId: matchId, levelId: normalizedLevelId);
  }

  Stream<LiveMatch?> watchMatch(String matchId) {
    final normalizedId = matchId.trim();
    if (normalizedId.isEmpty) {
      return Stream<LiveMatch?>.value(null);
    }
    final matchRef = _db().collection('liveMatches').doc(normalizedId);
    return matchRef.snapshots().asyncMap((matchSnap) async {
      if (!matchSnap.exists) return null;
      final playersSnap = await matchRef.collection('players').get();
      final players = <String, LiveMatchPlayer>{};
      for (final doc in playersSnap.docs) {
        players[doc.id] = LiveMatchPlayer.fromFirestore(doc.data());
      }
      return LiveMatch.fromFirestore(
        id: matchSnap.id,
        data: matchSnap.data() ?? <String, dynamic>{},
        players: players,
      );
    });
  }

  Future<LiveMatch?> getMatch(String matchId) async {
    final normalizedId = matchId.trim();
    if (normalizedId.isEmpty) return null;
    final matchRef = _db().collection('liveMatches').doc(normalizedId);
    final matchSnap = await matchRef.get();
    if (!matchSnap.exists) return null;
    final playersSnap = await matchRef.collection('players').get();
    final players = <String, LiveMatchPlayer>{};
    for (final doc in playersSnap.docs) {
      players[doc.id] = LiveMatchPlayer.fromFirestore(doc.data());
    }
    return LiveMatch.fromFirestore(
      id: matchSnap.id,
      data: matchSnap.data() ?? <String, dynamic>{},
      players: players,
    );
  }

  Future<void> acceptInvite({
    required String matchId,
    String? inboxMessageId,
  }) async {
    final uid = await _requireUid();
    final normalizedId = matchId.trim();
    if (normalizedId.isEmpty) throw StateError('INVALID_MATCH_ID');
    final matchRef = _db().collection('liveMatches').doc(normalizedId);
    await expireIfStale(normalizedId);
    final playerRef = matchRef.collection('players').doc(uid);
    final userRef = _db().collection('users').doc(uid);
    final userSnap = await userRef.get();
    final userData = userSnap.data() ?? <String, dynamic>{};
    final username = _readString(userData['username']);
    final avatarId = _readString(userData['avatarId'], fallback: 'default');

    String createdByUid = '';
    String invitedUid = '';
    String levelId = '';
    await _db().runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      if (!matchSnap.exists) throw StateError('MATCH_NOT_FOUND');
      final data = matchSnap.data() ?? <String, dynamic>{};
      invitedUid = _readString(data['invitedUid']);
      createdByUid = _readString(data['createdByUid']);
      levelId = _readString(data['levelId']);
      final status = _readString(data['status']);
      if (uid != invitedUid && uid != createdByUid) {
        if (kDebugMode) {
          debugPrint(
            '[live-duel] accept denied: uid not participant '
            'match=$normalizedId uid=$uid',
          );
        }
        throw StateError('MATCH_ACCESS_DENIED');
      }
      if (status == 'finished' || status == 'cancelled') {
        if (kDebugMode) {
          debugPrint(
            '[live-duel] accept ignored: match terminal '
            'match=$normalizedId status=$status',
          );
        }
        throw StateError('MATCH_CLOSED');
      }

      tx.set(
        playerRef,
        <String, dynamic>{
          'uid': uid,
          'username': username,
          'avatarId': avatarId,
          'state': 'joined',
          'joinedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      final userName = username.isNotEmpty
          ? username
          : _readString(userData['playerName'], fallback: 'Player');
      if (uid == createdByUid) {
        tx.set(
          matchRef,
          <String, dynamic>{'playerAName': userName},
          SetOptions(merge: true),
        );
      } else if (uid == invitedUid) {
        tx.set(
          matchRef,
          <String, dynamic>{'playerBName': userName},
          SetOptions(merge: true),
        );
      }
    });

    final inboxId = (inboxMessageId ?? '').trim();
    if (inboxId.isNotEmpty) {
      await _inboxService.deleteInboxItem(uid: uid, messageId: inboxId);
    }

    if (uid == invitedUid && createdByUid.isNotEmpty && createdByUid != uid) {
      final label = username.isNotEmpty
          ? '@$username'
          : _readString(userData['playerName'], fallback: 'Player');
      await _inboxService.addInboxItem(
        uid: createdByUid,
        type: 'system_news',
        title: 'Duel invite accepted',
        body: '$label accepted your live duel invite.',
        status: 'accepted',
        extraData: <String, dynamic>{
          'fromUid': uid,
          'fromUsername': username,
          'fromPlayerName':
              _readString(userData['playerName'], fallback: 'Player'),
          'fromAvatarId': avatarId,
          'ctaType': 'open_live_duel',
          'ctaPayload': normalizedId,
          'liveMatchId': normalizedId,
          'levelId': levelId,
          'relatedType': 'live_duel_invite',
        },
        messageId: 'live_duel_accept_${normalizedId}_$uid',
      );
    }
  }

  Future<void> declineInvite({
    required String matchId,
    String? inboxMessageId,
  }) async {
    final uid = await _requireUid();
    final normalizedId = matchId.trim();
    if (normalizedId.isEmpty) throw StateError('INVALID_MATCH_ID');
    final matchRef = _db().collection('liveMatches').doc(normalizedId);
    final playerRef = matchRef.collection('players').doc(uid);
    final userRef = _db().collection('users').doc(uid);
    final userSnap = await userRef.get();
    final userData = userSnap.data() ?? <String, dynamic>{};
    final username = _readString(userData['username']);
    final playerName = _readString(userData['playerName'], fallback: 'Player');
    final avatarId = _readString(userData['avatarId'], fallback: 'default');

    String notifyUid = '';
    String levelId = '';
    String reason = 'invite_declined';
    await _db().runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      if (!matchSnap.exists) throw StateError('MATCH_NOT_FOUND');
      final data = matchSnap.data() ?? <String, dynamic>{};
      final status = _readString(data['status']);
      if (status == 'finished' || status == 'cancelled') return;
      final invitedUid = _readString(data['invitedUid']);
      final createdByUid = _readString(data['createdByUid']);
      levelId = _readString(data['levelId']);
      if (uid != invitedUid && uid != createdByUid) {
        throw StateError('MATCH_ACCESS_DENIED');
      }
      if (uid == invitedUid) {
        notifyUid = createdByUid;
        reason = 'invite_declined';
      } else {
        notifyUid = invitedUid;
        reason = 'invite_cancelled';
      }
      tx.set(
        playerRef,
        <String, dynamic>{
          'state': 'abandoned',
          'completed': false,
          'resultPlace': 2,
          'finishedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(
        matchRef,
        <String, dynamic>{
          'status': 'cancelled',
          'reason': reason,
          'winnerUid': '',
          'loserUid': '',
          'finishedAt': FieldValue.serverTimestamp(),
          'resultResolvedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    final inboxId = (inboxMessageId ?? '').trim();
    if (inboxId.isNotEmpty) {
      await _inboxService.deleteInboxItem(uid: uid, messageId: inboxId);
    }

    if (notifyUid.isNotEmpty && notifyUid != uid) {
      final label = username.isNotEmpty ? '@$username' : playerName;
      final title = reason == 'invite_cancelled'
          ? 'Duel invite cancelled'
          : 'Duel invite declined';
      final body = reason == 'invite_cancelled'
          ? '$label cancelled the live duel invite.'
          : '$label declined your live duel invite.';
      await _inboxService.addInboxItem(
        uid: notifyUid,
        type: 'system_news',
        title: title,
        body: body,
        status: 'declined',
        extraData: <String, dynamic>{
          'fromUid': uid,
          'fromUsername': username,
          'fromPlayerName': playerName,
          'fromAvatarId': avatarId,
          'ctaType': 'open_social',
          'ctaPayload': '/social',
          'liveMatchId': normalizedId,
          'levelId': levelId,
          'relatedType': 'live_duel_invite',
        },
        messageId: 'live_duel_decline_${normalizedId}_$uid',
      );
    }
  }

  Future<void> setReady({
    required String matchId,
    required bool ready,
  }) async {
    final uid = await _requireUid();
    final normalizedId = matchId.trim();
    if (normalizedId.isEmpty) throw StateError('INVALID_MATCH_ID');
    final matchRef = _db().collection('liveMatches').doc(normalizedId);
    final playerRef = matchRef.collection('players').doc(uid);

    await _db().runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      if (!matchSnap.exists) throw StateError('MATCH_NOT_FOUND');
      final data = matchSnap.data() ?? <String, dynamic>{};
      final createdByUid = _readString(data['createdByUid']);
      final invitedUid = _readString(data['invitedUid']);
      final status = _readString(data['status']);

      if (uid != createdByUid && uid != invitedUid) {
        if (kDebugMode) {
          debugPrint(
            '[live-duel] setReady denied: uid not participant '
            'match=$normalizedId uid=$uid',
          );
        }
        throw StateError('MATCH_ACCESS_DENIED');
      }
      if (status == 'finished' || status == 'cancelled') {
        if (kDebugMode) {
          debugPrint(
            '[live-duel] setReady ignored: match terminal '
            'match=$normalizedId status=$status',
          );
        }
        throw StateError('MATCH_CLOSED');
      }
      if (status == 'playing') {
        if (kDebugMode) {
          debugPrint(
            '[live-duel] setReady ignored: already playing match=$normalizedId',
          );
        }
        return;
      }

      tx.set(
        playerRef,
        <String, dynamic>{
          'state': ready ? 'ready' : 'joined',
          'joinedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final readyA = uid == createdByUid ? ready : (data['readyA'] == true);
      final readyB = uid == invitedUid ? ready : (data['readyB'] == true);

      final payload = <String, dynamic>{
        'readyA': readyA,
        'readyB': readyB,
      };

      if (status == 'pending' && readyA && readyB) {
        payload['status'] = 'countdown';
        payload['acceptedAt'] = FieldValue.serverTimestamp();
        payload['reason'] = '';
      }
      tx.set(matchRef, payload, SetOptions(merge: true));
    });
  }

  Future<void> ensurePlaying(String matchId) async {
    final uid = await _requireUid();
    final normalizedId = matchId.trim();
    if (normalizedId.isEmpty) return;
    await expireIfStale(normalizedId);
    final matchRef = _db().collection('liveMatches').doc(normalizedId);
    final playerRef = matchRef.collection('players').doc(uid);

    await _db().runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      if (!matchSnap.exists) return;
      final data = matchSnap.data() ?? <String, dynamic>{};
      final status = _readString(data['status']);
      if (status == 'cancelled' || status == 'finished') return;
      if (status == 'countdown') {
        final acceptedAt = (data['acceptedAt'] as Timestamp?)?.toDate();
        final countdownSeconds = _readInt(data['countdownSeconds']) <= 0
            ? 3
            : _readInt(data['countdownSeconds']);
        if (acceptedAt != null) {
          final startMs =
              acceptedAt.millisecondsSinceEpoch + (countdownSeconds * 1000);
          if (DateTime.now().millisecondsSinceEpoch >= startMs) {
            tx.set(
              matchRef,
              <String, dynamic>{
                'status': 'playing',
                'startAtMs': startMs,
              },
              SetOptions(merge: true),
            );
          }
        }
      }
      tx.set(
        playerRef,
        <String, dynamic>{
          'state': 'playing',
          'joinedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> reportFinish({
    required String matchId,
    required int elapsedMsFromStart,
  }) async {
    final uid = await _requireUid();
    final normalizedId = matchId.trim();
    if (normalizedId.isEmpty || elapsedMsFromStart <= 0) return;
    await expireIfStale(normalizedId);
    final matchRef = _db().collection('liveMatches').doc(normalizedId);
    final playerRef = matchRef.collection('players').doc(uid);

    await _db().runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      if (!matchSnap.exists) return;
      final matchData = matchSnap.data() ?? <String, dynamic>{};
      final status = _readString(matchData['status']);
      if (status == 'cancelled') return;

      final playerSnap = await tx.get(playerRef);
      final currentState = _readString(playerSnap.data()?['state']);
      final alreadyFinished = currentState == 'finished';
      final pUids = (matchData['playerUids'] as List? ?? const <dynamic>[])
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      if (pUids.length < 2 || !pUids.contains(uid)) {
        if (kDebugMode) {
          debugPrint(
            '[live-duel] reportFinish rejected: uid not participant '
            'match=$normalizedId uid=$uid players=$pUids',
          );
        }
        return;
      }
      final opponentUid = pUids.firstWhere((id) => id != uid, orElse: () => '');
      final startAtMs = _readInt(matchData['startAtMs']);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final derivedMs = startAtMs > 0 ? max(1, nowMs - startAtMs) : 0;
      var officialMs = elapsedMsFromStart > 0 ? elapsedMsFromStart : derivedMs;
      if (officialMs <= 0) {
        officialMs = max(1, elapsedMsFromStart);
      }
      if (officialMs <= 0) {
        officialMs = 1;
      }

      if (!alreadyFinished) {
        tx.set(
          playerRef,
          <String, dynamic>{
            'state': 'finished',
            'completed': true,
            'finishedAtMsFromStart': officialMs,
            'finishedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      final timeField = uid == _readString(matchData['createdByUid'])
          ? 'playerATimeMs'
          : 'playerBTimeMs';
      tx.set(
        matchRef,
        <String, dynamic>{
          timeField: officialMs,
        },
        SetOptions(merge: true),
      );

      final winnerUid = _readString(matchData['winnerUid']);
      if (winnerUid.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[live-duel] finish recorded (winner already locked) '
            'match=$normalizedId uid=$uid winner=$winnerUid ms=$officialMs',
          );
        }
        return;
      }

      tx.set(
        matchRef,
        <String, dynamic>{
          'status': 'finished',
          'winnerUid': uid,
          'loserUid': opponentUid,
          'reason': 'completed',
          'finishedAt': FieldValue.serverTimestamp(),
          'resultResolvedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(
        playerRef,
        <String, dynamic>{'resultPlace': 1},
        SetOptions(merge: true),
      );
      if (kDebugMode) {
        debugPrint(
          '[live-duel] winner resolved match=$normalizedId winner=$uid '
          'loser=$opponentUid ms=$officialMs',
        );
      }
    });
    try {
      await _realtimeRef(normalizedId).doc(uid).set(
        <String, dynamic>{
          'uid': uid,
          'state': 'finished',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<void> markAbandoned(String matchId) async {
    final uid = await _requireUid();
    final normalizedId = matchId.trim();
    if (normalizedId.isEmpty) return;
    await expireIfStale(normalizedId);
    final matchRef = _db().collection('liveMatches').doc(normalizedId);
    final playerRef = matchRef.collection('players').doc(uid);
    await _db().runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      if (!matchSnap.exists) return;
      final status = _readString(matchSnap.data()?['status']);
      if (status == 'cancelled') return;
      tx.set(
        playerRef,
        <String, dynamic>{
          'state': 'abandoned',
          'completed': false,
          'resultPlace': 2,
          'finishedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
    try {
      await _realtimeRef(normalizedId).doc(uid).set(
        <String, dynamic>{
          'uid': uid,
          'state': 'abandoned',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
    await resolveWinner(matchId);
  }

  Stream<LiveMatchRealtimeTrail?> watchRealtimeTrail({
    required String matchId,
    required String uid,
  }) {
    final normalizedId = matchId.trim();
    final normalizedUid = uid.trim();
    if (normalizedId.isEmpty || normalizedUid.isEmpty) {
      return Stream<LiveMatchRealtimeTrail?>.value(null);
    }
    return _realtimeRef(normalizedId)
        .doc(normalizedUid)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return LiveMatchRealtimeTrail.fromFirestore(
        snap.data() ?? <String, dynamic>{},
      );
    });
  }

  Future<void> publishRealtimeTrail({
    required String matchId,
    required List<int> pathCells,
    String state = 'drawing',
    int pathVersion = 0,
  }) async {
    final uid = await _requireUid();
    final normalizedId = matchId.trim();
    if (normalizedId.isEmpty) return;
    final normalizedState = state.trim().isEmpty ? 'drawing' : state.trim();
    final sanitizedPath =
        pathCells.where((e) => e >= 0).toList(growable: false);
    await _realtimeRef(normalizedId).doc(uid).set(
      <String, dynamic>{
        'uid': uid,
        'pathCells': sanitizedPath,
        'state': normalizedState,
        'pathVersion': pathVersion,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> clearRealtimeTrail({
    required String matchId,
    String state = 'stopped',
  }) async {
    final uid = await _requireUid();
    final normalizedId = matchId.trim();
    if (normalizedId.isEmpty) return;
    await _realtimeRef(normalizedId).doc(uid).set(
      <String, dynamic>{
        'uid': uid,
        'pathCells': const <int>[],
        'state': state.trim().isEmpty ? 'stopped' : state.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<LiveMatchEmote>> watchMatchEmotes(
    String matchId, {
    int limit = 20,
  }) {
    final normalizedId = matchId.trim();
    if (normalizedId.isEmpty) {
      return Stream<List<LiveMatchEmote>>.value(const <LiveMatchEmote>[]);
    }
    final qLimit = limit.clamp(1, 50);
    return _emotesRef(normalizedId)
        .orderBy('createdAt', descending: true)
        .limit(qLimit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => LiveMatchEmote.fromFirestore(d.id, d.data()))
              .toList(growable: false),
        );
  }

  Future<void> sendMatchEmote({
    required String matchId,
    required String emoteId,
  }) async {
    final uid = await _requireUid();
    final normalizedId = matchId.trim();
    final normalizedEmote = emoteId.trim();
    if (normalizedId.isEmpty || normalizedEmote.isEmpty) return;

    final matchRef = _db().collection('liveMatches').doc(normalizedId);
    final playerRef = matchRef.collection('players').doc(uid);
    final emoteRef = _emotesRef(normalizedId).doc();
    var username = '';

    await _db().runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      if (!matchSnap.exists) throw StateError('MATCH_NOT_FOUND');
      final matchData = matchSnap.data() ?? <String, dynamic>{};
      final playerUids = (matchData['playerUids'] as List? ?? const <dynamic>[])
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
      if (!playerUids.contains(uid)) {
        throw StateError('MATCH_ACCESS_DENIED');
      }
      final status = _readString(matchData['status']);
      if (status != 'finished') {
        throw StateError('EMOTES_DISABLED');
      }

      final playerSnap = await tx.get(playerRef);
      final playerData = playerSnap.data() ?? <String, dynamic>{};
      username = _readString(playerData['username']);
      final lastEmoteAtMs = _readInt(playerData['lastEmoteAtMs']);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (lastEmoteAtMs > 0 && (nowMs - lastEmoteAtMs) < _emoteCooldownMs) {
        throw StateError('EMOTE_COOLDOWN');
      }

      tx.set(
        playerRef,
        <String, dynamic>{
          'lastEmoteAtMs': nowMs,
        },
        SetOptions(merge: true),
      );
      tx.set(
        emoteRef,
        <String, dynamic>{
          'emoteId': normalizedEmote,
          'sentByUid': uid,
          'senderUsername': username,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  Future<void> resolveWinner(String matchId) async {
    final normalizedId = matchId.trim();
    if (normalizedId.isEmpty) return;
    final matchRef = _db().collection('liveMatches').doc(normalizedId);
    await _db().runTransaction((tx) async {
      final matchSnap = await tx.get(matchRef);
      if (!matchSnap.exists) return;
      final matchData = matchSnap.data() ?? <String, dynamic>{};
      final status = _readString(matchData['status']);
      if (status == 'cancelled') return;

      final pUids = (matchData['playerUids'] as List?)
              ?.whereType<String>()
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      if (pUids.length < 2) return;
      final p1Ref = matchRef.collection('players').doc(pUids[0]);
      final p2Ref = matchRef.collection('players').doc(pUids[1]);
      final p1Snap = await tx.get(p1Ref);
      final p2Snap = await tx.get(p2Ref);
      final p1 = p1Snap.data() ?? <String, dynamic>{};
      final p2 = p2Snap.data() ?? <String, dynamic>{};

      final s1 = _readString(p1['state']);
      final s2 = _readString(p2['state']);
      final t1 = _readInt(p1['finishedAtMsFromStart']);
      final t2 = _readInt(p2['finishedAtMsFromStart']);

      final existingWinner = _readString(matchData['winnerUid']);
      String winner = existingWinner;
      String loser = _readString(matchData['loserUid']);
      String reason = _readString(matchData['reason']);
      var shouldFinish = false;

      if (s1 == 'abandoned' && s2 == 'abandoned') {
        shouldFinish = true;
        if (winner.isEmpty) {
          winner = '';
          loser = '';
          reason = 'both_abandoned';
        }
      } else if (s1 == 'abandoned' && s2 == 'finished') {
        shouldFinish = true;
        if (winner.isEmpty) {
          winner = pUids[1];
          loser = pUids[0];
          reason = 'opponent_abandoned';
        }
      } else if (s2 == 'abandoned' && s1 == 'finished') {
        shouldFinish = true;
        if (winner.isEmpty) {
          winner = pUids[0];
          loser = pUids[1];
          reason = 'opponent_abandoned';
        }
      } else if (s1 == 'abandoned' && s2 != 'finished') {
        shouldFinish = true;
        if (winner.isEmpty) {
          winner = pUids[1];
          loser = pUids[0];
          reason = 'opponent_abandoned';
        }
      } else if (s2 == 'abandoned' && s1 != 'finished') {
        shouldFinish = true;
        if (winner.isEmpty) {
          winner = pUids[0];
          loser = pUids[1];
          reason = 'opponent_abandoned';
        }
      } else if (s1 == 'finished' && s2 == 'finished' && t1 > 0 && t2 > 0) {
        shouldFinish = true;
        if (winner.isEmpty) {
          if (t1 < t2) {
            winner = pUids[0];
            loser = pUids[1];
          } else if (t2 < t1) {
            winner = pUids[1];
            loser = pUids[0];
          } else {
            winner = '';
            loser = '';
          }
          reason = 'both_finished';
        }
      }

      if (!shouldFinish) return;

      tx.set(
        matchRef,
        <String, dynamic>{
          'status': 'finished',
          'winnerUid': winner,
          'loserUid': loser,
          'reason': reason,
          'finishedAt': FieldValue.serverTimestamp(),
          if (existingWinner.isEmpty)
            'resultResolvedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      // Keep players docs self-owned writable only; result is derived from
      // match winner/loser fields, so we avoid cross-writing rival subdocs.
    });
  }

  Future<LiveDuelCreateResult> createRematch({
    required String previousMatchId,
  }) async {
    final uid = await _requireUid();
    final previous = await getMatch(previousMatchId);
    if (previous == null) throw StateError('MATCH_NOT_FOUND');
    final opponentUid = previous.opponentUid(uid);
    if (opponentUid.isEmpty) throw StateError('INVALID_DUEL_TARGET');
    if (previous.levelId.trim().isEmpty) throw StateError('INVALID_LEVEL_ID');
    return createInvite(toUid: opponentUid, levelId: previous.levelId);
  }

  Future<bool> isUserBusyInDuel(String uid) async {
    return _hasActiveMatch(uid);
  }

  Future<Map<String, bool>> busyMapForUids(List<String> uids) async {
    final out = <String, bool>{};
    for (final uid in uids) {
      final normalized = uid.trim();
      if (normalized.isEmpty) continue;
      out[normalized] = await _hasActiveMatch(normalized);
    }
    return out;
  }

  Future<void> expireIfStale(String matchId) async {
    final normalizedId = matchId.trim();
    if (normalizedId.isEmpty) return;
    final ref = _db().collection('liveMatches').doc(normalizedId);
    await _db().runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() ?? <String, dynamic>{};
      final status = _readString(data['status']);
      if (status == 'finished' || status == 'cancelled') return;
      final now = DateTime.now();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final acceptedAt = (data['acceptedAt'] as Timestamp?)?.toDate();
      final updatedAt = (data['finishedAt'] as Timestamp?)?.toDate();
      String? reason;

      if (status == 'pending' && createdAt != null) {
        if (now.difference(createdAt) > _pendingTtl) {
          reason = 'invite_expired';
        }
      } else if (status == 'countdown') {
        if (acceptedAt == null || now.difference(acceptedAt) > _countdownTtl) {
          reason = 'countdown_timeout';
        }
      } else if (status == 'playing') {
        final anchor = acceptedAt ?? createdAt ?? updatedAt;
        if (anchor != null && now.difference(anchor) > _playingTtl) {
          reason = 'playing_timeout';
        }
      }

      if (reason == null) return;
      tx.set(
        ref,
        <String, dynamic>{
          'status': 'cancelled',
          'reason': reason,
          'finishedAt': FieldValue.serverTimestamp(),
          'winnerUid': '',
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<LiveMatch?> _findActiveMatchBetween({
    required String uidA,
    required String uidB,
    required String levelId,
  }) async {
    // Avoid composite-index requirements (especially in web/internal testing):
    // query by one indexed field and filter remaining conditions client-side.
    final snap = await _db()
        .collection('liveMatches')
        .where('playerUids', arrayContains: uidA)
        .limit(40)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      if (_readString(data['levelId']) != levelId) continue;
      final status = _readString(data['status']);
      if (status == 'finished' || status == 'cancelled') continue;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null &&
          DateTime.now().difference(createdAt).inHours >
              _maxActiveMatchAgeHours) {
        continue;
      }
      final uids = (data['playerUids'] as List?)
              ?.whereType<String>()
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false) ??
          const <String>[];
      if (uids.contains(uidB)) {
        final match = await getMatch(doc.id);
        if (match != null) return match;
      }
    }
    return null;
  }

  Future<bool> _hasActiveMatch(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return false;
    final snap = await _db()
        .collection('liveMatches')
        .where('playerUids', arrayContains: normalizedUid)
        .limit(40)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final status = _readString(data['status']);
      if (status == 'finished' || status == 'cancelled') continue;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final acceptedAt = (data['acceptedAt'] as Timestamp?)?.toDate();
      if (status == 'pending' && createdAt != null) {
        if (DateTime.now().difference(createdAt) > _pendingTtl) continue;
      }
      if (status == 'countdown' && acceptedAt != null) {
        if (DateTime.now().difference(acceptedAt) > _countdownTtl) continue;
      }
      if (status == 'playing') {
        final anchor = acceptedAt ?? createdAt;
        if (anchor != null && DateTime.now().difference(anchor) > _playingTtl) {
          continue;
        }
      }
      if (createdAt != null &&
          DateTime.now().difference(createdAt).inHours >
              _maxActiveMatchAgeHours) {
        continue;
      }
      return true;
    }
    return false;
  }

  CollectionReference<Map<String, dynamic>> _realtimeRef(String matchId) {
    return _db().collection('liveMatches').doc(matchId).collection('realtime');
  }

  CollectionReference<Map<String, dynamic>> _emotesRef(String matchId) {
    return _db()
        .collection('liveMatches')
        .doc(matchId)
        .collection('postMatchEmotes');
  }

  static LevelRouteInfo? parseLevelRouteInfo(String levelId) {
    final value = levelId.trim();
    if (value.isEmpty) return null;
    final idx = value.lastIndexOf('_');
    if (idx <= 0 || idx >= value.length - 1) return null;
    final pack = value.substring(0, idx).trim();
    final levelText = value.substring(idx + 1).trim();
    final level = int.tryParse(levelText) ?? 0;
    if (pack.isEmpty || level <= 0) return null;
    return LevelRouteInfo(packId: pack, levelIndex: level);
  }

  String _readString(Object? value, {String fallback = ''}) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
  }

  int _readInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  FirebaseFirestore _db() {
    try {
      return FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: _firestoreDatabaseId,
      );
    } catch (_) {
      return FirebaseFirestore.instance;
    }
  }

  Future<String> _requireUid() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      throw StateError('AUTH_REQUIRED');
    }
    return uid;
  }
}
