import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/leaderboard_entry.dart';

class SocialLeaderboardService {
  static const String _firestoreDatabaseId = 'tracepath-database';

  Future<void> submitLevelScore({
    required String uid,
    required String levelId,
    required String username,
    required String playerName,
    String photoUrl = '',
    required String avatarId,
    required String equippedSkinId,
    required String equippedTrailId,
    required int bestTimeMs,
    required int moves,
    required int stars,
  }) async {
    final normalizedUid = uid.trim().isEmpty ? await _requireUid() : uid.trim();
    final normalizedLevelId = levelId.trim();
    if (normalizedLevelId.isEmpty || bestTimeMs <= 0) return;
    final scoreRef = _db()
        .collection('leaderboards')
        .doc(normalizedLevelId)
        .collection('scores')
        .doc(normalizedUid);

    await _db().runTransaction((tx) async {
      final currentSnap = await tx.get(scoreRef);
      final currentData = currentSnap.data() ?? <String, dynamic>{};
      final currentBest = LeaderboardEntry.readInt(currentData['bestTimeMs']);
      final currentMoves = LeaderboardEntry.readInt(currentData['moves']);
      final betterByTime = !currentSnap.exists ||
          currentBest <= 0 ||
          bestTimeMs < currentBest;
      final betterByMoves = currentSnap.exists &&
          currentBest > 0 &&
          bestTimeMs == currentBest &&
          (currentMoves <= 0 || (moves > 0 && moves < currentMoves));
      if (!betterByTime && !betterByMoves) return;

      tx.set(
        scoreRef,
        <String, dynamic>{
          'uid': normalizedUid,
          'playerName': playerName.trim().isEmpty ? 'Player' : playerName.trim(),
          'username': username.trim(),
          'photoUrl': photoUrl.trim(),
          'avatarId': avatarId.trim().isEmpty ? 'default' : avatarId.trim(),
          'equippedSkinId':
              equippedSkinId.trim().isEmpty ? 'default' : equippedSkinId.trim(),
          'equippedTrailId':
              equippedTrailId.trim().isEmpty ? 'none' : equippedTrailId.trim(),
          'levelId': normalizedLevelId,
          'bestTimeMs': bestTimeMs,
          'moves': moves,
          'stars': stars,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> submitLevelResult({
    required String levelId,
    required int bestTimeMs,
    required int moves,
    required int stars,
  }) async {
    final uid = await _requireUid();
    final normalizedLevelId = levelId.trim();
    if (normalizedLevelId.isEmpty || bestTimeMs <= 0) return;
    final userRef = _db().collection('users').doc(uid);
    final userSnap = await userRef.get();
    final userData = userSnap.data() ?? <String, dynamic>{};
    final playerName =
        ((userData['playerName'] as String?)?.trim().isNotEmpty == true)
            ? (userData['playerName'] as String).trim()
            : 'Player';
    final username = (userData['username'] as String?)?.trim() ?? '';
    final photoUrl = (userData['photoUrl'] as String?)?.trim().isNotEmpty == true
        ? (userData['photoUrl'] as String).trim()
        : ((userData['photoURL'] as String?)?.trim().isNotEmpty == true
            ? (userData['photoURL'] as String).trim()
            : (FirebaseAuth.instance.currentUser?.photoURL ?? '').trim());
    final avatarId =
        ((userData['avatarId'] as String?)?.trim().isNotEmpty == true)
            ? (userData['avatarId'] as String).trim()
            : 'default';
    final equippedSkinId =
        ((userData['equippedSkinId'] as String?)?.trim().isNotEmpty == true)
            ? (userData['equippedSkinId'] as String).trim()
            : 'default';
    final equippedTrailId =
        ((userData['equippedTrailId'] as String?)?.trim().isNotEmpty == true)
            ? (userData['equippedTrailId'] as String).trim()
            : 'none';

    await submitLevelScore(
      uid: uid,
      levelId: normalizedLevelId,
      username: username,
      playerName: playerName,
      photoUrl: photoUrl,
      avatarId: avatarId,
      equippedSkinId: equippedSkinId,
      equippedTrailId: equippedTrailId,
      bestTimeMs: bestTimeMs,
      moves: moves,
      stars: stars,
    );
    if (kDebugMode) {
      debugPrint(
        '[leaderboard] submitLevelResult saved levelId=$normalizedLevelId uid=$uid bestTimeMs=$bestTimeMs moves=$moves stars=$stars',
      );
    }
  }

  Future<void> persistCompletedLevel({
    required String levelId,
    required int bestTimeMs,
    required int moves,
    required int stars,
    int? highestLevelReached,
  }) async {
    final uid = await _requireUid();
    final normalizedLevelId = levelId.trim();
    if (normalizedLevelId.isEmpty) return;

    final completedRef = _db()
        .collection('users')
        .doc(uid)
        .collection('completed_levels')
        .doc(normalizedLevelId);
    final userRef = _db().collection('users').doc(uid);

    if (kDebugMode) {
      debugPrint(
        '[leaderboard] persistCompletedLevel uid=$uid levelId=$normalizedLevelId bestTimeMs=$bestTimeMs moves=$moves stars=$stars',
      );
      debugPrint(
        '[leaderboard] write path: users/$uid/completed_levels/$normalizedLevelId',
      );
    }

    await _db().runTransaction((tx) async {
      final completedSnap = await tx.get(completedRef);
      final current = completedSnap.data() ?? <String, dynamic>{};
      final currentBest = LeaderboardEntry.readInt(current['bestTimeMs']);
      final currentMoves = LeaderboardEntry.readInt(current['moves']);
      final betterByTime = !completedSnap.exists ||
          currentBest <= 0 ||
          (bestTimeMs > 0 && bestTimeMs < currentBest);
      final betterByMoves = completedSnap.exists &&
          currentBest > 0 &&
          bestTimeMs == currentBest &&
          (currentMoves <= 0 || (moves > 0 && moves < currentMoves));

      final payload = <String, dynamic>{
        'levelId': normalizedLevelId,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (!completedSnap.exists) {
        payload['completedAt'] = FieldValue.serverTimestamp();
      }
      if (betterByTime || betterByMoves) {
        payload['bestTimeMs'] = bestTimeMs;
        payload['moves'] = moves;
        payload['stars'] = stars;
      } else {
        payload['bestTimeMs'] = currentBest > 0 ? currentBest : bestTimeMs;
        payload['moves'] = currentMoves > 0 ? currentMoves : moves;
        payload['stars'] = max(
          LeaderboardEntry.readInt(current['stars']),
          stars,
        );
      }
      tx.set(completedRef, payload, SetOptions(merge: true));
    });

    final completedSnap = await _db()
        .collection('users')
        .doc(uid)
        .collection('completed_levels')
        .get();
    final totalCompleted = completedSnap.docs.length;
    final currentUserSnap = await userRef.get();
    final currentUser = currentUserSnap.data() ?? <String, dynamic>{};
    final currentHighest = LeaderboardEntry.readInt(
      currentUser['highestLevelReached'],
    );
    final currentFastest = LeaderboardEntry.readInt(currentUser['fastestSolveMs']);

    final nextFastest = bestTimeMs <= 0
        ? currentFastest
        : (currentFastest <= 0 ? bestTimeMs : (bestTimeMs < currentFastest ? bestTimeMs : currentFastest));
    final nextHighest = highestLevelReached != null &&
            highestLevelReached > currentHighest
        ? highestLevelReached
        : currentHighest;

    if (kDebugMode) {
      debugPrint(
        '[leaderboard] write path: users/$uid stats totalLevelsCompleted=$totalCompleted highestLevelReached=$nextHighest fastestSolveMs=$nextFastest',
      );
    }

    await userRef.set(
      <String, dynamic>{
        'totalLevelsCompleted': totalCompleted,
        'highestLevelReached': nextHighest,
        'fastestSolveMs': nextFastest,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<List<LeaderboardEntry>> getTopScores(
    String levelId, {
    int limit = 50,
  }) async {
    final normalized = levelId.trim();
    if (normalized.isEmpty) return const <LeaderboardEntry>[];
    final safeLimit = limit <= 0 ? 1 : (limit > 200 ? 200 : limit);
    final snap = await _db()
        .collection('leaderboards')
        .doc(normalized)
        .collection('scores')
        .orderBy('bestTimeMs')
        .limit(safeLimit)
        .get();
    final items = snap.docs
        .map((doc) => LeaderboardEntry.fromFirestore(doc.data()))
        .toList(growable: false);
    final filtered = items.where((e) => e.bestTimeMs > 0).toList(growable: false)
      ..sort(_compareEntries);
    return filtered;
  }

  Stream<List<LeaderboardEntry>> watchTopScores(
    String levelId, {
    int limit = 50,
  }) async* {
    final normalized = levelId.trim();
    if (normalized.isEmpty) {
      yield const <LeaderboardEntry>[];
      return;
    }
    final safeLimit = limit <= 0 ? 1 : (limit > 200 ? 200 : limit);
    yield* _db()
        .collection('leaderboards')
        .doc(normalized)
        .collection('scores')
        .orderBy('bestTimeMs')
        .limit(safeLimit)
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((doc) => LeaderboardEntry.fromFirestore(doc.data()))
          .where((e) => e.bestTimeMs > 0)
          .toList(growable: false)
        ..sort(_compareEntries);
      return items;
    });
  }

  Future<List<LeaderboardEntry>> getFriendsTopScores(
    String levelId, {
    bool includeCurrentUser = true,
  }) async {
    final uid = await _requireUid();
    final normalized = levelId.trim();
    if (normalized.isEmpty) return const <LeaderboardEntry>[];

    final friendsSnap =
        await _db().collection('users').doc(uid).collection('friends').get();
    final allowed = <String>{
      if (includeCurrentUser) uid,
      ...friendsSnap.docs.map((d) => d.id),
    };
    if (allowed.isEmpty) return const <LeaderboardEntry>[];

    final all = await getTopScores(normalized, limit: 200);
    final filtered = all.where((e) => allowed.contains(e.uid)).toList(growable: false)
      ..sort(_compareEntries);
    if (kDebugMode) {
      debugPrint(
        '[leaderboard] friends filter levelId=$normalized currentUid=$uid allowedIds=${allowed.length} result=${filtered.length}',
      );
    }
    return filtered;
  }

  Future<LeaderboardEntry?> getUserScore({
    required String levelId,
    required String uid,
  }) async {
    final normalized = levelId.trim();
    final normalizedUid = uid.trim().isEmpty ? await _requireUid() : uid.trim();
    if (normalized.isEmpty) return null;
    final snap = await _db()
        .collection('leaderboards')
        .doc(normalized)
        .collection('scores')
        .doc(normalizedUid)
        .get();
    if (!snap.exists) return null;
    final entry = LeaderboardEntry.fromFirestore(
      snap.data() ?? <String, dynamic>{},
    );
    return entry.bestTimeMs > 0 ? entry : null;
  }

  Future<LeaderboardEntry?> getCurrentUserScore(String levelId) async {
    final uid = await _requireUid();
    return getUserScore(levelId: levelId, uid: uid);
  }

  int _compareEntries(LeaderboardEntry a, LeaderboardEntry b) {
    final byTime = a.bestTimeMs.compareTo(b.bestTimeMs);
    if (byTime != 0) return byTime;
    final aMoves = a.moves <= 0 ? 1 << 30 : a.moves;
    final bMoves = b.moves <= 0 ? 1 << 30 : b.moves;
    final byMoves = aMoves.compareTo(bMoves);
    if (byMoves != 0) return byMoves;
    return a.uid.compareTo(b.uid);
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
