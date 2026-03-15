bool isDefaultSkinId(String? skinId) {
  final normalized = (skinId ?? '').trim().toLowerCase();
  return normalized.isEmpty ||
      normalized == 'default' ||
      normalized == 'pointer_default' ||
      normalized == 'pointer-default' ||
      normalized == 'skin_default' ||
      normalized == 'none';
}

List<String> orderedAvatarCandidates({
  required String photoUrl,
  required String skinUrl,
  required bool preferSkin,
}) {
  final photo = photoUrl.trim();
  final skin = skinUrl.trim();
  final list = <String>[];
  if (preferSkin) {
    if (skin.isNotEmpty) list.add(skin);
    if (photo.isNotEmpty) list.add(photo);
    return list;
  }
  if (photo.isNotEmpty) list.add(photo);
  if (skin.isNotEmpty) list.add(skin);
  return list;
}

