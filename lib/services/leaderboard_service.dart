import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/leaderboard_entry.dart';

class SocialLeaderboardService {
  static const String _firestoreDatabaseId = 'tracepath-database';
  static const String _globalLeaderboardId = 'global';

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
      final currentFirst = LeaderboardEntry.readInt(
        currentData['firstClearTimeMs'],
      );
      final currentRanking = LeaderboardEntry.readInt(
        currentData['rankingTimeMs'],
      );
      final currentPersonal = LeaderboardEntry.readInt(
        currentData['personalBestTimeMs'],
      );
      final currentMoves = LeaderboardEntry.readInt(currentData['moves']);
      final resolvedFirstFromLegacy = currentFirst > 0
          ? currentFirst
          : (currentRanking > 0
              ? currentRanking
              : (currentBest > 0 ? currentBest : bestTimeMs));
      final rankingTimeMs =
          resolvedFirstFromLegacy > 0 ? resolvedFirstFromLegacy : bestTimeMs;
      final personalBestMs = currentSnap.exists
          ? (() {
              final base = currentPersonal > 0
                  ? currentPersonal
                  : (currentBest > 0 ? currentBest : bestTimeMs);
              if (base <= 0) return bestTimeMs;
              if (bestTimeMs <= 0) return base;
              return bestTimeMs < base ? bestTimeMs : base;
            })()
          : bestTimeMs;
      final betterByMoves = currentSnap.exists &&
          rankingTimeMs > 0 &&
          bestTimeMs == rankingTimeMs &&
          (currentMoves <= 0 || (moves > 0 && moves < currentMoves));

      tx.set(
        scoreRef,
        <String, dynamic>{
          'uid': normalizedUid,
          'playerName':
              playerName.trim().isEmpty ? 'Player' : playerName.trim(),
          'username': username.trim(),
          'photoUrl': photoUrl.trim(),
          'avatarId': avatarId.trim().isEmpty ? 'default' : avatarId.trim(),
          'equippedSkinId':
              equippedSkinId.trim().isEmpty ? 'default' : equippedSkinId.trim(),
          'equippedTrailId':
              equippedTrailId.trim().isEmpty ? 'none' : equippedTrailId.trim(),
          'levelId': normalizedLevelId,
          // Keep ranking immutable as first clear once set.
          'bestTimeMs': rankingTimeMs,
          'firstClearTimeMs': rankingTimeMs,
          'rankingTimeMs': rankingTimeMs,
          // Personal best can improve and is consumed by self-improvement modes.
          'personalBestTimeMs': personalBestMs,
          'moves': !currentSnap.exists
              ? moves
              : (betterByMoves ? moves : currentMoves),
          'stars': !currentSnap.exists
              ? stars
              : max(LeaderboardEntry.readInt(currentData['stars']), stars),
          if (!currentSnap.exists) 'firstClearAt': FieldValue.serverTimestamp(),
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
    final photoUrl =
        (userData['photoUrl'] as String?)?.trim().isNotEmpty == true
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
      final currentFirst =
          LeaderboardEntry.readInt(current['firstClearTimeMs']);
      final currentPersonal = LeaderboardEntry.readInt(
        current['personalBestTimeMs'],
      );
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
        payload['firstClearTimeMs'] = bestTimeMs;
      }
      final effectiveFirst = currentFirst > 0
          ? currentFirst
          : (currentBest > 0 ? currentBest : bestTimeMs);
      if (effectiveFirst > 0) {
        payload['firstClearTimeMs'] = effectiveFirst;
      }
      final effectivePersonal = (() {
        final base = currentPersonal > 0
            ? currentPersonal
            : (currentBest > 0 ? currentBest : bestTimeMs);
        if (base <= 0) return bestTimeMs;
        if (bestTimeMs <= 0) return base;
        return bestTimeMs < base ? bestTimeMs : base;
      })();
      if (effectivePersonal > 0) {
        payload['personalBestTimeMs'] = effectivePersonal;
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
    final avgSolveTimeMs = _computeAverageSolveTimeMs(completedSnap.docs);
    final averagedLevelCount = _countValidAverageLevels(completedSnap.docs);
    final totalCompleted = completedSnap.docs.length;
    final currentUserSnap = await userRef.get();
    final currentUser = currentUserSnap.data() ?? <String, dynamic>{};
    final currentHighest = LeaderboardEntry.readInt(
      currentUser['highestLevelReached'],
    );
    final currentFastest =
        LeaderboardEntry.readInt(currentUser['fastestSolveMs']);

    final nextFastest = bestTimeMs <= 0
        ? currentFastest
        : (currentFastest <= 0
            ? bestTimeMs
            : (bestTimeMs < currentFastest ? bestTimeMs : currentFastest));
    final nextHighest =
        highestLevelReached != null && highestLevelReached > currentHighest
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

    await _upsertGlobalScore(
      uid: uid,
      userData: currentUser,
      totalLevelsCompleted: totalCompleted,
      highestLevelReached: nextHighest,
      fastestSolveMs: nextFastest,
      avgSolveTimeMs: avgSolveTimeMs,
      averagedLevelCount: averagedLevelCount,
    );
  }

  Future<List<LeaderboardEntry>> getGlobalTopScores({int limit = 10}) async {
    final safeLimit = limit <= 0 ? 1 : (limit > 200 ? 200 : limit);
    final snap = await _db()
        .collection('leaderboards')
        .doc(_globalLeaderboardId)
        .collection('scores')
        .orderBy('globalScore', descending: true)
        .orderBy('bestTimeMs')
        .limit(safeLimit)
        .get();
    final items = snap.docs
        .map((doc) => LeaderboardEntry.fromFirestore(doc.data()))
        .toList(growable: false);
    final filtered =
        items.where((e) => e.uid.trim().isNotEmpty).toList(growable: false);
    return filtered;
  }

  Stream<List<LeaderboardEntry>> watchGlobalTopScores({int limit = 10}) async* {
    final safeLimit = limit <= 0 ? 1 : (limit > 200 ? 200 : limit);
    yield* _db()
        .collection('leaderboards')
        .doc(_globalLeaderboardId)
        .collection('scores')
        .orderBy('globalScore', descending: true)
        .orderBy('bestTimeMs')
        .limit(safeLimit)
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((doc) => LeaderboardEntry.fromFirestore(doc.data()))
          .where((e) => e.uid.trim().isNotEmpty)
          .toList(growable: false);
      return items;
    });
  }

  Stream<Map<String, dynamic>?> watchCurrentGlobalProfile() async* {
    final uid = await _requireUid();
    yield* _db()
        .collection('leaderboards')
        .doc(_globalLeaderboardId)
        .collection('scores')
        .doc(uid)
        .snapshots()
        .map((snap) => snap.data());
  }

  Stream<int?> watchCurrentGlobalRank({int scanLimit = 500}) async* {
    final uid = await _requireUid();
    final safeLimit = scanLimit <= 0 ? 50 : (scanLimit > 2000 ? 2000 : scanLimit);
    yield* _db()
        .collection('leaderboards')
        .doc(_globalLeaderboardId)
        .collection('scores')
        .orderBy('globalScore', descending: true)
        .orderBy('bestTimeMs')
        .limit(safeLimit)
        .snapshots()
        .map((snap) {
      final docs = snap.docs;
      for (var i = 0; i < docs.length; i++) {
        if (docs[i].id == uid) return i + 1;
      }
      return null;
    });
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
    final filtered = items
        .where((e) => e.bestTimeMs > 0)
        .toList(growable: false)
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
    final filtered = all
        .where((e) => allowed.contains(e.uid))
        .toList(growable: false)
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

  Future<void> _upsertGlobalScore({
    required String uid,
    required Map<String, dynamic> userData,
    required int totalLevelsCompleted,
    required int highestLevelReached,
    required int fastestSolveMs,
    required double avgSolveTimeMs,
    required int averagedLevelCount,
  }) async {
    final username = (userData['username'] as String?)?.trim() ?? '';
    final playerName =
        ((userData['playerName'] as String?)?.trim().isNotEmpty == true)
            ? (userData['playerName'] as String).trim()
            : 'Player';
    final photoUrl =
        (userData['photoUrl'] as String?)?.trim().isNotEmpty == true
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

    final safeFastest = fastestSolveMs > 0 ? fastestSolveMs : 99999999;
    final safeAvg = avgSolveTimeMs.isFinite && avgSolveTimeMs > 0
        ? avgSolveTimeMs
        : safeFastest.toDouble();
    // Ranking based on average clear time (lower is better), without penalizing
    // users who completed more levels.
    final globalScore =
        max(0, 1000000000 - safeAvg.round()) + max(0, totalLevelsCompleted);
    final globalTier = _globalTierForAverageMs(safeAvg);
    final globalRef = _db()
        .collection('leaderboards')
        .doc(_globalLeaderboardId)
        .collection('scores')
        .doc(uid);

    await globalRef.set(
      <String, dynamic>{
        'uid': uid,
        'playerName': playerName,
        'username': username,
        'photoUrl': photoUrl,
        'avatarId': avatarId,
        'equippedSkinId': equippedSkinId,
        'equippedTrailId': equippedTrailId,
        'levelId': _globalLeaderboardId,
        'bestTimeMs': safeFastest,
        'moves': totalLevelsCompleted,
        'stars': highestLevelReached,
        'globalScore': globalScore,
        'globalTier': globalTier,
        'avgSolveTimeMs': safeAvg.round(),
        'averagedLevelCount': averagedLevelCount,
        'totalLevelsCompleted': totalLevelsCompleted,
        'highestLevelReached': highestLevelReached,
        'fastestSolveMs': safeFastest,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  int _resolveLevelTimeMs(Map<String, dynamic> data) {
    final firstClear = LeaderboardEntry.readInt(data['firstClearTimeMs']);
    if (firstClear > 0) return firstClear;
    final personalBest = LeaderboardEntry.readInt(data['personalBestTimeMs']);
    if (personalBest > 0) return personalBest;
    final best = LeaderboardEntry.readInt(data['bestTimeMs']);
    if (best > 0) return best;
    return 0;
  }

  int _countValidAverageLevels(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var count = 0;
    for (final doc in docs) {
      final timeMs = _resolveLevelTimeMs(doc.data());
      if (timeMs > 0) count++;
    }
    return count;
  }

  double _computeAverageSolveTimeMs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var total = 0;
    var count = 0;
    for (final doc in docs) {
      final timeMs = _resolveLevelTimeMs(doc.data());
      if (timeMs <= 0) continue;
      total += timeMs;
      count++;
    }
    if (count == 0) return 0;
    return total / count;
  }

  String _globalTierForAverageMs(double avgMs) {
    if (avgMs <= 3500) return 'S+';
    if (avgMs <= 5000) return 'S';
    if (avgMs <= 7000) return 'A';
    if (avgMs <= 9000) return 'B';
    if (avgMs <= 12000) return 'C';
    return 'D';
  }
}
