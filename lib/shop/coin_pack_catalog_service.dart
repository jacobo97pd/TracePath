import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'coin_pack.dart';

class CoinPackCatalogResult {
  const CoinPackCatalogResult({
    required this.packs,
    required this.usingFallback,
    this.fallbackReason = '',
  });

  final List<CoinPack> packs;
  final bool usingFallback;
  final String fallbackReason;
}

class CoinPackCatalogService {
  static const String _collection = 'shop_coin_packs';
  static const String _expectedProjectId = 'tracepath-e2e90';
  static const String _firestoreDatabaseId = 'tracepath-database';

  CoinPackCatalogResult localFallbackResult({String reason = 'local_bootstrap'}) {
    return CoinPackCatalogResult(
      packs: _fallbackCatalog(),
      usingFallback: true,
      fallbackReason: reason,
    );
  }

  Future<CoinPackCatalogResult> fetchPacks({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    _logFirebaseConfig();
    try {
      final snap = await _db()
          .collection(_collection)
          .get()
          .timeout(timeout);
      if (kDebugMode) {
        debugPrint('[coin-packs] collection=$_collection docs=${snap.docs.length}');
      }

      final packs = <CoinPack>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        if (kDebugMode) {
          debugPrint('[coin-packs] doc id=${doc.id}');
          debugPrint('[coin-packs] doc raw=$data');
        }
        final parsed = CoinPack.fromDoc(
          docId: doc.id,
          data: Map<String, dynamic>.from(data),
        );
        if (!parsed.active) continue;
        packs.add(parsed);
      }

      packs.sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return a.title.compareTo(b.title);
      });

      if (packs.isNotEmpty) {
        return CoinPackCatalogResult(
          packs: List<CoinPack>.unmodifiable(packs),
          usingFallback: false,
        );
      }

      if (kDebugMode) {
        debugPrint('[coin-packs] no active docs -> using local fallback catalog');
      }
      return CoinPackCatalogResult(
        packs: _fallbackCatalog(),
        usingFallback: true,
        fallbackReason: 'empty_remote_catalog',
      );
    } on TimeoutException catch (_) {
      if (kDebugMode) {
        debugPrint('[coin-packs] remote fetch timeout -> fallback');
      }
      return CoinPackCatalogResult(
        packs: _fallbackCatalog(),
        usingFallback: true,
        fallbackReason: 'remote_timeout',
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[coin-packs] remote fetch error: $e');
        debugPrint('$st');
      }
      return CoinPackCatalogResult(
        packs: _fallbackCatalog(),
        usingFallback: true,
        fallbackReason: 'remote_fetch_error: $e',
      );
    }
  }

  void _logFirebaseConfig() {
    try {
      final app = Firebase.app();
      final options = app.options;
      if (kDebugMode) {
        debugPrint('[coin-packs] firebase app=${app.name}');
        debugPrint(
          '[coin-packs] firebase projectId=${options.projectId} '
          'storageBucket=${options.storageBucket} db=${_activeFirestoreName()}',
        );
      }
      if (options.projectId.trim() != _expectedProjectId && kDebugMode) {
        debugPrint(
          '[coin-packs] WARNING expected projectId=$_expectedProjectId current=${options.projectId}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[coin-packs] firebase options read failed: $e');
      }
    }
  }

  FirebaseFirestore _db() {
    try {
      return FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: _firestoreDatabaseId,
      );
    } catch (_) {
      return FirebaseFirestore.instance;
    }
  }

  String _activeFirestoreName() {
    try {
      return _db().databaseId;
    } catch (_) {
      return '(unknown)';
    }
  }

  List<CoinPack> _fallbackCatalog() {
    return const <CoinPack>[
      CoinPack(
        id: 'coins_500',
        title: 'Starter Pack',
        description: 'A small boost to start collecting skins and trails.',
        coins: 500,
        bonusCoins: 0,
        totalCoins: 500,
        priceLabel: '\u20ac0.99',
        productIdAndroid: 'coins_500',
        productIdIos: 'coins_500',
        imagePath: 'assets/shop/coin_packs/saco_pequeno.webp',
        sortOrder: 1,
        tag: '',
        active: true,
        isFallback: true,
      ),
      CoinPack(
        id: 'coins_1200',
        title: 'Small Coin Sack',
        description: 'A solid stash of coins to unlock new styles.',
        coins: 1200,
        bonusCoins: 100,
        totalCoins: 1300,
        priceLabel: '\u20ac2.99',
        productIdAndroid: 'coins_1200',
        productIdIos: 'coins_1200',
        imagePath: 'assets/shop/coin_packs/saco_mediano.webp',
        sortOrder: 2,
        tag: 'Popular',
        active: true,
        isFallback: true,
      ),
      CoinPack(
        id: 'coins_2500',
        title: 'Large Coin Sack',
        description: 'Perfect for grabbing multiple skins or trails.',
        coins: 2500,
        bonusCoins: 300,
        totalCoins: 2800,
        priceLabel: '\u20ac4.99',
        productIdAndroid: 'coins_2500',
        productIdIos: 'coins_2500',
        imagePath: 'assets/shop/coin_packs/saco_grande.webp',
        sortOrder: 3,
        tag: '',
        active: true,
        isFallback: true,
      ),
      CoinPack(
        id: 'coins_6500',
        title: 'Treasure Chest',
        description: 'A massive chest packed with shiny coins.',
        coins: 6500,
        bonusCoins: 1000,
        totalCoins: 7500,
        priceLabel: '\u20ac9.99',
        productIdAndroid: 'coins_6500',
        productIdIos: 'coins_6500',
        imagePath: 'assets/shop/coin_packs/cofre_grande.webp',
        sortOrder: 4,
        tag: 'Best Value',
        active: true,
        isFallback: true,
      ),
      CoinPack(
        id: 'coins_14000',
        title: 'Epic Treasure Chest',
        description: 'Overflowing with coins for serious collectors.',
        coins: 14000,
        bonusCoins: 3000,
        totalCoins: 17000,
        priceLabel: '\u20ac19.99',
        productIdAndroid: 'coins_14000',
        productIdIos: 'coins_14000',
        imagePath: 'assets/shop/coin_packs/cofre_epico.webp',
        sortOrder: 5,
        tag: '',
        active: true,
        isFallback: true,
      ),
      CoinPack(
        id: 'coins_30000',
        title: 'Legendary Coin Hoard',
        description: 'An enormous mountain of coins for true masters.',
        coins: 30000,
        bonusCoins: 8000,
        totalCoins: 38000,
        priceLabel: '\u20ac39.99',
        productIdAndroid: 'coins_30000',
        productIdIos: 'coins_30000',
        imagePath: 'assets/shop/coin_packs/lote_super_epico.webp',
        sortOrder: 6,
        tag: 'Ultimate',
        active: true,
        isFallback: true,
      ),
    ];
  }
}
