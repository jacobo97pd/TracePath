import 'editor_codec.dart';
import 'level_pack_writer.dart';

bool get supportsGeneralPackWrite => false;

Future<SaveToGeneralPackResult> saveLevelToGeneralPack(
  EditorLevelData data,
) async {
  return const SaveToGeneralPackResult(
    added: false,
    message:
        'Guardar en paquete general no disponible en esta plataforma (usa desktop).',
  );
}

