import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_firestore.dart';
import 'daily_puzzle_service.dart';

class EnergyCatalogItem {
  const EnergyCatalogItem({
    required this.productId,
    required this.batteryUnits,
    required this.coinCost,
    required this.title,
    required this.subtitle,
  });

  final String productId;
  final int batteryUnits;
  final int coinCost;
  final String title;
  final String subtitle;
}

enum EnergyConsumeFailureReason {
  none,
  noEnergy,
  authRequired,
  unknown,
}

class EnergyConsumeResult {
  const EnergyConsumeResult({
    required this.success,
    required this.snapshot,
    this.failureReason = EnergyConsumeFailureReason.none,
  });

  final bool success;
  final EnergySnapshot snapshot;
  final EnergyConsumeFailureReason failureReason;
}

enum EnergyBatteryUseFailureReason {
  none,
  noBattery,
  alreadyFull,
  authRequired,
  unknown,
}

class EnergyBatteryUseResult {
  const EnergyBatteryUseResult({
    required this.success,
    required this.snapshot,
    this.failureReason = EnergyBatteryUseFailureReason.none,
  });

  final bool success;
  final EnergySnapshot snapshot;
  final EnergyBatteryUseFailureReason failureReason;
}

enum EnergyBatteryPurchaseFailureReason {
  none,
  notEnoughCoins,
  authRequired,
  invalidOffer,
  unknown,
}

class EnergyBatteryPurchaseResult {
  const EnergyBatteryPurchaseResult({
    required this.success,
    required this.snapshot,
    this.newCoinsBalance,
    this.failureReason = EnergyBatteryPurchaseFailureReason.none,
  });

  final bool success;
  final EnergySnapshot snapshot;
  final int? newCoinsBalance;
  final EnergyBatteryPurchaseFailureReason failureReason;
}

class EnergySnapshot {
  const EnergySnapshot({
    required this.current,
    required this.max,
    required this.batteryCount,
    required this.dailyKey,
    required this.nextResetUtc,
  });

  factory EnergySnapshot.initial({
    int current = EnergyService.baseDailyMax,
    int max = EnergyService.baseDailyMax,
    int batteryCount = 0,
    String? dailyKey,
  }) {
    final now = DateTime.now().toUtc();
    return EnergySnapshot(
      current: current,
      max: max,
      batteryCount: batteryCount,
      dailyKey: dailyKey ?? DailyPuzzleService.currentDailyKey(now: now),
      nextResetUtc: DailyPuzzleService.nextDailyResetUtc(now: now),
    );
  }

  final int current;
  final int max;
  final int batteryCount;
  final String dailyKey;
  final DateTime nextResetUtc;

  bool get isDepleted => current <= 0;

  Duration timeUntilReset({DateTime? now}) {
    final base = (now ?? DateTime.now()).toUtc();
    final remaining = nextResetUtc.difference(base);
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }

  EnergySnapshot copyWith({
    int? current,
    int? max,
    int? batteryCount,
    String? dailyKey,
    DateTime? nextResetUtc,
  }) {
    return EnergySnapshot(
      current: current ?? this.current,
      max: max ?? this.max,
      batteryCount: batteryCount ?? this.batteryCount,
      dailyKey: dailyKey ?? this.dailyKey,
      nextResetUtc: nextResetUtc ?? this.nextResetUtc,
    );
  }
}

class EnergyService extends ChangeNotifier {
  EnergyService(this._prefs) {
    final auth = _firebaseAuthOrNull;
    if (auth != null) {
      _authSub = auth.authStateChanges().listen((_) {
        unawaited(refresh());
      });
    }
    _snapshot = _loadCachedSnapshot();
  }

  static const int baseDailyMax = 5;
  static const String _energyCurrentKey = 'energy_current';
  static const String _energyMaxKey = 'energy_max';
  static const String _energyLastResetKey = 'energy_last_reset_key';
  static const String _batteryCountKey = 'battery_count';
  static const String _firestoreDatabaseId = 'tracepath-database';

  static const List<EnergyCatalogItem> batteryOffers = <EnergyCatalogItem>[
    EnergyCatalogItem(
      productId: 'energy_battery_1',
      batteryUnits: 1,
      coinCost: 180,
      title: 'Battery x1',
      subtitle: 'Instant full energy refill',
    ),
    EnergyCatalogItem(
      productId: 'energy_battery_pack_3',
      batteryUnits: 3,
      coinCost: 480,
      title: 'Battery Pack x3',
      subtitle: '3 full refills at lower cost',
    ),
  ];

  final SharedPreferences _prefs;
  StreamSubscription<User?>? _authSub;
  EnergySnapshot _snapshot = EnergySnapshot.initial();
  bool _refreshing = false;

  FirebaseAuth? get _firebaseAuthOrNull {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  EnergySnapshot get snapshot => _snapshot;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<EnergySnapshot> refresh() async {
    if (_refreshing) return _snapshot;
    _refreshing = true;
    try {
      final uid = _activeUid();
      final todayKey = DailyPuzzleService.currentDailyKey();
      if (uid.isEmpty) {
        final local = _loadCachedSnapshot();
        final normalized = _normalizeForCurrentDailyKey(local, todayKey);
        await _persistScopedSnapshot(normalized, uid: _scopedUid(uid));
        _setSnapshot(normalized);
        return _snapshot;
      }

      final ref = _usersDoc(uid);
      EnergySnapshot? next;
      await _db().runTransaction((tx) async {
        final snap = await tx.get(ref);
        final map = snap.data() ?? <String, dynamic>{};
        final hydrated = _hydrateSnapshot(
          map,
          fallbackDailyKey: todayKey,
        );
        final normalized = _normalizeForCurrentDailyKey(hydrated, todayKey);
        final requiresWrite = _needsEnergyWrite(
          snapExists: snap.exists,
          data: map,
          normalized: normalized,
        );
        if (requiresWrite) {
          tx.set(
            ref,
            <String, dynamic>{
              'energyCurrent': normalized.current,
              'energyMax': normalized.max,
              'energyLastResetKey': normalized.dailyKey,
              'batteryCount': normalized.batteryCount,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
        next = normalized;
      });
      final resolved = next ?? EnergySnapshot.initial();
      await _persistScopedSnapshot(resolved, uid: _scopedUid(uid));
      _setSnapshot(resolved);
      if (kDebugMode) {
        debugPrint(
          '[energy] refresh uid=$uid current=${resolved.current}/${resolved.max} '
          'batteries=${resolved.batteryCount} key=${resolved.dailyKey} db=${_dbName()}',
        );
      }
      return _snapshot;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[energy] refresh failed: $e');
      }
      return _snapshot;
    } finally {
      _refreshing = false;
    }
  }

  Future<EnergyConsumeResult> consumeForNormalPuzzle() async {
    final uid = _activeUid();
    if (uid.isEmpty) {
      final refreshed = await refresh();
      if (refreshed.current <= 0) {
        return EnergyConsumeResult(
          success: false,
          snapshot: refreshed,
          failureReason: EnergyConsumeFailureReason.noEnergy,
        );
      }
      final next = refreshed.copyWith(current: refreshed.current - 1);
      await _persistScopedSnapshot(next, uid: _scopedUid(uid));
      _setSnapshot(next);
      return EnergyConsumeResult(success: true, snapshot: next);
    }

    try {
      final ref = _usersDoc(uid);
      EnergySnapshot? next;
      var ok = false;
      await _db().runTransaction((tx) async {
        final snap = await tx.get(ref);
        final map = snap.data() ?? <String, dynamic>{};
        final hydrated = _hydrateSnapshot(
          map,
          fallbackDailyKey: DailyPuzzleService.currentDailyKey(),
        );
        final normalized = _normalizeForCurrentDailyKey(
          hydrated,
          DailyPuzzleService.currentDailyKey(),
        );
        if (normalized.current <= 0) {
          ok = false;
          next = normalized;
          return;
        }
        final consumed = normalized.copyWith(current: normalized.current - 1);
        tx.set(
          ref,
          <String, dynamic>{
            'energyCurrent': consumed.current,
            'energyMax': consumed.max,
            'energyLastResetKey': consumed.dailyKey,
            'batteryCount': consumed.batteryCount,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        next = consumed;
        ok = true;
      });
      final resolved = next ?? _snapshot;
      _setSnapshot(resolved);
      await _persistScopedSnapshot(resolved, uid: _scopedUid(uid));
      return EnergyConsumeResult(
        success: ok,
        snapshot: resolved,
        failureReason: ok
            ? EnergyConsumeFailureReason.none
            : EnergyConsumeFailureReason.noEnergy,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[energy] consume failed uid=$uid: $e');
      }
      return EnergyConsumeResult(
        success: false,
        snapshot: _snapshot,
        failureReason: EnergyConsumeFailureReason.unknown,
      );
    }
  }

  Future<EnergyBatteryUseResult> useBatteryAndRefill() async {
    final uid = _activeUid();
    if (uid.isEmpty) {
      final refreshed = await refresh();
      if (refreshed.batteryCount <= 0) {
        return EnergyBatteryUseResult(
          success: false,
          snapshot: refreshed,
          failureReason: EnergyBatteryUseFailureReason.noBattery,
        );
      }
      if (refreshed.current >= refreshed.max) {
        return EnergyBatteryUseResult(
          success: false,
          snapshot: refreshed,
          failureReason: EnergyBatteryUseFailureReason.alreadyFull,
        );
      }
      final next = refreshed.copyWith(
        current: refreshed.max,
        batteryCount: math.max(0, refreshed.batteryCount - 1),
      );
      await _persistScopedSnapshot(next, uid: _scopedUid(uid));
      _setSnapshot(next);
      return EnergyBatteryUseResult(success: true, snapshot: next);
    }

    try {
      final ref = _usersDoc(uid);
      EnergySnapshot? next;
      var failure = EnergyBatteryUseFailureReason.none;
      await _db().runTransaction((tx) async {
        final snap = await tx.get(ref);
        final map = snap.data() ?? <String, dynamic>{};
        final normalized = _normalizeForCurrentDailyKey(
          _hydrateSnapshot(
            map,
            fallbackDailyKey: DailyPuzzleService.currentDailyKey(),
          ),
          DailyPuzzleService.currentDailyKey(),
        );
        if (normalized.batteryCount <= 0) {
          failure = EnergyBatteryUseFailureReason.noBattery;
          next = normalized;
          return;
        }
        if (normalized.current >= normalized.max) {
          failure = EnergyBatteryUseFailureReason.alreadyFull;
          next = normalized;
          return;
        }
        final consumedBattery = normalized.copyWith(
          current: normalized.max,
          batteryCount: math.max(0, normalized.batteryCount - 1),
        );
        tx.set(
          ref,
          <String, dynamic>{
            'energyCurrent': consumedBattery.current,
            'energyMax': consumedBattery.max,
            'energyLastResetKey': consumedBattery.dailyKey,
            'batteryCount': consumedBattery.batteryCount,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        next = consumedBattery;
      });
      final resolved = next ?? _snapshot;
      _setSnapshot(resolved);
      await _persistScopedSnapshot(resolved, uid: _scopedUid(uid));
      return EnergyBatteryUseResult(
        success: failure == EnergyBatteryUseFailureReason.none,
        snapshot: resolved,
        failureReason: failure,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[energy] use battery failed uid=$uid: $e');
      }
      return EnergyBatteryUseResult(
        success: false,
        snapshot: _snapshot,
        failureReason: EnergyBatteryUseFailureReason.unknown,
      );
    }
  }

  Future<EnergyBatteryPurchaseResult> buyBatteryPackWithCoins({
    required EnergyCatalogItem offer,
  }) async {
    if (offer.batteryUnits <= 0 || offer.coinCost < 0) {
      return EnergyBatteryPurchaseResult(
        success: false,
        snapshot: _snapshot,
        failureReason: EnergyBatteryPurchaseFailureReason.invalidOffer,
      );
    }
    final uid = _activeUid();
    if (uid.isEmpty) {
      return EnergyBatteryPurchaseResult(
        success: false,
        snapshot: _snapshot,
        failureReason: EnergyBatteryPurchaseFailureReason.authRequired,
      );
    }

    try {
      final ref = _usersDoc(uid);
      EnergySnapshot? next;
      int? nextCoins;
      var failure = EnergyBatteryPurchaseFailureReason.none;
      await _db().runTransaction((tx) async {
        final snap = await tx.get(ref);
        final map = snap.data() ?? <String, dynamic>{};
        final normalized = _normalizeForCurrentDailyKey(
          _hydrateSnapshot(
            map,
            fallbackDailyKey: DailyPuzzleService.currentDailyKey(),
          ),
          DailyPuzzleService.currentDailyKey(),
        );
        final currentCoins = _readInt(map['coins'], fallback: 0);
        if (currentCoins < offer.coinCost) {
          failure = EnergyBatteryPurchaseFailureReason.notEnoughCoins;
          next = normalized;
          nextCoins = currentCoins;
          return;
        }
        final purchased = normalized.copyWith(
          batteryCount: normalized.batteryCount + offer.batteryUnits,
        );
        nextCoins = currentCoins - offer.coinCost;
        tx.set(
          ref,
          <String, dynamic>{
            'coins': FieldValue.increment(-offer.coinCost),
            'batteryCount': purchased.batteryCount,
            'energyCurrent': purchased.current,
            'energyMax': purchased.max,
            'energyLastResetKey': purchased.dailyKey,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        next = purchased;
      });

      final resolved = next ?? _snapshot;
      _setSnapshot(resolved);
      await _persistScopedSnapshot(resolved, uid: _scopedUid(uid));
      return EnergyBatteryPurchaseResult(
        success: failure == EnergyBatteryPurchaseFailureReason.none,
        snapshot: resolved,
        newCoinsBalance: nextCoins,
        failureReason: failure,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[energy] buy battery failed uid=$uid: $e');
      }
      return EnergyBatteryPurchaseResult(
        success: false,
        snapshot: _snapshot,
        failureReason: EnergyBatteryPurchaseFailureReason.unknown,
      );
    }
  }

  void _setSnapshot(EnergySnapshot value) {
    _snapshot = value;
    notifyListeners();
  }

  EnergySnapshot _loadCachedSnapshot() {
    final uid = _scopedUid(_activeUid());
    final current = _prefs.getInt(_scoped(_energyCurrentKey, uid));
    final max = _prefs.getInt(_scoped(_energyMaxKey, uid));
    final battery = _prefs.getInt(_scoped(_batteryCountKey, uid));
    final dailyKey = _prefs.getString(_scoped(_energyLastResetKey, uid));
    return _normalizeForCurrentDailyKey(
      EnergySnapshot.initial(
        current: current ?? baseDailyMax,
        max: max ?? baseDailyMax,
        batteryCount: battery ?? 0,
        dailyKey: dailyKey,
      ),
      DailyPuzzleService.currentDailyKey(),
    );
  }

  Future<void> _persistScopedSnapshot(
    EnergySnapshot snapshot, {
    required String uid,
  }) async {
    await _prefs.setInt(_scoped(_energyCurrentKey, uid), snapshot.current);
    await _prefs.setInt(_scoped(_energyMaxKey, uid), snapshot.max);
    await _prefs.setInt(_scoped(_batteryCountKey, uid), snapshot.batteryCount);
    await _prefs.setString(
        _scoped(_energyLastResetKey, uid), snapshot.dailyKey);
  }

  bool _needsEnergyWrite({
    required bool snapExists,
    required Map<String, dynamic> data,
    required EnergySnapshot normalized,
  }) {
    if (!snapExists) return true;
    final hasCurrent = data.containsKey('energyCurrent');
    final hasMax = data.containsKey('energyMax');
    final hasKey = data.containsKey('energyLastResetKey');
    final hasBattery = data.containsKey('batteryCount');
    if (!hasCurrent || !hasMax || !hasKey || !hasBattery) return true;
    if (_readInt(data['energyCurrent'], fallback: normalized.current) !=
        normalized.current) {
      return true;
    }
    if (_readInt(data['energyMax'], fallback: normalized.max) !=
        normalized.max) {
      return true;
    }
    if (_readInt(data['batteryCount'], fallback: normalized.batteryCount) !=
        normalized.batteryCount) {
      return true;
    }
    return _readString(data['energyLastResetKey']) != normalized.dailyKey;
  }

  EnergySnapshot _hydrateSnapshot(
    Map<String, dynamic> data, {
    required String fallbackDailyKey,
  }) {
    final max = _readInt(data['energyMax'], fallback: baseDailyMax);
    final safeMax = max <= 0 ? baseDailyMax : max;
    final current = _readInt(data['energyCurrent'], fallback: safeMax);
    final dailyKey =
        _readString(data['energyLastResetKey']) ?? fallbackDailyKey;
    final battery = _readInt(data['batteryCount'], fallback: 0);
    final now = DateTime.now().toUtc();
    return EnergySnapshot(
      current: current.clamp(0, safeMax),
      max: safeMax,
      batteryCount: math.max(0, battery),
      dailyKey: dailyKey,
      nextResetUtc: DailyPuzzleService.nextDailyResetUtc(now: now),
    );
  }

  EnergySnapshot _normalizeForCurrentDailyKey(
    EnergySnapshot snapshot,
    String expectedDailyKey,
  ) {
    if (snapshot.dailyKey == expectedDailyKey) {
      return snapshot.copyWith(
        nextResetUtc: DailyPuzzleService.nextDailyResetUtc(),
      );
    }
    return snapshot.copyWith(
      current: snapshot.max,
      dailyKey: expectedDailyKey,
      nextResetUtc: DailyPuzzleService.nextDailyResetUtc(),
    );
  }

  int _readInt(Object? value, {required int fallback}) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? fallback;
    return fallback;
  }

  String? _readString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _activeUid() {
    try {
      return FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _scopedUid(String uid) {
    final trimmed = uid.trim();
    return trimmed.isEmpty ? 'guest' : trimmed;
  }

  String _scoped(String key, String uid) => '$key:$uid';

  FirebaseFirestore _db() {
    return AppFirestore.instance();
  }

  String _dbName() {
    try {
      return _db().databaseId;
    } catch (_) {
      return _firestoreDatabaseId;
    }
  }

  DocumentReference<Map<String, dynamic>> _usersDoc(String uid) {
    return _db().collection('users').doc(uid);
  }
}
