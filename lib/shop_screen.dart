import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'coins_service.dart';
import 'skin_catalog_service.dart';
import 'shop/coin_pack.dart';
import 'shop/coin_pack_catalog_service.dart';
import 'shop_image_preloader.dart';
import 'services/iap_service.dart';
import 'services/user_inventory_service.dart';
import 'services/energy_service.dart';
import 'trail/trail_catalog.dart';
import 'trail/trail_skin.dart';
import 'l10n/l10n.dart';
import 'ui/components/coin_pack_card.dart';
import 'ui/components/coin_display.dart';
import 'ui/components/network_image_compat.dart';
import 'ui/components/section_header.dart';
import 'ui/components/skin_card.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.coinsService,
    required this.skinCatalogService,
    required this.energyService,
  });

  final CoinsService coinsService;
  final SkinCatalogService skinCatalogService;
  final EnergyService energyService;

  static const List<CoinTrailDef> _coinTrails = <CoinTrailDef>[
    CoinTrailDef(id: 'trail_classic', name: 'Classic', costCoins: 0),
    CoinTrailDef(id: 'trail_smoke', name: 'SmokeTrail', costCoins: 280),
    CoinTrailDef(id: 'trail_fire', name: 'Fire', costCoins: 350),
    CoinTrailDef(id: 'trail_laser', name: 'Laser', costCoins: 500),
    CoinTrailDef(id: 'trail_plasma', name: 'PlasmaTrail', costCoins: 620),
    CoinTrailDef(id: 'trail_glitch', name: 'GlitchTrail', costCoins: 760),
    CoinTrailDef(id: 'trail_ink', name: 'InkTrail', costCoins: 840),
    CoinTrailDef(id: 'trail_magma', name: 'MagmaTrail', costCoins: 980),
    CoinTrailDef(id: 'trail_ice', name: 'IceTrail', costCoins: 1020),
    CoinTrailDef(id: 'trail_galaxy', name: 'GalaxyTrail', costCoins: 1280),
    CoinTrailDef(
      id: 'trail_galaxy_reveal',
      name: 'GalaxyRevealTrail',
      costCoins: 1660,
    ),
    CoinTrailDef(
      id: 'comic_trail_reveal',
      name: 'ComicTrailReveal',
      costCoins: 1720,
    ),
    CoinTrailDef(
      id: 'electric_trail_reveal',
      name: 'ElectricTrailReveal',
      costCoins: 1760,
    ),
    CoinTrailDef(
      id: 'golden_trail_reveal',
      name: 'GoldenTrailReveal',
      costCoins: 1820,
    ),
    CoinTrailDef(
      id: 'graffiti_trail_reveal',
      name: 'GraffitiTrailReveal',
      costCoins: 1780,
    ),
    CoinTrailDef(
        id: 'trail_speed_force', name: 'SpeedForceTrail', costCoins: 1450),
    CoinTrailDef(id: 'trail_sith', name: 'Sith', costCoins: 650),
    CoinTrailDef(
      id: 'trail_comic_spiderverse_v2',
      name: 'ComicSpiderverseTrailV2',
      costCoins: 1680,
    ),
    CoinTrailDef(
      id: 'trail_comic_spiderverse_rebuilt',
      name: 'ComicSpiderverseLegend',
      costCoins: 1980,
    ),
    CoinTrailDef(id: 'trail_punk_riff', name: 'PunkRiffTrail', costCoins: 1250),
    CoinTrailDef(
      id: 'trail_punk_riff_verdant',
      name: 'PunkRiff Verdant',
      costCoins: 1320,
    ),
    CoinTrailDef(
      id: 'trail_punk_riff_ember',
      name: 'PunkRiff Ember',
      costCoins: 1320,
    ),
    CoinTrailDef(
      id: 'trail_punk_riff_prism',
      name: 'PunkRiff Prism',
      costCoins: 1390,
    ),
    CoinTrailDef(id: 'trail_graffiti', name: 'GraffitiTrail', costCoins: 1320),
    CoinTrailDef(
      id: 'trail_urban_graffiti',
      name: 'UrbanGraffitiTrail',
      costCoins: 1480,
    ),
    CoinTrailDef(
      id: 'trail_halftone_explosion',
      name: 'HalftoneExplosionTrail',
      costCoins: 1380,
    ),
    CoinTrailDef(
      id: 'trail_sticker_bomb',
      name: 'StickerBombTrail',
      costCoins: 1440,
    ),
    CoinTrailDef(
      id: 'trail_glitch_print',
      name: 'GlitchPrintTrail',
      costCoins: 1490,
    ),
    CoinTrailDef(id: 'trail_ink_brush', name: 'InkBrushTrail', costCoins: 1000),
    CoinTrailDef(
      id: 'trail_ink_brush_crimson',
      name: 'InkBrush Crimson',
      costCoins: 1050,
    ),
    CoinTrailDef(
        id: 'trail_electric_arc', name: 'ElectricArcTrail', costCoins: 1100),
    CoinTrailDef(
        id: 'trail_golden_thread', name: 'GoldenThreadTrail', costCoins: 1200),
    CoinTrailDef(
        id: 'trail_golden_aura', name: 'GoldenAuraTrail', costCoins: 1350),
    CoinTrailDef(
        id: 'trail_holiday_spark', name: 'HolidaySparkTrail', costCoins: 1420),
    CoinTrailDef(id: 'trail_upside', name: 'UpsideTrail', costCoins: 1500),
    CoinTrailDef(
        id: 'trail_binary_rain', name: 'BinaryRainTrail', costCoins: 1580),
    CoinTrailDef(
      id: 'trail_symbiote_ink',
      name: 'SymbioteInkTrail',
      costCoins: 1980,
    ),
    CoinTrailDef(
      id: 'trail_void_rift',
      name: 'VoidRiftTrail',
      costCoins: 2250,
    ),
    // Re-added explicitly to ensure they behave exactly like the rest in shop.
    CoinTrailDef(id: 'trail_web', name: 'Web Trail', costCoins: 950),
    CoinTrailDef(
      id: 'trail_web_legendary',
      name: 'Web Trail Legendary',
      costCoins: 1850,
    ),
  ];

  static const Map<String, String> _trailDescriptions = <String, String>{
    'trail_classic': 'Balanced default trail for clean runs.',
    'trail_smoke': 'Soft drifting smoke with subtle motion.',
    'trail_fire': 'Hot ember line with flame accents.',
    'trail_laser': 'Sharp focused beam with crisp glow.',
    'trail_plasma': 'Charged plasma ribbon with inner flow.',
    'trail_glitch': 'Digital distortion with RGB glitching.',
    'trail_ink': 'Liquid ink stroke with organic edge.',
    'trail_magma': 'Molten core with volcanic crust vibes.',
    'trail_ice': 'Cold crystalline trace with frosty sparkles.',
    'trail_galaxy': 'Nebula stream with cosmic highlights.',
    'trail_galaxy_reveal':
        'Reveal a static galaxy texture under your path as you move.',
    'comic_trail_reveal':
        'Reveal a static comic background texture under your path as you move.',
    'electric_trail_reveal':
        'Reveal a static electric storm texture under your path as you move.',
    'golden_trail_reveal':
        'Reveal a static molten gold texture under your path as you move.',
    'graffiti_trail_reveal':
        'Reveal a static neon graffiti texture under your path as you move.',
    'trail_speed_force': 'High-energy streak with speed bursts.',
    'trail_sith': 'Dark red saber-style trail.',
    'trail_comic_spiderverse_v2':
        'Comic multiverse style with chromatic punch.',
    'trail_comic_spiderverse_rebuilt':
        'Premium comic variant tuned for bold readability.',
    'trail_punk_riff': 'Neon punk wave with high attitude.',
    'trail_punk_riff_verdant':
        'Punk riff variant in acid green and lime tones.',
    'trail_punk_riff_ember': 'Punk riff variant with hot red-orange energy.',
    'trail_punk_riff_prism':
        'Punk riff multicolor mix with high contrast accents.',
    'trail_graffiti': 'Street-art line with spray accents.',
    'trail_urban_graffiti': 'Heavy spray-paint feel with layered stamps.',
    'trail_halftone_explosion': 'Pop-art halftone impacts on movement.',
    'trail_sticker_bomb': 'Sticker collage aesthetic with playful chaos.',
    'trail_glitch_print': 'Printed glitch texture with RGB offsets.',
    'trail_web': 'Silk-thread web trail with subtle depth.',
    'trail_web_legendary': 'Legendary web with premium VFX layers.',
    'trail_ink_brush': 'Expressive brush stroke with painterly flow.',
    'trail_ink_brush_crimson': 'Crimson ink brush for dramatic runs.',
    'trail_electric_arc': 'Electric arc chain with energetic crackle.',
    'trail_golden_thread': 'Refined gold filament with premium shimmer.',
    'trail_golden_aura': 'Golden aura trail with regal glow.',
    'trail_holiday_spark': 'Festive sparkle line with seasonal tones.',
    'trail_upside': 'Dark upside-style trace with eerie pulse.',
    'trail_binary_rain': 'Data stream look with digital cadence.',
    'trail_symbiote_ink':
        'Living alien ink with organic pulses and predatory flow.',
    'trail_void_rift':
        'Legendary space-time rift with collapsing void edges and absorption.',
  };

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const Map<String, ({String name, int coins, String description})>
      _trailShopOverrides = {
    'trail_web': (
      name: 'Web Trail',
      coins: 950,
      description: 'Silk-thread web trail with subtle depth.',
    ),
    'trail_web_legendary': (
      name: 'Web Trail Legendary',
      coins: 1850,
      description: 'Legendary web with premium VFX layers.',
    ),
  };

  static const Map<String, String> _coinPackAssetById = <String, String>{
    'coins_500': 'assets/shop/coin_packs/saco_pequeno.webp',
    'coins_1200': 'assets/shop/coin_packs/saco_mediano.webp',
    'coins_2500': 'assets/shop/coin_packs/saco_grande.webp',
    'coins_6500': 'assets/shop/coin_packs/cofre_grande.webp',
    'coins_14000': 'assets/shop/coin_packs/cofre_epico.webp',
    'coins_30000': 'assets/shop/coin_packs/lote_super_epico.webp',
  };
  static const List<String> _coinPackAssetOrderFallback = <String>[
    'assets/shop/coin_packs/saco_pequeno.webp',
    'assets/shop/coin_packs/saco_mediano.webp',
    'assets/shop/coin_packs/saco_grande.webp',
    'assets/shop/coin_packs/cofre_grande.webp',
    'assets/shop/coin_packs/cofre_epico.webp',
    'assets/shop/coin_packs/lote_super_epico.webp',
  ];
  static const int _skinBatchSize = 8;
  int _visibleSkinCount = _skinBatchSize;
  bool _loadingMoreSkins = false;
  final Set<String> _precacheRangeKeys = <String>{};
  bool _shopReady = false;
  bool _shopPreparing = false;
  int _shopPrepDone = 0;
  int _shopPrepTotal = 0;
  bool _didShowCoinPackLoadError = false;
  bool _didShowCoinPackEmptyInfo = false;
  final Set<String> _shopPrepPaths = <String>{};
  final Map<String, String> _uiResolvedUrlCache = <String, String>{};
  final Map<String, Future<String?>> _uiInflightResolveCache =
      <String, Future<String?>>{};
  final Set<String> _gridPreviewLogIds = <String>{};
  final ShopImagePreloader _imagePreloader = ShopImagePreloader();
  final UserInventoryService _inventoryService = UserInventoryService();
  final CoinPackCatalogService _coinPackCatalogService =
      CoinPackCatalogService();
  late final IapService _iapService =
      IapService(coinsService: widget.coinsService);
  late Future<CoinPackCatalogResult> _coinPacksFuture;
  late Future<UserInventoryState> _inventoryStateFuture;
  String _lastIapSummaryFingerprint = '';

  @override
  void initState() {
    super.initState();
    widget.energyService.addListener(_onEnergyChanged);
    unawaited(widget.energyService.refresh());
    _coinPacksFuture = Future<CoinPackCatalogResult>.value(
      _coinPackCatalogService.localFallbackResult(
        reason: 'boot_fast_fallback',
      ),
    );
    final fallbackPacks = _coinPackCatalogService
        .localFallbackResult(reason: 'boot_fast_fallback')
        .packs;
    unawaited(_iapService.refreshCatalog(fallbackPacks));
    _inventoryStateFuture = _inventoryService.getInventoryState();
    unawaited(_refreshCoinPacksInBackground());
    unawaited(_refreshInventoryInBackground());
  }

  @override
  void dispose() {
    widget.energyService.removeListener(_onEnergyChanged);
    _iapService.dispose();
    super.dispose();
  }

  void _onEnergyChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _refreshCoinPacksInBackground() async {
    final result = await _coinPackCatalogService.fetchPacks(
      timeout: const Duration(seconds: 3),
    );
    await _iapService.refreshCatalog(result.packs);
    _logIapSummaryIfNeeded(result.packs, reason: 'refresh_background');
    if (!mounted) return;
    setState(() {
      _coinPacksFuture = Future<CoinPackCatalogResult>.value(result);
    });
  }

  Future<void> _refreshInventoryInBackground() async {
    final result = await _inventoryService.getInventoryState();
    if (!mounted) return;
    setState(() {
      _inventoryStateFuture = Future<UserInventoryState>.value(result);
    });
    await widget.coinsService.syncCoinsFromRemote(result.coins);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.coinsService,
        widget.skinCatalogService,
        _iapService,
        widget.energyService,
      ]),
      builder: (context, _) {
        final skins = widget.skinCatalogService.items.where((item) {
          final id = item.id.trim().toLowerCase();
          return id != 'pointer_default' &&
              id != 'pointer-default' &&
              id != 'default';
        }).map((item) {
          final previewRaw = _gridPreviewRawPath(item);
          final previewResolved = _resolveForRender(previewRaw);
          final fullResolved = _resolveForRender(item.fullImagePath);
          if (kDebugMode && _gridPreviewLogIds.add(item.id)) {
            debugPrint('[shop] Grid preview for ${item.id} -> $previewRaw');
          }
          return CoinSkinDef(
            id: item.id,
            name: item.name,
            assetPath: fullResolved,
            previewPath:
                (previewResolved == null || previewResolved.trim().isEmpty)
                    ? fullResolved
                    : previewResolved,
            bannerPath: _resolveForRender(item.bannerImagePath),
            cardPath: _resolveForRender(item.cardImagePath),
            costCoins: item.costCoins,
            rarity: item.rarity,
            featured: item.featured,
            order: item.order,
          );
        }).toList(growable: false);
        final sortedSkins = _sortSkinsForShop(skins);
        final visibleCount = min(_visibleSkinCount, sortedSkins.length);
        _queueInitialShopPrepare(context, sortedSkins);
        _queuePrecacheNextBatch(sortedSkins, visibleCount);
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F172A),
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/branding/shop_tracepath.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(context.l10n.shopTitle),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: StreamBuilder<int>(
                    stream: widget.coinsService.watchCoins(),
                    initialData: widget.coinsService.coins,
                    builder: (context, snapshot) {
                      final coins = snapshot.data ?? widget.coinsService.coins;
                      return Center(
                        child: CoinDisplay(coins: coins),
                      );
                    },
                  ),
                ),
              ],
              bottom: TabBar(
                indicatorColor: Color(0xFF60A5FA),
                indicatorWeight: 3,
                labelColor: Color(0xFFFFFFFF),
                unselectedLabelColor: Color(0xFF9FB0D3),
                tabs: [
                  Tab(text: context.l10n.shopTabSkins),
                  Tab(text: context.l10n.shopTabTrails),
                  Tab(text: context.l10n.shopTabCoinPacks),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildSkinsTab(context, sortedSkins, visibleCount),
                _buildTrailsTab(context),
                _buildCoinPacksTab(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkinsTab(
    BuildContext context,
    List<CoinSkinDef> skins,
    int visibleCount,
  ) {
    return FutureBuilder<UserInventoryState>(
      future: _inventoryStateFuture,
      builder: (context, snapshot) {
        final inventory = snapshot.data;
        final ownedIds = <String>{
          ...widget.coinsService.ownedSkins,
          if (inventory != null) ...inventory.ownedSkinIds.map(_toLocalSkinId),
        };
        final equippedFromRemote =
            inventory == null ? '' : _toLocalSkinId(inventory.equippedSkinId);
        final equippedId = equippedFromRemote.isEmpty
            ? widget.coinsService.selectedSkin
            : equippedFromRemote;
        final coinBalance = max(
          widget.coinsService.coins,
          inventory?.coins ?? 0,
        );

        final visibleSkins = skins.take(visibleCount).toList(growable: false);
        CoinSkinDef? featuredSkin;
        for (final skin in skins) {
          if (skin.featured) {
            featuredSkin = skin;
            break;
          }
        }
        final hasMore = visibleCount < skins.length;
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (!hasMore) return false;
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 220) {
              _loadMoreSkins(skins);
            }
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  context.l10n.shopSkinsLoaded(visibleCount, skins.length),
                  style: const TextStyle(
                    color: Color(0xFF9FB0D3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (featuredSkin != null) ...[
                SectionHeader(title: context.l10n.shopFeaturedSkin),
                const SizedBox(height: 10),
                _buildFeaturedSkinCard(
                  context: context,
                  skin: featuredSkin,
                  ownedIds: ownedIds,
                  equippedId: equippedId,
                  coinBalance: coinBalance,
                ),
                const SizedBox(height: 14),
              ],
              SectionHeader(title: context.l10n.shopPointerSkins),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemCount: visibleSkins.length,
                itemBuilder: (context, idx) {
                  final skin = visibleSkins[idx];
                  final owned = ownedIds.contains(skin.id);
                  final selected = equippedId == skin.id;
                  final cost = skin.costCoins ?? 0;
                  final canBuy = !owned && coinBalance >= cost;
                  return SkinCard(
                    skin: skin,
                    owned: owned,
                    equipped: selected,
                    canBuy: canBuy,
                    featured: skin.featured,
                    onPreviewTap: _fullRawPathForSkinId(skin.id).isEmpty
                        ? null
                        : () => _showSkinPreview(context, skin),
                    onActionTap: () => _onSkinAction(
                      skin: skin,
                      owned: owned,
                      cost: cost,
                    ),
                  );
                },
              ),
              if (hasMore || _loadingMoreSkins) ...[
                const SizedBox(height: 14),
                Center(
                  child: _loadingMoreSkins
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : OutlinedButton(
                          onPressed: () => _loadMoreSkins(skins),
                          child: Text(context.l10n.shopLoadMore),
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturedSkinCard({
    required BuildContext context,
    required CoinSkinDef skin,
    required Set<String> ownedIds,
    required String equippedId,
    required int coinBalance,
  }) {
    final owned = ownedIds.contains(skin.id);
    final selected = equippedId == skin.id;
    final cost = skin.costCoins ?? 0;
    final canBuy = !owned && coinBalance >= cost;
    final rarityColor = _rarityColor(skin.rarity);
    final rarityLabel = _displayRarity(skin.rarity);
    final actionLabel = selected
        ? context.l10n.shopEquipped
        : owned
            ? context.l10n.shopEquip
            : context.l10n.shopBuyCoins(cost);
    final imageCandidates = <String>[
      if ((skin.previewPath ?? '').trim().isNotEmpty) skin.previewPath!.trim(),
      if ((skin.assetPath ?? '').trim().isNotEmpty) skin.assetPath!.trim(),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1A273F), Color(0xFF162033)],
        ),
        border: Border.all(
          color: _rarityColor(skin.rarity),
          width: 1.4,
        ),
        boxShadow: <BoxShadow>[
          if (_normalizedRarity(skin.rarity) == 'legendary')
            const BoxShadow(
              color: Color(0x55FFB800),
              blurRadius: 18,
              spreadRadius: 1.5,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'FEATURED SKIN',
            style: TextStyle(
              color: Color(0xFFE6EEFF),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 2.1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: const Color(0xFF0D121A),
                padding: const EdgeInsets.all(10),
                child: _BannerImageWithFallback(
                  candidates: imageCandidates,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  skin.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: rarityColor.withOpacity(0.95)),
                ),
                child: Text(
                  rarityLabel,
                  style: TextStyle(
                    color: rarityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: selected
                  ? null
                  : (owned || canBuy)
                      ? () => _onSkinAction(
                            skin: skin,
                            owned: owned,
                            cost: cost,
                          )
                      : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                disabledBackgroundColor: const Color(0xFF23334F),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSkinAction({
    required CoinSkinDef skin,
    required bool owned,
    required int cost,
  }) async {
    final fullResolved =
        await _resolveFullUrlForSkin(skin.id, context: 'equip');
    await widget.coinsService.registerSkinAsset(skin.id, fullResolved);

    if (owned) {
      try {
        await _inventoryService.equipSkin(_toRemoteSkinId(skin.id));
        await widget.coinsService.syncEquippedSkinFromRemote(skin.id);
      } catch (_) {
        await widget.coinsService.selectSkin(skin.id);
      }
      if (!mounted) return;
      setState(() {
        _inventoryStateFuture = _inventoryService.getInventoryState();
      });
      return;
    }

    final confirmed = await _confirmSkinPurchase(skin);
    if (!confirmed) return;
    try {
      await _inventoryService.purchaseSkin(
        skinId: _toRemoteSkinId(skin.id),
        price: cost,
      );
      await _inventoryService.equipSkin(_toRemoteSkinId(skin.id));
      final remaining = await _inventoryService.getCurrentCoins();
      await widget.coinsService.syncCoinsFromRemote(remaining);
      await widget.coinsService.syncOwnedSkinFromRemote(skin.id);
      await widget.coinsService.syncEquippedSkinFromRemote(skin.id);
      if (!mounted) return;
      await _showPurchaseBanner(skin);
      setState(() {
        _inventoryStateFuture = _inventoryService.getInventoryState();
      });
    } catch (e) {
      final fallbackOk = await widget.coinsService.purchaseCoinSkin(skin);
      if (fallbackOk) {
        final selectedFull = await _resolveFullUrlForSkin(
          skin.id,
          context: 'purchase-equip-fallback',
        );
        await widget.coinsService.registerSkinAsset(
          skin.id,
          selectedFull,
        );
        await widget.coinsService.selectSkin(skin.id);
        if (!mounted) return;
        await _showPurchaseBanner(skin);
        unawaited(_refreshInventoryInBackground());
        return;
      }
      if (!mounted) return;
      final msg = e.toString().contains('INSUFFICIENT_COINS')
          ? 'Not enough coins'
          : 'Could not complete purchase';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }

  List<CoinSkinDef> _sortSkinsForShop(List<CoinSkinDef> skins) {
    final sorted = List<CoinSkinDef>.from(skins);
    sorted.sort((a, b) {
      if (a.featured != b.featured) {
        return a.featured ? -1 : 1;
      }
      final rarityCmp = _rarityPriority(a.rarity).compareTo(
        _rarityPriority(b.rarity),
      );
      if (rarityCmp != 0) return rarityCmp;
      final orderCmp = a.order.compareTo(b.order);
      if (orderCmp != 0) return orderCmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return sorted;
  }

  int _rarityPriority(String rarity) {
    switch (_normalizedRarity(rarity)) {
      case 'legendary':
        return 0;
      case 'epic':
        return 1;
      case 'rare':
        return 2;
      case 'common':
      default:
        return 3;
    }
  }

  String _normalizedRarity(String rarity) => rarity.trim().toLowerCase();

  String _displayRarity(String rarity) {
    switch (_normalizedRarity(rarity)) {
      case 'legendary':
        return 'Legendary';
      case 'epic':
        return 'Epic';
      case 'rare':
        return 'Rare';
      case 'common':
      default:
        return 'Common';
    }
  }

  Color _rarityColor(String rarity) {
    switch (_normalizedRarity(rarity)) {
      case 'rare':
        return const Color(0xFF3A8DFF);
      case 'epic':
        return const Color(0xFF9B59FF);
      case 'legendary':
        return const Color(0xFFFFB800);
      case 'common':
      default:
        return const Color(0xFF8A8F98);
    }
  }

  void _queueInitialShopPrepare(BuildContext context, List<CoinSkinDef> skins) {
    if (_shopReady || _shopPreparing || skins.isEmpty) return;
    _shopPreparing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prepareInitialShop(context, skins);
    });
  }

  Future<void> _prepareInitialShop(
    BuildContext context,
    List<CoinSkinDef> skins,
  ) async {
    final initialPreviewCount = min(8, skins.length);
    final likelyDetailCount = min(4, skins.length);
    final targets = <({String skinId, String rawPath, String kind})>[];
    for (var i = 0; i < initialPreviewCount; i++) {
      final id = skins[i].id;
      final preview = _previewRawPathForSkinId(id);
      if (preview.isNotEmpty) {
        targets.add((skinId: id, rawPath: preview, kind: 'preview'));
      }
    }
    for (var i = 0; i < likelyDetailCount; i++) {
      final id = skins[i].id;
      final full = _fullRawPathForSkinId(id);
      if (full.isNotEmpty) {
        targets.add((skinId: id, rawPath: full, kind: 'full'));
      }
    }

    final uniqueTargets = <({String skinId, String rawPath, String kind})>[];
    for (final t in targets) {
      final dedupe = '${t.skinId}|${t.kind}|${t.rawPath}';
      if (_shopPrepPaths.add(dedupe)) uniqueTargets.add(t);
    }
    _shopPrepTotal = uniqueTargets.length;
    _shopPrepDone = 0;
    if (mounted) setState(() {});
    final sw = Stopwatch()..start();

    var completedSinceLastPaint = 0;
    for (final target in uniqueTargets) {
      await _imagePreloader.preloadFromRawPath(
        skinId: target.skinId,
        rawPath: target.rawPath,
        kind: target.kind,
        context: context,
        resolver: _resolveUiPath,
        resolveContext: 'grid-preload:${target.kind}:${target.skinId}',
      );
      _shopPrepDone += 1;
      completedSinceLastPaint += 1;
      if (mounted && completedSinceLastPaint >= 4) {
        completedSinceLastPaint = 0;
        setState(() {});
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[ShopWarmup] initial cached $_shopPrepDone/$_shopPrepTotal in ${sw.elapsedMilliseconds}ms',
      );
    }
    if (!mounted) return;
    setState(() {
      _shopReady = true;
      _shopPreparing = false;
    });
  }

  Widget _buildTrailsTab(BuildContext context) {
    final entries = _effectiveTrailEntries(context);
    final missingInCatalog = entries
        .where((e) => !e.presentInCatalog)
        .map((e) => e.id)
        .toList(growable: false);
    if (kDebugMode && missingInCatalog.isNotEmpty) {
      debugPrint('[shop][trail] Missing in TrailCatalog: $missingInCatalog');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: [
        const SectionHeader(title: 'Trail Effects'),
        const SizedBox(height: 10),
        ...entries.map((entry) {
          final owned = widget.coinsService.ownsTrail(entry.id);
          final selected = widget.coinsService.selectedTrail == entry.id;
          final cost = entry.costCoins ?? 0;
          final canBuy = entry.availableInShop &&
              !owned &&
              widget.coinsService.coins >= cost;
          return _TrailShopCard(
            key: ValueKey<String>('trail-${entry.id}'),
            trailId: entry.id,
            trailName: entry.displayName,
            trailDescription: entry.description,
            owned: owned,
            selected: selected,
            cost: entry.costCoins,
            canBuy: canBuy,
            preview: entry.preview,
            availableInShop: entry.availableInShop,
            onEquip: () => widget.coinsService.selectTrail(entry.id),
            onBuy: () async {
              if (!entry.availableInShop) return;
              final ok = await widget.coinsService.purchaseCoinTrail(
                CoinTrailDef(
                  id: entry.id,
                  name: entry.displayName,
                  costCoins: entry.costCoins,
                ),
              );
              if (!mounted || !ok) return;
              await widget.coinsService.selectTrail(entry.id);
              if (!mounted) return;
              await _showTrailUnlockBanner(
                trailName: entry.displayName,
                preview: entry.preview,
              );
            },
          );
        }),
      ],
    );
  }

  List<_TrailShopMeta> _effectiveTrailEntries(BuildContext context) {
    final catalogById = <String, TrailSkinConfig>{
      for (final t in TrailCatalog.all) t.id.trim(): t,
    };
    final out = <_TrailShopMeta>[];
    final seen = <String>{};

    for (final configured in ShopScreen._coinTrails) {
      final id = configured.id.trim();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      final catalogEntry = catalogById[id];
      final preview = catalogEntry ?? TrailCatalog.resolveByTrailId(id);
      final override = _trailShopOverrides[id];
      final configuredName = configured.name.trim();
      final catalogName = preview.name.trim();
      final rawName = (override?.name.trim().isNotEmpty ?? false)
          ? override!.name.trim()
          : configuredName.isNotEmpty
              ? configuredName
              : (catalogName.isNotEmpty ? catalogName : _humanizeTrailId(id));
      final displayName = _formatTrailDisplayName(rawName);
      final description =
          override?.description ?? _resolveTrailDescription(id, context);
      final resolvedCost = override?.coins ?? configured.costCoins;
      final hasPrice = resolvedCost != null && resolvedCost >= 0;
      out.add(
        _TrailShopMeta(
          id: id,
          displayName: displayName,
          description: description,
          costCoins: resolvedCost,
          availableInShop: hasPrice,
          presentInCatalog: catalogEntry != null,
          preview: preview,
        ),
      );
    }

    for (final catalog in TrailCatalog.all) {
      final id = catalog.id.trim();
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      out.add(
        _TrailShopMeta(
          id: id,
          displayName: _formatTrailDisplayName(
            catalog.name.trim().isNotEmpty
                ? catalog.name.trim()
                : _humanizeTrailId(id),
          ),
          description: _resolveTrailDescription(id, context),
          costCoins: null,
          availableInShop: false,
          presentInCatalog: true,
          preview: catalog,
        ),
      );
    }
    return out;
  }

  String _resolveTrailDescription(String trailId, BuildContext context) {
    final configured = ShopScreen._trailDescriptions[trailId]?.trim() ?? '';
    if (configured.isNotEmpty) return configured;
    return context.l10n.shopDefaultTrailDescription;
  }

  String _humanizeTrailId(String id) {
    final cleaned = id.trim().replaceFirst(RegExp(r'^trail_'), '');
    if (cleaned.isEmpty) return 'Trail';
    final words = cleaned.split('_').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'Trail';
    return words
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _formatTrailDisplayName(String raw) {
    final base = raw.trim();
    if (base.isEmpty) return 'Trail';
    final spaced = base
        .replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ')
        .replaceAllMapped(RegExp(r'(?<=\D)(?=\d)'), (_) => ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (spaced.isEmpty) return 'Trail';
    return spaced;
  }

  Future<void> _showTrailUnlockBanner({
    required String trailName,
    required TrailSkinConfig preview,
  }) async {
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'trail_unlock_banner',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (dialogContext, __, ___) {
        return _TrailUnlockToast(
          trailName: trailName,
          preview: preview,
        );
      },
      transitionBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  Widget _buildCoinPacksTab(BuildContext context) {
    return FutureBuilder<CoinPackCatalogResult>(
      future: _coinPacksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }
        if (snapshot.hasError) {
          if (!_didShowCoinPackLoadError) {
            _didShowCoinPackLoadError = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showShopErrorPopup(
                title: 'Coin packs unavailable',
                message: 'Could not load coin packs. Please retry.',
              );
            });
          }
          return _buildCoinPackInlineInfo(
            context,
            title: 'Coin packs unavailable',
            subtitle: 'Please check your connection and retry.',
            onRetry: _reloadCoinPacks,
          );
        }
        final result = snapshot.data;
        final packs = result?.packs ?? const <CoinPack>[];
        if (packs.isEmpty) {
          if (!_didShowCoinPackEmptyInfo) {
            _didShowCoinPackEmptyInfo = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showShopErrorPopup(
                title: 'No coin packs available',
                message:
                    'Store products are not available right now. Please try again later.',
              );
            });
          }
          return _buildCoinPackInlineInfo(
            context,
            title: 'No coin packs available',
            subtitle:
                'Store products are not available right now. Please try again later.',
            onRetry: _reloadCoinPacks,
          );
        }
        _logIapSummaryIfNeeded(packs, reason: 'build_coin_packs_tab');
        _didShowCoinPackLoadError = false;
        _didShowCoinPackEmptyInfo = false;
        final iapState = _iapService.state;
        final iapMessage = _iapService.message.trim();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Row(
              children: [
                const Expanded(child: SectionHeader(title: 'Coin Packs')),
                TextButton.icon(
                  onPressed: () => unawaited(_iapService.restorePurchases()),
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('Restore'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildEnergyBatterySection(context),
            const SizedBox(height: 12),
            const SizedBox(height: 6),
            if (_iapService.isStoreLoading)
              const Text(
                'Loading store products...',
                style: TextStyle(
                  color: Color(0xFF9FB0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              )
            else if (_iapService.isStoreUnavailable ||
                _iapService.isStoreError ||
                iapState == IapStoreState.idle)
              Text(
                iapMessage.isEmpty
                    ? 'Store products are not available right now. Please try again later.'
                    : iapMessage,
                style: const TextStyle(
                  color: Color(0xFFFFB4A9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              const Text(
                'Choose the best bundle for your progress.',
                style: TextStyle(
                  color: Color(0xFF9FB0D3),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (_iapService.notFoundIds.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Missing products: ${_iapService.notFoundIds.join(', ')}',
                style: const TextStyle(
                  color: Color(0xFFB8C7E6),
                  fontSize: 11,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_iapService.pendingProductId.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF122036),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A3A57)),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Processing purchase...',
                        style: TextStyle(
                          color: Color(0xFFD7E6FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_iapService.isStoreUnavailable || _iapService.isStoreError) ...[
              _buildCoinPackInlineInfo(
                context,
                title: 'Store unavailable',
                subtitle:
                    'You can still browse all coin packs. Purchases are disabled right now.',
                onRetry: _reloadCoinPacks,
              ),
              const SizedBox(height: 10),
            ],
            Builder(
              builder: (context) {
                final width = MediaQuery.of(context).size.width;
                final veryNarrow = width < 360;
                final isNarrow = width < 390;
                final crossAxisCount = veryNarrow ? 1 : 2;
                final childAspectRatio =
                    veryNarrow ? 1.75 : (isNarrow ? 0.60 : 0.64);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: packs.length,
                  itemBuilder: (context, idx) {
                    final pack = packs[idx];
                    final available = _iapService.isPackAvailable(pack);
                    return CoinPackCard(
                      pack: pack,
                      assetPath: _coinPackAssetPath(pack),
                      priceText: _iapService.displayPriceForPack(pack),
                      enabled: available &&
                          _iapService.pendingProductId.isEmpty &&
                          _iapService.isStoreReady,
                      loading: _iapService.isPackPending(pack),
                      onBuy: () => unawaited(_onBuyCoinPack(pack)),
                    );
                  },
                );
              },
            ),
            if ((result?.usingFallback ?? false) && kDebugMode) ...[
              const SizedBox(height: 10),
              Text(
                'Showing local catalog fallback'
                '${(result?.fallbackReason ?? '').isNotEmpty ? ' (${result?.fallbackReason})' : ''}',
                style: const TextStyle(
                  color: Color(0xFF7E93B9),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEnergyBatterySection(BuildContext context) {
    final energy = widget.energyService.snapshot;
    final timeLeft = _formatDurationShort(energy.timeUntilReset());
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF142238),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2C3E5E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.battery_charging_full_rounded,
                color: Color(0xFF6EE7B7),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Energy batteries',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Energy ${energy.current}/${energy.max}',
                style: const TextStyle(
                  color: Color(0xFFCBEAD8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Batteries: ${energy.batteryCount} - Reset in $timeLeft',
            style: const TextStyle(
              color: Color(0xFF9EC2E9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (energy.batteryCount > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: () => unawaited(_useBatteryFromShop()),
                child: const Text('Use 1 battery now'),
              ),
            ),
          const SizedBox(height: 8),
          ...EnergyService.batteryOffers.map(
            (offer) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1B2F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E4468)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            offer.subtitle,
                            style: const TextStyle(
                              color: Color(0xFF9FB0D3),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () => unawaited(_buyBatteryFromShop(offer)),
                      child: Text('Buy ${offer.coinCost}'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useBatteryFromShop() async {
    final result = await widget.energyService.useBatteryAndRefill();
    if (!mounted) return;
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not use battery right now.'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Energy restored to ${result.snapshot.current}/${result.snapshot.max}.',
        ),
      ),
    );
  }

  Future<void> _buyBatteryFromShop(EnergyCatalogItem offer) async {
    final result = await widget.energyService.buyBatteryPackWithCoins(
      offer: offer,
    );
    if (!mounted) return;
    if (!result.success) {
      final text = result.failureReason ==
              EnergyBatteryPurchaseFailureReason.notEnoughCoins
          ? 'Not enough coins for this battery pack.'
          : 'Battery purchase failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)),
      );
      return;
    }
    if (result.newCoinsBalance != null) {
      await widget.coinsService.syncCoinsFromRemote(result.newCoinsBalance!);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Purchased ${offer.batteryUnits} battery(s). Total: ${result.snapshot.batteryCount}.',
        ),
      ),
    );
  }

  String _formatDurationShort(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60);
    final seconds = safe.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildCoinPackInlineInfo(
    BuildContext context, {
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF122036),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF2A3A57)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF9FB0D3),
                  fontSize: 13,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _reloadCoinPacks() {
    setState(() {
      _coinPacksFuture = _coinPackCatalogService.fetchPacks(
        timeout: const Duration(seconds: 3),
      );
    });
    unawaited(() async {
      final result = await _coinPacksFuture;
      await _iapService.refreshCatalog(result.packs);
      _logIapSummaryIfNeeded(result.packs, reason: 'reload');
    }());
  }

  Future<void> _showShopErrorPopup({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF131E31),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFFF8A80)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFB8C7E6),
            fontSize: 14,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF8FC4FF)),
            ),
          ),
        ],
      ),
    );
  }

  String _coinPackAssetPath(CoinPack pack) {
    final byId = _coinPackAssetById[pack.id];
    if (byId != null && byId.isNotEmpty) return byId;
    if (_coinPackAssetOrderFallback.isEmpty) return '';
    final clamped = pack.sortOrder > 0 ? pack.sortOrder - 1 : pack.sortOrder;
    final safe = clamped.clamp(0, _coinPackAssetOrderFallback.length - 1);
    return _coinPackAssetOrderFallback[safe];
  }

  Future<void> _onBuyCoinPack(CoinPack pack) async {
    debugPrint('[SHOP] coin pack tap packId=${pack.id}');
    debugPrint(
      '[SHOP-IAP] pre-buy state available=${_iapService.storeAvailable} ready=${_iapService.isStoreReady} loading=${_iapService.isStoreLoading} error=${_iapService.isStoreError} unavailable=${_iapService.isStoreUnavailable}',
    );
    debugPrint(
      '[SHOP-IAP] pre-buy mapping packId=${pack.id} productId=${_iapService.debugProductIdForPack(pack)} mapped=${_iapService.isPackAvailable(pack)}',
    );
    final result = await _iapService.buyPack(pack);
    if (!mounted) return;
    if (result.status == BuyCoinPackStatus.success) {
      final added = result.addedCoins;
      if (added > 0) {
        _showCoinPackGainFeedback(added);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase successful'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text(
          'Coin Packs',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          result.message.isEmpty
              ? 'Store products are not available right now. Please try again later.'
              : result.message,
          style: const TextStyle(color: Color(0xFF9FB0D3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _logIapSummaryIfNeeded(List<CoinPack> packs, {required String reason}) {
    final productIds = packs
        .map((p) => _iapService.debugProductIdForPack(p))
        .where((id) => id.trim().isNotEmpty)
        .toList(growable: false)
      ..sort();
    final loadedIds = _iapService.loadedProductIds.toList(growable: false)
      ..sort();
    final missing = _iapService.notFoundIds.toList(growable: false)..sort();
    final fingerprint = [
      _iapService.storeAvailable.toString(),
      _iapService.state.name,
      productIds.join(','),
      loadedIds.join(','),
      missing.join(','),
    ].join('|');
    if (fingerprint == _lastIapSummaryFingerprint) return;
    _lastIapSummaryFingerprint = fingerprint;
    debugPrint('[SHOP] IAP debug summary ($reason)');
    debugPrint('[SHOP] store available: ${_iapService.storeAvailable}');
    debugPrint('[SHOP] loaded products count: ${loadedIds.length}');
    debugPrint('[SHOP] loaded product IDs: ${loadedIds.join(", ")}');
    debugPrint('[SHOP] missing product IDs: ${missing.join(", ")}');
    _iapService.debugLogShopSummary(packs);
  }

  void _showCoinPackGainFeedback(int amount) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1100),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        content: Row(
          children: [
            const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD54A)),
            const SizedBox(width: 8),
            Text(
              '+$amount coins',
              style: const TextStyle(
                color: Color(0xFF8CFFAA),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _queuePrecacheNextBatch(
    List<CoinSkinDef> skins,
    int visibleCount,
  ) {
    if (visibleCount >= skins.length) return;
    final start = visibleCount;
    final end = min(start + _skinBatchSize, skins.length);
    final key = '${skins.length}:$start:$end';
    if (!_precacheRangeKeys.add(key)) return;
    Future<void>.microtask(() {
      if (!mounted) return;
      _precacheSkinRange(skins, start, end);
    });
  }

  Future<void> _loadMoreSkins(List<CoinSkinDef> skins) async {
    if (_loadingMoreSkins) return;
    if (_visibleSkinCount >= skins.length) return;
    final start = _visibleSkinCount;
    final end = min(start + _skinBatchSize, skins.length);
    setState(() {
      _loadingMoreSkins = true;
      _visibleSkinCount = end;
    });
    unawaited(() async {
      await _precacheSkinRange(skins, start, end);
      if (!mounted) return;
      setState(() {
        _loadingMoreSkins = false;
      });
    }());
  }

  Future<void> _precacheSkinRange(
    List<CoinSkinDef> skins,
    int start,
    int end,
  ) async {
    for (var i = start; i < end; i++) {
      await _precacheSkin(skins[i]);
    }
  }

  Future<void> _precacheSkin(CoinSkinDef skin) async {
    final preview = _previewRawPathForSkinId(skin.id);
    if (preview.isNotEmpty) {
      await _imagePreloader.preloadFromRawPath(
        skinId: skin.id,
        rawPath: preview,
        kind: 'preview',
        context: context,
        resolver: _resolveUiPath,
        resolveContext: 'grid-preview:${skin.id}',
      );
      return;
    }
    final full = _fullRawPathForSkinId(skin.id);
    if (full.isNotEmpty) {
      await _imagePreloader.preloadFromRawPath(
        skinId: skin.id,
        rawPath: full,
        kind: 'full',
        context: context,
        resolver: _resolveUiPath,
        resolveContext: 'grid-full:${skin.id}',
      );
    }
  }

  Future<void> _showSkinPreview(BuildContext context, CoinSkinDef skin) async {
    final fullRawPath = _fullRawPathForSkinId(skin.id);
    if (fullRawPath.isEmpty) return;
    if (kDebugMode) {
      debugPrint(
          '[shop] Opening full preview for ${skin.id} fullPath=$fullRawPath');
    }
    await _preloadDetailForSkin(skin.id, reason: 'full-preview');
    await widget.skinCatalogService.resolveDetailUrlsForSkin(skin.id);
    final resolvedFullPath = await _resolveUiPath(
      fullRawPath,
      context: 'full-preview:${skin.id}',
    );
    if (kDebugMode) {
      debugPrint(
        '[shop] Resolved full preview URL for ${skin.id} -> ${resolvedFullPath ?? '(null)'}',
      );
    }
    final imagePath = resolvedFullPath ?? _resolveForRender(fullRawPath) ?? '';
    if (imagePath.trim().isEmpty) return;
    if (!mounted) return;
    await showDialog<void>(
      context: this.context,
      barrierColor: Colors.black.withOpacity(0.86),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 36, 14, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      skin.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _buildPreviewImage(imagePath),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2937),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewImage(String path, {bool allowExtFallback = true}) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.contain, height: 360);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      if (kDebugMode) {
        debugPrint('[ShopPreview] open full image: $path');
      }
      if (kIsWeb) {
        return SizedBox(
          height: 360,
          child: buildNetworkImageCompat(
            url: path,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            fallback: const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        );
      }
      final sw = Stopwatch()..start();
      return Image.network(
        path,
        fit: BoxFit.contain,
        height: 360,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            if (kDebugMode) {
              debugPrint(
                '[ShopPreview] loaded in ${sw.elapsedMilliseconds}ms: $path',
              );
            }
          }
          return child;
        },
        errorBuilder: (_, __, ___) {
          if (kDebugMode) {
            debugPrint(
              '[ShopPreview] FAILED after ${sw.elapsedMilliseconds}ms: $path',
            );
          }
          final extFallback =
              allowExtFallback ? _extensionFallbackUrl(path) : null;
          if (extFallback != null && extFallback != path) {
            return _buildPreviewImage(extFallback, allowExtFallback: false);
          }
          return const SizedBox(
            height: 360,
            child: Center(child: Icon(Icons.broken_image_outlined)),
          );
        },
      );
    }
    if (path.startsWith('data:image')) {
      final comma = path.indexOf(',');
      if (comma > 0 && comma < path.length - 1) {
        final bytes = base64Decode(path.substring(comma + 1));
        return Image.memory(bytes, fit: BoxFit.contain, height: 360);
      }
    }
    if (kIsWeb) {
      return const SizedBox(
        height: 360,
        child: Center(child: Icon(Icons.image_not_supported_outlined)),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      height: 360,
      errorBuilder: (_, __, ___) => const SizedBox(
        height: 360,
        child: Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }

  Future<bool> _confirmSkinPurchase(CoinSkinDef skin) async {
    unawaited(_preloadDetailForSkin(skin.id, reason: 'purchase-open'));
    final price = skin.costCoins ?? 0;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF334155)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirm purchase',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Do you want to buy "${skin.name}" for $price coins?',
                  style: const TextStyle(
                    color: Color(0xFFB6C2DA),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF3B4A64)),
                          foregroundColor: const Color(0xFFD5DEEE),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Buy now'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result == true;
  }

  Future<void> _showPurchaseBanner(CoinSkinDef skin) async {
    unawaited(_preloadDetailForSkin(skin.id, reason: 'purchase-banner'));
    final bannerCandidates = await _bannerCandidatePathsForSkin(skin);

    if (kDebugMode && bannerCandidates.isEmpty) {
      debugPrint('[shop] No purchase image candidates for ${skin.id}');
    }

    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'purchase_banner',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (dialogContext, __, ___) {
        return _PurchaseBannerToast(
          skinName: skin.name,
          rarity: _displayRarity(skin.rarity),
          imageCandidates: bannerCandidates,
        );
      },
      transitionBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }

  Future<List<String>> _bannerCandidatePathsForSkin(CoinSkinDef skin) async {
    final item = widget.skinCatalogService.getById(skin.id);
    if (item == null) return const <String>[];
    await widget.skinCatalogService.resolveDetailUrlsForSkin(skin.id);
    final ordered = <({String source, String path})>[
      (source: 'banner', path: item.bannerImagePath),
      (source: 'card', path: item.cardImagePath),
      (source: 'preview', path: _gridPreviewRawPath(item)),
      (source: 'full', path: item.fullImagePath),
    ];

    if (kDebugMode) {
      debugPrint(
        '[shop] Purchase source paths for ${skin.id} '
        'banner=${item.bannerImagePath} card=${item.cardImagePath} '
        'preview=${_gridPreviewRawPath(item)} full=${item.fullImagePath}',
      );
      debugPrint('[shop] Purchase raw candidates for ${skin.id}:');
      for (final c in ordered) {
        debugPrint('- ${c.source}: ${c.path}');
      }
    }

    final resolved = <String>[];
    final resolvedBySource = <String, String>{};
    for (final candidate in ordered) {
      final raw = candidate.path.trim();
      if (raw.isEmpty) {
        resolvedBySource[candidate.source] = '';
        continue;
      }
      try {
        final url = await _resolveUiPath(
          raw,
          context: 'purchase-${candidate.source}:${skin.id}',
        );
        final cleanUrl = (url ?? '').trim();
        resolvedBySource[candidate.source] = cleanUrl;
        if (cleanUrl.isEmpty) {
          if (kDebugMode && candidate.source == 'banner') {
            debugPrint('[shop] Failed to resolve banner for ${skin.id}: empty');
          }
          continue;
        }
        if (!resolved.contains(cleanUrl)) {
          resolved.add(cleanUrl);
          if (mounted) {
            unawaited(_imagePreloader.preloadResolvedUrl(
              cleanUrl,
              skinId: skin.id,
              kind: candidate.source,
              context: context,
            ));
          }
        }
      } catch (e) {
        resolvedBySource[candidate.source] = '';
        if (kDebugMode && candidate.source == 'banner') {
          debugPrint('[shop] Failed to resolve banner for ${skin.id}: $e');
        }
      }
    }

    if (kDebugMode) {
      debugPrint('[shop] Purchase resolved candidates for ${skin.id}:');
      for (final c in ordered) {
        debugPrint('- ${c.source}: ${resolvedBySource[c.source] ?? ''}');
      }
      if (resolved.isNotEmpty) {
        final first = ordered.firstWhere(
          (c) => (resolvedBySource[c.source] ?? '').trim().isNotEmpty,
          orElse: () => (source: 'none', path: ''),
        );
        debugPrint('[shop] Purchase image fallback used: ${first.source}');
      }
    }

    return resolved;
  }

  String _gridPreviewRawPath(SkinCatalogItem item) {
    final preview = item.previewImagePath.trim();
    if (preview.isNotEmpty) return preview;
    return item.fullImagePath.trim();
  }

  String _previewRawPathForSkinId(String skinId) {
    final item = widget.skinCatalogService.getById(skinId);
    if (item == null) return '';
    return _gridPreviewRawPath(item);
  }

  String _fullRawPathForSkinId(String skinId) {
    final item = widget.skinCatalogService.getById(skinId);
    if (item == null) return '';
    return item.fullImagePath.trim();
  }

  String _toLocalSkinId(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (value == 'default') return 'pointer_default';
    return value;
  }

  String _toRemoteSkinId(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return 'default';
    if (value == 'pointer_default') return 'default';
    return value;
  }

  String? _resolveForRender(String? rawPath) {
    final raw = (rawPath ?? '').trim();
    if (raw.isEmpty) return null;
    final cached = _uiResolvedUrlCache[raw];
    if (cached != null && cached.trim().isNotEmpty) return cached;
    return widget.skinCatalogService.toRenderablePath(raw);
  }

  Future<String?> _resolveUiPath(String rawPath,
      {required String context}) async {
    final raw = rawPath.trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('assets/') ||
        raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('data:image')) {
      final normalizedDirect = raw.replaceAll(RegExp(r'\s+'), '');
      _uiResolvedUrlCache[raw] = normalizedDirect;
      return normalizedDirect;
    }

    final cached = _uiResolvedUrlCache[raw];
    if (cached != null) return cached;
    final inflight = _uiInflightResolveCache[raw];
    if (inflight != null) return inflight;

    final future = widget.skinCatalogService
        .resolveDownloadUrl(raw, context: context)
        .then((value) => value?.trim().isEmpty ?? true ? null : value)
        .catchError((e) {
      if (kDebugMode) {
        debugPrint('[shop] Failed to resolve $raw ($context): $e');
      }
      return null;
    });
    _uiInflightResolveCache[raw] = future;
    try {
      final resolved = await future;
      if (resolved != null) {
        _uiResolvedUrlCache[raw] = resolved;
      }
      return resolved;
    } finally {
      _uiInflightResolveCache.remove(raw);
    }
  }

  Future<String?> _resolveFullUrlForSkin(
    String skinId, {
    required String context,
  }) async {
    final fullRaw = _fullRawPathForSkinId(skinId);
    if (fullRaw.isEmpty) return null;
    return _resolveUiPath(fullRaw, context: '$context:$skinId');
  }

  Future<void> _preloadDetailForSkin(
    String skinId, {
    required String reason,
  }) async {
    final item = widget.skinCatalogService.getById(skinId);
    if (item == null) return;

    final preview = _gridPreviewRawPath(item);
    if (preview.isNotEmpty) {
      if (!mounted) return;
      await _imagePreloader.preloadFromRawPath(
        skinId: skinId,
        rawPath: preview,
        kind: 'preview',
        context: context,
        resolver: _resolveUiPath,
        resolveContext: '$reason:preview:$skinId',
      );
    }

    final full = item.fullImagePath.trim();
    if (full.isNotEmpty) {
      if (!mounted) return;
      await _imagePreloader.preloadFromRawPath(
        skinId: skinId,
        rawPath: full,
        kind: 'full',
        context: context,
        resolver: _resolveUiPath,
        resolveContext: '$reason:full:$skinId',
      );
    }

    final banner = item.bannerImagePath.trim();
    if (banner.isNotEmpty) {
      if (!mounted) return;
      await _imagePreloader.preloadFromRawPath(
        skinId: skinId,
        rawPath: banner,
        kind: 'banner',
        context: context,
        resolver: _resolveUiPath,
        resolveContext: '$reason:banner:$skinId',
      );
    }
  }

  String? _extensionFallbackUrl(String url) {
    final lower = url.toLowerCase();
    if (!lower.contains('.webp')) return null;
    final q = url.indexOf('?');
    final path = q >= 0 ? url.substring(0, q) : url;
    final query = q >= 0 ? url.substring(q) : '';
    final dot = path.toLowerCase().lastIndexOf('.webp');
    if (dot < 0) return null;
    return '${path.substring(0, dot)}.png$query';
  }
}

class _BannerImageWithFallback extends StatefulWidget {
  const _BannerImageWithFallback({
    required this.candidates,
    required this.fit,
  });

  final List<String> candidates;
  final BoxFit fit;

  @override
  State<_BannerImageWithFallback> createState() =>
      _BannerImageWithFallbackState();
}

class _BannerImageWithFallbackState extends State<_BannerImageWithFallback> {
  int _index = 0;
  bool _advancing = false;
  String? _lastStartedPath;
  String? _lockedSuccessPath;
  final Stopwatch _attemptSw = Stopwatch();
  bool _loadedLogged = false;

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.candidates.length) {
      return _buildBannerPlaceholder(error: true);
    }
    final path = widget.candidates[_index];
    if (_lastStartedPath != path) {
      _lastStartedPath = path;
      _lockedSuccessPath = null;
      _loadedLogged = false;
      _attemptSw
        ..reset()
        ..start();
      if (kDebugMode) {
        debugPrint('[shop] Banner start: $path');
      }
    }
    return _buildCandidateImage(path);
  }

  Widget _buildCandidateImage(String path) {
    final trimmed = path.trim();
    if (trimmed.startsWith('assets/')) {
      return Image.asset(
        trimmed,
        fit: widget.fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            _logLoaded(trimmed);
            return child;
          }
          return _buildBannerPlaceholder();
        },
        errorBuilder: (_, __, ___) => _advanceWithError(trimmed),
      );
    }
    if (trimmed.startsWith('data:image')) {
      final comma = trimmed.indexOf(',');
      if (comma > 0 && comma < trimmed.length - 1) {
        try {
          final bytes = base64Decode(trimmed.substring(comma + 1));
          _logLoaded(trimmed);
          return Image.memory(
            bytes,
            fit: widget.fit,
            frameBuilder: (context, child, _, __) {
              _logLoaded(trimmed);
              return child;
            },
          );
        } catch (_) {
          return _advanceWithError(trimmed);
        }
      }
      return _advanceWithError(trimmed);
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      if (kIsWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_lastStartedPath == trimmed) {
            _logLoaded(trimmed);
          }
        });
        return buildNetworkImageCompat(
          url: trimmed,
          fit: widget.fit,
          filterQuality: FilterQuality.high,
          fallback: _buildBannerPlaceholder(error: true),
        );
      }
      return Image.network(
        trimmed,
        fit: widget.fit,
        filterQuality: FilterQuality.high,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildBannerPlaceholder();
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            _logLoaded(trimmed);
          }
          return child;
        },
        errorBuilder: (_, __, ___) => _advanceWithError(trimmed),
      );
    }
    if (!kIsWeb) {
      return Image.file(
        File(trimmed),
        fit: widget.fit,
        frameBuilder: (context, child, _, __) {
          _logLoaded(trimmed);
          return child;
        },
        errorBuilder: (_, __, ___) => _advanceWithError(trimmed),
      );
    }
    return _advanceWithError(trimmed);
  }

  void _logLoaded(String path) {
    if (_loadedLogged) return;
    _loadedLogged = true;
    _lockedSuccessPath = path;
    if (kDebugMode) {
      debugPrint('[shop] Banner visible success: $path');
    }
  }

  Widget _advanceWithError(String path) {
    if (_lockedSuccessPath == path) {
      if (kDebugMode) {
        debugPrint('[shop] Banner web late error ignored: $path');
      }
      if (kIsWeb &&
          (path.startsWith('http://') || path.startsWith('https://'))) {
        return buildNetworkImageCompat(
          url: path,
          fit: widget.fit,
          filterQuality: FilterQuality.high,
          fallback: _buildBannerPlaceholder(error: true),
        );
      }
      return _buildBannerPlaceholder();
    }
    if (kDebugMode) {
      debugPrint(
        '[shop] Banner failed: $path (${_attemptSw.elapsedMilliseconds}ms)',
      );
      debugPrint('[shop] Banner fallback advance from: $path');
    }
    if (_advancing) {
      return _buildBannerPlaceholder();
    }
    _advancing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _index += 1;
        _advancing = false;
      });
    });
    return _buildBannerPlaceholder();
  }

  Widget _buildBannerPlaceholder({bool error = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1222),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A374F)),
      ),
      child: Center(
        child: Icon(
          error ? Icons.broken_image_outlined : Icons.photo_outlined,
          color: Colors.white70,
          size: 34,
        ),
      ),
    );
  }
}

class _PurchaseBannerToast extends StatefulWidget {
  const _PurchaseBannerToast({
    required this.skinName,
    required this.rarity,
    required this.imageCandidates,
  });

  final String skinName;
  final String rarity;
  final List<String> imageCandidates;

  @override
  State<_PurchaseBannerToast> createState() => _PurchaseBannerToastState();
}

class _PurchaseBannerToastState extends State<_PurchaseBannerToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideX;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2850),
    );
    _slideX = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -1.15, end: 0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 380,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0),
        weight: 2100,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1.2).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: 370,
      ),
    ]).animate(_controller);
    _fade = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 240,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: 2260,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 350,
      ),
    ]).animate(_controller);
    _scale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.97, end: 1.015).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 270,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.015, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 230,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: 2350,
      ),
    ]).animate(_controller);
    _glowPulse = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0.35),
        weight: 380,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.35, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 780,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 0.45).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 780,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0.4),
        weight: 910,
      ),
    ]).animate(_controller);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pop();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _rarityColor(String rarity) {
    switch (rarity.trim().toLowerCase()) {
      case 'legendary':
        return const Color(0xFFFFB800);
      case 'epic':
        return const Color(0xFF9B59FF);
      case 'rare':
        return const Color(0xFF3A8DFF);
      default:
        return const Color(0xFF8A8F98);
    }
  }

  String _rarityHeadline(String rarity) {
    final normalized = rarity.trim().toLowerCase();
    if (normalized == 'legendary' ||
        normalized == 'epic' ||
        normalized == 'rare' ||
        normalized == 'common') {
      return '${rarity.toUpperCase()} SKIN';
    }
    return 'NEW SKIN';
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(widget.rarity);
    final headline = _rarityHeadline(widget.rarity);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: const Alignment(0, -0.12),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final glowStrength = _glowPulse.value;
                return Opacity(
                  opacity: _fade.value,
                  child: Transform.translate(
                    offset: Offset(
                        _slideX.value *
                            MediaQuery.of(context).size.width *
                            0.82,
                        0),
                    child: Transform.scale(
                      scale: _scale.value,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                        constraints: const BoxConstraints(maxWidth: 700),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFF172038),
                              Color(0xFF111827),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: rarityColor.withOpacity(0.85),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.58),
                              blurRadius: 26,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: rarityColor.withOpacity(
                                0.15 + (0.18 * glowStrength),
                              ),
                              blurRadius: 34,
                              spreadRadius: 1.2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: double.infinity,
                                height: 124,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _BannerImageWithFallback(
                                      candidates: widget.imageCandidates,
                                      fit: BoxFit.cover,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: <Color>[
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.26),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: rarityColor.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: rarityColor.withOpacity(0.6),
                                    ),
                                  ),
                                  child: Text(
                                    headline,
                                    style: TextStyle(
                                      color: rarityColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 18,
                                  color: rarityColor.withOpacity(0.9),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.skinName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                                height: 1.06,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.shopUnlockedAndEquipped,
                              style: TextStyle(
                                color:
                                    const Color(0xFFA8B5D3).withOpacity(0.95),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TrailUnlockToast extends StatefulWidget {
  const _TrailUnlockToast({
    required this.trailName,
    required this.preview,
  });

  final String trailName;
  final TrailSkinConfig preview;

  @override
  State<_TrailUnlockToast> createState() => _TrailUnlockToastState();
}

class _TrailUnlockToastState extends State<_TrailUnlockToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideX;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2550),
    );
    _slideX = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: -1.08, end: 0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 340,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0),
        weight: 1820,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1.16).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: 390,
      ),
    ]).animate(_controller);
    _fade = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 220,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: 1970,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 360,
      ),
    ]).animate(_controller);
    _scale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.97, end: 1.015).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 240,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.015, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 220,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(1),
        weight: 2090,
      ),
    ]).animate(_controller);
    _glowPulse = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0.3),
        weight: 420,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.3, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 660,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1.0, end: 0.4).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 640,
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0.38),
        weight: 830,
      ),
    ]).animate(_controller);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pop();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF60A5FA);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: const Alignment(0, -0.1),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final glowStrength = _glowPulse.value;
                return Opacity(
                  opacity: _fade.value,
                  child: Transform.translate(
                    offset: Offset(
                      _slideX.value * MediaQuery.of(context).size.width * 0.82,
                      0,
                    ),
                    child: Transform.scale(
                      scale: _scale.value,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                        constraints: const BoxConstraints(maxWidth: 700),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFF172038),
                              Color(0xFF111827),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accent.withOpacity(0.9),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.58),
                              blurRadius: 26,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: accent.withOpacity(
                                0.14 + (0.16 * glowStrength),
                              ),
                              blurRadius: 32,
                              spreadRadius: 1.0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: double.infinity,
                                height: 108,
                                child: Container(
                                  color: const Color(0xFF0B1222),
                                  child: CustomPaint(
                                    painter: _TrailPreviewPainter(
                                      skin: widget.preview,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: accent.withOpacity(0.6),
                                    ),
                                  ),
                                  child: Text(
                                    context.l10n.shopNewTrail,
                                    style: TextStyle(
                                      color: accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 18,
                                  color: accent.withOpacity(0.9),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.trailName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                                height: 1.06,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.shopUnlockedAndEquipped,
                              style: TextStyle(
                                color:
                                    const Color(0xFFA8B5D3).withOpacity(0.95),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TrailShopCard extends StatelessWidget {
  const _TrailShopCard({
    super.key,
    required this.trailId,
    required this.trailName,
    required this.trailDescription,
    required this.owned,
    required this.selected,
    required this.cost,
    required this.canBuy,
    required this.availableInShop,
    required this.preview,
    required this.onEquip,
    required this.onBuy,
  });

  final String trailId;
  final String trailName;
  final String trailDescription;
  final bool owned;
  final bool selected;
  final int? cost;
  final bool canBuy;
  final bool availableInShop;
  final TrailSkinConfig preview;
  final VoidCallback onEquip;
  final Future<void> Function() onBuy;

  @override
  Widget build(BuildContext context) {
    final normalizedId = trailId.trim().toLowerCase();
    final resolvedName =
        trailName.trim().isNotEmpty ? trailName.trim() : preview.name.trim();
    final safeTrailName =
        resolvedName.isNotEmpty ? resolvedName : _humanizeTrailId(trailId);
    final safeDescription = trailDescription.trim().isNotEmpty
        ? trailDescription.trim()
        : _missingDescriptionLabel(context);
    final effectiveCost = cost ?? -1;
    final hasValidPrice = effectiveCost >= 0;
    final effectiveAvailableInShop = availableInShop && hasValidPrice;
    final isLegendary = normalizedId.contains('legendary') ||
        safeTrailName.toLowerCase().contains('legendary');
    final statusText = owned
        ? context.l10n.shopOwned
        : (effectiveAvailableInShop && hasValidPrice)
            ? context.l10n.shopCoinsAmount(effectiveCost)
            : _missingPriceLabel(context);
    final statusColor = owned
        ? const Color(0xFF6EE7B7)
        : (effectiveAvailableInShop && hasValidPrice)
            ? const Color(0xFFFFD166)
            : const Color(0xFFFFB4A9);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 92,
              color: const Color(0xFF0B1222),
              child: CustomPaint(
                painter: _TrailPreviewPainter(skin: preview),
              ),
            ),
          ),
          _TrailDetailsFooter(
            trailId: trailId,
            trailName: safeTrailName,
            description: safeDescription,
            statusText: statusText,
            statusColor: statusColor,
            isLegendary: isLegendary,
            owned: owned,
            effectiveAvailableInShop: effectiveAvailableInShop,
            hasValidPrice: hasValidPrice,
            effectiveCost: effectiveCost,
            actionButton: _buildActionButton(
              context,
              effectiveAvailableInShop: effectiveAvailableInShop,
              effectiveCost: effectiveCost,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required bool effectiveAvailableInShop,
    required int effectiveCost,
  }) {
    if (selected) {
      return Chip(
        visualDensity: VisualDensity.compact,
        label: Text(context.l10n.shopEquipped),
      );
    }
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(120, 36),
        foregroundColor: const Color(0xFFEAF2FF),
        disabledForegroundColor: const Color(0xFFD3E1FA),
        disabledBackgroundColor: const Color(0xFF32425E),
        backgroundColor: const Color(0xFF2E5D97),
      ),
      onPressed: owned
          ? onEquip
          : (effectiveAvailableInShop && canBuy)
              ? () => unawaited(onBuy())
              : null,
      child: Text(
        owned
            ? context.l10n.shopEquip
            : effectiveAvailableInShop
                ? context.l10n.shopBuyCoins(effectiveCost)
                : _unavailableButtonLabel(context),
      ),
    );
  }

  String _missingDescriptionLabel(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode.toLowerCase();
    return language == 'es'
        ? 'Sin descripcion disponible'
        : 'Description not available';
  }

  String _missingPriceLabel(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode.toLowerCase();
    return language == 'es' ? 'Precio no disponible' : 'Price unavailable';
  }

  String _unavailableButtonLabel(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode.toLowerCase();
    return language == 'es' ? 'No disponible' : 'Unavailable';
  }

  String _humanizeTrailId(String id) {
    final cleaned = id.trim().replaceFirst(RegExp(r'^trail_'), '');
    if (cleaned.isEmpty) return 'Trail';
    final words = cleaned.split('_').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'Trail';
    return words
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class _TrailDetailsFooter extends StatelessWidget {
  const _TrailDetailsFooter({
    required this.trailId,
    required this.trailName,
    required this.description,
    required this.statusText,
    required this.statusColor,
    required this.isLegendary,
    required this.owned,
    required this.effectiveAvailableInShop,
    required this.hasValidPrice,
    required this.effectiveCost,
    required this.actionButton,
  });

  final String trailId;
  final String trailName;
  final String description;
  final String statusText;
  final Color statusColor;
  final bool isLegendary;
  final bool owned;
  final bool effectiveAvailableInShop;
  final bool hasValidPrice;
  final int effectiveCost;
  final Widget actionButton;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          margin: const EdgeInsets.only(top: 10),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF132440),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF35517A),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trailName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isLegendary) ...[
                    const SizedBox(width: 6),
                    const Text(
                      'LEGENDARY',
                      style: TextStyle(
                        color: Color(0xFFFFD166),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFE4EEFF),
                  fontSize: 12.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      statusText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  actionButton,
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrailShopMeta {
  const _TrailShopMeta({
    required this.id,
    required this.displayName,
    required this.description,
    required this.costCoins,
    required this.availableInShop,
    required this.presentInCatalog,
    required this.preview,
  });

  final String id;
  final String displayName;
  final String description;
  final int? costCoins;
  final bool availableInShop;
  final bool presentInCatalog;
  final TrailSkinConfig preview;
}

class _TrailPreviewPainter extends CustomPainter {
  const _TrailPreviewPainter({required this.skin});

  final TrailSkinConfig skin;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.06, size.height * 0.65)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.15,
        size.width * 0.42,
        size.height * 0.9,
        size.width * 0.58,
        size.height * 0.45,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.1,
        size.width * 0.86,
        size.height * 0.6,
        size.width * 0.94,
        size.height * 0.36,
      );

    final width = max(3.0, size.height * 0.13 * skin.thickness);
    if (skin.glow) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = width * 1.6
          ..color = skin.primaryColor.withOpacity(0.22),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = width
        ..shader = LinearGradient(
          colors: [
            skin.primaryColor.withOpacity(0.95),
            skin.secondaryColor.withOpacity(0.92),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Offset.zero & size),
    );

    final tagPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 8, 56, 20),
        const Radius.circular(6),
      ),
      tagPaint,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: skin.name,
        style: const TextStyle(
          color: Color(0xFF9FB0D3),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      ellipsis: '...',
    )..layout(maxWidth: 52);
    tp.paint(canvas, const Offset(12, 12));

    if (skin.renderType == TrailRenderType.web ||
        skin.renderType == TrailRenderType.webLegendary) {
      for (var i = 0; i < 6; i++) {
        final t = i / 5.0;
        final p = _sample(path, size, t);
        if (p == null) continue;
        final tint = skin.renderType == TrailRenderType.webLegendary
            ? (i.isEven ? const Color(0xFFFF5BBE) : const Color(0xFF6EE7FF))
            : Colors.white;
        canvas.drawLine(
          p + Offset(0, -size.height * 0.08),
          p + Offset(0, size.height * 0.08),
          Paint()
            ..strokeWidth = 1.4
            ..color = tint.withOpacity(0.55),
        );
      }
    }

    if (skin.renderType == TrailRenderType.comic ||
        skin.renderType == TrailRenderType.comicSpiderverseV2 ||
        skin.renderType == TrailRenderType.comicSpiderverseRebuilt ||
        skin.renderType == TrailRenderType.comicSpiderverse ||
        skin.renderType == TrailRenderType.electricArc ||
        skin.renderType == TrailRenderType.plasma) {
      const dots = 7;
      for (var i = 0; i < dots; i++) {
        final t = (i + 1) / (dots + 1);
        final p = _sample(path, size, t);
        if (p == null) continue;
        canvas.drawCircle(
          p + Offset(0, (i.isEven ? 1 : -1) * size.height * 0.08),
          size.height * 0.03,
          Paint()..color = skin.secondaryColor.withOpacity(0.42),
        );
      }
    }
  }

  Offset? _sample(Path path, Size size, double t) {
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) return null;
    final metric = metrics.first;
    final tan = metric.getTangentForOffset(metric.length * t.clamp(0.0, 1.0));
    return tan?.position;
  }

  @override
  bool shouldRepaint(covariant _TrailPreviewPainter oldDelegate) {
    return oldDelegate.skin.id != skin.id;
  }
}
