import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/leaderboard_entry.dart';
import '../ui/avatar_utils.dart';
import '../ui/components/friends_ranking_list.dart';
import 'leaderboard_service.dart';

class FriendsRankingService {
  static const String _firestoreDatabaseId = 'tracepath-database';

  final SocialLeaderboardService _socialLeaderboardService =
      SocialLeaderboardService();
  final Map<String, String?> _skinPreviewUrlCache = <String, String?>{};

  Future<List<FriendsRankingRow>> loadForLevel(String levelId) async {
    final normalized = levelId.trim();
    if (normalized.isEmpty) return const <FriendsRankingRow>[];
    try {
      final entries = await _socialLeaderboardService.getFriendsTopScores(
        normalized,
      );
      return _mapEntries(entries);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[friends-ranking] load failed for $normalized: $e');
      }
      try {
        final me = await _socialLeaderboardService.getCurrentUserScore(normalized);
        if (me == null) return const <FriendsRankingRow>[];
        return _mapEntries(<LeaderboardEntry>[me]);
      } catch (_) {
        return const <FriendsRankingRow>[];
      }
    }
  }

  Future<List<FriendsRankingRow>> _mapEntries(
    List<LeaderboardEntry> entries,
  ) async {
    final out = <FriendsRankingRow>[];
    for (final entry in entries) {
      final skinUrl = await _resolveSkinPreviewUrl(entry.equippedSkinId);
      out.add(
        FriendsRankingRow(
          uid: entry.uid,
          displayName: _displayName(entry),
          bestTimeMs: entry.bestTimeMs,
          photoUrl: _resolveEntryPhotoUrl(entry),
          skinPreviewUrl: skinUrl ?? '',
          preferSkin: !isDefaultSkinId(entry.equippedSkinId),
        ),
      );
    }
    out.sort((a, b) {
      final byTime = a.bestTimeMs.compareTo(b.bestTimeMs);
      if (byTime != 0) return byTime;
      return a.uid.compareTo(b.uid);
    });
    return out;
  }

  Future<String?> _resolveSkinPreviewUrl(String skinId) async {
    final id = skinId.trim();
    if (id.isEmpty || id == 'default' || id == 'pointer_default') return null;
    if (_skinPreviewUrlCache.containsKey(id)) return _skinPreviewUrlCache[id];
    try {
      var snap = await _db().collection('skins_catalog').doc(id).get();
      Map<String, dynamic> data = snap.data() ?? <String, dynamic>{};
      if (!snap.exists || data.isEmpty) {
        final q = await _db()
            .collection('skins_catalog')
            .where('id', isEqualTo: id)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          data = q.docs.first.data();
        }
      }
      final imageRaw = data['image'];
      Map<String, dynamic>? imageMap;
      if (imageRaw is Map<String, dynamic>) {
        imageMap = imageRaw;
      } else if (imageRaw is Map) {
        imageMap = Map<String, dynamic>.from(imageRaw);
      }
      final rawPath = _readString(imageMap?['previewPath']) ??
          _readString(data['thumbPath']) ??
          _readString(data['thumbnailPath']) ??
          _readString(imageMap?['iconPath']) ??
          _readString(imageMap?['fullPath']) ??
          _readString(data['imagePath']);
      final resolved = await _resolveToDownloadUrl(rawPath);
      _skinPreviewUrlCache[id] = resolved;
      return resolved;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[friends-ranking] failed skin preview for $id: $e');
      }
      _skinPreviewUrlCache[id] = null;
      return null;
    }
  }

  String _resolveEntryPhotoUrl(LeaderboardEntry entry) {
    final current = _normalizeAvatarPath(entry.photoUrl);
    if (current.isNotEmpty) return current;
    if (entry.uid == FirebaseAuth.instance.currentUser?.uid) {
      final authUser = FirebaseAuth.instance.currentUser;
      final candidates = <String>[
        (authUser?.photoURL ?? '').trim(),
        if (authUser != null)
          ...authUser.providerData
              .map((p) => (p.photoURL ?? '').trim())
              .where((v) => v.isNotEmpty),
      ];
      for (final c in candidates) {
        final normalized = _normalizeAvatarPath(c);
        if (normalized.isNotEmpty) return normalized;
      }
    }
    return '';
  }

  String _displayName(LeaderboardEntry entry) {
    final username = entry.username.trim();
    if (username.isNotEmpty) return username;
    final playerName = entry.playerName.trim();
    if (playerName.isNotEmpty) return playerName;
    return 'Player';
  }

  String _normalizeAvatarPath(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:image') ||
        value.startsWith('assets/')) {
      return value;
    }
    if (value.startsWith('gs://')) {
      final withoutPrefix = value.replaceFirst('gs://', '');
      final slash = withoutPrefix.indexOf('/');
      if (slash <= 0 || slash >= withoutPrefix.length - 1) return '';
      final bucket = withoutPrefix.substring(0, slash);
      final objectPath = withoutPrefix.substring(slash + 1);
      return 'https://firebasestorage.googleapis.com/v0/b/'
          '$bucket/o/${Uri.encodeComponent(objectPath)}?alt=media';
    }
    return '';
  }

  Future<String?> _resolveToDownloadUrl(String? rawPath) async {
    final raw = (rawPath ?? '').trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('assets/') ||
        raw.startsWith('data:image')) {
      return raw;
    }
    if (raw.startsWith('gs://')) {
      try {
        return await FirebaseStorage.instance.refFromURL(raw).getDownloadURL();
      } catch (_) {
        return _toRenderableImageUrl(raw);
      }
    }
    final objectPath = raw.replaceAll('\\', '/');
    if (!objectPath.contains('/')) return null;
    try {
      return await FirebaseStorage.instance.ref(objectPath).getDownloadURL();
    } catch (_) {
      return _toRenderableImageUrl(objectPath);
    }
  }

  String? _toRenderableImageUrl(String rawPath) {
    final raw = rawPath.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('assets/') ||
        raw.startsWith('data:image')) {
      return raw;
    }
    if (raw.startsWith('gs://')) {
      final withoutPrefix = raw.replaceFirst('gs://', '');
      final slash = withoutPrefix.indexOf('/');
      if (slash <= 0 || slash >= withoutPrefix.length - 1) return null;
      final bucket = withoutPrefix.substring(0, slash);
      final objectPath = withoutPrefix.substring(slash + 1);
      return 'https://firebasestorage.googleapis.com/v0/b/'
          '$bucket/o/${Uri.encodeComponent(objectPath)}?alt=media';
    }
    final bucket = Firebase.app().options.storageBucket?.trim() ?? '';
    if (bucket.isEmpty) return null;
    final objectPath = raw.replaceAll('\\', '/');
    if (!objectPath.contains('/')) return null;
    return 'https://firebasestorage.googleapis.com/v0/b/'
        '$bucket/o/${Uri.encodeComponent(objectPath)}?alt=media';
  }

  String? _readString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
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
}
