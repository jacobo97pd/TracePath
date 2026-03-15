import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import '../../coins_service.dart';
import 'game_button.dart';
import 'network_image_compat.dart';

class SkinCard extends StatelessWidget {
  const SkinCard({
    super.key,
    required this.skin,
    required this.owned,
    required this.equipped,
    required this.canBuy,
    required this.onActionTap,
    this.onPreviewTap,
    this.featured = false,
    this.compactActionOnly = false,
  });

  final CoinSkinDef skin;
  final bool owned;
  final bool equipped;
  final bool canBuy;
  final VoidCallback? onActionTap;
  final VoidCallback? onPreviewTap;
  final bool featured;
  final bool compactActionOnly;

  @override
  Widget build(BuildContext context) {
    final rarity = _rarityLabel();
    final rarityColor = _rarityColor(rarity);
    final price = skin.costCoins ?? 0;
    final actionLabel = equipped
        ? 'Equipped'
        : owned
            ? 'Equip'
            : 'Buy $price';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rarityColor,
          width: (rarity == 'Rare' || rarity == 'Epic' || rarity == 'Legendary')
              ? 1.4
              : 1.0,
        ),
        boxShadow: [
          if (rarity == 'Epic')
            BoxShadow(
              color: const Color(0x449B59FF),
              blurRadius: 12,
              spreadRadius: 0.5,
            ),
          if (rarity == 'Legendary')
            BoxShadow(
              color: const Color(0x55FFB800),
              blurRadius: 18,
              spreadRadius: 1.2,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                color: const Color(0xFF0D121A),
                child: InkWell(
                  onTap: onPreviewTap,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _buildSkinImage(),
                        ),
                      ),
                      if (onPreviewTap != null)
                        const Positioned(
                          right: 6,
                          top: 6,
                          child: Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            skin.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            rarity,
            style: TextStyle(
              color: rarityColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (compactActionOnly)
            SizedBox(
              width: double.infinity,
              child: GameButton(
                label: actionLabel,
                outlined: owned && !equipped,
                expanded: true,
                onTap: equipped ? null : (owned || canBuy ? onActionTap : null),
              ),
            )
          else
            GameButton(
              label: actionLabel,
              outlined: owned && !equipped,
              expanded: true,
              onTap: equipped ? null : (owned || canBuy ? onActionTap : null),
            ),
        ],
      ),
    );
  }

  String _rarityLabel() {
    final raw = skin.rarity.trim();
    if (raw.isEmpty) return skin.isPremium ? 'Legendary' : 'Common';
    final normalized = raw.toLowerCase();
    if (normalized == 'legendary') return 'Legendary';
    if (normalized == 'epic') return 'Epic';
    if (normalized == 'rare') return 'Rare';
    return 'Common';
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'Rare':
        return const Color(0xFF3A8DFF);
      case 'Epic':
        return const Color(0xFF9B59FF);
      case 'Legendary':
        return const Color(0xFFFFB800);
      case 'Common':
      default:
        return const Color(0xFF8A8F98);
    }
  }

  Widget _buildSkinImage() {
    final preview = skin.previewPath?.trim() ?? '';
    final full = skin.assetPath?.trim() ?? '';
    if (preview.isEmpty && full.isEmpty) {
      return const Icon(
        Icons.gesture_rounded,
        color: Colors.white70,
        size: 38,
      );
    }
    final primaryPath = preview.isNotEmpty ? preview : full;
    final fallbackPath = preview.isNotEmpty && full.isNotEmpty ? full : null;
    final primaryLabel = preview.isNotEmpty ? 'thumb' : 'full-primary';
    return _buildPathImage(
      primaryPath,
      sourceLabel: primaryLabel,
      fallbackPath: fallbackPath,
    );
  }

  Widget _buildPathImage(
    String path, {
    required String sourceLabel,
    String? fallbackPath,
  }) {
    final fit = kIsWeb ? BoxFit.contain : BoxFit.cover;
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: fit);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      if (kDebugMode) {
        debugPrint('[ShopImage][$sourceLabel] start: $path');
      }
      if (kIsWeb) {
        return buildNetworkImageCompat(
          url: path,
          fit: fit,
          filterQuality: FilterQuality.medium,
          fallback:
              const Icon(Icons.broken_image_outlined, color: Colors.white70),
        );
      }
      return _TimedNetworkImage(
        url: path,
        fit: fit,
        sourceLabel: sourceLabel,
        onFallback: (failedUrl) {
          final extFallback = _extensionFallbackUrl(failedUrl);
          if (extFallback != null && extFallback != failedUrl) {
            return _buildPathImage(
              extFallback,
              sourceLabel: '$sourceLabel-ext-fallback',
            );
          }
          if (fallbackPath != null && fallbackPath != failedUrl) {
            return _buildPathImage(
              fallbackPath,
              sourceLabel: 'full-fallback',
            );
          }
          return const Icon(Icons.broken_image_outlined, color: Colors.white70);
        },
      );
    }
    if (path.startsWith('data:image')) {
      final comma = path.indexOf(',');
      if (comma > 0 && comma < path.length - 1) {
        final bytes = base64Decode(path.substring(comma + 1));
        return Image.memory(bytes, fit: fit);
      }
    }
    if (kIsWeb) {
      return const Icon(Icons.image_not_supported_outlined,
          color: Colors.white70);
    }
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, __, ___) {
        if (fallbackPath != null && fallbackPath != path) {
          return _buildPathImage(
            fallbackPath,
            sourceLabel: 'file-fallback',
          );
        }
        return const Icon(Icons.broken_image_outlined, color: Colors.white70);
      },
    );
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

class _TimedNetworkImage extends StatefulWidget {
  const _TimedNetworkImage({
    required this.url,
    required this.fit,
    required this.sourceLabel,
    required this.onFallback,
  });

  final String url;
  final BoxFit fit;
  final String sourceLabel;
  final Widget Function(String failedUrl) onFallback;

  @override
  State<_TimedNetworkImage> createState() => _TimedNetworkImageState();
}

class _TimedNetworkImageState extends State<_TimedNetworkImage> {
  late final Stopwatch _sw;
  bool _successLogged = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      widget.url,
      fit: widget.fit,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (!_successLogged && (wasSynchronouslyLoaded || frame != null)) {
          _successLogged = true;
          if (kDebugMode) {
            debugPrint(
              '[ShopImage][${widget.sourceLabel}] loaded in ${_sw.elapsedMilliseconds}ms: ${widget.url}',
            );
          }
        }
        return child;
      },
      errorBuilder: (_, __, ___) {
        if (!_failed) {
          _failed = true;
          if (kDebugMode) {
            debugPrint(
              '[ShopImage][${widget.sourceLabel}] FAILED after ${_sw.elapsedMilliseconds}ms: ${widget.url}',
            );
          }
        }
        return widget.onFallback(widget.url);
      },
    );
  }
}
