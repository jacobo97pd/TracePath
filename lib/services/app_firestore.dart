import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AppFirestore {
  AppFirestore._();

  static const String preferredDatabaseId = 'tracepath-database';

  static FirebaseFirestore instance() {
    try {
      return FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: preferredDatabaseId,
      );
    } catch (_) {
      return FirebaseFirestore.instance;
    }
  }

  static String activeDatabaseId() {
    try {
      return instance().databaseId;
    } catch (_) {
      return '(unknown)';
    }
  }

  static void debugLogUse(String source) {
    if (!kDebugMode) return;
    debugPrint(
      '[firestore] source=$source db=${activeDatabaseId()} preferred=$preferredDatabaseId',
    );
  }
}
