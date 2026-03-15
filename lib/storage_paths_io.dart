import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String?> resolveExportBasePath() async {
  final baseDir = await getApplicationSupportDirectory();
  final exportsDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}exports${Platform.pathSeparator}levels');
  if (!await exportsDir.exists()) {
    await exportsDir.create(recursive: true);
  }
  return exportsDir.path;
}

bool get supportsFileExport => true;
