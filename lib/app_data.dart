import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/level.dart';
import 'engine/level_generator.dart';
import 'engine/seed_random.dart';
import 'level_fingerprint_store.dart';
import 'level_export_registry.dart';
import 'pack_level_repository.dart';

const int displayedLevelCount = 200;
const int _campaignLevelCacheMaxEntries = 64;
const int _campaignFingerprintNamespaceLimit = 5000;
const int _dailyFingerprintNamespaceLimit = 3660;
const int _endlessLevelCacheMaxEntries = 32;
const int _endlessPrefetchPoolTarget = 4;
const int _maxEndlessGenerationRetries = 100;
const String _endlessGeneratorVersion = 'struct-v2';
const String _endlessDiskIndexKey = 'endless_level_disk_index';
const String _endlessDiskPrefix = 'endless_level_cache_';
const int _endlessDiskCacheMaxEntries = 80;

final Map<String, Level> _campaignLevelCache = <String, Level>{};
final List<String> _campaignLevelCacheOrder = <String>[];
final Map<String, Set<String>> _sessionFingerprintsByNamespace =
    <String, Set<String>>{};
final Map<String, Level> _endlessLevelCache = <String, Level>{};
final List<String> _endlessLevelCacheOrder = <String>[];
final Map<String, List<_PooledEndlessLevel>> _endlessPrefetchPools =
    <String, List<_PooledEndlessLevel>>{};
final Set<String> _endlessPrefetchInFlight = <String>{};
Level? _dailyLevelCache;
String? _dailyLevelCacheKey;

class _PooledEndlessLevel {
  const _PooledEndlessLevel({
    required this.index,
    required this.cacheKey,
    required this.level,
  });

  final int index;
  final String cacheKey;
  final Level level;
}

class EndlessLevelRequest {
  const EndlessLevelRequest({
    required this.difficulty,
    required this.index,
    required this.runSeed,
    this.difficultyOffset = 0,
    this.sizeDelta = 0,
    this.numberReduction = 0,
    this.retryNonce = 0,
  });

  final int difficulty;
  final int index;
  final int runSeed;
  final int difficultyOffset;
  final int sizeDelta;
  final int numberReduction;
  final int retryNonce;

  EndlessLevelRequest copyWith({
    int? difficulty,
    int? index,
    int? runSeed,
    int? difficultyOffset,
    int? sizeDelta,
    int? numberReduction,
    int? retryNonce,
  }) {
    return EndlessLevelRequest(
      difficulty: difficulty ?? this.difficulty,
      index: index ?? this.index,
      runSeed: runSeed ?? this.runSeed,
      difficultyOffset: difficultyOffset ?? this.difficultyOffset,
      sizeDelta: sizeDelta ?? this.sizeDelta,
      numberReduction: numberReduction ?? this.numberReduction,
      retryNonce: retryNonce ?? this.retryNonce,
    );
  }
}

class EndlessLevelRepository {
  const EndlessLevelRepository();

  Future<Level> getCurrentLevel(EndlessLevelRequest request) {
    return loadEndlessLevelAsync(
      difficulty: request.difficulty,
      index: request.index,
      runSeed: request.runSeed,
      difficultyOffset: request.difficultyOffset,
      sizeDelta: request.sizeDelta,
      numberReduction: request.numberReduction,
      retryNonce: request.retryNonce,
    );
  }

  Future<Level> getNextLevel(EndlessLevelRequest request) {
    return getCurrentLevel(
      request.copyWith(index: request.index + 1),
    );
  }

  Future<void> warmUpPool(
    EndlessLevelRequest request, {
    int poolSize = _endlessPrefetchPoolTarget,
  }) {
    return prefetchEndlessLevels(
      difficulty: request.difficulty,
      fromIndex: request.index,
      runSeed: request.runSeed,
      difficultyOffset: request.difficultyOffset,
      sizeDelta: request.sizeDelta,
      numberReduction: request.numberReduction,
      poolSize: poolSize,
    );
  }
}

const EndlessLevelRepository endlessLevelRepository = EndlessLevelRepository();

const List<PackDef> appPacks = [
  PackDef(
    id: 'classic',
    levelCount: 200,
    gridSizes: [
      GridSize(width: 5, height: 5),
      GridSize(width: 6, height: 6),
      GridSize(width: 7, height: 7),
    ],
    wallDensity: 0.12,
    unlockRequirements: PackUnlockRequirements(),
  ),
  PackDef(
    id: 'architect',
    levelCount: 200,
    gridSizes: [
      GridSize(width: 5, height: 5),
      GridSize(width: 6, height: 6),
      GridSize(width: 7, height: 7),
      GridSize(width: 8, height: 8),
    ],
    wallDensity: 0.18,
    unlockRequirements: PackUnlockRequirements(requiredClassicLevels: 30),
  ),
  PackDef(
    id: 'expert',
    levelCount: 200,
    gridSizes: [
      GridSize(width: 6, height: 6),
      GridSize(width: 7, height: 7),
      GridSize(width: 8, height: 8),
      GridSize(width: 9, height: 9),
    ],
    wallDensity: 0.22,
    unlockRequirements: PackUnlockRequirements(
      requiredTotalCampaignLevels: 80,
      requiredAtOrAboveDifficulty: 10,
      difficultyThreshold: 4,
    ),
  ),
];

PackDef? getPackById(String packId) {
  for (final pack in appPacks) {
    if (pack.id == packId) {
      return pack;
    }
  }
  return null;
}

Level loadCampaignLevel(String packId, int levelIndex, {int retryNonce = 0}) {
  final fromPack =
      PackLevelRepository.instance.getLevelSync(packId, levelIndex);
  if (fromPack != null) {
    final key =
        _campaignLevelCacheKey(packId, levelIndex, retryNonce: retryNonce);
    _cacheCampaignLevel(key, fromPack.level);
    final fingerprint = fromPack.fingerprint.isNotEmpty
        ? fromPack.fingerprint
        : _levelFingerprintForNamespace(
            level: fromPack.level,
            namespaceMode: 'campaign',
          );
    unawaited(LevelExportRegistry.instance.recordCampaignLevel(
      packId: packId,
      levelIndex: levelIndex,
      level: fromPack.level,
      fingerprint: fingerprint,
      nonce: retryNonce,
    ));
    assert(() {
      debugPrint(
          '[LevelLoad] source=pack mode=campaign pack=$packId index=$levelIndex');
      return true;
    }());
    return fromPack.level;
  }
  final exported = LevelExportRegistry.instance.loadCampaignLevelFromExportSync(
    packId: packId,
    levelIndex: levelIndex,
  );
  if (exported != null) {
    final key =
        _campaignLevelCacheKey(packId, levelIndex, retryNonce: retryNonce);
    _cacheCampaignLevel(key, exported);
    assert(() {
      debugPrint(
          '[LevelLoad] source=export mode=campaign pack=$packId index=$levelIndex');
      return true;
    }());
    return exported;
  }
  for (var attempt = 0; attempt < 1; attempt++) {
    final candidateNonce = retryNonce + attempt;
    final key =
        _campaignLevelCacheKey(packId, levelIndex, retryNonce: candidateNonce);
    final cached = _campaignLevelCache[key];
    if (cached != null) {
      final namespace = _campaignFingerprintNamespace(
        packId: packId,
        levelIndex: levelIndex,
        level: cached,
      );
      final fingerprint = _levelFingerprintForNamespace(
        level: cached,
        namespaceMode: 'campaign',
      );
      unawaited(LevelExportRegistry.instance.recordCampaignLevel(
        packId: packId,
        levelIndex: levelIndex,
        level: cached,
        fingerprint: fingerprint,
        seed: campaignLevelSeed(packId, levelIndex),
        nonce: candidateNonce,
      ));
      _debugLevelFingerprint(
        source: 'campaign',
        level: cached,
        namespace: namespace,
        fromCache: true,
        unique: true,
      );
      assert(() {
        debugPrint(
            '[LevelLoad] source=memory-cache mode=campaign pack=$packId index=$levelIndex');
        return true;
      }());
      return cached;
    }
    final level = getLevelForPack(
      packId,
      levelIndex,
      retryNonce: candidateNonce,
      getPackById: getPackById,
    );
    final accepted = _acceptLevelUniquenessSync(
      level: level,
      namespace: _campaignFingerprintNamespace(
          packId: packId, levelIndex: levelIndex, level: level),
    );
    if (!accepted) {
      continue;
    }
    _cacheCampaignLevel(key, level);
    final namespace = _campaignFingerprintNamespace(
      packId: packId,
      levelIndex: levelIndex,
      level: level,
    );
    final fingerprint = _levelFingerprintForNamespace(
      level: level,
      namespaceMode: 'campaign',
    );
    unawaited(LevelExportRegistry.instance.recordCampaignLevel(
      packId: packId,
      levelIndex: levelIndex,
      level: level,
      fingerprint: fingerprint,
      seed: campaignLevelSeed(packId, levelIndex),
      nonce: candidateNonce,
    ));
    _debugLevelFingerprint(
      source: 'campaign',
      level: level,
      namespace: namespace,
      fromCache: false,
      unique: true,
    );
    assert(() {
      debugPrint(
          '[LevelLoad] source=generator mode=campaign pack=$packId index=$levelIndex');
      return true;
    }());
    return level;
  }
  throw Exception(
      'Could not generate a unique campaign level for $packId/$levelIndex');
}

Future<Level> loadCampaignLevelAsync(
  String packId,
  int levelIndex, {
  int retryNonce = 0,
}) async {
  final fromPack =
      await PackLevelRepository.instance.getLevel(packId, levelIndex);
  if (fromPack != null) {
    final key =
        _campaignLevelCacheKey(packId, levelIndex, retryNonce: retryNonce);
    _cacheCampaignLevel(key, fromPack.level);
    final fingerprint = fromPack.fingerprint.isNotEmpty
        ? fromPack.fingerprint
        : _levelFingerprintForNamespace(
            level: fromPack.level,
            namespaceMode: 'campaign',
          );
    await LevelExportRegistry.instance.recordCampaignLevel(
      packId: packId,
      levelIndex: levelIndex,
      level: fromPack.level,
      fingerprint: fingerprint,
      nonce: retryNonce,
    );
    assert(() {
      debugPrint(
          '[LevelLoad] source=pack mode=campaign pack=$packId index=$levelIndex');
      return true;
    }());
    return fromPack.level;
  }
  final exported =
      await LevelExportRegistry.instance.loadCampaignLevelFromExport(
    packId: packId,
    levelIndex: levelIndex,
  );
  if (exported != null) {
    final key =
        _campaignLevelCacheKey(packId, levelIndex, retryNonce: retryNonce);
    _cacheCampaignLevel(key, exported);
    assert(() {
      debugPrint(
          '[LevelLoad] source=export mode=campaign pack=$packId index=$levelIndex');
      return true;
    }());
    return exported;
  }
  await LevelFingerprintStore.instance.initialize();
  for (var attempt = 0; attempt < 1; attempt++) {
    final candidateNonce = retryNonce + attempt;
    final key =
        _campaignLevelCacheKey(packId, levelIndex, retryNonce: candidateNonce);
    final cached = _campaignLevelCache[key];
    if (cached != null) {
      final namespace = _campaignFingerprintNamespace(
        packId: packId,
        levelIndex: levelIndex,
        level: cached,
      );
      final fingerprint = _levelFingerprintForNamespace(
        level: cached,
        namespaceMode: 'campaign',
      );
      await LevelExportRegistry.instance.recordCampaignLevel(
        packId: packId,
        levelIndex: levelIndex,
        level: cached,
        fingerprint: fingerprint,
        seed: campaignLevelSeed(packId, levelIndex),
        nonce: candidateNonce,
      );
      _debugLevelFingerprint(
        source: 'campaign',
        level: cached,
        namespace: namespace,
        fromCache: true,
        unique: true,
      );
      assert(() {
        debugPrint(
            '[LevelLoad] source=memory-cache mode=campaign pack=$packId index=$levelIndex');
        return true;
      }());
      return cached;
    }
    final json = await compute(_generateCampaignLevelJson, <String, Object>{
      'packId': packId,
      'levelIndex': levelIndex,
      'retryNonce': candidateNonce,
    });
    final level = Level.fromJson(Map<String, dynamic>.from(json));
    final namespace = _campaignFingerprintNamespace(
      packId: packId,
      levelIndex: levelIndex,
      level: level,
    );
    final fingerprint = _levelFingerprintForNamespace(
      level: level,
      namespaceMode: 'campaign',
    );
    final isUnique = await LevelFingerprintStore.instance.registerIfUnique(
      namespace: namespace,
      fingerprint: fingerprint,
      maxEntries: _campaignFingerprintNamespaceLimit,
    );
    if (!isUnique) {
      _debugLevelFingerprint(
        source: 'campaign',
        level: level,
        namespace: namespace,
        fromCache: false,
        unique: false,
      );
      continue;
    }
    _rememberSessionFingerprint(namespace, fingerprint);
    _cacheCampaignLevel(key, level);
    await LevelExportRegistry.instance.recordCampaignLevel(
      packId: packId,
      levelIndex: levelIndex,
      level: level,
      fingerprint: fingerprint,
      seed: campaignLevelSeed(packId, levelIndex),
      nonce: candidateNonce,
    );
    _debugLevelFingerprint(
      source: 'campaign',
      level: level,
      namespace: namespace,
      fromCache: false,
      unique: true,
    );
    assert(() {
      debugPrint(
          '[LevelLoad] source=generator mode=campaign pack=$packId index=$levelIndex');
      return true;
    }());
    return level;
  }
  throw Exception(
      'Could not generate a unique campaign level for $packId/$levelIndex');
}

int campaignLevelSeed(String packId, int levelIndex) {
  return hashString('$packId-level-$levelIndex');
}

int campaignLevelDifficulty(String packId, int levelIndex) {
  final pack = getPackById(packId);
  if (pack == null) {
    return 1;
  }
  final clampedIndex = levelIndex.clamp(1, pack.levelCount);
  final progress = clampedIndex / pack.levelCount;
  return (1 + (progress * 5).floor()).clamp(1, 5);
}

Level loadDailyLevel({int retryNonce = 0}) {
  final dateKey = getTodayString();
  final exported = LevelExportRegistry.instance.loadDailyLevelFromExportSync(
    dateKey: dateKey,
  );
  if (exported != null) {
    _dailyLevelCache = exported;
    _dailyLevelCacheKey = dateKey;
    assert(() {
      debugPrint('[LevelLoad] source=export mode=daily date=$dateKey');
      return true;
    }());
    return exported;
  }
  if (_dailyLevelCache != null && _dailyLevelCacheKey == dateKey) {
    final fingerprint = _levelFingerprintForNamespace(
      level: _dailyLevelCache!,
      namespaceMode: 'daily',
    );
    unawaited(LevelExportRegistry.instance.recordDailyLevel(
      dateKey: dateKey,
      level: _dailyLevelCache!,
      fingerprint: fingerprint,
      nonce: retryNonce,
    ));
    _debugLevelFingerprint(
      source: 'daily',
      level: _dailyLevelCache!,
      namespace: _dailyFingerprintNamespace(dateKey, _dailyLevelCache!),
      fromCache: true,
      unique: true,
    );
    assert(() {
      debugPrint('[LevelLoad] source=memory-cache mode=daily date=$dateKey');
      return true;
    }());
    return _dailyLevelCache!;
  }
  for (var attempt = 0; attempt < 300; attempt++) {
    final nonce = retryNonce + attempt;
    final level = getDailyLevel(retryNonce: nonce);
    final namespace = _dailyFingerprintNamespace(dateKey, level);
    final accepted = _acceptLevelUniquenessSync(
      level: level,
      namespace: namespace,
      maxEntries: _dailyFingerprintNamespaceLimit,
    );
    if (!accepted) {
      continue;
    }
    _dailyLevelCache = level;
    _dailyLevelCacheKey = dateKey;
    final fingerprint = _levelFingerprintForNamespace(
      level: level,
      namespaceMode: 'daily',
    );
    unawaited(LevelExportRegistry.instance.recordDailyLevel(
      dateKey: dateKey,
      level: level,
      fingerprint: fingerprint,
      nonce: nonce,
    ));
    _debugLevelFingerprint(
      source: 'daily',
      level: level,
      namespace: namespace,
      fromCache: false,
      unique: true,
    );
    assert(() {
      debugPrint('[LevelLoad] source=generator mode=daily date=$dateKey');
      return true;
    }());
    return level;
  }
  throw Exception('Could not generate a unique daily level for $dateKey');
}

Future<Level> loadDailyLevelAsync({int retryNonce = 0}) async {
  await LevelFingerprintStore.instance.initialize();
  final dateKey = getTodayString();
  final exported = await LevelExportRegistry.instance.loadDailyLevelFromExport(
    dateKey: dateKey,
  );
  if (exported != null) {
    _dailyLevelCache = exported;
    _dailyLevelCacheKey = dateKey;
    assert(() {
      debugPrint('[LevelLoad] source=export mode=daily date=$dateKey');
      return true;
    }());
    return exported;
  }
  if (_dailyLevelCache != null && _dailyLevelCacheKey == dateKey) {
    final fingerprint = _levelFingerprintForNamespace(
      level: _dailyLevelCache!,
      namespaceMode: 'daily',
    );
    await LevelExportRegistry.instance.recordDailyLevel(
      dateKey: dateKey,
      level: _dailyLevelCache!,
      fingerprint: fingerprint,
      nonce: retryNonce,
    );
    _debugLevelFingerprint(
      source: 'daily',
      level: _dailyLevelCache!,
      namespace: _dailyFingerprintNamespace(dateKey, _dailyLevelCache!),
      fromCache: true,
      unique: true,
    );
    assert(() {
      debugPrint('[LevelLoad] source=memory-cache mode=daily date=$dateKey');
      return true;
    }());
    return _dailyLevelCache!;
  }
  for (var attempt = 0; attempt < 320; attempt++) {
    final nonce = retryNonce + attempt;
    Map<String, dynamic> json;
    try {
      json = await compute(_generateDailyLevelJson, <String, Object>{
        'retryNonce': nonce,
      });
    } catch (_) {
      continue;
    }
    final level = Level.fromJson(Map<String, dynamic>.from(json));
    final namespace = _dailyFingerprintNamespace(dateKey, level);
    final fingerprint = _levelFingerprintForNamespace(
      level: level,
      namespaceMode: 'daily',
    );
    final isUnique = await LevelFingerprintStore.instance.registerIfUnique(
      namespace: namespace,
      fingerprint: fingerprint,
      maxEntries: _dailyFingerprintNamespaceLimit,
    );
    if (!isUnique) {
      _debugLevelFingerprint(
        source: 'daily',
        level: level,
        namespace: namespace,
        fromCache: false,
        unique: false,
      );
      continue;
    }
    _rememberSessionFingerprint(namespace, fingerprint);
    _dailyLevelCache = level;
    _dailyLevelCacheKey = dateKey;
    await LevelExportRegistry.instance.recordDailyLevel(
      dateKey: dateKey,
      level: level,
      fingerprint: fingerprint,
      nonce: nonce,
    );
    _debugLevelFingerprint(
      source: 'daily',
      level: level,
      namespace: namespace,
      fromCache: false,
      unique: true,
    );
    assert(() {
      debugPrint('[LevelLoad] source=generator mode=daily date=$dateKey');
      return true;
    }());
    return level;
  }
  throw Exception('Could not generate a unique daily level for $dateKey');
}

Level loadEndlessLevel({
  required int difficulty,
  required int index,
  required int runSeed,
  int difficultyOffset = 0,
  int sizeDelta = 0,
  int numberReduction = 0,
  int retryNonce = 0,
}) {
  const sizes = {1: 5, 2: 6, 3: 7, 4: 8, 5: 9};
  final baseSize = sizes[difficulty] ?? 6;
  final adaptedSize = (baseSize + sizeDelta).clamp(5, 10);
  final key = _endlessLevelCacheKey(
    difficulty: difficulty,
    index: index,
    grid: adaptedSize,
    runSeed: runSeed,
    difficultyOffset: difficultyOffset,
    sizeDelta: sizeDelta,
    numberReduction: numberReduction,
  );
  final cached = _endlessLevelCache[key];
  if (cached != null) {
    return cached;
  }

  final seed = retryNonce == 0
      ? hashString('endless-$runSeed-$difficulty-$index')
      : hashString('endless-$runSeed-$difficulty-$index-retry-$retryNonce');
  final adaptedDifficulty = (difficulty + difficultyOffset).clamp(1, 5);
  final level = generateLevel(
    adaptedSize,
    adaptedSize,
    adaptedDifficulty,
    seed,
    'endless',
  );
  if (numberReduction <= 0 || level.numbers.length <= 2) {
    _cacheEndlessLevel(key, level);
    return level;
  }
  final reduced = _reduceIntermediateNumbers(level, numberReduction, seed);
  _cacheEndlessLevel(key, reduced);
  return reduced;
}

Future<Level> loadEndlessLevelAsync({
  required int difficulty,
  required int index,
  required int runSeed,
  int difficultyOffset = 0,
  int sizeDelta = 0,
  int numberReduction = 0,
  int retryNonce = 0,
}) async {
  const sizes = {1: 5, 2: 6, 3: 7, 4: 8, 5: 9};
  final baseSize = sizes[difficulty] ?? 6;
  final adaptedSize = (baseSize + sizeDelta).clamp(5, 10);
  final key = _endlessLevelCacheKey(
    difficulty: difficulty,
    index: index,
    grid: adaptedSize,
    runSeed: runSeed,
    difficultyOffset: difficultyOffset,
    sizeDelta: sizeDelta,
    numberReduction: numberReduction,
  );

  final fromPool = _consumeFromEndlessPrefetchPool(
    difficulty: difficulty,
    index: index,
    runSeed: runSeed,
    difficultyOffset: difficultyOffset,
    sizeDelta: sizeDelta,
    numberReduction: numberReduction,
    expectedKey: key,
  );
  if (fromPool != null) {
    _cacheEndlessLevel(key, fromPool);
    _scheduleEndlessPrefetch(
      difficulty: difficulty,
      index: index,
      runSeed: runSeed,
      difficultyOffset: difficultyOffset,
      sizeDelta: sizeDelta,
      numberReduction: numberReduction,
    );
    return fromPool;
  }

  final cached = _endlessLevelCache[key];
  if (cached != null) {
    _scheduleEndlessPrefetch(
      difficulty: difficulty,
      index: index,
      runSeed: runSeed,
      difficultyOffset: difficultyOffset,
      sizeDelta: sizeDelta,
      numberReduction: numberReduction,
    );
    return cached;
  }

  final diskCached = await _readEndlessLevelFromDisk(key);
  if (diskCached != null) {
    _cacheEndlessLevel(key, diskCached);
    _scheduleEndlessPrefetch(
      difficulty: difficulty,
      index: index,
      runSeed: runSeed,
      difficultyOffset: difficultyOffset,
      sizeDelta: sizeDelta,
      numberReduction: numberReduction,
    );
    return diskCached;
  }

  final json = await compute(_generateEndlessLevelJson, <String, Object>{
    'difficulty': difficulty,
    'index': index,
    'runSeed': runSeed,
    'difficultyOffset': difficultyOffset,
    'sizeDelta': sizeDelta,
    'numberReduction': numberReduction,
    'retryNonce': retryNonce,
    'maxRetries': _maxEndlessGenerationRetries,
  });
  final level = Level.fromJson(Map<String, dynamic>.from(json));
  _cacheEndlessLevel(key, level);
  await _writeEndlessLevelToDisk(key, level);
  _scheduleEndlessPrefetch(
    difficulty: difficulty,
    index: index,
    runSeed: runSeed,
    difficultyOffset: difficultyOffset,
    sizeDelta: sizeDelta,
    numberReduction: numberReduction,
  );
  return level;
}

Map<String, dynamic> _generateCampaignLevelJson(Map<String, Object> input) {
  final packId = input['packId']! as String;
  final levelIndex = input['levelIndex']! as int;
  final retryNonce = input['retryNonce']! as int;
  return getLevelForPack(
    packId,
    levelIndex,
    retryNonce: retryNonce,
    getPackById: getPackById,
  ).toJson();
}

Map<String, dynamic> _generateEndlessLevelJson(Map<String, Object> input) {
  final difficulty = input['difficulty']! as int;
  final index = input['index']! as int;
  final runSeed = input['runSeed']! as int;
  final difficultyOffset = input['difficultyOffset']! as int;
  final sizeDelta = input['sizeDelta']! as int;
  final numberReduction = input['numberReduction']! as int;
  final retryNonce = input['retryNonce']! as int;
  final maxRetries =
      (input['maxRetries'] as int?) ?? _maxEndlessGenerationRetries;

  Object? lastError;
  for (var attempt = 0; attempt < maxRetries; attempt++) {
    try {
      final level = loadEndlessLevel(
        difficulty: difficulty,
        index: index,
        runSeed: runSeed,
        difficultyOffset: difficultyOffset,
        sizeDelta: sizeDelta,
        numberReduction: numberReduction,
        retryNonce: retryNonce + attempt,
      );
      assert(() {
        debugPrint(
          '[EndlessGen] success difficulty=$difficulty index=$index '
          'runSeed=$runSeed attempt=$attempt',
        );
        return true;
      }());
      return level.toJson();
    } catch (error) {
      lastError = error;
    }
  }
  throw Exception(
    'Endless generation failed after $maxRetries attempts '
    '(difficulty=$difficulty index=$index runSeed=$runSeed): $lastError',
  );
}

Map<String, dynamic> _generateDailyLevelJson(Map<String, Object> input) {
  final retryNonce = input['retryNonce']! as int;
  return getDailyLevel(retryNonce: retryNonce).toJson();
}

String _campaignLevelCacheKey(
  String packId,
  int levelIndex, {
  int retryNonce = 0,
}) {
  final seed = campaignLevelSeed(packId, levelIndex);
  return '$packId:$levelIndex:$seed:$retryNonce';
}

String _campaignFingerprintNamespace({
  required String packId,
  required int levelIndex,
  required Level level,
}) {
  return 'campaign|$packId|index=$levelIndex|difficulty=${level.difficulty}|size=${level.width}x${level.height}';
}

String _dailyFingerprintNamespace(String dateKey, Level level) {
  return 'daily|$dateKey|size=${level.width}x${level.height}|difficulty=${level.difficulty}';
}

void _rememberSessionFingerprint(String namespace, String fingerprint) {
  _sessionFingerprintsByNamespace
      .putIfAbsent(namespace, () => <String>{})
      .add(fingerprint);
}

String _levelFingerprintForNamespace({
  required Level level,
  required String namespaceMode,
}) {
  final tier = 'd${level.difficulty}';
  return LevelFingerprintStore.instance.fingerprintForLevel(
    level: level,
    namespaceMode: namespaceMode,
    difficultyTier: tier,
  );
}

bool _acceptLevelUniquenessSync({
  required Level level,
  required String namespace,
  String? extraNamespace,
  int maxEntries = _campaignFingerprintNamespaceLimit,
}) {
  final fingerprint = _levelFingerprintForNamespace(
    level: level,
    namespaceMode: namespace.startsWith('daily|') ? 'daily' : 'campaign',
  );
  final sessionSet =
      _sessionFingerprintsByNamespace.putIfAbsent(namespace, () => <String>{});
  final primarySeen = sessionSet.contains(fingerprint) ||
      LevelFingerprintStore.instance.containsInMemory(namespace, fingerprint);
  if (primarySeen) {
    return false;
  }
  if (extraNamespace != null) {
    final extraSessionSet = _sessionFingerprintsByNamespace.putIfAbsent(
      extraNamespace,
      () => <String>{},
    );
    if (extraSessionSet.contains(fingerprint) ||
        LevelFingerprintStore.instance
            .containsInMemory(extraNamespace, fingerprint)) {
      return false;
    }
    extraSessionSet.add(fingerprint);
  }
  if (sessionSet.contains(fingerprint) ||
      LevelFingerprintStore.instance.containsInMemory(namespace, fingerprint)) {
    return false;
  }
  sessionSet.add(fingerprint);
  Future<void>(() async {
    await LevelFingerprintStore.instance.registerIfUnique(
      namespace: namespace,
      fingerprint: fingerprint,
      maxEntries: maxEntries,
    );
    if (extraNamespace != null) {
      await LevelFingerprintStore.instance.registerIfUnique(
        namespace: extraNamespace,
        fingerprint: fingerprint,
        maxEntries: maxEntries,
      );
    }
  });
  return true;
}

void _debugLevelFingerprint({
  required String source,
  required Level level,
  required String namespace,
  required bool fromCache,
  required bool unique,
}) {
  assert(() {
    final fingerprint = _levelFingerprintForNamespace(
      level: level,
      namespaceMode: source == 'daily' ? 'daily' : 'campaign',
    );
    debugPrint(
      '[LevelFingerprint] source=$source namespace=$namespace '
      'fingerprint=$fingerprint fromCache=$fromCache unique=$unique',
    );
    return true;
  }());
}

void _cacheCampaignLevel(String key, Level level) {
  if (_campaignLevelCache.containsKey(key)) {
    _campaignLevelCacheOrder.remove(key);
  }
  _campaignLevelCache[key] = level;
  _campaignLevelCacheOrder.add(key);

  if (_campaignLevelCacheOrder.length <= _campaignLevelCacheMaxEntries) {
    return;
  }
  final oldest = _campaignLevelCacheOrder.removeAt(0);
  _campaignLevelCache.remove(oldest);
}

String _endlessLevelCacheKey({
  required int difficulty,
  required int index,
  required int grid,
  required int runSeed,
  required int difficultyOffset,
  required int sizeDelta,
  required int numberReduction,
}) {
  return 'endless|tier=endless|difficulty=$difficulty|grid=$grid|runSeed=$runSeed|index=$index|difficultyOffset=$difficultyOffset|sizeDelta=$sizeDelta|numberReduction=$numberReduction|generatorVersion=$_endlessGeneratorVersion';
}

void _cacheEndlessLevel(String key, Level level) {
  if (_endlessLevelCache.containsKey(key)) {
    _endlessLevelCacheOrder.remove(key);
  }
  _endlessLevelCache[key] = level;
  _endlessLevelCacheOrder.add(key);

  if (_endlessLevelCacheOrder.length <= _endlessLevelCacheMaxEntries) {
    return;
  }
  final oldest = _endlessLevelCacheOrder.removeAt(0);
  _endlessLevelCache.remove(oldest);
}

Future<void> prefetchEndlessLevels({
  required int difficulty,
  required int fromIndex,
  required int runSeed,
  int difficultyOffset = 0,
  int sizeDelta = 0,
  int numberReduction = 0,
  int poolSize = _endlessPrefetchPoolTarget,
}) async {
  final id = _endlessPoolId(
    difficulty: difficulty,
    runSeed: runSeed,
    difficultyOffset: difficultyOffset,
    sizeDelta: sizeDelta,
    numberReduction: numberReduction,
  );
  if (_endlessPrefetchInFlight.contains(id)) {
    return;
  }
  _endlessPrefetchInFlight.add(id);
  try {
    final queue =
        _endlessPrefetchPools.putIfAbsent(id, () => <_PooledEndlessLevel>[]);
    final target = poolSize.clamp(1, 8);
    var candidateIndex = fromIndex + 1;
    if (queue.isNotEmpty) {
      queue.sort((a, b) => a.index.compareTo(b.index));
      candidateIndex = queue.last.index + 1;
    }
    var generated = 0;
    var loopGuard = 0;
    while (queue.length < target && loopGuard < target * 8) {
      loopGuard++;
      const sizes = {1: 5, 2: 6, 3: 7, 4: 8, 5: 9};
      final baseSize = sizes[difficulty] ?? 6;
      final adaptedSize = (baseSize + sizeDelta).clamp(5, 10);
      final cacheKey = _endlessLevelCacheKey(
        difficulty: difficulty,
        index: candidateIndex,
        grid: adaptedSize,
        runSeed: runSeed,
        difficultyOffset: difficultyOffset,
        sizeDelta: sizeDelta,
        numberReduction: numberReduction,
      );
      if (_endlessLevelCache.containsKey(cacheKey)) {
        final level = _endlessLevelCache[cacheKey]!;
        queue.add(
          _PooledEndlessLevel(
            index: candidateIndex,
            cacheKey: cacheKey,
            level: level,
          ),
        );
        candidateIndex++;
        continue;
      }

      final diskLevel = await _readEndlessLevelFromDisk(cacheKey);
      if (diskLevel != null) {
        _cacheEndlessLevel(cacheKey, diskLevel);
        queue.add(
          _PooledEndlessLevel(
            index: candidateIndex,
            cacheKey: cacheKey,
            level: diskLevel,
          ),
        );
        candidateIndex++;
        continue;
      }

      try {
        final json = await compute(_generateEndlessLevelJson, <String, Object>{
          'difficulty': difficulty,
          'index': candidateIndex,
          'runSeed': runSeed,
          'difficultyOffset': difficultyOffset,
          'sizeDelta': sizeDelta,
          'numberReduction': numberReduction,
          'retryNonce': 0,
          'maxRetries': _maxEndlessGenerationRetries,
        });
        final level = Level.fromJson(Map<String, dynamic>.from(json));
        _cacheEndlessLevel(cacheKey, level);
        await _writeEndlessLevelToDisk(cacheKey, level);
        queue.add(
          _PooledEndlessLevel(
            index: candidateIndex,
            cacheKey: cacheKey,
            level: level,
          ),
        );
        generated++;
      } catch (_) {
        // Move to next index to avoid looping forever on one problematic slot.
      }
      candidateIndex++;
    }
    assert(() {
      debugPrint(
        '[EndlessPrefetch] difficulty=$difficulty runSeed=$runSeed '
        'queue=${queue.length} generated=$generated',
      );
      return true;
    }());
  } finally {
    _endlessPrefetchInFlight.remove(id);
  }
}

void _scheduleEndlessPrefetch({
  required int difficulty,
  required int index,
  required int runSeed,
  required int difficultyOffset,
  required int sizeDelta,
  required int numberReduction,
}) {
  Future<void>.microtask(() {
    return prefetchEndlessLevels(
      difficulty: difficulty,
      fromIndex: index,
      runSeed: runSeed,
      difficultyOffset: difficultyOffset,
      sizeDelta: sizeDelta,
      numberReduction: numberReduction,
    );
  });
}

Level? _consumeFromEndlessPrefetchPool({
  required int difficulty,
  required int index,
  required int runSeed,
  required int difficultyOffset,
  required int sizeDelta,
  required int numberReduction,
  required String expectedKey,
}) {
  final id = _endlessPoolId(
    difficulty: difficulty,
    runSeed: runSeed,
    difficultyOffset: difficultyOffset,
    sizeDelta: sizeDelta,
    numberReduction: numberReduction,
  );
  final queue = _endlessPrefetchPools[id];
  if (queue == null || queue.isEmpty) {
    return null;
  }
  queue.sort((a, b) => a.index.compareTo(b.index));
  for (var i = 0; i < queue.length; i++) {
    final item = queue[i];
    if (item.index == index && item.cacheKey == expectedKey) {
      queue.removeAt(i);
      return item.level;
    }
  }
  return null;
}

String _endlessPoolId({
  required int difficulty,
  required int runSeed,
  required int difficultyOffset,
  required int sizeDelta,
  required int numberReduction,
}) {
  return '$difficulty:$runSeed:$difficultyOffset:$sizeDelta:$numberReduction';
}

Future<Level?> _readEndlessLevelFromDisk(String key) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('$_endlessDiskPrefix$key');
  if (raw == null || raw.isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    return Level.fromJson(Map<String, dynamic>.from(decoded));
  } catch (_) {
    return null;
  }
}

Future<void> _writeEndlessLevelToDisk(String key, Level level) async {
  final prefs = await SharedPreferences.getInstance();
  final storageKey = '$_endlessDiskPrefix$key';
  await prefs.setString(storageKey, jsonEncode(level.toJson()));
  final keys = prefs.getStringList(_endlessDiskIndexKey) ?? <String>[];
  keys.remove(key);
  keys.add(key);
  while (keys.length > _endlessDiskCacheMaxEntries) {
    final oldest = keys.removeAt(0);
    await prefs.remove('$_endlessDiskPrefix$oldest');
  }
  await prefs.setStringList(_endlessDiskIndexKey, keys);
}

Level _reduceIntermediateNumbers(Level level, int reduction, int seed) {
  if (level.numbers.length <= 2 || reduction <= 0) {
    return level;
  }
  final rng = createRng(seed ^ 0x5F3759DF);
  final entries = level.numbers.entries.toList();
  entries.sort((a, b) => a.value.compareTo(b.value));
  final keep = <MapEntry<int, int>>[entries.first, entries.last];
  final middle = entries.sublist(1, entries.length - 1);
  shuffle(middle, rng);
  final keepMiddleCount = (middle.length - reduction).clamp(0, middle.length);
  keep.addAll(middle.take(keepMiddleCount));
  keep.sort((a, b) => a.value.compareTo(b.value));
  final numbers = <int, int>{};
  for (var i = 0; i < keep.length; i++) {
    // Keep selected clue cells but reindex values to a complete 1..N sequence.
    numbers[keep[i].key] = i + 1;
  }
  return Level(
    id: level.id,
    width: level.width,
    height: level.height,
    numbers: numbers,
    walls: level.walls,
    solution: level.solution,
    difficulty: level.difficulty,
    pack: level.pack,
  );
}
