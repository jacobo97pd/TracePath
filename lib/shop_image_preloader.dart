import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ShopImagePreloader {
  ShopImagePreloader();

  final BaseCacheManager _cacheManager = DefaultCacheManager();
  final Set<String> _preloadedUrls = <String>{};
  final Map<String, Future<void>> _inflightPreloads = <String, Future<void>>{};

  Future<void> preloadResolvedUrl(
    String url, {
    required String skinId,
    required String kind,
    BuildContext? context,
  }) async {
    final clean = url.trim();
    if (clean.isEmpty) return;

    if (_preloadedUrls.contains(clean)) {
      if (kDebugMode) {
        debugPrint('[shop-preload] Preload hit cache: $skinId [$kind] -> $clean');
      }
      return;
    }

    final inflight = _inflightPreloads[clean];
    if (inflight != null) {
      if (kDebugMode) {
        debugPrint('[shop-preload] Preload skipped (already inflight): $clean');
      }
      return inflight;
    }

    if (kDebugMode) {
      debugPrint('[shop-preload] ${_kindLabel(kind)} preload start: $skinId -> $clean');
    }

    final future = _doPreload(clean, context: context).then((_) {
      _preloadedUrls.add(clean);
      if (kDebugMode) {
        debugPrint('[shop-preload] Preload completed: $clean');
      }
    }).catchError((e) {
      if (kDebugMode) {
        debugPrint('[shop-preload] Preload failed: $clean error=$e');
      }
    }).whenComplete(() {
      _inflightPreloads.remove(clean);
    });

    _inflightPreloads[clean] = future;
    return future;
  }

  Future<void> preloadFromRawPath({
    required String skinId,
    required String rawPath,
    required String kind,
    required BuildContext context,
    required Future<String?> Function(
      String rawPath, {
      required String context,
    }) resolver,
    required String resolveContext,
  }) async {
    final raw = rawPath.trim();
    if (raw.isEmpty) return;
    final resolved = await resolver(raw, context: resolveContext);
    final url = (resolved ?? '').trim();
    if (url.isEmpty) return;
    return preloadResolvedUrl(
      url,
      skinId: skinId,
      kind: kind,
      context: context,
    );
  }

  Future<void> _doPreload(
    String path, {
    BuildContext? context,
  }) async {
    final lower = path.toLowerCase();
    final isHttp = lower.startsWith('http://') || lower.startsWith('https://');
    final isAsset = path.startsWith('assets/');
    final isDataUri = lower.startsWith('data:image');

    if (isHttp) {
      try {
        final cached = await _cacheManager.getFileFromCache(path);
        if (cached != null) {
          if (kDebugMode) {
            debugPrint('[shop-preload] Disk cache hit: $path');
          }
        } else {
          await _cacheManager.getSingleFile(path);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[shop-preload] Disk cache miss/fail: $path error=$e');
        }
      }
    }

    if (context == null) return;

    try {
      ImageProvider provider;
      if (isAsset) {
        provider = AssetImage(path);
      } else if (isHttp) {
        provider = NetworkImage(path);
      } else if (isDataUri) {
        return;
      } else if (!kIsWeb) {
        provider = FileImage(File(path));
      } else {
        return;
      }
      await precacheImage(provider, context);
    } catch (_) {
      // Non-fatal: precache best-effort only.
    }
  }

  String _kindLabel(String kind) {
    switch (kind) {
      case 'preview':
        return 'Preview';
      case 'full':
        return 'Full';
      case 'banner':
        return 'Banner';
      case 'card':
        return 'Card';
      default:
        return 'Image';
    }
  }
}
