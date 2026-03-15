import 'storage_paths_stub.dart'
    if (dart.library.io) 'storage_paths_io.dart'
    if (dart.library.html) 'storage_paths_web.dart' as impl;

Future<String?> resolveExportBasePath() => impl.resolveExportBasePath();

bool get supportsFileExport => impl.supportsFileExport;
