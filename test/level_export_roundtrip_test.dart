import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zip_path_flutter/app_data.dart';
import 'package:zip_path_flutter/engine/level_generator.dart';
import 'package:zip_path_flutter/engine/seed_random.dart';
import 'package:zip_path_flutter/level_export_registry.dart';
import 'package:zip_path_flutter/level_fingerprint_store.dart';

void main() {
  test('exports and reloads campaign/daily with identical fingerprints', () async {
    final basePath =
        '${Directory.current.path}${Platform.pathSeparator}build${Platform.pathSeparator}test_exports${Platform.pathSeparator}levels_roundtrip';
    final dir = Directory(basePath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }

    await LevelExportRegistry.instance.resetForTests(basePath: basePath);

    final c1 = getLevelForPack(
      'classic',
      1,
      retryNonce: 777,
      getPackById: getPackById,
    );
    final c2 = getLevelForPack(
      'classic',
      2,
      retryNonce: 778,
      getPackById: getPackById,
    );
    final daily = await loadDailyLevelAsync(retryNonce: 779);
    final today = getTodayString();

    final c1Fingerprint = LevelFingerprintStore.instance.fingerprintForLevel(
      level: c1,
      namespaceMode: 'campaign',
      difficultyTier: 'd${c1.difficulty}',
    );
    final c2Fingerprint = LevelFingerprintStore.instance.fingerprintForLevel(
      level: c2,
      namespaceMode: 'campaign',
      difficultyTier: 'd${c2.difficulty}',
    );
    final dailyFingerprint = LevelFingerprintStore.instance.fingerprintForLevel(
      level: daily,
      namespaceMode: 'daily',
      difficultyTier: 'd${daily.difficulty}',
    );
    await LevelExportRegistry.instance.recordCampaignLevel(
      packId: 'classic',
      levelIndex: 1,
      level: c1,
      fingerprint: c1Fingerprint,
      nonce: 777,
    );
    await LevelExportRegistry.instance.recordCampaignLevel(
      packId: 'classic',
      levelIndex: 2,
      level: c2,
      fingerprint: c2Fingerprint,
      nonce: 778,
    );
    await LevelExportRegistry.instance.recordDailyLevel(
      dateKey: today,
      level: daily,
      fingerprint: dailyFingerprint,
      nonce: 779,
    );

    final bundlePath = await LevelExportRegistry.instance.exportBundle();
    final bundleFile = File(bundlePath);
    expect(bundleFile.existsSync(), isTrue);

    final bundle = jsonDecode(bundleFile.readAsStringSync()) as Map<String, dynamic>;
    final levels = (bundle['levels'] as List<dynamic>? ?? const <dynamic>[]);
    expect(levels.length, greaterThanOrEqualTo(3));

    await LevelExportRegistry.instance.resetForTests(basePath: basePath);
    final rc1 = await LevelExportRegistry.instance.loadCampaignLevelFromExport(
      packId: 'classic',
      levelIndex: 1,
    );
    final rc2 = await LevelExportRegistry.instance.loadCampaignLevelFromExport(
      packId: 'classic',
      levelIndex: 2,
    );
    final rdaily = await LevelExportRegistry.instance.loadDailyLevelFromExport(
      dateKey: today,
    );

    expect(rc1, isNotNull);
    expect(rc2, isNotNull);
    expect(rdaily, isNotNull);

    final fC1 = c1Fingerprint;
    final fRC1 = LevelFingerprintStore.instance.fingerprintForLevel(
      level: rc1!,
      namespaceMode: 'campaign',
      difficultyTier: 'd${rc1.difficulty}',
    );
    final fC2 = c2Fingerprint;
    final fRC2 = LevelFingerprintStore.instance.fingerprintForLevel(
      level: rc2!,
      namespaceMode: 'campaign',
      difficultyTier: 'd${rc2.difficulty}',
    );
    final fD = dailyFingerprint;
    final fRD = LevelFingerprintStore.instance.fingerprintForLevel(
      level: rdaily!,
      namespaceMode: 'daily',
      difficultyTier: 'd${rdaily.difficulty}',
    );

    expect(fRC1, equals(fC1));
    expect(fRC2, equals(fC2));
    expect(fRD, equals(fD));
    expect(jsonEncode(rc1.toJson()), equals(jsonEncode(c1.toJson())));
    expect(jsonEncode(rc2.toJson()), equals(jsonEncode(c2.toJson())));
    expect(jsonEncode(rdaily.toJson()), equals(jsonEncode(daily.toJson())));
  });
}
