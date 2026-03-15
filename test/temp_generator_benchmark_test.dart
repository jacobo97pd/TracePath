import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zip_path_flutter/engine/level.dart';
import 'package:zip_path_flutter/engine/level_generator.dart';
import 'package:zip_path_flutter/engine/seed_random.dart';

class _CategoryConfig {
  const _CategoryConfig({
    required this.name,
    required this.packId,
    required this.width,
    required this.height,
    required this.difficulty,
    required this.profile,
  });

  final String name;
  final String packId;
  final int width;
  final int height;
  final int difficulty;
  final String profile;
}

void main() {
  test('benchmark structural generator families', () async {
    const samples = 20;
    const categories = <_CategoryConfig>[
      _CategoryConfig(
        name: 'campaign_low',
        packId: 'classic',
        width: 6,
        height: 6,
        difficulty: 2,
        profile: 'campaign_low',
      ),
      _CategoryConfig(
        name: 'campaign_mid',
        packId: 'classic',
        width: 7,
        height: 7,
        difficulty: 3,
        profile: 'campaign_mid',
      ),
      _CategoryConfig(
        name: 'campaign_high',
        packId: 'classic',
        width: 8,
        height: 8,
        difficulty: 5,
        profile: 'campaign_high',
      ),
      _CategoryConfig(
        name: 'daily',
        packId: 'daily',
        width: 8,
        height: 8,
        difficulty: 5,
        profile: 'daily_hard',
      ),
    ];

    final sampleBoards = <Map<String, dynamic>>[];
    for (final config in categories) {
      final timer = Stopwatch()..start();
      var ok = 0;
      var attempts = 0;
      final signatures = <String>{};
      var duplicateCount = 0;
      final chambers = <int>[];
      final chokepoints = <int>[];
      final earlyAmbiguity = <int, int>{};
      final clueCountDist = <int, int>{};
      final earlyMinDistanceDist = <int, int>{};
      final earlyRegionSpanDist = <int, int>{};
      var clueOutOfRange = 0;
      var earlySeparationViolations = 0;
      final rejectReasons = <String, int>{};

      for (var i = 0; i < samples; i++) {
        final seed = hashString('${config.name}|$i');
        try {
          attempts++;
          final level = generateLevel(
            config.width,
            config.height,
            config.difficulty,
            seed,
            config.packId,
            generationProfile: config.profile,
            levelIndexHint: i + 1,
          );
          ok++;
          final signature = _signature(level);
          if (!signatures.add(signature)) {
            duplicateCount++;
          }
          chambers.add(_estimateChambers(level));
          chokepoints.add(_countChokepoints(level));
          final ambiguous = _earlyAmbiguousSegments(level);
          earlyAmbiguity[ambiguous] = (earlyAmbiguity[ambiguous] ?? 0) + 1;
          final clueCount = level.numbers.length;
          clueCountDist[clueCount] = (clueCountDist[clueCount] ?? 0) + 1;
          final range = _targetClueRange(config);
          if (clueCount < range.$1 || clueCount > range.$2) {
            clueOutOfRange++;
          }
          final earlyMetrics = _earlyClueMetrics(level);
          earlyMinDistanceDist[earlyMetrics.$1] =
              (earlyMinDistanceDist[earlyMetrics.$1] ?? 0) + 1;
          earlyRegionSpanDist[earlyMetrics.$2] =
              (earlyRegionSpanDist[earlyMetrics.$2] ?? 0) + 1;
          if (!_passesEarlySeparation(earlyMetrics, level)) {
            earlySeparationViolations++;
          }

          if (sampleBoards.length < 10) {
            sampleBoards.add(<String, dynamic>{
              'category': config.name,
              'seed': seed,
              'level': level.toJson(),
            });
          }
        } on GenerationFailureException catch (e) {
          final match = RegExp(r'\[reason=([^\] ]+)').firstMatch(e.message);
          final reason = match?.group(1) ?? 'unknown';
          rejectReasons[reason] = (rejectReasons[reason] ?? 0) + 1;
        }
      }
      timer.stop();

      final successRate = ok / samples;
      final avgMs = ok == 0 ? 0.0 : timer.elapsedMilliseconds / ok;
      final avgChambers = chambers.isEmpty
          ? 0.0
          : chambers.reduce((a, b) => a + b) / chambers.length;
      final avgChokepoints = chokepoints.isEmpty
          ? 0.0
          : chokepoints.reduce((a, b) => a + b) / chokepoints.length;

      final avgAttempts = attempts / samples;
      final topRejects = rejectReasons.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final outOfRangeRate = ok == 0 ? 0.0 : clueOutOfRange / ok;
      final separationViolationRate =
          ok == 0 ? 0.0 : earlySeparationViolations / ok;

      // ignore: avoid_print
      print(
        '[GenBench] ${config.name} success=$ok/$samples '
        'rate=${(successRate * 100).toStringAsFixed(1)}% '
        'avgMs=${avgMs.toStringAsFixed(1)} '
        'avgAttempts=${avgAttempts.toStringAsFixed(2)} '
        'avgChambers=${avgChambers.toStringAsFixed(2)} '
        'avgChokepoints=${avgChokepoints.toStringAsFixed(2)} '
        'duplicates=$duplicateCount '
        'clueDist=$clueCountDist '
        'earlyMinDist=$earlyMinDistanceDist '
        'earlyRegionSpan=$earlyRegionSpanDist '
        'earlyAmbiguityDist=$earlyAmbiguity '
        'topRejects=${topRejects.take(3).map((e) => '${e.key}:${e.value}').join(', ')}',
      );
      expect(
        outOfRangeRate,
        lessThanOrEqualTo(0.10),
        reason:
            '${config.name} clue counts out-of-range too often (${(outOfRangeRate * 100).toStringAsFixed(1)}%)',
      );
      if (config.name != 'campaign_low') {
        expect(
          separationViolationRate,
          lessThanOrEqualTo(0.05),
          reason:
              '${config.name} early separation violated too often (${(separationViolationRate * 100).toStringAsFixed(1)}%)',
        );
      }
    }

    final outDir = Directory('build/temp_generator_samples');
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
    final outFile =
        File('${outDir.path}${Platform.pathSeparator}sample_levels.json');
    outFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(sampleBoards));
    // ignore: avoid_print
    print('[GenBench] wrote ${sampleBoards.length} samples to ${outFile.path}');
  }, timeout: const Timeout(Duration(minutes: 20)));
}

(int, int) _targetClueRange(_CategoryConfig config) {
  final maxSide = config.width > config.height ? config.width : config.height;
  if (config.name == 'daily') {
    if (maxSide >= 9) return (10, 12);
    return (9, 11);
  }
  if (maxSide >= 9) {
    if (config.name == 'campaign_low') return (7, 9);
    if (config.name == 'campaign_mid') return (9, 11);
    return (11, 13);
  }
  if (maxSide >= 7) {
    if (config.name == 'campaign_low') return (6, 8);
    if (config.name == 'campaign_mid') return (8, 10);
    return (10, 12);
  }
  if (config.name == 'campaign_low') return (5, 7);
  if (config.name == 'campaign_mid') return (6, 8);
  return (8, 10);
}

(int, int) _earlyClueMetrics(Level level) {
  final ordered = level.numbers.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  if (ordered.length < 4) {
    return (0, 0);
  }
  final firstFour = ordered.take(4).map((e) => e.key).toList(growable: false);
  final pairs = <(int, int)>[
    (0, 1),
    (1, 2),
    (2, 3),
    (0, 2),
    (0, 3),
    (1, 3),
  ];
  var minDistance = 999;
  for (final pair in pairs) {
    final a = firstFour[pair.$1];
    final b = firstFour[pair.$2];
    final ar = a ~/ level.width;
    final ac = a % level.width;
    final br = b ~/ level.width;
    final bc = b % level.width;
    final d = (ar - br).abs() + (ac - bc).abs();
    if (d < minDistance) {
      minDistance = d;
    }
  }
  final regions = <int>{};
  for (final cell in firstFour) {
    final row = cell ~/ level.width;
    final col = cell % level.width;
    final rowBucket = ((row * 3) ~/ level.height).clamp(0, 2);
    final colBucket = ((col * 3) ~/ level.width).clamp(0, 2);
    regions.add(rowBucket * 3 + colBucket);
  }
  return (minDistance, regions.length);
}

bool _passesEarlySeparation((int, int) metrics, Level level) {
  final maxSide = level.width > level.height ? level.width : level.height;
  final minRequired = maxSide >= 9 ? 7 : (maxSide >= 8 ? 6 : 3);
  return metrics.$1 >= minRequired && metrics.$2 >= 2;
}

String _signature(Level level) {
  final numbers = level.numbers.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  final walls = level.walls.map((w) {
    final a = w.cell1 < w.cell2 ? w.cell1 : w.cell2;
    final b = w.cell1 > w.cell2 ? w.cell1 : w.cell2;
    return '$a-$b';
  }).toList()
    ..sort();
  return '${level.width}x${level.height}|n=${numbers.map((e) => '${e.value}@${e.key}').join(",")}|w=${walls.join(",")}';
}

int _estimateChambers(Level level) {
  final wallSet = <String>{
    for (final w in level.walls)
      '${w.cell1 < w.cell2 ? w.cell1 : w.cell2},${w.cell1 > w.cell2 ? w.cell1 : w.cell2}'
  };

  var verticalDividers = 0;
  for (var col = 0; col < level.width - 1; col++) {
    var blocked = 0;
    for (var row = 0; row < level.height; row++) {
      final a = row * level.width + col;
      final b = a + 1;
      if (wallSet.contains('$a,$b')) blocked++;
    }
    if (blocked >= level.height - 2) verticalDividers++;
  }

  var horizontalDividers = 0;
  for (var row = 0; row < level.height - 1; row++) {
    var blocked = 0;
    for (var col = 0; col < level.width; col++) {
      final a = row * level.width + col;
      final b = a + level.width;
      if (wallSet.contains('$a,$b')) blocked++;
    }
    if (blocked >= level.width - 2) horizontalDividers++;
  }
  return ((verticalDividers + 1) * (horizontalDividers + 1)).clamp(1, 16);
}

int _countChokepoints(Level level) {
  final wallSet = <String>{
    for (final w in level.walls)
      '${w.cell1 < w.cell2 ? w.cell1 : w.cell2},${w.cell1 > w.cell2 ? w.cell1 : w.cell2}'
  };
  var chokepoints = 0;

  for (var col = 0; col < level.width - 1; col++) {
    var blocked = 0;
    for (var row = 0; row < level.height; row++) {
      final a = row * level.width + col;
      final b = a + 1;
      if (wallSet.contains('$a,$b')) blocked++;
    }
    final open = level.height - blocked;
    if (blocked >= level.height - 3 && open <= 2) chokepoints++;
  }
  for (var row = 0; row < level.height - 1; row++) {
    var blocked = 0;
    for (var col = 0; col < level.width; col++) {
      final a = row * level.width + col;
      final b = a + level.width;
      if (wallSet.contains('$a,$b')) blocked++;
    }
    final open = level.width - blocked;
    if (blocked >= level.width - 3 && open <= 2) chokepoints++;
  }
  return chokepoints;
}

int _earlyAmbiguousSegments(Level level) {
  final ordered = level.numbers.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  if (ordered.length < 2) return 0;
  final indexMap = <int, int>{};
  for (var i = 0; i < level.solution.length; i++) {
    indexMap[level.solution[i]] = i;
  }
  final wallSet = <String>{
    for (final w in level.walls)
      '${w.cell1 < w.cell2 ? w.cell1 : w.cell2},${w.cell1 > w.cell2 ? w.cell1 : w.cell2}'
  };
  int ambiguity = 0;
  final segmentLimit = ordered.length - 1 < 4 ? ordered.length - 1 : 4;
  for (var seg = 0; seg < segmentLimit; seg++) {
    final fromCell = ordered[seg].key;
    final fromIndex = indexMap[fromCell];
    if (fromIndex == null || fromIndex + 1 >= level.solution.length) continue;
    final current = level.solution[fromIndex];
    final row = current ~/ level.width;
    final col = current % level.width;
    final neighbors = <int>[];
    if (row > 0) neighbors.add(current - level.width);
    if (row < level.height - 1) neighbors.add(current + level.width);
    if (col > 0) neighbors.add(current - 1);
    if (col < level.width - 1) neighbors.add(current + 1);

    var options = 0;
    for (final n in neighbors) {
      final key = '${current < n ? current : n},${current > n ? current : n}';
      if (!wallSet.contains(key)) {
        options++;
      }
    }
    if (options >= 2) ambiguity++;
  }
  return ambiguity;
}
