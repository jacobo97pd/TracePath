import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/friend_profile.dart';
import 'friend_challenge_service.dart';
import 'user_profile_service.dart';

class FriendsService {
  FriendsService({UserProfileService? profileService})
      : _profileService = profileService ?? UserProfileService();

  static const String _firestoreDatabaseId = 'tracepath-database';
  final UserProfileService _profileService;

  Future<void> addFriend(String friendUid) => addFriendByUid(friendUid);

  Future<void> addFriendByUid(String friendUid) async {
    final currentUid = await _requireUid();
    final targetUid = friendUid.trim();
    if (targetUid.isEmpty || targetUid == currentUid) {
      throw StateError('INVALID_FRIEND_UID');
    }
    final targetData = await _readUserData(targetUid);
    if (targetData == null) {
      throw StateError('FRIEND_NOT_FOUND');
    }
    await _friendsRef(currentUid).doc(targetUid).set(
          _friendDocData(uid: targetUid, data: targetData),
          SetOptions(merge: true),
        );
  }

  Future<void> sendFriendRequest(String friendUid) =>
      sendFriendRequestByUid(friendUid);

  Future<String> sendLevelChallenge({
    required String toUid,
    required String levelId,
  }) async {
    final fromUid = await _requireUid();
    await FriendChallengeService().createRandomFriendChallenge(
      challengerUid: fromUid,
      challengedUid: toUid,
      currentLevelId: levelId,
      sourceScreen: 'friends_service',
    );
    return '';
  }

  Future<void> sendFriendRequestByUsername(String username) async {
    final raw = username;
    final input = username.trim();
    final normalized = input.toLowerCase();
    if (kDebugMode) {
      debugPrint(
        '[friends] sendFriendRequestByUsername raw="$raw" normalized="$normalized"',
      );
    }
    if (normalized.isEmpty) {
      throw StateError('FRIEND_USERNAME_NOT_FOUND');
    }
    final friendUid = await _resolveUidByUsername(normalized);
    if (friendUid == null || friendUid.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint(
            '[friends] reason=FRIEND_USERNAME_NOT_FOUND username="$normalized"');
      }
      throw StateError('FRIEND_USERNAME_NOT_FOUND');
    }
    if (kDebugMode) {
      debugPrint(
        '[friends] resolved username="$normalized" -> targetUid=$friendUid',
      );
    }
    await sendFriendRequestByUid(friendUid);
  }

  Future<void> sendFriendRequestByEmail(String email) async {
    final raw = email;
    final normalized = email.trim().toLowerCase();
    if (kDebugMode) {
      debugPrint(
        '[friends] sendFriendRequestByEmail raw="$raw" normalized="$normalized"',
      );
    }
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw StateError('FRIEND_EMAIL_INVALID');
    }
    final friendUid = await _resolveUidByEmail(normalized);
    if (friendUid == null || friendUid.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint(
            '[friends] reason=FRIEND_EMAIL_NOT_FOUND email="$normalized"');
      }
      throw StateError('FRIEND_EMAIL_NOT_FOUND');
    }
    if (kDebugMode) {
      debugPrint(
          '[friends] resolved email="$normalized" -> targetUid=$friendUid');
    }
    await sendFriendRequestByUid(friendUid);
  }

  Future<void> sendFriendRequestByUid(String friendUid) async {
    final currentUid = await _requireUid();
    final targetUid = friendUid.trim();
    final staleCutoff = DateTime.now().subtract(const Duration(days: 2));
    if (kDebugMode) {
      debugPrint(
          '[friends] sendFriendRequestByUid currentUid=$currentUid targetUid=$targetUid');
    }
    if (targetUid.isEmpty) {
      if (kDebugMode) {
        debugPrint('[friends] reason=INVALID_FRIEND_UID (empty target uid)');
      }
      throw StateError('INVALID_FRIEND_UID');
    }
    if (kDebugMode) {
      debugPrint('[friends] selfAdd=${targetUid == currentUid}');
    }
    if (targetUid == currentUid) {
      if (kDebugMode) {
        debugPrint('[friends] reason=SELF_ADD');
      }
      throw StateError('SELF_ADD');
    }

    final currentUserData = await _readUserData(currentUid);
    final targetUserData = await _readUserData(targetUid);
    if (currentUserData == null || targetUserData == null) {
      throw StateError('FRIEND_NOT_FOUND');
    }

    final currentUsername = _readString(currentUserData['username']);
    final currentPlayerName =
        _readString(currentUserData['playerName'], fallback: 'Player');
    final currentAvatarId =
        _readString(currentUserData['avatarId'], fallback: 'default');
    final targetUsername = _readString(targetUserData['username']);
    final targetPlayerName =
        _readString(targetUserData['playerName'], fallback: 'Player');
    final targetAvatarId =
        _readString(targetUserData['avatarId'], fallback: 'default');

    if (kDebugMode) {
      debugPrint(
          '[friends] send request currentUid=$currentUid targetUid=$targetUid');
      debugPrint(
        '[friends] current profile username=$currentUsername playerName=$currentPlayerName avatarId=$currentAvatarId',
      );
      debugPrint(
        '[friends] target profile username=$targetUsername playerName=$targetPlayerName avatarId=$targetAvatarId',
      );
      debugPrint(
        '[friends] write paths incoming=users/$targetUid/incoming_requests/$currentUid '
        'sent=users/$currentUid/sent_requests/$targetUid '
        'inbox=users/$targetUid/inbox/$currentUid',
      );
    }

    final currentFriendRef = _friendsRef(currentUid).doc(targetUid);
    final currentSentRef = _sentRequestsRef(currentUid).doc(targetUid);
    final targetIncomingRef = _incomingRequestsRef(targetUid).doc(currentUid);
    final targetInboxRef = _inboxRef(targetUid).doc(currentUid);
    final incomingPayload = <String, dynamic>{
      'fromUid': currentUid,
      'fromUsername': currentUsername,
      'fromPlayerName': currentPlayerName,
      'fromAvatarId': currentAvatarId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };
    final sentPayload = <String, dynamic>{
      'toUid': targetUid,
      'toUsername': targetUsername,
      'toPlayerName': targetPlayerName,
      'toAvatarId': targetAvatarId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };
    final inboxPayload = <String, dynamic>{
      'type': 'friend_request',
      'fromUid': currentUid,
      'fromUsername': currentUsername,
      'fromPlayerName': currentPlayerName,
      'fromAvatarId': currentAvatarId,
      'title': 'Friend request',
      'body':
          '${currentUsername.isNotEmpty ? currentUsername : currentPlayerName} sent you a friend request.',
      'status': 'pending',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await _db().runTransaction((tx) async {
        if (kDebugMode) {
          debugPrint(
              '[friends] read path: users/$currentUid/friends/$targetUid');
        }
        final currentFriendSnap = await tx.get(currentFriendRef);
        if (kDebugMode) {
          debugPrint('[friends] alreadyFriends=${currentFriendSnap.exists}');
        }
        if (currentFriendSnap.exists) {
          throw StateError('ALREADY_FRIENDS');
        }

        if (kDebugMode) {
          debugPrint(
              '[friends] read path: users/$currentUid/sent_requests/$targetUid');
        }
        final sentSnap = await tx.get(currentSentRef);
        if (sentSnap.exists) {
          final sentData = sentSnap.data() ?? <String, dynamic>{};
          final sentStatus =
              _readString(sentData['status'], fallback: 'pending')
                  .toLowerCase();
          final sentCreatedAt = sentData['createdAt'];
          final sentCreatedAtDate =
              sentCreatedAt is Timestamp ? sentCreatedAt.toDate() : null;
          final stalePending = !_isTerminalRequestStatus(sentStatus) &&
              (sentStatus.isEmpty ||
                  sentStatus == 'pending' ||
                  sentStatus == 'sent' ||
                  sentStatus == 'active') &&
              sentCreatedAtDate != null &&
              sentCreatedAtDate.isBefore(staleCutoff);
          if (_isTerminalRequestStatus(sentStatus) || stalePending) {
            if (kDebugMode) {
              debugPrint(
                '[friends] clearing stale/terminal sent request '
                'status=$sentStatus createdAt=$sentCreatedAtDate',
              );
            }
            tx.delete(currentSentRef);
          } else {
            if (kDebugMode) {
              debugPrint(
                '[friends] pendingSentRequest=true status=$sentStatus createdAt=$sentCreatedAtDate',
              );
            }
            throw StateError('REQUEST_ALREADY_SENT');
          }
        } else if (kDebugMode) {
          debugPrint('[friends] pendingSentRequest=false');
        }

        if (kDebugMode) {
          debugPrint(
            '[friends] read path: users/$currentUid/incoming_requests/$targetUid',
          );
        }
        final reverseIncomingSnap =
            await tx.get(_incomingRequestsRef(currentUid).doc(targetUid));
        if (reverseIncomingSnap.exists) {
          final reverseData = reverseIncomingSnap.data() ?? <String, dynamic>{};
          final reverseStatus =
              _readString(reverseData['status'], fallback: 'pending')
                  .toLowerCase();
          final reverseCreatedAt = reverseData['createdAt'];
          final reverseCreatedAtDate =
              reverseCreatedAt is Timestamp ? reverseCreatedAt.toDate() : null;
          final stalePending = !_isTerminalRequestStatus(reverseStatus) &&
              (reverseStatus.isEmpty ||
                  reverseStatus == 'pending' ||
                  reverseStatus == 'sent' ||
                  reverseStatus == 'active') &&
              reverseCreatedAtDate != null &&
              reverseCreatedAtDate.isBefore(staleCutoff);
          if (_isTerminalRequestStatus(reverseStatus) || stalePending) {
            if (kDebugMode) {
              debugPrint(
                '[friends] clearing stale/terminal reverse incoming request '
                'status=$reverseStatus createdAt=$reverseCreatedAtDate',
              );
            }
            tx.delete(_incomingRequestsRef(currentUid).doc(targetUid));
          } else {
            if (kDebugMode) {
              debugPrint(
                '[friends] reverseIncomingRequest=true status=$reverseStatus createdAt=$reverseCreatedAtDate',
              );
            }
            throw StateError('REQUEST_ALREADY_RECEIVED');
          }
        } else if (kDebugMode) {
          debugPrint('[friends] reverseIncomingRequest=false');
        }

        tx.set(targetIncomingRef, incomingPayload, SetOptions(merge: true));
        tx.set(currentSentRef, sentPayload, SetOptions(merge: true));
        tx.set(targetInboxRef, inboxPayload, SetOptions(merge: true));
      });
      if (kDebugMode) {
        debugPrint('[friends] reason=REQUEST_SENT_OK');
      }
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[friends] firestore error in sendFriendRequestByUid op=${e.plugin} code=${e.code} message=${e.message}',
        );
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[friends] send request failed currentUid=$currentUid targetUid=$targetUid error=$e',
        );
      }
      rethrow;
    }
  }

  Future<void> addFriendByUsername(String username) async {
    final friendUid = await _profileService.getUidByUsername(username.trim());
    if (friendUid == null || friendUid.trim().isEmpty) {
      throw StateError('FRIEND_USERNAME_NOT_FOUND');
    }
    await addFriendByUid(friendUid);
  }

  Future<void> acceptFriendRequest({
    required String fromUid,
    String? inboxMessageId,
  }) async {
    final currentUid = await _requireUid();
    final fromUidHint = fromUid.trim();
    final inboxIdHint = (inboxMessageId ?? '').trim();
    if (fromUidHint.isEmpty && inboxIdHint.isEmpty) {
      throw StateError('INVALID_FRIEND_UID');
    }
    if (fromUidHint == currentUid || inboxIdHint == currentUid) {
      throw StateError('INVALID_FRIEND_UID');
    }

    String senderUid = '';
    if (kDebugMode) {
      debugPrint(
        '[friends] acceptFriendRequest resolve currentUid=$currentUid fromUidHint=$fromUidHint inboxIdHint=$inboxIdHint',
      );
      debugPrint('[friends] read path: users/$currentUid/incoming_requests');
    }
    final incomingListSnap = await _incomingRequestsRef(currentUid).get();
    for (final doc in incomingListSnap.docs) {
      final docId = doc.id.trim();
      final data = doc.data();
      final fromField = _readString(data['fromUid']);
      if (docId == fromUidHint ||
          docId == inboxIdHint ||
          fromField == fromUidHint ||
          fromField == inboxIdHint) {
        senderUid = docId;
        break;
      }
    }
    if (senderUid.isEmpty && fromUidHint.isNotEmpty) {
      // Last safe fallback for compatibility: still treat hint as doc id.
      senderUid = fromUidHint;
    }
    if (senderUid.isEmpty) {
      throw StateError('REQUEST_NOT_FOUND');
    }
    if (kDebugMode) {
      debugPrint('[friends] accept using docId fromUid=$senderUid');
    }

    final currentData = await _readUserData(currentUid);
    final senderData = await _readUserData(senderUid);
    if (currentData == null || senderData == null) {
      throw StateError('FRIEND_NOT_FOUND');
    }

    final incomingRef = _incomingRequestsRef(currentUid).doc(senderUid);
    final senderSentRef = _sentRequestsRef(senderUid).doc(currentUid);
    final currentInboxRef = _inboxRef(currentUid).doc(
        (inboxMessageId ?? senderUid).trim().isEmpty
            ? senderUid
            : (inboxMessageId ?? senderUid).trim());
    final currentFriendRef = _friendsRef(currentUid).doc(senderUid);
    final senderFriendRef = _friendsRef(senderUid).doc(currentUid);
    final senderInboxRef =
        _inboxRef(senderUid).doc('friend_accept_$currentUid');
    final currentFriendPayload =
        _friendDocData(uid: senderUid, data: senderData);
    final senderFriendPayload =
        _friendDocData(uid: currentUid, data: currentData);
    final currentUsername = _readString(currentData['username']);
    final currentPlayerName =
        _readString(currentData['playerName'], fallback: 'Player');
    const acceptTitle = 'Friend request accepted';
    final acceptBody =
        '@${currentUsername.isNotEmpty ? currentUsername : currentPlayerName} accepted your request.';
    final senderInboxPayload = <String, dynamic>{
      'type': 'friend_accept',
      'fromUid': currentUid,
      'fromUsername': currentUsername,
      'fromPlayerName': currentPlayerName,
      'fromAvatarId': _readString(currentData['avatarId'], fallback: 'default'),
      'title': acceptTitle,
      'body': acceptBody,
      'status': 'accepted',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (kDebugMode) {
      debugPrint(
          '[friends] accept request currentUid=$currentUid fromUid=$senderUid');
      debugPrint('[friends] current profile data=$currentData');
      debugPrint('[friends] sender profile data=$senderData');
      debugPrint(
        '[friends] write paths currentFriend=users/$currentUid/friends/$senderUid '
        'senderFriend=users/$senderUid/friends/$currentUid '
        'deleteIncoming=users/$currentUid/incoming_requests/$senderUid '
        'deleteSent=users/$senderUid/sent_requests/$currentUid '
        'deleteInbox=users/$currentUid/inbox/${currentInboxRef.id}',
      );
      debugPrint('[friends] payload currentFriend=$currentFriendPayload');
      debugPrint('[friends] payload senderFriend=$senderFriendPayload');
    }

    try {
      if (kDebugMode) {
        debugPrint(
            '[friends] read path: users/$currentUid/incoming_requests/$senderUid');
      }
      final incomingSnap = await incomingRef.get();
      if (!incomingSnap.exists) {
        throw StateError('REQUEST_NOT_FOUND');
      }

      if (kDebugMode) {
        debugPrint(
          '[friends] write path: users/$currentUid/friends/$senderUid payload=$currentFriendPayload',
        );
        debugPrint(
          '[friends] write path: users/$senderUid/friends/$currentUid payload=$senderFriendPayload',
        );
      }

      final batch = _db().batch();
      batch.set(currentFriendRef, currentFriendPayload);
      batch.set(senderFriendRef, senderFriendPayload);
      batch.set(senderInboxRef, senderInboxPayload, SetOptions(merge: true));

      if (kDebugMode) {
        debugPrint(
            '[friends] delete path: users/$currentUid/incoming_requests/$senderUid');
        debugPrint(
            '[friends] delete path: users/$senderUid/sent_requests/$currentUid');
        debugPrint(
            '[friends] delete path: users/$currentUid/inbox/${currentInboxRef.id}');
        debugPrint(
          '[friends] write path: users/$senderUid/inbox/${senderInboxRef.id} payload=$senderInboxPayload',
        );
      }
      batch.delete(incomingRef);
      batch.delete(senderSentRef);
      batch.delete(currentInboxRef);
      await batch.commit();
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[friends] firestore error in acceptFriendRequest code=${e.code} message=${e.message}',
        );
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[friends] accept request failed currentUid=$currentUid fromUid=$senderUid error=$e');
      }
      rethrow;
    }
  }

  Future<void> declineFriendRequest({
    required String fromUid,
    String? inboxMessageId,
  }) async {
    final currentUid = await _requireUid();
    final senderUid = fromUid.trim();
    if (senderUid.isEmpty || senderUid == currentUid) {
      throw StateError('INVALID_FRIEND_UID');
    }
    final incomingRef = _incomingRequestsRef(currentUid).doc(senderUid);
    final senderSentRef = _sentRequestsRef(senderUid).doc(currentUid);
    final currentData = await _readUserData(currentUid) ?? <String, dynamic>{};
    final currentUsername = _readString(currentData['username']);
    final currentPlayerName =
        _readString(currentData['playerName'], fallback: 'Player');
    final currentAvatarId =
        _readString(currentData['avatarId'], fallback: 'default');
    final senderInboxRef =
        _inboxRef(senderUid).doc('friend_declined_$currentUid');
    final senderInboxPayload = <String, dynamic>{
      'type': 'system_news',
      'fromUid': currentUid,
      'fromUsername': currentUsername,
      'fromPlayerName': currentPlayerName,
      'fromAvatarId': currentAvatarId,
      'title': 'Friend request declined',
      'body':
          '@${currentUsername.isNotEmpty ? currentUsername : currentPlayerName} declined your friend request.',
      'status': 'declined',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'ctaType': 'open_social',
      'ctaPayload': '/social',
      'relatedType': 'friend_request',
    };
    final currentInboxRef = _inboxRef(currentUid).doc(
        (inboxMessageId ?? senderUid).trim().isEmpty
            ? senderUid
            : (inboxMessageId ?? senderUid).trim());
    if (kDebugMode) {
      debugPrint(
          '[friends] decline request currentUid=$currentUid fromUid=$senderUid');
      debugPrint(
        '[friends] delete paths incoming=users/$currentUid/incoming_requests/$senderUid '
        'sent=users/$senderUid/sent_requests/$currentUid '
        'inbox=users/$currentUid/inbox/${currentInboxRef.id}',
      );
    }
    try {
      final batch = _db().batch();
      batch.set(senderInboxRef, senderInboxPayload, SetOptions(merge: true));
      batch.delete(incomingRef);
      batch.delete(senderSentRef);
      batch.delete(currentInboxRef);
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[friends] decline request failed currentUid=$currentUid fromUid=$senderUid error=$e');
      }
      rethrow;
    }
  }

  Future<void> removeFriend(String friendUid) async {
    final uid = await _requireUid();
    await _friendsRef(uid).doc(friendUid.trim()).delete();
  }

  Future<List<FriendProfile>> getFriends() async {
    final uid = await _requireUid();
    final snap =
        await _friendsRef(uid).orderBy('addedAt', descending: true).get();
    return snap.docs
        .map((doc) => FriendProfile.fromFirestore(doc.id, doc.data()))
        .toList(growable: false);
  }

  Stream<List<FriendProfile>> watchFriends() async* {
    final uid = await _requireUid();
    yield* _friendsRef(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => FriendProfile.fromFirestore(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Map<String, dynamic> _friendDocData({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    final username = _readString(data['username']);
    final playerName = _readString(data['playerName'], fallback: 'Player');
    final photoUrl = _readString(data['photoUrl']);
    final avatarId = _readString(data['avatarId'], fallback: 'default');
    final equippedSkinId =
        _readString(data['equippedSkinId'], fallback: 'default');
    final equippedTrailId =
        _readString(data['equippedTrailId'], fallback: 'none');
    return <String, dynamic>{
      'uid': uid,
      'username': username,
      'playerName': playerName,
      'photoUrl': photoUrl,
      'avatarId': avatarId,
      'equippedSkinId': equippedSkinId,
      'equippedTrailId': equippedTrailId,
      'totalLevelsCompleted': _readInt(data['totalLevelsCompleted']),
      'addedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<Map<String, dynamic>?> _readUserData(String uid) async {
    if (kDebugMode) {
      debugPrint('[friends] read path: users/$uid');
    }
    final snap = await _userRef(uid).get();
    if (kDebugMode) {
      debugPrint(
        '[friends] users/$uid exists=${snap.exists} data=${snap.data()}',
      );
    }
    if (!snap.exists) return null;
    return snap.data() ?? <String, dynamic>{};
  }

  Future<String?> _resolveUidByUsername(String normalizedUsername) async {
    final key = normalizedUsername.trim().toLowerCase();
    if (kDebugMode) {
      debugPrint('[friends] read path: usernames/$key');
    }
    final indexSnap = await _db().collection('usernames').doc(key).get();
    if (kDebugMode) {
      debugPrint(
        '[friends] usernames/$key exists=${indexSnap.exists} data=${indexSnap.data()}',
      );
    }
    if (!indexSnap.exists) return null;
    final uid = _readString(indexSnap.data()?['uid']);
    if (uid.isEmpty) return null;
    return uid;
  }

  Future<String?> _resolveUidByEmail(String normalizedEmail) async {
    final key = normalizedEmail.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (kDebugMode) {
      debugPrint('[friends] read path: emails/$key');
    }
    final indexSnap = await _db().collection('emails').doc(key).get();
    if (indexSnap.exists) {
      final uid = _readString(indexSnap.data()?['uid']);
      if (uid.isNotEmpty) return uid;
    }

    if (kDebugMode) {
      debugPrint('[friends] fallback query users by emailLowercase/email');
    }
    final byLower = await _db()
        .collection('users')
        .where('emailLowercase', isEqualTo: key)
        .limit(1)
        .get();
    if (byLower.docs.isNotEmpty) {
      return byLower.docs.first.id.trim();
    }
    final byRaw = await _db()
        .collection('users')
        .where('email', isEqualTo: key)
        .limit(1)
        .get();
    if (byRaw.docs.isNotEmpty) {
      return byRaw.docs.first.id.trim();
    }
    return null;
  }

  String _readString(Object? value, {String fallback = ''}) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return fallback;
  }

  int _readInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  bool _isTerminalRequestStatus(String status) {
    switch (status.trim().toLowerCase()) {
      case 'declined':
      case 'rejected':
      case 'no_accept':
      case 'noaccept':
      case 'no accept':
      case 'not_accepted':
      case 'cancelled':
      case 'canceled':
      case 'expired':
      case 'failed':
      case 'closed':
      case 'accepted':
        return true;
      default:
        return false;
    }
  }

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _db().collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> _friendsRef(String uid) {
    return _userRef(uid).collection('friends');
  }

  CollectionReference<Map<String, dynamic>> _incomingRequestsRef(String uid) {
    return _userRef(uid).collection('incoming_requests');
  }

  CollectionReference<Map<String, dynamic>> _sentRequestsRef(String uid) {
    return _userRef(uid).collection('sent_requests');
  }

  CollectionReference<Map<String, dynamic>> _inboxRef(String uid) {
    return _userRef(uid).collection('inbox');
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
