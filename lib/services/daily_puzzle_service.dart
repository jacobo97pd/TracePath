import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../engine/seed_random.dart';
import 'app_firestore.dart';

class DailyRewardClaimResult {
  const DailyRewardClaimResult({
    required this.granted,
    required this.alreadyClaimed,
    this.newCoinsBalance,
  });

  final bool granted;
  final bool alreadyClaimed;
  final int? newCoinsBalance;
}

class DailyPuzzleService {
  static const int dailyRewardCoins = 35;

  static String currentDailyKey({DateTime? now}) {
    return getTodayString(now: (now ?? DateTime.now()).toUtc());
  }

  static DateTime nextDailyResetUtc({DateTime? now}) {
    final date = (now ?? DateTime.now()).toUtc();
    return DateTime.utc(date.year, date.month, date.day + 1);
  }

  static Duration timeUntilNextReset({DateTime? now}) {
    final current = (now ?? DateTime.now()).toUtc();
    final next = nextDailyResetUtc(now: current);
    return next.difference(current);
  }

  Future<DailyRewardClaimResult> claimDailyRewardOnce({
    required String dailyKey,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      if (kDebugMode) {
        debugPrint('[daily] claim skipped: missing auth user');
      }
      return const DailyRewardClaimResult(
        granted: false,
        alreadyClaimed: false,
      );
    }

    final normalizedDailyKey = dailyKey.trim();
    if (normalizedDailyKey.isEmpty) {
      return const DailyRewardClaimResult(
        granted: false,
        alreadyClaimed: false,
      );
    }

    final db = AppFirestore.instance();
    final userRef = db.collection('users').doc(uid);
    final rewardRef = userRef.collection('daily_rewards').doc(normalizedDailyKey);

    var granted = false;
    var alreadyClaimed = false;
    int? newCoinsBalance;

    await db.runTransaction((tx) async {
      final rewardSnap = await tx.get(rewardRef);
      final userSnap = await tx.get(userRef);

      if (rewardSnap.exists && (rewardSnap.data()?['claimed'] == true)) {
        alreadyClaimed = true;
        newCoinsBalance = (userSnap.data()?['coins'] as num?)?.toInt();
        return;
      }

      final currentCoins = (userSnap.data()?['coins'] as num?)?.toInt() ?? 0;
      newCoinsBalance = currentCoins + dailyRewardCoins;
      granted = true;

      tx.set(
        rewardRef,
        <String, dynamic>{
          'uid': uid,
          'dailyKey': normalizedDailyKey,
          'coinsAwarded': dailyRewardCoins,
          'claimed': true,
          'claimedAt': FieldValue.serverTimestamp(),
          'source': 'daily_puzzle',
        },
        SetOptions(merge: true),
      );

      tx.set(
        userRef,
        <String, dynamic>{
          'coins': FieldValue.increment(dailyRewardCoins),
          'lifetimeCoinsEarned': FieldValue.increment(dailyRewardCoins),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    if (kDebugMode) {
      debugPrint(
        '[daily] claim result uid=$uid key=$normalizedDailyKey granted=$granted alreadyClaimed=$alreadyClaimed newCoins=$newCoinsBalance',
      );
    }

    return DailyRewardClaimResult(
      granted: granted,
      alreadyClaimed: alreadyClaimed,
      newCoinsBalance: newCoinsBalance,
    );
  }
}
