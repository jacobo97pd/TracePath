import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GhostFrame {
  const GhostFrame({
    required this.timeMs,
    required this.x,
    required this.y,
  });

  final int timeMs;
  final double x;
  final double y;

  Map<String, dynamic> toJson() => <String, dynamic>{
        't': timeMs,
        'x': x,
        'y': y,
      };

  factory GhostFrame.fromJson(Map<String, dynamic> json) {
    double readDouble(Object? value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    int readInt(Object? value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return GhostFrame(
      timeMs: readInt(json['t']),
      x: readDouble(json['x']).clamp(0, 1),
      y: readDouble(json['y']).clamp(0, 1),
    );
  }
}

class GhostRun {
  const GhostRun({
    required this.levelId,
    required this.totalTimeMs,
    required this.boardWidth,
    required this.boardHeight,
    required this.frames,
  });

  final String levelId;
  final int totalTimeMs;
  final int boardWidth;
  final int boardHeight;
  final List<GhostFrame> frames;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'levelId': levelId,
        'totalTimeMs': totalTimeMs,
        'boardWidth': boardWidth,
        'boardHeight': boardHeight,
        'frames': frames.map((f) => f.toJson()).toList(growable: false),
      };

  factory GhostRun.fromJson(Map<String, dynamic> json) {
    final rawFrames = json['frames'];
    final parsed = <GhostFrame>[];
    if (rawFrames is List) {
      for (final item in rawFrames) {
        if (item is Map<String, dynamic>) {
          parsed.add(GhostFrame.fromJson(item));
        } else if (item is Map) {
          parsed.add(GhostFrame.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    int readInt(Object? value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final levelId = (json['levelId'] as String? ?? '').trim();
    return GhostRun(
      levelId: levelId,
      totalTimeMs: readInt(json['totalTimeMs']),
      boardWidth: readInt(json['boardWidth']),
      boardHeight: readInt(json['boardHeight']),
      frames: List<GhostFrame>.unmodifiable(parsed),
    );
  }
}

class GhostService {
  static const String _prefix = 'ghost_best_run:';
  static const String _firestoreDatabaseId = 'tracepath-database';

  Future<GhostRun?> loadBestRun({
    required String uid,
    required String levelId,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedLevelId = levelId.trim();
    if (normalizedLevelId.isEmpty) return null;

    final local = await _readLocalBestRun(
      uid: normalizedUid,
      levelId: normalizedLevelId,
    );
    if (normalizedUid.isEmpty || normalizedUid == 'guest') {
      return local;
    }

    try {
      final remote = await _readRemoteBestRun(
        uid: normalizedUid,
        levelId: normalizedLevelId,
      );
      if (remote != null) {
        await _writeLocalBestRun(
          uid: normalizedUid,
          levelId: normalizedLevelId,
          run: remote,
        );
        return remote;
      }
    } catch (_) {}

    return local;
  }

  Future<bool> saveBestRunIfBetter({
    required String uid,
    required GhostRun run,
  }) async {
    final normalizedUid = uid.trim();
    final normalized = _sanitizeRun(run);
    if (normalized == null) {
      return false;
    }

    if (normalizedUid.isEmpty || normalizedUid == 'guest') {
      return _saveLocalIfBetter(uid: normalizedUid, run: normalized);
    }

    var updated = false;
    try {
      final docRef = _db()
          .collection('users')
          .doc(normalizedUid)
          .collection('ghostRuns')
          .doc(normalized.levelId);
      await _db().runTransaction((tx) async {
        final snap = await tx.get(docRef);
        final current = _sanitizeRunFromMap(snap.data());
        final shouldReplace = current == null ||
            current.totalTimeMs <= 0 ||
            normalized.totalTimeMs < current.totalTimeMs;
        if (!shouldReplace) return;
        tx.set(
          docRef,
          <String, dynamic>{
            ...normalized.toJson(),
            'uid': normalizedUid,
            'updatedAt': FieldValue.serverTimestamp(),
            if (!snap.exists) 'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        updated = true;
      });
    } catch (_) {
      // Fallback to local-only persistence if remote fails.
      return _saveLocalIfBetter(uid: normalizedUid, run: normalized);
    }

    if (updated) {
      await _writeLocalBestRun(
        uid: normalizedUid,
        levelId: normalized.levelId,
        run: normalized,
      );
      return true;
    }

    final localUpdated =
        await _saveLocalIfBetter(uid: normalizedUid, run: normalized);
    return localUpdated;
  }

  Future<GhostRun?> _readRemoteBestRun({
    required String uid,
    required String levelId,
  }) async {
    final snap = await _db()
        .collection('users')
        .doc(uid)
        .collection('ghostRuns')
        .doc(levelId)
        .get();
    if (!snap.exists) return null;
    return _sanitizeRunFromMap(snap.data());
  }

  Future<GhostRun?> _readLocalBestRun({
    required String uid,
    required String levelId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(uid, levelId);
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return _sanitizeRunFromMap(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _saveLocalIfBetter({
    required String uid,
    required GhostRun run,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _readLocalBestRun(uid: uid, levelId: run.levelId);
    final shouldReplace = current == null ||
        current.totalTimeMs <= 0 ||
        run.totalTimeMs < current.totalTimeMs;
    if (!shouldReplace) return false;

    final key = _key(uid, run.levelId);
    await prefs.setString(key, jsonEncode(run.toJson()));
    return true;
  }

  Future<void> _writeLocalBestRun({
    required String uid,
    required String levelId,
    required GhostRun run,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(uid, levelId), jsonEncode(run.toJson()));
  }

  GhostRun? _sanitizeRunFromMap(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return _sanitizeRun(GhostRun.fromJson(raw));
    } catch (_) {
      return null;
    }
  }

  GhostRun? _sanitizeRun(GhostRun run) {
    final levelId = run.levelId.trim();
    if (levelId.isEmpty) return null;
    if (run.totalTimeMs <= 0) return null;
    final width = run.boardWidth <= 0 ? 1 : run.boardWidth;
    final height = run.boardHeight <= 0 ? 1 : run.boardHeight;

    final sorted = List<GhostFrame>.from(run.frames)
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));
    final normalized = <GhostFrame>[];
    var lastT = -1;
    for (final frame in sorted) {
      final t = frame.timeMs;
      if (t < 0) continue;
      if (t == lastT) {
        // Keep only latest sample for this timestamp.
        if (normalized.isNotEmpty) {
          normalized.removeLast();
        }
      }
      normalized.add(
        GhostFrame(
          timeMs: t,
          x: frame.x.clamp(0.0, 1.0),
          y: frame.y.clamp(0.0, 1.0),
        ),
      );
      lastT = t;
    }
    if (normalized.length < 2) return null;

    final effectiveTotal = run.totalTimeMs < normalized.last.timeMs
        ? normalized.last.timeMs
        : run.totalTimeMs;
    if (effectiveTotal <= 0) return null;

    return GhostRun(
      levelId: levelId,
      totalTimeMs: effectiveTotal,
      boardWidth: width,
      boardHeight: height,
      frames: List<GhostFrame>.unmodifiable(normalized),
    );
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

  String _key(String uid, String levelId) => '$_prefix$uid:$levelId';
}
