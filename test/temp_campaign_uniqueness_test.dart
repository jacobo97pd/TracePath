import 'package:flutter_test/flutter_test.dart';
import 'package:zip_path_flutter/app_data.dart';

void main() {
  test('campaign fingerprints avoid duplicates across 200 levels', () {
    final seen = <String>{};
    var duplicates = 0;

    for (var levelIndex = 1; levelIndex <= 200; levelIndex++) {
      final level = loadCampaignLevel('classic', levelIndex, retryNonce: 0);
      final numbers = level.numbers.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final walls = level.walls.map((w) {
        final a = w.cell1 < w.cell2 ? w.cell1 : w.cell2;
        final b = w.cell1 > w.cell2 ? w.cell1 : w.cell2;
        return '$a-$b';
      }).toList()
        ..sort();
      final key =
          '${level.width}x${level.height}|${numbers.map((e) => '${e.value}@${e.key}').join(",")}|${walls.join(",")}';
      if (!seen.add(key)) {
        duplicates++;
      }
    }

    expect(duplicates, equals(0));
  }, timeout: const Timeout(Duration(minutes: 20)));
}
