import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

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
    final user = _firebaseAuth.currentUser;
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
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        final credential = await _firebaseAuth.signInWithPopup(provider);
        final user = credential.user;
        if (user == null) return 'Google login failed';
        _mode = AuthMode.google;
        _displayName = user.displayName ?? user.email?.split('@').first ?? 'Player';
        _email = user.email;
        _avatarUrl = user.photoURL;
      } else {
        final account = await _googleSignIn.signIn();
        if (account == null) return 'Login canceled';
        final auth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        final result = await _firebaseAuth.signInWithCredential(credential);
        final user = result.user;
        _mode = AuthMode.google;
        _displayName = user?.displayName ?? account.displayName ?? account.email.split('@').first;
        _email = user?.email ?? account.email;
        _avatarUrl = user?.photoURL ?? account.photoUrl;
      }
      await _persist();
      notifyListeners();
      return null;
    } catch (e) {
      return 'Google login failed: $e';
    }
  }

  Future<void> signOut() async {
    if (_mode == AuthMode.google) {
      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
      }
      try {
        await _firebaseAuth.signOut();
      } catch (_) {}
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
