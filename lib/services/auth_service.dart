import 'package:firebase_auth/firebase_auth.dart';

class AppAuthService {
  AppAuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? get currentUid => _auth.currentUser?.uid;

  Future<User> ensureAuthenticated() async {
    final current = _auth.currentUser;
    if (current != null) return current;
    final cred = await _auth.signInAnonymously();
    final user = cred.user;
    if (user == null) {
      throw StateError('Anonymous auth did not return a user');
    }
    return user;
  }
}
