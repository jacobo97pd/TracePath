import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      return 'Firebase no configurado en este dispositivo. Añade GoogleService-Info.plist (iOS) y google-services.json (Android).';
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
