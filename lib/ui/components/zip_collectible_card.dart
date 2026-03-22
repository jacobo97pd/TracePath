import 'dart:math' as math;

import 'package:flutter/material.dart';

enum ZipCardRarity { common, rare, epic, legendary }

class ZipCollectibleCard extends StatefulWidget {
  const ZipCollectibleCard({
    super.key,
    required this.rarity,
    this.artwork,
    this.seasonLabel = 'S1',
    this.gradeLabel = 'ZIP GRADE',
    this.gradeValue = '10',
    this.padding = const EdgeInsets.all(12),
  });

  final ZipCardRarity rarity;
  final Widget? artwork;
  final String seasonLabel;
  final String gradeLabel;
  final String gradeValue;
  final EdgeInsets padding;

  @override
  State<ZipCollectibleCard> createState() => _ZipCollectibleCardState();
}

class _ZipCollectibleCardState extends State<ZipCollectibleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return RepaintBoundary(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _ZipSlabShellPainter(rarity: widget.rarity, t: t),
                child: Padding(
                  padding: widget.padding,
                  child: Column(
                    children: [
                      _TopSlabLabelBar(
                        rarity: widget.rarity,
                        seasonLabel: widget.seasonLabel,
                        gradeLabel: widget.gradeLabel,
                        gradeValue: widget.gradeValue,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0x8EFFFFFF),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 5),
                                spreadRadius: -2,
                              ),
                            ],
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0x1CFFFFFF),
                                Color(0x08FFFFFF),
                              ],
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: _backgroundGradient(widget.rarity),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (widget.artwork != null)
                                    widget.artwork!
                                  else
                                    CustomPaint(
                                      painter: _ZipPathEnergyPainter(
                                        rarity: widget.rarity,
                                        t: t,
                                      ),
                                    ),
                                  if (widget.rarity == ZipCardRarity.epic ||
                                      widget.rarity == ZipCardRarity.legendary)
                                    IgnorePointer(
                                      child: CustomPaint(
                                        painter: _ZipParticlePainter(
                                          rarity: widget.rarity,
                                          t: t,
                                        ),
                                      ),
                                    ),
                                  IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white.withOpacity(0.12),
                                            Colors.transparent,
                                            Colors.transparent,
                                            Colors.white.withOpacity(0.04),
                                          ],
                                          stops: const [0.0, 0.16, 0.75, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
    );
  }
}

class _ZipSlabShellPainter extends CustomPainter {
  _ZipSlabShellPainter({
    required this.rarity,
    required this.t,
  });

  final ZipCardRarity rarity;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = RRect.fromRectAndRadius(
      rect.deflate(1.2),
      const Radius.circular(24),
    );
    final mid = RRect.fromRectAndRadius(
      rect.deflate(4.5),
      const Radius.circular(21),
    );
    final inner = RRect.fromRectAndRadius(
      rect.deflate(8.5),
      const Radius.circular(18),
    );

    final slabBody = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x58F8FBFF),
          Color(0x1CE6ECF5),
          Color(0x3AF3F6FC),
        ],
        stops: [0.0, 0.52, 1.0],
      ).createShader(rect);
    canvas.drawRRect(outer, slabBody);

    final contour1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xB8FFFFFF);
    final contour2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0x66DCE3EE);
    canvas.drawRRect(mid, contour1);
    canvas.drawRRect(inner, contour2);

    final accent = _slabAccent(rarity, t);
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = rarity == ZipCardRarity.legendary ? 1.8 : 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withOpacity(0.36),
          accent.withOpacity(0.12),
        ],
      ).createShader(rect);
    canvas.drawRRect(inner.deflate(0.3), accentPaint);

    final topSpecular = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.02),
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.26),
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, 5, size.width - 12, size.height * 0.22),
        const Radius.circular(14),
      ),
      topSpecular,
    );

    final streakPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.22),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(rect);
    final streak = Path()
      ..moveTo(size.width * 0.06, size.height * 0.1)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * (0.08 + math.sin(t * math.pi * 2) * 0.01),
        size.width * 0.56,
        size.height * 0.14,
      )
      ..lineTo(size.width * 0.52, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.12,
        size.width * 0.07,
        size.height * 0.14,
      )
      ..close();
    canvas.drawPath(streak, streakPaint);

    final edgeShade = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.black.withOpacity(0.18);
    canvas.drawRRect(outer, edgeShade);
  }

  @override
  bool shouldRepaint(covariant _ZipSlabShellPainter oldDelegate) {
    return oldDelegate.rarity != rarity || oldDelegate.t != t;
  }
}

class _TopSlabLabelBar extends StatelessWidget {
  const _TopSlabLabelBar({
    required this.rarity,
    required this.seasonLabel,
    required this.gradeLabel,
    required this.gradeValue,
  });

  final ZipCardRarity rarity;
  final String seasonLabel;
  final String gradeLabel;
  final String gradeValue;

  @override
  Widget build(BuildContext context) {
    final accent = _slabAccent(rarity, 0);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xA7FFFFFF), width: 0.9),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xEAF8FBFF),
            Color(0xCCEDF2FA),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accent.withOpacity(0.26)),
            ),
            child: Text(
              seasonLabel,
              style: const TextStyle(
                color: Color(0xFF2B3444),
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Container(
              height: 9,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.09),
                    Colors.black.withOpacity(0.03),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _EmbeddedZipGradeBadge(label: gradeLabel, value: gradeValue),
        ],
      ),
    );
  }
}

class _EmbeddedZipGradeBadge extends StatelessWidget {
  const _EmbeddedZipGradeBadge({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDAE1EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF101820),
              fontSize: 8.2,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.35,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF05070B),
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZipPathEnergyPainter extends CustomPainter {
  _ZipPathEnergyPainter({
    required this.rarity,
    required this.t,
  });

  final ZipCardRarity rarity;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.68)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.26,
        size.width * 0.50,
        size.height * 0.88,
        size.width * 0.64,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.16,
        size.width * 0.88,
        size.height * 0.64,
        size.width * 0.92,
        size.height * 0.36,
      );

    final wobble = (math.sin(t * math.pi * 2) * 0.5 + 0.5);
    final baseWidth = switch (rarity) {
      ZipCardRarity.common => size.width * 0.07,
      ZipCardRarity.rare => size.width * 0.08,
      ZipCardRarity.epic => size.width * 0.09,
      ZipCardRarity.legendary => size.width * (0.1 + wobble * 0.01),
    };

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = baseWidth * (rarity.index >= ZipCardRarity.epic.index ? 1.9 : 1.5)
      ..color = _pathGlow(rarity, t).withOpacity(rarity == ZipCardRarity.common ? 0.22 : 0.34);
    canvas.drawPath(path, glowPaint);

    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = baseWidth
      ..shader = _pathGradient(rarity, t).createShader(Offset.zero & size);
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant _ZipPathEnergyPainter oldDelegate) {
    return oldDelegate.rarity != rarity || oldDelegate.t != t;
  }
}

class _ZipParticlePainter extends CustomPainter {
  _ZipParticlePainter({
    required this.rarity,
    required this.t,
  });

  final ZipCardRarity rarity;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final count = rarity == ZipCardRarity.legendary ? 16 : 10;
    for (var i = 0; i < count; i++) {
      final seed = i * 0.73;
      final x = (math.sin((t + seed) * math.pi * 2 * 0.7) * 0.42 + 0.5) * size.width;
      final y = (math.cos((t + seed * 1.9) * math.pi * 2 * 0.55) * 0.36 + 0.5) * size.height;
      final alpha = (0.22 + 0.22 * math.sin((t + seed) * math.pi * 2)).clamp(0.08, 0.42);
      final r = rarity == ZipCardRarity.legendary ? 1.8 : 1.4;
      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()
          ..color = (i.isEven ? const Color(0xFF8FF3FF) : const Color(0xFFFF78DF))
              .withOpacity(alpha.toDouble()),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ZipParticlePainter oldDelegate) {
    return oldDelegate.rarity != rarity || oldDelegate.t != t;
  }
}

LinearGradient _backgroundGradient(ZipCardRarity rarity) {
  return switch (rarity) {
    ZipCardRarity.common => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D1118), Color(0xFF080B11)],
      ),
    ZipCardRarity.rare => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0E1220), Color(0xFF090E1A), Color(0xFF111225)],
      ),
    ZipCardRarity.epic => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF101229), Color(0xFF0C1020), Color(0xFF141127)],
      ),
    ZipCardRarity.legendary => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F101B), Color(0xFF0A0D16), Color(0xFF13141E)],
      ),
  };
}

Color _slabAccent(ZipCardRarity rarity, double t) {
  final pulse = 0.86 + 0.14 * math.sin(t * math.pi * 2);
  return switch (rarity) {
    ZipCardRarity.common => const Color(0xFFB6BFCE),
    ZipCardRarity.rare =>
      Color.lerp(const Color(0xFF8CB2F1), const Color(0xFFA091E7), pulse)!,
    ZipCardRarity.epic =>
      Color.lerp(const Color(0xFF7EDCEB), const Color(0xFFC47DD5), pulse)!,
    ZipCardRarity.legendary =>
      Color.lerp(const Color(0xFFECC476), const Color(0xFF90D8EF), pulse)!,
  };
}

Color _pathGlow(ZipCardRarity rarity, double t) {
  final pulse = 0.86 + 0.14 * math.sin(t * math.pi * 2);
  return switch (rarity) {
    ZipCardRarity.common => const Color(0xFF7D91B0),
    ZipCardRarity.rare => Color.lerp(const Color(0xFF69B7FF), const Color(0xFF8A72FF), pulse)!,
    ZipCardRarity.epic => Color.lerp(const Color(0xFF5BEBFF), const Color(0xFFFF66DB), pulse)!,
    ZipCardRarity.legendary => Color.lerp(const Color(0xFFFFD16A), const Color(0xFF58ECFF), pulse)!,
  };
}

LinearGradient _pathGradient(ZipCardRarity rarity, double t) {
  return switch (rarity) {
    ZipCardRarity.common => const LinearGradient(
        colors: [Color(0xFFC4D0E4), Color(0xFFD3DDF2)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    ZipCardRarity.rare => const LinearGradient(
        colors: [Color(0xFFB9E4FF), Color(0xFFA5B8FF), Color(0xFFD8C6FF)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    ZipCardRarity.epic => const LinearGradient(
        colors: [Color(0xFF62ECFF), Color(0xFF95B0FF), Color(0xFFFF66D7)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
    ZipCardRarity.legendary => LinearGradient(
        colors: [
          const Color(0xFFFFD772),
          Color.lerp(const Color(0xFF4CF2FF), const Color(0xFF73A9FF), t)!,
          const Color(0xFFFF69D6),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
  };
}
