import 'level.dart';
import 'seed_random.dart';

class _SolveResult {
  const _SolveResult({required this.count, required this.solutions});

  final int count;
  final List<List<int>> solutions;
}

class _PathCell {
  const _PathCell({required this.row, required this.col, required this.index});

  final int row;
  final int col;
  final int index;
}

const int _kGridSize = 6;

Level generateLinkedinJsLevel({
  required int seed,
  required int levelIndex,
}) {
  const totalCells = _kGridSize * _kGridSize;
  const maxAttempts = 50;

  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final attemptRng = createRng(seed ^ ((attempt + 1) * 0x9E3779B9));
    final fullPath = _generateHamiltonianPath(attemptRng);
    if (fullPath == null) {
      continue;
    }

    final revealedPositions = <int>{};
    const intermediateCount = 6; // 6x6 -> 8 clues total like worker.js
    final cluePositions = _placeCluesSmartly(fullPath, intermediateCount + 2);
    revealedPositions.addAll(cluePositions);

    Map<int, int> numbers =
        _createNumbersFromRevealed(fullPath, revealedPositions);
    var result = _solvePuzzle(numbers, maxSolutions: 5);

    var fixAttempts = 0;
    const maxFixAttempts = 15;

    while (result.count > 1 && fixAttempts < maxFixAttempts) {
      final sol1 = fullPath.map((e) => e.index).toList(growable: false);
      List<int>? sol2;
      for (final candidate in result.solutions) {
        if (!_samePath(candidate, sol1)) {
          sol2 = candidate;
          break;
        }
      }
      sol2 ??= result.solutions.isNotEmpty ? result.solutions.first : null;
      if (sol2 == null) {
        break;
      }

      var diffPosition = -1;
      for (var i = 0; i < totalCells; i++) {
        if (sol1[i] != sol2[i]) {
          diffPosition = i;
          break;
        }
      }

      if (diffPosition != -1) {
        revealedPositions.add(diffPosition);
        numbers = _createNumbersFromRevealed(fullPath, revealedPositions);
      }

      result = _solvePuzzle(numbers, maxSolutions: 5);
      fixAttempts++;
    }

    if (result.count > 1 && fixAttempts >= maxFixAttempts) {
      revealedPositions.add(totalCells ~/ 3);
      revealedPositions.add((totalCells * 2) ~/ 3);
      numbers = _createNumbersFromRevealed(fullPath, revealedPositions);
      result = _solvePuzzle(numbers, maxSolutions: 5);
    }

    if (result.count == 1 && result.solutions.isNotEmpty) {
      return Level(
        id: 'linkedin-js-$levelIndex',
        width: _kGridSize,
        height: _kGridSize,
        numbers: numbers,
        walls: const <Wall>[],
        solution: List<int>.from(result.solutions.first),
        difficulty: 3,
        pack: 'linkedin_js',
      );
    }
  }

  throw Exception('Could not generate LinkedIn JS level for seed=$seed');
}

bool _samePath(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

Map<int, int> _createNumbersFromRevealed(
  List<_PathCell> path,
  Set<int> revealedPositions,
) {
  final sortedPositions = revealedPositions.toList()..sort();
  final numbers = <int, int>{};
  for (var i = 0; i < sortedPositions.length; i++) {
    final pathPos = sortedPositions[i];
    numbers[path[pathPos].index] = i + 1;
  }
  return numbers;
}

List<int> _placeCluesSmartly(List<_PathCell> path, int count) {
  final clues = <int>[0, path.length - 1];

  while (clues.length < count) {
    var bestIndex = -1;
    var bestScore = -1e9;

    for (var i = 1; i < path.length - 1; i++) {
      if (clues.contains(i)) {
        continue;
      }

      var minManhattan = 1 << 30;
      var minPathDist = 1 << 30;

      for (final clueIdx in clues) {
        final clueCell = path[clueIdx];
        final candidate = path[i];

        final manhattan = (candidate.row - clueCell.row).abs() +
            (candidate.col - clueCell.col).abs();
        final pathDist = (i - clueIdx).abs();

        if (manhattan < minManhattan) {
          minManhattan = manhattan;
        }
        if (pathDist < minPathDist) {
          minPathDist = pathDist;
        }
      }

      final score = minManhattan + (minPathDist / path.length) * 0.15;
      if (score > bestScore) {
        bestScore = score;
        bestIndex = i;
      }
    }

    if (bestIndex == -1) {
      break;
    }
    clues.add(bestIndex);
  }

  return clues;
}

List<_PathCell>? _generateHamiltonianPath(Rng rng) {
  const total = _kGridSize * _kGridSize;
  final path = <int>[];
  final visited = List<bool>.filled(total, false);

  List<int> neighbors(int idx) {
    final row = idx ~/ _kGridSize;
    final col = idx % _kGridSize;
    final result = <int>[];
    const dirs = <List<int>>[
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
    ];
    for (final dir in dirs) {
      final r = row + dir[0];
      final c = col + dir[1];
      if (r >= 0 && r < _kGridSize && c >= 0 && c < _kGridSize) {
        result.add(r * _kGridSize + c);
      }
    }
    shuffle(result, rng);
    return result;
  }

  bool backtrack(int current) {
    path.add(current);
    visited[current] = true;

    if (path.length == total) {
      return true;
    }

    final nextNeighbors = neighbors(current);
    nextNeighbors.sort((a, b) {
      final aCount = neighbors(a).where((n) => !visited[n]).length;
      final bCount = neighbors(b).where((n) => !visited[n]).length;
      return aCount.compareTo(bCount);
    });

    for (final n in nextNeighbors) {
      if (!visited[n] && backtrack(n)) {
        return true;
      }
    }

    path.removeLast();
    visited[current] = false;
    return false;
  }

  final start = (rng() * total).floor();
  if (!backtrack(start)) {
    return null;
  }

  return path
      .map((idx) => _PathCell(
            row: idx ~/ _kGridSize,
            col: idx % _kGridSize,
            index: idx,
          ))
      .toList(growable: false);
}

_SolveResult _solvePuzzle(Map<int, int> numbers, {required int maxSolutions}) {
  const total = _kGridSize * _kGridSize;
  var count = 0;
  final solutions = <List<int>>[];

  int? numberAt(int idx) => numbers[idx];

  bool isAdjacent(int a, int b) {
    final rowA = a ~/ _kGridSize;
    final colA = a % _kGridSize;
    final rowB = b ~/ _kGridSize;
    final colB = b % _kGridSize;
    final dr = (rowA - rowB).abs();
    final dc = (colA - colB).abs();
    return (dr == 1 && dc == 0) || (dr == 0 && dc == 1);
  }

  void solve(List<int> path, List<bool> visited, int nextNum) {
    if (count >= maxSolutions) {
      return;
    }

    if (path.length == total) {
      count++;
      solutions.add(List<int>.from(path));
      return;
    }

    final last = path.last;

    for (var idx = 0; idx < total; idx++) {
      if (visited[idx]) {
        continue;
      }
      if (!isAdjacent(last, idx)) {
        continue;
      }

      final cellNum = numberAt(idx);
      if (cellNum != null && cellNum != nextNum) {
        continue;
      }

      visited[idx] = true;
      path.add(idx);
      solve(path, visited, cellNum == nextNum ? nextNum + 1 : nextNum);
      path.removeLast();
      visited[idx] = false;
    }
  }

  int? start;
  numbers.forEach((cell, n) {
    if (n == 1) {
      start = cell;
    }
  });

  if (start == null) {
    return const _SolveResult(count: 0, solutions: <List<int>>[]);
  }

  final visited = List<bool>.filled(total, false);
  visited[start!] = true;
  solve(<int>[start!], visited, 2);
  return _SolveResult(count: count, solutions: solutions);
}
