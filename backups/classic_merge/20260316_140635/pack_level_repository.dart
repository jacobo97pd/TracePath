import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'engine/level.dart';

class PackLevelRecord {
  const PackLevelRecord({
    required this.id,
    required this.fingerprint,
    required this.difficultyTag,
    required this.source,
    required this.level,
  });

  final String id;
  final String fingerprint;
  final String difficultyTag;
  final String source;
  final Level level;
}

class PackLevelRepository {
  PackLevelRepository._();
  static final PackLevelRepository instance = PackLevelRepository._();

  static const Map<String, String> _packAssetMap = <String, String>{
    'all': 'assets/levels/pack_all_v1.json',
    'pack_all_v1': 'assets/levels/pack_all_v1.json',
    'classic': 'assets/levels/pack_core_v1.json',
    'core': 'assets/levels/pack_core_v1.json',
    'curated': 'assets/levels/pack_curated_v1.json',
    'linkedin': 'assets/levels/pack_linkedin_v1.json',
    'pack_linkedin_v1': 'assets/levels/pack_linkedin_v1.json',
    'linkedin_editor': 'assets/levels/pack_linkedin_editor_v1.json',
    'pack_linkedin_editor_v1': 'assets/levels/pack_linkedin_editor_v1.json',
    'linkedin_js_generated': 'assets/levels/pack_linkedin_js_generated_v1.json',
    'pack_linkedin_js_generated_v1':
        'assets/levels/pack_linkedin_js_generated_v1.json',
    'bulk_variant_100': 'assets/levels/pack_bulk_variant_100_v1.json',
    'pack_bulk_variant_100_v1': 'assets/levels/pack_bulk_variant_100_v1.json',
    'bulk_variant_200': 'assets/levels/pack_bulk_variant_200_v1.json',
    'pack_bulk_variant_200_v1': 'assets/levels/pack_bulk_variant_200_v1.json',
    'variant_alphabet': 'assets/levels/pack_variant_alphabet_v1.json',
    'pack_variant_alphabet_v1': 'assets/levels/pack_variant_alphabet_v1.json',
    'variant_alphabet_reverse':
        'assets/levels/pack_variant_alphabet_reverse_v1.json',
    'pack_variant_alphabet_reverse_v1':
        'assets/levels/pack_variant_alphabet_reverse_v1.json',
    'variant_multiples': 'assets/levels/pack_variant_multiples_v1.json',
    'pack_variant_multiples_v1': 'assets/levels/pack_variant_multiples_v1.json',
    'variant_roman': 'assets/levels/pack_variant_roman_v1.json',
    'pack_variant_roman_v1': 'assets/levels/pack_variant_roman_v1.json',
    'variant_multiples_roman':
        'assets/levels/pack_variant_multiples_roman_v1.json',
    'pack_variant_multiples_roman_v1':
        'assets/levels/pack_variant_multiples_roman_v1.json',
  };

  final Map<String, List<PackLevelRecord>> _cache =
      <String, List<PackLevelRecord>>{};
  final Set<String> _loadFailed = <String>{};

  bool isPrecomputedPack(String packId) => _packAssetMap.containsKey(packId);

  Future<void> loadPack(String packId) async {
    if (_cache.containsKey(packId) || _loadFailed.contains(packId)) {
      return;
    }
    final assetPath = _packAssetMap[packId];
    if (assetPath == null) {
      _loadFailed.add(packId);
      return;
    }
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final levels = (decoded['levels'] as List<dynamic>? ?? const <dynamic>[]);
      final records = <PackLevelRecord>[];
      for (var i = 0; i < levels.length; i++) {
        final node = Map<String, dynamic>.from(levels[i] as Map);
        records.add(_toRecord(packId: packId, index: i + 1, node: node));
      }
      _cache[packId] = records;
      assert(() {
        debugPrint(
            '[PackRepo] loaded pack=$packId source=$assetPath count=${records.length}');
        return true;
      }());
    } catch (_) {
      _loadFailed.add(packId);
      assert(() {
        debugPrint('[PackRepo] failed to load pack=$packId source=$assetPath');
        return true;
      }());
    }
  }

  Future<PackLevelRecord?> getLevel(String packId, int index) async {
    await loadPack(packId);
    return getLevelSync(packId, index);
  }

  PackLevelRecord? getLevelSync(String packId, int index) {
    final records = _cache[packId];
    if (records == null || index <= 0 || index > records.length) {
      return null;
    }
    return records[index - 1];
  }

  int totalLevelsSync(String packId) => _cache[packId]?.length ?? 0;

  Future<int> totalLevels(String packId) async {
    await loadPack(packId);
    return totalLevelsSync(packId);
  }

  PackLevelRecord _toRecord({
    required String packId,
    required int index,
    required Map<String, dynamic> node,
  }) {
    final sizeRaw = node['size'];
    late final int width;
    late final int height;
    if (sizeRaw is num) {
      width = sizeRaw.toInt();
      height = sizeRaw.toInt();
    } else if (sizeRaw is Map) {
      final size = Map<String, dynamic>.from(sizeRaw);
      width = (size['w'] as num).toInt();
      height = (size['h'] as num).toInt();
    } else {
      throw StateError('Invalid size format for level ${node['id']}');
    }
    final clues = (node['clues'] as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
    final numbers = <int, int>{};
    for (final clue in clues) {
      final n = (clue['n'] as num).toInt();
      final x = (clue['x'] as num).toInt();
      final y = (clue['y'] as num).toInt();
      final cell = y * width + x;
      numbers[cell] = n;
    }
    final displayLabels = _parseDisplayLabels(node);
    final walls = _parseWalls(
      wallsRaw: node['walls'],
      width: width,
      height: height,
    );
    final solution = (node['solution'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => (e as num).toInt())
        .toList(growable: false);
    final id = (node['id'] as String?) ?? '$packId-$index';
    final metrics = node['metrics'] is Map
        ? Map<String, dynamic>.from(node['metrics'] as Map)
        : const <String, dynamic>{};
    final difficultyTag =
        (node['difficultyTag'] as String?) ??
        _difficultyTagFromMetrics(metrics) ??
        'd1';
    final difficulty = int.tryParse(difficultyTag.replaceFirst('d', '')) ?? 1;
    final level = Level(
      id: id,
      width: width,
      height: height,
      numbers: numbers,
      displayLabels: displayLabels,
      walls: walls,
      solution: solution,
      difficulty: difficulty,
      pack: packId,
    );
    return PackLevelRecord(
      id: id,
      fingerprint: (node['fingerprint'] as String?) ?? '',
      difficultyTag: difficultyTag,
      source: (node['source'] as String?) ?? 'asset',
      level: level,
    );
  }

  Map<int, String> _parseDisplayLabels(Map<String, dynamic> node) {
    final metaRaw = node['meta'];
    if (metaRaw is! Map) {
      return const <int, String>{};
    }
    final meta = Map<String, dynamic>.from(metaRaw);
    final labelsRaw = meta['display_labels'];
    if (labelsRaw is! Map) {
      return const <int, String>{};
    }
    final labelsMap = Map<String, dynamic>.from(labelsRaw);
    final out = <int, String>{};
    labelsMap.forEach((k, v) {
      final key = int.tryParse(k.trim());
      if (key == null) return;
      final text = v.toString().trim();
      if (text.isEmpty) return;
      out[key] = text;
    });
    return out;
  }

  String? _difficultyTagFromMetrics(Map<String, dynamic> metrics) {
    final estimate = (metrics['difficulty_estimate'] as String?)?.trim();
    switch (estimate) {
      case 'easy':
        return 'd2';
      case 'medium':
        return 'd3';
      case 'hard':
        return 'd5';
      default:
        return null;
    }
  }

  List<Wall> _parseWalls({
    required dynamic wallsRaw,
    required int width,
    required int height,
  }) {
    if (wallsRaw is List) {
      return wallsRaw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .map((e) => Wall(
                cell1: (e['cell1'] as num).toInt(),
                cell2: (e['cell2'] as num).toInt(),
              ))
          .toList(growable: false);
    }
    if (wallsRaw is Map) {
      final wallsMap = Map<String, dynamic>.from(wallsRaw);
      final hSegments = (wallsMap['h'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
      final vSegments = (wallsMap['v'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
      final walls = <Wall>[];
      for (final seg in hSegments) {
        final x = (seg['x'] as num?)?.toInt() ?? 0;
        final y = (seg['y'] as num?)?.toInt() ?? 0;
        final len = (seg['len'] as num?)?.toInt() ?? 0;
        if (y <= 0 || y > height || len <= 0) continue;
        for (var dx = 0; dx < len; dx++) {
          final cx = x + dx;
          if (cx < 0 || cx >= width) continue;
          final top = (y - 1) * width + cx;
          final bottom = y * width + cx;
          walls.add(Wall(cell1: top, cell2: bottom));
        }
      }
      for (final seg in vSegments) {
        final x = (seg['x'] as num?)?.toInt() ?? 0;
        final y = (seg['y'] as num?)?.toInt() ?? 0;
        final len = (seg['len'] as num?)?.toInt() ?? 0;
        if (x <= 0 || x > width || len <= 0) continue;
        for (var dy = 0; dy < len; dy++) {
          final cy = y + dy;
          if (cy < 0 || cy >= height) continue;
          final left = cy * width + (x - 1);
          final right = cy * width + x;
          walls.add(Wall(cell1: left, cell2: right));
        }
      }
      return walls;
    }
    return const <Wall>[];
  }
}
