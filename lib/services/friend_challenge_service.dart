import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/friend_challenge.dart';
import '../pack_level_repository.dart';
import 'inbox_service.dart';

class FriendChallengeService {
  static const String _firestoreDatabaseId = 'tracepath-database';
  static const List<String> _challengePackIds = <String>[
    'world_01',
    'world_02',
    'world_03',
    'world_04',
    'world_05',
    'world_06',
    'world_07',
    'world_08',
    'world_09',
    'world_10',
    'world_11',
    'world_12',
    'world_13',
    'world_14',
    'world_15',
    'world_16',
    'world_17',
    'classic',
  ];

  final InboxService _inboxService = InboxService();
  final Random _random = Random();

  Future<void> createRandomFriendChallenge({
    required String challengerUid,
    required String challengedUid,
    String? currentLevelId,
    String? sourceScreen,
  }) async {
    final authUid = await _requireUid();
    final normalizedChallenger = challengerUid.trim();
    final normalizedTarget = challengedUid.trim();
    final excluded = (currentLevelId ?? '').trim();
    final source = (sourceScreen ?? 'unknown').trim();
    if (normalizedChallenger.isEmpty || normalizedTarget.isEmpty) {
      throw StateError('INVALID_USER_IDS');
    }
    if (normalizedChallenger != authUid) {
      throw StateError('AUTH_UID_MISMATCH');
    }
    if (normalizedChallenger == normalizedTarget) {
      throw StateError('INVALID_CHALLENGE_TARGET');
    }

    debugPrint(
      '[FRIEND_CHALLENGE] Challenge button pressed from [$source]',
    );
    debugPrint('[FRIEND_CHALLENGE] Using centralized FriendChallengeService');
    debugPrint('[FRIEND_CHALLENGE] Excluded level: $excluded');

    final selected = await _selectRandomPuzzle(excludedLevelId: excluded);
    if (selected == null) {
      throw StateError('NO_PUZZLES_AVAILABLE');
    }
    debugPrint(
        '[FRIEND_CHALLENGE] Random puzzle selected: ${selected.puzzleId}');

    final challengeRef = _db().collection('friend_challenges').doc();
    final createdAtMs = DateTime.now().millisecondsSinceEpoch;
    final duplicate = await _findRecentDuplicate(
      challengerId: normalizedChallenger,
      challengedUserId: normalizedTarget,
      puzzleId: selected.puzzleId,
    );
    if (duplicate != null) {
      debugPrint(
          '[FRIEND_CHALLENGE] Duplicate ignored: ${duplicate.challengeId}');
      return;
    }

    final payload = <String, dynamic>{
      'challengeId': challengeRef.id,
      'challengerUserId': normalizedChallenger,
      'challengedUserId': normalizedTarget,
      'puzzleId': selected.puzzleId,
      'packId': selected.packId,
      'levelIndex': selected.levelIndex,
      'mode': 'friend_challenge',
      'createdAt': FieldValue.serverTimestamp(),
      'createdAtMs': createdAtMs,
      'status': 'pending',
      'puzzleDifficulty': selected.difficulty,
      'gridWidth': selected.width,
      'gridHeight': selected.height,
      'excludedLevelId': excluded,
    };
    await challengeRef.set(payload, SetOptions(merge: true));
    await _inboxService.addInboxItem(
      uid: normalizedTarget,
      type: 'friend_challenge',
      title: 'Friendly Challenge',
      body: 'You received a new friendly challenge.',
      status: 'pending',
      extraData: <String, dynamic>{
        'fromUid': normalizedChallenger,
        'ctaType': 'open_friend_challenge',
        'ctaPayload': challengeRef.id,
        'challengeId': challengeRef.id,
        'puzzleId': selected.puzzleId,
        'mode': 'friend_challenge',
      },
      messageId: 'friend_challenge_${challengeRef.id}',
    );
    debugPrint('[FRIEND_CHALLENGE] Challenge created successfully');
  }

  Future<void> createChallenge({
    required String challengerId,
    required String challengedUserId,
    required String? currentLevelId,
  }) {
    return createRandomFriendChallenge(
      challengerUid: challengerId,
      challengedUid: challengedUserId,
      currentLevelId: currentLevelId,
      sourceScreen: 'legacy_callsite',
    );
  }

  Future<FriendChallenge?> getChallenge(String challengeId) async {
    final id = challengeId.trim();
    if (id.isEmpty) return null;
    final snap = await _db().collection('friend_challenges').doc(id).get();
    if (!snap.exists) return null;
    return FriendChallenge.fromFirestore(
      snap.id,
      snap.data() ?? <String, dynamic>{},
    );
  }

  Future<void> acknowledgeInviteOpened({
    required String challengeId,
  }) async {
    final uid = await _requireUid();
    final id = challengeId.trim();
    if (id.isEmpty) return;

    final challengeRef = _db().collection('friend_challenges').doc(id);
    String challengerUid = '';
    await _db().runTransaction((tx) async {
      final snap = await tx.get(challengeRef);
      if (!snap.exists) return;
      final data = snap.data() ?? <String, dynamic>{};
      final challengedUid = _readString(data['challengedUserId']);
      challengerUid = _readString(data['challengerUserId']);
      if (challengedUid != uid || challengerUid.isEmpty) {
        challengerUid = '';
        return;
      }
      final status = _readString(data['status'], fallback: 'pending');
      if (status == 'pending') {
        tx.set(
          challengeRef,
          <String, dynamic>{
            'status': 'active',
            'acceptedByUid': uid,
            'acceptedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });

    if (challengerUid.isEmpty || challengerUid == uid) return;
    final me = await _readUserData(uid);
    final username = _readString(me?['username']);
    final playerName = _readString(me?['playerName'], fallback: 'Player');
    final avatarId = _readString(me?['avatarId'], fallback: 'default');
    final label = username.isNotEmpty ? '@$username' : playerName;
    await _inboxService.addInboxItem(
      uid: challengerUid,
      type: 'system_news',
      title: 'Challenge accepted',
      body: '$label accepted your friendly challenge.',
      status: 'accepted',
      extraData: <String, dynamic>{
        'fromUid': uid,
        'fromUsername': username,
        'fromPlayerName': playerName,
        'fromAvatarId': avatarId,
        'ctaType': 'open_friend_challenge',
        'ctaPayload': id,
        'challengeId': id,
        'relatedType': 'friend_challenge',
      },
      messageId: 'friend_challenge_accept_${id}_$uid',
    );
  }

  Future<void> declineInvite({
    required String challengeId,
    String? inboxMessageId,
  }) async {
    final uid = await _requireUid();
    final id = challengeId.trim();
    if (id.isEmpty) {
      throw StateError('INVALID_CHALLENGE_ID');
    }
    final challengeRef = _db().collection('friend_challenges').doc(id);
    String challengerUid = '';
    await _db().runTransaction((tx) async {
      final snap = await tx.get(challengeRef);
      if (!snap.exists) throw StateError('CHALLENGE_NOT_FOUND');
      final data = snap.data() ?? <String, dynamic>{};
      final challengedUid = _readString(data['challengedUserId']);
      challengerUid = _readString(data['challengerUserId']);
      if (challengedUid != uid) throw StateError('CHALLENGE_ACCESS_DENIED');
      final status = _readString(data['status'], fallback: 'pending');
      if (status == 'declined') return;
      tx.set(
        challengeRef,
        <String, dynamic>{
          'status': 'declined',
          'declinedByUid': uid,
          'declinedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    final inboxId = (inboxMessageId ?? '').trim();
    if (inboxId.isNotEmpty) {
      await _inboxService.deleteInboxItem(uid: uid, messageId: inboxId);
    }

    if (challengerUid.isEmpty || challengerUid == uid) return;
    final me = await _readUserData(uid);
    final username = _readString(me?['username']);
    final playerName = _readString(me?['playerName'], fallback: 'Player');
    final avatarId = _readString(me?['avatarId'], fallback: 'default');
    final label = username.isNotEmpty ? '@$username' : playerName;
    await _inboxService.addInboxItem(
      uid: challengerUid,
      type: 'system_news',
      title: 'Challenge declined',
      body: '$label declined your friendly challenge.',
      status: 'declined',
      extraData: <String, dynamic>{
        'fromUid': uid,
        'fromUsername': username,
        'fromPlayerName': playerName,
        'fromAvatarId': avatarId,
        'ctaType': 'open_social',
        'ctaPayload': '/social',
        'challengeId': id,
        'relatedType': 'friend_challenge',
      },
      messageId: 'friend_challenge_decline_${id}_$uid',
    );
  }

  Future<void> markCompleted({
    required String challengeId,
    required int elapsedMs,
  }) async {
    final uid = await _requireUid();
    final id = challengeId.trim();
    if (id.isEmpty || elapsedMs <= 0) return;
    final challengeRef = _db().collection('friend_challenges').doc(id);
    final snap = await challengeRef.get();
    if (!snap.exists) return;
    final challenge = FriendChallenge.fromFirestore(
      snap.id,
      snap.data() ?? <String, dynamic>{},
    );
    if (!challenge.involvesUser(uid)) return;

    final resultRef =
        _db().collection('friend_challenge_results').doc('${id}_$uid');
    await resultRef.set(
      <String, dynamic>{
        'challengeId': id,
        'userId': uid,
        'mode': 'friend_challenge',
        'elapsedMs': elapsedMs,
        'puzzleId': challenge.puzzleId,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    if (uid == challenge.challengerUserId) {
      await challengeRef.set(
        <String, dynamic>{
          'challengerResultMs': elapsedMs,
          'status': 'active',
        },
        SetOptions(merge: true),
      );
    } else if (uid == challenge.challengedUserId) {
      await challengeRef.set(
        <String, dynamic>{
          'challengedResultMs': elapsedMs,
          'status': 'active',
        },
        SetOptions(merge: true),
      );
    }
  }

  Future<FriendChallenge?> _findRecentDuplicate({
    required String challengerId,
    required String challengedUserId,
    required String puzzleId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final snap = await _db()
        .collection('friend_challenges')
        .where('challengerUserId', isEqualTo: challengerId)
        .limit(30)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final status = (data['status'] as String?)?.trim() ?? '';
      final target = (data['challengedUserId'] as String?)?.trim() ?? '';
      final docPuzzle = (data['puzzleId'] as String?)?.trim() ?? '';
      final createdAtMs =
          data['createdAtMs'] is num ? (data['createdAtMs'] as num).toInt() : 0;
      final isFresh = createdAtMs > 0 && (now - createdAtMs) <= 60000;
      if (target == challengedUserId &&
          docPuzzle == puzzleId &&
          status == 'pending' &&
          isFresh) {
        return FriendChallenge.fromFirestore(doc.id, data);
      }
    }
    return null;
  }

  Future<_ChallengePuzzleRef?> _selectRandomPuzzle({
    required String excludedLevelId,
  }) async {
    final repo = PackLevelRepository.instance;
    for (final packId in _challengePackIds) {
      await repo.loadPack(packId);
    }

    _ChallengePuzzleRef? current;
    final parsed = _parseLevelRouteInfo(excludedLevelId);
    if (parsed != null) {
      final record = await repo.getLevel(parsed.$1, parsed.$2);
      if (record != null) {
        current = _ChallengePuzzleRef(
          packId: parsed.$1,
          levelIndex: parsed.$2,
          puzzleId: '${parsed.$1}_${parsed.$2}',
          difficulty: record.level.difficulty,
          width: record.level.width,
          height: record.level.height,
        );
      }
    }

    final pool = <_ChallengePuzzleRef>[];
    for (final packId in _challengePackIds) {
      final total = repo.totalLevelsSync(packId);
      for (var i = 1; i <= total; i++) {
        final record = repo.getLevelSync(packId, i);
        if (record == null) continue;
        final id = '${packId}_$i';
        if (id == excludedLevelId) continue;
        pool.add(
          _ChallengePuzzleRef(
            packId: packId,
            levelIndex: i,
            puzzleId: id,
            difficulty: record.level.difficulty,
            width: record.level.width,
            height: record.level.height,
          ),
        );
      }
    }
    if (pool.isEmpty) return null;
    if (pool.length == 1) return pool.first;

    if (current != null) {
      final exact = pool
          .where((p) =>
              p.difficulty == current!.difficulty &&
              p.width == current.width &&
              p.height == current.height)
          .toList(growable: false);
      if (exact.isNotEmpty) {
        return exact[_random.nextInt(exact.length)];
      }
      final partial = pool
          .where((p) =>
              p.difficulty == current!.difficulty ||
              (p.width == current.width && p.height == current.height))
          .toList(growable: false);
      if (partial.isNotEmpty) {
        return partial[_random.nextInt(partial.length)];
      }
    }
    return pool[_random.nextInt(pool.length)];
  }

  (String, int)? _parseLevelRouteInfo(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    final idx = normalized.lastIndexOf('_');
    if (idx <= 0 || idx >= normalized.length - 1) return null;
    final pack = normalized.substring(0, idx).trim();
    final level = int.tryParse(normalized.substring(idx + 1).trim()) ?? 0;
    if (pack.isEmpty || level <= 0) return null;
    return (pack, level);
  }

  Future<Map<String, dynamic>?> _readUserData(String uid) async {
    final snap = await _db().collection('users').doc(uid.trim()).get();
    if (!snap.exists) return null;
    return snap.data() ?? <String, dynamic>{};
  }

  String _readString(Object? value, {String fallback = ''}) {
    final text = value is String ? value.trim() : '';
    return text.isEmpty ? fallback : text;
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

class _ChallengePuzzleRef {
  const _ChallengePuzzleRef({
    required this.packId,
    required this.levelIndex,
    required this.puzzleId,
    required this.difficulty,
    required this.width,
    required this.height,
  });

  final String packId;
  final int levelIndex;
  final String puzzleId;
  final int difficulty;
  final int width;
  final int height;
}
