import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class StreakUpdateResult {
  const StreakUpdateResult({
    required this.currentStreak,
    required this.bestStreak,
    required this.streakIncreased,
    required this.streakReset,
    required this.alreadyUpdatedToday,
    this.milestoneReached,
    this.rewardCoins,
  });

  final int currentStreak;
  final int bestStreak;
  final bool streakIncreased;
  final bool streakReset;
  final int? milestoneReached;
  final int? rewardCoins;
  final bool alreadyUpdatedToday;
}

class StreakService {
  static const String _firestoreDatabaseId = 'tracepath-database';
  static const Map<int, int> _milestoneRewards = <int, int>{
    1: 10,
    3: 30,
    7: 80,
    14: 150,
    30: 300,
  };

  Future<StreakUpdateResult> registerCompletedLevel({
    required String uid,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw StateError('INVALID_UID');
    }

    final userRef = _db().collection('users').doc(normalizedUid);
    final now = DateTime.now();
    final today = _formatDate(now);
    final yesterday = _formatDate(now.subtract(const Duration(days: 1)));

    return _db().runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? const <String, dynamic>{};

      final currentRaw = _readInt(data['currentStreak']);
      final bestRaw = _readInt(data['bestStreak']);
      final lastDate = (data['lastStreakDate'] as String?)?.trim() ?? '';
      final claimed = _readIntList(data['claimedStreakMilestones']);

      var current = currentRaw;
      var best = bestRaw;
      var alreadyUpdatedToday = false;
      var streakIncreased = false;
      var streakReset = false;
      int? milestoneReached;
      int? rewardCoins;

      if (lastDate == today) {
        alreadyUpdatedToday = true;
        if (current <= 0) {
          current = 1;
        }
        best = max(best, current);
      } else if (lastDate.isEmpty) {
        current = 1;
        best = max(best, current);
        streakIncreased = true;
      } else if (lastDate == yesterday) {
        current = max(0, current) + 1;
        if (current <= 0) current = 1;
        best = max(best, current);
        streakIncreased = true;
      } else {
        current = 1;
        best = max(best, current);
        streakIncreased = true;
        streakReset = true;
      }

      if (!alreadyUpdatedToday) {
        final reward = _milestoneRewards[current];
        if (reward != null && !claimed.contains(current)) {
          claimed.add(current);
          claimed.sort();
          milestoneReached = current;
          rewardCoins = reward;
        }
      }

      tx.set(
        userRef,
        <String, dynamic>{
          'currentStreak': current,
          'bestStreak': best,
          'lastStreakDate': alreadyUpdatedToday ? lastDate : today,
          'claimedStreakMilestones': claimed,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      return StreakUpdateResult(
        currentStreak: current,
        bestStreak: best,
        streakIncreased: streakIncreased,
        streakReset: streakReset,
        milestoneReached: milestoneReached,
        rewardCoins: rewardCoins,
        alreadyUpdatedToday: alreadyUpdatedToday,
      );
    });
  }

  List<int> _readIntList(Object? value) {
    if (value is List) {
      final out = <int>[];
      for (final item in value) {
        final parsed = _readInt(item);
        if (parsed > 0) out.add(parsed);
      }
      return out.toSet().toList()..sort();
    }
    return <int>[];
  }

  int _readInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
}

