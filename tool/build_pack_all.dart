import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final corePath = 'assets/levels/pack_core_v1.json';
  final curatedPath = 'assets/levels/pack_curated_v1.json';
  final outPath = 'assets/levels/pack_all_v1.json';

  final core =
      jsonDecode(await File(corePath).readAsString()) as Map<String, dynamic>;
  final curated = jsonDecode(await File(curatedPath).readAsString())
      as Map<String, dynamic>;

  final combined = <Map<String, dynamic>>[];
  final seen = <String>{};

  void addLevels(Map<String, dynamic> pack) {
    final levels = (pack['levels'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e));
    for (final level in levels) {
      final fp = (level['fingerprint'] as String?) ?? '';
      final dedupeKey = fp.isNotEmpty ? 'fp:$fp' : 'id:${level['id']}';
      if (seen.add(dedupeKey)) {
        combined.add(level);
      }
    }
  }

  addLevels(core);
  addLevels(curated);

  final output = <String, dynamic>{
    'packId': 'all',
    'version': 'pack_all_v1',
    'count': combined.length,
    'levels': combined,
  };

  await File(outPath)
      .writeAsString(const JsonEncoder.withIndent('  ').convert(output));
  stdout.writeln('Wrote $outPath with ${combined.length} levels');
}
