import 'package:flutter/foundation.dart';

import 'level.dart';
import 'seed_random.dart';

typedef PackResolver = PackDef? Function(String packId);
const bool _enableGenerationDebugLogs = false;

enum GenerationFailReason {
  noHamiltonianPath,
  disconnectedStructure,
  overconstrainedStructure,
  incompleteClues,
  clueOrderInvalid,
  consecutiveJumpFail,
  localClusterFail,
  insufficientChokepoints,
  chamberDensityTooLow,
  centralCompressionLow,
  branchingTooLow,
  conflictZonesTooLow,
  degreeOneRunTooLong,
  dispersionTooLow,
  alternativeRouteFail,
  tooLinear,
  delayedTrapFail,
  ercFail,
  casFail,
  earlySeparationFail,
  symmetryRisk,
  extremeValidationFail,
  uniquenessFail,
}

class StrictnessProfile {
  const StrictnessProfile({
    required this.id,
    required this.relaxation,
    required this.straightRunCap,
    required this.requireDelayedTrap,
    required this.requireAlternativeRoute,
    required this.minDispersionFactor,
  });

  final String id;
  final int relaxation;
  final int straightRunCap;
  final bool requireDelayedTrap;
  final bool requireAlternativeRoute;
  final double minDispersionFactor;
}

const List<StrictnessProfile> _strictnessProfiles = <StrictnessProfile>[
  StrictnessProfile(
    id: 'S0',
    relaxation: 0,
    straightRunCap: 3,
    requireDelayedTrap: true,
    requireAlternativeRoute: true,
    minDispersionFactor: 1.0,
  ),
  StrictnessProfile(
    id: 'S1',
    relaxation: 1,
    straightRunCap: 4,
    requireDelayedTrap: true,
    requireAlternativeRoute: true,
    minDispersionFactor: 0.92,
  ),
  StrictnessProfile(
    id: 'S2',
    relaxation: 2,
    straightRunCap: 4,
    requireDelayedTrap: true,
    requireAlternativeRoute: true,
    minDispersionFactor: 0.84,
  ),
  StrictnessProfile(
    id: 'S3',
    relaxation: 3,
    straightRunCap: 5,
    requireDelayedTrap: false,
    requireAlternativeRoute: true,
    minDispersionFactor: 0.74,
  ),
  StrictnessProfile(
    id: 'S4',
    relaxation: 4,
    straightRunCap: 5,
    requireDelayedTrap: false,
    requireAlternativeRoute: false,
    minDispersionFactor: 0.64,
  ),
];

class GenerationFailureException implements Exception {
  GenerationFailureException(this.message);
  final String message;

  @override
  String toString() => message;
}

enum _ModeTier { campaign, hard, veryHard }

enum Mode { campaign, daily, other }

enum Tier { low, mid, high }

class _ModeValidationPolicy {
  const _ModeValidationPolicy({
    required this.enforceErc,
    required this.enforceCas,
    required this.ercMinScore,
    required this.casMinScore,
    required this.casMinEarlyAmbiguousSegments,
    required this.casRequireFirstTwoEarlySegments,
    required this.uniquenessMandatory,
    required this.allowNearUnique,
    required this.maxTinyComponentsPerCheckpoint,
    required this.requireMidSplitOrNarrow,
    required this.casEarlyOnly,
  });

  final bool enforceErc;
  final bool enforceCas;
  final double ercMinScore;
  final double casMinScore;
  final int casMinEarlyAmbiguousSegments;
  final bool casRequireFirstTwoEarlySegments;
  final bool uniquenessMandatory;
  final bool allowNearUnique;
  final int maxTinyComponentsPerCheckpoint;
  final bool requireMidSplitOrNarrow;
  final bool casEarlyOnly;
}

class _ErcCheckpointStats {
  const _ErcCheckpointStats({
    required this.prefixRatio,
    required this.components,
    required this.maxComponentSize,
    required this.mediumLowFrontierCount,
    required this.tinyComponents,
    required this.narrowEntries,
    required this.frontierRatio,
    required this.pressure,
  });

  final double prefixRatio;
  final int components;
  final int maxComponentSize;
  final int mediumLowFrontierCount;
  final int tinyComponents;
  final int narrowEntries;
  final double frontierRatio;
  final double pressure;
}

class _ErcResult {
  const _ErcResult({
    required this.score,
    required this.checkpoints,
  });

  final double score;
  final List<_ErcCheckpointStats> checkpoints;
}

class _CasSegmentStats {
  const _CasSegmentStats({
    required this.segmentNumber,
    required this.maxBranching,
    required this.plausibleAlternatives,
    required this.segmentScore,
  });

  final int segmentNumber;
  final int maxBranching;
  final int plausibleAlternatives;
  final double segmentScore;
}

class _CasResult {
  const _CasResult({
    required this.score,
    required this.earlyAmbiguousSegments,
    required this.earlyFirstTwoAmbiguousSegments,
    required this.segmentStats,
  });

  final double score;
  final int earlyAmbiguousSegments;
  final int earlyFirstTwoAmbiguousSegments;
  final List<_CasSegmentStats> segmentStats;
}

enum _BlueprintFamily {
  comb,
  nestedChambers,
  ringEnclosure,
  multiChoke,
}

bool shouldHaveWalls(int seed) {
  // Deterministic 35% wall distribution per seed.
  final mixed = (seed * 1103515245 + 12345) & 0x7fffffff;
  return (mixed % 100) < 35;
}

List<int> _getNeighbors(int idx, int width, int height) {
  final row = idx ~/ width;
  final col = idx % width;
  final neighbors = <int>[];
  if (row > 0) neighbors.add(idx - width);
  if (row < height - 1) neighbors.add(idx + width);
  if (col > 0) neighbors.add(idx - 1);
  if (col < width - 1) neighbors.add(idx + 1);
  return neighbors;
}

List<int>? _warnsdorffPath(int width, int height, int start, Rng rng) {
  final total = width * height;
  final visited = List<int>.filled(total, 0);
  final path = <int>[start];
  visited[start] = 1;

  while (path.length < total) {
    final current = path.last;
    final neighbors = _getNeighbors(current, width, height)
        .where((n) => visited[n] == 0)
        .toList();

    if (neighbors.isEmpty) return null;

    final degrees = neighbors
        .map((n) => _getNeighbors(n, width, height)
            .where((nn) => visited[nn] == 0)
            .length)
        .toList();

    var minDeg = 5;
    for (final d in degrees) {
      if (d < minDeg) minDeg = d;
    }

    final candidates = <int>[];
    for (var i = 0; i < neighbors.length; i++) {
      if (degrees[i] == minDeg) candidates.add(neighbors[i]);
    }

    final next = candidates[(rng() * candidates.length).floor()];
    visited[next] = 1;
    path.add(next);
  }

  return path;
}

List<List<int>> _adjacencyListFromWalls(
    int width, int height, List<Wall> walls) {
  final adjacencyMap = _buildAdjacency(width, height, walls);
  final total = width * height;
  return List<List<int>>.generate(
    total,
    (index) => List<int>.from(adjacencyMap[index] ?? const <int>[]),
  );
}

List<int>? _generateHamiltonianPathInGraph(
    int width, int height, List<Wall> walls, Rng rng,
    {int searchBudget = 70000}) {
  final total = width * height;
  final adjacency = _adjacencyListFromWalls(width, height, walls);
  final visited = List<bool>.filled(total, false);
  final path = <int>[];

  final center = ((height ~/ 2) * width) + (width ~/ 2);
  final starts = List<int>.generate(total, (i) => i);
  starts.sort((a, b) {
    final aDeg = adjacency[a].length;
    final bDeg = adjacency[b].length;
    if (aDeg != bDeg) {
      return bDeg.compareTo(aDeg);
    }
    final da = _manhattanCellDistance(a, center, width);
    final db = _manhattanCellDistance(b, center, width);
    return da.compareTo(db);
  });
  final maxStarts = total < 20 ? total : 16;
  var budget = searchBudget;

  bool dfs(int current, int visitedCount) {
    if (budget-- <= 0) {
      return false;
    }
    if (visitedCount == total) {
      return true;
    }
    if (!_remainingGraphSeemsValid(
      adjacency: adjacency,
      visited: visited,
      current: current,
      endCell: null,
    )) {
      return false;
    }
    if (visitedCount % 5 == 0 &&
        !_isRemainingConnected(
          adjacency: adjacency,
          visited: visited,
          current: current,
        )) {
      return false;
    }

    final candidates = <int>[];
    for (final n in adjacency[current]) {
      if (!visited[n]) {
        candidates.add(n);
      }
    }
    if (candidates.isEmpty) {
      return false;
    }

    candidates.sort((a, b) {
      var aForward = 0;
      for (final n in adjacency[a]) {
        if (!visited[n]) {
          aForward++;
        }
      }
      var bForward = 0;
      for (final n in adjacency[b]) {
        if (!visited[n]) {
          bForward++;
        }
      }
      if (aForward != bForward) {
        return aForward.compareTo(bForward);
      }
      final aCenter = _manhattanCellDistance(a, center, width);
      final bCenter = _manhattanCellDistance(b, center, width);
      if (aCenter != bCenter) {
        return aCenter.compareTo(bCenter);
      }
      return rng() < 0.5 ? -1 : 1;
    });

    for (final next in candidates) {
      visited[next] = true;
      path.add(next);
      if (dfs(next, visitedCount + 1)) {
        return true;
      }
      path.removeLast();
      visited[next] = false;
    }
    return false;
  }

  for (var i = 0; i < maxStarts; i++) {
    for (var j = 0; j < total; j++) {
      visited[j] = false;
    }
    path.clear();
    final start = starts[i];
    visited[start] = true;
    path.add(start);
    if (dfs(start, 1)) {
      return List<int>.from(path);
    }
  }
  return null;
}

List<int> _zigzagPath(int width, int height) {
  final path = <int>[];
  for (var row = 0; row < height; row++) {
    if (row.isEven) {
      for (var col = 0; col < width; col++) {
        path.add(row * width + col);
      }
    } else {
      for (var col = width - 1; col >= 0; col--) {
        path.add(row * width + col);
      }
    }
  }
  return path;
}

// ignore: unused_element
List<int> _generateHamiltonianPath(int width, int height, Rng rng) {
  final total = width * height;
  final startOrder = List<int>.generate(total, (i) => i);
  shuffle(startOrder, rng);

  final attempts = total < 30 ? total : 30;
  for (var attempt = 0; attempt < attempts; attempt++) {
    final result = _warnsdorffPath(width, height, startOrder[attempt], rng);
    if (result != null && result.length == total) return result;
  }

  return _zigzagPath(width, height);
}

(Mode, Tier) _cluePolicyContext(
  String packId,
  String? generationProfile,
  int difficulty,
  int levelIndexHint,
) {
  if (packId == 'daily') {
    return (Mode.daily, Tier.high);
  }
  if (packId == 'classic') {
    if (generationProfile == 'campaign_low') {
      return (Mode.campaign, Tier.low);
    }
    if (generationProfile == 'campaign_mid') {
      return (Mode.campaign, Tier.mid);
    }
    if (generationProfile == 'campaign_high' ||
        generationProfile == 'campaign_elite') {
      return (Mode.campaign, Tier.high);
    }
    if (levelIndexHint <= 30) {
      return (Mode.campaign, Tier.low);
    }
    if (levelIndexHint <= 80) {
      return (Mode.campaign, Tier.mid);
    }
    return (Mode.campaign, Tier.high);
  }
  if (packId == 'architect' || packId == 'expert') {
    return (Mode.other, Tier.high);
  }
  final tier =
      difficulty >= 4 ? Tier.high : (difficulty >= 3 ? Tier.mid : Tier.low);
  return (Mode.other, tier);
}

({int min, int max}) _clueCountRange({
  required Mode mode,
  required Tier tier,
  required int w,
  required int h,
}) {
  final maxSide = w > h ? w : h;
  if (maxSide >= 9) {
    if (mode == Mode.daily) return (min: 10, max: 12);
    if (tier == Tier.low) return (min: 7, max: 9);
    if (tier == Tier.mid) return (min: 9, max: 11);
    return (min: 11, max: 13);
  }
  if (maxSide >= 7) {
    if (mode == Mode.daily) return (min: 9, max: 11);
    if (tier == Tier.low) return (min: 6, max: 8);
    if (tier == Tier.mid) return (min: 8, max: 10);
    return (min: 10, max: 12);
  }
  if (mode == Mode.daily) return (min: 7, max: 9);
  if (tier == Tier.low) return (min: 5, max: 7);
  if (tier == Tier.mid) return (min: 6, max: 8);
  return (min: 8, max: 10);
}

int chooseClueCount({
  required Mode mode,
  required Tier tier,
  required int w,
  required int h,
  required int levelIndex,
  required int seed,
}) {
  final range = _clueCountRange(mode: mode, tier: tier, w: w, h: h);
  final span = (range.max - range.min + 1).clamp(1, 12);
  final jitterSeed =
      hashString('clue-count|$mode|$tier|$w|$h|$levelIndex|$seed');
  final offset = jitterSeed.abs() % span;
  var count = range.min + offset;
  final rareSpecial =
      tier == Tier.high && (w >= 9 || h >= 9) && (jitterSeed.abs() % 17 == 0);
  if (rareSpecial) {
    count = (count + 1).clamp(range.min, 14);
  }
  final totalCells = w * h;
  return count.clamp(2, totalCells);
}

Map<int, List<int>> _buildAdjacency(int width, int height, List<Wall> walls) {
  final total = width * height;
  final blocked = <String>{};
  for (final wall in walls) {
    blocked.add(_edgeKey(wall.cell1, wall.cell2));
  }

  final adjacency = <int, List<int>>{};
  for (var cell = 0; cell < total; cell++) {
    final next = <int>[];
    for (final n in _getNeighbors(cell, width, height)) {
      if (!blocked.contains(_edgeKey(cell, n))) {
        next.add(n);
      }
    }
    adjacency[cell] = next;
  }
  return adjacency;
}

bool _isEdgeOrCorner(int cell, int width, int height) {
  final row = cell ~/ width;
  final col = cell % width;
  return row == 0 || col == 0 || row == height - 1 || col == width - 1;
}

int _manhattanCellDistance(int a, int b, int width) {
  final aRow = a ~/ width;
  final aCol = a % width;
  final bRow = b ~/ width;
  final bCol = b % width;
  final dRow = (aRow - bRow).abs();
  final dCol = (aCol - bCol).abs();
  return dRow + dCol;
}

Map<int, int> _buildPathIndexMap(List<int> path) {
  final map = <int, int>{};
  for (var i = 0; i < path.length; i++) {
    map[path[i]] = i;
  }
  return map;
}

int _minJumpForDifficulty(int difficulty, int width, int height) {
  final base = <int>[1, 2, 2, 3, 4][(difficulty - 1).clamp(0, 4)];
  final sizeBoost = (width >= 8 || height >= 8) ? 1 : 0;
  return (base + sizeBoost).clamp(1, 6);
}

int _minDispersionForDifficulty(int difficulty, int width, int height) {
  final spreadBase = <int>[1, 1, 2, 2, 3][(difficulty - 1).clamp(0, 4)];
  final sizeBoost = (width >= 8 || height >= 8) ? 1 : 0;
  return (spreadBase + sizeBoost).clamp(1, 5);
}

_ModeTier _modeTierForPack(String packId) {
  if (packId == 'architect' || packId == 'expert') {
    return _ModeTier.veryHard;
  }
  if (packId == 'daily' || packId == 'endless') {
    return _ModeTier.hard;
  }
  return _ModeTier.campaign;
}

_ModeValidationPolicy _modeValidationPolicy(
  String packId,
  int difficulty,
  StrictnessProfile profile,
  String? generationProfile,
) {
  final tier = _modeTierForPack(packId);
  final relaxation = profile.relaxation;
  final dailySoft = generationProfile?.contains('daily_hard_soft') ?? false;
  final dailyProfile = generationProfile?.contains('daily_hard') ?? false;
  switch (tier) {
    case _ModeTier.campaign:
      final enableHardSignals = generationProfile != 'campaign_low' ||
          difficulty >= 4 ||
          generationProfile == 'campaign_high' ||
          generationProfile == 'campaign_elite';
      final campaignMid = generationProfile == 'campaign_mid';
      final strictCampaign = generationProfile == 'campaign_high' ||
          generationProfile == 'campaign_elite';
      return _ModeValidationPolicy(
        enforceErc: enableHardSignals && relaxation < 4,
        enforceCas: enableHardSignals && relaxation < 4,
        ercMinScore: (strictCampaign ? 0.24 : (campaignMid ? 0.14 : 0.65)) -
            relaxation * 0.06,
        casMinScore: (strictCampaign ? 0.54 : (campaignMid ? 0.48 : 0.62)) -
            relaxation * 0.05,
        casMinEarlyAmbiguousSegments:
            strictCampaign ? 2 : (campaignMid ? 2 : (difficulty >= 5 ? 1 : 0)),
        casRequireFirstTwoEarlySegments: false,
        uniquenessMandatory: strictCampaign,
        allowNearUnique: !strictCampaign,
        maxTinyComponentsPerCheckpoint: relaxation >= 3 ? 1 : 0,
        requireMidSplitOrNarrow:
            strictCampaign || campaignMid || difficulty >= 5,
        casEarlyOnly: strictCampaign || campaignMid,
      );
    case _ModeTier.hard:
      final dailyStrict = dailyProfile || (packId == 'daily' && !dailySoft);
      return _ModeValidationPolicy(
        enforceErc: !dailySoft,
        enforceCas: true,
        ercMinScore: ((dailyStrict ? 0.16 : (dailySoft ? 0.11 : 0.20)) -
                relaxation * 0.08)
            .clamp(-0.20, 0.80),
        casMinScore: ((dailyStrict ? 0.52 : (dailySoft ? 0.47 : 0.58)) -
                relaxation * 0.05)
            .clamp(0.35, 0.95),
        casMinEarlyAmbiguousSegments: dailySoft ? 1 : (relaxation >= 3 ? 1 : 2),
        casRequireFirstTwoEarlySegments: false,
        uniquenessMandatory: true,
        allowNearUnique: false,
        maxTinyComponentsPerCheckpoint: relaxation >= 3 ? 1 : 0,
        requireMidSplitOrNarrow: dailySoft ? false : relaxation < 3,
        casEarlyOnly: dailyStrict || dailySoft,
      );
    case _ModeTier.veryHard:
      return _ModeValidationPolicy(
        enforceErc: true,
        enforceCas: true,
        ercMinScore: (0.30 - relaxation * 0.07).clamp(0.0, 0.90),
        casMinScore: (0.66 - relaxation * 0.05).clamp(0.45, 1.0),
        casMinEarlyAmbiguousSegments: 2,
        casRequireFirstTwoEarlySegments: relaxation < 3,
        uniquenessMandatory: true,
        allowNearUnique: false,
        maxTinyComponentsPerCheckpoint: 0,
        requireMidSplitOrNarrow: relaxation < 4,
        casEarlyOnly: false,
      );
  }
}

int _countShortJumpPairs(
  List<int> sortedPositions,
  List<int> path,
  int width,
  int minJump,
) {
  if (sortedPositions.length < 2) {
    return 0;
  }
  var count = 0;
  for (var i = 0; i < sortedPositions.length - 1; i++) {
    final cellA = path[sortedPositions[i]];
    final cellB = path[sortedPositions[i + 1]];
    if (_manhattanCellDistance(cellA, cellB, width) < minJump) {
      count++;
    }
  }
  return count;
}

double _positionalTensionScore(
  int pos,
  List<int> path,
  int width,
  int height,
  Map<int, List<int>> adjacency,
  Map<int, int> blockedDegree,
  Map<int, int> pathIndexMap,
  Rng rng,
) {
  final cell = path[pos];
  final row = cell ~/ width;
  final col = cell % width;
  final centerRow = (height - 1) / 2;
  final centerCol = (width - 1) / 2;
  final distToCenter = (row - centerRow).abs() + (col - centerCol).abs();
  final maxDist = (centerRow + centerCol).abs() + 1;
  final centerScore = 1.0 - (distToCenter / maxDist);
  final branching = (adjacency[cell]?.length ?? 0).toDouble();
  final blocked = (blockedDegree[cell] ?? 0).toDouble();
  final progress = pos / (path.length - 1);
  final middlePathBonus = (0.45 - (progress - 0.5).abs()) * 2.0;

  var longShortcutBonus = 0.0;
  for (final n in adjacency[cell] ?? const <int>[]) {
    final delta = (pathIndexMap[n]! - pos).abs();
    if (delta >= width) {
      longShortcutBonus += 0.45;
    }
  }

  return centerScore * 2.2 +
      branching * 1.25 +
      blocked * 0.8 +
      middlePathBonus +
      longShortcutBonus +
      (rng() - 0.5) * 0.22;
}

Map<int, int> _placeTrickyNumbers(
  List<int> path,
  int width,
  int height,
  int count,
  List<Wall> walls,
  int difficulty,
  Rng rng,
) {
  final total = path.length;
  final finalCount = count.clamp(2, total);

  if (finalCount >= total) {
    return {
      for (var i = 0; i < total; i++) path[i]: i + 1,
    };
  }

  final minJump = _minJumpForDifficulty(difficulty, width, height);
  final minDispersion = _minDispersionForDifficulty(difficulty, width, height);
  final allowedShortPairs = difficulty >= 4 ? (difficulty >= 5 ? 2 : 1) : 0;

  final pathIndexMap = _buildPathIndexMap(path);
  final adjacency = _buildAdjacency(width, height, walls);
  final wallSet = <String>{};
  for (final wall in walls) {
    wallSet.add(_edgeKey(wall.cell1, wall.cell2));
  }
  final blockedDegree = <int, int>{};
  for (var cell = 0; cell < total; cell++) {
    var blocked = 0;
    for (final n in _getNeighbors(cell, width, height)) {
      if (wallSet.contains(_edgeKey(cell, n))) {
        blocked++;
      }
    }
    blockedDegree[cell] = blocked;
  }

  final selectedPositions = <int>{0, total - 1};
  final scoredPositions = <MapEntry<int, double>>[];

  for (var pos = 1; pos < total - 1; pos++) {
    final score = _positionalTensionScore(
      pos,
      path,
      width,
      height,
      adjacency,
      blockedDegree,
      pathIndexMap,
      rng,
    );
    scoredPositions.add(MapEntry(pos, score));
  }

  scoredPositions.sort((a, b) => b.value.compareTo(a.value));

  while (selectedPositions.length < finalCount) {
    var bestPos = -1;
    var bestScore = -1e12;

    for (final entry in scoredPositions) {
      final pos = entry.key;
      if (selectedPositions.contains(pos)) continue;

      final sortedWithCandidate = <int>[...selectedPositions, pos]..sort();
      final shortPairs = _countShortJumpPairs(
        sortedWithCandidate,
        path,
        width,
        minJump,
      );
      if (shortPairs > allowedShortPairs) {
        continue;
      }

      final candidateCell = path[pos];
      var minCellDistance = width * height;
      for (final existing in selectedPositions) {
        final d = _manhattanCellDistance(
          candidateCell,
          path[existing],
          width,
        );
        if (d < minCellDistance) {
          minCellDistance = d;
        }
      }
      if (minCellDistance < minDispersion && shortPairs == 0) {
        continue;
      }

      var jumpScore = 0.0;
      final idx = sortedWithCandidate.indexOf(pos);
      if (idx > 0) {
        final left = sortedWithCandidate[idx - 1];
        final d = _manhattanCellDistance(path[left], candidateCell, width);
        jumpScore += d.toDouble();
      }
      if (idx < sortedWithCandidate.length - 1) {
        final right = sortedWithCandidate[idx + 1];
        final d = _manhattanCellDistance(candidateCell, path[right], width);
        jumpScore += d.toDouble();
      }

      var score = entry.value + jumpScore * 0.85;
      if (shortPairs > 0) {
        score += 0.8;
      } else {
        score += minCellDistance * 0.35;
      }
      if (_isEdgeOrCorner(candidateCell, width, height)) {
        score -= difficulty >= 4 ? 0.45 : 0.15;
      }
      if (selectedPositions.length > 3) {
        final ordered = selectedPositions.toList()..sort();
        final first = ordered.first;
        final last = ordered.last;
        final corridorCompression = (pos - first).abs() + (last - pos).abs();
        if (corridorCompression < total ~/ 5) {
          score -= 0.4;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestPos = pos;
      }
    }

    if (bestPos == -1) break;
    selectedPositions.add(bestPos);
  }

  final orderedPositions = selectedPositions.toList()..sort();
  final shortPairs =
      _countShortJumpPairs(orderedPositions, path, width, minJump);
  if (shortPairs > allowedShortPairs) {
    return {
      for (var i = 0; i < orderedPositions.length; i++)
        path[orderedPositions[i]]: i + 1,
    };
  }

  return {
    for (var i = 0; i < orderedPositions.length; i++)
      path[orderedPositions[i]]: i + 1,
  };
}

Map<int, int> _placeAnchoredCluesForEarlySpike(
  List<int> path,
  int width,
  int height,
  int count,
  List<Wall> walls,
  int difficulty,
  Rng rng,
) {
  final target = count.clamp(2, path.length);
  if (target <= 2) {
    return {
      path[path.length ~/ 2]: 1,
      path.last: 2,
    };
  }
  final fallback = _placeTrickyNumbers(
    path,
    width,
    height,
    count,
    walls,
    difficulty,
    rng,
  );
  final fallbackPositions = fallback.keys
      .map((c) => _pathIndexOf(path, c))
      .where((p) => p >= 0)
      .toList(growable: true)
    ..sort();
  final minDistance = _earlySeparationThreshold(width, height);
  final strictEarly = difficulty >= 3;
  final center = ((height ~/ 2) * width) + (width ~/ 2);
  final adjacency = _buildAdjacency(width, height, walls);
  final pathIndexMap = _buildPathIndexMap(path);
  final wallSet = <String>{
    for (final wall in walls) _edgeKey(wall.cell1, wall.cell2)
  };
  final blockedDegree = <int, int>{};
  for (var cell = 0; cell < width * height; cell++) {
    var blocked = 0;
    for (final n in _getNeighbors(cell, width, height)) {
      if (wallSet.contains(_edgeKey(cell, n))) {
        blocked++;
      }
    }
    blockedDegree[cell] = blocked;
  }
  final scored = <int>[];
  final scores = <int, double>{};
  for (var pos = 1; pos < path.length - 1; pos++) {
    final score = _positionalTensionScore(
          pos,
          path,
          width,
          height,
          adjacency,
          blockedDegree,
          pathIndexMap,
          rng,
        ) -
        (_manhattanCellDistance(path[pos], center, width) * 0.35);
    scored.add(pos);
    scores[pos] = score;
  }
  scored.sort((a, b) => (scores[b] ?? 0).compareTo(scores[a] ?? 0));
  final top = scored.take(40).toList(growable: false);
  List<int>? earlySelection;
  var bestEarlyScore = -1e12;
  for (var i = 0; i < top.length; i++) {
    final p1 = top[i];
    for (var j = i + 1; j < top.length; j++) {
      final p2 = top[j];
      if (p2 <= p1 + 1) continue;
      for (var k = j + 1; k < top.length; k++) {
        final p3 = top[k];
        if (p3 <= p2 + 1) continue;
        for (var m = k + 1; m < top.length; m++) {
          final p4 = top[m];
          if (p4 <= p3 + 1) continue;
          final cells = <int>[path[p1], path[p2], path[p3], path[p4]];
          if (!_earlyClueSeparationSatisfied(
            cells,
            width,
            height,
            minDistance: minDistance,
            strict: strictEarly,
          )) {
            continue;
          }
          final spread = _regionSpreadCount(cells, width, height);
          final score = (scores[p1] ?? 0) +
              (scores[p2] ?? 0) +
              (scores[p3] ?? 0) +
              (scores[p4] ?? 0) +
              spread * 2.5;
          if (score > bestEarlyScore) {
            bestEarlyScore = score;
            earlySelection = <int>[p1, p2, p3, p4];
          }
        }
      }
    }
  }
  if (earlySelection == null) {
    List<int>? bestCandidate;
    var bestCandidateScore = -1e12;
    for (var attempt = 0; attempt < 3200; attempt++) {
      final picks = <int>{
        1 + (rng() * (path.length - 2)).floor(),
        1 + (rng() * (path.length - 2)).floor(),
        1 + (rng() * (path.length - 2)).floor(),
        1 + (rng() * (path.length - 2)).floor(),
      }.toList()
        ..sort();
      if (picks.length != 4) {
        continue;
      }
      final cells = <int>[
        path[picks[0]],
        path[picks[1]],
        path[picks[2]],
        path[picks[3]],
      ];
      final spread = _regionSpreadCount(cells, width, height);
      final pairDistances = <int>[
        _manhattanCellDistance(cells[0], cells[1], width),
        _manhattanCellDistance(cells[1], cells[2], width),
        _manhattanCellDistance(cells[2], cells[3], width),
        _manhattanCellDistance(cells[0], cells[2], width),
        _manhattanCellDistance(cells[0], cells[3], width),
        _manhattanCellDistance(cells[1], cells[3], width),
      ];
      final minPair = pairDistances.reduce((a, b) => a < b ? a : b);
      final score =
          (minPair * 10 + spread * 4 + picks[3] - picks[0]).toDouble();
      if (score > bestCandidateScore) {
        bestCandidateScore = score;
        bestCandidate = picks;
      }
      if (_earlyClueSeparationSatisfied(
        cells,
        width,
        height,
        minDistance: minDistance,
        strict: strictEarly,
      )) {
        earlySelection = picks;
        break;
      }
    }
    if (earlySelection == null &&
        bestCandidate != null &&
        !strictEarly &&
        bestCandidateScore > 0) {
      earlySelection = bestCandidate;
    }
  }

  final ordered = <int>[];
  final used = <int>{};
  if (earlySelection != null) {
    final earlyOrdered = List<int>.from(earlySelection)..sort();
    final requiredTail = target - 4;
    final availableTail = path.length - (earlyOrdered.last + 1);
    if (availableTail < requiredTail) {
      earlySelection = null;
    }
  }
  if (earlySelection != null) {
    final earlyOrdered = List<int>.from(earlySelection)..sort();
    ordered.addAll(earlyOrdered);
    used.addAll(earlyOrdered);
    final minExtraPos = earlyOrdered.last + 1;
    final candidates = <int>[];
    for (final pos in fallbackPositions) {
      if (pos < minExtraPos || used.contains(pos)) continue;
      candidates.add(pos);
    }
    while (ordered.length < target && candidates.isNotEmpty) {
      var bestIdx = 0;
      var bestScore = -1e12;
      for (var i = 0; i < candidates.length; i++) {
        final pos = candidates[i];
        final cell = path[pos];
        final prevCell = path[ordered.last];
        final jumpFromPrev =
            _manhattanCellDistance(prevCell, cell, width).toDouble();
        var minToExisting = 999.0;
        for (final existingPos in ordered) {
          final d =
              _manhattanCellDistance(path[existingPos], cell, width).toDouble();
          if (d < minToExisting) {
            minToExisting = d;
          }
        }
        final score = jumpFromPrev * 1.2 + minToExisting * 0.6;
        if (score > bestScore) {
          bestScore = score;
          bestIdx = i;
        }
      }
      final picked = candidates.removeAt(bestIdx);
      if (used.add(picked)) {
        ordered.add(picked);
      }
    }
    if (ordered.length < target) {
      for (var pos = minExtraPos;
          pos < path.length && ordered.length < target;
          pos++) {
        if (used.add(pos)) {
          ordered.add(pos);
        }
      }
    }
  } else {
    for (final pos in fallbackPositions) {
      if (ordered.length >= (target < 4 ? target : 4)) break;
      if (used.add(pos)) {
        ordered.add(pos);
      }
    }
  }
  for (final pos in fallbackPositions) {
    if (ordered.length >= target) break;
    if (earlySelection != null && pos <= ordered.last) continue;
    if (used.add(pos)) {
      ordered.add(pos);
    }
  }
  while (ordered.length < target) {
    final pos = (rng() * path.length).floor();
    if (earlySelection != null && pos <= ordered.last) {
      continue;
    }
    if (used.add(pos)) {
      ordered.add(pos);
    }
    if (used.length >= path.length) {
      break;
    }
  }
  if (ordered.length < target) {
    final start =
        earlySelection != null ? (ordered.isEmpty ? 0 : ordered.last + 1) : 0;
    for (var pos = start; pos < path.length && ordered.length < target; pos++) {
      if (used.add(pos)) {
        ordered.add(pos);
      }
    }
  }
  if (earlySelection == null) {
    ordered.sort();
  }
  for (var i = 1; i < ordered.length; i++) {
    if (ordered[i] <= ordered[i - 1]) {
      ordered.sort();
      break;
    }
  }
  final numbers = <int, int>{};
  for (var i = 0; i < ordered.length; i++) {
    numbers[path[ordered[i]]] = i + 1;
  }
  return numbers;
}

// ignore: unused_element
List<Wall> _generateWalls(
  List<int> path,
  int width,
  int height,
  int count,
  Rng rng,
) {
  final pathAdj = <String>{};
  for (var i = 0; i < path.length - 1; i++) {
    final a = path[i] < path[i + 1] ? path[i] : path[i + 1];
    final b = path[i] > path[i + 1] ? path[i] : path[i + 1];
    pathAdj.add('$a,$b');
  }

  final possible = <Wall>[];
  final total = width * height;
  for (var idx = 0; idx < total; idx++) {
    final row = idx ~/ width;
    final col = idx % width;
    if (col < width - 1) {
      final right = idx + 1;
      if (!pathAdj.contains('$idx,$right')) {
        possible.add(Wall(cell1: idx, cell2: right));
      }
    }
    if (row < height - 1) {
      final bottom = idx + width;
      if (!pathAdj.contains('$idx,$bottom')) {
        possible.add(Wall(cell1: idx, cell2: bottom));
      }
    }
  }

  shuffle(possible, rng);
  return possible
      .take(count < possible.length ? count : possible.length)
      .toList();
}

String _edgeKey(int a, int b) {
  final x = a < b ? a : b;
  final y = a > b ? a : b;
  return '$x,$y';
}

int _pathIndexOf(List<int> path, int cell) {
  for (var i = 0; i < path.length; i++) {
    if (path[i] == cell) return i;
  }
  return -1;
}

Set<String> _buildDecoyCorridorEdges(
  List<int> path,
  int width,
  int height,
  int difficulty,
  Rng rng,
) {
  final pathAdj = <String>{};
  for (var i = 0; i < path.length - 1; i++) {
    pathAdj.add(_edgeKey(path[i], path[i + 1]));
  }

  final corridorEdges = <String>{};
  final corridorCount = difficulty == 5 ? 4 : 3;

  for (var c = 0; c < corridorCount; c++) {
    var start = path[(rng() * path.length).floor()];
    var startPos = _pathIndexOf(path, start);
    if (startPos <= 0 || startPos >= path.length - 1) {
      startPos = (path.length * 0.35 + rng() * path.length * 0.4).floor();
      start = path[startPos.clamp(1, path.length - 2)];
    }

    var current = start;
    var prev = -1;
    final targetLen = (difficulty == 5 ? 5 : 4) + (rng() * 4).floor();

    for (var step = 0; step < targetLen; step++) {
      final options = <int>[];
      for (final n in _getNeighbors(current, width, height)) {
        if (n == prev) continue;
        final key = _edgeKey(current, n);
        if (pathAdj.contains(key)) continue;
        options.add(n);
      }
      if (options.isEmpty) break;

      options.sort((a, b) {
        final da = (_pathIndexOf(path, a) - _pathIndexOf(path, current)).abs();
        final db = (_pathIndexOf(path, b) - _pathIndexOf(path, current)).abs();
        return db.compareTo(da);
      });

      final pick =
          options[(rng() * (options.length > 2 ? 2 : options.length)).floor()];
      corridorEdges.add(_edgeKey(current, pick));
      prev = current;
      current = pick;
    }
  }

  return corridorEdges;
}

Set<String> _buildChamberEdgesFromGrid(
  int width,
  int height,
  int difficulty,
  String packId,
  Rng rng,
) {
  final family = _chooseBlueprintFamily(
    width: width,
    height: height,
    difficulty: difficulty,
    packId: packId,
    generationProfile: null,
    rng: rng,
  );
  switch (family) {
    case _BlueprintFamily.comb:
      return _buildCombWalls(width, height, difficulty, rng);
    case _BlueprintFamily.nestedChambers:
      return _buildNestedChambersWalls(width, height, difficulty, rng);
    case _BlueprintFamily.ringEnclosure:
      return _buildRingEnclosureWalls(width, height, difficulty, rng);
    case _BlueprintFamily.multiChoke:
      return _buildMultiChokeWalls(width, height, difficulty, rng);
  }
}

_BlueprintFamily _chooseBlueprintFamily({
  required int width,
  required int height,
  required int difficulty,
  required String packId,
  required String? generationProfile,
  required Rng rng,
}) {
  final forcedFamily = _forcedFamilyFromProfile(generationProfile);
  if (forcedFamily != null) {
    return forcedFamily;
  }
  if (generationProfile == 'campaign_low') {
    return rng() < 0.7
        ? _BlueprintFamily.comb
        : _BlueprintFamily.nestedChambers;
  }
  if (generationProfile == 'campaign_mid') {
    final roll = rng();
    if (roll < 0.45) return _BlueprintFamily.comb;
    if (roll < 0.8) return _BlueprintFamily.nestedChambers;
    return _BlueprintFamily.multiChoke;
  }
  if (generationProfile == 'campaign_high' ||
      generationProfile == 'campaign_elite') {
    final roll = rng();
    if (roll < 0.35) return _BlueprintFamily.nestedChambers;
    if (roll < 0.6) return _BlueprintFamily.multiChoke;
    if (roll < 0.8) return _BlueprintFamily.ringEnclosure;
    return _BlueprintFamily.comb;
  }
  if (generationProfile == 'daily_hard') {
    return rng() < 0.6
        ? _BlueprintFamily.nestedChambers
        : _BlueprintFamily.comb;
  }
  if (packId == 'daily') {
    return rng() < 0.55
        ? _BlueprintFamily.nestedChambers
        : _BlueprintFamily.comb;
  }
  if (packId == 'architect' || packId == 'expert') {
    final roll = rng();
    if (roll < 0.4) return _BlueprintFamily.multiChoke;
    if (roll < 0.75) return _BlueprintFamily.nestedChambers;
    return _BlueprintFamily.ringEnclosure;
  }
  if (difficulty >= 4) {
    final roll = rng();
    if (roll < 0.35) return _BlueprintFamily.comb;
    if (roll < 0.6) return _BlueprintFamily.nestedChambers;
    if (roll < 0.8) return _BlueprintFamily.ringEnclosure;
    return _BlueprintFamily.multiChoke;
  }
  return rng() < 0.5 ? _BlueprintFamily.comb : _BlueprintFamily.nestedChambers;
}

_BlueprintFamily? _forcedFamilyFromProfile(String? generationProfile) {
  if (generationProfile == null) {
    return null;
  }
  if (generationProfile.contains('family=comb')) {
    return _BlueprintFamily.comb;
  }
  if (generationProfile.contains('family=nested')) {
    return _BlueprintFamily.nestedChambers;
  }
  if (generationProfile.contains('family=ring')) {
    return _BlueprintFamily.ringEnclosure;
  }
  if (generationProfile.contains('family=multichoke')) {
    return _BlueprintFamily.multiChoke;
  }
  return null;
}

int _profileMutationIndex(String? generationProfile) {
  if (generationProfile == null) {
    return 0;
  }
  final match = RegExp(r'mut=(\d+)').firstMatch(generationProfile);
  if (match == null) {
    return 0;
  }
  return int.tryParse(match.group(1) ?? '0') ?? 0;
}

Set<String> _lightenBlueprintEdges(
    Set<String> edges, double keepRatio, Rng rng) {
  if (keepRatio >= 0.999 || edges.length <= 3) {
    return edges;
  }
  final list = edges.toList(growable: true);
  list.sort();
  final kept = <String>{};
  for (final edge in list) {
    if (rng() <= keepRatio) {
      kept.add(edge);
    }
  }
  if (kept.length < 2) {
    kept.addAll(list.take(2));
  }
  return kept;
}

Set<String> _buildCombWalls(int width, int height, int difficulty, Rng rng) {
  final edges = <String>{};
  final vertical = rng() < 0.5;
  final lanes = (difficulty >= 5 ? 2 : 1) + (rng() < 0.35 ? 1 : 0);
  final laneBias = (rng() * 3).floor() - 1;
  if (vertical && width >= 5) {
    for (var i = 0; i < lanes; i++) {
      final col =
          (((i + 1) * width ~/ (lanes + 1)) + laneBias).clamp(1, width - 2);
      final bridges = <int>{
        (height * (0.16 + rng() * 0.18)).floor().clamp(0, height - 1),
        (height * (0.44 + rng() * 0.16)).floor().clamp(0, height - 1),
        (height * (0.72 + rng() * 0.18)).floor().clamp(0, height - 1),
      };
      if (difficulty <= 2 || difficulty == 4) {
        bridges.add((height * 0.5).floor());
      }
      for (var row = 0; row < height; row++) {
        if (bridges.contains(row)) continue;
        edges.add(_edgeKey(row * width + col, row * width + col + 1));
      }
    }
  } else if (height >= 5) {
    for (var i = 0; i < lanes; i++) {
      final row =
          (((i + 1) * height ~/ (lanes + 1)) + laneBias).clamp(1, height - 2);
      final bridges = <int>{
        (width * (0.16 + rng() * 0.18)).floor().clamp(0, width - 1),
        (width * (0.44 + rng() * 0.16)).floor().clamp(0, width - 1),
        (width * (0.72 + rng() * 0.18)).floor().clamp(0, width - 1),
      };
      if (difficulty <= 2 || difficulty == 4) {
        bridges.add((width * 0.5).floor());
      }
      for (var col = 0; col < width; col++) {
        if (bridges.contains(col)) continue;
        edges.add(_edgeKey(row * width + col, (row + 1) * width + col));
      }
    }
  }
  final keepRatio = difficulty >= 5 ? 0.88 : 0.62;
  return _lightenBlueprintEdges(edges, keepRatio, rng);
}

Set<String> _buildNestedChambersWalls(
  int width,
  int height,
  int difficulty,
  Rng rng,
) {
  final edges = <String>{};
  if (width < 5 || height < 5) {
    return _buildCombWalls(width, height, difficulty, rng);
  }
  final r1 = (height * (0.12 + rng() * 0.18)).floor().clamp(1, height - 3);
  final r2 = (height * (0.68 + rng() * 0.2)).floor().clamp(r1 + 2, height - 2);
  final c1 = (width * (0.12 + rng() * 0.18)).floor().clamp(1, width - 3);
  final c2 = (width * (0.68 + rng() * 0.2)).floor().clamp(c1 + 2, width - 2);

  for (var c = c1; c < c2; c++) {
    if (c != c1 + 1) edges.add(_edgeKey(r1 * width + c, r1 * width + c + 1));
    if (c != c2 - 2) edges.add(_edgeKey(r2 * width + c, r2 * width + c + 1));
  }
  for (var r = r1; r < r2; r++) {
    if (r != r2 - 2) edges.add(_edgeKey(r * width + c1, (r + 1) * width + c1));
    if (r != r1 + 1) edges.add(_edgeKey(r * width + c2, (r + 1) * width + c2));
  }

  final innerR =
      (((r1 + r2) ~/ 2) + ((rng() * 3).floor() - 1)).clamp(1, height - 3);
  final innerC =
      (((c1 + c2) ~/ 2) + ((rng() * 3).floor() - 1)).clamp(1, width - 3);
  for (var c = c1 + 1; c < c2; c++) {
    if (c == innerC) continue;
    edges.add(_edgeKey(innerR * width + c, innerR * width + c + 1));
  }
  for (var r = r1 + 1; r < r2; r++) {
    if (r == innerR) continue;
    edges.add(_edgeKey(r * width + innerC, (r + 1) * width + innerC));
  }
  final keepRatio = difficulty >= 5 ? 0.84 : 0.58;
  return _lightenBlueprintEdges(edges, keepRatio, rng);
}

Set<String> _buildRingEnclosureWalls(
    int width, int height, int difficulty, Rng rng) {
  final edges = <String>{};
  if (width < 6 || height < 6) {
    return _buildNestedChambersWalls(width, height, difficulty, rng);
  }
  final top = (height * (0.15 + rng() * 0.2)).floor().clamp(1, height - 3);
  final bottom =
      (height * (0.65 + rng() * 0.2)).floor().clamp(top + 2, height - 2);
  final left = (width * (0.15 + rng() * 0.2)).floor().clamp(1, width - 3);
  final right =
      (width * (0.65 + rng() * 0.2)).floor().clamp(left + 2, width - 2);
  final gateTop = left + ((right - left) ~/ 2);
  final gateBottom = left + ((right - left) ~/ 3);
  final gateLeft = top + ((bottom - top) ~/ 2);
  final gateRight = top + ((bottom - top) ~/ 3);

  for (var c = left; c < right; c++) {
    if (c != gateTop) edges.add(_edgeKey(top * width + c, top * width + c + 1));
    if (c != gateBottom) {
      edges.add(_edgeKey(bottom * width + c, bottom * width + c + 1));
    }
  }
  for (var r = top; r < bottom; r++) {
    if (r != gateLeft) {
      edges.add(_edgeKey(r * width + left, (r + 1) * width + left));
    }
    if (r != gateRight) {
      edges.add(_edgeKey(r * width + right, (r + 1) * width + right));
    }
  }
  final keepRatio = difficulty >= 5 ? 0.88 : 0.60;
  return _lightenBlueprintEdges(edges, keepRatio, rng);
}

Set<String> _buildMultiChokeWalls(
    int width, int height, int difficulty, Rng rng) {
  final edges = <String>{..._buildCombWalls(width, height, difficulty, rng)};
  final centerRow = (height ~/ 2) + ((rng() * 3).floor() - 1);
  final centerCol = (width ~/ 2) + ((rng() * 3).floor() - 1);
  final clampedRow = centerRow.clamp(1, height - 2);
  final clampedCol = centerCol.clamp(1, width - 2);
  if (width >= 5) {
    for (var row = 1; row < height - 1; row++) {
      if (row == clampedRow || row == clampedRow - 1) continue;
      if (rng() < 0.2) continue;
      edges.add(
          _edgeKey(row * width + clampedCol, row * width + clampedCol + 1));
    }
  }
  if (height >= 5) {
    for (var col = 1; col < width - 1; col++) {
      if (col == clampedCol || col == clampedCol - 1) continue;
      if (rng() < 0.2) continue;
      edges.add(
          _edgeKey(clampedRow * width + col, (clampedRow + 1) * width + col));
    }
  }
  final keepRatio = difficulty >= 5 ? 0.86 : 0.57;
  return _lightenBlueprintEdges(edges, keepRatio, rng);
}

Set<String> _buildDailyBackboneWalls(int width, int height, Rng rng) {
  final edges = <String>{};
  final useVertical = rng() < 0.55 || height < 6;
  if (useVertical && width >= 6) {
    final splitCol =
        ((width ~/ 2) + ((rng() * 3).floor() - 1)).clamp(1, width - 2);
    final gates = <int>{
      (height * 0.25).floor().clamp(0, height - 1),
      (height * 0.70).floor().clamp(0, height - 1),
      (height * 0.50).floor().clamp(0, height - 1),
    };
    for (var row = 0; row < height; row++) {
      if (gates.contains(row)) {
        continue;
      }
      final a = row * width + splitCol;
      edges.add(_edgeKey(a, a + 1));
    }
  }
  if (!useVertical && height >= 6) {
    final splitRow =
        ((height ~/ 2) + ((rng() * 3).floor() - 1)).clamp(1, height - 2);
    final gates = <int>{
      (width * 0.32).floor().clamp(0, width - 1),
      (width * 0.76).floor().clamp(0, width - 1),
      (width * 0.55).floor().clamp(0, width - 1),
    };
    for (var col = 0; col < width; col++) {
      if (gates.contains(col)) {
        continue;
      }
      final a = splitRow * width + col;
      edges.add(_edgeKey(a, a + width));
    }
  }
  return edges;
}

List<Wall> _generateStructuralWalls(
  int width,
  int height,
  int difficulty,
  double baseWallDensity,
  String packId,
  Rng rng,
  String? generationProfile,
) {
  final softDaily = generationProfile != null &&
      generationProfile.contains('daily_hard_soft');
  final thinWalls =
      generationProfile != null && generationProfile.contains('thin=1');
  final chokeBoost =
      generationProfile != null && generationProfile.contains('choke=high');
  final uniquenessReinforce =
      generationProfile != null && generationProfile.contains('uniq=1');
  final mutationIndex = _profileMutationIndex(generationProfile);
  final total = width * height;
  final allEdges = <Wall>[];
  for (var idx = 0; idx < total; idx++) {
    final row = idx ~/ width;
    final col = idx % width;
    if (col < width - 1) {
      allEdges.add(Wall(cell1: idx, cell2: idx + 1));
    }
    if (row < height - 1) {
      allEdges.add(Wall(cell1: idx, cell2: idx + width));
    }
  }

  const baseByDifficulty = <double>[0.06, 0.08, 0.10, 0.12, 0.15];
  var wallRatio = baseByDifficulty[(difficulty - 1).clamp(0, 4)];
  wallRatio += (baseWallDensity - 0.12) * 0.35;
  wallRatio += packId == 'architect' ? 0.03 : 0.0;
  wallRatio += packId == 'expert' ? 0.02 : 0.0;
  if (packId == 'daily') {
    wallRatio *= 0.72;
  }
  if (softDaily) {
    wallRatio *= 0.82;
  }
  if (thinWalls) {
    wallRatio *= 0.84;
  }
  if (chokeBoost) {
    wallRatio += 0.02;
  }
  if (uniquenessReinforce) {
    wallRatio += 0.015;
  }
  wallRatio += (mutationIndex % 5 - 2) * 0.004;
  wallRatio = wallRatio.clamp(0.08, 0.45);
  final targetWallCount = (allEdges.length * wallRatio).round();

  final family = _chooseBlueprintFamily(
    width: width,
    height: height,
    difficulty: difficulty,
    packId: packId,
    generationProfile: generationProfile,
    rng: rng,
  );
  final fixedEdges = switch (family) {
    _BlueprintFamily.comb => _buildCombWalls(width, height, difficulty, rng),
    _BlueprintFamily.nestedChambers =>
      _buildNestedChambersWalls(width, height, difficulty, rng),
    _BlueprintFamily.ringEnclosure =>
      _buildRingEnclosureWalls(width, height, difficulty, rng),
    _BlueprintFamily.multiChoke =>
      _buildMultiChokeWalls(width, height, difficulty, rng),
  };
  if (packId == 'daily' || generationProfile?.contains('daily_hard') == true) {
    fixedEdges.addAll(_buildDailyBackboneWalls(width, height, rng));
  }
  final centerRow = (height - 1) / 2;
  final centerCol = (width - 1) / 2;

  final degrees = List<int>.filled(total, 0);
  for (var idx = 0; idx < total; idx++) {
    degrees[idx] = _getNeighbors(idx, width, height).length;
  }
  final selectedKeys = <String>{};

  bool tryAddEdge(Wall edge) {
    final key = _edgeKey(edge.cell1, edge.cell2);
    if (selectedKeys.contains(key)) {
      return false;
    }
    final nextDeg1 = degrees[edge.cell1] - 1;
    final nextDeg2 = degrees[edge.cell2] - 1;
    if (nextDeg1 < 1 || nextDeg2 < 1) {
      return false;
    }
    selectedKeys.add(key);
    degrees[edge.cell1] = nextDeg1;
    degrees[edge.cell2] = nextDeg2;
    return true;
  }

  for (final key in fixedEdges) {
    final parts = key.split(',');
    tryAddEdge(Wall(cell1: int.parse(parts[0]), cell2: int.parse(parts[1])));
  }

  final candidates = <MapEntry<Wall, double>>[];
  for (final edge in allEdges) {
    final key = _edgeKey(edge.cell1, edge.cell2);
    if (selectedKeys.contains(key)) continue;
    final row1 = edge.cell1 ~/ width;
    final col1 = edge.cell1 % width;
    final row2 = edge.cell2 ~/ width;
    final col2 = edge.cell2 % width;
    final midRow = (row1 + row2) / 2;
    final midCol = (col1 + col2) / 2;
    final centerDist = (midRow - centerRow).abs() + (midCol - centerCol).abs();
    final centerMax = centerRow + centerCol + 1;
    final centerScore = 1 - (centerDist / centerMax);

    var score = centerScore * 2.2 + (rng() - 0.5) * 0.7;
    final edgeTouch = row1 == 0 ||
        col1 == 0 ||
        row1 == height - 1 ||
        col1 == width - 1 ||
        row2 == 0 ||
        col2 == 0 ||
        row2 == height - 1 ||
        col2 == width - 1;
    if (edgeTouch) {
      score += 0.4;
    }
    candidates.add(MapEntry(edge, score));
  }
  candidates.sort((a, b) => b.value.compareTo(a.value));

  for (final entry in candidates) {
    if (selectedKeys.length >= targetWallCount) {
      break;
    }
    tryAddEdge(entry.key);
  }

  final selectedWalls = selectedKeys.map((key) {
    final parts = key.split(',');
    return Wall(cell1: int.parse(parts[0]), cell2: int.parse(parts[1]));
  }).toList(growable: true);

  // Reliability guard: peel walls back until graph is connected and not overconstrained.
  var guard = 0;
  while (guard < 80 &&
      (!_isStructureConnected(width, height, selectedWalls) ||
          _isStructureOverconstrained(width, height, selectedWalls))) {
    guard++;
    if (selectedWalls.isEmpty) {
      break;
    }
    final idx = (rng() * selectedWalls.length).floor();
    selectedWalls.removeAt(idx);
  }

  return selectedWalls;
}

bool _isStructureConnected(int width, int height, List<Wall> walls) {
  final adjacency = _adjacencyListFromWalls(width, height, walls);
  if (adjacency.isEmpty) {
    return false;
  }
  final seen = List<bool>.filled(adjacency.length, false);
  final queue = <int>[0];
  seen[0] = true;
  while (queue.isNotEmpty) {
    final cell = queue.removeLast();
    for (final n in adjacency[cell]) {
      if (seen[n]) continue;
      seen[n] = true;
      queue.add(n);
    }
  }
  for (final s in seen) {
    if (!s) return false;
  }
  return true;
}

bool _isStructureOverconstrained(
  int width,
  int height,
  List<Wall> walls,
) {
  final adjacency = _adjacencyListFromWalls(width, height, walls);
  var degreeOne = 0;
  for (final neighbors in adjacency) {
    if (neighbors.isEmpty) {
      return true;
    }
    if (neighbors.length == 1) {
      degreeOne++;
    }
  }
  final maxAllowedDegreeOne = (width + height).clamp(8, 20);
  return degreeOne > maxAllowedDegreeOne;
}

List<Wall> _mutateWallsForFeasibility(
  List<Wall> walls,
  int width,
  int height,
  Rng rng,
) {
  if (walls.length < 4) {
    return walls;
  }
  final edges = List<Wall>.from(walls);
  final scale = ((width * height) / 25).floor().clamp(1, 4);
  final removeCount = 2 + scale + (rng() * (3 + scale)).floor();
  for (var i = 0; i < removeCount && edges.length > 3; i++) {
    final idx = (rng() * edges.length).floor();
    edges.removeAt(idx);
  }
  return edges;
}

List<Wall> _reinforceWallsForAmbiguity(
  List<int> path,
  List<Wall> walls,
  int width,
  int height,
  int difficulty,
  Rng rng,
) {
  final wallSet = <String>{for (final w in walls) _edgeKey(w.cell1, w.cell2)};
  final pathAdj = <String>{};
  for (var i = 0; i < path.length - 1; i++) {
    pathAdj.add(_edgeKey(path[i], path[i + 1]));
  }

  final pathIndex = _buildPathIndexMap(path);
  final candidates = <MapEntry<String, double>>[];
  final total = width * height;
  for (var cell = 0; cell < total; cell++) {
    for (final n in _getNeighbors(cell, width, height)) {
      final key = _edgeKey(cell, n);
      if (wallSet.contains(key) || pathAdj.contains(key)) {
        continue;
      }
      if (cell > n) {
        continue;
      }
      final jump = (pathIndex[cell]! - pathIndex[n]!).abs();
      final row1 = cell ~/ width;
      final col1 = cell % width;
      final row2 = n ~/ width;
      final col2 = n % width;
      final centerRow = (height - 1) / 2;
      final centerCol = (width - 1) / 2;
      final midRow = (row1 + row2) / 2;
      final midCol = (col1 + col2) / 2;
      final centerDist =
          (midRow - centerRow).abs() + (midCol - centerCol).abs();
      final centerScore = 1 - (centerDist / (centerRow + centerCol + 1));
      final score = jump * 1.2 + centerScore * 1.8 + (rng() - 0.5) * 0.35;
      candidates.add(MapEntry(key, score));
    }
  }
  candidates.sort((a, b) => b.value.compareTo(a.value));

  final maxAdds = difficulty >= 4 ? 3 : 2;
  var added = 0;
  for (final entry in candidates) {
    if (added >= maxAdds) {
      break;
    }
    final parts = entry.key.split(',');
    final a = int.parse(parts[0]);
    final b = int.parse(parts[1]);
    var aDegree = 0;
    for (final n in _getNeighbors(a, width, height)) {
      if (!wallSet.contains(_edgeKey(a, n))) {
        aDegree++;
      }
    }
    var bDegree = 0;
    for (final n in _getNeighbors(b, width, height)) {
      if (!wallSet.contains(_edgeKey(b, n))) {
        bDegree++;
      }
    }
    if (aDegree <= 1 || bDegree <= 1) {
      continue;
    }
    wallSet.add(entry.key);
    added++;
  }
  return wallSet.map((key) {
    final parts = key.split(',');
    return Wall(cell1: int.parse(parts[0]), cell2: int.parse(parts[1]));
  }).toList(growable: false);
}

Set<String> _buildChamberPartitionEdges(
  List<int> path,
  int width,
  int height,
  int difficulty,
  Rng rng,
) {
  final pathSet = <String>{};
  for (var i = 0; i < path.length - 1; i++) {
    pathSet.add(_edgeKey(path[i], path[i + 1]));
  }

  final edges = <String>{};
  final cutCount = difficulty >= 5 ? 3 : (difficulty >= 4 ? 2 : 1);
  final verticalFirst = rng() < 0.5;

  for (var cut = 0; cut < cutCount; cut++) {
    final vertical = cut.isEven ? verticalFirst : !verticalFirst;
    final gateCount = difficulty >= 4 ? 2 : 1;

    if (vertical && width >= 4) {
      final bias = ((rng() * 3).floor() - 1).clamp(-1, 1);
      final boundaryCol = (width ~/ 2 + bias).clamp(1, width - 2);
      final gateRows = <int>{};
      while (gateRows.length < gateCount) {
        gateRows
            .add((height * (0.2 + rng() * 0.6)).floor().clamp(0, height - 1));
      }

      for (var row = 0; row < height; row++) {
        if (gateRows.contains(row)) continue;
        final a = row * width + boundaryCol;
        final b = a + 1;
        final key = _edgeKey(a, b);
        if (!pathSet.contains(key)) {
          edges.add(key);
        }
      }

      // Add a nearby partial parallel cut to thicken structure.
      final offsetBoundary = (boundaryCol + (rng() < 0.5 ? -1 : 1)).clamp(
        1,
        width - 2,
      );
      var start = (height * 0.15).floor();
      var end = (height * 0.85).ceil();
      if (start >= end) {
        start = 0;
        end = height;
      }
      for (var row = start; row < end; row++) {
        if (gateRows.contains(row) && rng() < 0.7) continue;
        final a = row * width + offsetBoundary;
        final b = a + 1;
        final key = _edgeKey(a, b);
        if (!pathSet.contains(key)) {
          edges.add(key);
        }
      }
    } else if (!vertical && height >= 4) {
      final bias = ((rng() * 3).floor() - 1).clamp(-1, 1);
      final boundaryRow = (height ~/ 2 + bias).clamp(1, height - 2);
      final gateCols = <int>{};
      while (gateCols.length < gateCount) {
        gateCols.add((width * (0.2 + rng() * 0.6)).floor().clamp(0, width - 1));
      }

      for (var col = 0; col < width; col++) {
        if (gateCols.contains(col)) continue;
        final a = boundaryRow * width + col;
        final b = a + width;
        final key = _edgeKey(a, b);
        if (!pathSet.contains(key)) {
          edges.add(key);
        }
      }

      final offsetBoundary = (boundaryRow + (rng() < 0.5 ? -1 : 1)).clamp(
        1,
        height - 2,
      );
      var start = (width * 0.15).floor();
      var end = (width * 0.85).ceil();
      if (start >= end) {
        start = 0;
        end = width;
      }
      for (var col = start; col < end; col++) {
        if (gateCols.contains(col) && rng() < 0.7) continue;
        final a = offsetBoundary * width + col;
        final b = a + width;
        final key = _edgeKey(a, b);
        if (!pathSet.contains(key)) {
          edges.add(key);
        }
      }
    }
  }

  return edges;
}

Set<String> _buildBarrierBlueprintEdges(
  List<int> path,
  int width,
  int height,
  int difficulty,
  Rng rng,
) {
  final total = width * height;
  final centerRow = height ~/ 2;
  final centerCol = width ~/ 2;
  final pathSet = <String>{};
  for (var i = 0; i < path.length - 1; i++) {
    pathSet.add(_edgeKey(path[i], path[i + 1]));
  }

  final barrierEdges = <String>{
    ..._buildChamberPartitionEdges(path, width, height, difficulty, rng),
  };
  final segmentCount = difficulty >= 5 ? 3 : (difficulty >= 3 ? 2 : 1);
  final verticalFirst = rng() < 0.5;

  for (var s = 0; s < segmentCount; s++) {
    final useVertical = (s.isEven ? verticalFirst : !verticalFirst);
    if (useVertical) {
      final colOffset = ((rng() * 3).floor() - 1).clamp(-1, 1);
      final col = (centerCol + colOffset).clamp(1, width - 2);
      final rowStart =
          (centerRow - 2 - (rng() * 2).floor()).clamp(0, height - 2);
      final rowEnd = (centerRow + 2 + (rng() * 2).floor()).clamp(1, height - 1);
      for (var row = rowStart; row < rowEnd; row++) {
        final a = row * width + col;
        final b = (row + 1) * width + col;
        if (a >= 0 &&
            b >= 0 &&
            a < total &&
            b < total &&
            !pathSet.contains(_edgeKey(a, b))) {
          barrierEdges.add(_edgeKey(a, b));
        }
      }
    } else {
      final rowOffset = ((rng() * 3).floor() - 1).clamp(-1, 1);
      final row = (centerRow + rowOffset).clamp(1, height - 2);
      final colStart =
          (centerCol - 2 - (rng() * 2).floor()).clamp(0, width - 2);
      final colEnd = (centerCol + 2 + (rng() * 2).floor()).clamp(1, width - 1);
      for (var col = colStart; col < colEnd; col++) {
        final a = row * width + col;
        final b = row * width + col + 1;
        if (a >= 0 &&
            b >= 0 &&
            a < total &&
            b < total &&
            !pathSet.contains(_edgeKey(a, b))) {
          barrierEdges.add(_edgeKey(a, b));
        }
      }
    }
  }

  return barrierEdges;
}

double _edgeCenterTensionScore(int cell1, int cell2, int width, int height) {
  final centerRow = (height - 1) / 2;
  final centerCol = (width - 1) / 2;
  final row1 = cell1 ~/ width;
  final col1 = cell1 % width;
  final row2 = cell2 ~/ width;
  final col2 = cell2 % width;
  final midRow = (row1 + row2) / 2;
  final midCol = (col1 + col2) / 2;
  final dist = (midRow - centerRow).abs() + (midCol - centerCol).abs();
  final maxDist = centerRow + centerCol + 1;
  return 1 - (dist / maxDist);
}

// ignore: unused_element
List<Wall> _generateExtremeWalls(
  List<int> path,
  int width,
  int height,
  int difficulty,
  double baseWallDensity,
  String packId,
  Rng rng,
) {
  final pathAdj = <String>{};
  for (var i = 0; i < path.length - 1; i++) {
    pathAdj.add(_edgeKey(path[i], path[i + 1]));
  }

  final pathIndexMap = _buildPathIndexMap(path);
  final possible = <Wall>[];
  final total = width * height;
  for (var idx = 0; idx < total; idx++) {
    final row = idx ~/ width;
    final col = idx % width;
    if (col < width - 1) {
      final right = idx + 1;
      if (!pathAdj.contains(_edgeKey(idx, right))) {
        possible.add(Wall(cell1: idx, cell2: right));
      }
    }
    if (row < height - 1) {
      final bottom = idx + width;
      if (!pathAdj.contains(_edgeKey(idx, bottom))) {
        possible.add(Wall(cell1: idx, cell2: bottom));
      }
    }
  }

  final barrierEdges =
      _buildBarrierBlueprintEdges(path, width, height, difficulty, rng);
  final corridorEdges =
      _buildDecoyCorridorEdges(path, width, height, difficulty, rng);
  final corridorNodes = <int>{};
  for (final key in corridorEdges) {
    final parts = key.split(',');
    corridorNodes.add(int.parse(parts[0]));
    corridorNodes.add(int.parse(parts[1]));
  }

  const baseByDifficulty = <double>[0.34, 0.40, 0.52, 0.68, 0.78];
  var ratioBase = baseByDifficulty[(difficulty - 1).clamp(0, 4)];
  ratioBase += (baseWallDensity - 0.12) * 0.35;
  ratioBase += packId == 'expert' ? 0.04 : 0;
  ratioBase += (rng() - 0.5) * 0.08;
  ratioBase = ratioBase.clamp(0.56, 0.84);

  var wallCount = (possible.length * ratioBase).round();
  wallCount = wallCount.clamp(
    (possible.length * 0.48).round(),
    (possible.length * 0.90).round(),
  );

  final scored = <MapEntry<Wall, double>>[];
  for (final edge in possible) {
    final key = _edgeKey(edge.cell1, edge.cell2);
    var score = rng() * 1.2;

    if (corridorEdges.contains(key)) {
      score -= 100;
    }
    if (barrierEdges.contains(key)) {
      score += 5.0;
    }

    final touchesCorridor = corridorNodes.contains(edge.cell1) ||
        corridorNodes.contains(edge.cell2);
    if (touchesCorridor && !corridorEdges.contains(key)) {
      score += 3.6;
    }

    final idxA = pathIndexMap[edge.cell1]!;
    final idxB = pathIndexMap[edge.cell2]!;
    final avgProgress = ((idxA + idxB) / 2) / (path.length - 1);
    if (avgProgress > 0.6 && avgProgress < 0.9) {
      score += 1.2;
    }
    final pathLeap = (idxA - idxB).abs();
    if (pathLeap >= width) {
      score += 2.1;
    } else if (pathLeap >= width ~/ 2) {
      score += 1.2;
    }

    final centerScore =
        _edgeCenterTensionScore(edge.cell1, edge.cell2, width, height);
    score += centerScore * 2.0;

    final rowA = edge.cell1 ~/ width;
    final colA = edge.cell1 % width;
    final rowB = edge.cell2 ~/ width;
    final colB = edge.cell2 % width;
    final edgeTouch = rowA == 0 ||
        colA == 0 ||
        rowA == height - 1 ||
        colA == width - 1 ||
        rowB == 0 ||
        colB == 0 ||
        rowB == height - 1 ||
        colB == width - 1;
    if (edgeTouch) score += 0.4;

    final mirroredCell1 = (height - 1 - rowA) * width + (width - 1 - colA);
    final mirroredCell2 = (height - 1 - rowB) * width + (width - 1 - colB);
    final mirrorKey = _edgeKey(mirroredCell1, mirroredCell2);
    if (mirrorKey != key && !pathAdj.contains(mirrorKey) && rng() < 0.45) {
      score += 0.7;
    }

    scored.add(MapEntry(edge, score));
  }

  scored.sort((a, b) => b.value.compareTo(a.value));
  final selected = <Wall>[];
  final preservedJumps = <String>{};
  for (final edge in possible) {
    final idxA = pathIndexMap[edge.cell1]!;
    final idxB = pathIndexMap[edge.cell2]!;
    if ((idxA - idxB).abs() >= width + 1 && rng() < 0.26) {
      preservedJumps.add(_edgeKey(edge.cell1, edge.cell2));
    }
  }
  for (final entry in scored) {
    if (selected.length >= wallCount) {
      break;
    }
    final key = _edgeKey(entry.key.cell1, entry.key.cell2);
    if (preservedJumps.contains(key)) {
      continue;
    }
    selected.add(entry.key);
  }
  return selected;
}

int _countOpenChoicesAlongPath(
  List<int> path,
  List<Wall> walls,
  int width,
  int height,
) {
  final wallSet = <String>{};
  for (final w in walls) {
    wallSet.add(_edgeKey(w.cell1, w.cell2));
  }

  final visited = <int>{};
  var branching = 0;

  for (var i = 0; i < path.length - 1; i++) {
    final current = path[i];
    visited.add(current);
    var options = 0;
    for (final n in _getNeighbors(current, width, height)) {
      if (visited.contains(n)) continue;
      if (wallSet.contains(_edgeKey(current, n))) continue;
      options++;
    }
    if (options > 1) branching++;
  }
  return branching;
}

int _countConsecutiveDegreeOneSteps(
  List<int> path,
  List<Wall> walls,
  int width,
  int height,
) {
  final wallSet = <String>{};
  for (final w in walls) {
    wallSet.add(_edgeKey(w.cell1, w.cell2));
  }

  final visited = <int>{};
  var currentRun = 0;
  var longestRun = 0;
  for (var i = 0; i < path.length - 1; i++) {
    final current = path[i];
    visited.add(current);
    var options = 0;
    for (final n in _getNeighbors(current, width, height)) {
      if (visited.contains(n)) continue;
      if (wallSet.contains(_edgeKey(current, n))) continue;
      options++;
    }
    if (options <= 1) {
      currentRun++;
      if (currentRun > longestRun) {
        longestRun = currentRun;
      }
    } else {
      currentRun = 0;
    }
  }
  return longestRun;
}

int _countConflictZones(
  List<int> path,
  List<Wall> walls,
  int width,
  int height,
) {
  final adjacency = _buildAdjacency(width, height, walls);
  var zones = 0;
  for (final cell in path) {
    final degree = (adjacency[cell] ?? const <int>[]).length;
    if (degree >= 3) {
      zones++;
    }
  }
  return zones;
}

int _estimateChamberCount(List<Wall> walls, int width, int height) {
  final wallSet = <String>{};
  for (final w in walls) {
    wallSet.add(_edgeKey(w.cell1, w.cell2));
  }

  var verticalDividers = 0;
  for (var col = 0; col < width - 1; col++) {
    var blocked = 0;
    for (var row = 0; row < height; row++) {
      final a = row * width + col;
      final b = a + 1;
      if (wallSet.contains(_edgeKey(a, b))) {
        blocked++;
      }
    }
    if (blocked >= height - 2) {
      verticalDividers++;
    }
  }

  var horizontalDividers = 0;
  for (var row = 0; row < height - 1; row++) {
    var blocked = 0;
    for (var col = 0; col < width; col++) {
      final a = row * width + col;
      final b = a + width;
      if (wallSet.contains(_edgeKey(a, b))) {
        blocked++;
      }
    }
    if (blocked >= width - 2) {
      horizontalDividers++;
    }
  }

  final chambers = (verticalDividers + 1) * (horizontalDividers + 1);
  return chambers.clamp(1, 16);
}

int _countStrongChokepoints(List<Wall> walls, int width, int height) {
  final wallSet = <String>{};
  for (final w in walls) {
    wallSet.add(_edgeKey(w.cell1, w.cell2));
  }
  var chokepoints = 0;

  for (var col = 0; col < width - 1; col++) {
    var blocked = 0;
    for (var row = 0; row < height; row++) {
      final a = row * width + col;
      final b = a + 1;
      if (wallSet.contains(_edgeKey(a, b))) {
        blocked++;
      }
    }
    final open = height - blocked;
    if (blocked >= height - 3 && open <= 2) {
      chokepoints++;
    }
  }

  for (var row = 0; row < height - 1; row++) {
    var blocked = 0;
    for (var col = 0; col < width; col++) {
      final a = row * width + col;
      final b = a + width;
      if (wallSet.contains(_edgeKey(a, b))) {
        blocked++;
      }
    }
    final open = width - blocked;
    if (blocked >= width - 3 && open <= 2) {
      chokepoints++;
    }
  }
  return chokepoints;
}

double _centralCompressionDensity(List<Wall> walls, int width, int height) {
  final rMin = (height * 0.25).floor();
  final rMax = (height * 0.75).ceil().clamp(1, height - 1);
  final cMin = (width * 0.25).floor();
  final cMax = (width * 0.75).ceil().clamp(1, width - 1);
  if (rMin >= rMax || cMin >= cMax) {
    return 0;
  }

  var inCenter = 0;
  for (final w in walls) {
    final r1 = w.cell1 ~/ width;
    final c1 = w.cell1 % width;
    final r2 = w.cell2 ~/ width;
    final c2 = w.cell2 % width;
    final mr = (r1 + r2) / 2;
    final mc = (c1 + c2) / 2;
    if (mr >= rMin && mr <= rMax && mc >= cMin && mc <= cMax) {
      inCenter++;
    }
  }
  return inCenter / walls.length.clamp(1, 999999);
}

bool _hasAlternativeRoutePressure(
  Level level, {
  required int difficulty,
}) {
  final orderedCells = _orderedNumberCells(level.numbers);
  if (orderedCells.length < 2) {
    return false;
  }
  final pathIndexMap = _buildPathIndexMap(level.solution);
  final adjacency = _buildAdjacency(level.width, level.height, level.walls);

  var pressuredPairs = 0;
  for (var i = 0; i < orderedCells.length - 1; i++) {
    final from = orderedCells[i];
    final to = orderedCells[i + 1];
    final fromPos = pathIndexMap[from];
    final toPos = pathIndexMap[to];
    if (fromPos == null || toPos == null) {
      continue;
    }
    final start = fromPos < toPos ? fromPos : toPos;
    final end = fromPos < toPos ? toPos : fromPos;
    var segmentPressure = 0;
    for (var p = start; p <= end; p++) {
      final cell = level.solution[p];
      if ((adjacency[cell] ?? const <int>[]).length >= 3) {
        segmentPressure++;
      }
    }
    final directOptions = (adjacency[from] ?? const <int>[]).length;
    if (segmentPressure > 0 && directOptions >= 2) {
      pressuredPairs++;
    }
  }

  final requiredRatio = difficulty >= 4 ? 0.55 : 0.35;
  return pressuredPairs / (orderedCells.length - 1) >= requiredRatio;
}

double _spatialDispersionScore(Map<int, int> numbers, int width, int height) {
  final cells = _orderedNumberCells(numbers);
  if (cells.length < 2) {
    return 0;
  }
  final quadrants = <int>{};
  for (final cell in cells) {
    final row = cell ~/ width;
    final col = cell % width;
    final top = row < height / 2 ? 0 : 1;
    final left = col < width / 2 ? 0 : 1;
    quadrants.add(top * 2 + left);
  }
  final minR = (height * 0.2).floor();
  final maxR = (height * 0.8).ceil();
  final minC = (width * 0.2).floor();
  final maxC = (width * 0.8).ceil();
  var centerBandHits = 0;
  for (final cell in cells) {
    final row = cell ~/ width;
    final col = cell % width;
    if (row >= minR && row <= maxR && col >= minC && col <= maxC) {
      centerBandHits++;
    }
  }
  return quadrants.length + centerBandHits / cells.length;
}

bool _hasGoodTurnEntropy(
  List<int> solution,
  int width,
  int height,
  int straightRunCap,
) {
  final stats = _turnEntropyStats(solution, width, height);
  if (stats.turnRate < 0.28) {
    return false;
  }
  if (stats.longestStraight > straightRunCap) {
    return false;
  }
  return stats.perimeterRatio < 0.68;
}

({double turnRate, int longestStraight, double perimeterRatio})
    _turnEntropyStats(
  List<int> solution,
  int width,
  int height,
) {
  if (solution.length < 4) {
    return (
      turnRate: 0,
      longestStraight: solution.length,
      perimeterRatio: 1.0,
    );
  }
  final dirs = <int>[];
  for (var i = 0; i < solution.length - 1; i++) {
    final a = solution[i];
    final b = solution[i + 1];
    if (b == a + 1) {
      dirs.add(0); // right
    } else if (b == a - 1) {
      dirs.add(1); // left
    } else if (b == a + width) {
      dirs.add(2); // down
    } else {
      dirs.add(3); // up
    }
  }
  var turns = 0;
  var longestStraight = 1;
  var straightRun = 1;
  for (var i = 1; i < dirs.length; i++) {
    if (dirs[i] == dirs[i - 1]) {
      straightRun++;
      if (straightRun > longestStraight) {
        longestStraight = straightRun;
      }
    } else {
      turns++;
      straightRun = 1;
    }
  }
  final turnRate = turns / (dirs.length - 1);
  final earlyLength =
      (solution.length * 0.65).floor().clamp(1, solution.length);
  var perimeterEarly = 0;
  for (var i = 0; i < earlyLength; i++) {
    if (_isEdgeOrCorner(solution[i], width, height)) {
      perimeterEarly++;
    }
  }
  final perimeterRatio = perimeterEarly / earlyLength;
  return (
    turnRate: turnRate,
    longestStraight: longestStraight,
    perimeterRatio: perimeterRatio,
  );
}

int _localRegionId(int cell, int width, int height) {
  final row = cell ~/ width;
  final col = cell % width;
  final rowBucket = ((row * 3) ~/ height).clamp(0, 2);
  final colBucket = ((col * 3) ~/ width).clamp(0, 2);
  return rowBucket * 3 + colBucket;
}

int _earlySeparationThreshold(int width, int height) {
  final maxSide = width > height ? width : height;
  if (maxSide >= 9) return 7;
  if (maxSide >= 8) return 6;
  if (maxSide >= 7) return 3;
  return 4;
}

int _regionSpreadCount(Iterable<int> cells, int width, int height) {
  final regions = <int>{};
  for (final cell in cells) {
    regions.add(_localRegionId(cell, width, height));
  }
  return regions.length;
}

bool _earlyClueSeparationSatisfied(
  List<int> earlyClueCells,
  int width,
  int height, {
  required int minDistance,
  required bool strict,
}) {
  if (earlyClueCells.length < 4) {
    return false;
  }
  final one = earlyClueCells[0];
  final two = earlyClueCells[1];
  final three = earlyClueCells[2];
  final four = earlyClueCells[3];
  final d12 = _manhattanCellDistance(one, two, width);
  final d23 = _manhattanCellDistance(two, three, width);
  final d34 = _manhattanCellDistance(three, four, width);
  final cross13 = _manhattanCellDistance(one, three, width);
  final cross14 = _manhattanCellDistance(one, four, width);
  final cross24 = _manhattanCellDistance(two, four, width);
  final minConsecutive = strict ? minDistance : (minDistance - 1).clamp(4, 7);
  final minCross = strict ? minDistance : (minDistance - 2).clamp(3, 6);
  if (d12 < minConsecutive || d23 < minConsecutive || d34 < minConsecutive) {
    return false;
  }
  if (cross13 < minCross || cross14 < minCross || cross24 < minCross) {
    return false;
  }
  final spread = _regionSpreadCount(earlyClueCells.take(4), width, height);
  if (spread < 2) {
    return false;
  }
  final rows = earlyClueCells.take(4).map((c) => c ~/ width).toSet();
  final cols = earlyClueCells.take(4).map((c) => c % width).toSet();
  if (rows.length <= 1 || cols.length <= 1) {
    return false;
  }
  return true;
}

bool _hasTooManyConsecutiveLocalClues(Level level) {
  final ordered = _orderedNumberCells(level.numbers);
  if (ordered.length < 3) {
    return false;
  }
  var run = 1;
  var prevRegion = _localRegionId(ordered.first, level.width, level.height);
  for (var i = 1; i < ordered.length; i++) {
    final region = _localRegionId(ordered[i], level.width, level.height);
    if (region == prevRegion) {
      run++;
      if (run > 2) {
        return true;
      }
    } else {
      run = 1;
      prevRegion = region;
    }
  }
  return false;
}

bool _requiresStrongEarlySeparation(String packId, String? generationProfile) {
  if (packId == 'daily') return true;
  if (packId == 'classic') {
    if (generationProfile == 'campaign_low') {
      return false;
    }
    return true;
  }
  return false;
}

bool _passesEarlySeparationGate(
  Level level, {
  required String packId,
  required String? generationProfile,
}) {
  final ordered = _orderedNumberCells(level.numbers);
  if (ordered.length < 4) {
    return false;
  }
  final strict = _requiresStrongEarlySeparation(packId, generationProfile);
  if (!strict) {
    return true;
  }
  final minDistance = _earlySeparationThreshold(level.width, level.height);
  final early = ordered.take(4).toList(growable: false);
  if (!_earlyClueSeparationSatisfied(
    early,
    level.width,
    level.height,
    minDistance: minDistance,
    strict: true,
  )) {
    return false;
  }
  final spread = _regionSpreadCount(early, level.width, level.height);
  return spread >= 2;
}

bool _passesEarlyJumpPressure(Level level) {
  final ordered = _orderedNumberCells(level.numbers);
  if (ordered.length < 4) {
    return false;
  }
  final minDistance =
      (_earlySeparationThreshold(level.width, level.height) - 1).clamp(3, 7);
  final early = ordered.take(4).toList(growable: false);
  var strongJumps = 0;
  for (var i = 0; i < early.length - 1; i++) {
    final d = _manhattanCellDistance(early[i], early[i + 1], level.width);
    if (d < (minDistance - 1).clamp(2, 6)) {
      return false;
    }
    if (d >= minDistance) {
      strongJumps++;
    }
  }
  return strongJumps >= 2;
}

int _simulateWrongBranchDepth({
  required int start,
  required int from,
  required Set<int> visitedPrefix,
  required Map<int, List<int>> adjacency,
  int maxDepth = 8,
}) {
  var prev = from;
  var current = start;
  final visited = <int>{...visitedPrefix, start};
  var depth = 1;

  while (depth < maxDepth) {
    final options = <int>[];
    for (final n in adjacency[current] ?? const <int>[]) {
      if (n == prev || visited.contains(n)) {
        continue;
      }
      options.add(n);
    }
    if (options.isEmpty) {
      return depth;
    }
    options.sort((a, b) {
      final da = (adjacency[a] ?? const <int>[]).length;
      final db = (adjacency[b] ?? const <int>[]).length;
      return db.compareTo(da);
    });
    final next = options.first;
    prev = current;
    current = next;
    visited.add(current);
    depth++;
  }
  return depth;
}

bool _hasDelayedTrap(
  List<int> path,
  List<Wall> walls,
  int width,
  int height,
) {
  final adjacency = _buildAdjacency(width, height, walls);
  final earlyLimit = (path.length * 0.28).floor().clamp(4, 22);
  var delayedTrapFound = false;

  for (var i = 1; i < earlyLimit && i < path.length - 2; i++) {
    final current = path[i];
    final trueNext = path[i + 1];
    final prefixVisited = <int>{for (var p = 0; p <= i; p++) path[p]};
    for (final n in adjacency[current] ?? const <int>[]) {
      if (n == trueNext || prefixVisited.contains(n)) {
        continue;
      }
      final failDepth = _simulateWrongBranchDepth(
        start: n,
        from: current,
        visitedPrefix: prefixVisited,
        adjacency: adjacency,
      );
      if (failDepth >= 3 && failDepth <= 7) {
        delayedTrapFound = true;
        break;
      }
    }
    if (delayedTrapFound) {
      break;
    }
  }
  return delayedTrapFound;
}

_ErcResult _enclosureRiskCurveScore(Level level) {
  final checkpoints = <double>[0.10, 0.20, 0.30, 0.40];
  final adjacency = _buildAdjacency(level.width, level.height, level.walls);
  final totalCells = level.width * level.height;
  final checkpointStats = <_ErcCheckpointStats>[];

  for (final ratio in checkpoints) {
    final k = (totalCells * ratio).floor().clamp(1, totalCells - 1);
    final visited = <int>{for (var i = 0; i < k; i++) level.solution[i]};
    final seen = <int>{};
    var numComponents = 0;
    var maxComponentSize = 0;
    var mediumLowFrontierCount = 0;
    var tinyComponents = 0;
    var totalNarrowEntries = 0;
    var totalFrontierEdges = 0;

    for (var cell = 0; cell < totalCells; cell++) {
      if (visited.contains(cell) || seen.contains(cell)) {
        continue;
      }
      numComponents++;
      final queue = <int>[cell];
      seen.add(cell);
      final component = <int>[];
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        component.add(current);
        for (final n in adjacency[current] ?? const <int>[]) {
          if (visited.contains(n) || seen.contains(n)) {
            continue;
          }
          seen.add(n);
          queue.add(n);
        }
      }

      if (component.length > maxComponentSize) {
        maxComponentSize = component.length;
      }
      if (component.length <= 3) {
        tinyComponents++;
      }

      var boundaryEdges = 0;
      var narrowEntries = 0;
      for (final c in component) {
        var remainingDegree = 0;
        for (final n in adjacency[c] ?? const <int>[]) {
          if (visited.contains(n)) {
            boundaryEdges++;
          } else {
            remainingDegree++;
          }
        }
        if (remainingDegree <= 1) {
          narrowEntries++;
        }
      }
      if (component.length >= 8 &&
          component.length <= 20 &&
          boundaryEdges <= 3) {
        mediumLowFrontierCount++;
      }
      totalNarrowEntries += narrowEntries;
      totalFrontierEdges += boundaryEdges;
    }

    final frontierRatio =
        totalFrontierEdges / (totalCells - k).clamp(1, totalCells);
    var pressure = 0.0;
    if (numComponents >= 2) {
      pressure += 1.0;
    }
    pressure += mediumLowFrontierCount * 0.55;
    pressure += (totalNarrowEntries >= 2 ? 0.45 : 0.0);
    pressure -= tinyComponents * 0.35;
    if (numComponents == 1 && frontierRatio > 1.05) {
      pressure -= 0.6;
    }

    checkpointStats.add(
      _ErcCheckpointStats(
        prefixRatio: ratio,
        components: numComponents,
        maxComponentSize: maxComponentSize,
        mediumLowFrontierCount: mediumLowFrontierCount,
        tinyComponents: tinyComponents,
        narrowEntries: totalNarrowEntries,
        frontierRatio: frontierRatio,
        pressure: pressure,
      ),
    );
  }

  var totalScore = 0.0;
  for (final cp in checkpointStats) {
    totalScore += cp.pressure;
  }
  return _ErcResult(
    score: totalScore / checkpointStats.length.clamp(1, 99),
    checkpoints: checkpointStats,
  );
}

bool _passesERC(Level level, _ModeValidationPolicy policy) {
  if (!policy.enforceErc) {
    return true;
  }
  final result = _enclosureRiskCurveScore(level);
  if (result.score < policy.ercMinScore) {
    return false;
  }

  var hasValidMidCheckpoint = false;
  for (final cp in result.checkpoints) {
    if ((cp.prefixRatio - 0.20).abs() < 0.011 ||
        (cp.prefixRatio - 0.30).abs() < 0.011) {
      final splitOk = cp.components >= 2;
      final narrowOk = cp.components == 1 && cp.narrowEntries >= 2;
      if (splitOk || narrowOk) {
        hasValidMidCheckpoint = true;
      }
    }
    if (cp.tinyComponents > policy.maxTinyComponentsPerCheckpoint) {
      return false;
    }
  }
  if (policy.requireMidSplitOrNarrow && !hasValidMidCheckpoint) {
    return false;
  }

  var allTooOpen = true;
  for (final cp in result.checkpoints) {
    if (!(cp.components == 1 &&
        cp.frontierRatio > 1.30 &&
        cp.narrowEntries < 2 &&
        cp.mediumLowFrontierCount == 0)) {
      allTooOpen = false;
      break;
    }
  }
  return !allTooOpen;
}

int _simulateAlternativePlausibility({
  required int start,
  required int from,
  required Set<int> visitedPrefix,
  required Map<int, List<int>> adjacency,
  required int sampleSeed,
  int maxDepth = 10,
}) {
  final rng = createRng(sampleSeed);
  var previous = from;
  var current = start;
  final visited = <int>{...visitedPrefix, start};
  var depth = 1;

  while (depth < maxDepth) {
    final candidates = <int>[];
    for (final n in adjacency[current] ?? const <int>[]) {
      if (n == previous || visited.contains(n)) {
        continue;
      }
      candidates.add(n);
    }
    if (candidates.isEmpty) {
      return depth;
    }
    candidates.sort((a, b) {
      final da = (adjacency[a] ?? const <int>[]).length;
      final db = (adjacency[b] ?? const <int>[]).length;
      return db.compareTo(da);
    });
    final pickWindow = candidates.length < 3 ? candidates.length : 3;
    final chosen = candidates[(rng() * pickWindow).floor()];
    previous = current;
    current = chosen;
    visited.add(current);
    depth++;
  }
  return depth;
}

_CasResult _clueSegmentAmbiguityScore(
  Level level, {
  bool earlyOnly = false,
}) {
  final clueCells = _orderedNumberCells(level.numbers);
  if (clueCells.length < 2) {
    return const _CasResult(
      score: 0,
      earlyAmbiguousSegments: 0,
      earlyFirstTwoAmbiguousSegments: 0,
      segmentStats: <_CasSegmentStats>[],
    );
  }

  final pathIndex = _buildPathIndexMap(level.solution);
  final adjacency = _buildAdjacency(level.width, level.height, level.walls);
  final segmentStats = <_CasSegmentStats>[];
  var weightedScore = 0.0;
  var scoreWeight = 0.0;
  var earlyAmbiguous = 0;
  var earlyFirstTwoAmbiguous = 0;

  final fullSegmentCount = clueCells.length - 1;
  final segmentCount =
      earlyOnly ? fullSegmentCount.clamp(1, 4) : fullSegmentCount;
  for (var seg = 0; seg < segmentCount; seg++) {
    final fromCell = clueCells[seg];
    final toCell = clueCells[seg + 1];
    final fromIdx = pathIndex[fromCell];
    final toIdx = pathIndex[toCell];
    if (fromIdx == null || toIdx == null) {
      continue;
    }
    final start = fromIdx < toIdx ? fromIdx : toIdx;
    final end = fromIdx < toIdx ? toIdx : fromIdx;
    if (end <= start) {
      continue;
    }

    var maxBranching = 0;
    var plausibleAlternatives = 0;
    var segmentScore = 0.0;
    var segmentSamples = 0;

    final maxSample = start + 2 < end ? start + 2 : end - 1;
    for (var sample = start; sample <= maxSample; sample++) {
      final current = level.solution[sample];
      final trueNext = level.solution[sample + 1];
      final visited = <int>{
        for (var i = 0; i <= sample; i++) level.solution[i]
      };
      final nextMoves = <int>[];
      for (final n in adjacency[current] ?? const <int>[]) {
        if (!visited.contains(n)) {
          nextMoves.add(n);
        }
      }
      if (nextMoves.length > maxBranching) {
        maxBranching = nextMoves.length;
      }
      if (nextMoves.length >= 2) {
        segmentScore += 0.6;
      }

      for (final move in nextMoves) {
        if (move == trueNext) {
          continue;
        }
        final survival = _simulateAlternativePlausibility(
          start: move,
          from: current,
          visitedPrefix: visited,
          adjacency: adjacency,
          sampleSeed: current ^ (move << 5) ^ (sample * 131),
        );
        if (survival >= 4) {
          plausibleAlternatives++;
          segmentScore += survival >= 6 ? 0.45 : 0.3;
        }
      }
      segmentSamples++;
    }

    final normalizedScore =
        segmentSamples == 0 ? 0.0 : segmentScore / segmentSamples.toDouble();
    final isEarly = seg < 4;
    final ambiguousSegment = maxBranching >= 2 && plausibleAlternatives >= 1;
    if (isEarly && ambiguousSegment) {
      earlyAmbiguous++;
      if (seg < 2) {
        earlyFirstTwoAmbiguous++;
      }
    }

    final segmentNumber = seg + 1;
    segmentStats.add(
      _CasSegmentStats(
        segmentNumber: segmentNumber,
        maxBranching: maxBranching,
        plausibleAlternatives: plausibleAlternatives,
        segmentScore: normalizedScore,
      ),
    );

    final weight = isEarly ? 1.5 : 1.0;
    weightedScore += normalizedScore * weight;
    scoreWeight += weight;
  }

  return _CasResult(
    score: scoreWeight == 0 ? 0 : weightedScore / scoreWeight,
    earlyAmbiguousSegments: earlyAmbiguous,
    earlyFirstTwoAmbiguousSegments: earlyFirstTwoAmbiguous,
    segmentStats: segmentStats,
  );
}

bool _passesCAS(Level level, _ModeValidationPolicy policy) {
  if (!policy.enforceCas) {
    return true;
  }
  final result = _clueSegmentAmbiguityScore(
    level,
    earlyOnly: policy.casEarlyOnly,
  );
  if (result.score < policy.casMinScore) {
    return false;
  }
  if (result.earlyAmbiguousSegments < policy.casMinEarlyAmbiguousSegments) {
    return false;
  }
  if (policy.casRequireFirstTwoEarlySegments &&
      result.earlyFirstTwoAmbiguousSegments < 2) {
    return false;
  }
  var earlyFirstThreeAmbiguous = 0;
  for (final stat in result.segmentStats) {
    if (stat.segmentNumber > 3) {
      continue;
    }
    if (stat.maxBranching >= 2 && stat.plausibleAlternatives >= 1) {
      earlyFirstThreeAmbiguous++;
    }
  }
  if (policy.casMinEarlyAmbiguousSegments >= 2 &&
      earlyFirstThreeAmbiguous < 2) {
    return false;
  }
  return true;
}

bool _isOverSymmetric(Map<int, int> numbers, int width, int height) {
  if (numbers.length < 6) {
    return false;
  }
  final cells = numbers.keys.toSet();
  var mirroredHits = 0;
  for (final cell in cells) {
    final row = cell ~/ width;
    final col = cell % width;
    final mirrored = (height - 1 - row) * width + (width - 1 - col);
    if (cells.contains(mirrored)) {
      mirroredHits++;
    }
  }
  final ratio = mirroredHits / cells.length;
  return ratio > 0.72;
}

bool _hasLateConstraintNumber(Map<int, int> numbers, List<int> path) {
  if (numbers.length < 3) return true;
  final maxNumber = numbers.values.reduce((a, b) => a > b ? a : b);
  var lateFound = false;
  for (final entry in numbers.entries) {
    final number = entry.value;
    if (number == 1 || number == maxNumber) continue;
    final pos = _pathIndexOf(path, entry.key);
    if (pos < 0) continue;
    final progress = pos / (path.length - 1);
    if (progress >= 0.68) {
      lateFound = true;
      break;
    }
  }
  return lateFound;
}

List<int> _orderedNumberCells(Map<int, int> numbers) {
  final entries = numbers.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  return entries.map((e) => e.key).toList(growable: false);
}

int _countLongClueJumps(
  Map<int, int> numbers,
  int width,
  int minJump,
) {
  final ordered = _orderedNumberCells(numbers);
  if (ordered.length < 2) {
    return 0;
  }
  var count = 0;
  for (var i = 0; i < ordered.length - 1; i++) {
    final d = _manhattanCellDistance(ordered[i], ordered[i + 1], width);
    if (d >= minJump) {
      count++;
    }
  }
  return count;
}

bool _passesConsecutiveClueDistance(
  Level level, {
  required int difficulty,
  int relaxation = 0,
}) {
  final ordered = _orderedNumberCells(level.numbers);
  if (ordered.length < 2) {
    return false;
  }
  final minJump = _minJumpForDifficulty(difficulty, level.width, level.height);
  final allowedShortPairs = difficulty >= 4 ? 2 : (difficulty >= 3 ? 1 : 0);
  final relaxedMinJump = (minJump - relaxation).clamp(1, minJump);
  final relaxedShortPairs = allowedShortPairs + relaxation;
  var shortPairs = 0;
  for (var i = 0; i < ordered.length - 1; i++) {
    final d = _manhattanCellDistance(ordered[i], ordered[i + 1], level.width);
    if (d < relaxedMinJump) {
      shortPairs++;
      if (shortPairs > relaxedShortPairs) {
        return false;
      }
    }
  }
  if (relaxation < 3 && _hasTooManyConsecutiveLocalClues(level)) {
    return false;
  }
  return true;
}

bool _hasConsecutiveCompleteClueValues(Map<int, int> numbers) {
  if (numbers.isEmpty) {
    return false;
  }
  final values = numbers.values.toList()..sort();
  final maxValue = values.last;
  if (maxValue != values.length) {
    return false;
  }
  for (var i = 0; i < values.length; i++) {
    if (values[i] != i + 1) {
      return false;
    }
  }
  return true;
}

bool _numbersStrictlyIncreaseAlongSolution(Level level) {
  if (level.numbers.isEmpty) {
    return false;
  }
  var expected = 1;
  for (final cell in level.solution) {
    final number = level.numbers[cell];
    if (number == null) {
      continue;
    }
    if (number != expected) {
      return false;
    }
    expected++;
  }
  final maxNumber = level.numbers.values.reduce((a, b) => a > b ? a : b);
  return expected == maxNumber + 1;
}

GenerationFailReason? _cheapFeasibilityFailure(
  Level level, {
  required int difficulty,
  required String packId,
  required StrictnessProfile profile,
  required String? generationProfile,
}) {
  final chamberCount = _estimateChamberCount(
    level.walls,
    level.width,
    level.height,
  );
  final chokepoints = _countStrongChokepoints(
    level.walls,
    level.width,
    level.height,
  );
  final longestDegreeOneRun = _countConsecutiveDegreeOneSteps(
    level.solution,
    level.walls,
    level.width,
    level.height,
  );
  final turnStats =
      _turnEntropyStats(level.solution, level.width, level.height);

  final dailyLike = packId == 'daily' ||
      generationProfile == 'daily_hard' ||
      generationProfile == 'daily_hard_soft';
  final dailySoft = generationProfile?.contains('daily_hard_soft') ?? false;
  final campaignHard = generationProfile == 'campaign_high' ||
      generationProfile == 'campaign_elite';

  final minDailyChambers = 1;
  if ((dailyLike && chamberCount < minDailyChambers) ||
      (campaignHard && chamberCount < 1)) {
    return GenerationFailReason.chamberDensityTooLow;
  }
  final minDailyChokepoints = 0;
  if ((dailyLike && chokepoints < minDailyChokepoints) ||
      (campaignHard && chokepoints < 0)) {
    return GenerationFailReason.insufficientChokepoints;
  }
  if (longestDegreeOneRun >
      (difficulty >= 4 ? level.width + 1 : level.width + 2)) {
    return GenerationFailReason.degreeOneRunTooLong;
  }
  final dailyStraightSlack = dailySoft ? 5 : (dailyLike ? 3 : 0);
  final maxPerimeterRatio = dailySoft ? 0.90 : (dailyLike ? 0.80 : 0.72);
  if (turnStats.longestStraight >
          profile.straightRunCap + 1 + dailyStraightSlack ||
      turnStats.perimeterRatio > maxPerimeterRatio) {
    return GenerationFailReason.tooLinear;
  }
  return null;
}

GenerationFailReason? _baselineFailureReason(
  Level level, {
  required int difficulty,
  required String packId,
  required StrictnessProfile profile,
  required _ModeValidationPolicy policy,
  required String? generationProfile,
}) {
  final relaxation = profile.relaxation;
  final chamberCount = _estimateChamberCount(
    level.walls,
    level.width,
    level.height,
  );
  final dailyLike = packId == 'daily' ||
      (generationProfile?.startsWith('daily_hard') ?? false);
  final dailySoftProfile =
      generationProfile?.contains('daily_hard_soft') ?? false;
  final minChambers = (difficulty >= 4 ? 3 : 2) - relaxation;
  final dailyStrict = packId == 'daily' &&
      generationProfile != 'daily_hard_soft' &&
      generationProfile != 'daily_hard_soft|thin=1';
  final dailySoft = packId == 'daily' &&
      (generationProfile == 'daily_hard_soft' ||
          generationProfile?.contains('daily_hard_soft') == true);
  final effectiveMinChambers = dailyStrict ? 1 : (dailySoft ? 1 : minChambers);
  final campaignHigh = generationProfile == 'campaign_high' ||
      generationProfile == 'campaign_elite';
  final adjustedMinChambers = campaignHigh
      ? (effectiveMinChambers - 1).clamp(1, 6)
      : effectiveMinChambers;
  if (chamberCount < adjustedMinChambers) {
    return GenerationFailReason.chamberDensityTooLow;
  }
  if (packId == 'architect' && chamberCount < 2) {
    return GenerationFailReason.chamberDensityTooLow;
  }
  final chokepoints = _countStrongChokepoints(
    level.walls,
    level.width,
    level.height,
  );
  final architectMinChokepoints = profile.relaxation >= 3 ? 1 : 2;
  if (packId == 'architect' && chokepoints < architectMinChokepoints) {
    return GenerationFailReason.insufficientChokepoints;
  }
  final centerCompression = _centralCompressionDensity(
    level.walls,
    level.width,
    level.height,
  );
  final architectCompressionTarget = profile.relaxation >= 3 ? 0.22 : 0.34;
  if (packId == 'architect' && centerCompression < architectCompressionTarget) {
    return GenerationFailReason.centralCompressionLow;
  }

  final branching = _countOpenChoicesAlongPath(
    level.solution,
    level.walls,
    level.width,
    level.height,
  );
  final minBranchingByDifficulty = <int>[2, 3, 5, 8, 12];
  final minBranching = minBranchingByDifficulty[(difficulty - 1).clamp(0, 4)];
  if (branching < (minBranching - relaxation * 2)) {
    return GenerationFailReason.branchingTooLow;
  }
  if (packId == 'architect' && branching < 8) {
    return GenerationFailReason.branchingTooLow;
  }

  final conflictZones = _countConflictZones(
    level.solution,
    level.walls,
    level.width,
    level.height,
  );
  final minConflictByDifficulty = <int>[2, 4, 6, 10, 14];
  final minConflict = minConflictByDifficulty[(difficulty - 1).clamp(0, 4)];
  if (conflictZones < (minConflict - relaxation * 2)) {
    return GenerationFailReason.conflictZonesTooLow;
  }

  final longestDegreeOneRun = _countConsecutiveDegreeOneSteps(
    level.solution,
    level.walls,
    level.width,
    level.height,
  );
  final maxDegreeOneRun =
      (difficulty >= 4 ? level.width : level.width + 2) + relaxation;
  if (longestDegreeOneRun > maxDegreeOneRun) {
    return GenerationFailReason.degreeOneRunTooLong;
  }

  final minJump = _minJumpForDifficulty(difficulty, level.width, level.height);
  final longJumps = _countLongClueJumps(level.numbers, level.width, minJump);
  final minLongJumpsByDifficulty = <int>[1, 2, 3, 6, 8];
  final minLongJumps = minLongJumpsByDifficulty[(difficulty - 1).clamp(0, 4)]
      .clamp(1, level.numbers.length - 1);
  final requiredLongJumps =
      (minLongJumps - relaxation).clamp(1, level.numbers.length - 1);
  if (longJumps < requiredLongJumps) {
    if (!(dailyLike && _passesEarlyJumpPressure(level))) {
      return GenerationFailReason.consecutiveJumpFail;
    }
  }
  final dispersion = _spatialDispersionScore(
    level.numbers,
    level.width,
    level.height,
  );
  final minDispersion = difficulty >= 4 ? 3.2 : 2.6;
  final targetDispersion =
      (minDispersion - relaxation * 0.2) * profile.minDispersionFactor;
  if (dispersion < targetDispersion) {
    return GenerationFailReason.dispersionTooLow;
  }

  if (profile.requireAlternativeRoute &&
      !_hasAlternativeRoutePressure(level, difficulty: difficulty)) {
    return GenerationFailReason.alternativeRouteFail;
  }
  final dailyEntropySlack = packId == 'daily' ? (dailySoftProfile ? 4 : 2) : 0;
  if (!(dailySoftProfile && packId == 'daily') &&
      !_hasGoodTurnEntropy(
        level.solution,
        level.width,
        level.height,
        profile.straightRunCap + dailyEntropySlack,
      )) {
    return GenerationFailReason.tooLinear;
  }
  if (relaxation < 2 &&
      _isOverSymmetric(level.numbers, level.width, level.height)) {
    return GenerationFailReason.symmetryRisk;
  }
  if (difficulty >= 3 &&
      packId != 'daily' &&
      profile.requireDelayedTrap &&
      !_hasDelayedTrap(
          level.solution, level.walls, level.width, level.height)) {
    return GenerationFailReason.delayedTrapFail;
  }
  if (packId == 'architect' &&
      !_hasAlternativeRoutePressure(level, difficulty: difficulty)) {
    return GenerationFailReason.alternativeRouteFail;
  }
  if (!_passesERC(level, policy)) {
    return GenerationFailReason.ercFail;
  }
  if (!_passesCAS(level, policy)) {
    return GenerationFailReason.casFail;
  }
  return null;
}

GenerationFailReason? _finalValidationFailure(
  Level level, {
  required int difficulty,
  required String packId,
  required StrictnessProfile profile,
  required _ModeValidationPolicy policy,
  required String? generationProfile,
}) {
  if (!_hasConsecutiveCompleteClueValues(level.numbers)) {
    return GenerationFailReason.incompleteClues;
  }
  if (!_numbersStrictlyIncreaseAlongSolution(level)) {
    return GenerationFailReason.clueOrderInvalid;
  }
  if (!_passesConsecutiveClueDistance(
    level,
    difficulty: difficulty,
    relaxation: profile.relaxation,
  )) {
    final dailyLike = packId == 'daily' ||
        (generationProfile?.startsWith('daily_hard') ?? false);
    if (dailyLike) {
      // Daily keeps strong early spike via early separation/CAS gates;
      // allow softer late clue spacing to improve generation reliability.
    } else {
      if (_hasTooManyConsecutiveLocalClues(level)) {
        return GenerationFailReason.localClusterFail;
      }
      return GenerationFailReason.consecutiveJumpFail;
    }
  }
  if (!_passesEarlySeparationGate(
    level,
    packId: packId,
    generationProfile: generationProfile,
  )) {
    return GenerationFailReason.earlySeparationFail;
  }
  final baselineFailure = _baselineFailureReason(
    level,
    difficulty: difficulty,
    packId: packId,
    profile: profile,
    policy: policy,
    generationProfile: generationProfile,
  );
  if (baselineFailure != null) {
    return baselineFailure;
  }
  return null;
}

bool _passesExtremeValidation(
  List<int> path,
  Map<int, int> numbers,
  List<Wall> walls,
  int width,
  int height,
  int difficulty,
) {
  if (!_hasLateConstraintNumber(numbers, path)) return false;

  final branchingChoices =
      _countOpenChoicesAlongPath(path, walls, width, height);
  final minChoices = difficulty == 5 ? 7 : 4;
  if (branchingChoices < minChoices) return false;

  final totalAdj = 2 * width * height - width - height;
  final openEdges = totalAdj - walls.length;
  if (openEdges <= path.length - 1) return false;

  final longJumpMin = _minJumpForDifficulty(difficulty, width, height);
  final longJumpCount = _countLongClueJumps(numbers, width, longJumpMin);
  final neededLongJumps = ((numbers.length - 1) * 0.62).round().clamp(2, 16);
  if (longJumpCount < neededLongJumps) {
    return false;
  }

  return true;
}

// ignore: unused_element
int _getWallCount(
  int width,
  int height,
  int difficulty,
  double baseWallDensity,
  String packId,
  Rng rng,
) {
  final maxEdges = 2 * width * height - width - height;
  const difficultyFactors = [0.90, 1.00, 1.15, 1.35, 1.55];
  final difficultyFactor = difficultyFactors[(difficulty - 1).clamp(0, 4)];
  final densityJitter = 0.7 + rng() * 0.75;
  final packBoost = packId == 'expert' ? 1.08 : 1.0;

  return (maxEdges *
          baseWallDensity *
          difficultyFactor *
          densityJitter *
          packBoost)
      .round();
}

bool _remainingGraphSeemsValid({
  required List<List<int>> adjacency,
  required List<bool> visited,
  required int current,
  required int? endCell,
}) {
  final total = visited.length;
  var degreeOneCount = 0;

  for (var cell = 0; cell < total; cell++) {
    if (visited[cell]) continue;
    var available = 0;
    for (final n in adjacency[cell]) {
      if (!visited[n] || n == current) {
        available++;
      }
    }
    if (available == 0) {
      return false;
    }
    if (available == 1) {
      degreeOneCount++;
    }
  }

  if (degreeOneCount > 2) {
    return false;
  }

  if (endCell != null && !visited[endCell]) {
    var endDegree = 0;
    for (final n in adjacency[endCell]) {
      if (!visited[n] || n == current) {
        endDegree++;
      }
    }
    if (endDegree == 0) {
      return false;
    }
  }

  return true;
}

bool _isRemainingConnected({
  required List<List<int>> adjacency,
  required List<bool> visited,
  required int current,
}) {
  final total = visited.length;
  final seen = List<bool>.filled(total, false);
  final queue = <int>[current];
  seen[current] = true;

  while (queue.isNotEmpty) {
    final cell = queue.removeLast();
    for (final n in adjacency[cell]) {
      if (seen[n]) continue;
      if (visited[n] && n != current) continue;
      seen[n] = true;
      queue.add(n);
    }
  }

  for (var cell = 0; cell < total; cell++) {
    if (!visited[cell] && !seen[cell]) {
      return false;
    }
  }
  return true;
}

int countSolutions(Level level, {int maxSolutions = 2}) {
  final totalCells = level.width * level.height;
  final startCellEntry =
      level.numbers.entries.where((entry) => entry.value == 1).toList();
  if (startCellEntry.isEmpty) {
    return 0;
  }

  final startCell = startCellEntry.first.key;
  final maxNumber = level.numbers.values.isEmpty
      ? 0
      : level.numbers.values.reduce((a, b) => a > b ? a : b);
  int? endCell;
  for (final entry in level.numbers.entries) {
    if (entry.value == maxNumber) {
      endCell = entry.key;
      break;
    }
  }

  final adjacencyMap = _buildAdjacency(level.width, level.height, level.walls);
  final adjacency = List<List<int>>.generate(
    totalCells,
    (index) => List<int>.from(adjacencyMap[index] ?? const <int>[]),
  );
  for (final list in adjacency) {
    list.sort();
  }

  final visited = List<bool>.filled(totalCells, false);
  visited[startCell] = true;
  var nextRequiredNumber = 2;
  var solutions = 0;

  void dfs(int current, int visitedCount, int expectedNumber) {
    if (solutions >= maxSolutions) {
      return;
    }

    if (current == endCell && visitedCount < totalCells) {
      return;
    }

    if (visitedCount == totalCells) {
      if (current == endCell && expectedNumber > maxNumber) {
        solutions++;
      }
      return;
    }

    if (!_remainingGraphSeemsValid(
      adjacency: adjacency,
      visited: visited,
      current: current,
      endCell: endCell,
    )) {
      return;
    }

    if (visitedCount % 5 == 0 &&
        !_isRemainingConnected(
          adjacency: adjacency,
          visited: visited,
          current: current,
        )) {
      return;
    }

    final candidates = <int>[];
    for (final n in adjacency[current]) {
      if (visited[n]) continue;
      if (n == endCell && visitedCount != totalCells - 1) continue;

      final number = level.numbers[n];
      if (number != null && number != expectedNumber) continue;
      candidates.add(n);
    }

    candidates.sort((a, b) {
      var aDegree = 0;
      for (final n in adjacency[a]) {
        if (!visited[n]) aDegree++;
      }
      var bDegree = 0;
      for (final n in adjacency[b]) {
        if (!visited[n]) bDegree++;
      }
      return aDegree.compareTo(bDegree);
    });

    for (final next in candidates) {
      visited[next] = true;
      final number = level.numbers[next];
      final nextExpected =
          number == expectedNumber ? expectedNumber + 1 : expectedNumber;
      dfs(next, visitedCount + 1, nextExpected);
      visited[next] = false;
      if (solutions >= maxSolutions) {
        return;
      }
    }
  }

  dfs(startCell, 1, nextRequiredNumber);
  return solutions;
}

StrictnessProfile _chooseStrictnessProfile(
  int attempt,
  Map<GenerationFailReason, int> failCounts,
  int difficulty,
  String packId,
  String? generationProfile,
) {
  var idx = attempt ~/ 5;
  if (difficulty <= 2 && idx < 2) {
    idx = 2;
  } else if (difficulty == 3 && idx < 1) {
    idx = 1;
  }
  final dailySoft = packId == 'daily' &&
      (generationProfile?.contains('daily_hard_soft') ?? false);
  if (packId == 'daily') {
    final minDailyIdx = dailySoft ? 3 : 2;
    if (idx < minDailyIdx) {
      idx = minDailyIdx;
    }
  }
  if ((failCounts[GenerationFailReason.noHamiltonianPath] ?? 0) > 6) {
    idx = idx < 2 ? 2 : idx;
  }
  if ((failCounts[GenerationFailReason.disconnectedStructure] ?? 0) > 4) {
    idx = idx < 3 ? 3 : idx;
  }
  if ((failCounts[GenerationFailReason.noHamiltonianPath] ?? 0) > 12) {
    idx = idx < 4 ? 4 : idx;
  }
  if (idx < 0) idx = 0;
  if (idx >= _strictnessProfiles.length) {
    idx = _strictnessProfiles.length - 1;
  }
  return _strictnessProfiles[idx];
}

String? _resolveAttemptGenerationProfile(
  String? baseProfile,
  int attempt,
  Map<GenerationFailReason, int> failCounts,
  String packId,
) {
  if (baseProfile == null) {
    return null;
  }
  if (packId != 'daily') {
    return baseProfile;
  }
  final noPath = failCounts[GenerationFailReason.noHamiltonianPath] ?? 0;
  final tooLinear = failCounts[GenerationFailReason.tooLinear] ?? 0;
  final uniqFail = failCounts[GenerationFailReason.uniquenessFail] ?? 0;
  final extremeFail =
      failCounts[GenerationFailReason.extremeValidationFail] ?? 0;
  final baseSoft = baseProfile.contains('daily_hard_soft');

  final passthrough = <String>[];
  String? baseFamily;
  var baseMutation = 0;
  for (final part in baseProfile.split('|')) {
    if (part.startsWith('family=')) {
      baseFamily = part;
      continue;
    }
    if (part.startsWith('mut=')) {
      baseMutation = int.tryParse(part.substring(4)) ?? 0;
      continue;
    }
    if (part == 'daily_hard' || part == 'daily_hard_soft') {
      continue;
    }
    passthrough.add(part);
  }
  const families = <String>[
    'family=nested',
    'family=comb',
    'family=ring',
    'family=multichoke',
  ];
  final familyToken = baseFamily ??
      families[(attempt + noPath + uniqFail + tooLinear) % families.length];
  final mutation = (baseMutation + attempt + tooLinear + extremeFail) % 17;
  final softToken = (baseSoft || (noPath + extremeFail) > 10)
      ? 'daily_hard_soft'
      : 'daily_hard';
  final extra = passthrough.isEmpty ? '' : '|${passthrough.join("|")}';
  return '$softToken|$familyToken|mut=$mutation$extra';
}

int _generationAttemptBudget(String packId, String? generationProfile) {
  if (packId == 'daily') {
    return 1;
  }
  if (packId == 'architect' || packId == 'expert') {
    return 44;
  }
  return 36;
}

int _pathAttemptBudget(String packId, String? generationProfile) {
  if (packId == 'daily') {
    return 1;
  }
  return 8;
}

int _mutationAttemptBudget(String packId, String? generationProfile) {
  if (packId == 'daily') {
    return 2;
  }
  return 2;
}

void _debugAttemptLog({
  required String packId,
  required int width,
  required int height,
  required int difficulty,
  required int seed,
  required int attempt,
  required StrictnessProfile profile,
  required GenerationFailReason reason,
  double? turnRate,
  int? longestStraight,
  int? chokepoints,
  double? dispersion,
  int? solutions,
  double? ercScore,
  double? casScore,
  int? casEarlyAmbiguous,
}) {
  if (!_enableGenerationDebugLogs) {
    return;
  }
  assert(() {
    debugPrint(
      '[GenAttempt] '
      'pack=$packId size=${width}x$height diff=$difficulty seed=$seed '
      'attempt=$attempt profile=${profile.id} reason=$reason '
      'turnRate=${turnRate?.toStringAsFixed(3) ?? '-'} '
      'straight=${longestStraight ?? '-'} '
      'chokepoints=${chokepoints ?? '-'} '
      'dispersion=${dispersion?.toStringAsFixed(3) ?? '-'} '
      'erc=${ercScore?.toStringAsFixed(3) ?? '-'} '
      'cas=${casScore?.toStringAsFixed(3) ?? '-'} '
      'casEarly=${casEarlyAmbiguous ?? '-'} '
      'solutions=${solutions ?? '-'}',
    );
    return true;
  }());
}

Level? _generateReliabilityStructuralLevel({
  required int width,
  required int height,
  required int difficulty,
  required int seed,
  required String packId,
  required int numberCount,
  String? generationProfile,
}) {
  final profile = _strictnessProfiles.last;
  final policy =
      _modeValidationPolicy(packId, difficulty, profile, generationProfile);
  final totalCells = width * height;
  for (var i = 0; i < 30; i++) {
    final attemptSeed = seed ^ (0x9E3779B9 * (i + 1));
    final rng = createRng(attemptSeed);
    var walls = _generateStructuralWalls(
      width,
      height,
      difficulty,
      (0.08 + difficulty * 0.015).clamp(0.06, 0.22),
      packId,
      rng,
      generationProfile,
    );

    List<int>? path;
    for (var localTry = 0; localTry < 6; localTry++) {
      if (!_isStructureConnected(width, height, walls) ||
          _isStructureOverconstrained(width, height, walls)) {
        walls = _mutateWallsForFeasibility(
          walls,
          width,
          height,
          createRng(attemptSeed ^ (localTry * 313)),
        );
        continue;
      }
      path = _generateHamiltonianPathInGraph(
        width,
        height,
        walls,
        createRng(attemptSeed ^ (localTry * 997)),
        searchBudget: (packId == 'daily' ||
                (generationProfile?.startsWith('daily_hard') ?? false))
            ? 10000
            : 70000,
      );
      if (path != null && path.length == totalCells) {
        break;
      }
      walls = _mutateWallsForFeasibility(
        walls,
        width,
        height,
        createRng(attemptSeed ^ (localTry * 673)),
      );
    }
    if (path == null || path.length != totalCells) {
      final dailyLike = packId == 'daily' ||
          (generationProfile?.startsWith('daily_hard') ?? false);
      if (dailyLike) {
        final synthesized = _generateHamiltonianPath(
          width,
          height,
          createRng(attemptSeed ^ 0x517CC1B7),
        );
        if (synthesized.length == totalCells) {
          final pathAdj = <String>{};
          for (var i = 0; i < synthesized.length - 1; i++) {
            pathAdj.add(_edgeKey(synthesized[i], synthesized[i + 1]));
          }
          walls = walls
              .where(
                  (wall) => !pathAdj.contains(_edgeKey(wall.cell1, wall.cell2)))
              .toList(growable: false);
          path = synthesized;
        } else {
          continue;
        }
      } else {
        continue;
      }
    }
    final hardEarlySpike = generationProfile == 'daily_hard' ||
        (generationProfile?.startsWith('daily_hard') ?? false) ||
        generationProfile == 'campaign_mid' ||
        generationProfile == 'campaign_high' ||
        generationProfile == 'campaign_elite' ||
        packId == 'architect' ||
        packId == 'expert' ||
        packId == 'daily';
    final numbers = hardEarlySpike
        ? _placeAnchoredCluesForEarlySpike(
            path,
            width,
            height,
            numberCount,
            walls,
            difficulty,
            rng,
          )
        : _placeTrickyNumbers(
            path,
            width,
            height,
            numberCount,
            walls,
            difficulty,
            rng,
          );
    final level = Level(
      id: '$packId-$seed',
      width: width,
      height: height,
      numbers: numbers,
      walls: walls,
      solution: path,
      difficulty: difficulty,
      pack: packId,
    );
    final fail = _finalValidationFailure(
      level,
      difficulty: difficulty,
      packId: packId,
      profile: profile,
      policy: policy,
      generationProfile: generationProfile,
    );
    if (fail != null &&
        fail != GenerationFailReason.alternativeRouteFail &&
        fail != GenerationFailReason.delayedTrapFail &&
        fail != GenerationFailReason.centralCompressionLow) {
      continue;
    }
    final candidateSolutions = countSolutions(level, maxSolutions: 2);
    if (candidateSolutions == 1 ||
        (!policy.uniquenessMandatory &&
            policy.allowNearUnique &&
            candidateSolutions <= 2)) {
      return level;
    }
  }

  // Last reliability synthesis: keep chamber structure, then embed a path-compatible subset.
  final rng = createRng(seed ^ 0x517CC1B7);
  final path = _generateHamiltonianPath(width, height, rng);
  final pathAdj = <String>{};
  for (var i = 0; i < path.length - 1; i++) {
    pathAdj.add(_edgeKey(path[i], path[i + 1]));
  }
  final chamberEdges =
      _buildChamberEdgesFromGrid(width, height, difficulty, packId, rng);
  final walls = <Wall>[];
  for (final key in chamberEdges) {
    if (pathAdj.contains(key)) {
      continue;
    }
    final parts = key.split(',');
    walls.add(Wall(cell1: int.parse(parts[0]), cell2: int.parse(parts[1])));
  }
  final hardEarlySpike = generationProfile == 'daily_hard' ||
      (generationProfile?.startsWith('daily_hard') ?? false) ||
      generationProfile == 'campaign_mid' ||
      generationProfile == 'campaign_high' ||
      generationProfile == 'campaign_elite' ||
      packId == 'architect' ||
      packId == 'expert' ||
      packId == 'daily';
  final numbers = hardEarlySpike
      ? _placeAnchoredCluesForEarlySpike(
          path,
          width,
          height,
          numberCount,
          walls,
          difficulty,
          rng,
        )
      : _placeTrickyNumbers(
          path,
          width,
          height,
          numberCount,
          walls,
          difficulty,
          rng,
        );
  final level = Level(
    id: '$packId-$seed',
    width: width,
    height: height,
    numbers: numbers,
    walls: walls,
    solution: path,
    difficulty: difficulty,
    pack: packId,
  );
  final finalFail = _finalValidationFailure(
    level,
    difficulty: difficulty,
    packId: packId,
    profile: profile,
    policy: policy,
    generationProfile: generationProfile,
  );
  if (finalFail != null &&
      finalFail != GenerationFailReason.alternativeRouteFail &&
      finalFail != GenerationFailReason.delayedTrapFail &&
      finalFail != GenerationFailReason.centralCompressionLow) {
    return null;
  }
  var reinforcedLevel = level;
  var solutions = countSolutions(reinforcedLevel, maxSolutions: 2);
  if (policy.uniquenessMandatory && solutions > 1) {
    var mutableWalls = List<Wall>.from(walls);
    for (var reinforce = 0; reinforce < 8 && solutions > 1; reinforce++) {
      mutableWalls = _reinforceWallsForAmbiguity(
        path,
        mutableWalls,
        width,
        height,
        difficulty,
        createRng(seed ^ (0x9E3779B9 * (reinforce + 1))),
      );
      reinforcedLevel = Level(
        id: '$packId-$seed-r$reinforce',
        width: width,
        height: height,
        numbers: numbers,
        walls: mutableWalls,
        solution: path,
        difficulty: difficulty,
        pack: packId,
      );
      solutions = countSolutions(reinforcedLevel, maxSolutions: 2);
    }
  }
  if ((policy.uniquenessMandatory && solutions == 1) ||
      (!policy.uniquenessMandatory &&
          policy.allowNearUnique &&
          solutions <= 2)) {
    return reinforcedLevel;
  }
  return null;
}

Level generateLevel(
  int width,
  int height,
  int difficulty,
  int seed,
  String packId, {
  double wallDensity = 0.12,
  String? generationProfile,
  int levelIndexHint = 1,
}) {
  const hasWalls = true;
  if (_enableGenerationDebugLogs) {
    assert(() {
      debugPrint('Level $packId-$seed hasWalls=$hasWalls');
      return true;
    }());
  }
  final totalCells = width * height;
  final policyContext = _cluePolicyContext(
    packId,
    generationProfile,
    difficulty,
    levelIndexHint,
  );
  final numberCount = chooseClueCount(
    mode: policyContext.$1,
    tier: policyContext.$2,
    w: width,
    h: height,
    levelIndex: levelIndexHint,
    seed: seed,
  ).clamp(2, totalCells);
  final failCounts = <GenerationFailReason, int>{};
  GenerationFailReason lastReason = GenerationFailReason.noHamiltonianPath;
  var lastSolutions = -1;
  double? lastTurnRate;
  int? lastLongestStraight;
  double? lastDispersion;
  int? lastChokepoints;
  double? lastErcScore;
  double? lastCasScore;
  int? lastCasEarlyAmbiguous;
  final attemptBudget = _generationAttemptBudget(packId, generationProfile);
  final pathBudget = _pathAttemptBudget(packId, generationProfile);
  final mutationBudget = _mutationAttemptBudget(packId, generationProfile);

  for (var attempt = 0; attempt < attemptBudget; attempt++) {
    if (attempt >= 20 &&
        ((failCounts[GenerationFailReason.noHamiltonianPath] ?? 0) +
                (failCounts[GenerationFailReason.disconnectedStructure] ?? 0) >
            24)) {
      break;
    }
    final attemptSeed = seed + attempt * 7919;
    final baseRng = createRng(attemptSeed);
    final attemptProfile = _resolveAttemptGenerationProfile(
      generationProfile,
      attempt,
      failCounts,
      packId,
    );
    final profile = _chooseStrictnessProfile(
      attempt,
      failCounts,
      difficulty,
      packId,
      attemptProfile,
    );
    final policy =
        _modeValidationPolicy(packId, difficulty, profile, attemptProfile);

    final adaptiveWallDensity = (wallDensity +
            (difficulty >= 4 ? 0.06 : (difficulty >= 3 ? 0.03 : 0.0)) +
            (packId == 'daily' ? -0.06 : 0.0) +
            attempt * 0.0015)
        .clamp(0.05, 0.65);

    var walls = _generateStructuralWalls(
      width,
      height,
      difficulty,
      adaptiveWallDensity,
      packId,
      baseRng,
      attemptProfile,
    );
    List<int>? path;
    for (var pathTry = 0; pathTry < pathBudget; pathTry++) {
      if (pathTry > 0) {
        final densityFactor = 1 - pathTry * 0.11;
        walls = _generateStructuralWalls(
          width,
          height,
          difficulty,
          (adaptiveWallDensity * densityFactor).clamp(0.03, 0.50),
          packId,
          createRng(attemptSeed ^ (pathTry * 0x45D9F3B)),
          attemptProfile,
        );
      }
      if (!_isStructureConnected(width, height, walls)) {
        lastReason = GenerationFailReason.disconnectedStructure;
        failCounts[lastReason] = (failCounts[lastReason] ?? 0) + 1;
        _debugAttemptLog(
          packId: packId,
          width: width,
          height: height,
          difficulty: difficulty,
          seed: seed,
          attempt: attempt,
          profile: profile,
          reason: lastReason,
        );
        walls = _mutateWallsForFeasibility(
          walls,
          width,
          height,
          createRng(attemptSeed ^ (pathTry + 17)),
        );
        continue;
      }
      if (_isStructureOverconstrained(width, height, walls)) {
        lastReason = GenerationFailReason.overconstrainedStructure;
        failCounts[lastReason] = (failCounts[lastReason] ?? 0) + 1;
        _debugAttemptLog(
          packId: packId,
          width: width,
          height: height,
          difficulty: difficulty,
          seed: seed,
          attempt: attempt,
          profile: profile,
          reason: lastReason,
        );
        walls = _mutateWallsForFeasibility(
          walls,
          width,
          height,
          createRng(attemptSeed ^ (pathTry + 31)),
        );
        continue;
      }
      path = _generateHamiltonianPathInGraph(
        width,
        height,
        walls,
        createRng(attemptSeed ^ (0x61C88647 + pathTry * 31)),
        searchBudget: (packId == 'daily' ||
                (attemptProfile?.startsWith('daily_hard') ?? false))
            ? 9000
            : 70000,
      );
      if (path != null && path.length == totalCells) {
        break;
      }
      lastReason = GenerationFailReason.noHamiltonianPath;
      failCounts[lastReason] = (failCounts[lastReason] ?? 0) + 1;
      _debugAttemptLog(
        packId: packId,
        width: width,
        height: height,
        difficulty: difficulty,
        seed: seed,
        attempt: attempt,
        profile: profile,
        reason: lastReason,
      );
      walls = _mutateWallsForFeasibility(
        walls,
        width,
        height,
        createRng(attemptSeed ^ (pathTry + 53)),
      );
    }
    if (path == null || path.length != totalCells) {
      final dailyLike = packId == 'daily' ||
          (attemptProfile?.startsWith('daily_hard') ?? false);
      if (dailyLike) {
        final synthesized = _generateHamiltonianPath(
          width,
          height,
          createRng(attemptSeed ^ 0x517CC1B7),
        );
        if (synthesized.length == totalCells) {
          final pathAdj = <String>{};
          for (var i = 0; i < synthesized.length - 1; i++) {
            pathAdj.add(_edgeKey(synthesized[i], synthesized[i + 1]));
          }
          walls = walls
              .where(
                  (wall) => !pathAdj.contains(_edgeKey(wall.cell1, wall.cell2)))
              .toList(growable: false);
          path = synthesized;
        } else {
          continue;
        }
      } else {
        continue;
      }
    }

    for (var mutation = 0; mutation < mutationBudget; mutation++) {
      final rng = createRng(
        attemptSeed ^ ((mutation + 1) * 0x9E3779B9),
      );
      final hardEarlySpike = generationProfile == 'daily_hard' ||
          (generationProfile?.startsWith('daily_hard') ?? false) ||
          generationProfile == 'campaign_mid' ||
          generationProfile == 'campaign_high' ||
          generationProfile == 'campaign_elite' ||
          packId == 'architect' ||
          packId == 'expert' ||
          packId == 'daily';
      final numbers = hardEarlySpike
          ? _placeAnchoredCluesForEarlySpike(
              path,
              width,
              height,
              numberCount,
              walls,
              difficulty,
              rng,
            )
          : _placeTrickyNumbers(
              path,
              width,
              height,
              numberCount,
              walls,
              difficulty,
              rng,
            );

      final level = Level(
        id: '$packId-$seed',
        width: width,
        height: height,
        numbers: numbers,
        walls: walls,
        solution: path,
        difficulty: difficulty,
        pack: packId,
      );

      final turnStats = _turnEntropyStats(level.solution, width, height);
      final dispersion = _spatialDispersionScore(level.numbers, width, height);
      final chokepoints = _countStrongChokepoints(level.walls, width, height);
      final quickFailure = _cheapFeasibilityFailure(
        level,
        difficulty: difficulty,
        packId: packId,
        profile: profile,
        generationProfile: attemptProfile,
      );
      if (quickFailure != null) {
        lastReason = quickFailure;
        failCounts[lastReason] = (failCounts[lastReason] ?? 0) + 1;
        _debugAttemptLog(
          packId: packId,
          width: width,
          height: height,
          difficulty: difficulty,
          seed: seed,
          attempt: attempt,
          profile: profile,
          reason: quickFailure,
          turnRate: turnStats.turnRate,
          longestStraight: turnStats.longestStraight,
          chokepoints: chokepoints,
          dispersion: dispersion,
        );
        continue;
      }
      _ErcResult? ercResult;
      _CasResult? casResult;
      final validationFailure = _finalValidationFailure(
        level,
        difficulty: difficulty,
        packId: packId,
        profile: profile,
        policy: policy,
        generationProfile: attemptProfile,
      );
      if (validationFailure == GenerationFailReason.ercFail ||
          validationFailure == GenerationFailReason.casFail) {
        ercResult = _enclosureRiskCurveScore(level);
        casResult = _clueSegmentAmbiguityScore(
          level,
          earlyOnly: policy.casEarlyOnly,
        );
      }
      if (validationFailure != null) {
        lastReason = validationFailure;
        failCounts[lastReason] = (failCounts[lastReason] ?? 0) + 1;
        lastTurnRate = turnStats.turnRate;
        lastLongestStraight = turnStats.longestStraight;
        lastDispersion = dispersion;
        lastChokepoints = chokepoints;
        lastErcScore = ercResult?.score;
        lastCasScore = casResult?.score;
        lastCasEarlyAmbiguous = casResult?.earlyAmbiguousSegments;
        _debugAttemptLog(
          packId: packId,
          width: width,
          height: height,
          difficulty: difficulty,
          seed: seed,
          attempt: attempt,
          profile: profile,
          reason: validationFailure,
          turnRate: turnStats.turnRate,
          longestStraight: turnStats.longestStraight,
          chokepoints: chokepoints,
          dispersion: dispersion,
          ercScore: ercResult?.score,
          casScore: casResult?.score,
          casEarlyAmbiguous: casResult?.earlyAmbiguousSegments,
        );
        continue;
      }
      final enforceExtremeValidation = difficulty >= 4 &&
          !(generationProfile?.startsWith('daily_hard') ?? false) &&
          packId != 'daily';
      if (enforceExtremeValidation &&
          !_passesExtremeValidation(
            path,
            numbers,
            walls,
            width,
            height,
            difficulty,
          )) {
        lastReason = GenerationFailReason.extremeValidationFail;
        failCounts[lastReason] = (failCounts[lastReason] ?? 0) + 1;
        lastTurnRate = turnStats.turnRate;
        lastLongestStraight = turnStats.longestStraight;
        lastDispersion = dispersion;
        lastChokepoints = chokepoints;
        lastErcScore = ercResult?.score;
        lastCasScore = casResult?.score;
        lastCasEarlyAmbiguous = casResult?.earlyAmbiguousSegments;
        _debugAttemptLog(
          packId: packId,
          width: width,
          height: height,
          difficulty: difficulty,
          seed: seed,
          attempt: attempt,
          profile: profile,
          reason: lastReason,
          turnRate: turnStats.turnRate,
          longestStraight: turnStats.longestStraight,
          chokepoints: chokepoints,
          dispersion: dispersion,
          ercScore: ercResult?.score,
          casScore: casResult?.score,
          casEarlyAmbiguous: casResult?.earlyAmbiguousSegments,
        );
        continue;
      }

      final solutions = countSolutions(level, maxSolutions: 2);
      final acceptsNearUnique =
          !policy.uniquenessMandatory && policy.allowNearUnique;
      if (solutions == 1 || (acceptsNearUnique && solutions <= 2)) {
        return level;
      }
      if (solutions > 1) {
        lastReason = GenerationFailReason.uniquenessFail;
        failCounts[lastReason] = (failCounts[lastReason] ?? 0) + 1;
        lastSolutions = solutions;
        lastTurnRate = turnStats.turnRate;
        lastLongestStraight = turnStats.longestStraight;
        lastDispersion = dispersion;
        lastChokepoints = chokepoints;
        lastErcScore = ercResult?.score;
        lastCasScore = casResult?.score;
        lastCasEarlyAmbiguous = casResult?.earlyAmbiguousSegments;
        _debugAttemptLog(
          packId: packId,
          width: width,
          height: height,
          difficulty: difficulty,
          seed: seed,
          attempt: attempt,
          profile: profile,
          reason: lastReason,
          turnRate: turnStats.turnRate,
          longestStraight: turnStats.longestStraight,
          chokepoints: chokepoints,
          dispersion: dispersion,
          ercScore: ercResult?.score,
          casScore: casResult?.score,
          casEarlyAmbiguous: casResult?.earlyAmbiguousSegments,
          solutions: solutions,
        );
        walls = _reinforceWallsForAmbiguity(
          path,
          walls,
          width,
          height,
          difficulty,
          rng,
        );
      }
    }
  }

  final allowReliabilityFallback = !(packId == 'daily' &&
      (generationProfile?.startsWith('daily_hard') ?? false));
  if (allowReliabilityFallback) {
    final reliabilityLevel = _generateReliabilityStructuralLevel(
      width: width,
      height: height,
      difficulty: difficulty,
      seed: seed,
      packId: packId,
      numberCount: numberCount,
      generationProfile: generationProfile,
    );
    if (reliabilityLevel != null) {
      return reliabilityLevel;
    }
  }

  throw GenerationFailureException(
    'Generation failed '
    '[reason=${lastReason.name} profile=${_chooseStrictnessProfile(attemptBudget - 1, failCounts, difficulty, packId, generationProfile).id}] '
    'pack=$packId size=${width}x$height difficulty=$difficulty seed=$seed '
    'solutions=$lastSolutions '
    'turnRate=${lastTurnRate?.toStringAsFixed(3) ?? '-'} '
    'straight=${lastLongestStraight ?? '-'} '
    'chokepoints=${lastChokepoints ?? '-'} '
    'dispersion=${lastDispersion?.toStringAsFixed(3) ?? '-'} '
    'erc=${lastErcScore?.toStringAsFixed(3) ?? '-'} '
    'cas=${lastCasScore?.toStringAsFixed(3) ?? '-'} '
    'casEarly=${lastCasEarlyAmbiguous ?? '-'} '
    'profileHint=${generationProfile ?? '-'} '
    'levelIndex=$levelIndexHint '
    'failCounts=$failCounts',
  );
}

Level getLevelForPack(
  String packId,
  int levelIndex, {
  int retryNonce = 0,
  required PackResolver getPackById,
}) {
  final pack = getPackById(packId);
  if (pack == null) {
    return generateLevel(5, 5, 1, levelIndex, 'classic');
  }

  final seed = retryNonce == 0
      ? hashString('$packId-level-$levelIndex')
      : hashString('$packId-level-$levelIndex-retry-$retryNonce');
  final clampedLevel = levelIndex.clamp(1, pack.levelCount);
  final progress = clampedLevel / pack.levelCount;
  final sizeIdx = ((progress * pack.gridSizes.length).floor())
      .clamp(0, pack.gridSizes.length - 1);
  var gridSize = pack.gridSizes[sizeIdx];
  final baseDifficulty = (1 + (progress * 5).floor()).clamp(1, 5);
  String generationProfile = 'campaign_mid';
  var difficulty = baseDifficulty;
  var wallDensity = pack.wallDensity;

  if (clampedLevel <= 30) {
    generationProfile = 'campaign_low';
    difficulty = baseDifficulty.clamp(1, 3);
    wallDensity = (pack.wallDensity * 0.90).clamp(0.08, 0.24);
    if (clampedLevel > 15 && pack.gridSizes.length > 1) {
      gridSize = pack.gridSizes[1];
    }
  } else if (clampedLevel <= 80) {
    generationProfile = 'campaign_mid';
    difficulty = baseDifficulty.clamp(2, 4);
    wallDensity = (pack.wallDensity * 1.00).clamp(0.10, 0.28);
    if (pack.gridSizes.length > 1) {
      gridSize = pack.gridSizes[1];
    }
  } else if (clampedLevel <= 200) {
    generationProfile = 'campaign_high';
    difficulty = baseDifficulty.clamp(3, 5);
    wallDensity = (pack.wallDensity * 1.14).clamp(0.12, 0.34);
  } else {
    generationProfile = 'campaign_elite';
    difficulty = 5;
    wallDensity = (pack.wallDensity * 1.22).clamp(0.14, 0.40);
  }

  if (difficulty == 5) {
    final rng = createRng(seed);
    var target =
        gridSize.width > gridSize.height ? gridSize.width : gridSize.height;
    if (target < 8) target = 8;
    final roll = rng();
    if (roll > 0.82) {
      target = 10;
    } else if (roll > 0.56) {
      target = 9;
    }
    gridSize = GridSize(width: target, height: target);
  }

  if (retryNonce > 0 && clampedLevel <= 80 && pack.gridSizes.length > 1) {
    final diversityRng = createRng(seed ^ (retryNonce * 104729));
    if (diversityRng() > 0.48) {
      final bumpedIdx = (sizeIdx + 1).clamp(0, pack.gridSizes.length - 1);
      gridSize = pack.gridSizes[bumpedIdx];
    }
    if (diversityRng() > 0.72) {
      difficulty = (difficulty + 1).clamp(1, 5);
    }
    if (clampedLevel <= 30 && diversityRng() > 0.66) {
      generationProfile = 'campaign_mid';
      wallDensity = (wallDensity * 1.06).clamp(0.10, 0.30);
    }
  }

  return generateLevel(
    gridSize.width,
    gridSize.height,
    difficulty,
    seed,
    packId,
    wallDensity: wallDensity,
    generationProfile: generationProfile,
    levelIndexHint: clampedLevel,
  );
}

Level getDailyLevel({int retryNonce = 0}) {
  final now = DateTime.now();
  final dateBase = 'daily-${now.year}-${now.month}-${now.day}';
  const maxAttempts = 240;
  const desktopBudgetMs = 12000;
  const mobileBudgetMs = 15000;
  final timeBudgetMs = defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS
      ? mobileBudgetMs
      : desktopBudgetMs;
  final watch = Stopwatch()..start();
  final reasonCounts = <GenerationFailReason, int>{};
  GenerationFailReason? lastReason;
  final familyOrder = _shuffledDailyFamilies(dateBase, retryNonce);

  GenerationFailureException? lastFailure;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (watch.elapsedMilliseconds > timeBudgetMs) {
      break;
    }
    final config = _buildDailyAttemptConfig(
      dateBase: dateBase,
      retryNonce: retryNonce,
      attempt: attempt,
      elapsedMs: watch.elapsedMilliseconds,
      timeBudgetMs: timeBudgetMs,
      familyOrder: familyOrder,
      reasonCounts: reasonCounts,
      lastReason: lastReason,
    );

    final seed = hashString('$dateBase-retry-$retryNonce-attempt-$attempt');
    try {
      return generateLevel(
        config.size,
        config.size,
        config.difficulty,
        seed,
        'daily',
        generationProfile: config.profile,
      );
    } on GenerationFailureException catch (e) {
      lastFailure = e;
      final reason = _extractFailureReason(e.message);
      lastReason = reason;
      if (reason != null) {
        reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
      }
      if (_enableGenerationDebugLogs) {
        assert(() {
          debugPrint(
            '[DailyGen] attempt=$attempt profile=${config.profile} reason=$reason elapsedMs=${watch.elapsedMilliseconds}',
          );
          return true;
        }());
      }
    }
  }
  if (lastFailure != null) {
    throw lastFailure;
  }
  throw GenerationFailureException(
    'Daily generation exhausted attempts=$maxAttempts budgetMs=$timeBudgetMs',
  );
}

class _DailyAttemptConfig {
  const _DailyAttemptConfig({
    required this.profile,
    required this.size,
    required this.difficulty,
  });

  final String profile;
  final int size;
  final int difficulty;
}

List<String> _shuffledDailyFamilies(String dateBase, int retryNonce) {
  final base = <String>['nested', 'comb', 'ring', 'multichoke'];
  final shift = hashString('$dateBase|family|$retryNonce') % base.length;
  final rotated = <String>[];
  for (var i = 0; i < base.length; i++) {
    rotated.add(base[(i + shift) % base.length]);
  }
  return rotated;
}

_DailyAttemptConfig _buildDailyAttemptConfig({
  required String dateBase,
  required int retryNonce,
  required int attempt,
  required int elapsedMs,
  required int timeBudgetMs,
  required List<String> familyOrder,
  required Map<GenerationFailReason, int> reasonCounts,
  required GenerationFailReason? lastReason,
}) {
  final noPath = (reasonCounts[GenerationFailReason.noHamiltonianPath] ?? 0) +
      (reasonCounts[GenerationFailReason.disconnectedStructure] ?? 0) +
      (reasonCounts[GenerationFailReason.overconstrainedStructure] ?? 0);
  final uniquenessFails =
      reasonCounts[GenerationFailReason.uniquenessFail] ?? 0;
  final extremeFails =
      reasonCounts[GenerationFailReason.extremeValidationFail] ?? 0;
  final casFails = reasonCounts[GenerationFailReason.casFail] ?? 0;
  final tooLinearFails = reasonCounts[GenerationFailReason.tooLinear] ?? 0;

  final nearingBudget = elapsedMs > (timeBudgetMs * 0.65).floor();
  final soft = attempt >= 6 ||
      nearingBudget ||
      noPath >= 1 ||
      extremeFails >= 1 ||
      casFails >= 2;

  final baseFamily = familyOrder[(attempt + retryNonce) % familyOrder.length];
  var family = baseFamily;
  final tags = <String>[];

  if (lastReason == GenerationFailReason.tooLinear) {
    family = (attempt.isEven) ? 'multichoke' : 'nested';
    tags.add('choke=high');
  } else if (lastReason == GenerationFailReason.uniquenessFail) {
    family = (attempt.isEven) ? 'ring' : 'nested';
    tags.add('uniq=1');
  } else if (lastReason == GenerationFailReason.noHamiltonianPath ||
      lastReason == GenerationFailReason.disconnectedStructure ||
      lastReason == GenerationFailReason.overconstrainedStructure ||
      lastReason == GenerationFailReason.extremeValidationFail) {
    family = (attempt.isEven) ? 'comb' : 'nested';
    tags.add('thin=1');
  } else if (lastReason == GenerationFailReason.casFail) {
    family = (attempt.isEven) ? 'nested' : 'multichoke';
    tags.add('cas=early');
  }

  final mutationBase = retryNonce * 5 + attempt * 7 + tooLinearFails * 3;
  final mutation =
      (mutationBase + uniquenessFails * 5 + extremeFails * 4 + noPath * 2) % 31;
  final softToken = soft ? 'daily_hard_soft' : 'daily_hard';
  final profile = '$softToken|family=$family|mut=$mutation'
      '${tags.isEmpty ? '' : '|${tags.join("|")}'}';

  final size = 7;
  return _DailyAttemptConfig(
    profile: profile,
    size: size,
    difficulty: 4,
  );
}

GenerationFailReason? _extractFailureReason(String message) {
  final match = RegExp(r'\[reason=([^\] ]+)').firstMatch(message);
  final token = match?.group(1);
  if (token == null) {
    return null;
  }
  for (final value in GenerationFailReason.values) {
    if (value.name == token) {
      return value;
    }
  }
  return null;
}

Level getEndlessLevel(int difficulty, int index) {
  final seed = hashString(
      'endless-$difficulty-$index-${DateTime.now().millisecondsSinceEpoch}');
  const sizes = {1: 5, 2: 6, 3: 7, 4: 8, 5: 9};
  final size = sizes[difficulty] ?? 6;
  return generateLevel(size, size, difficulty, seed, 'endless');
}

void debugWallDistribution({
  int levelCount = 100,
  String namespace = 'distribution',
}) {
  var withWalls = 0;
  for (var i = 1; i <= levelCount; i++) {
    final seed = hashString('$namespace-$i');
    if (shouldHaveWalls(seed)) {
      withWalls++;
    }
  }
  final withoutWalls = levelCount - withWalls;
  final withWallsPct = (withWalls * 100 / levelCount).toStringAsFixed(1);
  final withoutWallsPct = (withoutWalls * 100 / levelCount).toStringAsFixed(1);
  // ignore: avoid_print
  print(
    'Wall distribution over $levelCount levels: '
    'withWalls=$withWalls ($withWallsPct%), '
    'noWalls=$withoutWalls ($withoutWallsPct%)',
  );
}
