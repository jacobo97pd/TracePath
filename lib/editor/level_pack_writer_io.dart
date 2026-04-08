import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'editor_codec.dart';
import 'level_pack_writer.dart';

bool get supportsGeneralPackWrite => true;

Future<SaveToGeneralPackResult> saveLevelToGeneralPack(
  EditorLevelData data,
) async {
  final file = _findGeneralPackFile();
  if (file == null) {
    return const SaveToGeneralPackResult(
      added: false,
      message: 'No se encontro assets/levels/pack_all_v1.json',
    );
  }

  final raw = await file.readAsString();
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    return const SaveToGeneralPackResult(
      added: false,
      message: 'Formato invalido de pack_all_v1.json',
    );
  }

  final levelsRaw = decoded['levels'];
  if (levelsRaw is! List) {
    return const SaveToGeneralPackResult(
      added: false,
      message: 'pack_all_v1.json no contiene lista de levels',
    );
  }

  final levels = levelsRaw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: true);

  final incomingSignature = _signatureFromEditorData(data);
  for (final level in levels) {
    if (_signatureFromPackLevel(level) == incomingSignature) {
      final existingId = (level['id'] as String?)?.trim();
      return SaveToGeneralPackResult(
        added: false,
        message: 'Este nivel ya existe en el pack general.',
        levelId: existingId,
      );
    }
  }

  var maxId = 0;
  for (final level in levels) {
    final id = (level['id'] as String?)?.trim() ?? '';
    final match = RegExp(r'^all-(\d+)$').firstMatch(id);
    if (match == null) continue;
    final value = int.tryParse(match.group(1) ?? '') ?? 0;
    maxId = max(maxId, value);
  }
  final nextIdNumber = maxId + 1;
  final nextLevelId = 'all-$nextIdNumber';

  final newLevel = <String, dynamic>{
    'id': nextLevelId,
    'size': <String, int>{'w': data.width, 'h': data.height},
    'difficultyTag': _difficultyTagForSize(data.width, data.height),
    'source': 'editor',
    'fingerprint': '',
    'clues': _sortedClues(data),
    'walls': _wallsAsCellEdges(data),
    'solution': const <int>[],
    'sourceLevelId': 'editor-$nextIdNumber',
  };

  levels.add(newLevel);
  decoded['levels'] = levels;
  decoded['count'] = levels.length;
  decoded['version'] = 'pack_all_v1_unified';

  final backupPath =
      '${file.path}.bak_editor_${DateTime.now().millisecondsSinceEpoch}';
  await file.copy(backupPath);

  final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
  await file.writeAsString(pretty);

  return SaveToGeneralPackResult(
    added: true,
    message: 'Nivel guardado en pack general como $nextLevelId',
    levelId: nextLevelId,
  );
}

File? _findGeneralPackFile() {
  Directory cursor = Directory.current.absolute;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${cursor.path}${Platform.pathSeparator}assets'
      '${Platform.pathSeparator}levels'
      '${Platform.pathSeparator}pack_all_v1.json',
    );
    if (candidate.existsSync()) {
      return candidate;
    }
    final parent = cursor.parent;
    if (parent.path == cursor.path) break;
    cursor = parent;
  }
  return null;
}

List<Map<String, int>> _sortedClues(EditorLevelData data) {
  final clues = data.clues.entries
      .map(
        (e) => <String, int>{
          'n': e.value,
          'x': e.key.x,
          'y': e.key.y,
        },
      )
      .toList(growable: false);
  clues.sort((a, b) {
    final byN = (a['n'] ?? 0).compareTo(b['n'] ?? 0);
    if (byN != 0) return byN;
    final byY = (a['y'] ?? 0).compareTo(b['y'] ?? 0);
    if (byY != 0) return byY;
    return (a['x'] ?? 0).compareTo(b['x'] ?? 0);
  });
  return clues;
}

List<Map<String, int>> _wallsAsCellEdges(EditorLevelData data) {
  final seen = <String>{};
  final walls = <Map<String, int>>[];
  for (var y = 1; y < data.height; y++) {
    for (var x = 0; x < data.width; x++) {
      if (!data.hWalls[y][x]) continue;
      final a = (y - 1) * data.width + x;
      final b = y * data.width + x;
      final minCell = min(a, b);
      final maxCell = max(a, b);
      final key = '$minCell:$maxCell';
      if (!seen.add(key)) continue;
      walls.add(<String, int>{'cell1': minCell, 'cell2': maxCell});
    }
  }
  for (var y = 0; y < data.height; y++) {
    for (var x = 1; x < data.width; x++) {
      if (!data.vWalls[y][x]) continue;
      final a = y * data.width + (x - 1);
      final b = y * data.width + x;
      final minCell = min(a, b);
      final maxCell = max(a, b);
      final key = '$minCell:$maxCell';
      if (!seen.add(key)) continue;
      walls.add(<String, int>{'cell1': minCell, 'cell2': maxCell});
    }
  }
  walls.sort((a, b) {
    final by1 = (a['cell1'] ?? 0).compareTo(b['cell1'] ?? 0);
    if (by1 != 0) return by1;
    return (a['cell2'] ?? 0).compareTo(b['cell2'] ?? 0);
  });
  return walls;
}

String _difficultyTagForSize(int width, int height) {
  final size = max(width, height);
  if (size <= 5) return 'd1';
  if (size == 6) return 'd2';
  if (size == 7) return 'd3';
  return 'd4';
}

String _signatureFromEditorData(EditorLevelData data) {
  final clues = _sortedClues(data)
      .map((c) => '${c['n']}:${c['x']}:${c['y']}')
      .toList(growable: false);
  final walls = _wallsAsCellEdges(data)
      .map((w) => '${w['cell1']}-${w['cell2']}')
      .toList(growable: false);
  return 'w=${data.width};h=${data.height};clues=${clues.join(',')};walls=${walls.join(',')}';
}

String _signatureFromPackLevel(Map<String, dynamic> level) {
  final sizeRaw = level['size'];
  int w = 0;
  int h = 0;
  if (sizeRaw is Map<String, dynamic>) {
    w = (sizeRaw['w'] as num?)?.toInt() ?? 0;
    h = (sizeRaw['h'] as num?)?.toInt() ?? 0;
  }
  final cluesRaw = (level['clues'] as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
  final clues = cluesRaw
      .map(
        (c) =>
            '${(c['n'] as num?)?.toInt() ?? 0}:${(c['x'] as num?)?.toInt() ?? 0}:${(c['y'] as num?)?.toInt() ?? 0}',
      )
      .toList(growable: false)
    ..sort();

  final wallsRaw = (level['walls'] as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
  final walls = wallsRaw
      .map((w) {
        final a = (w['cell1'] as num?)?.toInt() ?? 0;
        final b = (w['cell2'] as num?)?.toInt() ?? 0;
        final minCell = min(a, b);
        final maxCell = max(a, b);
        return '$minCell-$maxCell';
      })
      .toList(growable: false)
    ..sort();

  return 'w=$w;h=$h;clues=${clues.join(',')};walls=${walls.join(',')}';
}

