import 'dart:convert';
import 'dart:io';

import 'package:zip_path_flutter/engine/level.dart';
import 'package:zip_path_flutter/engine/linkedin_js_generator.dart';
import 'package:zip_path_flutter/engine/seed_random.dart';

int _readIntArg(List<String> args, String name, int fallback) {
  final idx = args.indexOf(name);
  if (idx == -1 || idx + 1 >= args.length) {
    return fallback;
  }
  return int.tryParse(args[idx + 1]) ?? fallback;
}

String _readStringArg(List<String> args, String name, String fallback) {
  final idx = args.indexOf(name);
  if (idx == -1 || idx + 1 >= args.length) {
    return fallback;
  }
  return args[idx + 1];
}

Map<String, dynamic> _toPackLevelJson(Level level, int index) {
  final clues = level.numbers.entries.map((entry) {
    final cell = entry.key;
    final n = entry.value;
    final x = cell % level.width;
    final y = cell ~/ level.width;
    return <String, dynamic>{
      'n': n,
      'x': x,
      'y': y,
    };
  }).toList(growable: false)
    ..sort((a, b) {
      final na = a['n'] as int;
      final nb = b['n'] as int;
      if (na != nb) return na.compareTo(nb);
      final ya = a['y'] as int;
      final yb = b['y'] as int;
      if (ya != yb) return ya.compareTo(yb);
      return (a['x'] as int).compareTo(b['x'] as int);
    });

  return <String, dynamic>{
    'id': 'linkedin-js-$index',
    'size': {'w': level.width, 'h': level.height},
    'difficultyTag': 'd${level.difficulty}',
    'source': 'linkedin_js_generator',
    'fingerprint': '',
    'clues': clues,
    'walls': level.walls
        .map((w) => <String, dynamic>{'cell1': w.cell1, 'cell2': w.cell2})
        .toList(growable: false),
    'solution': level.solution,
  };
}

void main(List<String> args) {
  final count = _readIntArg(args, '--count', 200).clamp(1, 5000);
  final outPath = _readStringArg(
    args,
    '--out',
    'assets/levels/pack_linkedin_js_generated_v1.json',
  );

  final levels = <Map<String, dynamic>>[];
  for (var i = 1; i <= count; i++) {
    Level? level;
    Object? lastError;
    for (var retry = 0; retry < 30; retry++) {
      final seed = hashString('linkedin_js-level-$i-retry-$retry');
      try {
        level = generateLinkedinJsLevel(seed: seed, levelIndex: i);
        break;
      } catch (error) {
        lastError = error;
      }
    }
    if (level == null) {
      throw Exception('Failed to generate level $i after retries: $lastError');
    }
    levels.add(_toPackLevelJson(level, i));
  }

  final pack = <String, dynamic>{
    'packId': 'linkedin_js_generated',
    'version': 'pack_linkedin_js_generated_v1',
    'count': levels.length,
    'levels': levels,
  };

  final outFile = File(outPath);
  outFile.createSync(recursive: true);
  outFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(pack),
    flush: true,
  );

  stdout.writeln('Generated ${levels.length} levels -> ${outFile.path}');
}
