import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class UserInventoryState {
  const UserInventoryState({
    required this.coins,
    required this.equippedSkinId,
    required this.ownedSkinIds,
  });

  final int coins;
  final String equippedSkinId;
  final Set<String> ownedSkinIds;
}

class UserInventoryService {
  static const String _firestoreDatabaseId = 'tracepath-database';

  Future<bool> userOwnsSkin(String skinId) async {
    final uid = await _requireUid();
    final snap = await _userRef(uid).collection('owned_skins').doc(skinId).get();
    if (!snap.exists) return false;
    final data = snap.data() ?? <String, dynamic>{};
    final owned = data['owned'];
    if (owned is bool) return owned;
    return true;
  }

  Future<void> purchaseSkin({
    required String skinId,
    required int price,
  }) async {
    final uid = await _requireUid();
    if (skinId.trim().isEmpty) {
      throw StateError('Invalid skin id');
    }
    if (price < 0) {
      throw StateError('Invalid skin price');
    }
    final userRef = _userRef(uid);
    final ownedRef = userRef.collection('owned_skins').doc(skinId);
    await _db().runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) {
        throw StateError('USER_DOC_NOT_FOUND');
      }
      final ownedSnap = await tx.get(ownedRef);
      if (ownedSnap.exists) {
        tx.set(
          userRef,
          <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        return;
      }
      final data = userSnap.data() ?? <String, dynamic>{};
      final currentCoins = _readInt(data['coins']);
      if (currentCoins < price) {
        throw StateError('INSUFFICIENT_COINS');
      }
      tx.set(
        userRef,
        <String, dynamic>{
          'coins': max(0, currentCoins - price),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(
        ownedRef,
        <String, dynamic>{
          'owned': true,
          'purchasedAt': FieldValue.serverTimestamp(),
          'source': 'shop',
        },
      );
    });
  }

  Future<void> equipSkin(String skinId) async {
    final uid = await _requireUid();
    final userRef = _userRef(uid);
    final ownedRef = userRef.collection('owned_skins').doc(skinId);
    final ownedSnap = await ownedRef.get();
    if (!ownedSnap.exists) {
      throw StateError('SKIN_NOT_OWNED');
    }
    await userRef.set(
      <String, dynamic>{
        'equippedSkinId': skinId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<List<String>> getOwnedSkins() async {
    final uid = await _requireUid();
    final snap = await _userRef(uid).collection('owned_skins').get();
    final ids = <String>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      final owned = data['owned'];
      if (owned == false) continue;
      ids.add(doc.id);
    }
    if (!ids.contains('default')) {
      ids.add('default');
    }
    ids.sort();
    return ids;
  }

  Future<UserInventoryState> getInventoryState() async {
    final uid = await _requireUid();
    final userSnap = await _userRef(uid).get();
    final userData = userSnap.data() ?? <String, dynamic>{};
    final coins = _readInt(userData['coins']);
    final equippedRaw = (userData['equippedSkinId'] as String?)?.trim() ?? '';
    final equipped = equippedRaw.isEmpty ? 'default' : equippedRaw;
    final owned = await getOwnedSkins();
    return UserInventoryState(
      coins: coins,
      equippedSkinId: equipped,
      ownedSkinIds: owned.toSet(),
    );
  }

  Future<int> getCurrentCoins() async {
    final uid = await _requireUid();
    final snap = await _userRef(uid).get();
    return _readInt((snap.data() ?? const <String, dynamic>{})['coins']);
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _db().collection('users').doc(uid);
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

  int _readInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}
