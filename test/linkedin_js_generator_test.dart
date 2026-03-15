import 'package:flutter_test/flutter_test.dart';
import 'package:zip_path_flutter/engine/linkedin_js_generator.dart';
import 'package:zip_path_flutter/engine/level_generator.dart';

void main() {
  test('linkedin js generator creates solvable unique level', () {
    final level = generateLinkedinJsLevel(seed: 123456, levelIndex: 1);

    expect(level.width, 6);
    expect(level.height, 6);
    expect(level.walls, isEmpty);
    expect(level.numbers.values.contains(1), isTrue);

    final maxNumber = level.numbers.values.reduce((a, b) => a > b ? a : b);
    for (var n = 1; n <= maxNumber; n++) {
      expect(level.numbers.values.contains(n), isTrue);
    }

    final solutions = countSolutions(level, maxSolutions: 2);
    expect(solutions, 1);
  });
}
