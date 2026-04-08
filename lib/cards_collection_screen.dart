import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'coins_service.dart';
import 'l10n/l10n.dart';
import 'skin_catalog_service.dart';
import 'ui/components/network_image_compat.dart';
import 'ui/components/zip_collectible_card.dart';

class CardsCollectionScreen extends StatelessWidget {
  const CardsCollectionScreen({
    super.key,
    required this.coinsService,
    required this.skinCatalogService,
  });

  final CoinsService coinsService;
  final SkinCatalogService skinCatalogService;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AnimatedBuilder(
      animation: Listenable.merge([coinsService, skinCatalogService]),
      builder: (context, _) {
        final owned = coinsService.ownedSkins;
        final cards = skinCatalogService.items.where((item) {
          if (item.id.trim().isEmpty) return false;
          if (item.id.trim() == 'pointer_default') return false;
          return owned.contains(item.id);
        }).toList(growable: false)
          ..sort((a, b) => _rarityRank(a.rarity).compareTo(_rarityRank(b.rarity)));

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            title: Text(l10n.cardsCollectionTitle),
          ),
          body: cards.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.cardsCollectionEmpty,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF9FB0D3),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    childAspectRatio: 2 / 3.24,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, i) {
                    final skin = cards[i];
                    final rarity = _toCardRarity(skin.rarity);
                    final isEquipped = coinsService.selectedSkin == skin.id;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _InteractiveCollectibleCard(
                            rarity: rarity,
                            front: ZipCollectibleCard(
                              rarity: rarity,
                              artwork: _CardArtwork(
                                skin: skin,
                                skinCatalogService: skinCatalogService,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          skin.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              _rarityLabel(rarity, l10n),
                              style: TextStyle(
                                color: _rarityColor(rarity),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            if (isEquipped)
                              Text(
                                l10n.shopEquipped,
                                style: const TextStyle(
                                  color: Color(0xFF8AB4FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }

  int _rarityRank(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'legendary':
        return 0;
      case 'epic':
        return 1;
      case 'rare':
        return 2;
      default:
        return 3;
    }
  }

  ZipCardRarity _toCardRarity(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'legendary':
        return ZipCardRarity.legendary;
      case 'epic':
        return ZipCardRarity.epic;
      case 'rare':
        return ZipCardRarity.rare;
      default:
        return ZipCardRarity.common;
    }
  }

  String _rarityLabel(ZipCardRarity rarity, dynamic l10n) {
    switch (rarity) {
      case ZipCardRarity.legendary:
        return l10n.cardsRarityLegendary;
      case ZipCardRarity.epic:
        return l10n.cardsRarityEpic;
      case ZipCardRarity.rare:
        return l10n.cardsRarityRare;
      case ZipCardRarity.common:
        return l10n.cardsRarityCommon;
    }
  }

  Color _rarityColor(ZipCardRarity rarity) {
    switch (rarity) {
      case ZipCardRarity.legendary:
        return const Color(0xFFFFC766);
      case ZipCardRarity.epic:
        return const Color(0xFFFF6FD8);
      case ZipCardRarity.rare:
        return const Color(0xFF74B6FF);
      case ZipCardRarity.common:
        return const Color(0xFFA6B1C7);
    }
  }

}

class _InteractiveCollectibleCard extends StatefulWidget {
  const _InteractiveCollectibleCard({
    required this.rarity,
    required this.front,
  });

  final ZipCardRarity rarity;
  final Widget front;

  @override
  State<_InteractiveCollectibleCard> createState() =>
      _InteractiveCollectibleCardState();
}

class _InteractiveCollectibleCardState extends State<_InteractiveCollectibleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
    value: 0,
  );

  bool _dragging = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleFlip,
      onHorizontalDragStart: (_) => _dragging = true,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: (_) => _onDragEnd(),
      onHorizontalDragCancel: _onDragEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * math.pi;
          final showFront = angle <= math.pi / 2;
          final effectiveAngle = showFront ? angle : angle - math.pi;
          final face = showFront
              ? widget.front
              : _CollectibleCardBack(rarity: widget.rarity);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(effectiveAngle),
            child: face,
          );
        },
      ),
    );
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || box.size.width <= 0) return;
    final delta = (details.primaryDelta ?? 0) / box.size.width;
    _controller.value = (_controller.value + (delta * -1.05)).clamp(0.0, 1.0);
  }

  void _onDragEnd() {
    final target = _controller.value >= 0.5 ? 1.0 : 0.0;
    _animateTo(target);
    _dragging = false;
  }

  void _toggleFlip() {
    if (_dragging) return;
    final target = _controller.value >= 0.5 ? 0.0 : 1.0;
    _animateTo(target);
  }

  void _animateTo(double target) {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }
}

class _CollectibleCardBack extends StatelessWidget {
  const _CollectibleCardBack({required this.rarity});

  final ZipCardRarity rarity;

  @override
  Widget build(BuildContext context) {
    final rarityLabel = _rarityText(rarity);
    final rarityColor = _rarityTone(rarity);
    final assetPath = _backAssetByRarity(rarity);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: rarityColor.withOpacity(0.9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF131E33),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.style_rounded,
                  color: Color(0xFF93A7CC),
                  size: 40,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.38),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.52),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: rarityColor.withOpacity(0.9)),
                    ),
                    child: Text(
                      rarityLabel,
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.swipe_rounded,
                    size: 16,
                    color: Color(0xFFDFE8FA),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _backAssetByRarity(ZipCardRarity rarity) {
    switch (rarity) {
      case ZipCardRarity.rare:
        return 'assets/ui/cards/rare_back.png';
      case ZipCardRarity.epic:
        return 'assets/ui/cards/epic_card.png';
      case ZipCardRarity.legendary:
        return 'assets/ui/cards/legendary-card.png';
      case ZipCardRarity.common:
        return 'assets/ui/cards/common_back.png';
    }
  }

  static String _rarityText(ZipCardRarity rarity) {
    switch (rarity) {
      case ZipCardRarity.common:
        return 'COMMON';
      case ZipCardRarity.rare:
        return 'RARE';
      case ZipCardRarity.epic:
        return 'EPIC';
      case ZipCardRarity.legendary:
        return 'LEGENDARY';
    }
  }

  static Color _rarityTone(ZipCardRarity rarity) {
    switch (rarity) {
      case ZipCardRarity.common:
        return const Color(0xFFA6B1C7);
      case ZipCardRarity.rare:
        return const Color(0xFF74B6FF);
      case ZipCardRarity.epic:
        return const Color(0xFFFF6FD8);
      case ZipCardRarity.legendary:
        return const Color(0xFFFFC766);
    }
  }
}

class _CardArtwork extends StatefulWidget {
  const _CardArtwork({
    required this.skin,
    required this.skinCatalogService,
  });

  final SkinCatalogItem skin;
  final SkinCatalogService skinCatalogService;

  @override
  State<_CardArtwork> createState() => _CardArtworkState();
}

class _CardArtworkState extends State<_CardArtwork> {
  final List<String> _candidates = <String>[];
  int _index = 0;
  bool _loaded = false;
  bool _advanceQueued = false;

  @override
  void initState() {
    super.initState();
    _prepareCandidates();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox.shrink();
    }
    if (_candidates.isEmpty || _index >= _candidates.length) {
      return const SizedBox.shrink();
    }
    final current = _candidates[_index];
    if (current.startsWith('assets/')) {
      return Image.asset(
        current,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) {
          _queueNextCandidate();
          return const SizedBox.shrink();
        },
      );
    }
    return _buildRemoteImage(current);
  }

  Widget _buildRemoteImage(String url) {
    if (kIsWeb) {
      return buildNetworkImageCompat(
        url: url,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        fallback: Builder(
          builder: (context) {
            _queueNextCandidate();
            return const SizedBox.shrink();
          },
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) {
        _queueNextCandidate();
        return const SizedBox.shrink();
      },
    );
  }

  void _queueNextCandidate() {
    if (_advanceQueued) return;
    _advanceQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _advanceQueued = false;
      _nextCandidate();
    });
  }

  void _nextCandidate() {
    if (!mounted) return;
    if (_index + 1 >= _candidates.length) return;
    setState(() => _index += 1);
  }

  Future<void> _prepareCandidates() async {
    final orderedRawCandidates = <String>[
      widget.skin.cardImagePath,
      widget.skin.previewImagePath,
      widget.skin.thumbnailPath,
      widget.skin.bannerImagePath,
      ..._inferTarjetaCandidatesFromPath(widget.skin.fullImagePath),
      ..._inferTarjetaCandidatesFromPath(widget.skin.previewImagePath),
      ..._inferTarjetaCandidatesFromPath(widget.skin.thumbnailPath),
      ..._inferTarjetaCandidatesFromPath(widget.skin.imagePath),
      widget.skin.fullImagePath,
      widget.skin.imagePath,
    ];

    for (final raw in orderedRawCandidates) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final resolved = await widget.skinCatalogService.resolveDownloadUrl(
            trimmed,
            context: 'cards:${widget.skin.id}',
          ) ??
          widget.skinCatalogService.toRenderablePath(trimmed);
      final candidate = resolved.trim();
      if (candidate.isEmpty) continue;
      if (!_candidates.contains(candidate)) {
        _candidates.add(candidate);
      }
      for (final variant in _extensionVariants(candidate)) {
        if (variant.isEmpty) continue;
        if (!_candidates.contains(variant)) {
          _candidates.add(variant);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _index = 0;
    });
  }

  List<String> _inferTarjetaCandidatesFromPath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return const <String>[];
    final normalized = trimmed.replaceAll('\\', '/');
    final out = <String>{};

    String withSuffix(String source, String suffix) {
      final q = source.indexOf('?');
      final base = q >= 0 ? source.substring(0, q) : source;
      final query = q >= 0 ? source.substring(q) : '';
      final dot = base.lastIndexOf('.');
      if (dot <= 0) return '$base$suffix$query';
      final stem = base.substring(0, dot);
      final ext = base.substring(dot);
      return '$stem$suffix$ext$query';
    }

    final tarjeta = withSuffix(normalized, '-tarjeta');
    out.add(tarjeta);
    out.add(tarjeta.replaceAll('-thumb-tarjeta.', '-tarjeta.'));
    out.add(tarjeta.replaceAll('-banner-tarjeta.', '-tarjeta.'));
    out.add(tarjeta.replaceAll('-preview-tarjeta.', '-tarjeta.'));
    if (tarjeta.toLowerCase().contains('.webp')) {
      out.add(tarjeta.replaceAll('.webp', '.png'));
      out.add(tarjeta.replaceAll('.WEBP', '.png'));
    }
    return out.toList(growable: false);
  }

  List<String> _extensionVariants(String source) {
    final lower = source.toLowerCase();
    if (lower.startsWith('assets/')) return const <String>[];
    if (!(lower.startsWith('http://') || lower.startsWith('https://'))) {
      return const <String>[];
    }

    final q = source.indexOf('?');
    final base = q >= 0 ? source.substring(0, q) : source;
    final query = q >= 0 ? source.substring(q) : '';
    final dot = base.lastIndexOf('.');
    if (dot <= 0) return const <String>[];

    final stem = base.substring(0, dot);
    final ext = base.substring(dot).toLowerCase();
    if (ext == '.webp') {
      return <String>['$stem.png$query', '$stem.jpg$query'];
    }
    if (ext == '.png') {
      return <String>['$stem.webp$query', '$stem.jpg$query'];
    }
    if (ext == '.jpg' || ext == '.jpeg') {
      return <String>['$stem.png$query', '$stem.webp$query'];
    }
    return const <String>[];
  }
}

