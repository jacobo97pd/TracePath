import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  String? packPath;
  String? importsPath;
  for (final arg in args) {
    if (arg.startsWith('--pack=')) {
      packPath = arg.substring('--pack='.length);
    } else if (arg.startsWith('--imports=')) {
      importsPath = arg.substring('--imports='.length);
    }
  }

  if (packPath == null || importsPath == null) {
    stderr.writeln(
        'Usage: dart run tool/merge_imports.dart --pack=assets/levels/pack_all_v1.json --imports=imports/linkedin_imports.json');
    exitCode = 64;
    return;
  }

  final packFile = File(packPath);
  final importsFile = File(importsPath);
  if (!packFile.existsSync()) {
    stderr.writeln('Pack file not found: $packPath');
    exitCode = 66;
    return;
  }
  if (!importsFile.existsSync()) {
    stderr.writeln('Imports file not found: $importsPath');
    exitCode = 66;
    return;
  }

  final pack = jsonDecode(packFile.readAsStringSync()) as Map<String, dynamic>;
  final importsRoot =
      jsonDecode(importsFile.readAsStringSync()) as Map<String, dynamic>;

  final existingLevels =
      ((pack['levels'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: true);

  final imports =
      ((importsRoot['levels'] as List<dynamic>?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);

  final seen = <String>{};
  for (final level in existingLevels) {
    final fp = (level['fingerprint'] as String?) ?? '';
    if (fp.isNotEmpty) seen.add(fp);
  }

  var appended = 0;
  for (final level in imports) {
    final normalized =
        _normalizeLevel(level, appended + existingLevels.length + 1);
    final fp = (normalized['fingerprint'] as String?) ?? '';
    if (fp.isNotEmpty && seen.contains(fp)) {
      continue;
    }
    if (fp.isNotEmpty) {
      seen.add(fp);
    }
    existingLevels.add(normalized);
    appended++;
  }

  final output = <String, dynamic>{
    'packId': (pack['packId'] as String?) ?? 'all',
    'version': (pack['version'] as String?) ?? 'pack_all_v1',
    'count': existingLevels.length,
    'levels': existingLevels,
  };

  packFile
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(output));
  stdout.writeln('Merged $appended new levels into $packPath');
  stdout.writeln('Total levels: ${existingLevels.length}');
}

Map<String, dynamic> _normalizeLevel(
    Map<String, dynamic> level, int fallbackIndex) {
  final size = Map<String, dynamic>.from(
      (level['size'] as Map?) ?? const <String, dynamic>{'w': 7, 'h': 7});
  final clues = ((level['clues'] as List<dynamic>?) ?? const <dynamic>[])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
  final walls = ((level['walls'] as List<dynamic>?) ?? const <dynamic>[])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);

  return <String, dynamic>{
    'id': (level['id'] as String?) ?? 'linkedin-import-$fallbackIndex',
    'size': <String, int>{
      'w': ((size['w'] as num?) ?? 7).toInt(),
      'h': ((size['h'] as num?) ?? 7).toInt(),
    },
    'difficultyTag': (level['difficultyTag'] as String?) ?? 'd5',
    'source': (level['source'] as String?) ?? 'linkedin',
    'origin': (level['origin'] as String?) ?? 'curated',
    'tags': (level['tags'] as List<dynamic>?) ?? const <String>['linkedin'],
    'fingerprint': (level['fingerprint'] as String?) ?? '',
    'clues': clues,
    'walls': walls,
    'solution': ((level['solution'] as List<dynamic>?) ?? const <dynamic>[])
        .map((e) => (e as num).toInt())
        .toList(growable: false),
  };
}
