import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_firestore.dart';

class PresenceService with WidgetsBindingObserver {
  StreamSubscription<User?>? _authSub;
  String _activeUid = '';
  bool _isForeground = true;
  bool? _lastOnlineSent;
  DateTime _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _activeUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    unawaited(_syncPresence(force: true));
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    await _authSub?.cancel();
    _authSub = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isForeground = true;
        unawaited(_syncPresence(force: true));
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isForeground = false;
        unawaited(_syncPresence(force: true));
        break;
    }
  }

  Future<void> markCurrentUserOffline({bool force = true}) async {
    _isForeground = false;
    await _syncPresence(force: force, explicitOnline: false);
  }

  void _onAuthChanged(User? user) {
    final nextUid = user?.uid.trim() ?? '';
    if (_activeUid != nextUid) {
      _activeUid = nextUid;
      _lastOnlineSent = null;
      _lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);
    }
    unawaited(_syncPresence(force: true));
  }

  Future<void> _syncPresence({
    bool force = false,
    bool? explicitOnline,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) return;
    final shouldBeOnline = explicitOnline ?? _isForeground;
    final now = DateTime.now();
    final elapsed = now.difference(_lastSentAt);
    if (!force &&
        _lastOnlineSent == shouldBeOnline &&
        elapsed < const Duration(seconds: 20)) {
      return;
    }
    try {
      await AppFirestore.instance().collection('users').doc(uid).set(
        <String, dynamic>{
          'isOnline': shouldBeOnline,
          'lastSeenAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      _lastOnlineSent = shouldBeOnline;
      _lastSentAt = now;
      if (kDebugMode) {
        debugPrint(
          '[presence] uid=$uid online=$shouldBeOnline db=${AppFirestore.activeDatabaseId()}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[presence] write failed uid=$uid online=$shouldBeOnline error=$e');
      }
    }
  }
}

