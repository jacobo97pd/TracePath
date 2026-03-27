import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/inbox_item.dart';

class InboxService {
  static const String _firestoreDatabaseId = 'tracepath-database';

  Future<void> addInboxItem({
    required String uid,
    required String type,
    required String title,
    required String body,
    required String status,
    bool read = false,
    Map<String, dynamic>? extraData,
    String? messageId,
  }) async {
    final normalizedUid = uid.trim().isEmpty ? await _requireUid() : uid.trim();
    final normalizedType = _normalizeType(type);
    final normalizedStatus = _normalizeStatus(status);
    final payload = <String, dynamic>{
      'type': normalizedType,
      'title': title.trim().isEmpty ? 'Message' : title.trim(),
      'body': body.trim(),
      'status': normalizedStatus,
      'read': read,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (extraData != null && extraData.isNotEmpty) {
      payload.addAll(extraData);
    }
    final ref = _inboxRef(normalizedUid);
    final docId = (messageId ?? '').trim();
    if (docId.isNotEmpty) {
      await ref.doc(docId).set(payload, SetOptions(merge: true));
      return;
    }
    await ref.add(payload);
  }

  Stream<List<InboxItem>> watchInbox([String? uid]) async* {
    final targetUid =
        (uid ?? '').trim().isEmpty ? await _requireUid() : uid!.trim();
    yield* _inboxRef(targetUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => InboxItem.fromFirestore(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Stream<int> watchUnreadCount({String? uid}) async* {
    final targetUid =
        (uid ?? '').trim().isEmpty ? await _requireUid() : uid!.trim();
    yield* _inboxRef(targetUid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) {
      var count = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final type = (data['type'] as String?)?.trim().toLowerCase() ?? '';
        if (type == 'live_duel_invite') continue;
        count++;
      }
      return count;
    });
  }

  Future<void> markAsRead({
    required String uid,
    required String messageId,
  }) async {
    final targetUid = uid.trim().isEmpty ? await _requireUid() : uid.trim();
    final id = messageId.trim();
    if (id.isEmpty) return;
    await _inboxRef(targetUid).doc(id).set(
      <String, dynamic>{
        'read': true,
        'status': 'read',
      },
      SetOptions(merge: true),
    );
  }

  Future<void> markCurrentAsRead(String messageId) async {
    final uid = await _requireUid();
    await markAsRead(uid: uid, messageId: messageId);
  }

  Future<void> deleteInboxItem({
    required String uid,
    required String messageId,
  }) async {
    final targetUid = uid.trim().isEmpty ? await _requireUid() : uid.trim();
    final id = messageId.trim();
    if (id.isEmpty) return;
    await _inboxRef(targetUid).doc(id).delete();
  }

  Future<void> deleteCurrentInboxItem(String messageId) async {
    final uid = await _requireUid();
    await deleteInboxItem(uid: uid, messageId: messageId);
  }

  CollectionReference<Map<String, dynamic>> _inboxRef(String uid) {
    return _db().collection('users').doc(uid).collection('inbox');
  }

  String _normalizeType(String type) {
    final value = type.trim().toLowerCase();
    switch (value) {
      case 'friend_request':
      case 'friend_accept':
      case 'friend_challenge':
      case 'level_challenge':
      case 'live_duel_invite':
      case 'system_news':
        return value;
      default:
        return 'system_news';
    }
  }

  String _normalizeStatus(String status) {
    final value = status.trim().toLowerCase();
    switch (value) {
      case 'pending':
      case 'accepted':
      case 'declined':
      case 'active':
      case 'read':
        return value;
      default:
        return 'active';
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
