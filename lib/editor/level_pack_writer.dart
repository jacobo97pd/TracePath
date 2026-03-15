import 'editor_codec.dart';
import 'level_pack_writer_stub.dart'
    if (dart.library.io) 'level_pack_writer_io.dart' as impl;

class SaveToGeneralPackResult {
  const SaveToGeneralPackResult({
    required this.added,
    required this.message,
    this.levelId,
  });

  final bool added;
  final String message;
  final String? levelId;
}

bool get supportsGeneralPackWrite => impl.supportsGeneralPackWrite;

Future<SaveToGeneralPackResult> saveLevelToGeneralPack(
  EditorLevelData data,
) {
  return impl.saveLevelToGeneralPack(data);
}

