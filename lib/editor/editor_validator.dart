import 'dart:math';

import 'editor_codec.dart';

class EditorValidator {
  const EditorValidator._();

  static List<String> validate(EditorLevelData data) {
    final errors = <String>[];
    final width = data.width;
    final height = data.height;

    if (width < 2 || height < 2) {
      errors.add('width/height must be >= 2');
    }

    if (data.hWalls.length != height + 1) {
      errors.add('hWalls must have ${height + 1} rows');
    }
    for (var y = 0; y < data.hWalls.length; y++) {
      if (data.hWalls[y].length != width) {
        errors.add('hWalls[$y] must have $width columns');
      }
    }

    if (data.vWalls.length != height) {
      errors.add('vWalls must have $height rows');
    }
    for (var y = 0; y < data.vWalls.length; y++) {
      if (data.vWalls[y].length != width + 1) {
        errors.add('vWalls[$y] must have ${width + 1} columns');
      }
    }

    final seenNumbers = <int>{};
    for (final entry in data.clues.entries) {
      final point = entry.key;
      final number = entry.value;
      if (point.x < 0 || point.x >= width || point.y < 0 || point.y >= height) {
        errors.add('Clue out of bounds at (${point.x}, ${point.y})');
      }
      if (number <= 0) {
        errors.add('Clue number must be > 0 at (${point.x}, ${point.y})');
      }
      if (!seenNumbers.add(number)) {
        errors.add('Duplicated clue number: $number');
      }
    }

    final encoded = EditorCodec.toJson(data);
    final walls = encoded['walls'] as Map<String, dynamic>;
    for (final segment in (walls['h'] as List<dynamic>)) {
      final map = Map<String, dynamic>.from(segment as Map);
      if ((map['len'] as int) <= 0) {
        errors.add('Horizontal segment with len <= 0');
      }
    }
    for (final segment in (walls['v'] as List<dynamic>)) {
      final map = Map<String, dynamic>.from(segment as Map);
      if ((map['len'] as int) <= 0) {
        errors.add('Vertical segment with len <= 0');
      }
    }

    return errors;
  }

  static int suggestNextClueNumber(Map<Point<int>, int> clues) {
    if (clues.isEmpty) {
      return 1;
    }
    return clues.values.reduce(max) + 1;
  }
}
