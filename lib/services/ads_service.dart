import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_firestore.dart';

class ManualAdQuota {
  const ManualAdQuota({
    required this.watchedToday,
    required this.maxDailyAds,
    required this.cooldownRemaining,
  });

  final int watchedToday;
  final int maxDailyAds;
  final Duration cooldownRemaining;

  int get remaining => max(0, maxDailyAds - watchedToday);
  bool get limitReached => watchedToday >= maxDailyAds;
  bool get cooldownActive => cooldownRemaining > Duration.zero;
}

class ManualAdRewardGrant {
  const ManualAdRewardGrant({
    required this.coinsGranted,
    required this.newCoinsBalance,
    required this.adsWatchedToday,
  });

  final int coinsGranted;
  final int newCoinsBalance;
  final int adsWatchedToday;
}

class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();
  static const int maxDailyManualAds = 5;
  static const int manualAdRewardCoins = 50;
  static const int automaticAdRewardCoins = 20;
  static const Duration manualAdCooldown = Duration(minutes: 2);

  static const String _rewardedProdAdUnitId =
      'ca-app-pub-1638901415672449/5768820354';
  static const String _rewardedTestAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  // Keep true while QA/testing to guarantee test inventory on release builds.
  static const bool _forceTestRewardedAds = true;

  RewardedAd? _rewardedAd;
  bool _isLoadingRewardedAd = false;
  bool _manualRegisterInFlight = false;

  bool get hasRewardedAd => _rewardedAd != null;
  bool get isLoadingRewardedAd => _isLoadingRewardedAd;

  String get _rewardedAdUnitId {
    if (kDebugMode || _forceTestRewardedAds) {
      return _rewardedTestAdUnitId;
    }
    return _rewardedProdAdUnitId;
  }

  Future<void> loadRewardedAd() async {
    if (kIsWeb) {
      debugPrint('[IAP-ADS] Rewarded ads not supported on web.');
      return;
    }
    if (_isLoadingRewardedAd || _rewardedAd != null) {
      return;
    }
    _isLoadingRewardedAd = true;
    debugPrint('[IAP-ADS] Loading rewarded ad: $_rewardedAdUnitId');
    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd?.dispose();
          _rewardedAd = ad;
          _isLoadingRewardedAd = false;
          debugPrint('[IAP-ADS] Rewarded ad loaded.');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoadingRewardedAd = false;
          debugPrint('[IAP-ADS] Rewarded ad failed to load: $error');
          Future<void>.delayed(const Duration(seconds: 8), () {
            unawaited(loadRewardedAd());
          });
        },
      ),
    );
  }

  Future<bool> canWatchAd() async {
    final quota = await getManualAdQuota();
    return !quota.limitReached && !quota.cooldownActive;
  }

  Future<ManualAdRewardGrant> grantManualAdReward() async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      throw StateError('AUTH_REQUIRED');
    }
    if (_manualRegisterInFlight) {
      throw StateError('AD_REGISTER_IN_PROGRESS');
    }
    _manualRegisterInFlight = true;
    try {
      await resetAdsIfNeeded();
      final userRef = _db.collection('users').doc(uid);
      late ManualAdRewardGrant grant;
      await _db.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        final data = snap.data() ?? <String, dynamic>{};
        final watched = _readInt(data['adsWatchedToday']);
        final lastAdAt = _readDateTime(data['lastAdWatchedAt']);
        final currentCoins = _readInt(data['coins']);
        if (watched >= maxDailyManualAds) {
          throw StateError('ADS_DAILY_LIMIT_REACHED');
        }
        if (_cooldownRemaining(lastAdAt) > Duration.zero) {
          throw StateError('ADS_COOLDOWN_ACTIVE');
        }
        final nextWatched = watched + 1;
        final nextCoins = currentCoins + manualAdRewardCoins;
        tx.set(
          userRef,
          <String, dynamic>{
            'adsWatchedToday': nextWatched,
            'lastAdWatchedAt': FieldValue.serverTimestamp(),
            'coins': nextCoins,
            'lifetimeCoinsEarned': FieldValue.increment(manualAdRewardCoins),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        grant = ManualAdRewardGrant(
          coinsGranted: manualAdRewardCoins,
          newCoinsBalance: nextCoins,
          adsWatchedToday: nextWatched,
        );
      });
      return grant;
    } finally {
      _manualRegisterInFlight = false;
    }
  }

  Future<void> resetAdsIfNeeded() async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      return;
    }
    final userRef = _db.collection('users').doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? <String, dynamic>{};
      final watched = _readInt(data['adsWatchedToday']);
      final lastReset = _readDateTime(data['adsLastResetAt']);
      final now = DateTime.now();
      final shouldReset = lastReset == null || !_isSameDay(lastReset, now);
      if (shouldReset) {
        tx.set(
          userRef,
          <String, dynamic>{
            'adsWatchedToday': 0,
            'adsLastResetAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else if (snap.data() == null || !data.containsKey('adsWatchedToday')) {
        tx.set(
          userRef,
          <String, dynamic>{
            'adsWatchedToday': watched,
            'adsLastResetAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<ManualAdQuota> getManualAdQuota() async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      return const ManualAdQuota(
        watchedToday: 0,
        maxDailyAds: maxDailyManualAds,
        cooldownRemaining: Duration.zero,
      );
    }
    await resetAdsIfNeeded();
    final snap = await _db.collection('users').doc(uid).get();
    final data = snap.data() ?? <String, dynamic>{};
    final watched = _readInt(data['adsWatchedToday']);
    final lastAdAt = _readDateTime(data['lastAdWatchedAt']);
    return ManualAdQuota(
      watchedToday: watched,
      maxDailyAds: maxDailyManualAds,
      cooldownRemaining: _cooldownRemaining(lastAdAt),
    );
  }

  Future<bool> showRewardedAd(FutureOr<void> Function() onReward) async {
    if (kIsWeb) {
      debugPrint('[IAP-ADS] showRewardedAd skipped on web.');
      return false;
    }
    final ad = _rewardedAd;
    if (ad == null) {
      debugPrint('[IAP-ADS] showRewardedAd requested but ad is null.');
      unawaited(loadRewardedAd());
      return false;
    }

    final completer = Completer<bool>();
    var rewardEarned = false;
    var rewardHandled = false;

    _rewardedAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        debugPrint('[IAP-ADS] Rewarded ad shown.');
      },
      onAdDismissedFullScreenContent: (dismissedAd) {
        debugPrint('[IAP-ADS] Rewarded ad dismissed. earned=$rewardEarned');
        dismissedAd.dispose();
        if (!completer.isCompleted) {
          completer.complete(rewardEarned);
        }
        unawaited(loadRewardedAd());
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        debugPrint('[IAP-ADS] Failed to show rewarded ad: $error');
        failedAd.dispose();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        unawaited(loadRewardedAd());
      },
    );

    ad.show(
      onUserEarnedReward: (_, reward) async {
        if (rewardHandled) return;
        rewardHandled = true;
        debugPrint(
          '[IAP-ADS] User earned reward: amount=${reward.amount} type=${reward.type}',
        );
        try {
          await onReward();
          rewardEarned = true;
        } catch (e, st) {
          debugPrint('[IAP-ADS] onReward failed: $e');
          debugPrintStack(stackTrace: st);
          rewardEarned = false;
        }
      },
    );

    return completer.future;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  FirebaseFirestore get _db => AppFirestore.instance();

  int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Duration _cooldownRemaining(DateTime? lastAdAt) {
    if (lastAdAt == null) return Duration.zero;
    final elapsed = DateTime.now().difference(lastAdAt);
    if (elapsed >= manualAdCooldown) return Duration.zero;
    return manualAdCooldown - elapsed;
  }
}
