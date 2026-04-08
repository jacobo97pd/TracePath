import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/app_firestore.dart';

enum AuthMode { none, guest, google }

class AuthService extends ChangeNotifier {
  AuthService(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  FirebaseAuth? get _firebaseAuthOrNull {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static const _modeKey = 'auth_mode_v1';
  static const _nameKey = 'auth_name_v1';
  static const _emailKey = 'auth_email_v1';
  static const _avatarKey = 'auth_avatar_v1';

  AuthMode _mode = AuthMode.none;
  bool _ready = false;
  String? _displayName;
  String? _email;
  String? _avatarUrl;

  bool get isReady => _ready;
  AuthMode get mode => _mode;
  bool get isAuthenticated => _mode != AuthMode.none;
  bool get isGuest => _mode == AuthMode.guest;
  String get displayName =>
      _displayName ?? (_mode == AuthMode.guest ? 'Guest' : 'Player');
  String? get email => _email;
  String? get avatarUrl => _avatarUrl;

  Future<void> _load() async {
    final raw = _prefs.getString(_modeKey);
    _mode = switch (raw) {
      'guest' => AuthMode.guest,
      'google' => AuthMode.google,
      _ => AuthMode.none,
    };
    _displayName = _prefs.getString(_nameKey);
    _email = _prefs.getString(_emailKey);
    _avatarUrl = _prefs.getString(_avatarKey);
    final user = _firebaseAuthOrNull?.currentUser;
    if (user != null) {
      _mode = AuthMode.google;
      _displayName = user.displayName ?? _displayName ?? user.email?.split('@').first;
      _email = user.email ?? _email;
      _avatarUrl = user.photoURL ?? _avatarUrl;
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> continueAsGuest() async {
    _mode = AuthMode.guest;
    _displayName = 'Guest';
    _email = null;
    _avatarUrl = null;
    await _persist();
    notifyListeners();
  }

  Future<String?> signInWithGoogle() async {
    final firebaseAuth = _firebaseAuthOrNull;
    if (firebaseAuth == null) {
      return 'Firebase no configurado en este dispositivo. Anade GoogleService-Info.plist (iOS) y google-services.json (Android).';
    }
    try {
      debugPrint('TRACE google sign in start');
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        final credential = await firebaseAuth.signInWithPopup(provider);
        final user = credential.user;
        debugPrint('TRACE web popup user: ${user?.uid}');
        if (user == null) return 'Google login failed';
        _mode = AuthMode.google;
        _displayName = user.displayName ?? user.email?.split('@').first ?? 'Player';
        _email = user.email;
        _avatarUrl = user.photoURL;
      } else {
        final account = await _googleSignIn.signIn();
        debugPrint('TRACE googleUser: $account');
        if (account == null) {
          debugPrint('TRACE google sign in cancelled by user');
          return 'Login canceled';
        }
        final googleAuth = await account.authentication;
        debugPrint('TRACE accessToken: ${googleAuth.accessToken != null}');
        debugPrint('TRACE idToken: ${googleAuth.idToken != null}');
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final result = await firebaseAuth.signInWithCredential(credential);
        final user = result.user;
        debugPrint('TRACE firebase sign in OK: ${user?.uid}');
        _mode = AuthMode.google;
        _displayName = user?.displayName ?? account.displayName ?? account.email.split('@').first;
        _email = user?.email ?? account.email;
        _avatarUrl = user?.photoURL ?? account.photoUrl;
      }
      await _persist();
      notifyListeners();
      return null;
    } catch (e, st) {
      debugPrint('TRACE google sign in ERROR: $e');
      debugPrint('TRACE google sign in STACK: $st');
      return 'Google login failed: $e';
    }
  }

  Future<void> signOut() async {
    final firebaseAuth = _firebaseAuthOrNull;
    final uid = firebaseAuth?.currentUser?.uid.trim() ?? '';
    if (uid.isNotEmpty) {
      try {
        await AppFirestore.instance().collection('users').doc(uid).set(
          <String, dynamic>{
            'isOnline': false,
            'lastSeenAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[presence] signOut offline write failed uid=$uid error=$e');
        }
      }
    }
    if (_mode == AuthMode.google) {
      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
      }
      if (firebaseAuth != null) {
        try {
          await firebaseAuth.signOut();
        } catch (_) {}
      }
    }
    _mode = AuthMode.none;
    _displayName = null;
    _email = null;
    _avatarUrl = null;
    await _persist();
    notifyListeners();
  }

  Future<String?> deleteCurrentAccount() async {
    final firebaseAuth = _firebaseAuthOrNull;
    if (firebaseAuth == null) {
      return 'Firebase no configurado en este dispositivo.';
    }

    if (_mode == AuthMode.guest) {
      await signOut();
      return null;
    }

    final user = firebaseAuth.currentUser;
    if (user == null) {
      await signOut();
      return null;
    }

    final uid = user.uid.trim();
    if (uid.isEmpty) {
      await signOut();
      return null;
    }

    try {
      await _reauthenticateForDeleteIfNeeded(user);

      final db = AppFirestore.instance();
      final userRef = db.collection('users').doc(uid);
      final userSnap = await userRef.get();
      final userData = userSnap.data() ?? const <String, dynamic>{};

      await _deleteOwnedUserData(userRef);
      await _deleteUserLookupIndexes(db, userData, authUser: user);

      await user.delete();
      try {
        await firebaseAuth.signOut();
      } catch (_) {}

      _mode = AuthMode.none;
      _displayName = null;
      _email = null;
      _avatarUrl = null;
      await _persist();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e, st) {
      debugPrint('TRACE delete account FirebaseAuthException: ${e.code} ${e.message}');
      debugPrint('TRACE delete account stack: $st');
      if (e.code == 'requires-recent-login') {
        return 'Por seguridad, vuelve a iniciar sesion y reintenta eliminar la cuenta.';
      }
      if (e.code == 'network-request-failed') {
        return 'No hay conexion. Revisa tu red e intentalo de nuevo.';
      }
      if (e.code == 'user-mismatch' || e.code == 'invalid-credential') {
        return 'No se pudo verificar tu sesion para eliminar la cuenta.';
      }
      return 'No se pudo eliminar la cuenta: ${e.message ?? e.code}';
    } on FirebaseException catch (e, st) {
      debugPrint('TRACE delete account FirebaseException: ${e.code} ${e.message}');
      debugPrint('TRACE delete account stack: $st');
      if (e.code == 'permission-denied') {
        return 'Firestore rechazo el borrado de datos. Revisa las reglas.';
      }
      return 'No se pudo eliminar la cuenta: ${e.message ?? e.code}';
    } catch (e, st) {
      debugPrint('TRACE delete account ERROR: $e');
      debugPrint('TRACE delete account stack: $st');
      return 'No se pudo eliminar la cuenta: $e';
    }
  }

  Future<void> _reauthenticateForDeleteIfNeeded(User user) async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters(<String, String>{'prompt': 'select_account'});
      await user.reauthenticateWithPopup(provider);
      return;
    }

    final providers = user.providerData.map((p) => p.providerId).toSet();
    if (!providers.contains('google.com')) {
      return;
    }

    GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signInSilently();
    } catch (_) {
      account = null;
    }
    account ??= await _googleSignIn.signIn();
    if (account == null) {
      throw FirebaseAuthException(
        code: 'user-cancelled',
        message: 'Cancelado por el usuario',
      );
    }
    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await user.reauthenticateWithCredential(credential);
  }

  Future<void> _deleteOwnedUserData(
    DocumentReference<Map<String, dynamic>> userRef,
  ) async {
    const subcollections = <String>[
      'friends',
      'incoming_requests',
      'sent_requests',
      'inbox',
      'owned_skins',
      'owned_trails',
      'wallet_transactions',
      'purchases',
      'completed_levels',
      'level_rewards',
      'achievements',
      'reported_levels',
      'daily_rewards',
      'progress',
    ];

    for (final path in subcollections) {
      await _deleteCollection(userRef.collection(path));
    }

    await userRef.delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snap = await collection.limit(200).get();
      if (snap.docs.isEmpty) return;
      final batch = AppFirestore.instance().batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteUserLookupIndexes(
    FirebaseFirestore db,
    Map<String, dynamic> userData, {
    required User authUser,
  }) async {
    final username = (userData['username'] as String?)?.trim().toLowerCase();
    if (username != null && username.isNotEmpty) {
      await db.collection('usernames').doc(username).delete();
    }

    final emailCandidates = <String>{
      (userData['email'] as String?)?.trim().toLowerCase() ?? '',
      (authUser.email ?? '').trim().toLowerCase(),
    }..removeWhere((e) => e.isEmpty);
    for (final email in emailCandidates) {
      await db.collection('emails').doc(email).delete();
    }
  }

  Future<void> _persist() async {
    final modeText = switch (_mode) {
      AuthMode.none => 'none',
      AuthMode.guest => 'guest',
      AuthMode.google => 'google',
    };
    await _prefs.setString(_modeKey, modeText);
    if (_displayName == null) {
      await _prefs.remove(_nameKey);
    } else {
      await _prefs.setString(_nameKey, _displayName!);
    }
    if (_email == null) {
      await _prefs.remove(_emailKey);
    } else {
      await _prefs.setString(_emailKey, _email!);
    }
    if (_avatarUrl == null) {
      await _prefs.remove(_avatarKey);
    } else {
      await _prefs.setString(_avatarKey, _avatarUrl!);
    }
  }
}
