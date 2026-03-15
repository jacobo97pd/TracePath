import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/wallet_transaction.dart';

class WalletHistoryService {
  static const String _firestoreDatabaseId = 'tracepath-database';

  Future<void> addTransaction({
    required String uid,
    required String type,
    required int amount,
    required String source,
    String? referenceId,
  }) async {
    final normalizedUid = uid.trim().isEmpty ? await _requireUid() : uid.trim();
    final normalizedType = _normalizeType(type);
    final normalizedSource = _normalizeSource(source);
    await _transactionsRef(normalizedUid).add(
      <String, dynamic>{
        'type': normalizedType,
        'amount': amount,
        'source': normalizedSource,
        'referenceId': (referenceId ?? '').trim(),
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Stream<List<WalletTransaction>> watchTransactions(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return const Stream<List<WalletTransaction>>.empty();
    }
    return _transactionsRef(normalizedUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => WalletTransaction.fromFirestore(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  CollectionReference<Map<String, dynamic>> _transactionsRef(String uid) {
    return _db()
        .collection('users')
        .doc(uid)
        .collection('wallet_transactions');
  }

  String _normalizeType(String raw) {
    final value = raw.trim().toLowerCase();
    switch (value) {
      case 'reward':
      case 'purchase':
      case 'spend':
        return value;
      default:
        return 'reward';
    }
  }

  String _normalizeSource(String raw) {
    final value = raw.trim().toLowerCase();
    switch (value) {
      case 'level_complete':
      case 'coin_pack':
      case 'skin_purchase':
      case 'trail_purchase':
        return value;
      default:
        return 'level_complete';
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

