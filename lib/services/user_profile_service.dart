import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class UserProfileSnapshot {
  const UserProfileSnapshot({
    required this.uid,
    required this.playerName,
    required this.username,
    required this.usernameLowercase,
    required this.avatarId,
    required this.equippedSkinId,
    required this.equippedTrailId,
  });

  final String uid;
  final String playerName;
  final String username;
  final String usernameLowercase;
  final String avatarId;
  final String equippedSkinId;
  final String equippedTrailId;
}

class UserProfileService {
  static const String _firestoreDatabaseId = 'tracepath-database';
  static const int _maxUsernameChanges = 3;
  static final RegExp _usernameRegExp = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  Future<void> ensureCurrentUserProfile() async {
    final uid = await _requireUid();
    final ref = _usersRef().doc(uid);
    DocumentSnapshot<Map<String, dynamic>> snap;
    try {
      snap = await ref.get(const GetOptions(source: Source.server));
    } catch (_) {
      snap = await ref.get();
    }
    final ts = FieldValue.serverTimestamp();
    if (!snap.exists) {
      final initial = UserModel.defaultFirestore(
        uid: uid,
        createdAt: ts,
        updatedAt: ts,
      );
      // Profile bootstrap must never initialize wallet fields.
      initial.remove('coins');
      initial.remove('lifetimeCoinsEarned');
      initial.remove('lifetimeCoinsPurchased');
      final authEmail =
          (FirebaseAuth.instance.currentUser?.email ?? '').trim().toLowerCase();
      if (authEmail.isNotEmpty) {
        initial['email'] = authEmail;
        initial['emailLowercase'] = authEmail;
      }
      await ref.set(
        initial,
        SetOptions(merge: true),
      );
      await _syncLookupIndexes(
        uid: uid,
        username: (initial['username'] as String?)?.trim() ?? '',
        emailLowercase: authEmail,
      );
      return;
    }
    final data = snap.data() ?? <String, dynamic>{};
    final missing = UserModel.missingFieldsForExisting(
      uid: uid,
      existing: data,
      updatedAt: ts,
    );
    final email = (FirebaseAuth.instance.currentUser?.email ?? '').trim();
    if (email.isNotEmpty &&
        ((data['email'] as String?)?.trim().isEmpty ?? true)) {
      missing['email'] = email;
    }
    final emailLower = email.toLowerCase();
    if (emailLower.isNotEmpty &&
        ((data['emailLowercase'] as String?)?.trim().isEmpty ?? true)) {
      missing['emailLowercase'] = emailLower;
    }
    if (missing.isNotEmpty) {
      await ref.set(missing, SetOptions(merge: true));
    }
    if (!data.containsKey('usernameChangeCount') ||
        data['usernameChangeCount'] == null) {
      await ref.set(
        <String, dynamic>{
          'usernameChangeCount': 0,
          'updatedAt': ts,
        },
        SetOptions(merge: true),
      );
    }
    final merged = <String, dynamic>{...data, ...missing};
    await _syncLookupIndexes(
      uid: uid,
      username: (merged['username'] as String?)?.trim() ?? '',
      emailLowercase: (merged['emailLowercase'] as String?)?.trim() ?? '',
    );
  }

  Future<bool> isUsernameAvailable(String username) async {
    final normalized = _normalizeUsername(username);
    if (normalized == null) return false;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid.trim().isEmpty) return false;
    final userSnap = await _usersRef().doc(currentUid).get();
    final userData = userSnap.data() ?? <String, dynamic>{};
    final currentLower =
        (userData['usernameLowercase'] as String?)?.trim().toLowerCase() ?? '';
    final changeCount = _readInt(userData['usernameChangeCount']);
    if (changeCount >= _maxUsernameChanges && currentLower != normalized) {
      return false;
    }
    final snap = await _db().collection('usernames').doc(normalized).get();
    if (!snap.exists) return true;
    final owner = (snap.data()?['uid'] as String?)?.trim();
    return owner != null && owner == currentUid;
  }

  Future<void> setUsername(String username) async {
    final uid = await _requireUid();
    final normalized = _normalizeUsername(username);
    if (normalized == null) {
      throw StateError('INVALID_USERNAME');
    }
    final usersRef = _usersRef().doc(uid);
    final usernameRef = _db().collection('usernames').doc(normalized);
    await _db().runTransaction((tx) async {
      final userSnap = await tx.get(usersRef);
      if (!userSnap.exists) {
        throw StateError('AUTH_REQUIRED');
      }
      final currentData = userSnap.data() ?? <String, dynamic>{};
      final currentLower =
          (currentData['usernameLowercase'] as String?)?.trim().toLowerCase() ??
              '';
      final currentName = (currentData['username'] as String?)?.trim() ?? '';
      final changeCount = _readInt(currentData['usernameChangeCount']);

      if (currentLower == normalized && currentName == username.trim()) {
        return;
      }
      if (changeCount >= _maxUsernameChanges) {
        throw StateError('USERNAME_CHANGE_LIMIT_REACHED');
      }

      final usernameSnap = await tx.get(usernameRef);
      if (usernameSnap.exists) {
        final owner = (usernameSnap.data()?['uid'] as String?)?.trim();
        if (owner != uid) {
          throw StateError('USERNAME_TAKEN');
        }
      }

      if (currentLower.isNotEmpty && currentLower != normalized) {
        final previousUsernameRef =
            _db().collection('usernames').doc(currentLower);
        final previousUsernameSnap = await tx.get(previousUsernameRef);
        if (previousUsernameSnap.exists) {
          final previousOwner =
              (previousUsernameSnap.data()?['uid'] as String?)?.trim() ?? '';
          if (previousOwner == uid) {
            tx.delete(previousUsernameRef);
          }
        }
      }

      tx.set(
        usernameRef,
        <String, dynamic>{
          'uid': uid,
          'username': username.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      tx.set(
        usersRef,
        <String, dynamic>{
          'username': username.trim(),
          'usernameLowercase': normalized,
          'usernameChangeCount': changeCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
    final authEmail =
        (FirebaseAuth.instance.currentUser?.email ?? '').trim().toLowerCase();
    await _syncLookupIndexes(
      uid: uid,
      username: username.trim(),
      emailLowercase: authEmail,
    );
  }

  Future<String?> getUidByUsername(String username) async {
    final raw = username;
    final normalized = _normalizeUsername(username);
    if (kDebugMode) {
      debugPrint(
          '[username-lookup] raw="$raw" normalized="${normalized ?? ''}"');
    }
    if (normalized == null) {
      if (kDebugMode) {
        debugPrint('[username-lookup] invalid username format');
      }
      return null;
    }

    final indexPath = 'usernames/$normalized';
    try {
      if (kDebugMode) {
        debugPrint('[username-lookup] checking index doc: $indexPath');
      }
      final snap = await _db().collection('usernames').doc(normalized).get();
      if (kDebugMode) {
        debugPrint(
          '[username-lookup] index exists=${snap.exists} data=${snap.data()}',
        );
      }
      if (snap.exists) {
        final uid = (snap.data()?['uid'] as String?)?.trim();
        if (kDebugMode) {
          debugPrint(
              '[username-lookup] resolved uid from index="${uid ?? ''}"');
        }
        if (uid != null && uid.isNotEmpty) {
          final userSnap = await _usersRef().doc(uid).get();
          if (kDebugMode) {
            debugPrint(
              '[username-lookup] users/$uid exists=${userSnap.exists} data=${userSnap.data()}',
            );
          }
          return userSnap.exists ? uid : null;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[username-lookup] index lookup error: $e');
      }
      rethrow;
    }

    try {
      if (kDebugMode) {
        debugPrint(
          '[username-lookup] index miss, fallback query users where usernameLowercase == $normalized',
        );
      }
      final query = await _usersRef()
          .where('usernameLowercase', isEqualTo: normalized)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint('[username-lookup] fallback query empty');
        }
        return null;
      }
      final doc = query.docs.first;
      final uid = doc.id.trim();
      if (kDebugMode) {
        debugPrint(
          '[username-lookup] fallback resolved uid="$uid" data=${doc.data()}',
        );
      }
      if (uid.isEmpty) return null;

      // Heal the username index opportunistically for future fast lookups.
      try {
        await _db().collection('usernames').doc(normalized).set(
          <String, dynamic>{
            'uid': uid,
            'username':
                (doc.data()['username'] as String?)?.trim().isNotEmpty == true
                    ? (doc.data()['username'] as String).trim()
                    : username.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        if (kDebugMode) {
          debugPrint(
              '[username-lookup] healed index doc usernames/$normalized');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[username-lookup] index heal failed: $e');
        }
      }
      return uid;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[username-lookup] fallback query error: $e');
      }
      rethrow;
    }
  }

  Future<UserProfileSnapshot?> getPublicProfile(String uid) async {
    final snap = await _usersRef().doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data() ?? <String, dynamic>{};
    return UserProfileSnapshot(
      uid: uid,
      playerName: (data['playerName'] as String?)?.trim().isNotEmpty == true
          ? (data['playerName'] as String).trim()
          : 'Player',
      username: (data['username'] as String?)?.trim() ?? '',
      usernameLowercase: (data['usernameLowercase'] as String?)?.trim() ?? '',
      avatarId: (data['avatarId'] as String?)?.trim().isNotEmpty == true
          ? (data['avatarId'] as String).trim()
          : 'default',
      equippedSkinId:
          (data['equippedSkinId'] as String?)?.trim().isNotEmpty == true
              ? (data['equippedSkinId'] as String).trim()
              : 'default',
      equippedTrailId:
          (data['equippedTrailId'] as String?)?.trim().isNotEmpty == true
              ? (data['equippedTrailId'] as String).trim()
              : 'none',
    );
  }

  Future<void> updatePublicProfile({
    String? playerName,
    String? avatarId,
  }) async {
    final uid = await _requireUid();
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (playerName != null && playerName.trim().isNotEmpty) {
      payload['playerName'] = playerName.trim();
    }
    if (avatarId != null && avatarId.trim().isNotEmpty) {
      payload['avatarId'] = avatarId.trim();
    }
    await _usersRef().doc(uid).set(payload, SetOptions(merge: true));
  }

  String? _normalizeUsername(String raw) {
    final value = raw.trim().replaceAll('@', '');
    if (!_usernameRegExp.hasMatch(value)) return null;
    return value.toLowerCase();
  }

  int _readInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  CollectionReference<Map<String, dynamic>> _usersRef() =>
      _db().collection('users');

  Future<void> _syncLookupIndexes({
    required String uid,
    required String username,
    required String emailLowercase,
  }) async {
    final normalizedUsername = _normalizeUsername(username) ?? '';
    if (normalizedUsername.isNotEmpty) {
      await _db().collection('usernames').doc(normalizedUsername).set(
        <String, dynamic>{
          'uid': uid,
          'username': username.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    if (emailLowercase.trim().isNotEmpty &&
        emailLowercase.trim().contains('@')) {
      await _db().collection('emails').doc(emailLowercase.trim()).set(
        <String, dynamic>{
          'uid': uid,
          'email': emailLowercase.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
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
