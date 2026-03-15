import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'batch_models.dart';

class BatchSessionStore {
  const BatchSessionStore();

  static const String _key = 'curate_batch_session_v1';

  Future<List<CurationBatchItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const <CurationBatchItem>[];
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final snapshot = BatchSessionSnapshot.fromJson(decoded);
      return snapshot.items;
    } catch (_) {
      return const <CurationBatchItem>[];
    }
  }

  Future<void> save(List<CurationBatchItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final snapshot = BatchSessionSnapshot(items: items);
    // Keep storage light on web; only curated data is persisted, not raw images.
    await prefs.setString(
        _key, snapshot.toJsonString(includeImageBytes: false));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
