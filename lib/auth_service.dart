import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/app_firestore.dart';

enum AuthMode { none, guest, google, apple }

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
      'apple' => AuthMode.apple,
      _ => AuthMode.none,
    };
    _displayName = _prefs.getString(_nameKey);
    _email = _prefs.getString(_emailKey);
    _avatarUrl = _prefs.getString(_avatarKey);
    final user = _firebaseAuthOrNull?.currentUser;
    if (user != null) {
      final providers = user.providerData.map((p) => p.providerId).toSet();
      _mode = providers.contains('apple.com') ? AuthMode.apple : AuthMode.google;
      _displayName =
          user.displayName ?? _displayName ?? user.email?.split('@').first;
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
        _displayName =
            user?.displayName ?? account.displayName ?? account.email.split('@').first;
        _email = user?.email ?? account.email;
        _avatarUrl = user?.photoURL ?? account.photoUrl;
      }

      final user = firebaseAuth.currentUser;
      if (user != null) {
        await _upsertUserFromAuth(user, provider: 'google');
      }

      _mode = AuthMode.google;
      await _persist();
      notifyListeners();
      return null;
    } catch (e, st) {
      debugPrint('TRACE google sign in ERROR: $e');
      debugPrint('TRACE google sign in STACK: $st');
      return 'Google login failed: $e';
    }
  }

  Future<String?> signInWithApple() async {
    final firebaseAuth = _firebaseAuthOrNull;
    if (firebaseAuth == null) {
      return 'Firebase no configurado en este dispositivo.';
    }
    if (kIsWeb) {
      return 'Apple login solo esta disponible en iOS.';
    }

    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        return 'Sign in with Apple no disponible en este dispositivo.';
      }

      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final result = await firebaseAuth.signInWithCredential(oauthCredential);
      final user = result.user;
      if (user == null) {
        return 'Apple login failed';
      }

      final firstName = appleCredential.givenName?.trim() ?? '';
      final lastName = appleCredential.familyName?.trim() ?? '';
      final fullName = ('$firstName $lastName').trim();
      if (fullName.isNotEmpty && (user.displayName ?? '').trim().isEmpty) {
        await user.updateDisplayName(fullName);
      }

      _mode = AuthMode.apple;
      _displayName = (user.displayName ?? '').trim().isNotEmpty
          ? user.displayName
          : (fullName.isNotEmpty ? fullName : (user.email?.split('@').first ?? 'Player'));
      _email = user.email;
      _avatarUrl = user.photoURL;

      await _upsertUserFromAuth(user, provider: 'apple');
      await _persist();
      notifyListeners();
      return null;
    } on SignInWithAppleAuthorizationException catch (e, st) {
      debugPrint('TRACE apple sign in ERROR: ${e.code} ${e.message}');
      debugPrint('TRACE apple sign in STACK: $st');
      if (e.code == AuthorizationErrorCode.canceled) {
        return 'Login cancelado';
      }
      return 'Apple login failed: ${e.message}';
    } on FirebaseAuthException catch (e, st) {
      debugPrint('TRACE apple sign in FirebaseAuthException: ${e.code} ${e.message}');
      debugPrint('TRACE apple sign in STACK: $st');
      return 'Apple login failed: ${e.message ?? e.code}';
    } catch (e, st) {
      debugPrint('TRACE apple sign in ERROR: $e');
      debugPrint('TRACE apple sign in STACK: $st');
      return 'Apple login failed: $e';
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
    if (_mode == AuthMode.google || _mode == AuthMode.apple) {
      if (!kIsWeb && _mode == AuthMode.google) {
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
      if (e.code == 'user-cancelled') {
        return 'Operacion cancelada';
      }
      return 'No se pudo eliminar la cuenta: ${e.message ?? e.code}';
    } on FirebaseException catch (e, st) {
      debugPrint('TRACE delete account FirebaseException: ${e.code} ${e.message}');
      debugPrint('TRACE delete account stack: $st');
      if (_isFirestoreInternalAssertion(e)) {
        return 'Error interno temporal de Firestore Web. Recarga la app y vuelve a intentarlo.';
      }
      if (e.code == 'permission-denied') {
        return 'Firestore rechazo el borrado de datos. Revisa las reglas.';
      }
      return 'No se pudo eliminar la cuenta: ${e.message ?? e.code}';
    } catch (e, st) {
      debugPrint('TRACE delete account ERROR: $e');
      debugPrint('TRACE delete account stack: $st');
      if (_isFirestoreInternalAssertion(e)) {
        return 'Error interno temporal de Firestore Web. Recarga la app y vuelve a intentarlo.';
      }
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

    if (providers.contains('apple.com')) {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      await user.reauthenticateWithCredential(oauthCredential);
      return;
    }

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
      try {
        await _deleteCollection(userRef.collection(path));
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[delete-account] subcollection cleanup failed path=$path error=$e');
          debugPrint('$st');
        }
        // Best-effort cleanup: do not block account deletion for secondary data.
      }
    }

    try {
      await userRef.delete();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[delete-account] root user doc delete failed error=$e');
        debugPrint('$st');
      }
      if (!_isFirestoreInternalAssertion(e)) {
        rethrow;
      }
    }
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
      try {
        await db.collection('usernames').doc(username).delete();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[delete-account] username index delete failed key=$username error=$e');
          debugPrint('$st');
        }
      }
    }

    final emailCandidates = <String>{
      (userData['email'] as String?)?.trim().toLowerCase() ?? '',
      (authUser.email ?? '').trim().toLowerCase(),
    }..removeWhere((e) => e.isEmpty);
    for (final email in emailCandidates) {
      try {
        await db.collection('emails').doc(email).delete();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[delete-account] email index delete failed key=$email error=$e');
          debugPrint('$st');
        }
      }
    }
  }

  Future<void> _persist() async {
    final modeText = switch (_mode) {
      AuthMode.none => 'none',
      AuthMode.guest => 'guest',
      AuthMode.google => 'google',
      AuthMode.apple => 'apple',
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

  Future<void> _upsertUserFromAuth(User user, {required String provider}) async {
    final uid = user.uid.trim();
    if (uid.isEmpty) return;

    final db = AppFirestore.instance();
    final userRef = db.collection('users').doc(uid);
    final snap = await userRef.get();

    final display = (user.displayName ?? '').trim();
    final email = (user.email ?? '').trim();

    final payload = <String, dynamic>{
      'uid': uid,
      'playerName': display.isNotEmpty
          ? display
          : (email.isNotEmpty ? email.split('@').first : 'Player'),
      'email': email,
      'photoUrl': user.photoURL,
      'authProvider': provider,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isOnline': true,
      'lastSeenAt': FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['coins'] = 0;
      payload['lifetimeCoinsEarned'] = 0;
      payload['username'] = '';
      payload['usernameLowercase'] = '';
      payload['usernameChangeCount'] = 0;
    }

    await userRef.set(payload, SetOptions(merge: true));
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List<String>.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  bool _isFirestoreInternalAssertion(Object error) {
    final raw = error.toString().toUpperCase();
    return raw.contains('FIRESTORE') &&
        raw.contains('INTERNAL ASSERTION FAILED');
  }
}
