import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SkinCatalogItem {
  const SkinCatalogItem({
    required this.id,
    required this.name,
    this.fullImagePath = '',
    this.previewImagePath = '',
    this.bannerImagePath = '',
    this.cardImagePath = '',
    required this.costCoins,
    this.isPremium = false,
    this.rarity = 'Common',
    this.featured = false,
    this.enabled = true,
    this.order = 0,
    this.posX = 0,
    this.posY = 0,
  });

  final String id;
  final String name;
  final String fullImagePath;
  final String previewImagePath;
  final String bannerImagePath;
  final String cardImagePath;
  final int costCoins;
  final bool isPremium;
  final String rarity;
  final bool featured;
  final bool enabled;
  final int order;
  final int posX;
  final int posY;

  String get imagePath => fullImagePath;
  String get thumbnailPath => previewImagePath;
  String get cardPath => cardImagePath;

  SkinCatalogItem copyWith({
    String? id,
    String? name,
    String? fullImagePath,
    String? previewImagePath,
    String? bannerImagePath,
    String? cardImagePath,
    int? costCoins,
    bool? isPremium,
    String? rarity,
    bool? featured,
    bool? enabled,
    int? order,
    int? posX,
    int? posY,
  }) {
    return SkinCatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      fullImagePath: fullImagePath ?? this.fullImagePath,
      previewImagePath: previewImagePath ?? this.previewImagePath,
      bannerImagePath: bannerImagePath ?? this.bannerImagePath,
      cardImagePath: cardImagePath ?? this.cardImagePath,
      costCoins: costCoins ?? this.costCoins,
      isPremium: isPremium ?? this.isPremium,
      rarity: rarity ?? this.rarity,
      featured: featured ?? this.featured,
      enabled: enabled ?? this.enabled,
      order: order ?? this.order,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'fullImagePath': fullImagePath,
        'previewImagePath': previewImagePath,
        'bannerImagePath': bannerImagePath,
        'cardImagePath': cardImagePath,
        'imagePath': fullImagePath,
        'thumbPath': previewImagePath,
        'thumbnailPath': previewImagePath,
        'cardPath': cardImagePath,
        'image': <String, Object?>{
          'fullPath': fullImagePath,
          'previewPath': previewImagePath,
          'iconPath': previewImagePath,
          'bannerPath': bannerImagePath,
        },
        'costCoins': costCoins,
        'isPremium': isPremium,
        'rarity': rarity,
        'featured': featured,
        'enabled': enabled,
        'order': order,
        'posX': posX,
        'posY': posY,
      };

  static SkinCatalogItem fromJson(Map<String, dynamic> json) {
    final imageRaw = json['image'];
    final image = imageRaw is Map
        ? Map<String, dynamic>.from(imageRaw)
        : const <String, dynamic>{};

    final id = _canonicalId(_readString(json['id']) ?? '');
    final full = _pick(<String?>[
      _readString(json['fullImagePath']),
      _readString(image['fullPath']),
      _readString(json['imagePath']),
      _readString(json['image']),
    ]);
    final preview = _pick(<String?>[
      _readString(json['previewImagePath']),
      _readString(image['previewPath']),
      _readString(json['thumbPath']),
      _readString(json['thumbnailPath']),
      _readString(image['iconPath']),
      _inferPreviewFromFull(full),
    ]);
    final banner = _pick(<String?>[
      _readString(json['bannerImagePath']),
      _readString(image['bannerPath']),
    ]);
    final card = _pick(<String?>[
      _readString(json['cardImagePath']),
      _readString(json['cardPath']),
    ]);

    return SkinCatalogItem(
      id: id.isEmpty ? 'pointer_default' : id,
      name: _readString(json['name']) ?? 'Skin',
      fullImagePath: _normalizePath(full),
      previewImagePath: _normalizePath(preview),
      bannerImagePath: _normalizePath(banner),
      cardImagePath: _normalizePath(card),
      costCoins: (json['costCoins'] as num?)?.toInt() ??
          (json['price'] as num?)?.toInt() ??
          0,
      isPremium: _readBool(json['isPremium'], defaultValue: false),
      rarity: _readString(json['rarity']) ?? 'Common',
      featured: _readBool(json['featured'], defaultValue: false),
      enabled: _readBool(json['enabled'], defaultValue: true),
      order: (json['order'] as num?)?.toInt() ?? 0,
      posX: (json['posX'] as num?)?.toInt() ?? 0,
      posY: (json['posY'] as num?)?.toInt() ?? 0,
    );
  }

  static String _pick(List<String?> values) {
    for (final value in values) {
      final v = value?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static bool _readBool(Object? value, {required bool defaultValue}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return defaultValue;
  }

  static String? _readString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _canonicalId(String rawId) {
    final normalized = rawId.trim().toLowerCase();
    if (normalized == 'default' ||
        normalized == 'pointer-default' ||
        normalized == 'pointer_default') {
      return 'pointer_default';
    }
    return rawId.trim();
  }

  static String _normalizePath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceAll('\\', '/');
  }

  static String _inferPreviewFromFull(String fullRaw) {
    final full = fullRaw.trim();
    if (full.isEmpty) return '';
    final normalized = full.replaceAll('\\', '/');
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized.replaceFirstMapped(
        RegExp(r'(\.[^./?]+)(\?.*)?$'),
        (m) => '-thumb${m.group(1)}${m.group(2) ?? ''}',
      );
    }
    final dot = normalized.lastIndexOf('.');
    if (dot <= 0) return normalized;
    return '${normalized.substring(0, dot)}-thumb${normalized.substring(dot)}';
  }
}

class SkinCatalogService extends ChangeNotifier {
  SkinCatalogService(this._prefs) {
    _loadFromPrefs();
    _bootstrapCatalog();
  }

  static const String _catalogKey = 'shop_skin_catalog_v2';
  static const int _catalogSchemaVersion = 2;
  static const String _catalogLegacyKey = 'shop_skin_catalog_v1';
  static const String _remoteSkinsUrlKey = 'shop_skin_remote_url_v1';
  static const String _defaultRemoteSkinsUrl = 'http://localhost:8080/skins/';
  static const String _assetManifestPath = 'assets/skins/skins_catalog_v1.json';
  static const String _firestoreCollection = 'skins_catalog';
  static const String _preferredDatabaseId = 'tracepath-database';
  static const SkinCatalogItem _defaultItem = SkinCatalogItem(
    id: 'pointer_default',
    name: 'Default',
    costCoins: 0,
    rarity: 'Classic',
    order: 0,
  );

  final SharedPreferences _prefs;
  List<SkinCatalogItem> _items = <SkinCatalogItem>[_defaultItem];
  final Map<String, String> _downloadUrlCache = <String, String>{};
  final Map<String, Future<String?>> _inflightDownloadUrlCache =
      <String, Future<String?>>{};

  List<SkinCatalogItem> get items {
    final sorted = List<SkinCatalogItem>.from(_items);
    sorted.sort((a, b) {
      final byY = a.posY.compareTo(b.posY);
      if (byY != 0) return byY;
      final byX = a.posX.compareTo(b.posX);
      if (byX != 0) return byX;
      return a.order.compareTo(b.order);
    });
    return sorted;
  }

  SkinCatalogItem? getById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  String get remoteSkinsUrl =>
      _normalizeHttpDirectoryUrl(
        _prefs.getString(_remoteSkinsUrlKey) ?? _defaultRemoteSkinsUrl,
      ) ??
      _defaultRemoteSkinsUrl;

  Future<void> setRemoteSkinsUrl(String url) async {
    final normalized = _normalizeHttpDirectoryUrl(url);
    if (normalized == null) return;
    await _prefs.setString(_remoteSkinsUrlKey, normalized);
  }

  Future<void> refreshFromFirebase() async {
    await _bootstrapCatalog(forceRemote: true);
  }

  Future<void> _bootstrapCatalog({bool forceRemote = false}) async {
    final hadCache = _items.any((e) => e.id != 'pointer_default');
    final preferred = await _syncFromFirestore(
      databaseId: _preferredDatabaseId,
      label: _preferredDatabaseId,
    );
    if (preferred) {
      if (kDebugMode) {
        debugPrint('[skins] Using Firestore source: $_preferredDatabaseId');
      }
      return;
    }

    final fallback = await _syncFromFirestore(
      databaseId: null,
      label: '(default)',
    );
    if (fallback) {
      if (kDebugMode) {
        debugPrint('[skins] Using Firestore source: (default)');
      }
      return;
    }

    if (hadCache && !forceRemote) {
      if (kDebugMode) {
        debugPrint(
            '[skins] Firestore unavailable, keeping valid catalog cache');
      }
      return;
    }

    await _hydrateFromAssetManifest();
    if (_items.any((e) => e.id != 'pointer_default')) {
      await _save();
      _notifyListenersSafely();
      return;
    }

    _items = <SkinCatalogItem>[_defaultItem];
    await _save();
    _notifyListenersSafely();
  }

  Future<bool> _syncFromFirestore({
    required String? databaseId,
    required String label,
  }) async {
    if (kDebugMode) {
      final prefix = databaseId == null
          ? 'Firestore fallback db'
          : 'Firestore preferred db';
      debugPrint('[skins] $prefix: $label');
    }

    try {
      final firestore = databaseId == null
          ? FirebaseFirestore.instance
          : FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: databaseId,
            );
      final snapshot = await firestore.collection(_firestoreCollection).get();
      if (kDebugMode) {
        debugPrint('[skins] Docs fetched: ${snapshot.docs.length}');
      }
      if (snapshot.docs.isEmpty) return false;

      final parsedById = <String, SkinCatalogItem>{};
      for (final doc in snapshot.docs) {
        final parsed = _parseCatalogDoc(doc);
        if (parsed == null) continue;
        parsedById[parsed.id] = parsed;
      }

      if (!parsedById.containsKey('pointer_default')) {
        parsedById['pointer_default'] = _defaultItem;
      }

      final parsed = parsedById.values
          .where((e) => e.id == 'pointer_default' || e.fullImagePath.isNotEmpty)
          .toList(growable: true)
        ..sort((a, b) => a.order.compareTo(b.order));

      final enabledSkins =
          parsed.where((e) => e.id != 'pointer_default').length;
      if (enabledSkins == 0) return false;

      if (kDebugMode) {
        final cacheById = <String, SkinCatalogItem>{
          for (final item in _items) item.id: item,
        };
        for (final item in parsed) {
          if (item.id == 'pointer_default') continue;
          final cached = cacheById[item.id];
          debugPrint(
              '[skins] Firestore item ${item.id} banner=${item.bannerImagePath}');
          if (cached != null) {
            debugPrint(
                '[skins] Cache item ${item.id} banner=${cached.bannerImagePath}');
            if (cached.bannerImagePath != item.bannerImagePath ||
                cached.cardImagePath != item.cardImagePath ||
                cached.previewImagePath != item.previewImagePath ||
                cached.fullImagePath != item.fullImagePath) {
              debugPrint(
                  '[skins] Cache refreshed from Firestore for ${item.id}');
            }
          }
        }
      }

      final changed = !_sameCatalog(_items, parsed);
      _items = parsed;
      _reindexOrders();
      if (changed) {
        await _save();
        _notifyListenersSafely();
      }

      if (kDebugMode) {
        debugPrint('[skins] Enabled skins: $enabledSkins');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[skins] Firestore read failed for $label: $e');
      }
      return false;
    }
  }

  SkinCatalogItem? _parseCatalogDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final enabled = _readBool(data['enabled'], defaultValue: true);
    if (!enabled) return null;

    final id = _canonicalSkinId(doc.id);
    final imageMapRaw = data['image'];
    final imageMap = imageMapRaw is Map
        ? Map<String, dynamic>.from(imageMapRaw)
        : const <String, dynamic>{};

    final fullPathRaw = _pick(<String?>[
      _readString(imageMap['fullPath']),
      _readString(data['imagePath']),
      _readString(data['image']),
    ]);
    if (id != 'pointer_default' && fullPathRaw.isEmpty) return null;

    final previewPathRaw = _pick(<String?>[
      _readString(imageMap['previewPath']),
      _readString(data['thumbPath']),
      _readString(data['thumbnailPath']),
      _readString(imageMap['iconPath']),
      _inferPreviewFromFullPath(fullPathRaw),
    ]);

    final bannerPathRaw = _pick(<String?>[
      _readString(imageMap['bannerPath']),
    ]);

    final cardPathRaw = _pick(<String?>[
      _readString(data['cardPath']),
    ]);

    final item = SkinCatalogItem(
      id: id,
      name: _readString(data['name']) ??
          (id == 'pointer_default' ? 'Default' : _humanName(doc.id)),
      fullImagePath:
          id == 'pointer_default' ? '' : _normalizeStoragePath(fullPathRaw),
      previewImagePath: _normalizeStoragePath(previewPathRaw),
      bannerImagePath: _normalizeStoragePath(bannerPathRaw),
      cardImagePath: _normalizeStoragePath(cardPathRaw),
      costCoins: (data['price'] as num?)?.toInt() ??
          (data['costCoins'] as num?)?.toInt() ??
          300,
      isPremium: _readBool(data['isPremium'], defaultValue: false),
      rarity: _readString(data['rarity']) ?? 'Common',
      featured: _readBool(data['featured'], defaultValue: false),
      enabled: true,
      order: (data['order'] as num?)?.toInt() ?? 0,
      posX: (data['posX'] as num?)?.toInt() ?? 0,
      posY: (data['posY'] as num?)?.toInt() ?? 0,
    );

    if (kDebugMode) {
      debugPrint(
        '[skins] Parsed ${item.id} full=${item.fullImagePath} '
        'preview=${item.previewImagePath} banner=${item.bannerImagePath} '
        'card=${item.cardImagePath}',
      );
    }
    return item;
  }

  void _loadFromPrefs() {
    final raw =
        _prefs.getString(_catalogKey) ?? _prefs.getString(_catalogLegacyKey);
    if (raw == null || raw.trim().isEmpty) {
      _items = <SkinCatalogItem>[_defaultItem];
      if (kDebugMode) {
        debugPrint('[skins] Catalog cache empty -> seeded default');
      }
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      final schemaVersion = decoded is Map<String, dynamic>
          ? (decoded['schemaVersion'] as num?)?.toInt() ?? 0
          : 0;
      final list = decoded is Map<String, dynamic>
          ? (decoded['items'] as List<dynamic>? ?? const <dynamic>[])
          : (decoded is List ? decoded : const <dynamic>[]);

      final parsed = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(SkinCatalogItem.fromJson)
          .toList();

      if (parsed.isEmpty) {
        _items = <SkinCatalogItem>[_defaultItem];
      } else {
        if (!parsed.any((e) => e.id == 'pointer_default')) {
          parsed.insert(0, _defaultItem);
        }
        _items = parsed;
      }

      if (schemaVersion != _catalogSchemaVersion && kDebugMode) {
        debugPrint('[skins] Catalog cache invalidated due to schema mismatch');
      }
      if (kDebugMode) {
        debugPrint('[skins] Catalog cache loaded items=${_items.length}');
        for (final item in _items) {
          if (item.id == 'pointer_default') continue;
          debugPrint(
              '[skins] Cache item ${item.id} banner=${item.bannerImagePath}');
        }
      }

      if (schemaVersion != _catalogSchemaVersion) {
        _save();
      }
    } catch (_) {
      _items = <SkinCatalogItem>[_defaultItem];
      if (kDebugMode) {
        debugPrint('[skins] Catalog cache invalidated due to parse error');
      }
    }
  }

  Future<void> _hydrateFromAssetManifest() async {
    try {
      final raw = await rootBundle.loadString(_assetManifestPath);
      final decoded = jsonDecode(raw);
      final list = decoded is Map<String, dynamic>
          ? (decoded['items'] as List<dynamic>? ?? const <dynamic>[])
          : (decoded is List ? decoded : const <dynamic>[]);

      final manifestItems = list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(SkinCatalogItem.fromJson)
          .toList(growable: false);

      final byId = <String, SkinCatalogItem>{
        for (final item in _items) item.id: item
      };
      for (final item in manifestItems) {
        byId.putIfAbsent(item.id, () => item);
      }
      byId.putIfAbsent('pointer_default', () => _defaultItem);

      _items = byId.values.toList(growable: true);
      _reindexOrders();
      if (kDebugMode) {
        debugPrint('[skins] Asset fallback loaded items=${_items.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[skins] Asset manifest fallback failed: $e');
      }
    }
  }

  Future<bool> _save() {
    final payload = <String, Object?>{
      'schemaVersion': _catalogSchemaVersion,
      'items': _items.map((e) => e.toJson()).toList(),
    };
    return _prefs.setString(_catalogKey, jsonEncode(payload));
  }

  void _reindexOrders() {
    _items = [
      for (var i = 0; i < _items.length; i++) _items[i].copyWith(order: i),
    ];
  }

  Future<void> updateItem(SkinCatalogItem item) async {
    final idx = _items.indexWhere((e) => e.id == item.id);
    if (idx < 0) return;
    _items[idx] = item;
    await _save();
    notifyListeners();
  }

  Future<void> removeItem(String id) async {
    if (id == 'pointer_default') return;
    _items = _items.where((e) => e.id != id).toList(growable: true);
    _reindexOrders();
    await _save();
    notifyListeners();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _items.length) return;
    if (newIndex < 0 || newIndex > _items.length) return;

    final next = List<SkinCatalogItem>.from(_items);
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex, moved);

    _items = next;
    _reindexOrders();
    await _save();
    notifyListeners();
  }

  Future<int> importFromDirectory(String dirPath) async {
    if (kIsWeb) return 0;
    final path = dirPath.trim();
    if (path.isEmpty) return 0;

    final dir = Directory(path);
    if (!await dir.exists()) return 0;

    final files = await dir
        .list(recursive: true)
        .where((e) => e is File)
        .cast<File>()
        .where((file) => _isImagePath(file.path))
        .toList();

    files.sort((a, b) => a.path.compareTo(b.path));

    var added = 0;
    final ids = _items.map((e) => e.id).toSet();
    final existingFullPaths =
        _items.map((e) => e.fullImagePath.toLowerCase()).toSet();

    for (final file in files) {
      final normalized = file.path.replaceAll('\\', '/');
      if (existingFullPaths.contains(normalized.toLowerCase())) continue;

      final fileName = file.uri.pathSegments.last;
      final id = _makeUniqueId(_slugId(fileName), ids);
      ids.add(id);

      _items.add(
        SkinCatalogItem(
          id: id,
          name: _humanName(fileName),
          fullImagePath: normalized,
          costCoins: 300,
          order: _items.length,
        ),
      );
      existingFullPaths.add(normalized.toLowerCase());
      added++;
    }

    if (added > 0) {
      await _save();
      notifyListeners();
    }
    return added;
  }

  Future<int> importSingleFile(String filePath) async {
    if (kIsWeb) return 0;
    final path = filePath.trim();
    if (path.isEmpty || !_isImagePath(path)) return 0;

    final file = File(path);
    if (!await file.exists()) return 0;

    final normalized = file.path.replaceAll('\\', '/');
    if (_items.any(
        (e) => e.fullImagePath.toLowerCase() == normalized.toLowerCase())) {
      return 0;
    }

    final fileName = file.uri.pathSegments.last;
    final ids = _items.map((e) => e.id).toSet();
    final id = _makeUniqueId(_slugId(fileName), ids);

    _items.add(
      SkinCatalogItem(
        id: id,
        name: _humanName(fileName),
        fullImagePath: normalized,
        costCoins: 300,
        order: _items.length,
      ),
    );

    await _save();
    notifyListeners();
    return 1;
  }

  Future<int> importFromWebFiles(List<PlatformFile> files) async {
    if (files.isEmpty) return 0;

    var added = 0;
    final ids = _items.map((e) => e.id).toSet();

    for (final file in files) {
      final name = file.name.trim();
      if (name.isEmpty || !_isImagePath(name)) continue;

      final bytes = await _readPlatformFileBytes(file);
      if (bytes == null || bytes.isEmpty) continue;

      final dataUri =
          'data:${_mimeTypeByName(name)};base64,${base64Encode(bytes)}';
      if (_items.any((e) => e.fullImagePath == dataUri)) continue;

      final id = _makeUniqueId(_slugId(name), ids);
      ids.add(id);

      _items.add(
        SkinCatalogItem(
          id: id,
          name: _humanName(name),
          fullImagePath: dataUri,
          costCoins: 300,
          order: _items.length,
        ),
      );
      added++;
    }

    if (added > 0) {
      await _save();
      notifyListeners();
    }
    return added;
  }

  Future<int> importFromHttpDirectory(String directoryUrl) async {
    final normalized = _normalizeHttpDirectoryUrl(directoryUrl);
    if (normalized == null) return 0;

    final baseUri = Uri.parse(normalized);
    String html;
    try {
      html = await NetworkAssetBundle(baseUri).loadString(baseUri.toString());
    } catch (_) {
      return 0;
    }

    final urls = _extractRemoteImageUrls(baseUri, html);
    if (urls.isEmpty) return 0;

    var added = 0;
    final ids = _items.map((e) => e.id).toSet();
    final existing = _items.map((e) => e.fullImagePath.toLowerCase()).toSet();

    for (final url in urls) {
      if (existing.contains(url.toLowerCase())) continue;
      final fileName = Uri.parse(url).pathSegments.last;
      final id = _makeUniqueId(_slugId(fileName), ids);
      ids.add(id);
      _items.add(
        SkinCatalogItem(
          id: id,
          name: _humanName(fileName),
          fullImagePath: url,
          costCoins: 300,
          order: _items.length,
        ),
      );
      existing.add(url.toLowerCase());
      added++;
    }

    if (added > 0) {
      await _save();
      notifyListeners();
    }
    return added;
  }

  Future<int> syncFromHttpDirectory(String directoryUrl) async {
    final normalized = _normalizeHttpDirectoryUrl(directoryUrl);
    if (normalized == null) return 0;

    final baseUri = Uri.parse(normalized);
    String html;
    try {
      html = await NetworkAssetBundle(baseUri).loadString(baseUri.toString());
    } catch (_) {
      return 0;
    }

    final urls = _extractRemoteImageUrls(baseUri, html);
    if (urls.isEmpty) return 0;

    final remoteSet = urls.map((e) => e.toLowerCase()).toSet();
    _items = _items.where((item) {
      final p = item.fullImagePath.trim().toLowerCase();
      if (p.startsWith('http://') || p.startsWith('https://')) {
        return remoteSet.contains(p);
      }
      return true;
    }).toList(growable: true);

    final added = await importFromHttpDirectory(normalized);
    await _save();
    notifyListeners();
    return added;
  }

  Future<void> resetToDefaults() async {
    await _prefs.remove(_catalogKey);
    _items = <SkinCatalogItem>[_defaultItem];
    await _save();
    _notifyListenersSafely();
    await _bootstrapCatalog(forceRemote: true);
  }

  Future<String?> resolveDownloadUrl(
    String? storagePath, {
    String context = 'generic',
  }) async {
    final raw = (storagePath ?? '').trim();
    if (raw.isEmpty) return null;
    if (_isDirectRenderablePath(raw)) return raw;

    final key = raw.startsWith('gs://') ? raw : raw.replaceAll('\\', '/');

    final cached = _downloadUrlCache[key];
    if (cached != null) {
      if (kDebugMode) {
        debugPrint('[skins] URL cache hit for $key');
      }
      return cached;
    }

    final inflight = _inflightDownloadUrlCache[key];
    if (inflight != null) {
      if (kDebugMode) {
        debugPrint('[skins] URL inflight reuse for $key');
      }
      return inflight;
    }

    if (kDebugMode) {
      debugPrint('[skins] URL cache miss for $key');
    }

    final future = _resolveDownloadUrlNoCache(key, context: context);
    _inflightDownloadUrlCache[key] = future;
    try {
      final resolved = await future;
      if (resolved != null && resolved.trim().isNotEmpty) {
        _downloadUrlCache[key] = resolved;
      }
      return resolved;
    } finally {
      _inflightDownloadUrlCache.remove(key);
    }
  }

  Future<void> warmupPreviewUrls({int count = 8}) async {
    if (count <= 0) return;
    var resolved = 0;
    for (final item in items) {
      if (item.id == 'pointer_default') continue;
      final path = item.previewImagePath.trim().isNotEmpty
          ? item.previewImagePath
          : item.fullImagePath;
      if (path.trim().isEmpty) continue;
      await resolveDownloadUrl(path, context: 'warmup-preview:${item.id}');
      resolved++;
      if (resolved >= count) break;
    }
  }

  Future<void> resolveDetailUrlsForSkin(String skinId) async {
    final item = getById(skinId);
    if (item == null) return;

    if (item.fullImagePath.trim().isNotEmpty) {
      if (kDebugMode) {
        debugPrint('[skins] Resolving full URL for ${item.id}');
      }
      await resolveDownloadUrl(item.fullImagePath,
          context: 'detail-full:${item.id}');
    }
    if (item.bannerImagePath.trim().isNotEmpty) {
      if (kDebugMode) {
        debugPrint('[skins] Resolving banner URL for ${item.id}');
      }
      await resolveDownloadUrl(item.bannerImagePath,
          context: 'detail-banner:${item.id}');
    }
  }

  String toRenderablePath(String rawPath) {
    final raw = rawPath.trim();
    if (raw.isEmpty || _isDirectRenderablePath(raw)) return raw;

    final key = raw.startsWith('gs://') ? raw : raw.replaceAll('\\', '/');
    final cached = _downloadUrlCache[key];
    if (cached != null) return cached;

    final derived = key.startsWith('gs://')
        ? _publicStorageMediaUrlFromGs(key)
        : _publicStorageMediaUrlFromObjectPath(key);
    return derived ?? raw;
  }

  Future<String?> _resolveDownloadUrlNoCache(
    String path, {
    required String context,
  }) async {
    if (path.startsWith('gs://')) {
      try {
        return await FirebaseStorage.instance.refFromURL(path).getDownloadURL();
      } catch (e) {
        final publicUrl = _publicStorageMediaUrlFromGs(path);
        if (publicUrl != null) return publicUrl;
        if (kDebugMode) {
          debugPrint('[skins] Failed to resolve $context for $path: $e');
        }
        return null;
      }
    }

    final normalized = path.replaceAll('\\', '/');
    try {
      return await FirebaseStorage.instance.ref(normalized).getDownloadURL();
    } catch (e) {
      final publicUrl = _publicStorageMediaUrlFromObjectPath(normalized);
      if (publicUrl != null) return publicUrl;
      if (kDebugMode) {
        debugPrint('[skins] Failed to resolve $context for $normalized: $e');
      }
      return null;
    }
  }

  String _normalizeStoragePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceAll('\\', '/');
  }

  static bool _isDirectRenderablePath(String path) {
    return path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('assets/') ||
        path.startsWith('data:image');
  }

  String? _publicStorageMediaUrlFromGs(String gsUrl) {
    final withoutPrefix = gsUrl.replaceFirst('gs://', '');
    final slash = withoutPrefix.indexOf('/');
    if (slash <= 0 || slash >= withoutPrefix.length - 1) return null;

    final bucket = withoutPrefix.substring(0, slash);
    final objectPath = withoutPrefix.substring(slash + 1);
    if (!_isStorageObjectPath(objectPath)) return null;

    final encoded = Uri.encodeComponent(objectPath);
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encoded?alt=media';
  }

  String? _publicStorageMediaUrlFromObjectPath(String objectPath) {
    if (!_isStorageObjectPath(objectPath)) return null;

    String bucket = '';
    try {
      bucket = Firebase.app().options.storageBucket ?? '';
    } catch (_) {
      return null;
    }
    if (bucket.trim().isEmpty) return null;

    final encoded = Uri.encodeComponent(objectPath);
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encoded?alt=media';
  }

  static bool _isStorageObjectPath(String path) {
    final normalized = path.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('/')) return false;
    return normalized.endsWith('.png') ||
        normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.webp');
  }

  static bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  static String _mimeTypeByName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/png';
  }

  static bool _readBool(Object? value, {required bool defaultValue}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return defaultValue;
  }

  static String? _readString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _pick(List<String?> values) {
    for (final value in values) {
      final v = value?.trim() ?? '';
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static String _canonicalSkinId(String rawId) {
    final normalized = rawId.trim().toLowerCase();
    if (normalized == 'default' ||
        normalized == 'pointer-default' ||
        normalized == 'pointer_default') {
      return 'pointer_default';
    }
    return rawId.trim();
  }

  static String _inferPreviewFromFullPath(String fullPathRaw) {
    final raw = fullPathRaw.trim();
    if (raw.isEmpty) return '';

    final normalized = raw.replaceAll('\\', '/');
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized.replaceFirstMapped(
        RegExp(r'(\.[^./?]+)(\?.*)?$'),
        (m) => '-thumb${m.group(1)}${m.group(2) ?? ''}',
      );
    }

    if (normalized.startsWith('gs://')) {
      final slash = normalized.indexOf('/', 'gs://'.length);
      if (slash <= 0 || slash >= normalized.length - 1) return '';
      final bucketPrefix = normalized.substring(0, slash + 1);
      final objectPath = normalized.substring(slash + 1);
      final dot = objectPath.lastIndexOf('.');
      if (dot <= 0) return '$bucketPrefix$objectPath-thumb';
      final thumbObject =
          '${objectPath.substring(0, dot)}-thumb${objectPath.substring(dot)}';
      return '$bucketPrefix$thumbObject';
    }

    final dot = normalized.lastIndexOf('.');
    if (dot <= 0) return normalized;
    return '${normalized.substring(0, dot)}-thumb${normalized.substring(dot)}';
  }

  static String _slugId(String input) {
    final withoutExt = input.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final normalized = withoutExt
        .trim()
        .toLowerCase()
        .replaceAll('_', '-')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]+'), '-')
        .replaceAll(RegExp(r'\-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return normalized.isEmpty ? 'skin' : normalized;
  }

  static String _makeUniqueId(String base, Set<String> existingIds) {
    if (!existingIds.contains(base)) return base;
    var i = 2;
    while (existingIds.contains('$base-$i')) {
      i++;
    }
    return '$base-$i';
  }

  static String _humanName(String input) {
    final withoutExt = input.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final normalized = withoutExt.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (normalized.isEmpty) return 'Skin';
    return normalized
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String? _normalizeHttpDirectoryUrl(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    try {
      final uri = Uri.parse(value);
      if (!(uri.scheme == 'http' || uri.scheme == 'https')) return null;
      return value.endsWith('/') ? value : '$value/';
    } catch (_) {
      return null;
    }
  }

  static List<String> _extractRemoteImageUrls(Uri baseUri, String html) {
    final matches = RegExp(
      r'''href\s*=\s*["']([^"']+\.(?:png|jpg|jpeg|webp))["']''',
      caseSensitive: false,
    ).allMatches(html);

    final result = <String>[];
    for (final match in matches) {
      final href = match.group(1);
      if (href == null || href.trim().isEmpty) continue;
      result.add(baseUri.resolve(href).toString());
    }
    return result;
  }

  static bool _sameCatalog(List<SkinCatalogItem> a, List<SkinCatalogItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x.id != y.id ||
          x.name != y.name ||
          x.fullImagePath != y.fullImagePath ||
          x.previewImagePath != y.previewImagePath ||
          x.bannerImagePath != y.bannerImagePath ||
          x.cardImagePath != y.cardImagePath ||
          x.costCoins != y.costCoins ||
          x.isPremium != y.isPremium ||
          x.rarity != y.rarity ||
          x.featured != y.featured ||
          x.enabled != y.enabled ||
          x.order != y.order ||
          x.posX != y.posX ||
          x.posY != y.posY) {
        return false;
      }
    }
    return true;
  }

  static Future<Uint8List?> _readPlatformFileBytes(PlatformFile file) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return file.bytes!;
    }

    final stream = file.readStream;
    if (stream == null) return null;

    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    final data = builder.takeBytes();
    return data.isEmpty ? null : data;
  }

  void _notifyListenersSafely() {
    final binding = SchedulerBinding.instance;
    final phase = binding.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks) {
      binding.addPostFrameCallback((_) => notifyListeners());
      return;
    }
    notifyListeners();
  }
}
