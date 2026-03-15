import 'package:flutter_test/flutter_test.dart';
import 'package:zip_path_flutter/engine/level.dart';
import 'package:zip_path_flutter/game_board.dart';

Level _level({
  required int width,
  required int height,
  required Map<int, int> numbers,
}) {
  return Level(
    id: 'test',
    width: width,
    height: height,
    numbers: numbers,
    walls: const <Wall>[],
    solution: const <int>[],
    difficulty: 1,
    pack: 'test',
  );
}

void main() {
  group('GameBoardRules.computeSolved / computeLastSequentialNumber', () {
    test('1) correct order + full coverage => solved true', () {
      final level = _level(
        width: 2,
        height: 2,
        numbers: const <int, int>{0: 1, 1: 2, 2: 3},
      );
      final path = <int>[0, 1, 3, 2];

      expect(GameBoardRules.computeLastSequentialNumber(level, path), 3);
      expect(GameBoardRules.computeSolved(level, path), isTrue);
    });

    test('2) reach max early + later fill but wrong order => solved false', () {
      final level = _level(
        width: 2,
        height: 2,
        numbers: const <int, int>{0: 1, 2: 2, 1: 3},
      );
      final path = <int>[0, 1, 3, 2]; // numbers encountered: [1,3,2]

      expect(GameBoardRules.computeLastSequentialNumber(level, path), 2);
      expect(GameBoardRules.computeSolved(level, path), isFalse);
    });

    test('3) full coverage but missing number 3 in sequence => solved false', () {
      final level = _level(
        width: 2,
        height: 2,
        numbers: const <int, int>{0: 1, 1: 2, 2: 4},
      );
      final path = <int>[0, 1, 3, 2]; // encountered: [1,2,4], max=4

      expect(GameBoardRules.computeLastSequentialNumber(level, path), 2);
      expect(GameBoardRules.computeSolved(level, path), isFalse);
    });

    test('4) duplicated cell => solved false', () {
      final level = _level(
        width: 2,
        height: 2,
        numbers: const <int, int>{0: 1, 1: 2},
      );
      final path = <int>[0, 1, 1, 2];

      expect(path.toSet().length == path.length, isFalse);
      expect(GameBoardRules.computeSolved(level, path), isFalse);
    });

    test('5) path empty => solved false', () {
      final level = _level(
        width: 2,
        height: 2,
        numbers: const <int, int>{0: 1, 1: 2},
      );
      final path = <int>[];

      expect(GameBoardRules.computeLastSequentialNumber(level, path), 0);
      expect(GameBoardRules.computeSolved(level, path), isFalse);
    });

    test('1) maxNumber early allowed, final path ending elsewhere => solved false', () {
      final level = _level(
        width: 2,
        height: 2,
        numbers: const <int, int>{0: 1, 1: 3, 2: 2},
      );
      final wallEdges = <String>{};
      final canStepOnMaxEarly = GameBoardRules.canMoveToCell(
        level,
        <int>[0],
        wallEdges,
        1,
      );
      final path = <int>[0, 1, 3, 2]; // max=3 visited early, path.last != endCell(1)

      expect(canStepOnMaxEarly, isTrue);
      expect(GameBoardRules.computeSolved(level, path), isFalse);
    });

    test('2) early max then rewind, finish with endCell last and sequence => solved true', () {
      final level = _level(
        width: 2,
        height: 2,
        numbers: const <int, int>{0: 1, 2: 2, 1: 3},
      );
      final finalPath = <int>[0, 2, 3, 1];

      expect(GameBoardRules.computeSolved(level, finalPath), isTrue);
    });

    test('3) correct full path with endCell last => solved true', () {
      final level = _level(
        width: 2,
        height: 2,
        numbers: const <int, int>{0: 1, 1: 2, 2: 3},
      );
      final path = <int>[0, 1, 3, 2];

      expect(GameBoardRules.computeSolved(level, path), isTrue);
    });

    test('4) full coverage but numbers out of order => solved false', () {
      final level = _level(
        width: 2,
        height: 2,
        numbers: const <int, int>{0: 1, 2: 2, 1: 3},
      );
      final path = <int>[0, 1, 2, 3]; // encountered [1,3,2], full coverage

      expect(GameBoardRules.computeLastSequentialNumber(level, path), 2);
      expect(GameBoardRules.computeSolved(level, path), isFalse);
    });
  });
}
