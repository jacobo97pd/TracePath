import 'dart:convert';
import 'dart:math';

class EditorLevelData {
  const EditorLevelData({
    required this.width,
    required this.height,
    required this.hWalls,
    required this.vWalls,
    required this.clues,
  });

  final int width;
  final int height;
  final List<List<bool>> hWalls;
  final List<List<bool>> vWalls;
  final Map<Point<int>, int> clues;

  bool get isSquare => width == height;
}

class EditorCodec {
  const EditorCodec._();

  static EditorLevelData fromJsonString(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON root must be an object');
    }
    return fromJsonMap(decoded);
  }

  static EditorLevelData fromJsonMap(Map<String, dynamic> json) {
    final sizeValue = json['size'];
    int width;
    int height;
    if (sizeValue is num) {
      width = sizeValue.toInt();
      height = width;
    } else if (sizeValue is Map<String, dynamic>) {
      width = (sizeValue['w'] as num?)?.toInt() ?? 0;
      height = (sizeValue['h'] as num?)?.toInt() ?? 0;
    } else {
      throw const FormatException('Missing size field');
    }

    if (width < 2 || height < 2) {
      throw const FormatException('width/height must be >= 2');
    }

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

    final clues = <Point<int>, int>{};
    final rawClues = json['clues'];
    if (rawClues is List<dynamic>) {
      for (final rawClue in rawClues) {
        final clue = Map<String, dynamic>.from(rawClue as Map);
        final n = (clue['n'] as num).toInt();
        final x = (clue['x'] as num).toInt();
        final y = (clue['y'] as num).toInt();
        _ensureCellInRange(width, height, x, y);
        clues[Point<int>(x, y)] = n;
      }
    }

    final rawWalls = json['walls'];
    if (rawWalls is Map<String, dynamic>) {
      final rawH = rawWalls['h'];
      if (rawH is List<dynamic>) {
        for (final rawSegment in rawH) {
          final segment = Map<String, dynamic>.from(rawSegment as Map);
          final x = (segment['x'] as num).toInt();
          final y = (segment['y'] as num).toInt();
          final len = (segment['len'] as num).toInt();
          _ensureHorizontalSegmentInRange(width, height, x, y, len);
          for (var i = 0; i < len; i++) {
            hWalls[y][x + i] = true;
          }
        }
      }
      final rawV = rawWalls['v'];
      if (rawV is List<dynamic>) {
        for (final rawSegment in rawV) {
          final segment = Map<String, dynamic>.from(rawSegment as Map);
          final x = (segment['x'] as num).toInt();
          final y = (segment['y'] as num).toInt();
          final len = (segment['len'] as num).toInt();
          _ensureVerticalSegmentInRange(width, height, x, y, len);
          for (var i = 0; i < len; i++) {
            vWalls[y + i][x] = true;
          }
        }
      }
    }

    return EditorLevelData(
      width: width,
      height: height,
      hWalls: hWalls,
      vWalls: vWalls,
      clues: clues,
    );
  }

  static Map<String, dynamic> toJson(EditorLevelData data) {
    final clueItems = data.clues.entries.map((entry) {
      return {
        'n': entry.value,
        'x': entry.key.x,
        'y': entry.key.y,
      };
    }).toList(growable: false)
      ..sort((a, b) {
        final nA = a['n'] as int;
        final nB = b['n'] as int;
        if (nA != nB) {
          return nA.compareTo(nB);
        }
        final yA = a['y'] as int;
        final yB = b['y'] as int;
        if (yA != yB) {
          return yA.compareTo(yB);
        }
        return (a['x'] as int).compareTo(b['x'] as int);
      });

    final hSegments = <Map<String, int>>[];
    for (var y = 0; y <= data.height; y++) {
      var x = 0;
      while (x < data.width) {
        if (!data.hWalls[y][x]) {
          x++;
          continue;
        }
        final start = x;
        while (x < data.width && data.hWalls[y][x]) {
          x++;
        }
        hSegments.add({'x': start, 'y': y, 'len': x - start});
      }
    }

    final vSegments = <Map<String, int>>[];
    for (var x = 0; x <= data.width; x++) {
      var y = 0;
      while (y < data.height) {
        if (!data.vWalls[y][x]) {
          y++;
          continue;
        }
        final start = y;
        while (y < data.height && data.vWalls[y][x]) {
          y++;
        }
        vSegments.add({'x': x, 'y': start, 'len': y - start});
      }
    }

    return {
      'size': data.isSquare ? data.width : {'w': data.width, 'h': data.height},
      'clues': clueItems,
      'walls': {
        'h': hSegments,
        'v': vSegments,
      },
    };
  }

  static String toJsonString(
    EditorLevelData data, {
    bool pretty = true,
  }) {
    final json = toJson(data);
    return pretty
        ? const JsonEncoder.withIndent('  ').convert(json)
        : jsonEncode(json);
  }

  static void _ensureCellInRange(int width, int height, int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) {
      throw FormatException(
        'Clue out of bounds: ($x,$y) for width=$width height=$height',
      );
    }
  }

  static void _ensureHorizontalSegmentInRange(
    int width,
    int height,
    int x,
    int y,
    int len,
  ) {
    if (len < 1 ||
        y < 0 ||
        y > height ||
        x < 0 ||
        x >= width ||
        x + len > width) {
      throw FormatException(
        'Invalid horizontal segment x=$x y=$y len=$len width=$width height=$height',
      );
    }
  }

  static void _ensureVerticalSegmentInRange(
    int width,
    int height,
    int x,
    int y,
    int len,
  ) {
    if (len < 1 ||
        x < 0 ||
        x > width ||
        y < 0 ||
        y >= height ||
        y + len > height) {
      throw FormatException(
        'Invalid vertical segment x=$x y=$y len=$len width=$width height=$height',
      );
    }
  }
}
