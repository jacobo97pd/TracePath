import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class UserAchievementState {
  const UserAchievementState({
    required this.unlocked,
    required this.unlockedAt,
    required this.unlockedDateText,
  });

  final bool unlocked;
  final DateTime? unlockedAt;
  final String? unlockedDateText;
}

class AchievementPersistenceService {
  static const String _firestoreDatabaseId = 'tracepath-database';

  Future<Map<String, UserAchievementState>> loadUserAchievements(String uid) async {
    final safeUid = uid.trim();
    if (safeUid.isEmpty) return const <String, UserAchievementState>{};
    final snap = await _usersRef().doc(safeUid).collection('achievements').get();
    final out = <String, UserAchievementState>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final unlocked = data['unlocked'] == true;
      if (!unlocked) continue;
      final state = _fromData(data);
      out[doc.id] = state;
    }
    return out;
  }

  Future<UserAchievementState?> unlockAchievement({
    required String uid,
    required String achievementId,
  }) async {
    final safeUid = uid.trim();
    final safeAchievementId = achievementId.trim();
    if (safeUid.isEmpty || safeAchievementId.isEmpty) return null;

    final ref = _usersRef()
        .doc(safeUid)
        .collection('achievements')
        .doc(safeAchievementId);
    final today = _todayText();

    await _db().runTransaction((tx) async {
      final snap = await tx.get(ref);
      final existing = snap.data() ?? const <String, dynamic>{};
      if (existing['unlocked'] == true) {
        return;
      }
      tx.set(
        ref,
        <String, dynamic>{
          'unlocked': true,
          'unlockedAt': FieldValue.serverTimestamp(),
          'unlockedDateText': today,
        },
        SetOptions(merge: true),
      );
    });

    final after = await ref.get();
    if (!after.exists) return null;
    return _fromData(after.data() ?? const <String, dynamic>{});
  }

  Future<bool> isAchievementUnlocked({
    required String uid,
    required String achievementId,
  }) async {
    final safeUid = uid.trim();
    final safeAchievementId = achievementId.trim();
    if (safeUid.isEmpty || safeAchievementId.isEmpty) return false;
    final snap = await _usersRef()
        .doc(safeUid)
        .collection('achievements')
        .doc(safeAchievementId)
        .get();
    if (!snap.exists) return false;
    return snap.data()?['unlocked'] == true;
  }

  UserAchievementState _fromData(Map<String, dynamic> data) {
    DateTime? unlockedAt;
    final ts = data['unlockedAt'];
    if (ts is Timestamp) {
      unlockedAt = ts.toDate();
    } else if (ts is DateTime) {
      unlockedAt = ts;
    }
    final dateText = (data['unlockedDateText'] as String?)?.trim();
    return UserAchievementState(
      unlocked: data['unlocked'] == true,
      unlockedAt: unlockedAt,
      unlockedDateText: dateText?.isEmpty == true ? null : dateText,
    );
  }

  String _todayText() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  CollectionReference<Map<String, dynamic>> _usersRef() =>
      _db().collection('users');

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
}

