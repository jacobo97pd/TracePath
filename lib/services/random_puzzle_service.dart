import 'dart:math';

import '../pack_level_repository.dart';

class RandomPuzzleSelection {
  const RandomPuzzleSelection({
    required this.packId,
    required this.levelIndex,
    required this.puzzleId,
    required this.difficulty,
    required this.width,
    required this.height,
  });

  final String packId;
  final int levelIndex;
  final String puzzleId;
  final int difficulty;
  final int width;
  final int height;
}

class RandomPuzzleService {
  static const List<String> challengePackIds = <String>[
    'world_01',
    'world_02',
    'world_03',
    'world_04',
    'world_05',
    'world_06',
    'world_07',
    'world_08',
    'world_09',
    'world_10',
    'world_11',
    'world_12',
    'world_13',
    'world_14',
    'world_15',
    'world_16',
    'world_17',
    'classic',
  ];

  final Random _random;

  RandomPuzzleService({Random? random}) : _random = random ?? Random();

  Future<RandomPuzzleSelection?> selectRandomPuzzle({
    String excludedLevelId = '',
    String preferredLevelId = '',
  }) async {
    final excluded = excludedLevelId.trim();
    final preferred = preferredLevelId.trim();
    final repo = PackLevelRepository.instance;
    for (final packId in challengePackIds) {
      await repo.loadPack(packId);
    }

    RandomPuzzleSelection? preferredPuzzle;
    final preferredInfo = parseLevelRouteInfo(preferred);
    if (preferredInfo != null) {
      final record = await repo.getLevel(
        preferredInfo.packId,
        preferredInfo.levelIndex,
      );
      if (record != null) {
        preferredPuzzle = RandomPuzzleSelection(
          packId: preferredInfo.packId,
          levelIndex: preferredInfo.levelIndex,
          puzzleId: '${preferredInfo.packId}_${preferredInfo.levelIndex}',
          difficulty: record.level.difficulty,
          width: record.level.width,
          height: record.level.height,
        );
      }
    }

    final pool = <RandomPuzzleSelection>[];
    for (final packId in challengePackIds) {
      final total = repo.totalLevelsSync(packId);
      for (var i = 1; i <= total; i++) {
        final record = repo.getLevelSync(packId, i);
        if (record == null) continue;
        final id = '${packId}_$i';
        if (id == excluded) continue;
        pool.add(
          RandomPuzzleSelection(
            packId: packId,
            levelIndex: i,
            puzzleId: id,
            difficulty: record.level.difficulty,
            width: record.level.width,
            height: record.level.height,
          ),
        );
      }
    }
    if (pool.isEmpty) return null;
    if (pool.length == 1) return pool.first;

    if (preferredPuzzle != null) {
      final exact = pool
          .where(
            (p) =>
                p.difficulty == preferredPuzzle!.difficulty &&
                p.width == preferredPuzzle.width &&
                p.height == preferredPuzzle.height,
          )
          .toList(growable: false);
      if (exact.isNotEmpty) {
        return exact[_random.nextInt(exact.length)];
      }
      final partial = pool
          .where(
            (p) =>
                p.difficulty == preferredPuzzle!.difficulty ||
                (p.width == preferredPuzzle.width &&
                    p.height == preferredPuzzle.height),
          )
          .toList(growable: false);
      if (partial.isNotEmpty) {
        return partial[_random.nextInt(partial.length)];
      }
    }
    return pool[_random.nextInt(pool.length)];
  }

  static RandomPuzzleRouteInfo? parseLevelRouteInfo(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    final idx = normalized.lastIndexOf('_');
    if (idx <= 0 || idx >= normalized.length - 1) return null;
    final pack = normalized.substring(0, idx).trim();
    final level = int.tryParse(normalized.substring(idx + 1).trim()) ?? 0;
    if (pack.isEmpty || level <= 0) return null;
    return RandomPuzzleRouteInfo(packId: pack, levelIndex: level);
  }
}

class RandomPuzzleRouteInfo {
  const RandomPuzzleRouteInfo({
    required this.packId,
    required this.levelIndex,
  });

  final String packId;
  final int levelIndex;
}
