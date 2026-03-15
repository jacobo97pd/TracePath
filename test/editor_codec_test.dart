import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zip_path_flutter/editor/editor_codec.dart';
import 'package:zip_path_flutter/editor/editor_validator.dart';

void main() {
  group('EditorCodec', () {
    test('roundtrip preserves clues and walls (square)', () {
      const width = 7;
      const height = 7;
      final hWalls = List.generate(
        height + 1,
        (_) => List<bool>.filled(width, false),
        growable: false,
      );
      final vWalls = List.generate(
        height,
        (_) => List<bool>.filled(width + 1, false),
        growable: false,
      );

      hWalls[0][0] = true;
      hWalls[0][1] = true;
      hWalls[4][2] = true;
      hWalls[4][3] = true;
      hWalls[4][4] = true;
      vWalls[1][0] = true;
      vWalls[2][0] = true;
      vWalls[2][5] = true;

      final source = EditorLevelData(
        width: width,
        height: height,
        hWalls: hWalls,
        vWalls: vWalls,
        clues: {
          const Point<int>(1, 1): 1,
          const Point<int>(5, 3): 2,
          const Point<int>(6, 6): 3,
        },
      );

      final encoded = EditorCodec.toJsonString(source);
      final decoded = EditorCodec.fromJsonString(encoded);

      expect(decoded.width, source.width);
      expect(decoded.height, source.height);
      expect(decoded.clues, source.clues);
      expect(decoded.hWalls, source.hWalls);
      expect(decoded.vWalls, source.vWalls);
    });

    test('roundtrip preserves clues and walls (rectangular)', () {
      const width = 6;
      const height = 7;
      final source = EditorLevelData(
        width: width,
        height: height,
        hWalls: List.generate(
          height + 1,
          (y) => List<bool>.generate(width, (x) => y == 2 && x >= 1 && x <= 3),
          growable: false,
        ),
        vWalls: List.generate(
          height,
          (y) => List<bool>.generate(width + 1, (x) => x == 4 && y <= 2),
          growable: false,
        ),
        clues: {
          const Point<int>(0, 0): 1,
          const Point<int>(5, 6): 2,
        },
      );

      final encoded = EditorCodec.toJson(source);
      expect(encoded['size'], {'w': width, 'h': height});

      final decoded =
          EditorCodec.fromJsonString(EditorCodec.toJsonString(source));
      expect(decoded.width, width);
      expect(decoded.height, height);
      expect(decoded.clues, source.clues);
      expect(decoded.hWalls, source.hWalls);
      expect(decoded.vWalls, source.vWalls);
    });

    test('loads canonical segments correctly', () {
      const raw = '''
{
  "size": {"w": 6, "h": 7},
  "clues": [{"n":1,"x":2,"y":3}],
  "walls": {
    "h": [{"x":1,"y":2,"len":3}],
    "v": [{"x":4,"y":0,"len":2}]
  }
}
''';
      final level = EditorCodec.fromJsonString(raw);

      expect(level.hWalls[2][1], isTrue);
      expect(level.hWalls[2][2], isTrue);
      expect(level.hWalls[2][3], isTrue);
      expect(level.vWalls[0][4], isTrue);
      expect(level.vWalls[1][4], isTrue);
      expect(level.clues[const Point<int>(2, 3)], 1);
    });
  });

  group('EditorValidator', () {
    test('detects invalid clue coordinates', () {
      const width = 5;
      const height = 6;
      final level = EditorLevelData(
        width: width,
        height: height,
        hWalls: List.generate(
          height + 1,
          (_) => List<bool>.filled(width, false),
          growable: false,
        ),
        vWalls: List.generate(
          height,
          (_) => List<bool>.filled(width + 1, false),
          growable: false,
        ),
        clues: {
          const Point<int>(7, 1): 1,
        },
      );

      final errors = EditorValidator.validate(level);
      expect(errors.any((e) => e.contains('out of bounds')), isTrue);
    });
  });
}
