import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/level.dart';

const String levelFingerprintGeneratorVersion = 'struct-v3';

class LevelFingerprintStore {
  LevelFingerprintStore._();

  static final LevelFingerprintStore instance = LevelFingerprintStore._();

  final Map<String, Set<String>> _seenByNamespace = <String, Set<String>>{};
  final Map<String, List<String>> _orderByNamespace = <String, List<String>>{};

  bool _initialized = false;
  bool _initInFlight = false;

  static const String _storageKey = 'level_fingerprints_json_v3';

  Future<void> initialize() async {
    if (_initialized || _initInFlight) {
      while (_initInFlight) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      return;
    }
    _initInFlight = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['namespaces'] is Map) {
          final namespaces =
              Map<String, dynamic>.from(decoded['namespaces'] as Map);
          for (final entry in namespaces.entries) {
            final list = (entry.value as List<dynamic>)
                .map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList(growable: true);
            _orderByNamespace[entry.key] = list;
            _seenByNamespace[entry.key] = list.toSet();
          }
        }
      } else {
        await prefs.setString(
          _storageKey,
          jsonEncode(<String, dynamic>{
            'version': levelFingerprintGeneratorVersion,
            'namespaces': <String, dynamic>{},
          }),
        );
      }
      _initialized = true;
    } catch (_) {
      _initialized = true;
    } finally {
      _initInFlight = false;
    }
  }

  bool containsInMemory(String namespace, String fingerprint) {
    return _seenByNamespace[namespace]?.contains(fingerprint) ?? false;
  }

  Future<bool> registerIfUnique({
    required String namespace,
    required String fingerprint,
    required int maxEntries,
  }) async {
    await initialize();
    final seen = _seenByNamespace.putIfAbsent(namespace, () => <String>{});
    if (seen.contains(fingerprint)) {
      return false;
    }
    final order = _orderByNamespace.putIfAbsent(namespace, () => <String>[]);
    seen.add(fingerprint);
    order.add(fingerprint);
    while (order.length > maxEntries) {
      final oldest = order.removeAt(0);
      seen.remove(oldest);
    }
    await _persist();
    return true;
  }

  String fingerprintForLevel({
    required Level level,
    required String namespaceMode,
    required String difficultyTier,
  }) {
    final wallTokens = level.walls.map((wall) {
      final a = wall.cell1 < wall.cell2 ? wall.cell1 : wall.cell2;
      final b = wall.cell1 > wall.cell2 ? wall.cell1 : wall.cell2;
      return '$a-$b';
    }).toList()
      ..sort();

    final clueEntries = level.numbers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final clueTokens = clueEntries.map((e) => '${e.value}@${e.key}').toList();

    final payload = <String>[
      'v=$levelFingerprintGeneratorVersion',
      'mode=$namespaceMode',
      'tier=$difficultyTier',
      'pack=${level.pack}',
      'size=${level.width}x${level.height}',
      'walls=${wallTokens.join(",")}',
      'clues=${clueTokens.join(",")}',
    ].join('|');
    return sha256.convert(utf8.encode(payload)).toString();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'version': levelFingerprintGeneratorVersion,
        'namespaces': <String, dynamic>{
          for (final entry in _orderByNamespace.entries) entry.key: entry.value,
        },
      };
      await prefs.setString(_storageKey, jsonEncode(payload));
    } catch (_) {
      assert(() {
        debugPrint('[LevelFingerprint] persist failed');
        return true;
      }());
    }
  }
}
