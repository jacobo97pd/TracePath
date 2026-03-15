import 'package:flutter_test/flutter_test.dart';
import 'package:zip_path_flutter/engine/level_generator.dart';
import 'package:zip_path_flutter/engine/seed_random.dart';

void main() {
  test('daily diagnostics', () {
    const samples = 20;
    final reasons = <String, int>{};
    var ok = 0;
    var totalMs = 0;
    final regex = RegExp(r'\[reason=([^\] ]+)');
    for (var i = 0; i < samples; i++) {
      final seed = hashString('daily-7-$i');
      final sw = Stopwatch()..start();
      try {
        generateLevel(7, 7, 4, seed, 'daily');
        ok++;
      } on GenerationFailureException catch (e) {
        final m = regex.firstMatch(e.message);
        final reason = m?.group(1) ?? 'unknown';
        reasons[reason] = (reasons[reason] ?? 0) + 1;
      } finally {
        sw.stop();
        totalMs += sw.elapsedMilliseconds;
      }
    }
    final sorted = reasons.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // ignore: avoid_print
    print(
      '[DailyDiag] ok=$ok/$samples '
      'avgMs=${(totalMs / samples).toStringAsFixed(1)} '
      'reasons=${sorted.map((e) => '${e.key}:${e.value}').join(', ')}',
    );
  });
}
