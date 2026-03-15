import 'dart:math' as math;

import 'package:crypto/crypto.dart';

import '../engine/level.dart';
import '../engine/level_generator.dart' show countSolutions;
import 'batch_models.dart';

class CurationValidator {
  const CurationValidator();

  ValidationResult validate(CurationBatchItem item) {
    final clues = List<CurationClue>.from(item.clues)
      ..sort((a, b) => a.n.compareTo(b.n));
    if (clues.isEmpty) {
      return const ValidationResult(
        valid: false,
        reason: 'No clues present',
        solutionCount: 0,
        solution: <int>[],
        fingerprint: null,
      );
    }

    if (clues.any((c) => c.n <= 0)) {
      return const ValidationResult(
        valid: false,
        reason: 'Needs numbering',
        solutionCount: 0,
        solution: <int>[],
        fingerprint: null,
      );
    }

    for (var i = 0; i < clues.length; i++) {
      if (clues[i].n != i + 1) {
        return const ValidationResult(
          valid: false,
          reason: 'Clues must be consecutive 1..N',
          solutionCount: 0,
          solution: <int>[],
          fingerprint: null,
        );
      }
    }

    final usedCells = <int>{};
    final numbers = <int, int>{};
    for (final clue in clues) {
      if (clue.x < 0 ||
          clue.y < 0 ||
          clue.x >= item.gridSize ||
          clue.y >= item.gridSize) {
        return const ValidationResult(
          valid: false,
          reason: 'Clue outside board bounds',
          solutionCount: 0,
          solution: <int>[],
          fingerprint: null,
        );
      }
      final cell = clue.y * item.gridSize + clue.x;
      if (!usedCells.add(cell)) {
        return const ValidationResult(
          valid: false,
          reason: 'Duplicate clue cell',
          solutionCount: 0,
          solution: <int>[],
          fingerprint: null,
        );
      }
      numbers[cell] = clue.n;
    }

    final level = Level(
      id: item.id,
      width: item.gridSize,
      height: item.gridSize,
      numbers: numbers,
      walls: _normalizeWalls(item.walls),
      solution: const <int>[],
      difficulty: 5,
      pack: 'all',
    );

    final solution = _findFirstSolution(level);
    if (solution == null) {
      return const ValidationResult(
        valid: false,
        reason: 'No valid solution found',
        solutionCount: 0,
        solution: <int>[],
        fingerprint: null,
      );
    }

    final count = countSolutions(
      Level(
        id: level.id,
        width: level.width,
        height: level.height,
        numbers: level.numbers,
        walls: level.walls,
        solution: solution,
        difficulty: level.difficulty,
        pack: level.pack,
      ),
      maxSolutions: 2,
    );
    if (count != 1) {
      return ValidationResult(
        valid: false,
        reason: 'Uniqueness failed (solutions=$count)',
        solutionCount: count,
        solution: solution,
        fingerprint: null,
      );
    }

    if (!_passesEarlySeparation(clues, item.gridSize)) {
      return ValidationResult(
        valid: false,
        reason: 'Early clues 1..4 too close',
        solutionCount: count,
        solution: solution,
        fingerprint: _fingerprint(
          gridSize: item.gridSize,
          clues: clues,
          walls: level.walls,
        ),
      );
    }

    return ValidationResult(
      valid: true,
      reason: 'Valid',
      solutionCount: count,
      solution: solution,
      fingerprint: _fingerprint(
        gridSize: item.gridSize,
        clues: clues,
        walls: level.walls,
      ),
    );
  }

  List<Wall> _normalizeWalls(List<Wall> walls) {
    final norm = walls
        .map((w) => Wall(
              cell1: math.min(w.cell1, w.cell2),
              cell2: math.max(w.cell1, w.cell2),
            ))
        .toList(growable: false);
    final dedup = <String, Wall>{};
    for (final w in norm) {
      dedup['${w.cell1}:${w.cell2}'] = w;
    }
    final list = dedup.values.toList(growable: false)
      ..sort((a, b) {
        final c = a.cell1.compareTo(b.cell1);
        if (c != 0) return c;
        return a.cell2.compareTo(b.cell2);
      });
    return list;
  }

  bool _passesEarlySeparation(List<CurationClue> clues, int size) {
    if (clues.length < 4) {
      return true;
    }
    final d = size >= 9 ? 7 : 5;
    int dist(CurationClue a, CurationClue b) =>
        (a.x - b.x).abs() + (a.y - b.y).abs();
    final c1 = clues[0];
    final c2 = clues[1];
    final c3 = clues[2];
    final c4 = clues[3];
    return dist(c1, c2) >= d &&
        dist(c2, c3) >= d &&
        dist(c3, c4) >= d &&
        dist(c1, c3) >= d - 1 &&
        dist(c2, c4) >= d - 1;
  }

  String _fingerprint({
    required int gridSize,
    required List<CurationClue> clues,
    required List<Wall> walls,
  }) {
    final cluePart = clues.map((c) => '${c.n}:${c.x}:${c.y}').join('|');
    final wallPart = walls.map((w) => '${w.cell1}:${w.cell2}').join('|');
    final canonical = 's=$gridSize;$cluePart;$wallPart';
    return sha256.convert(canonical.codeUnits).toString();
  }

  List<int>? _findFirstSolution(Level level) {
    final totalCells = level.width * level.height;
    if (level.numbers.isEmpty) {
      return null;
    }
    int? startCell;
    int? endCell;
    final maxNumber = level.numbers.values.reduce(math.max);
    for (final entry in level.numbers.entries) {
      if (entry.value == 1) startCell = entry.key;
      if (entry.value == maxNumber) endCell = entry.key;
    }
    if (startCell == null || endCell == null) return null;

    final adjacency = _buildAdjacency(level.width, level.height, level.walls);
    final visited = List<bool>.filled(totalCells, false);
    final path = <int>[];
    List<int>? solution;

    void dfs(int current, int expected) {
      if (solution != null) return;
      visited[current] = true;
      path.add(current);

      if (path.length == totalCells) {
        if (current == endCell && expected > maxNumber) {
          solution = List<int>.from(path);
        }
      } else {
        final nexts = List<int>.from(adjacency[current] ?? const <int>[])
          ..sort((a, b) {
            final da = _degree(a, adjacency, visited);
            final db = _degree(b, adjacency, visited);
            return da.compareTo(db);
          });
        for (final next in nexts) {
          if (visited[next]) continue;
          if (next == endCell && path.length != totalCells - 1) continue;
          final number = level.numbers[next];
          if (number != null && number != expected) continue;
          final nextExpected = number == expected ? expected + 1 : expected;
          dfs(next, nextExpected);
          if (solution != null) break;
        }
      }

      path.removeLast();
      visited[current] = false;
    }

    dfs(startCell, 2);
    return solution;
  }

  int _degree(int cell, Map<int, List<int>> adjacency, List<bool> visited) {
    var d = 0;
    for (final n in adjacency[cell] ?? const <int>[]) {
      if (!visited[n]) d++;
    }
    return d;
  }

  Map<int, List<int>> _buildAdjacency(int width, int height, List<Wall> walls) {
    final blocked = <String>{};
    for (final wall in walls) {
      final a = math.min(wall.cell1, wall.cell2);
      final b = math.max(wall.cell1, wall.cell2);
      blocked.add('$a:$b');
    }

    bool blockedEdge(int a, int b) {
      final x = math.min(a, b);
      final y = math.max(a, b);
      return blocked.contains('$x:$y');
    }

    final adjacency = <int, List<int>>{};
    final total = width * height;
    for (var c = 0; c < total; c++) {
      final x = c % width;
      final y = c ~/ width;
      final list = <int>[];
      void add(int nx, int ny) {
        if (nx < 0 || ny < 0 || nx >= width || ny >= height) return;
        final n = ny * width + nx;
        if (!blockedEdge(c, n)) {
          list.add(n);
        }
      }

      add(x - 1, y);
      add(x + 1, y);
      add(x, y - 1);
      add(x, y + 1);
      adjacency[c] = list;
    }
    return adjacency;
  }
}
