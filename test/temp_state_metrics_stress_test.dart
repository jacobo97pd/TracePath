import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zip_path_flutter/app_data.dart';
import 'package:zip_path_flutter/engine/level_generator.dart';
import 'package:zip_path_flutter/engine/seed_random.dart';

class _ModeRunConfig {
  const _ModeRunConfig({
    required this.packId,
    required this.size,
    required this.difficulty,
  });

  final String packId;
  final int size;
  final int difficulty;
}

void main() {
  test('state-metric stress', () async {
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {};
    const samples = 50;
    const rawGeneratorSamples = 1;
    const configs = <_ModeRunConfig>[
      _ModeRunConfig(packId: 'campaign', size: 6, difficulty: 3),
      _ModeRunConfig(packId: 'daily', size: 7, difficulty: 4),
      _ModeRunConfig(packId: 'endless', size: 8, difficulty: 4),
      _ModeRunConfig(packId: 'architect', size: 8, difficulty: 5),
      _ModeRunConfig(packId: 'expert', size: 9, difficulty: 5),
    ];

    final reasonRegex = RegExp(r'\[reason=([a-zA-Z]+)');
    try {
      // ignore: avoid_print
      print('state-metric stress: $samples seeds per mode');
      for (final config in configs) {
        var successes = 0;
        var totalMs = 0;
        final failReasons = <String, int>{};
        for (var i = 0; i < rawGeneratorSamples; i++) {
          final seed =
              hashString('${config.packId}-${config.size}-${i * 7919}');
          final watch = Stopwatch()..start();
          try {
            generateLevel(
              config.size,
              config.size,
              config.difficulty,
              seed,
              config.packId,
            );
            successes++;
          } on GenerationFailureException catch (e) {
            final match = reasonRegex.firstMatch(e.message);
            final reason = match?.group(1) ?? 'unknown';
            failReasons[reason] = (failReasons[reason] ?? 0) + 1;
          } finally {
            watch.stop();
            totalMs += watch.elapsedMilliseconds;
          }
        }

        final successRate = successes / rawGeneratorSamples;
        final avgMs = totalMs / rawGeneratorSamples;
        final topReasons = failReasons.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topSummary =
            topReasons.take(3).map((e) => '${e.key}:${e.value}').join(', ');

        // ignore: avoid_print
        print(
          '[Stress][$rawGeneratorSamples] ${config.packId} '
          'success=${(successRate * 100).toStringAsFixed(1)}% '
          'avgMs=${avgMs.toStringAsFixed(1)} '
          'fails=${rawGeneratorSamples - successes} '
          'top=${topSummary.isEmpty ? '-' : topSummary}',
        );
      }

      var dailyLoaderOk = 0;
      final loaderWatch = Stopwatch()..start();
      var loaderTotalMs = 0;
      for (var i = 0; i < samples; i++) {
        final sw = Stopwatch()..start();
        try {
          final level = await loadDailyLevelAsync(retryNonce: i);
          if (level.numbers.isNotEmpty) {
            dailyLoaderOk++;
          }
        } catch (_) {}
        sw.stop();
        loaderTotalMs += sw.elapsedMilliseconds;
      }
      loaderWatch.stop();
      final loaderAvg = loaderTotalMs / samples;
      // ignore: avoid_print
      print(
        '[Stress][$samples] daily-loader success=$dailyLoaderOk/$samples '
        'avgMs=${loaderAvg.toStringAsFixed(1)} totalMs=${loaderWatch.elapsedMilliseconds}',
      );
      expect(dailyLoaderOk / samples, greaterThanOrEqualTo(0.9));
      expect(loaderAvg, lessThanOrEqualTo(2500));
    } finally {
      debugPrint = originalDebugPrint;
    }
  }, timeout: const Timeout(Duration(minutes: 25)));
}
