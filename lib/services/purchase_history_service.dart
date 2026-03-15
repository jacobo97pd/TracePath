import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/purchase_record.dart';

class PurchaseHistoryService {
  static const String _firestoreDatabaseId = 'tracepath-database';

  Future<void> addPurchaseRecord({
    required String uid,
    required String productId,
    required String platform,
    required String status,
    required int coinsGranted,
    required bool receiptVerified,
    String? purchaseId,
  }) async {
    final normalizedUid = uid.trim().isEmpty ? await _requireUid() : uid.trim();
    final ref = _purchasesRef(normalizedUid);
    final docId = (purchaseId ?? '').trim();
    final payload = <String, dynamic>{
      'productId': productId.trim(),
      'platform': _normalizePlatform(platform),
      'status': _normalizeStatus(status),
      'coinsGranted': coinsGranted,
      'receiptVerified': receiptVerified,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (docId.isNotEmpty) {
      await ref.doc(docId).set(payload, SetOptions(merge: true));
      return;
    }
    await ref.add(payload);
  }

  Stream<List<PurchaseRecord>> watchPurchases(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return const Stream<List<PurchaseRecord>>.empty();
    }
    return _purchasesRef(normalizedUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => PurchaseRecord.fromFirestore(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  CollectionReference<Map<String, dynamic>> _purchasesRef(String uid) {
    return _db().collection('users').doc(uid).collection('purchases');
  }

  String _normalizePlatform(String raw) {
    final value = raw.trim().toLowerCase();
    switch (value) {
      case 'android':
      case 'ios':
        return value;
      default:
        return 'android';
    }
  }

  String _normalizeStatus(String raw) {
    final value = raw.trim().toLowerCase();
    switch (value) {
      case 'completed':
      case 'pending':
      case 'canceled':
        return value;
      default:
        return 'pending';
    }
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

