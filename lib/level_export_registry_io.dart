import 'dart:convert';
import 'dart:io';

import 'engine/level.dart';

const String levelExportSchemaVersion = '1';
const String levelExportGeneratorVersion = 'struct-v3';

class ExportLevelRecord {
  const ExportLevelRecord({
    required this.id,
    required this.mode,
    required this.packId,
    required this.levelIndex,
    required this.date,
    required this.size,
    required this.difficultyTier,
    required this.generatorVersion,
    required this.seed,
    required this.nonce,
    required this.fingerprint,
    required this.clues,
    required this.walls,
    required this.levelJson,
  });

  final String id;
  final String mode;
  final String? packId;
  final int? levelIndex;
  final String? date;
  final Map<String, int> size;
  final String difficultyTier;
  final String generatorVersion;
  final int? seed;
  final int? nonce;
  final String fingerprint;
  final List<Map<String, int>> clues;
  final List<Map<String, int>> walls;
  final Map<String, dynamic> levelJson;

  factory ExportLevelRecord.fromJson(Map<String, dynamic> json) {
    return ExportLevelRecord(
      id: json['id'] as String,
      mode: json['mode'] as String,
      packId: json['packId'] as String?,
      levelIndex: json['levelIndex'] as int?,
      date: json['date'] as String?,
      size: Map<String, int>.from((json['size'] as Map).map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      )),
      difficultyTier: json['difficultyTier'] as String,
      generatorVersion: json['generatorVersion'] as String,
      seed: json['seed'] as int?,
      nonce: json['nonce'] as int?,
      fingerprint: json['fingerprint'] as String,
      clues: (json['clues'] as List<dynamic>)
          .map((e) => Map<String, int>.from((e as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              )))
          .toList(growable: false),
      walls: (json['walls'] as List<dynamic>)
          .map((e) => Map<String, int>.from((e as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toInt()),
              )))
          .toList(growable: false),
      levelJson: Map<String, dynamic>.from(json['level'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'mode': mode,
      'packId': packId,
      'levelIndex': levelIndex,
      'date': date,
      'size': size,
      'difficultyTier': difficultyTier,
      'generatorVersion': generatorVersion,
      'seed': seed,
      'nonce': nonce,
      'fingerprint': fingerprint,
      'clues': clues,
      'walls': walls,
      'level': levelJson,
    };
  }

  Level toLevel() => Level.fromJson(levelJson);
}

class LevelExportRegistry {
  LevelExportRegistry._();

  static final LevelExportRegistry instance = LevelExportRegistry._();

  bool _initialized = false;
  final Set<String> _fingerprints = <String>{};
  final Map<String, ExportLevelRecord> _campaignByKey =
      <String, ExportLevelRecord>{};
  final Map<String, ExportLevelRecord> _dailyByDate =
      <String, ExportLevelRecord>{};

  Directory? _baseDir;
  File? _registryFile;
  File? _bundleFile;

  Future<void> initialize({String? basePath}) async {
    if (_initialized) {
      return;
    }
    final resolvedPath = basePath ??
        '${Directory.current.path}${Platform.pathSeparator}exports${Platform.pathSeparator}levels';
    _baseDir = Directory(resolvedPath);
    if (!await _baseDir!.exists()) {
      await _baseDir!.create(recursive: true);
    }
    _registryFile =
        File('${_baseDir!.path}${Platform.pathSeparator}registry.ndjson');
    _bundleFile =
        File('${_baseDir!.path}${Platform.pathSeparator}all_levels.json');
    if (!await _registryFile!.exists()) {
      await _registryFile!.writeAsString('', flush: true);
    }
    await _hydrateFromDisk();
    _initialized = true;
  }

  String get bundlePath => _bundleFile?.path ?? '';
  String get registryPath => _registryFile?.path ?? '';

  Future<void> resetForTests({String? basePath}) async {
    _initialized = false;
    _fingerprints.clear();
    _campaignByKey.clear();
    _dailyByDate.clear();
    await initialize(basePath: basePath);
  }

  Future<void> recordCampaignLevel({
    required String packId,
    required int levelIndex,
    required Level level,
    required String fingerprint,
    int? seed,
    int? nonce,
  }) async {
    await initialize();
    final record = _buildRecord(
      mode: 'campaign',
      level: level,
      fingerprint: fingerprint,
      packId: packId,
      levelIndex: levelIndex,
      date: null,
      seed: seed,
      nonce: nonce,
    );
    await _appendIfUnique(record);
  }

  Future<void> recordDailyLevel({
    required String dateKey,
    required Level level,
    required String fingerprint,
    int? seed,
    int? nonce,
  }) async {
    await initialize();
    final record = _buildRecord(
      mode: 'daily',
      level: level,
      fingerprint: fingerprint,
      packId: null,
      levelIndex: null,
      date: dateKey,
      seed: seed,
      nonce: nonce,
    );
    await _appendIfUnique(record);
  }

  Level? loadCampaignLevelFromExportSync({
    required String packId,
    required int levelIndex,
  }) {
    final key = '$packId#$levelIndex';
    final record = _campaignByKey[key];
    assert(() {
      if (record != null) {
        stderr.writeln(
            '[LevelExport] load source=export mode=campaign pack=$packId index=$levelIndex');
      }
      return true;
    }());
    return record?.toLevel();
  }

  Level? loadDailyLevelFromExportSync({
    required String dateKey,
  }) {
    final record = _dailyByDate[dateKey];
    assert(() {
      if (record != null) {
        stderr.writeln(
            '[LevelExport] load source=export mode=daily date=$dateKey');
      }
      return true;
    }());
    return record?.toLevel();
  }

  Future<Level?> loadCampaignLevelFromExport({
    required String packId,
    required int levelIndex,
  }) async {
    await initialize();
    return loadCampaignLevelFromExportSync(
        packId: packId, levelIndex: levelIndex);
  }

  Future<Level?> loadDailyLevelFromExport({
    required String dateKey,
  }) async {
    await initialize();
    return loadDailyLevelFromExportSync(dateKey: dateKey);
  }

  Future<List<ExportLevelRecord>> readAllRecords() async {
    await initialize();
    final records = <ExportLevelRecord>[];
    records.addAll(_campaignByKey.values);
    records.addAll(_dailyByDate.values);
    records.sort((a, b) => a.id.compareTo(b.id));
    return records;
  }

  Future<String> exportBundle() async {
    await initialize();
    final records = await readAllRecords();
    final payload = <String, dynamic>{
      'schemaVersion': levelExportSchemaVersion,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'generatorVersion': levelExportGeneratorVersion,
      'count': records.length,
      'levels': records.map((e) => e.toJson()).toList(growable: false),
    };
    await _bundleFile!.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return _bundleFile!.path;
  }

  Future<void> _hydrateFromDisk() async {
    _fingerprints.clear();
    _campaignByKey.clear();
    _dailyByDate.clear();

    if (await _bundleFile!.exists()) {
      try {
        final decoded = jsonDecode(await _bundleFile!.readAsString())
            as Map<String, dynamic>;
        final levels =
            (decoded['levels'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<Map>()
                .map((e) =>
                    ExportLevelRecord.fromJson(Map<String, dynamic>.from(e)));
        for (final record in levels) {
          _indexRecord(record);
        }
      } catch (_) {}
    }

    final lines = await _registryFile!.readAsLines();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      try {
        final decoded = jsonDecode(trimmed) as Map<String, dynamic>;
        final record = ExportLevelRecord.fromJson(decoded);
        _indexRecord(record);
      } catch (_) {}
    }
  }

  void _indexRecord(ExportLevelRecord record) {
    _fingerprints.add(record.fingerprint);
    if (record.mode == 'campaign' &&
        record.packId != null &&
        record.levelIndex != null) {
      _campaignByKey['${record.packId}#${record.levelIndex}'] = record;
    } else if (record.mode == 'daily' && record.date != null) {
      _dailyByDate[record.date!] = record;
    }
  }

  Future<void> _appendIfUnique(ExportLevelRecord record) async {
    if (_fingerprints.contains(record.fingerprint)) {
      assert(() {
        stderr.writeln(
          '[LevelExport] record skipped duplicate mode=${record.mode} id=${record.id} fingerprint=${record.fingerprint}',
        );
        return true;
      }());
      return;
    }
    await _registryFile!.writeAsString(
      '${jsonEncode(record.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
    _indexRecord(record);
    assert(() {
      stderr.writeln(
        '[LevelExport] record stored mode=${record.mode} id=${record.id} fingerprint=${record.fingerprint}',
      );
      return true;
    }());
  }

  ExportLevelRecord _buildRecord({
    required String mode,
    required Level level,
    required String fingerprint,
    required String? packId,
    required int? levelIndex,
    required String? date,
    required int? seed,
    required int? nonce,
  }) {
    final orderedClues = level.numbers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final clues = orderedClues
        .map((entry) => <String, int>{
              'n': entry.value,
              'x': entry.key % level.width,
              'y': entry.key ~/ level.width,
            })
        .toList(growable: false);
    final walls = level.walls.map((wall) {
      final a = wall.cell1 < wall.cell2 ? wall.cell1 : wall.cell2;
      final b = wall.cell1 > wall.cell2 ? wall.cell1 : wall.cell2;
      return <String, int>{'cell1': a, 'cell2': b};
    }).toList(growable: true)
      ..sort((a, b) {
        final byA = a['cell1']!.compareTo(b['cell1']!);
        if (byA != 0) {
          return byA;
        }
        return a['cell2']!.compareTo(b['cell2']!);
      });
    final recordId =
        mode == 'campaign' ? 'campaign|$packId|$levelIndex' : 'daily|$date';
    return ExportLevelRecord(
      id: recordId,
      mode: mode,
      packId: packId,
      levelIndex: levelIndex,
      date: date,
      size: <String, int>{'w': level.width, 'h': level.height},
      difficultyTier: 'd${level.difficulty}',
      generatorVersion: levelExportGeneratorVersion,
      seed: seed,
      nonce: nonce,
      fingerprint: fingerprint,
      clues: clues,
      walls: walls,
      levelJson: level.toJson(),
    );
  }
}
