import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'trail_skin.dart';

class TrailSnapshot {
  const TrailSnapshot({
    required this.points,
    required this.opacity,
    required this.widthScale,
    required this.frame,
    required this.chromaOffset,
  });

  final List<Offset> points;
  final double opacity;
  final double widthScale;
  final int frame;
  final Offset chromaOffset;
}

class TrailRenderContext {
  const TrailRenderContext({
    required this.canvas,
    required this.boardRect,
    required this.pathCurve,
    required this.pathPoints,
    required this.headPosition,
    required this.cellSize,
    required this.baseStrokeWidth,
    required this.trailSkin,
    required this.phase,
    required this.visualPhase,
    required this.visualFrame,
    required this.solved,
    required this.clipPath,
    required this.nowSeconds,
    this.snapshots = const <TrailSnapshot>[],
    this.smokeSprites = const <ui.Image>[],
    this.iconSprites = const <ui.Image>[],
  });

  final Canvas canvas;
  final Rect boardRect;
  final Path pathCurve;
  final List<Offset> pathPoints;
  final Offset? headPosition;
  final double cellSize;
  final double baseStrokeWidth;
  final TrailSkinConfig trailSkin;
  final double phase;
  final double visualPhase;
  final int visualFrame;
  final bool solved;
  final Path clipPath;
  final double nowSeconds;
  final List<TrailSnapshot> snapshots;
  final List<ui.Image> smokeSprites;
  final List<ui.Image> iconSprites;
}

class TrailRenderer {
  const TrailRenderer._();

  static void paintBase(TrailRenderContext ctx) {
    final skin = ctx.trailSkin;
    if (skin.renderType == TrailRenderType.punkRiff) {
      _paintPunkRiffBase(ctx);
      return;
    }
    if (skin.renderType == TrailRenderType.graffiti) {
      _paintGraffitiBase(ctx);
      return;
    }
    if (skin.renderType == TrailRenderType.halftoneExplosion) {
      _paintHalftoneExplosionBase(ctx);
      return;
    }
    if (skin.renderType == TrailRenderType.stickerBomb) {
      _paintStickerBombBase(ctx);
      return;
    }
    if (skin.renderType == TrailRenderType.glitchPrint) {
      _paintGlitchPrintBase(ctx);
      return;
    }
    final widthStep =
        skin.renderType == TrailRenderType.comic ? _comicWidthStep(ctx) : 1.0;
    final width = ctx.baseStrokeWidth * skin.thickness * widthStep;
    final startColor = skin.primaryColor.withOpacity(skin.opacity);
    final endColor = ctx.solved
        ? Color.lerp(skin.secondaryColor, Colors.white, 0.15)!
        : skin.secondaryColor.withOpacity(skin.opacity);

    final pathPaint = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..shader = (skin.renderType == TrailRenderType.comic
              ? LinearGradient(
                  colors: <Color>[
                    const Color(0xFF121A2C).withOpacity(skin.opacity),
                    const Color(0xFF9333EA).withOpacity(skin.opacity * 0.78),
                    const Color(0xFF22D3EE).withOpacity(skin.opacity * 0.82),
                    const Color(0xFFFDE047).withOpacity(skin.opacity * 0.72),
                  ],
                  stops: const <double>[0.0, 0.34, 0.7, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [startColor, endColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ))
          .createShader(ctx.boardRect);

    if (skin.glow) {
      final glowPaint = Paint()
        ..strokeWidth = width + max(2, ctx.cellSize * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..color = skin.primaryColor.withOpacity(0.24);
      ctx.canvas.drawPath(ctx.pathCurve, glowPaint);
    }

    ctx.canvas.drawPath(ctx.pathCurve, pathPaint);
  }

  static void paintVfx(TrailRenderContext ctx) {
    switch (ctx.trailSkin.renderType) {
      case TrailRenderType.basic:
        return;
      case TrailRenderType.fire:
        _paintFireVfx(ctx);
        return;
      case TrailRenderType.laser:
        _paintLaserVfx(ctx);
        return;
      case TrailRenderType.plasma:
        _paintPlasmaTrail(ctx);
        return;
      case TrailRenderType.glitch:
        _paintGlitchTrail(ctx);
        return;
      case TrailRenderType.ink:
        _paintInkTrail(ctx);
        return;
      case TrailRenderType.magma:
        _paintMagmaTrail(ctx);
        return;
      case TrailRenderType.ice:
        _paintIceTrail(ctx);
        return;
      case TrailRenderType.galaxy:
        _paintGalaxyTrail(ctx);
        return;
      case TrailRenderType.speedForce:
        _paintSpeedForceTrail(ctx);
        return;
      case TrailRenderType.web:
        _paintWebTrail(ctx);
        return;
      case TrailRenderType.inkBrush:
        _paintInkBrushTrail(ctx);
        return;
      case TrailRenderType.electricArc:
        _paintElectricArcTrail(ctx);
        return;
      case TrailRenderType.goldenThread:
        _paintGoldenThreadTrail(ctx);
        return;
      case TrailRenderType.goldenAura:
        _paintGoldenAuraTrail(ctx);
        return;
      case TrailRenderType.holidaySpark:
        _paintHolidaySparkTrail(ctx);
        return;
      case TrailRenderType.upside:
        _paintUpsideTrail(ctx);
        return;
      case TrailRenderType.binaryRain:
        _paintBinaryRainTrail(ctx);
        return;
      case TrailRenderType.smoke:
        _paintSmokeTrail(ctx);
        return;
      case TrailRenderType.water:
      case TrailRenderType.electric:
        _paintGenericParticleVfx(ctx);
        return;
      case TrailRenderType.comic:
        _paintComicVfx(ctx);
        return;
      case TrailRenderType.punkRiff:
        _paintPunkRiffTrail(ctx);
        return;
      case TrailRenderType.graffiti:
        _paintGraffitiTrail(ctx);
        return;
      case TrailRenderType.halftoneExplosion:
        _paintHalftoneExplosionTrail(ctx);
        return;
      case TrailRenderType.stickerBomb:
        _paintStickerBombTrail(ctx);
        return;
      case TrailRenderType.glitchPrint:
        _paintGlitchPrintTrail(ctx);
        return;
    }
  }

  static void _paintPunkRiffBase(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.punkRiff;
    final pulse =
        1 + sin(ctx.phase * pi * 2 * cfg.pulseSpeed) * cfg.pulseStrength;
    final jitter = _jitterPolyline(
      ctx.pathPoints,
      amount: ctx.cellSize * 0.028 * (1 + cfg.glitchStrength),
      phase: ctx.phase * pi * 2,
    );
    final jitterPath = _buildSmoothPath(jitter);
    final width =
        ctx.baseStrokeWidth * ctx.trailSkin.thickness * cfg.coreWidth * pulse;

    final under = Paint()
      ..strokeWidth = width * 1.18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF06070B),
          Color(0xFF0F0C16),
          Color(0xFF0A0A10),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(ctx.boardRect);
    ctx.canvas.drawPath(jitterPath, under);

    final mass = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFFFF2EC9),
          Color(0xFFF91A9D),
          Color(0xFFE31286),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(ctx.boardRect)
      ..color = Colors.white.withOpacity(cfg.pinkMassOpacity);
    ctx.canvas.drawPath(jitterPath, mass);

    final segmented = Paint()
      ..strokeWidth = max(1.0, width * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = const Color(0xFFFFE84A).withOpacity(0.28);
    for (var i = 1; i < jitter.length; i += 2) {
      final a = jitter[i - 1];
      final b = jitter[i];
      final segA = Offset.lerp(a, b, 0.18)!;
      final segB = Offset.lerp(a, b, 0.62)!;
      ctx.canvas.drawLine(segA, segB, segmented);
    }
  }

  static void _paintPunkRiffTrail(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.punkRiff;
    final pulse =
        1 + sin(ctx.phase * pi * 2 * cfg.pulseSpeed) * cfg.pulseStrength;
    final path = _buildSmoothPath(ctx.pathPoints);
    final glitchPx = ctx.cellSize * cfg.glitchOffset * (1 + cfg.glitchStrength);

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);

    final yellowOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = ctx.baseStrokeWidth * 0.58
      ..color = const Color(0xFFFFE84A)
          .withOpacity(0.22 + cfg.glitchStrength * 0.36);
    final pinkOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = ctx.baseStrokeWidth * 0.56
      ..color = const Color(0xFFFF2EC9)
          .withOpacity(0.22 + cfg.glitchStrength * 0.36);
    ctx.canvas.drawPath(path.shift(Offset(glitchPx, 0)), yellowOutline);
    ctx.canvas.drawPath(path.shift(Offset(-glitchPx, 0)), pinkOutline);

    _paintPunkRiffBolts(ctx, cfg, pulse);
    _paintPunkPaperFragments(ctx, cfg, pulse);
    _paintPunkInkSplashes(ctx, cfg, pulse);
    _paintPunkHalftone(ctx, cfg);
    _paintHeadGlow(ctx, scale: 0.34, alpha: 0.16 + cfg.glitchStrength * 0.18);
    ctx.canvas.restore();
    _paintPunkIconStamps(ctx, cfg);
  }

  static void _paintGraffitiBase(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.graffiti;
    final jitter = _jitterPolyline(
      ctx.pathPoints,
      amount: ctx.cellSize * 0.035,
      phase: ctx.phase * pi * 2,
    );
    final sprayPath = _buildSmoothPath(jitter);
    final width = ctx.baseStrokeWidth * ctx.trailSkin.thickness * cfg.coreWidth;

    final under = Paint()
      ..strokeWidth = width * 1.22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = const Color(0xFF111827).withOpacity(0.68);
    ctx.canvas.drawPath(sprayPath, under);

    final palette = cfg.colorPalette.isEmpty
        ? const <Color>[
            Color(0xFFFF2EC9),
            Color(0xFF22D3EE),
            Color(0xFFFFE84A),
            Color(0xFFA3FF12),
          ]
        : cfg.colorPalette;
    final gradientPaint = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: <Color>[
          palette[0 % palette.length].withOpacity(0.95),
          palette[1 % palette.length].withOpacity(0.92),
          palette[2 % palette.length].withOpacity(0.93),
          palette[3 % palette.length].withOpacity(0.9),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(ctx.boardRect);
    ctx.canvas.drawPath(sprayPath, gradientPaint);

    final grainPaint = Paint()
      ..strokeWidth = max(1.0, width * 0.16)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = Colors.white.withOpacity(0.14);
    for (var i = 1; i < jitter.length; i += 2) {
      final a = jitter[i - 1];
      final b = jitter[i];
      final s = Offset.lerp(a, b, 0.12)!;
      final e = Offset.lerp(a, b, 0.42)!;
      ctx.canvas.drawLine(s, e, grainPaint);
    }

    final glowPaint = Paint()
      ..strokeWidth = width + ctx.cellSize * 0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: <Color>[
          palette[0 % palette.length].withOpacity(0.18),
          palette[1 % palette.length].withOpacity(0.16),
          palette[2 % palette.length].withOpacity(0.14),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(ctx.boardRect);
    ctx.canvas.drawPath(sprayPath, glowPaint);
  }

  static void _paintGraffitiTrail(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.graffiti;
    final palette = cfg.colorPalette.isEmpty
        ? const <Color>[
            Color(0xFFFF2EC9),
            Color(0xFF22D3EE),
            Color(0xFFFFE84A),
            Color(0xFFA3FF12),
            Color(0xFFF8FAFC),
          ]
        : cfg.colorPalette;

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    _paintGraffitiSprayParticles(ctx, cfg, palette);
    _paintGraffitiSplashes(ctx, cfg, palette);
    _paintGraffitiDrips(ctx, cfg, palette);
    _paintHeadGlow(ctx, scale: 0.34, alpha: 0.14);
    ctx.canvas.restore();
  }

  static void _paintGraffitiSprayParticles(
    TrailRenderContext ctx,
    GraffitiTrailConfig cfg,
    List<Color> palette,
  ) {
    final count =
        max(12, (ctx.pathPoints.length * cfg.sprayParticleFrequency * 3.0).round());
    final ttl = cfg.sprayParticleLifetime.clamp(0.25, 1.6);
    for (var i = 0; i < count; i++) {
      final lifeT = ((ctx.nowSeconds / ttl) + i * 0.173) % 1.0;
      final fade = (1.0 - lifeT).clamp(0.0, 1.0);
      if (fade < 0.03) continue;
      final t = ((ctx.visualFrame * 0.031) + i * 0.097) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      final tan = _sampleTangent(ctx.pathPoints, t);
      if (p == null || tan == null) continue;
      final n = Offset(-tan.dy, tan.dx);
      final spread = ctx.cellSize * (0.05 + _rand(9000 + i, 0, 0.16));
      final center = p +
          n * _rand(9020 + i, -1, 1) * spread +
          tan * _rand(9040 + i, -1, 1) * spread * 0.5;
      final radius = ctx.cellSize * _rand(9060 + i, 0.008, 0.032);
      final c = palette[i % palette.length].withOpacity(0.18 + fade * 0.5);
      ctx.canvas.drawCircle(center, radius, Paint()..color = c);
    }
  }

  static void _paintGraffitiSplashes(
    TrailRenderContext ctx,
    GraffitiTrailConfig cfg,
    List<Color> palette,
  ) {
    final count = max(4, (ctx.pathPoints.length * cfg.splashFrequency).round());
    for (var i = 0; i < count; i++) {
      final t = ((ctx.visualFrame * 0.019) + i * 0.211) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      if (p == null) continue;
      final size = ctx.cellSize * _rand(9300 + i, 0.05, 0.11);
      final center = p +
          Offset(
            _rand(9320 + i, -1, 1) * ctx.cellSize * 0.18,
            _rand(9340 + i, -1, 1) * ctx.cellSize * 0.18,
          );
      final splash = Path();
      final petals = 6 + (i % 4);
      for (var k = 0; k < petals; k++) {
        final ang = (k / petals) * pi * 2;
        final rr = size * _rand(9360 + i * 13 + k, 0.55, 1.12);
        final pt = center + Offset(cos(ang) * rr, sin(ang) * rr);
        if (k == 0) {
          splash.moveTo(pt.dx, pt.dy);
        } else {
          splash.lineTo(pt.dx, pt.dy);
        }
      }
      splash.close();
      ctx.canvas.drawPath(
        splash,
        Paint()..color = palette[(i + 2) % palette.length].withOpacity(0.24),
      );
    }
  }

  static void _paintGraffitiDrips(
    TrailRenderContext ctx,
    GraffitiTrailConfig cfg,
    List<Color> palette,
  ) {
    final count = max(2, (ctx.pathPoints.length * cfg.dripFrequency).round());
    for (var i = 0; i < count; i++) {
      final t = ((ctx.visualFrame * 0.023) + i * 0.29) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      if (p == null) continue;
      final len = ctx.cellSize * _rand(9600 + i, 0.08, 0.24);
      final width = ctx.cellSize * _rand(9620 + i, 0.012, 0.026);
      final start = p +
          Offset(
            _rand(9640 + i, -1, 1) * ctx.cellSize * 0.1,
            _rand(9660 + i, -1, 1) * ctx.cellSize * 0.04,
          );
      final end = start + Offset(0, len);
      final color = palette[(i + 3) % palette.length].withOpacity(0.28);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = color;
      ctx.canvas.drawLine(start, end, paint);
      ctx.canvas.drawCircle(end, width * 0.72, Paint()..color = color);
    }
  }

  static void _paintHalftoneExplosionBase(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.halftoneExplosion;
    final pulse = 1 + sin(ctx.phase * pi * 2 * 1.8) * 0.1;
    final width = ctx.baseStrokeWidth * ctx.trailSkin.thickness * cfg.coreWidth * pulse;
    final jitter = _jitterPolyline(
      ctx.pathPoints,
      amount: ctx.cellSize * 0.018,
      phase: ctx.phase * pi * 2,
    );
    final path = _buildSmoothPath(jitter);

    final glow = Paint()
      ..strokeWidth = width + ctx.cellSize * 0.09
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = const Color(0x66FFB703);
    ctx.canvas.drawPath(path, glow);

    final base = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFFFFE84A),
          Color(0xFFFFB703),
          Color(0xFFFF3B30),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(ctx.boardRect);
    ctx.canvas.drawPath(path, base);
  }

  static void _paintHalftoneExplosionTrail(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.halftoneExplosion;
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    _paintHalftoneDots(ctx, cfg);
    _paintExplosionBursts(ctx, cfg);
    _paintImpactFlashes(ctx, cfg);
    ctx.canvas.restore();
  }

  static void _paintHalftoneDots(
    TrailRenderContext ctx,
    HalftoneExplosionTrailConfig cfg,
  ) {
    final count = max(6, (ctx.pathPoints.length * 0.22).round());
    final dotRadius = max(1.0, ctx.cellSize * cfg.halftoneSize);
    final colors = <Color>[
      const Color(0xFFFFE84A),
      const Color(0xFFFF3B30),
      const Color(0xFFFFFFFF),
    ];
    for (var i = 0; i < count; i++) {
      final t = ((ctx.visualFrame * 0.019) + i * 0.173) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      final tan = _sampleTangent(ctx.pathPoints, t);
      if (p == null || tan == null) continue;
      final n = Offset(-tan.dy, tan.dx);
      final spread = ctx.cellSize * (0.12 + _rand(12000 + i, 0, 0.15));
      final c0 = p + n * spread;
      final c1 = p - n * spread;
      final color = colors[i % colors.length].withOpacity(0.26);
      ctx.canvas.drawCircle(c0, dotRadius, Paint()..color = color);
      ctx.canvas.drawCircle(c1, dotRadius * 0.9, Paint()..color = color);
    }
  }

  static void _paintExplosionBursts(
    TrailRenderContext ctx,
    HalftoneExplosionTrailConfig cfg,
  ) {
    final count = max(4, (ctx.pathPoints.length * cfg.burstFrequency).round());
    final ttl = cfg.burstLifetime.clamp(0.25, 1.4);
    for (var i = 0; i < count; i++) {
      final lifeT = ((ctx.nowSeconds / ttl) + i * 0.233) % 1.0;
      final fade = (1.0 - lifeT).clamp(0.0, 1.0);
      if (fade < 0.06) continue;
      final t = ((ctx.visualFrame * 0.027) + i * 0.187) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      if (p == null) continue;
      final center = p +
          Offset(
            _rand(12200 + i, -1, 1) * ctx.cellSize * 0.12,
            _rand(12220 + i, -1, 1) * ctx.cellSize * 0.12,
          );
      final rays = 7 + (i % 4);
      final inner = ctx.cellSize * _rand(12240 + i, 0.03, 0.05);
      final outer = ctx.cellSize * _rand(12260 + i, 0.09, 0.15);
      final rot = _rand(12280 + i, -pi, pi);
      final burst = Path();
      for (var k = 0; k < rays * 2; k++) {
        final rr = (k.isEven ? outer : inner) * (0.88 + fade * 0.2);
        final ang = rot + (k / (rays * 2)) * pi * 2;
        final pt = center + Offset(cos(ang) * rr, sin(ang) * rr);
        if (k == 0) {
          burst.moveTo(pt.dx, pt.dy);
        } else {
          burst.lineTo(pt.dx, pt.dy);
        }
      }
      burst.close();
      final fillColor = (i.isEven
              ? const Color(0xFFFFE84A)
              : const Color(0xFFFF3B30))
          .withOpacity(0.16 + fade * 0.34);
      final strokeColor = const Color(0xFF111827).withOpacity(0.26 + fade * 0.32);
      ctx.canvas.drawPath(burst, Paint()..color = fillColor);
      ctx.canvas.drawPath(
        burst,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.0, ctx.cellSize * 0.012)
          ..color = strokeColor,
      );
    }
  }

  static void _paintImpactFlashes(
    TrailRenderContext ctx,
    HalftoneExplosionTrailConfig cfg,
  ) {
    if (ctx.pathPoints.length < 3) return;
    final maxFlashes = max(2, (ctx.pathPoints.length * cfg.impactFlashFrequency).round());
    var flashed = 0;
    for (var i = 1; i < ctx.pathPoints.length - 1; i++) {
      if (flashed >= maxFlashes) break;
      final a = ctx.pathPoints[i - 1];
      final b = ctx.pathPoints[i];
      final c = ctx.pathPoints[i + 1];
      final v1 = b - a;
      final v2 = c - b;
      final l1 = v1.distance;
      final l2 = v2.distance;
      if (l1 <= 0.001 || l2 <= 0.001) continue;
      final n1 = v1 / l1;
      final n2 = v2 / l2;
      final dot = (n1.dx * n2.dx + n1.dy * n2.dy).clamp(-1.0, 1.0);
      final turn = acos(dot);
      if (turn < 0.38) continue;
      if (_rand(13000 + i * 3 + ctx.visualFrame, 0, 1) >
          cfg.impactFlashFrequency + 0.12) {
        continue;
      }
      final center = b;
      final len = ctx.cellSize * (0.12 + turn * 0.1);
      final flashPaint = Paint()
        ..strokeWidth = max(1.2, ctx.cellSize * 0.018)
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFF7D6).withOpacity(0.6);
      ctx.canvas.drawLine(
        center + Offset(-len, 0),
        center + Offset(len, 0),
        flashPaint,
      );
      ctx.canvas.drawLine(
        center + Offset(0, -len),
        center + Offset(0, len),
        flashPaint,
      );
      flashed++;
    }
  }

  static void _paintStickerBombBase(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.stickerBomb;
    final width = ctx.baseStrokeWidth * ctx.trailSkin.thickness * cfg.coreWidth;
    final path = _buildSmoothPath(
      _jitterPolyline(
        ctx.pathPoints,
        amount: ctx.cellSize * 0.012,
        phase: ctx.phase * pi * 2,
      ),
    );

    final glow = Paint()
      ..strokeWidth = width + ctx.cellSize * 0.08
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = ctx.trailSkin.primaryColor.withOpacity(0.18);
    ctx.canvas.drawPath(path, glow);

    final base = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: <Color>[
          ctx.trailSkin.primaryColor.withOpacity(0.95),
          ctx.trailSkin.secondaryColor.withOpacity(0.9),
          const Color(0xFFFFE84A).withOpacity(0.88),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(ctx.boardRect);
    ctx.canvas.drawPath(path, base);
  }

  static void _paintStickerBombTrail(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.stickerBomb;
    final palette = <Color>[
      const Color(0xFFFF2EC9),
      const Color(0xFF22D3EE),
      const Color(0xFFFFE84A),
      const Color(0xFFA3FF12),
      const Color(0xFFF8FAFC),
    ];
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    _paintStickerParticles(ctx, cfg, palette);
    _paintStickerClusters(ctx, cfg, palette);
    ctx.canvas.restore();
  }

  static void _paintStickerParticles(
    TrailRenderContext ctx,
    StickerBombTrailConfig cfg,
    List<Color> palette,
  ) {
    final count = max(8, (ctx.pathPoints.length * cfg.stickerFrequency * 2.2).round());
    final ttl = cfg.stickerLifetime.clamp(0.25, 1.5);
    for (var i = 0; i < count; i++) {
      final lifeT = ((ctx.nowSeconds / ttl) + i * 0.197) % 1.0;
      final fade = (1 - lifeT).clamp(0.0, 1.0);
      if (fade < 0.05) continue;
      final t = ((ctx.visualFrame * 0.023) + i * 0.141) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      final tan = _sampleTangent(ctx.pathPoints, t);
      if (p == null || tan == null) continue;
      final n = Offset(-tan.dy, tan.dx);
      final center = p +
          n * _rand(15000 + i, -1, 1) * ctx.cellSize * 0.17 +
          tan * _rand(15020 + i, -1, 1) * ctx.cellSize * 0.08;
      final rotation =
          _rand(15040 + i, -cfg.rotationVariance * pi, cfg.rotationVariance * pi);
      final scale = 1 + _rand(15060 + i, -cfg.scaleVariance, cfg.scaleVariance);
      final size = ctx.cellSize * (0.145 * scale.clamp(0.7, 1.55));
      final color = palette[i % palette.length].withOpacity(0.24 + fade * 0.52);
      _drawSticker(canvas: ctx.canvas, center: center, size: size, rotation: rotation, color: color);
    }
  }

  static void _paintStickerClusters(
    TrailRenderContext ctx,
    StickerBombTrailConfig cfg,
    List<Color> palette,
  ) {
    final clusterCount = max(2, (ctx.pathPoints.length * cfg.stickerFrequency * 0.8).round());
    for (var i = 0; i < clusterCount; i++) {
      final t = ((ctx.visualFrame * 0.017) + i * 0.31) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      if (p == null) continue;
      final center = p +
          Offset(
            _rand(15100 + i, -1, 1) * ctx.cellSize * 0.14,
            _rand(15120 + i, -1, 1) * ctx.cellSize * 0.14,
          );
      final stickersInCluster = 3 + (i % 3);
      for (var j = 0; j < stickersInCluster; j++) {
        final ang = (j / stickersInCluster) * pi * 2 + _rand(15140 + i + j, -0.3, 0.3);
        final r = ctx.cellSize * _rand(15160 + i + j, 0.05, 0.12);
        final pos = center + Offset(cos(ang) * r, sin(ang) * r);
        final rotation = _rand(
          15180 + i + j,
          -cfg.rotationVariance * pi,
          cfg.rotationVariance * pi,
        );
        final scale = 1 + _rand(15200 + i + j, -cfg.scaleVariance, cfg.scaleVariance);
        final size = ctx.cellSize * (0.12 * scale.clamp(0.7, 1.55));
        final color = palette[(i + j + 2) % palette.length].withOpacity(0.32);
        _drawSticker(canvas: ctx.canvas, center: pos, size: size, rotation: rotation, color: color);
      }
    }
  }

  static void _drawSticker({
    required Canvas canvas,
    required Offset center,
    required double size,
    required double rotation,
    required Color color,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final rect = Rect.fromCenter(center: Offset.zero, width: size * 1.1, height: size * 0.84);
    final sticker = RRect.fromRectAndRadius(rect, Radius.circular(size * 0.2));
    canvas.drawRRect(
      sticker,
      Paint()..color = color,
    );
    canvas.drawRRect(
      sticker,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.8, size * 0.08)
        ..color = Colors.black.withOpacity(0.32),
    );
    final mark = Path()
      ..moveTo(-size * 0.18, size * 0.02)
      ..lineTo(0, -size * 0.18)
      ..lineTo(size * 0.18, size * 0.02)
      ..lineTo(0, size * 0.2)
      ..close();
    canvas.drawPath(
      mark,
      Paint()..color = Colors.white.withOpacity(0.34),
    );
    canvas.restore();
  }

  static void _paintGlitchPrintBase(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.glitchPrint;
    final width = ctx.baseStrokeWidth * ctx.trailSkin.thickness * cfg.coreWidth;
    final jitter = _jitterPolyline(
      ctx.pathPoints,
      amount: ctx.cellSize * 0.016,
      phase: ctx.phase * pi * 2,
    );
    final path = _buildSmoothPath(jitter);

    final under = Paint()
      ..strokeWidth = width * 1.16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = const Color(0xFF0A0A0F).withOpacity(0.58);
    ctx.canvas.drawPath(path, under);

    final base = Paint()
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = const Color(0xFFF8FAFC).withOpacity(0.9);
    ctx.canvas.drawPath(path, base);
  }

  static void _paintGlitchPrintTrail(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.glitchPrint;
    final path = _buildSmoothPath(ctx.pathPoints);
    final shiftPx = ctx.cellSize * cfg.rgbShift;
    final jitter = sin(ctx.phase * pi * 2 * 3.1) * ctx.cellSize * cfg.glitchOffset;
    final offA = Offset(shiftPx + jitter, -shiftPx * 0.35);
    final offB = Offset(-shiftPx - jitter * 0.6, shiftPx * 0.45);

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);

    final cyan = Paint()
      ..strokeWidth = ctx.baseStrokeWidth * 0.58
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = const Color(0xFF22D3EE).withOpacity(0.45);
    final magenta = Paint()
      ..strokeWidth = ctx.baseStrokeWidth * 0.56
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = const Color(0xFFFF2EC9).withOpacity(0.45);
    ctx.canvas.drawPath(path.shift(offA), cyan);
    ctx.canvas.drawPath(path.shift(offB), magenta);

    _paintGlitchPrintFragments(ctx, cfg);
    _paintGlitchPrintNoiseStrips(ctx, cfg);
    _paintHeadGlow(
      ctx,
      scale: 0.3,
      alpha: (0.1 + cfg.noiseIntensity * 0.25).clamp(0.08, 0.24),
    );
    ctx.canvas.restore();
  }

  static void _paintGlitchPrintFragments(
    TrailRenderContext ctx,
    GlitchPrintTrailConfig cfg,
  ) {
    final count = max(8, (ctx.pathPoints.length * cfg.fragmentFrequency * 2.2).round());
    final s = cfg.fragmentSize.clamp(0.02, 0.2);
    for (var i = 0; i < count; i++) {
      final t = ((ctx.visualFrame * 0.041) + i * 0.103) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      final tan = _sampleTangent(ctx.pathPoints, t);
      if (p == null || tan == null) continue;
      final n = Offset(-tan.dy, tan.dx);
      final center = p +
          n * _rand(17000 + i, -1, 1) * ctx.cellSize * 0.18 +
          tan * _rand(17020 + i, -1, 1) * ctx.cellSize * 0.1;
      final w = ctx.cellSize * _rand(17040 + i, s * 0.8, s * 1.7);
      final h = ctx.cellSize * _rand(17060 + i, s * 0.42, s * 1.06);
      final jitterX = _rand(17080 + i + ctx.visualFrame, -1, 1) *
          ctx.cellSize *
          cfg.glitchOffset *
          0.6;
      final rect = Rect.fromCenter(
        center: center + Offset(jitterX, 0),
        width: w,
        height: h,
      );
      final color = i.isEven
          ? const Color(0xFF22D3EE).withOpacity(0.28)
          : const Color(0xFFFF2EC9).withOpacity(0.28);
      ctx.canvas.drawRect(rect, Paint()..color = color);
      ctx.canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(0.8, h * 0.16)
          ..color = const Color(0xFFF8FAFC).withOpacity(0.24),
      );
    }
  }

  static void _paintGlitchPrintNoiseStrips(
    TrailRenderContext ctx,
    GlitchPrintTrailConfig cfg,
  ) {
    final board = ctx.boardRect;
    final strips = max(2, (cfg.noiseIntensity * 12).round());
    for (var i = 0; i < strips; i++) {
      final y = _rand(17100 + i + ctx.visualFrame, board.top, board.bottom);
      final h = ctx.cellSize * _rand(17120 + i, 0.018, 0.05);
      final jumpX = _rand(17140 + i + ctx.visualFrame, -1, 1) *
          ctx.cellSize *
          cfg.glitchOffset *
          1.2;
      final w = board.width * _rand(17160 + i, 0.2, 0.72);
      final x = _rand(17180 + i, board.left, board.right - w);
      final rect = Rect.fromLTWH(x + jumpX, y, w, h);
      final c = (i % 3 == 0)
          ? const Color(0xFF22D3EE).withOpacity(0.2)
          : (i % 3 == 1)
              ? const Color(0xFFFF2EC9).withOpacity(0.2)
              : const Color(0xFFF8FAFC).withOpacity(0.16);
      ctx.canvas.drawRect(rect, Paint()..color = c);
    }
  }

  static void _paintPunkRiffBolts(
    TrailRenderContext ctx,
    PunkRiffTrailConfig cfg,
    double pulse,
  ) {
    final count = max(7, (ctx.pathPoints.length * cfg.yellowBoltFrequency).round());
    final boltPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = max(1.0, ctx.cellSize * 0.026)
      ..color = const Color(0xFFFFE84A).withOpacity(0.7);
    final boltGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = max(2.0, ctx.cellSize * 0.05)
      ..color = const Color(0x66FFE84A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    for (var i = 0; i < count; i++) {
      final t = ((ctx.visualFrame * 0.037) + i * 0.121) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      final tan = _sampleTangent(ctx.pathPoints, t);
      if (p == null || tan == null) continue;
      final normal = Offset(-tan.dy, tan.dx);
      final size = ctx.cellSize * (0.08 + _rand(1900 + i, 0, 0.08) * pulse);
      final s1 = p + normal * size;
      final s2 = s1 +
          Offset(
            _rand(1930 + i, -1, 1) * size * 1.1,
            _rand(1940 + i, -1, 1) * size * 1.1,
          );
      final s3 = s2 +
          Offset(
            _rand(1950 + i, -1, 1) * size * 0.95,
            _rand(1960 + i, -1, 1) * size * 0.95,
          );
      final pathBolt = Path()
        ..moveTo(s1.dx, s1.dy)
        ..lineTo(s2.dx, s2.dy)
        ..lineTo(s3.dx, s3.dy);
      ctx.canvas.drawPath(pathBolt, boltGlow);
      ctx.canvas.drawPath(pathBolt, boltPaint);
    }
  }

  static void _paintPunkPaperFragments(
    TrailRenderContext ctx,
    PunkRiffTrailConfig cfg,
    double pulse,
  ) {
    final count =
        max(5, (ctx.pathPoints.length * cfg.paperFragmentFrequency).round());
    for (var i = 0; i < count; i++) {
      final t = ((ctx.visualFrame * 0.029) + i * 0.163 + _rand(2200 + i, 0, 1)) %
          1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      final tan = _sampleTangent(ctx.pathPoints, t);
      if (p == null || tan == null) continue;
      final normal = Offset(-tan.dy, tan.dx);
      final center = p +
          normal * (_rand(2240 + i, -1, 1) * ctx.cellSize * 0.16) +
          Offset(
            _rand(2260 + i, -1, 1) * ctx.cellSize * 0.06,
            _rand(2280 + i, -1, 1) * ctx.cellSize * 0.06,
          );
      final w = ctx.cellSize * (0.09 + _rand(2300 + i, 0, 0.08) * pulse);
      final h = ctx.cellSize * (0.054 + _rand(2320 + i, 0, 0.06));
      final rot = _rand(2340 + i, -pi, pi);
      ctx.canvas.save();
      ctx.canvas.translate(center.dx, center.dy);
      ctx.canvas.rotate(rot);
      final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
      final fill = Paint()..color = const Color(0xFFF2EACF).withOpacity(0.36);
      ctx.canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(h * 0.18)),
        fill,
      );
      final linePaint = Paint()
        ..strokeWidth = max(0.7, h * 0.08)
        ..color = const Color(0xFF111111).withOpacity(0.45)
        ..strokeCap = StrokeCap.round;
      for (var l = 0; l < 3; l++) {
        final y = -h * 0.22 + l * h * 0.22;
        ctx.canvas.drawLine(
          Offset(-w * 0.34, y),
          Offset(w * 0.34, y + _rand(2360 + i + l, -1, 1) * h * 0.04),
          linePaint,
        );
      }
      ctx.canvas.restore();
    }
  }

  static void _paintPunkInkSplashes(
    TrailRenderContext ctx,
    PunkRiffTrailConfig cfg,
    double pulse,
  ) {
    final count = max(6, (ctx.pathPoints.length * cfg.inkSplashFrequency).round());
    for (var i = 0; i < count; i++) {
      final t = ((ctx.visualFrame * 0.033) + i * 0.149) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      if (p == null) continue;
      final center = p +
          Offset(
            _rand(2600 + i, -1, 1) * ctx.cellSize * 0.17,
            _rand(2620 + i, -1, 1) * ctx.cellSize * 0.17,
          );
      final r = ctx.cellSize * (0.03 + _rand(2640 + i, 0, 0.045) * pulse);
      final color = <Color>[
        const Color(0xFF000000),
        const Color(0xFFE41798),
        const Color(0xFFFFE84A),
        const Color(0xFF1A1A1A),
      ][i % 4]
          .withOpacity(0.28 + _rand(2660 + i, 0, 0.24));
      ctx.canvas.drawCircle(center, r, Paint()..color = color);
    }
  }

  static void _paintPunkHalftone(TrailRenderContext ctx, PunkRiffTrailConfig cfg) {
    if (ctx.pathPoints.length < 2) return;
    const count = 4;
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFE84A).withOpacity(cfg.halftoneOpacity);
    for (var i = 0; i < count; i++) {
      final t = ((ctx.visualFrame * 0.025) + i * 0.27) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      if (p == null) continue;
      final cluster = Rect.fromCenter(
        center: p + Offset(_rand(2800 + i, -1, 1) * ctx.cellSize * 0.1, 0),
        width: ctx.cellSize * 0.28,
        height: ctx.cellSize * 0.2,
      );
      final step = max(2.0, ctx.cellSize * 0.04);
      for (double y = cluster.top + step; y <= cluster.bottom; y += step) {
        for (double x = cluster.left + step; x <= cluster.right; x += step) {
          if ((((x / step) + (y / step)).floor()) % 2 != 0) continue;
          ctx.canvas.drawCircle(Offset(x, y), step * 0.16, dotPaint);
        }
      }
    }
  }

  static void _paintPunkIconStamps(
    TrailRenderContext ctx,
    PunkRiffTrailConfig cfg,
  ) {
    final sprites = ctx.iconSprites;
    if (sprites.isEmpty || ctx.pathPoints.length < 2) return;

    final pathLength = _polylineLength(ctx.pathPoints);
    if (pathLength <= 0.001) return;

    final spacing = max(8.0, ctx.cellSize * cfg.iconStampSpacing);
    final maxVisibleDistance = pathLength;
    final minDistance = max(0.0, pathLength - maxVisibleDistance);
    final firstSlot = (minDistance / spacing).floor();
    final lastSlot = (pathLength / spacing).floor();
    const maxStamps = 7;
    final startSlot = max(firstSlot, lastSlot - 36);
    final cols = max(1, (ctx.boardRect.width / ctx.cellSize).round());
    final rows = max(1, (ctx.boardRect.height / ctx.cellSize).round());
    final totalCells = max(1, cols * rows);
    var painted = 0;

    for (var slot = startSlot; slot <= lastSlot; slot++) {
      if (painted >= maxStamps) break;
      if (_rand(slot * 23 + 7080, 0, 1) > cfg.iconStampFrequency - 0.02) {
        continue;
      }
      final distance = slot * spacing;
      final pathAnchor = _samplePointAtDistance(ctx.pathPoints, distance);
      if (pathAnchor == null) continue;

      final age = ((lastSlot - slot) / max(1, 36)).clamp(0.0, 1.0);
      final fade = (1.0 - age * 0.78).clamp(0.0, 1.0);
      if (fade < 0.08) continue;

      final sprite = sprites[(slot % sprites.length).abs()];
      final iconScale = _rand(
        slot * 31 + 7100,
        max(0.38, cfg.iconStampScaleMin * 2.0),
        max(0.64, cfg.iconStampScaleMax * 2.1),
      ).clamp(0.34, 0.8);
      final size = ctx.cellSize * iconScale;
      final seed = slot * 37 + 9120;
      final randomCell = (_rand(seed, 0, totalCells - 0.001)).floor();
      final r = randomCell ~/ cols;
      final c = randomCell % cols;
      final cellCenter = Offset(
        (c + 0.5) * ctx.cellSize,
        (r + 0.5) * ctx.cellSize,
      );
      final lerpToPath = _rand(seed + 1, 0.18, 0.42);
      final baseCenter = Offset.lerp(cellCenter, pathAnchor, lerpToPath)!;
      final floatT = (ctx.visualFrame * 0.11) + slot * 0.37;
      final floatOffset = Offset(
        sin(floatT) * ctx.cellSize * 0.22,
        cos(floatT * 0.87) * ctx.cellSize * 0.18,
      );
      final jitterOffset = Offset(
        _rand(seed + 2, -1, 1) * ctx.cellSize * 0.16,
        _rand(seed + 3, -1, 1) * ctx.cellSize * 0.14,
      );
      final jitter = _rand(
        slot * 37 + 7120,
        -cfg.iconStampRotationJitter,
        cfg.iconStampRotationJitter,
      );
      final alpha = (cfg.iconStampOpacity * fade).clamp(0.0, 1.0);
      final board = ctx.boardRect;
      const outsideChance = 0.68;
      Offset stampedCenter = baseCenter + floatOffset + jitterOffset;
      if (_rand(seed + 7, 0, 1) < outsideChance) {
        final margin = ctx.cellSize * _rand(seed + 8, 0.25, 0.75);
        final side = (_rand(seed + 9, 0, 3.999)).floor();
        switch (side) {
          case 0:
            stampedCenter = Offset(
              _rand(seed + 10, board.left, board.right),
              board.top - margin,
            );
            break;
          case 1:
            stampedCenter = Offset(
              _rand(seed + 11, board.left, board.right),
              board.bottom + margin,
            );
            break;
          case 2:
            stampedCenter = Offset(
              board.left - margin,
              _rand(seed + 12, board.top, board.bottom),
            );
            break;
          default:
            stampedCenter = Offset(
              board.right + margin,
              _rand(seed + 13, board.top, board.bottom),
            );
            break;
        }
        stampedCenter = stampedCenter + floatOffset * 0.75;
      }
      final baseAngle = _rand(seed + 4, -pi, pi);

      final shadowRect = Rect.fromCenter(
        center: stampedCenter,
        width: size * 1.22,
        height: size * 1.22,
      );
      ctx.canvas.drawRRect(
        RRect.fromRectAndRadius(shadowRect, Radius.circular(size * 0.18)),
        Paint()..color = Colors.black.withOpacity(alpha * 0.28),
      );

      _drawIconSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: stampedCenter,
        size: size,
        rotation: baseAngle + jitter,
        opacity: alpha,
      );
      painted += 1;
    }
  }

  static double _polylineLength(List<Offset> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    return total;
  }

  static Offset? _samplePointAtDistance(List<Offset> points, double distance) {
    if (points.isEmpty) return null;
    if (points.length == 1) return points.first;
    final target = distance.clamp(0.0, _polylineLength(points));
    var traveled = 0.0;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final segLen = (b - a).distance;
      if (segLen <= 0.0001) continue;
      if (traveled + segLen >= target) {
        final local = (target - traveled) / segLen;
        return Offset.lerp(a, b, local);
      }
      traveled += segLen;
    }
    return points.last;
  }

  // ignore: unused_element
  static Offset? _sampleTangentAtDistance(List<Offset> points, double distance) {
    if (points.length < 2) return null;
    final target = distance.clamp(0.0, _polylineLength(points));
    var traveled = 0.0;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final dir = b - a;
      final segLen = dir.distance;
      if (segLen <= 0.0001) continue;
      if (traveled + segLen >= target) {
        return dir / segLen;
      }
      traveled += segLen;
    }
    final fallback = points.last - points[points.length - 2];
    final len = fallback.distance;
    if (len <= 0.0001) return null;
    return fallback / len;
  }

  // ignore: unused_element
  static void _paintBinaryGlyph({
    required Canvas canvas,
    required String text,
    required Offset position,
    required double cellSize,
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: max(8, cellSize * 0.12),
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, position - Offset(painter.width * 0.5, painter.height * 0.5));
  }

  // ignore: unused_element
  static void _drawSmokeSprite(
    Canvas canvas,
    ui.Image sprite,
    Offset center,
    double size,
    double rotation,
    double opacity,
  ) {
    final src = Rect.fromLTWH(
      0,
      0,
      sprite.width.toDouble(),
      sprite.height.toDouble(),
    );
    final dst = Rect.fromCenter(center: center, width: size, height: size);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawImageRect(
      sprite,
      src,
      dst,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withOpacity(opacity),
    );
    canvas.restore();
  }

  static void _drawIconSprite({
    required Canvas canvas,
    required ui.Image sprite,
    required Offset center,
    required double size,
    required double rotation,
    required double opacity,
  }) {
    final src = Rect.fromLTWH(
      0,
      0,
      sprite.width.toDouble(),
      sprite.height.toDouble(),
    );
    final dst = Rect.fromCenter(center: center, width: size, height: size);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawImageRect(
      sprite,
      src,
      dst,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium
        ..color = Colors.white.withOpacity(opacity),
    );
    canvas.restore();
  }

  // ignore: unused_element
  static List<Offset> _offsetPolyline(List<Offset> points, double amount) {
    if (points.length < 2) return points;
    final out = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final prev = i == 0 ? points[i] : points[i - 1];
      final next = i == points.length - 1 ? points[i] : points[i + 1];
      final dir = next - prev;
      final len = dir.distance;
      if (len == 0) {
        out.add(points[i]);
        continue;
      }
      final normal = Offset(-dir.dy / len, dir.dx / len);
      out.add(points[i] + normal * amount);
    }
    return out;
  }

  static List<Offset> _jitterPolyline(
    List<Offset> points, {
    required double amount,
    required double phase,
  }) {
    if (points.length < 2 || amount <= 0) return points;
    final out = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final prev = i == 0 ? points[i] : points[i - 1];
      final next = i == points.length - 1 ? points[i] : points[i + 1];
      final dir = next - prev;
      final len = dir.distance;
      if (len <= 0.0001) {
        out.add(points[i]);
        continue;
      }
      final normal = Offset(-dir.dy / len, dir.dx / len);
      final wave = sin(phase + i * 0.93) * 0.5 + cos(phase * 0.7 + i * 1.27) * 0.5;
      out.add(points[i] + normal * (wave * amount));
    }
    return out;
  }

  static void _paintFireVfx(TrailRenderContext ctx) {
    _paintHeadGlow(ctx, scale: 0.42, alpha: 0.30);
    _paintParticles(
      ctx,
      colorA: const Color(0xFFFF6A2B),
      colorB: const Color(0xFFFFD36A),
      intensity: 1.0,
    );
  }

  static void _paintLaserVfx(TrailRenderContext ctx) {
    final shimmer = (sin(ctx.phase * pi * 2) * 0.5 + 0.5);
    final glow = Paint()
      ..strokeWidth = ctx.baseStrokeWidth * (0.45 + shimmer * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = ctx.trailSkin.primaryColor.withOpacity(0.35 + shimmer * 0.28);
    ctx.canvas.drawPath(ctx.pathCurve, glow);

    _paintHeadGlow(ctx, scale: 0.3, alpha: 0.22 + shimmer * 0.2);
    _paintParticles(
      ctx,
      colorA: const Color(0xFF6CE1FF),
      colorB: const Color(0xFF9AB9FF),
      intensity: 0.6,
    );
  }

  static void _paintGenericParticleVfx(TrailRenderContext ctx) {
    _paintParticles(
      ctx,
      colorA: ctx.trailSkin.primaryColor,
      colorB: ctx.trailSkin.secondaryColor,
      intensity: 0.5,
    );
  }

  static void _paintPlasmaTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintGlitchTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintInkTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintMagmaTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintIceTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintGalaxyTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintSpeedForceTrail(TrailRenderContext ctx) =>
      _paintLaserVfx(ctx);
  static void _paintWebTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintInkBrushTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintElectricArcTrail(TrailRenderContext ctx) =>
      _paintLaserVfx(ctx);
  static void _paintGoldenThreadTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintGoldenAuraTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintHolidaySparkTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintUpsideTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintBinaryRainTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintSmokeTrail(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);
  static void _paintComicVfx(TrailRenderContext ctx) =>
      _paintGenericParticleVfx(ctx);

  static void _paintHeadGlow(
    TrailRenderContext ctx, {
    required double scale,
    required double alpha,
  }) {
    final head = ctx.headPosition;
    if (head == null) return;
    final radius = ctx.cellSize * scale * ctx.trailSkin.effectIntensity;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          ctx.trailSkin.secondaryColor.withOpacity(alpha),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: head, radius: radius));
    ctx.canvas.drawCircle(head, radius, paint);
  }

  static void _paintParticles(
    TrailRenderContext ctx, {
    required Color colorA,
    required Color colorB,
    required double intensity,
  }) {
    final particle = ctx.trailSkin.particle;
    if (!particle.enabled || ctx.pathPoints.length < 2 || particle.count <= 0) {
      return;
    }

    final count = particle.count;
    final speed = particle.speed * ctx.trailSkin.effectIntensity;
    final spreadPx = particle.spread * (ctx.cellSize / 80.0);
    final minR = particle.minRadius * (ctx.cellSize / 70.0);
    final maxR = particle.maxRadius * (ctx.cellSize / 70.0);

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < count; i++) {
      final seed = (i + 1) * 937;
      final t = ((ctx.phase * speed) + _rand(seed, 0.0, 1.0)) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      if (p == null) continue;

      final jitter = particle.jitter * intensity;
      final dx = (_rand(seed + 11, -1, 1) * spreadPx) * jitter;
      final dy = (_rand(seed + 19, -1, 1) * spreadPx) * jitter;
      final life = ((ctx.phase * speed) + _rand(seed + 23, 0, 1)) % 1.0;
      final alpha = (1 - life).clamp(0.0, 1.0);
      final radius = minR + (maxR - minR) * _rand(seed + 29, 0, 1);
      final color = Color.lerp(colorA, colorB, _rand(seed + 37, 0, 1))!
          .withOpacity(alpha * 0.55);

      ctx.canvas.drawCircle(
        Offset(p.dx + dx, p.dy + dy),
        radius,
        Paint()..color = color,
      );
    }
    ctx.canvas.restore();
  }

  static Offset? _samplePoint(List<Offset> points, double t) {
    if (points.isEmpty) return null;
    if (points.length == 1) return points.first;
    final segments = points.length - 1;
    final scaled = (t.clamp(0.0, 1.0)) * segments;
    final idx = min(segments - 1, scaled.floor());
    final local = scaled - idx;
    return Offset.lerp(points[idx], points[idx + 1], local);
  }

  static double _rand(int seed, double minValue, double maxValue) {
    final v = (sin(seed * 12.9898) * 43758.5453) % 1.0;
    final unit = v.isNaN ? 0.0 : (v < 0 ? v + 1 : v);
    return minValue + (maxValue - minValue) * unit;
  }

  static double _comicWidthStep(TrailRenderContext ctx) {
    const pattern = <double>[0.92, 1.0, 1.08, 0.97, 1.03, 0.95];
    return pattern[ctx.visualFrame % pattern.length];
  }

  // ignore: unused_element
  static double _comicPulse(TrailRenderContext ctx) {
    const pattern = <double>[0.1, 0.44, 0.2, 0.56, 0.28, 0.48];
    return pattern[ctx.visualFrame % pattern.length];
  }

  // ignore: unused_element
  static Path _buildComicBurstPath(
    Offset center,
    double w,
    double h,
    Offset tailTip,
  ) {
    const spikes = 14;
    final pts = <Offset>[];
    for (var i = 0; i < spikes; i++) {
      final a = (i / spikes) * pi * 2;
      final rx = w * 0.5 * (i.isEven ? 1.0 : 0.83);
      final ry = h * 0.5 * (i.isEven ? 1.0 : 0.8);
      pts.add(Offset(center.dx + cos(a) * rx, center.dy + sin(a) * ry));
    }

    var minDist = double.infinity;
    var idx = 0;
    for (var i = 0; i < pts.length; i++) {
      final d = (pts[i] - tailTip).distance;
      if (d < minDist) {
        minDist = d;
        idx = i;
      }
    }
    final leftIdx = (idx - 1 + pts.length) % pts.length;
    final rightIdx = (idx + 1) % pts.length;
    final left = Offset.lerp(pts[leftIdx], pts[idx], 0.45)!;
    final right = Offset.lerp(pts[rightIdx], pts[idx], 0.45)!;

    final p = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 1; i < pts.length; i++) {
      p.lineTo(pts[i].dx, pts[i].dy);
    }
    p.lineTo(right.dx, right.dy);
    p.lineTo(tailTip.dx, tailTip.dy);
    p.lineTo(left.dx, left.dy);
    p.close();
    return p;
  }

  static Offset? _sampleTangent(List<Offset> points, double t) {
    if (points.length < 2) return null;
    final segments = points.length - 1;
    final scaled = (t.clamp(0.0, 1.0)) * segments;
    final idx = min(segments - 1, scaled.floor());
    final dir = points[idx + 1] - points[idx];
    final len = dir.distance;
    if (len <= 0.0001) return null;
    return dir / len;
  }

  static Path _buildSmoothPath(List<Offset> points) {
    final pathShape = Path();
    if (points.isEmpty) return pathShape;
    if (points.length == 1) {
      pathShape.moveTo(points.first.dx, points.first.dy);
      return pathShape;
    }
    if (points.length == 2) {
      pathShape
        ..moveTo(points.first.dx, points.first.dy)
        ..lineTo(points.last.dx, points.last.dy);
      return pathShape;
    }
    pathShape.moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final mid = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      pathShape.quadraticBezierTo(current.dx, current.dy, mid.dx, mid.dy);
    }
    final last = points.last;
    pathShape.lineTo(last.dx, last.dy);
    return pathShape;
  }
}
