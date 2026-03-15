import 'dart:convert';
import 'dart:io';

import 'package:zip_path_flutter/level_export_registry.dart';

Future<void> main(List<String> args) async {
  final basePath = args.isNotEmpty ? args.first : null;
  await LevelExportRegistry.instance.initialize(basePath: basePath);
  final bundlePath = await LevelExportRegistry.instance.exportBundle();
  final records = await LevelExportRegistry.instance.readAllRecords();

  final baseDir = File(bundlePath).parent;
  final campaignByPack = <String, List<ExportLevelRecord>>{};
  final dailyByDate = <String, List<ExportLevelRecord>>{};
  for (final record in records) {
    if (record.mode == 'campaign' && record.packId != null) {
      campaignByPack
          .putIfAbsent(record.packId!, () => <ExportLevelRecord>[])
          .add(record);
    } else if (record.mode == 'daily' && record.date != null) {
      dailyByDate
          .putIfAbsent(record.date!, () => <ExportLevelRecord>[])
          .add(record);
    }
  }

  for (final entry in campaignByPack.entries) {
    entry.value.sort((a, b) {
      final ai = a.levelIndex ?? 0;
      final bi = b.levelIndex ?? 0;
      return ai.compareTo(bi);
    });
    final out = File(
      '${baseDir.path}${Platform.pathSeparator}campaign_pack_${entry.key}.json',
    );
    await out.writeAsString(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'schemaVersion': levelExportSchemaVersion,
        'mode': 'campaign',
        'packId': entry.key,
        'count': entry.value.length,
        'levels': entry.value.map((e) => e.toJson()).toList(growable: false),
      }),
      flush: true,
    );
  }

  for (final entry in dailyByDate.entries) {
    final out = File(
      '${baseDir.path}${Platform.pathSeparator}daily_${entry.key}.json',
    );
    await out.writeAsString(
      const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
        'schemaVersion': levelExportSchemaVersion,
        'mode': 'daily',
        'date': entry.key,
        'count': entry.value.length,
        'levels': entry.value.map((e) => e.toJson()).toList(growable: false),
      }),
      flush: true,
    );
  }

  stdout.writeln('Export complete');
  stdout.writeln('Base: ${baseDir.path}');
  stdout.writeln('Bundle: $bundlePath');
  stdout.writeln('Total levels: ${records.length}');
  stdout.writeln('Campaign files: ${campaignByPack.length}');
  stdout.writeln('Daily files: ${dailyByDate.length}');
}
