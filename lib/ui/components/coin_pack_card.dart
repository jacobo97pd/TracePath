import 'package:flutter/material.dart';

import '../../shop/coin_pack.dart';

class CoinPackCard extends StatelessWidget {
  const CoinPackCard({
    super.key,
    required this.pack,
    required this.assetPath,
    required this.onBuy,
  });

  final CoinPack pack;
  final String assetPath;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final title = pack.title.trim().isEmpty ? 'Coin Pack' : pack.title;
    final description = pack.description.trim();
    final hasBonus = pack.bonusCoins > 0;
    final effectiveTotal = pack.totalCoins > 0
        ? pack.totalCoins
        : (pack.coins + pack.bonusCoins);
    final tag = pack.tag.trim();
    final tagLower = tag.toLowerCase();
    final isBestValue = tagLower == 'best value';
    final isPopular = tagLower == 'popular';
    final isSpecial = isBestValue ||
        tagLower.contains('ultimate') ||
        tagLower.contains('epic');

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 250;
        final imageHeight = compact ? 82.0 : 98.0;
        final titleSize = compact ? 12.0 : 13.0;
        final coinsSize = compact ? 14.0 : 15.0;
        final bonusSize = compact ? 10.0 : 11.0;
        final buttonHeight = compact ? 30.0 : 34.0;
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1B2538),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isBestValue
                  ? const Color(0xFFD4AF37)
                  : (isSpecial
                      ? const Color(0x6658A6FF)
                      : const Color(0xFF2D3D59)),
              width: isBestValue ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isBestValue
                    ? const Color(0x55D4AF37)
                    : (isSpecial
                        ? const Color(0x332E7BFF)
                        : const Color(0x22000000)),
                blurRadius: isBestValue ? 20 : (isSpecial ? 18 : 12),
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: imageHeight,
                        color: const Color(0xFF101A2E),
                        child: _CoinPackImage(assetPath: assetPath),
                      ),
                    ),
                    if (tag.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _TagBadge(
                          label: tag,
                          popular: isPopular,
                          bestValue: isBestValue,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!compact && description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF9EB3D8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${pack.coins} Coins',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: coinsSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (hasBonus) ...[
                      const SizedBox(height: 2),
                      Text(
                        '+${pack.bonusCoins} Bonus',
                        style: TextStyle(
                          color: const Color(0xFF6DE6A6),
                          fontSize: bonusSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Total: $effectiveTotal',
                          style: const TextStyle(
                            color: Color(0xFF9FB0D3),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: onBuy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          textStyle: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: compact ? 11 : 12,
                          ),
                        ),
                        child: Text(
                          pack.priceLabel.trim().isEmpty
                              ? 'Coming soon'
                              : pack.priceLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({
    required this.label,
    required this.popular,
    required this.bestValue,
  });

  final String label;
  final bool popular;
  final bool bestValue;

  @override
  Widget build(BuildContext context) {
    final border = bestValue
        ? const Color(0xFFD4AF37)
        : (popular ? const Color(0xFF4AA8FF) : const Color(0xFF3B82F6));
    final text = bestValue
        ? const Color(0xFFFFE59A)
        : (popular ? const Color(0xFFBEE3FF) : const Color(0xFF9DD4FF));
    final bg = bestValue
        ? const Color(0xFF3A2E12)
        : (popular ? const Color(0xFF132B4D) : const Color(0xFF102648));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _CoinPackImage extends StatelessWidget {
  const _CoinPackImage({
    required this.assetPath,
  });

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final path = assetPath.trim();
    if (path.isEmpty || !path.startsWith('assets/')) {
      return const _ImageFallback();
    }
    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const _ImageFallback(),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.monetization_on_outlined,
        color: Color(0xFF8CA4CF),
        size: 30,
      ),
    );
  }
}
