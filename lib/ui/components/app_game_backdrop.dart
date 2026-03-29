import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppGameBackdrop extends StatelessWidget {
  const AppGameBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.background,
                  Color(0xFF091628),
                ],
                stops: [0.0, 0.56, 1.0],
              ),
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: _ArcadePatternPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class AppGameOverlay extends StatelessWidget {
  const AppGameOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _ArcadeGlowPainter(),
      ),
    );
  }
}

class _ArcadePatternPainter extends CustomPainter {
  const _ArcadePatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.accent.withOpacity(0.03)
      ..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final node = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.accentSecondary.withOpacity(0.05);
    for (int i = 0; i < 26; i++) {
      final x = (i * 97.0) % size.width;
      final y = (i * 131.0) % size.height;
      canvas.drawCircle(Offset(x, y), 2.2, node);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArcadeGlowPainter extends CustomPainter {
  const _ArcadeGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final topGlow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.42));
    canvas.drawRect(rect, topGlow);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.accentSecondary.withOpacity(0.08);
    final center = Offset(size.width * 0.8, size.height * 0.14);
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(center, 42 + (i * 18), ring);
    }

    final particle = Paint()
      ..color = AppColors.accent.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 20; i++) {
      final x = (math.sin(i * 0.77) * 0.5 + 0.5) * size.width;
      final y = (math.cos(i * 1.17) * 0.5 + 0.5) * size.height * 0.92;
      canvas.drawCircle(Offset(x, y), 1.4, particle);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
