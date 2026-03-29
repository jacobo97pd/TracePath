import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/user_model.dart';
import 'services/coin_reward_overlay_service.dart';
import 'shop/coin_pack.dart';

class CoinSkinDef {
  const CoinSkinDef({
    required this.id,
    required this.name,
    this.assetPath,
    this.previewPath,
    this.bannerPath,
    this.cardPath,
    this.metrics,
    this.costCoins,
    this.isPremium = false,
    this.rarity = 'Common',
    this.featured = false,
    this.order = 0,
  });

  final String id;
  final String name;
  final String? assetPath;
  final String? previewPath;
  final String? bannerPath;
  final String? cardPath;
  final SkinMetrics? metrics;
  final int? costCoins;
  final bool isPremium;
  final String rarity;
  final bool featured;
  final int order;
}

class CoinTrailDef {
  const CoinTrailDef({
    required this.id,
    required this.name,
    this.costCoins,
    this.isPremium = false,
  });

  final String id;
  final String name;
  final int? costCoins;
  final bool isPremium;
}

class SkinMetrics {
  const SkinMetrics({
    required this.width,
    required this.height,
    required this.aspectRatio,
    required this.coverageRatio,
    required this.bboxWidth,
    required this.bboxHeight,
  });

  final int width;
  final int height;
  final double aspectRatio;
  final double coverageRatio;
  final int bboxWidth;
  final int bboxHeight;
}

class LevelRewardGrantResult {
  const LevelRewardGrantResult({
    required this.coinsAwarded,
    required this.firstCompletion,
  });

  final int coinsAwarded;
  final bool firstCompletion;
}

class LegacyLevelRewardGap {
  const LegacyLevelRewardGap({
    required this.levelId,
    required this.completedAt,
    required this.bestTimeMs,
    required this.personalBestTimeMs,
  });

  final String levelId;
  final DateTime? completedAt;
  final int bestTimeMs;
  final int personalBestTimeMs;
}

class CoinsService extends ChangeNotifier {
  CoinsService(this._prefs) {
    _coins = _prefs.getInt(_coinsKey) ?? 0;
    _ownedSkins = <String>{_defaultSkinId};
    _selectedSkin = _defaultSkinId;
    _ownedTrails = <String>{_defaultTrailId};
    _selectedTrail = _defaultTrailId;
    _claimedLevelRewards =
        _prefs.getStringList(_claimedLevelRewardsKey)?.toSet() ?? <String>{};

    _skinAssetMap = <String, String>{..._skinAssetById};
    if (_coins < _testBootstrapCoins) {
      _coins = _testBootstrapCoins;
      _prefs.setInt(_coinsKey, _coins);
    }

    _unsyncedDelta = _prefs.getInt(_unsyncedDeltaKey) ?? 0;
    _unsyncedLifetimeEarned = _prefs.getInt(_unsyncedEarnedKey) ?? 0;
    _unsyncedLifetimePurchased = _prefs.getInt(_unsyncedPurchasedKey) ?? 0;
    _unsyncedLevelsCompleted = _prefs.getInt(_unsyncedLevelsCompletedKey) ?? 0;
    _lastSyncedUid = _prefs.getString(_lastSyncedUidKey);
    _dropStalePendingSyncStateAtStartup();

    _coinsController.add(_coins);
    final auth = _firebaseAuthOrNull;
    if (auth != null) {
      _authSub = auth.authStateChanges().listen((user) {
        unawaited(_onAuthUserChanged(user));
      });
      unawaited(_ensureAuthenticatedUser());
      unawaited(_onAuthUserChanged(auth.currentUser));
    } else if (kDebugMode) {
      debugPrint(
        '[coins] Firebase not configured; remote sync disabled (local-only mode)',
      );
    }
  }

  static const String _coinsKey = 'coins_balance';
  static const String _ownedSkinsKey = 'coins_owned_skins';
  static const String _selectedSkinKey = 'coins_selected_skin';
  static const String _skinAssetMapKey = 'coins_skin_asset_map';
  static const String _ownedTrailsKey = 'coins_owned_trails';
  static const String _selectedTrailKey = 'coins_selected_trail';
  static const String _claimedLevelRewardsKey = 'coins_claimed_level_rewards';
  static const String _claimedLevelRewardsPrefix =
      'coins_claimed_level_rewards:';
  static const String _unsyncedDeltaKey = 'coins_unsynced_delta_v1';
  static const String _lastSyncedUidKey = 'coins_last_synced_uid_v1';
  static const String _unsyncedEarnedKey = 'coins_unsynced_earned_v1';
  static const String _unsyncedPurchasedKey = 'coins_unsynced_purchased_v1';
  static const String _unsyncedLevelsCompletedKey =
      'coins_unsynced_levels_completed_v1';

  static const String _defaultSkinId = 'pointer_default';
  static const String _defaultTrailId = 'trail_classic';
  static const int levelClearReward = 25;
  static const int perfectLevelBonus = 10;
  static const int _testBootstrapCoins = 0;
  static const String _firebaseStorageBucket =
      'tracepath-e2e90.firebasestorage.app';
  static const String _firestoreDatabaseId = 'tracepath-database';
  static const Map<String, String> _skinFileAliasById = <String, String>{
    'spider_cerdo_old_man': 'spider-cerdo-oldman.png',
  };
  static const Map<String, String> _skinAssetById = <String, String>{
    'pointer_pig_vader': 'assets/skins/pointer_pig_vader.png',
  };

  final SharedPreferences _prefs;
  final StreamController<int> _coinsController =
      StreamController<int>.broadcast();

  int _coins = 0;
  String _selectedSkin = _defaultSkinId;
  String _selectedTrail = _defaultTrailId;
  Set<String> _ownedSkins = <String>{_defaultSkinId};
  Set<String> _ownedTrails = <String>{_defaultTrailId};
  Set<String> _claimedLevelRewards = <String>{};
  Map<String, String> _skinAssetMap = <String, String>{};

  int _unsyncedDelta = 0;
  int _unsyncedLifetimeEarned = 0;
  int _unsyncedLifetimePurchased = 0;
  int _unsyncedLevelsCompleted = 0;
  String? _lastSyncedUid;
  String? _activeCosmeticUid;
  String? _activeRewardsUid;

  StreamSubscription<User?>? _authSub;
  Timer? _remoteRetryTimer;
  bool _syncInProgress = false;

  bool get _isFirebaseConfigured {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAuth? get _firebaseAuthOrNull {
    if (!_isFirebaseConfigured) return null;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  User? get _firebaseUserOrNull => _firebaseAuthOrNull?.currentUser;

  void _dropStalePendingSyncStateAtStartup() {
    if (_unsyncedDelta == 0 &&
        _unsyncedLifetimeEarned == 0 &&
        _unsyncedLifetimePurchased == 0 &&
        _unsyncedLevelsCompleted == 0) {
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[coins] startup clears stale pending sync '
        'delta=$_unsyncedDelta earned=$_unsyncedLifetimeEarned '
        'purchased=$_unsyncedLifetimePurchased levels=$_unsyncedLevelsCompleted',
      );
    }
    _unsyncedDelta = 0;
    _unsyncedLifetimeEarned = 0;
    _unsyncedLifetimePurchased = 0;
    _unsyncedLevelsCompleted = 0;
    unawaited(_persistCoinSyncState());
  }

  int get coins => _coins;
  Future<int> getCoins() async => _coins;
  Stream<int> watchCoins() => _coinsController.stream;
  String get selectedSkin => _selectedSkin;
  String get selectedTrail => _selectedTrail;

  String? get selectedSkinAssetPath {
    final mapped = _skinAssetMap[_selectedSkin];
    if (mapped != null && mapped.trim().isNotEmpty) {
      final normalized = mapped.trim();
      final uri = Uri.tryParse(normalized);
      final host = (uri?.host ?? '').toLowerCase();
      final isLocalhost = host == 'localhost' || host == '127.0.0.1';
      if (isLocalhost) {
        final migrated = _inferRemoteUrlForSkinId(_selectedSkin);
        if (kDebugMode) {
          debugPrint(
            '[PointerSkin] migrating selectedSkinAssetPath from localhost: $normalized -> ${migrated ?? ''}',
          );
        }
        return migrated;
      }
      return normalized;
    }
    if (_selectedSkin == _defaultSkinId) return null;
    return _inferRemoteUrlForSkinId(_selectedSkin);
  }

  bool ownsSkin(String skinId) => _ownedSkins.contains(skinId);
  bool ownsTrail(String trailId) => _ownedTrails.contains(trailId);
  Set<String> get ownedSkins => Set<String>.unmodifiable(_ownedSkins);
  Set<String> get ownedTrails => Set<String>.unmodifiable(_ownedTrails);

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _coins += amount;
    _unsyncedDelta += amount;
    _unsyncedLifetimeEarned += amount;
    await _persistCoinSyncState();
    _emitCoinUpdate();
    _triggerCoinRewardAnimation(amount);
    unawaited(_syncCoinsToRemoteSilently());
  }

  Future<bool> spendCoins(int amount) async {
    if (amount <= 0) return true;
    if (_coins < amount) return false;
    _coins -= amount;
    _unsyncedDelta -= amount;
    await _persistCoinSyncState();
    _emitCoinUpdate();
    unawaited(_syncCoinsToRemoteSilently());
    return true;
  }

  Future<int> penalizeCoins(int amount) async {
    if (amount <= 0) return 0;
    final deducted = min(_coins, amount);
    if (deducted <= 0) return 0;
    _coins -= deducted;
    _unsyncedDelta -= deducted;
    await _persistCoinSyncState();
    _emitCoinUpdate();
    unawaited(_syncCoinsToRemoteSilently());
    return deducted;
  }

  Future<bool> rewardCampaignLevelCompletion({
    required String packId,
    required int levelIndex,
    int amount = levelClearReward,
  }) async {
    final rewardKey = '$packId:$levelIndex';
    if (_claimedLevelRewards.contains(rewardKey)) {
      return false;
    }
    _claimedLevelRewards = {..._claimedLevelRewards, rewardKey};
    _coins += amount;
    _unsyncedDelta += amount;
    _unsyncedLifetimeEarned += amount;
    _unsyncedLevelsCompleted += 1;
    await _persistClaimedLevelRewardsScoped();
    await _persistCoinSyncState();
    _emitCoinUpdate();
    _triggerCoinRewardAnimation(amount);
    unawaited(_syncCoinsToRemoteSilently());
    return true;
  }

  Future<int> rewardLevelCompletion({
    required bool perfectCompletion,
  }) async {
    final bonus = perfectCompletion ? perfectLevelBonus : 0;
    final total = levelClearReward + bonus;
    _coins += total;
    _unsyncedDelta += total;
    _unsyncedLifetimeEarned += total;
    _unsyncedLevelsCompleted += 1;
    await _persistCoinSyncState();
    _emitCoinUpdate();
    _triggerCoinRewardAnimation(total);
    unawaited(_syncCoinsToRemoteSilently());
    return total;
  }

  Future<LevelRewardGrantResult> rewardLevelCompletionOncePerLevel({
    required String levelId,
    required bool perfectCompletion,
  }) async {
    final normalizedLevelId = levelId.trim();
    if (normalizedLevelId.isEmpty) {
      return const LevelRewardGrantResult(
          coinsAwarded: 0, firstCompletion: false);
    }
    final bonus = perfectCompletion ? perfectLevelBonus : 0;
    final total = levelClearReward + bonus;
    if (total <= 0) {
      return const LevelRewardGrantResult(
          coinsAwarded: 0, firstCompletion: false);
    }

    final user = _firebaseUserOrNull;
    if (user == null) {
      if (_claimedLevelRewards.contains(normalizedLevelId)) {
        if (kDebugMode) {
          debugPrint(
            '[coins][level-reward] first clear skipped (already claimed) '
            'uid=guest level=$normalizedLevelId',
          );
          debugPrint(
            '[coins][level-reward] perfect bonus skipped '
            'uid=guest level=$normalizedLevelId reason=already_claimed',
          );
        }
        return const LevelRewardGrantResult(
            coinsAwarded: 0, firstCompletion: false);
      }
      _claimedLevelRewards = <String>{
        ..._claimedLevelRewards,
        normalizedLevelId
      };
      _coins += total;
      _unsyncedDelta += total;
      _unsyncedLifetimeEarned += total;
      await _persistClaimedLevelRewardsScoped();
      await _persistCoinSyncState();
      _emitCoinUpdate();
      _triggerCoinRewardAnimation(total);
      if (kDebugMode) {
        debugPrint(
          '[coins][level-reward] first clear granted uid=guest '
          'level=$normalizedLevelId coins=$total perfect=$perfectCompletion',
        );
        debugPrint(
          perfectCompletion
              ? '[coins][level-reward] perfect bonus granted '
                  'uid=guest level=$normalizedLevelId bonus=$bonus'
              : '[coins][level-reward] perfect bonus skipped '
                  'uid=guest level=$normalizedLevelId reason=not_perfect',
        );
      }
      return LevelRewardGrantResult(coinsAwarded: total, firstCompletion: true);
    }

    final uid = user.uid;
    final userRef = _usersDocRef(uid);
    final completedRef =
        userRef.collection('completed_levels').doc(normalizedLevelId);
    final rewardRef =
        userRef.collection('level_rewards').doc(normalizedLevelId);

    var awardedCoins = 0;
    var firstCompletion = false;
    Future<void> attemptGrant() async {
      await _activeFirestore().runTransaction((tx) async {
        final rewardSnap = await tx.get(rewardRef);
        if (rewardSnap.exists) {
          firstCompletion = false;
          awardedCoins = 0;
          return;
        }
        firstCompletion = true;
        awardedCoins = total;
        tx.set(
          rewardRef,
          <String, dynamic>{
            'levelId': normalizedLevelId,
            'coinsAwarded': total,
            'awardedAt': FieldValue.serverTimestamp(),
            'source': 'level_first_completion',
          },
          SetOptions(merge: true),
        );
        tx.set(
          completedRef,
          <String, dynamic>{
            'completed': true,
            'levelId': normalizedLevelId,
            'firstCompletedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        tx.set(
          userRef,
          <String, dynamic>{
            'uid': uid,
            'coins': FieldValue.increment(total),
            'lifetimeCoinsEarned': FieldValue.increment(total),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    }

    Object? lastError;
    StackTrace? lastStackTrace;
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        await attemptGrant();
        lastError = null;
        lastStackTrace = null;
        break;
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;
        if (kDebugMode) {
          debugPrint(
            '[coins][level-reward] transaction failure uid=$uid '
            'level=$normalizedLevelId attempt=$attempt error=$e',
          );
        }
      }
    }
    if (lastError != null) {
      if (kDebugMode) {
        debugPrint(
          '[coins][level-reward] transaction failure final uid=$uid '
          'level=$normalizedLevelId',
        );
      }
      Error.throwWithStackTrace(
          lastError, lastStackTrace ?? StackTrace.current);
    }

    if (!firstCompletion || awardedCoins <= 0) {
      if (kDebugMode) {
        debugPrint(
          '[coins][level-reward] first clear skipped (already claimed) '
          'uid=$uid level=$normalizedLevelId '
          'firstCompletion=$firstCompletion awarded=$awardedCoins',
        );
        debugPrint(
          '[coins][level-reward] perfect bonus skipped '
          'uid=$uid level=$normalizedLevelId reason=already_claimed',
        );
      }
      return const LevelRewardGrantResult(
          coinsAwarded: 0, firstCompletion: false);
    }

    _claimedLevelRewards = <String>{..._claimedLevelRewards, normalizedLevelId};
    _coins += awardedCoins;
    await _persistClaimedLevelRewardsScoped();
    await _prefs.setInt(_coinsKey, _coins);
    _emitCoinUpdate();
    _triggerCoinRewardAnimation(awardedCoins);
    if (kDebugMode) {
      debugPrint(
        '[coins][level-reward] first clear granted uid=$uid '
        'level=$normalizedLevelId coins=$awardedCoins perfect=$perfectCompletion',
      );
      debugPrint(
        perfectCompletion
            ? '[coins][level-reward] perfect bonus granted '
                'uid=$uid level=$normalizedLevelId bonus=$bonus'
            : '[coins][level-reward] perfect bonus skipped '
                'uid=$uid level=$normalizedLevelId reason=not_perfect',
      );
    }
    return LevelRewardGrantResult(
      coinsAwarded: awardedCoins,
      firstCompletion: true,
    );
  }

  Future<List<LegacyLevelRewardGap>> detectLegacyLevelRewardGaps({
    String? uid,
  }) async {
    if (!_isFirebaseConfigured) return const <LegacyLevelRewardGap>[];
    final resolvedUid = (uid ?? _firebaseUserOrNull?.uid ?? '').trim();
    if (resolvedUid.isEmpty) return const <LegacyLevelRewardGap>[];
    final userRef = _usersDocRef(resolvedUid);
    final completedSnap = await userRef.collection('completed_levels').get();
    final rewardSnap = await userRef.collection('level_rewards').get();
    final rewardedLevelIds = rewardSnap.docs.map((d) => d.id).toSet();
    final gaps = <LegacyLevelRewardGap>[];
    for (final doc in completedSnap.docs) {
      final levelId = doc.id.trim();
      if (levelId.isEmpty || rewardedLevelIds.contains(levelId)) continue;
      final data = doc.data();
      final completedAtRaw = data['completedAt'] ?? data['firstCompletedAt'];
      gaps.add(
        LegacyLevelRewardGap(
          levelId: levelId,
          completedAt:
              completedAtRaw is Timestamp ? completedAtRaw.toDate() : null,
          bestTimeMs: _readRemoteInt(data, 'bestTimeMs'),
          personalBestTimeMs: _readRemoteInt(data, 'personalBestTimeMs'),
        ),
      );
    }
    gaps.sort((a, b) => a.levelId.compareTo(b.levelId));
    if (kDebugMode) {
      debugPrint(
        '[coins][legacy-reconcile] detect uid=$resolvedUid '
        'completed=${completedSnap.docs.length} rewards=${rewardSnap.docs.length} '
        'gaps=${gaps.length}',
      );
    }
    return gaps;
  }

  Future<int> repairLegacyLevelRewardMarkers({
    required Iterable<String> levelIds,
    String? uid,
    String source = 'legacy_manual_reconcile',
  }) async {
    if (!_isFirebaseConfigured) return 0;
    final resolvedUid = (uid ?? _firebaseUserOrNull?.uid ?? '').trim();
    if (resolvedUid.isEmpty) return 0;
    final normalized = levelIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (normalized.isEmpty) return 0;
    final userRef = _usersDocRef(resolvedUid);
    final batch = _activeFirestore().batch();
    var writes = 0;
    for (final levelId in normalized) {
      final rewardRef = userRef.collection('level_rewards').doc(levelId);
      batch.set(
        rewardRef,
        <String, dynamic>{
          'levelId': levelId,
          'coinsAwarded': 0,
          'awardedAt': FieldValue.serverTimestamp(),
          'source': source,
          'legacyReconciled': true,
        },
        SetOptions(merge: true),
      );
      writes += 1;
    }
    await batch.commit();
    if (kDebugMode) {
      debugPrint(
        '[coins][legacy-reconcile] repair uid=$resolvedUid markers=$writes '
        'source=$source',
      );
    }
    return writes;
  }

  Future<BuyCoinPackResult> buyCoinPack(CoinPack pack) async {
    return const BuyCoinPackResult(
      status: BuyCoinPackStatus.failed,
      addedCoins: 0,
      message: 'IAP is handled by IapService',
    );
  }

  Future<int> applyCoinPackPurchase(CoinPack pack) async {
    final amount =
        pack.totalCoins > 0 ? pack.totalCoins : (pack.coins + pack.bonusCoins);
    if (amount <= 0) return 0;
    _coins += amount;
    _unsyncedDelta += amount;
    _unsyncedLifetimePurchased += amount;
    await _persistCoinSyncState();
    _emitCoinUpdate();
    _triggerCoinRewardAnimation(amount,
        visualOverride: _visualCoinsForPurchase(amount));
    unawaited(_syncCoinsToRemoteSilently());
    return amount;
  }

  Future<int> grantVerifiedCoinPackPurchase({
    required CoinPack pack,
    required String productId,
    required String purchaseId,
    required String purchaseStatus,
    String verificationData = '',
  }) async {
    final user = _firebaseUserOrNull;
    if (user == null) return 0;

    final amount =
        pack.totalCoins > 0 ? pack.totalCoins : (pack.coins + pack.bonusCoins);
    if (amount <= 0) return 0;

    final uid = user.uid;
    final safePurchaseId = purchaseId.trim().isEmpty
        ? '${productId}_${DateTime.now().millisecondsSinceEpoch}'
        : purchaseId.trim();
    final refId = _sanitizeDocId(safePurchaseId);

    final userRef = _usersDocRef(uid);
    final purchaseRef = userRef.collection('purchases').doc(refId);
    final walletRef = userRef.collection('wallet_transactions').doc(refId);

    var credited = 0;
    await _activeFirestore().runTransaction((tx) async {
      final purchaseSnap = await tx.get(purchaseRef);
      if (purchaseSnap.exists) {
        credited = 0;
        return;
      }
      credited = amount;
      tx.set(
        userRef,
        <String, dynamic>{
          'uid': uid,
          'coins': FieldValue.increment(amount),
          'lifetimeCoinsPurchased': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(
        purchaseRef,
        <String, dynamic>{
          'purchaseId': refId,
          'status': purchaseStatus,
          'productId': productId,
          'packId': pack.id,
          'coins': pack.coins,
          'bonusCoins': pack.bonusCoins,
          'totalCoins': amount,
          'source': 'iap_coin_pack',
          'verificationData': verificationData,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(
        walletRef,
        <String, dynamic>{
          'type': 'purchase',
          'source': 'iap_coin_pack',
          'amount': amount,
          'referenceId': refId,
          'packId': pack.id,
          'productId': productId,
          'coins': pack.coins,
          'bonusCoins': pack.bonusCoins,
          'totalCoins': amount,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    if (credited > 0) {
      _coins += credited;
      await _prefs.setInt(_coinsKey, _coins);
      _emitCoinUpdate();
      _triggerCoinRewardAnimation(
        credited,
        visualOverride: _visualCoinsForPurchase(credited),
      );
    }
    return credited;
  }

  String _sanitizeDocId(String value) {
    final cleaned = value.replaceAll('/', '_').trim();
    if (cleaned.isEmpty) return '';
    if (cleaned.length <= 140) return cleaned;
    return cleaned.substring(0, 140);
  }

  Future<void> updateProfileProgress({
    int? highestLevelReached,
    int? playTimeSecondsDelta,
    bool? gameWon,
    int? solveMs,
  }) async {
    final user = _firebaseUserOrNull;
    if (user == null) return;
    try {
      final ref = _usersDocRef(user.uid);
      await _activeFirestore().runTransaction((tx) async {
        final snap = await tx.get(ref);
        final current = snap.data() ?? <String, dynamic>{};
        final currentFastest = _readRemoteInt(current, 'fastestSolveMs');
        final currentHighest = _readRemoteInt(current, 'highestLevelReached');
        final payload = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
          'gamesPlayed': FieldValue.increment(1),
        };
        if (gameWon == true) {
          payload['gamesWon'] = FieldValue.increment(1);
        }
        if (playTimeSecondsDelta != null && playTimeSecondsDelta > 0) {
          payload['totalPlayTimeSeconds'] =
              FieldValue.increment(playTimeSecondsDelta);
        }
        if (highestLevelReached != null &&
            highestLevelReached > currentHighest) {
          payload['highestLevelReached'] = highestLevelReached;
        }
        if (solveMs != null && solveMs > 0) {
          final nextFastest =
              currentFastest <= 0 ? solveMs : min(currentFastest, solveMs);
          payload['fastestSolveMs'] = nextFastest;
        }
        tx.set(ref, payload, SetOptions(merge: true));
      });
    } catch (_) {
      _scheduleRemoteRetry();
    }
  }

  Future<bool> purchaseCoinSkin(CoinSkinDef skin) async {
    if (skin.isPremium || skin.costCoins == null || skin.costCoins! < 0) {
      return false;
    }
    if (ownsSkin(skin.id)) {
      return true;
    }
    final ok = await spendCoins(skin.costCoins!);
    if (!ok) {
      return false;
    }
    _ownedSkins = {..._ownedSkins, skin.id};
    await registerSkinAsset(skin.id, skin.assetPath);
    await _persistOwnedSkinsScoped();
    unawaited(_markOwnedSkinRemote(skin.id, source: 'shop'));
    notifyListeners();
    return true;
  }

  Future<void> selectSkin(String skinId) async {
    if (!_ownedSkins.contains(skinId)) return;
    if (_selectedSkin == skinId) return;
    if (!_skinAssetMap.containsKey(skinId) && skinId != _defaultSkinId) {
      final inferred = _inferRemoteUrlForSkinId(skinId);
      if (inferred != null) {
        _skinAssetMap = <String, String>{..._skinAssetMap, skinId: inferred};
        await _persistSkinAssetMapScoped();
      }
    }
    _selectedSkin = skinId;
    await _persistSelectedSkinScoped();
    unawaited(_updateEquippedRemote(skinId: skinId));
    notifyListeners();
  }

  Future<void> registerSkinAsset(String skinId, String? assetPath) async {
    if (assetPath == null || assetPath.trim().isEmpty) return;
    final existing = _skinAssetMap[skinId];
    if (existing == assetPath) return;
    _skinAssetMap = <String, String>{..._skinAssetMap, skinId: assetPath};
    await _persistSkinAssetMapScoped();
    notifyListeners();
  }

  Future<void> syncCoinsFromRemote(int remoteCoins) async {
    _coins = max(0, remoteCoins);
    _unsyncedDelta = 0;
    await _persistCoinSyncState();
    _emitCoinUpdate();
  }

  Future<void> syncOwnedSkinFromRemote(String skinId) async {
    if (skinId.trim().isEmpty) return;
    if (_ownedSkins.contains(skinId)) return;
    _ownedSkins = {..._ownedSkins, skinId};
    await _persistOwnedSkinsScoped();
    notifyListeners();
  }

  Future<void> syncEquippedSkinFromRemote(String skinId) async {
    if (skinId.trim().isEmpty) return;
    final localId = skinId == 'default' ? _defaultSkinId : skinId;
    if (!_ownedSkins.contains(localId)) {
      _ownedSkins = {..._ownedSkins, localId};
      await _persistOwnedSkinsScoped();
    }
    _selectedSkin = localId;
    await _persistSelectedSkinScoped();
    notifyListeners();
  }

  Future<bool> purchaseCoinTrail(CoinTrailDef trail) async {
    if (trail.isPremium || trail.costCoins == null || trail.costCoins! < 0) {
      return false;
    }
    if (ownsTrail(trail.id)) {
      return true;
    }
    final ok = await spendCoins(trail.costCoins!);
    if (!ok) {
      return false;
    }
    _ownedTrails = {..._ownedTrails, trail.id};
    await _persistOwnedTrailsScoped();
    unawaited(_markOwnedTrailRemote(trail.id, source: 'shop'));
    notifyListeners();
    return true;
  }

  Future<void> selectTrail(String trailId) async {
    if (!_ownedTrails.contains(trailId)) return;
    if (_selectedTrail == trailId) return;
    _selectedTrail = trailId;
    await _persistSelectedTrailScoped();
    unawaited(_updateEquippedRemote(trailId: trailId));
    notifyListeners();
  }

  Future<void> _persistCoinSyncState() async {
    await _prefs.setInt(_coinsKey, _coins);
    await _prefs.setInt(_unsyncedDeltaKey, _unsyncedDelta);
    await _prefs.setInt(_unsyncedEarnedKey, _unsyncedLifetimeEarned);
    await _prefs.setInt(_unsyncedPurchasedKey, _unsyncedLifetimePurchased);
    await _prefs.setInt(_unsyncedLevelsCompletedKey, _unsyncedLevelsCompleted);
  }

  Future<void> _ensureAuthenticatedUser() async {
    final auth = _firebaseAuthOrNull;
    if (auth == null || auth.currentUser != null) return;
    try {
      if (kDebugMode) {
        debugPrint('[coins] No auth user; signing in anonymously...');
      }
      await auth.signInAnonymously();
      if (kDebugMode) {
        debugPrint('[coins] Anonymous sign-in OK uid=${auth.currentUser?.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[coins] Anonymous sign-in failed: $e');
      }
    }
  }

  Future<void> _onAuthUserChanged(User? user) async {
    if (user == null) return;
    if (kDebugMode) {
      debugPrint('[coins] auth change uid=${user.uid}');
    }
    if (_activeCosmeticUid != user.uid) {
      await _loadUserScopedCosmeticState(user.uid);
    }
    if (_activeRewardsUid != user.uid) {
      await _loadUserScopedRewardState(user.uid);
    }
    await _ensureUserDocument(user.uid);
    await _hydrateInventoryFromRemote(user.uid);
    await _mergeLocalWithRemote(user.uid);
  }

  Future<void> _loadUserScopedRewardState(String uid) async {
    _activeRewardsUid = uid;
    final scoped = _prefs.getStringList(_claimedLevelRewardsKeyForUid(uid));
    final legacy = _prefs.getStringList(_claimedLevelRewardsKey);
    _claimedLevelRewards = (scoped ?? legacy ?? const <String>[]).toSet();
    await _persistClaimedLevelRewardsScoped();
  }

  Future<void> _loadUserScopedCosmeticState(String uid) async {
    _activeCosmeticUid = uid;
    final scopedOwnedSkins = _prefs.getStringList(_ownedSkinsKeyForUid(uid));
    final scopedSelectedSkin = _prefs.getString(_selectedSkinKeyForUid(uid));
    final scopedOwnedTrails = _prefs.getStringList(_ownedTrailsKeyForUid(uid));
    final scopedSelectedTrail = _prefs.getString(_selectedTrailKeyForUid(uid));
    final scopedSkinMapRaw = _prefs.getString(_skinAssetMapKeyForUid(uid));

    final legacyOwnedSkins = _prefs.getStringList(_ownedSkinsKey);
    final legacySelectedSkin = _prefs.getString(_selectedSkinKey);
    final legacyOwnedTrails = _prefs.getStringList(_ownedTrailsKey);
    final legacySelectedTrail = _prefs.getString(_selectedTrailKey);
    final legacySkinMapRaw = _prefs.getString(_skinAssetMapKey);

    _ownedSkins =
        (scopedOwnedSkins ?? legacyOwnedSkins ?? <String>[_defaultSkinId])
            .toSet();
    if (_ownedSkins.isEmpty) {
      _ownedSkins = <String>{_defaultSkinId};
    } else {
      _ownedSkins.add(_defaultSkinId);
    }

    _selectedSkin =
        (scopedSelectedSkin ?? legacySelectedSkin ?? _defaultSkinId).trim();
    if (_selectedSkin.isEmpty || !_ownedSkins.contains(_selectedSkin)) {
      _selectedSkin = _defaultSkinId;
    }

    _ownedTrails =
        (scopedOwnedTrails ?? legacyOwnedTrails ?? <String>[_defaultTrailId])
            .toSet();
    if (_ownedTrails.isEmpty) {
      _ownedTrails = <String>{_defaultTrailId};
    } else {
      _ownedTrails.add(_defaultTrailId);
    }

    _selectedTrail =
        (scopedSelectedTrail ?? legacySelectedTrail ?? _defaultTrailId).trim();
    if (_selectedTrail.isEmpty || !_ownedTrails.contains(_selectedTrail)) {
      _selectedTrail = _defaultTrailId;
    }

    _skinAssetMap = <String, String>{..._skinAssetById};
    final rawMap = (scopedSkinMapRaw ?? legacySkinMapRaw ?? '').trim();
    if (rawMap.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMap);
        if (decoded is Map<String, dynamic>) {
          for (final e in decoded.entries) {
            final value = e.value;
            if (value is String && value.trim().isNotEmpty) {
              _skinAssetMap[e.key] = value;
            }
          }
        }
      } catch (_) {}
    }

    _normalizeSkinAssetMapToRemoteIfNeeded();
    await _persistScopedCosmeticState();
    if (kDebugMode) {
      debugPrint(
        '[coins] cosmetics from local cache uid=$uid '
        'equippedSkin=$_selectedSkin equippedTrail=$_selectedTrail '
        'ownedSkins=${_ownedSkins.length} ownedTrails=${_ownedTrails.length}',
      );
    }
    notifyListeners();
  }

  Future<void> _hydrateInventoryFromRemote(String uid) async {
    try {
      final userRef = _usersDocRef(uid);
      final userSnap = await userRef.get();
      final userData = userSnap.data() ?? const <String, dynamic>{};

      final remoteOwnedSkinsSnap =
          await userRef.collection('owned_skins').get();
      final remoteOwnedTrailsSnap =
          await userRef.collection('owned_trails').get();

      final nextOwnedSkins = <String>{..._ownedSkins};
      for (final doc in remoteOwnedSkinsSnap.docs) {
        final data = doc.data();
        if (data['owned'] == false) continue;
        nextOwnedSkins.add(_localSkinId(doc.id));
      }
      nextOwnedSkins.add(_defaultSkinId);

      final nextOwnedTrails = <String>{..._ownedTrails};
      for (final doc in remoteOwnedTrailsSnap.docs) {
        final data = doc.data();
        if (data['owned'] == false) continue;
        nextOwnedTrails.add(_localTrailId(doc.id));
      }
      nextOwnedTrails.add(_defaultTrailId);

      final remoteEquippedSkinRaw =
          (userData['equippedSkinId'] as String?)?.trim() ?? '';
      final remoteEquippedTrailRaw =
          (userData['equippedTrailId'] as String?)?.trim() ?? '';
      final remoteEquippedSkin = remoteEquippedSkinRaw.isEmpty
          ? _defaultSkinId
          : _localSkinId(remoteEquippedSkinRaw);
      final remoteEquippedTrail = remoteEquippedTrailRaw.isEmpty
          ? _defaultTrailId
          : _localTrailId(remoteEquippedTrailRaw);

      var changed = false;
      if (nextOwnedSkins.length != _ownedSkins.length ||
          !nextOwnedSkins.containsAll(_ownedSkins)) {
        _ownedSkins = nextOwnedSkins;
        await _persistOwnedSkinsScoped();
        changed = true;
      }
      if (nextOwnedTrails.length != _ownedTrails.length ||
          !nextOwnedTrails.containsAll(_ownedTrails)) {
        _ownedTrails = nextOwnedTrails;
        await _persistOwnedTrailsScoped();
        changed = true;
      }

      if (_ownedSkins.contains(remoteEquippedSkin) &&
          _selectedSkin != remoteEquippedSkin) {
        _selectedSkin = remoteEquippedSkin;
        await _persistSelectedSkinScoped();
        changed = true;
      }
      if (_ownedTrails.contains(remoteEquippedTrail) &&
          _selectedTrail != remoteEquippedTrail) {
        _selectedTrail = remoteEquippedTrail;
        await _persistSelectedTrailScoped();
        changed = true;
      }

      if (kDebugMode) {
        debugPrint(
          '[coins] cosmetics from Firestore uid=$uid '
          'ownedSkins=${_ownedSkins.length} ownedTrails=${_ownedTrails.length} '
          'equippedSkin=$_selectedSkin equippedTrail=$_selectedTrail',
        );
      }
      if (changed) {
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[coins] hydrate inventory failed uid=$uid: $e');
      }
    }
  }

  Future<void> _ensureUserDocument(String uid) async {
    try {
      final ref = _usersDocRef(uid);
      DocumentSnapshot<Map<String, dynamic>> snap;
      try {
        snap = await ref.get(const GetOptions(source: Source.server));
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[coins] ensureUserDocument skipped (server read unavailable) uid=$uid error=$e',
          );
        }
        return;
      }
      final ts = FieldValue.serverTimestamp();
      final authUser = _firebaseUserOrNull;
      if (snap.exists) {
        final existing = snap.data() ?? <String, dynamic>{};
        final missing = UserModel.missingFieldsForExisting(
          uid: uid,
          existing: existing,
          updatedAt: ts,
        );
        // Migration must never write wallet defaults; those are managed only
        // by explicit economy flows (rewards/purchases/manual grants).
        missing.remove('coins');
        missing.remove('lifetimeCoinsEarned');
        missing.remove('lifetimeCoinsPurchased');
        final authPatch = <String, dynamic>{};
        final authName = (authUser?.displayName ?? '').trim();
        final authEmail = (authUser?.email ?? '').trim();
        final authPhoto = (authUser?.photoURL ?? '').trim();
        final existingName = (existing['playerName'] as String?)?.trim() ?? '';
        final existingEmail = (existing['email'] as String?)?.trim() ?? '';
        final existingPhoto = (existing['photoUrl'] as String?)?.trim() ?? '';
        if (authName.isNotEmpty &&
            (existingName.isEmpty || existingName == 'Player')) {
          authPatch['playerName'] = authName;
        }
        if (authEmail.isNotEmpty && existingEmail.isEmpty) {
          authPatch['email'] = authEmail;
        }
        final existingEmailLower =
            (existing['emailLowercase'] as String?)?.trim() ?? '';
        if (authEmail.isNotEmpty &&
            (existingEmailLower.isEmpty ||
                existingEmailLower != authEmail.toLowerCase())) {
          authPatch['emailLowercase'] = authEmail.toLowerCase();
        }
        if (authPhoto.isNotEmpty && existingPhoto.isEmpty) {
          authPatch['photoUrl'] = authPhoto;
        }
        final existingUsername =
            (existing['username'] as String?)?.trim() ?? '';
        final existingLower =
            (existing['usernameLowercase'] as String?)?.trim() ?? '';
        if (existingUsername.isNotEmpty && existingLower.isEmpty) {
          missing['usernameLowercase'] = existingUsername.toLowerCase();
        }
        missing.addAll(authPatch);
        if (missing.isNotEmpty) {
          _debugUserSetWrite(uid, missing, source: '_ensureUserDocument:migrate');
          await ref.set(missing, SetOptions(merge: true));
          if (kDebugMode) {
            debugPrint(
              '[coins] user doc migrated users/$uid fields=${missing.keys.toList()} db=${_activeFirestoreName()}',
            );
          }
        }
        if (kDebugMode) {
          debugPrint(
            '[coins] user doc already exists users/$uid db=${_activeFirestoreName()}',
          );
        }
        final merged = <String, dynamic>{...existing, ...missing};
        await _syncUserLookupIndexes(uid: uid, userData: merged);
        await _ensureOwnedDefaultsRemote(uid);
        return;
      }
      var recoveredCoins = max(0, _coins);
      final fallbackCoins = await _tryReadCoinsFromDefaultDb(uid);
      if (fallbackCoins != null) {
        recoveredCoins = max(recoveredCoins, fallbackCoins);
      }

      final freshPayload = UserModel.defaultFirestore(
        uid: uid,
        createdAt: ts,
        updatedAt: ts,
      )
        ..['playerName'] = (authUser?.displayName ?? '').trim().isNotEmpty
            ? authUser!.displayName!.trim()
            : 'Player'
        ..['email'] = (authUser?.email ?? '').trim()
        ..['emailLowercase'] = (authUser?.email ?? '').trim().toLowerCase()
        ..['photoUrl'] = (authUser?.photoURL ?? '').trim();
      // Never initialize wallet fields here to avoid accidental resets on
      // races/mis-detected first-run states.
      freshPayload.remove('coins');
      freshPayload.remove('lifetimeCoinsEarned');
      freshPayload.remove('lifetimeCoinsPurchased');
      _debugUserSetWrite(uid, freshPayload, source: '_ensureUserDocument:create');
      await ref.set(freshPayload, SetOptions(merge: true));
      if (kDebugMode) {
        debugPrint(
          '[coins] user doc created (non-wallet fields) users/$uid '
          'recoveredCoins=$recoveredCoins db=${_activeFirestoreName()}',
        );
      }
      await _syncUserLookupIndexes(uid: uid, userData: freshPayload);
      await _ensureOwnedDefaultsRemote(uid);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[coins] ensureUserDocument failed uid=$uid: $e');
      }
    }
  }

  Future<void> _mergeLocalWithRemote(String uid) async {
    if (_syncInProgress) return;
    _syncInProgress = true;
    try {
      final docRef = _usersDocRef(uid);
      final snap = await _getUserDocFresh(docRef);
      final remoteCoins = _readRemoteInt(snap.data(), 'coins');
      final isFirstSyncForUid = _lastSyncedUid != uid;
      // Startup/auth sync is strictly remote-authoritative for wallet values.
      // We intentionally DO NOT push local pending deltas here to avoid
      // overriding manual admin edits in Firestore.
      final target = max(0, remoteCoins).toInt();
      if (kDebugMode) {
        debugPrint(
          '[coins] merge read uid=$uid remoteCoins=$remoteCoins unsyncedDelta=$_unsyncedDelta firstSync=$isFirstSyncForUid db=${_activeFirestoreName()}',
        );
      }
      final now = FieldValue.serverTimestamp();
      final payload = <String, dynamic>{
        'uid': uid,
        'equippedSkinId': _remoteSkinId(_selectedSkin),
        'equippedTrailId': _remoteTrailId(_selectedTrail),
        'updatedAt': now,
        if (!snap.exists) 'createdAt': now,
      };
      _debugUserSetWrite(uid, payload, source: '_mergeLocalWithRemote');
      await docRef.set(payload, SetOptions(merge: true));

      _coins = target;
      _unsyncedDelta = 0;
      _unsyncedLifetimeEarned = 0;
      _unsyncedLifetimePurchased = 0;
      _unsyncedLevelsCompleted = 0;
      _lastSyncedUid = uid;
      await _persistCoinSyncState();
      await _prefs.setString(_lastSyncedUidKey, uid);
      _remoteRetryTimer?.cancel();
      _emitCoinUpdate();
      if (kDebugMode) {
        if (isFirstSyncForUid) {
          debugPrint(
            '[coins] first sync for uid=$uid uses remote source of truth '
            '(no cross-user local carryover)',
          );
        }
        debugPrint(
          '[coins] merge sync OK uid=$uid coins=$_coins db=${_activeFirestoreName()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[coins] merge sync failed uid=$uid: $e');
      }
      _scheduleRemoteRetry();
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _syncCoinsToRemoteSilently() async {
    final user = _firebaseUserOrNull;
    if (user == null || _syncInProgress) return;
    if (_unsyncedDelta == 0 &&
        _unsyncedLifetimeEarned == 0 &&
        _unsyncedLifetimePurchased == 0 &&
        _unsyncedLevelsCompleted == 0) {
      return;
    }
    _syncInProgress = true;
    try {
      final docRef = _usersDocRef(user.uid);
      final delta = _unsyncedDelta;
      final earnedDelta = _unsyncedLifetimeEarned;
      final purchasedDelta = _unsyncedLifetimePurchased;
      final levelsDelta = _unsyncedLevelsCompleted;
      final payload = <String, dynamic>{
        'uid': user.uid,
        if (delta != 0) 'coins': FieldValue.increment(delta),
        if (earnedDelta != 0) 'lifetimeCoinsEarned': FieldValue.increment(earnedDelta),
        if (purchasedDelta != 0)
          'lifetimeCoinsPurchased': FieldValue.increment(purchasedDelta),
        if (levelsDelta != 0)
          'totalLevelsCompleted': FieldValue.increment(levelsDelta),
        'equippedSkinId': _remoteSkinId(_selectedSkin),
        'equippedTrailId': _remoteTrailId(_selectedTrail),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      _debugUserSetWrite(user.uid, payload, source: '_syncCoinsToRemoteSilently');
      await docRef.set(payload, SetOptions(merge: true));

      // Keep current local wallet (already updated by local actions) and clear pending deltas.
      _unsyncedDelta = 0;
      _unsyncedLifetimeEarned = 0;
      _unsyncedLifetimePurchased = 0;
      _unsyncedLevelsCompleted = 0;
      _lastSyncedUid = user.uid;
      await _persistCoinSyncState();
      await _prefs.setString(_lastSyncedUidKey, user.uid);
      _remoteRetryTimer?.cancel();
      _emitCoinUpdate();
      if (kDebugMode) {
        debugPrint(
          '[coins] silent sync OK uid=${user.uid} coins=$_coins appliedDelta=$delta db=${_activeFirestoreName()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[coins] silent sync failed uid=${user.uid}: $e');
      }
      _scheduleRemoteRetry();
    } finally {
      _syncInProgress = false;
    }
  }

  void _scheduleRemoteRetry() {
    if (!_isFirebaseConfigured) return;
    _remoteRetryTimer?.cancel();
    _remoteRetryTimer = Timer(const Duration(seconds: 8), () {
      unawaited(_syncCoinsToRemoteSilently());
    });
    if (kDebugMode) {
      debugPrint('[coins] scheduled remote retry in 8s');
    }
  }

  int _readRemoteInt(Map<String, dynamic>? data, String key) {
    if (data == null) return 0;
    final value = data[key];
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  void _emitCoinUpdate() {
    _coinsController.add(_coins);
    notifyListeners();
  }

  void _triggerCoinRewardAnimation(int amount, {int? visualOverride}) {
    if (amount <= 0) return;
    final visual = visualOverride ?? _visualCoinsForReward(amount);
    unawaited(
      CoinRewardOverlayService.instance.showCoinRewardAnimation(
        amount: amount,
        visualCount: visual,
      ),
    );
  }

  int _visualCoinsForReward(int amount) {
    if (amount <= 30) return 12;
    if (amount <= 200) return 14;
    if (amount <= 1200) return 16;
    return 18;
  }

  int _visualCoinsForPurchase(int amount) {
    if (amount <= 1200) return 16;
    if (amount <= 6500) return 18;
    if (amount <= 14000) return 20;
    return 24;
  }

  Future<void> _updateEquippedRemote({
    String? skinId,
    String? trailId,
  }) async {
    final user = _firebaseUserOrNull;
    if (user == null) return;
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (skinId != null) {
      payload['equippedSkinId'] = _remoteSkinId(skinId);
    }
    if (trailId != null) {
      payload['equippedTrailId'] = _remoteTrailId(trailId);
    }
    try {
      _debugUserSetWrite(user.uid, payload, source: '_updateEquippedRemote');
      await _usersDocRef(user.uid).set(payload, SetOptions(merge: true));
    } catch (_) {
      _scheduleRemoteRetry();
    }
  }

  Future<void> _markOwnedSkinRemote(
    String skinId, {
    required String source,
  }) async {
    final user = _firebaseUserOrNull;
    if (user == null) return;
    final canonical = _remoteSkinId(skinId);
    try {
      await _usersDocRef(user.uid)
          .collection('owned_skins')
          .doc(canonical)
          .set(<String, dynamic>{
        'owned': true,
        'purchasedAt': FieldValue.serverTimestamp(),
        'source': source,
      }, SetOptions(merge: true));
    } catch (_) {
      _scheduleRemoteRetry();
    }
  }

  Future<void> _markOwnedTrailRemote(
    String trailId, {
    required String source,
  }) async {
    final user = _firebaseUserOrNull;
    if (user == null) return;
    final canonical = _remoteTrailId(trailId);
    try {
      await _usersDocRef(user.uid)
          .collection('owned_trails')
          .doc(canonical)
          .set(<String, dynamic>{
        'owned': true,
        'purchasedAt': FieldValue.serverTimestamp(),
        'source': source,
      }, SetOptions(merge: true));
    } catch (_) {
      _scheduleRemoteRetry();
    }
  }

  String _remoteSkinId(String skinId) {
    return skinId == _defaultSkinId ? 'default' : skinId;
  }

  String _remoteTrailId(String trailId) {
    return trailId == _defaultTrailId ? 'none' : trailId;
  }

  String _localSkinId(String remoteSkinId) {
    final value = remoteSkinId.trim();
    if (value.isEmpty || value == 'default') return _defaultSkinId;
    return value;
  }

  String _localTrailId(String remoteTrailId) {
    final value = remoteTrailId.trim();
    if (value.isEmpty || value == 'none') return _defaultTrailId;
    return value;
  }

  Future<void> _ensureOwnedDefaultsRemote(String uid) async {
    try {
      await _usersDocRef(uid).collection('owned_skins').doc('default').set(
        <String, dynamic>{
          'owned': true,
          'purchasedAt': FieldValue.serverTimestamp(),
          'source': 'reward',
        },
        SetOptions(merge: true),
      );
      await _usersDocRef(uid).collection('owned_trails').doc('none').set(
        <String, dynamic>{
          'owned': true,
          'purchasedAt': FieldValue.serverTimestamp(),
          'source': 'reward',
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      _scheduleRemoteRetry();
    }
  }

  Future<void> _syncUserLookupIndexes({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final username = (userData['username'] as String?)?.trim() ?? '';
      final usernameLower = username.toLowerCase();
      if (usernameLower.isNotEmpty) {
        await _activeFirestore().collection('usernames').doc(usernameLower).set(
          <String, dynamic>{
            'uid': uid,
            'username': username,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      final emailRaw = (userData['email'] as String?)?.trim() ?? '';
      final emailLower = emailRaw.toLowerCase();
      if (emailLower.isNotEmpty && emailLower.contains('@')) {
        await _activeFirestore().collection('emails').doc(emailLower).set(
          <String, dynamic>{
            'uid': uid,
            'email': emailRaw,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[coins] sync user lookup indexes failed uid=$uid: $e');
      }
    }
  }

  DocumentReference<Map<String, dynamic>> _usersDocRef(String uid) {
    return _activeFirestore().collection('users').doc(uid);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserDocFresh(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      return await ref.get(const GetOptions(source: Source.server));
    } catch (_) {
      // Fallback to default behavior when server-only read is unavailable.
      return ref.get();
    }
  }

  Future<int?> _tryReadCoinsFromDefaultDb(String uid) async {
    if (!_isFirebaseConfigured) return null;
    try {
      final preferred = _activeFirestore();
      final defaultDb = FirebaseFirestore.instance;
      if (preferred.databaseId == defaultDb.databaseId) return null;
      final snap = await defaultDb.collection('users').doc(uid).get();
      if (!snap.exists) return null;
      final recovered = _readRemoteInt(snap.data(), 'coins');
      if (kDebugMode) {
        debugPrint(
          '[coins] fallback read from default db uid=$uid '
          'coins=$recovered preferred=${preferred.databaseId} default=${defaultDb.databaseId}',
        );
      }
      return recovered;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[coins] fallback default-db read failed uid=$uid: $e');
      }
      return null;
    }
  }

  void _debugUserSetWrite(
    String uid,
    Map<String, dynamic> data, {
    required String source,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      'FIRESTORE WRITE users/$uid source=$source db=${_activeFirestoreName()} -> $data',
    );
  }

  FirebaseFirestore _activeFirestore() {
    if (!_isFirebaseConfigured) {
      throw StateError('Firebase not configured');
    }
    try {
      return FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: _firestoreDatabaseId,
      );
    } catch (_) {
      return FirebaseFirestore.instance;
    }
  }

  String _activeFirestoreName() {
    if (!_isFirebaseConfigured) {
      return '(firebase-disabled)';
    }
    try {
      FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: _firestoreDatabaseId,
      );
      return _firestoreDatabaseId;
    } catch (_) {
      return '(default)';
    }
  }

  void _normalizeSkinAssetMapToRemoteIfNeeded() {
    var changed = false;
    final next = <String, String>{..._skinAssetMap};
    for (final entry in next.entries.toList()) {
      final value = entry.value.trim();
      if (value.isEmpty) continue;
      final isAsset = value.startsWith('assets/');
      final isHttp =
          value.startsWith('http://') || value.startsWith('https://');
      final isData = value.startsWith('data:image');
      if (isAsset || isData) continue;

      if (isHttp) {
        final normalizedHttp = _normalizeLegacyHttpUrl(entry.key, value);
        if (normalizedHttp != null && normalizedHttp != value) {
          next[entry.key] = normalizedHttp;
          changed = true;
        }
        continue;
      }

      final normalizedStorage =
          _normalizeStoragePathToMediaUrl(entry.key, value);
      if (normalizedStorage != null && normalizedStorage != value) {
        next[entry.key] = normalizedStorage;
        changed = true;
      }
    }
    if (!changed) return;
    _skinAssetMap = next;
    _persistSkinAssetMapScoped();
  }

  String _stateUid() => _activeCosmeticUid ?? 'guest';

  String _ownedSkinsKeyForUid(String uid) => 'ownedSkins_$uid';
  String _selectedSkinKeyForUid(String uid) => 'equippedSkin_$uid';
  String _ownedTrailsKeyForUid(String uid) => 'ownedTrails_$uid';
  String _selectedTrailKeyForUid(String uid) => 'equippedTrail_$uid';
  String _skinAssetMapKeyForUid(String uid) => 'skinAssetMap_$uid';
  String _claimedLevelRewardsKeyForUid(String uid) =>
      '$_claimedLevelRewardsPrefix$uid';

  Future<void> _persistClaimedLevelRewardsScoped() async {
    final sorted = _claimedLevelRewards.toList()..sort();
    final rewardsUid = _activeRewardsUid?.trim() ?? '';
    if (rewardsUid.isEmpty) {
      await _prefs.setStringList(_claimedLevelRewardsKey, sorted);
      return;
    }
    await _prefs.setStringList(
        _claimedLevelRewardsKeyForUid(rewardsUid), sorted);
  }

  Future<void> _persistOwnedSkinsScoped() async {
    await _prefs.setStringList(
      _ownedSkinsKeyForUid(_stateUid()),
      _ownedSkins.toList()..sort(),
    );
  }

  Future<void> _persistSelectedSkinScoped() async {
    await _prefs.setString(_selectedSkinKeyForUid(_stateUid()), _selectedSkin);
  }

  Future<void> _persistOwnedTrailsScoped() async {
    await _prefs.setStringList(
      _ownedTrailsKeyForUid(_stateUid()),
      _ownedTrails.toList()..sort(),
    );
  }

  Future<void> _persistSelectedTrailScoped() async {
    await _prefs.setString(
        _selectedTrailKeyForUid(_stateUid()), _selectedTrail);
  }

  Future<void> _persistSkinAssetMapScoped() async {
    await _prefs.setString(
      _skinAssetMapKeyForUid(_stateUid()),
      jsonEncode(_skinAssetMap),
    );
  }

  Future<void> _persistScopedCosmeticState() async {
    await _persistOwnedSkinsScoped();
    await _persistSelectedSkinScoped();
    await _persistOwnedTrailsScoped();
    await _persistSelectedTrailScoped();
    await _persistSkinAssetMapScoped();
  }

  String? _inferRemoteUrlForSkinId(String skinId) {
    if (skinId.trim().isEmpty || skinId == _defaultSkinId) return null;
    final alias = _skinFileAliasById[skinId];
    final canonicalId = _canonicalSkinIdFromAny(alias ?? skinId);
    final encoded = Uri.encodeComponent('skins/$canonicalId/$canonicalId.png');
    return 'https://firebasestorage.googleapis.com/v0/b/$_firebaseStorageBucket/o/$encoded?alt=media';
  }

  String _toPngFileName(String fileName) {
    final normalized = fileName.replaceAll('\\', '/');
    final dot = normalized.lastIndexOf('.');
    if (dot <= 0 || dot >= normalized.length - 1) return '$normalized.png';
    final ext = normalized.substring(dot + 1).toLowerCase();
    if (ext == 'png') return normalized;
    return '${normalized.substring(0, dot)}.png';
  }

  static String _basename(String input) {
    final normalized = input.replaceAll('\\', '/');
    final idx = normalized.lastIndexOf('/');
    if (idx < 0 || idx >= normalized.length - 1) return normalized;
    return normalized.substring(idx + 1);
  }

  String? _normalizeLegacyHttpUrl(String skinId, String httpUrl) {
    final uri = Uri.tryParse(httpUrl);
    final host = (uri?.host ?? '').toLowerCase();
    final isLocalhost = host == 'localhost' || host == '127.0.0.1';
    if (isLocalhost) {
      final canonicalId = _canonicalSkinIdFromAny(skinId);
      final encoded =
          Uri.encodeComponent('skins/$canonicalId/$canonicalId.png');
      return 'https://firebasestorage.googleapis.com/v0/b/$_firebaseStorageBucket/o/$encoded?alt=media';
    }

    final lower = httpUrl.toLowerCase();
    if (!lower.contains('/skins_low_renders/') &&
        !lower.contains('%2fskins_low_renders%2f')) {
      return null;
    }
    final canonicalId = _canonicalSkinIdFromAny(skinId);
    final encoded = Uri.encodeComponent('skins/$canonicalId/$canonicalId.png');
    return 'https://firebasestorage.googleapis.com/v0/b/$_firebaseStorageBucket/o/$encoded?alt=media';
  }

  String? _normalizeStoragePathToMediaUrl(String skinId, String rawPath) {
    final normalized = rawPath.replaceAll('\\', '/').trim();
    final lower = normalized.toLowerCase();
    final isImage = lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
    if (!isImage) return null;

    if (lower.startsWith('skins/')) {
      final encoded = Uri.encodeComponent(_toPngFileName(normalized));
      return 'https://firebasestorage.googleapis.com/v0/b/$_firebaseStorageBucket/o/$encoded?alt=media';
    }

    if (lower.startsWith('skins_low_renders/')) {
      final canonicalId = _canonicalSkinIdFromAny(skinId);
      final encoded =
          Uri.encodeComponent('skins/$canonicalId/$canonicalId.png');
      return 'https://firebasestorage.googleapis.com/v0/b/$_firebaseStorageBucket/o/$encoded?alt=media';
    }

    final fileName = _basename(normalized);
    if (fileName.isEmpty) return null;
    final canonicalId = _canonicalSkinIdFromAny(skinId);
    final encoded = Uri.encodeComponent(
      'skins/$canonicalId/${_toPngFileName(fileName)}',
    );
    return 'https://firebasestorage.googleapis.com/v0/b/$_firebaseStorageBucket/o/$encoded?alt=media';
  }

  String _canonicalSkinIdFromAny(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'pointer-default';
    final file = _basename(trimmed)
        .replaceFirst(RegExp(r'\.[a-z0-9]+$', caseSensitive: false), '');
    final normalized =
        file.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final compact = normalized
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (compact.isEmpty) return 'pointer-default';
    if (compact.endsWith('-thumb')) {
      return compact.substring(0, compact.length - '-thumb'.length);
    }
    if (compact.endsWith('-banner')) {
      return compact.substring(0, compact.length - '-banner'.length);
    }
    return compact;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _remoteRetryTimer?.cancel();
    _coinsController.close();
    super.dispose();
  }
}

enum BuyCoinPackStatus { comingSoon, success, cancelled, failed }

class BuyCoinPackResult {
  const BuyCoinPackResult({
    required this.status,
    required this.addedCoins,
    required this.message,
  });

  final BuyCoinPackStatus status;
  final int addedCoins;
  final String message;
}
