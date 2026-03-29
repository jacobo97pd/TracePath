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
    this.nodeCenters = const <Offset>[],
    this.snapshots = const <TrailSnapshot>[],
    this.smokeSprites = const <ui.Image>[],
    this.iconSprites = const <ui.Image>[],
    this.webSprites = const WebTrailSprites(),
    this.webLegendarySprites = const WebLegendaryTrailSprites(),
    this.comicSpiderverseSprites = const ComicSpiderverseTrailSprites(),
    this.comicSpiderverseRebuiltSprites =
        const ComicSpiderverseRebuiltSprites(),
    this.urbanGraffitiSprites = const UrbanGraffitiTrailSprites(),
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
  final List<Offset> nodeCenters;
  final List<TrailSnapshot> snapshots;
  final List<ui.Image> smokeSprites;
  final List<ui.Image> iconSprites;
  final WebTrailSprites webSprites;
  final WebLegendaryTrailSprites webLegendarySprites;
  final ComicSpiderverseTrailSprites comicSpiderverseSprites;
  final ComicSpiderverseRebuiltSprites comicSpiderverseRebuiltSprites;
  final UrbanGraffitiTrailSprites urbanGraffitiSprites;
}

class WebTrailSprites {
  const WebTrailSprites({
    this.nodeBurst01,
    this.nodeBurst02,
    this.sparkle,
    this.microBridge,
    this.threadSoft,
    this.silkFragment,
    this.highlightStreak,
  });

  final ui.Image? nodeBurst01;
  final ui.Image? nodeBurst02;
  final ui.Image? sparkle;
  final ui.Image? microBridge;
  final ui.Image? threadSoft;
  final ui.Image? silkFragment;
  final ui.Image? highlightStreak;

  bool get hasThreadOverlay => threadSoft != null;
  bool get hasHighlight => highlightStreak != null;
  bool get hasMicroBridge => microBridge != null;
  bool get hasNodeBurst => nodeBurst01 != null || nodeBurst02 != null;
  bool get hasSparkle => sparkle != null;
  bool get hasSilkFragment => silkFragment != null;
}

class WebLegendaryTrailSprites {
  const WebLegendaryTrailSprites({
    this.nodeBurst01,
    this.nodeBurst02,
    this.sparkle,
    this.energyFlick,
    this.microBridge,
    this.highlightStreak,
    this.halftonePatch,
  });

  final ui.Image? nodeBurst01;
  final ui.Image? nodeBurst02;
  final ui.Image? sparkle;
  final ui.Image? energyFlick;
  final ui.Image? microBridge;
  final ui.Image? highlightStreak;
  final ui.Image? halftonePatch;

  bool get hasNodeBurst => nodeBurst01 != null || nodeBurst02 != null;
}

class ComicSpiderverseTrailSprites {
  const ComicSpiderverseTrailSprites({
    this.glitchStreak,
    this.offsetShadow,
    this.frameSlice,
    this.dotParticle,
    this.starParticle,
    this.burst01,
    this.burst02,
    this.inkSplash01,
    this.inkSplash02,
    this.halftone01,
    this.halftone02,
    this.bubble01,
    this.bubble02,
    this.textPow,
    this.textBzz,
  });

  final ui.Image? glitchStreak;
  final ui.Image? offsetShadow;
  final ui.Image? frameSlice;
  final ui.Image? dotParticle;
  final ui.Image? starParticle;
  final ui.Image? burst01;
  final ui.Image? burst02;
  final ui.Image? inkSplash01;
  final ui.Image? inkSplash02;
  final ui.Image? halftone01;
  final ui.Image? halftone02;
  final ui.Image? bubble01;
  final ui.Image? bubble02;
  final ui.Image? textPow;
  final ui.Image? textBzz;

  List<ui.Image> get bursts =>
      <ui.Image>[if (burst01 != null) burst01!, if (burst02 != null) burst02!];
  List<ui.Image> get inks => <ui.Image>[
        if (inkSplash01 != null) inkSplash01!,
        if (inkSplash02 != null) inkSplash02!,
      ];
  List<ui.Image> get halftones => <ui.Image>[
        if (halftone01 != null) halftone01!,
        if (halftone02 != null) halftone02!,
      ];
  List<ui.Image> get bubbles => <ui.Image>[
        if (bubble01 != null) bubble01!,
        if (bubble02 != null) bubble02!,
      ];
  List<ui.Image> get texts => <ui.Image>[
        if (textPow != null) textPow!,
        if (textBzz != null) textBzz!,
      ];
}

class ComicSpiderverseRebuiltSprites {
  const ComicSpiderverseRebuiltSprites({
    this.glitchStreak,
    this.offsetShadow,
    this.frameSlice,
    this.dotParticle,
    this.starParticle,
    this.burst01,
    this.burst02,
    this.inkSplash01,
    this.inkSplash02,
    this.halftone01,
    this.halftone02,
    this.bubble01,
    this.bubble02,
    this.textPow,
    this.textBzz,
  });

  final ui.Image? glitchStreak;
  final ui.Image? offsetShadow;
  final ui.Image? frameSlice;
  final ui.Image? dotParticle;
  final ui.Image? starParticle;
  final ui.Image? burst01;
  final ui.Image? burst02;
  final ui.Image? inkSplash01;
  final ui.Image? inkSplash02;
  final ui.Image? halftone01;
  final ui.Image? halftone02;
  final ui.Image? bubble01;
  final ui.Image? bubble02;
  final ui.Image? textPow;
  final ui.Image? textBzz;

  List<ui.Image> get bursts =>
      <ui.Image>[if (burst01 != null) burst01!, if (burst02 != null) burst02!];
  List<ui.Image> get inks => <ui.Image>[
        if (inkSplash01 != null) inkSplash01!,
        if (inkSplash02 != null) inkSplash02!,
      ];
  List<ui.Image> get halftones => <ui.Image>[
        if (halftone01 != null) halftone01!,
        if (halftone02 != null) halftone02!,
      ];
  List<ui.Image> get bubbles => <ui.Image>[
        if (bubble01 != null) bubble01!,
        if (bubble02 != null) bubble02!,
      ];
  List<ui.Image> get texts => <ui.Image>[
        if (textPow != null) textPow!,
        if (textBzz != null) textBzz!,
      ];
}

class UrbanGraffitiTrailSprites {
  const UrbanGraffitiTrailSprites({
    this.graffitiSplash,
    this.graffitiTag01,
    this.paintDrip,
    this.spraySoft,
  });

  final ui.Image? graffitiSplash;
  final ui.Image? graffitiTag01;
  final ui.Image? paintDrip;
  final ui.Image? spraySoft;
}

class TrailRenderer {
  const TrailRenderer._();

  static final Map<int, _WebBridgePattern> _webBridgeCache =
      <int, _WebBridgePattern>{};
  static int _rebuiltLastLoggedBurstFrame = -1;
  static int _rebuiltLastLoggedDecalFrame = -1;
  static int _rebuiltLastLoggedSliceFrame = -1;

  static void paintBase(TrailRenderContext ctx) {
    if (ctx.trailSkin.renderType == TrailRenderType.galaxyReveal) {
      // Galaxy reveal draws via dedicated mask-based painter in game_board.dart.
      // Skip the default procedural stroke to avoid covering the reveal texture.
      return;
    }
    final skin = ctx.trailSkin;
    if (skin.renderType == TrailRenderType.punkRiff) {
      _paintPunkRiffBase(ctx);
      return;
    }
    if (skin.renderType == TrailRenderType.graffiti) {
      _paintGraffitiBase(ctx);
      return;
    }
    if (skin.renderType == TrailRenderType.urbanGraffiti) {
      _paintUrbanGraffitiBase(ctx);
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
    if (skin.renderType == TrailRenderType.web) {
      _paintWebBase(ctx);
      return;
    }
    if (skin.renderType == TrailRenderType.webLegendary) {
      _paintWebLegendaryBase(ctx);
      return;
    }
    if (skin.renderType == TrailRenderType.comicSpiderverse) {
      _paintComicSpiderverseBase(ctx);
      return;
    }
    if (skin.renderType == TrailRenderType.comicSpiderverseV2) {
      _paintComicSpiderverseV2Base(ctx);
      return;
    }
    if (skin.renderType == TrailRenderType.comicSpiderverseRebuilt) {
      _paintComicSpiderverseRebuiltBase(ctx);
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
      case TrailRenderType.galaxyReveal:
        return;
      case TrailRenderType.speedForce:
        _paintSpeedForceTrail(ctx);
        return;
      case TrailRenderType.web:
        _paintWebTrail(ctx);
        return;
      case TrailRenderType.webLegendary:
        _paintWebLegendaryTrail(ctx);
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
      case TrailRenderType.comicSpiderverse:
        _paintComicSpiderverseVfx(ctx);
        return;
      case TrailRenderType.comicSpiderverseV2:
        _paintComicSpiderverseV2Vfx(ctx);
        return;
      case TrailRenderType.comicSpiderverseRebuilt:
        _paintComicSpiderverseRebuiltVfx(ctx);
        return;
      case TrailRenderType.punkRiff:
        _paintPunkRiffTrail(ctx);
        return;
      case TrailRenderType.graffiti:
        _paintGraffitiTrail(ctx);
        return;
      case TrailRenderType.urbanGraffiti:
        _paintUrbanGraffitiTrail(ctx);
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
    final colorA = ctx.trailSkin.primaryColor;
    final colorB = ctx.trailSkin.secondaryColor;
    final colorMid = Color.lerp(colorA, colorB, 0.5) ?? colorA;
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
      ..color = colorB.withOpacity(0.22 + cfg.glitchStrength * 0.36);
    final pinkOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = ctx.baseStrokeWidth * 0.56
      ..color = colorA.withOpacity(0.22 + cfg.glitchStrength * 0.36);
    ctx.canvas.drawPath(path.shift(Offset(glitchPx, 0)), yellowOutline);
    ctx.canvas.drawPath(path.shift(Offset(-glitchPx, 0)), pinkOutline);

    _paintPunkRiffBolts(ctx, cfg, pulse, colorB);
    _paintPunkPaperFragments(ctx, cfg, pulse);
    _paintPunkInkSplashes(ctx, cfg, pulse, colorA, colorB, colorMid);
    _paintPunkHalftone(ctx, cfg, colorMid);
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
    final count = max(
        12, (ctx.pathPoints.length * cfg.sprayParticleFrequency * 3.0).round());
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

  static void _paintUrbanGraffitiBase(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.urbanGraffiti;
    final spray = ctx.urbanGraffitiSprites.spraySoft;
    final points = _jitterPolyline(
      ctx.pathPoints,
      amount: ctx.cellSize * (cfg.lineJitter * 1.2),
      phase: ctx.phase * pi * 2 * 0.85,
    );
    final rawWidth =
        ctx.baseStrokeWidth * ctx.trailSkin.thickness * cfg.mainWidth;
    final baseWidth =
        rawWidth.clamp(ctx.cellSize * 0.48, ctx.cellSize * 0.78).toDouble();

    final pathLen = _polylineLength(points);
    if (pathLen <= 0.001) return;

    if (spray != null) {
      final spacing = ctx.cellSize * _rand(61001 + ctx.visualFrame, 0.2, 0.32);
      final stampCount = (pathLen / max(6.0, spacing)).ceil().clamp(8, 260);
      for (var i = 0; i < stampCount; i++) {
        final seed = 61031 + i * 37;
        final d = i * spacing + _rand(seed + 3, -spacing * 0.35, spacing * 0.35);
        final p = _samplePointAtDistance(points, d);
        final tan = _sampleTangentAtDistance(points, d);
        if (p == null || tan == null) continue;
        final n = Offset(-tan.dy, tan.dx);
        final center = p +
            n * (ctx.cellSize * _rand(seed + 5, -0.18, 0.18)) +
            tan * (ctx.cellSize * _rand(seed + 7, -0.08, 0.08));
        final scale = _rand(seed + 11, 1.2, 1.6);
        final opacity = _rand(seed + 13, 0.25, 0.45);
        final tint = _rand(seed + 15, 0, 1) < 0.5
            ? const Color(0xFF62D8D2)
            : const Color(0xFFC44798);
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: spray,
          center: center,
          width: ctx.cellSize * scale,
          height: ctx.cellSize * scale * _rand(seed + 17, 0.78, 0.98),
          rotation: atan2(tan.dy, tan.dx) + _rand(seed + 19, -0.5, 0.5),
          opacity: opacity,
          tint: tint,
        );
      }
    }

    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final seg = b - a;
      final segLen = seg.distance;
      if (segLen <= 0.5) continue;
      final dir = seg / segLen;
      final n = Offset(-dir.dy, dir.dx);
      final chunks = max(2, (segLen / max(6.0, ctx.cellSize * 0.2)).ceil());
      for (var k = 0; k < chunks; k++) {
        final seed = 62001 + i * 53 + k * 11;
        if (_rand(seed + 1, 0, 1) < 0.08) continue;
        final t0 = k / chunks;
        final t1 = (k + _rand(seed + 3, 0.72, 1.0)) / chunks;
        final p0 = Offset.lerp(a, b, t0.clamp(0.0, 1.0))!;
        final p1 = Offset.lerp(a, b, t1.clamp(0.0, 1.0))!;
        final off = n * (ctx.cellSize * _rand(seed + 5, -0.05, 0.05));
        final widthMul = _rand(seed + 7, 0.78, 1.18);
        final c = _rand(seed + 9, 0, 1) < 0.5
            ? const Color(0xFF57C8C8)
            : const Color(0xFFB5418D);
        final segPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = max(1.0, baseWidth * widthMul)
          ..isAntiAlias = true
          ..color = c.withOpacity(_rand(seed + 13, 0.62, 0.88));
        ctx.canvas.drawLine(p0 + off, p1 + off, segPaint);
      }
    }

    for (var i = 0; i < max(8, (pathLen / max(12.0, ctx.cellSize * 0.4)).round()); i++) {
      final seed = 63001 + i * 29;
      final p = _samplePoint(points, _rand(seed + 3, 0, 1));
      if (p == null) continue;
      final r = ctx.cellSize * _rand(seed + 5, 0.03, 0.09);
      final c = _rand(seed + 7, 0, 1) < 0.5
          ? const Color(0xFF53C1BC)
          : const Color(0xFFB14486);
      ctx.canvas.drawCircle(
        p + Offset(
          _rand(seed + 9, -1, 1) * ctx.cellSize * 0.04,
          _rand(seed + 11, -1, 1) * ctx.cellSize * 0.04,
        ),
        r,
        Paint()..color = c.withOpacity(_rand(seed + 13, 0.28, 0.52)),
      );
    }
  }

  static void _paintUrbanGraffitiTrail(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.urbanGraffiti;
    final anchors = _collectUrbanGraffitiAnchors(ctx);
    final placed = <_UrbanPlacement>[];
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    _paintUrbanGraffitiSprayUnderlay(ctx, cfg);
    _paintUrbanGraffitiSplashes(ctx, cfg, anchors, placed);
    _paintUrbanGraffitiDrips(ctx, cfg, anchors, placed);
    _paintUrbanGraffitiTags(ctx, cfg, anchors, placed);
    _paintHeadGlow(ctx, scale: 0.2, alpha: 0.025);
    ctx.canvas.restore();
  }

  static void _paintUrbanGraffitiSprayUnderlay(
    TrailRenderContext ctx,
    UrbanGraffitiTrailConfig cfg,
  ) {
    final spray = ctx.urbanGraffitiSprites.spraySoft;
    if (spray == null) return;
    final pathLen = _polylineLength(ctx.pathPoints);
    if (pathLen <= 0.001) return;
    final spacing = _rand(
      41001 + ctx.visualFrame,
      cfg.spraySpacingMinPx,
      cfg.spraySpacingMaxPx,
    );
    final count = (pathLen / max(22.0, spacing * 1.2)).ceil().clamp(1, 10);
    for (var i = 0; i < count; i++) {
      final seed = 41031 + i * 53;
      if (_rand(seed + 1, 0, 1) < 0.28) continue;
      final d = (i * spacing) +
          _rand(seed + 3, -spacing * 0.2, spacing * 0.2) +
          pathLen * 0.01;
      final p = _samplePointAtDistance(ctx.pathPoints, d);
      final tan = _sampleTangentAtDistance(ctx.pathPoints, d);
      if (p == null || tan == null) continue;
      final n = Offset(-tan.dy, tan.dx);
      final side = _rand(seed + 4, 0, 1) < 0.5 ? -1.0 : 1.0;
      final center = p +
          n * side * (ctx.cellSize * _rand(seed + 5, 0.26, 0.54)) +
          tan * (ctx.cellSize * _rand(seed + 6, -0.12, 0.12));
      final opacity = _rand(
        seed + 7,
        cfg.sprayOpacityMin,
        cfg.sprayOpacityMax,
      );
      final scale = _rand(seed + 11, cfg.sprayScaleMin, cfg.sprayScaleMax);
      final tint = _rand(seed + 15, 0, 1) < 0.5
          ? const Color(0xFF8AD7D4)
          : const Color(0xFFB978A7);
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: spray,
        center: center,
        width: ctx.cellSize * scale * 1.08,
        height: ctx.cellSize * scale * 0.94,
        rotation: atan2(tan.dy, tan.dx) + _rand(seed + 13, -0.36, 0.36),
        opacity: opacity * 0.55,
        tint: tint,
      );
    }
  }

  static void _paintUrbanGraffitiSplashes(
    TrailRenderContext ctx,
    UrbanGraffitiTrailConfig cfg,
    List<_UrbanAnchor> anchors,
    List<_UrbanPlacement> placed,
  ) {
    final splash = ctx.urbanGraffitiSprites.graffitiSplash;
    if (splash == null || anchors.isEmpty || cfg.maxSplashes <= 0) return;
    var spawned = 0;
    final maxSpawn = cfg.maxSplashes.clamp(0, 6);
    for (var i = 0; i < anchors.length; i++) {
      if (spawned >= maxSpawn) break;
      final anchor = anchors[i];
      double chance = cfg.splashChanceOnTurn * 0.42;
      if (anchor.type == _UrbanAnchorType.nodeHit) {
        chance = cfg.splashChanceOnNode;
      } else if (anchor.type == _UrbanAnchorType.sharpTurn) {
        chance = cfg.splashChanceOnTurn;
      } else if (anchor.type == _UrbanAnchorType.milestone) {
        chance *= 0.55;
      }
      if (_rand(42001 + i * 17 + ctx.visualFrame, 0, 1) > chance) continue;
      final n = Offset(-anchor.tangent.dy, anchor.tangent.dx);
      final side = _rand(42009 + i * 19, 0, 1) < 0.5 ? -1.0 : 1.0;
      final candidate = anchor.center +
          n * side * ctx.cellSize * _rand(42011 + i * 23, 0.24, 0.5);
      final radius = ctx.cellSize * 0.3;
      final resolved = _resolveUrbanDecalCenter(
        ctx,
        candidate: candidate,
        tangent: anchor.tangent,
        radius: radius,
        placed: placed,
        cfg: cfg,
      );
      if (resolved == null) {
        continue;
      }
      final scale = _rand(42013 + i * 29, cfg.splashScaleMin, cfg.splashScaleMax);
      final opacity = _rand(
        42017 + i * 31,
        cfg.splashOpacityMin,
        cfg.splashOpacityMax,
      );
      final tint = _rand(42016 + i * 33, 0, 1) < 0.5
          ? const Color(0xFF66CDC9)
          : const Color(0xFFBD4D93);
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: splash,
        center: resolved + Offset(0, ctx.cellSize * 0.02),
        width: ctx.cellSize * scale * 1.12,
        height: ctx.cellSize * scale * 1.02,
        rotation: _rand(42018 + i * 35, -0.5, 0.5),
        opacity: opacity * 0.28,
        tint: tint.withOpacity(0.9),
      );
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: splash,
        center: resolved,
        width: ctx.cellSize * scale * 1.18,
        height: ctx.cellSize * scale * 1.06,
        rotation: _rand(42019 + i * 37, -0.42, 0.42),
        opacity: opacity,
        tint: tint,
      );
      placed.add(_UrbanPlacement(center: resolved, radius: radius));
      spawned++;
      if (cfg.debugMode) {
        debugPrint('[UrbanGraffitiTrail] splash spawned at $resolved');
      }
    }
  }

  static void _paintUrbanGraffitiDrips(
    TrailRenderContext ctx,
    UrbanGraffitiTrailConfig cfg,
    List<_UrbanAnchor> anchors,
    List<_UrbanPlacement> placed,
  ) {
    final drip = ctx.urbanGraffitiSprites.paintDrip;
    if (drip == null || anchors.isEmpty || cfg.maxDrips <= 0) return;
    var spawned = 0;
    for (var i = 0; i < anchors.length; i++) {
      if (spawned >= cfg.maxDrips) break;
      final anchor = anchors[i];
      double chance = cfg.dripChance;
      if (anchor.type == _UrbanAnchorType.nodeHit) {
        chance *= 2.2;
      } else if (anchor.type == _UrbanAnchorType.sharpTurn) {
        chance *= 0.55;
      }
      if (_rand(43001 + i * 41 + ctx.visualFrame, 0, 1) > chance) continue;
      final n = Offset(-anchor.tangent.dy, anchor.tangent.dx);
      final candidate = anchor.center +
          n * ctx.cellSize * _rand(43003 + i * 43, -0.14, 0.14) +
          Offset(0, ctx.cellSize * _rand(43007 + i * 47, 0.22, 0.4));
      final radius = ctx.cellSize * 0.28;
      final resolved = _resolveUrbanDecalCenter(
        ctx,
        candidate: candidate,
        tangent: anchor.tangent,
        radius: radius,
        placed: placed,
        cfg: cfg,
      );
      if (resolved == null) {
        continue;
      }
      final scale = _rand(43009 + i * 53, cfg.dripScaleMin, cfg.dripScaleMax);
      final opacity = _rand(43013 + i * 59, cfg.dripOpacityMin, cfg.dripOpacityMax);
      final tint = _rand(43014 + i * 61, 0, 1) < 0.5
          ? const Color(0xFF72C9C4)
          : const Color(0xFFAA4B8B);
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: drip,
        center: resolved + Offset(0, ctx.cellSize * 0.02),
        width: ctx.cellSize * scale * 0.82,
        height: ctx.cellSize * scale * 1.2,
        rotation: _rand(43015 + i * 60, -0.16, 0.16),
        opacity: opacity * 0.24,
        tint: tint,
      );
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: drip,
        center: resolved,
        width: ctx.cellSize * scale * 0.82,
        height: ctx.cellSize * scale * 1.18,
        rotation: _rand(43017 + i * 61, -0.2, 0.2),
        opacity: opacity,
        tint: tint,
      );
      placed.add(_UrbanPlacement(center: resolved, radius: radius));
      spawned++;
      if (cfg.debugMode) {
        debugPrint('[UrbanGraffitiTrail] drip spawned at $resolved');
      }
    }
  }

  static void _paintUrbanGraffitiTags(
    TrailRenderContext ctx,
    UrbanGraffitiTrailConfig cfg,
    List<_UrbanAnchor> anchors,
    List<_UrbanPlacement> placed,
  ) {
    final tag = ctx.urbanGraffitiSprites.graffitiTag01;
    if (tag == null || anchors.isEmpty || cfg.maxTags <= 0) return;
    final candidates = anchors
        .where((a) =>
            a.type == _UrbanAnchorType.nodeHit ||
            a.type == _UrbanAnchorType.milestone)
        .toList(growable: false);
    for (var i = 0; i < candidates.length; i++) {
      final anchor = candidates[i];
      final chance = anchor.type == _UrbanAnchorType.nodeHit
          ? cfg.tagChance * 2.2
          : cfg.tagChance;
      if (_rand(44001 + i * 67 + ctx.visualFrame, 0, 1) > chance) continue;
      final n = Offset(-anchor.tangent.dy, anchor.tangent.dx);
      final side = _rand(44003 + i * 71, 0, 1) < 0.5 ? -1.0 : 1.0;
      final candidate = anchor.center +
          n * side * ctx.cellSize * _rand(44005 + i * 73, 0.42, 0.62) +
          Offset(0, -ctx.cellSize * _rand(44007 + i * 79, 0.02, 0.14));
      final radius = ctx.cellSize * 0.3;
      final resolved = _resolveUrbanDecalCenter(
        ctx,
        candidate: candidate,
        tangent: anchor.tangent,
        radius: radius,
        placed: placed,
        cfg: cfg,
      );
      if (resolved == null) {
        continue;
      }
      final scale = _rand(44009 + i * 83, cfg.tagScaleMin, cfg.tagScaleMax);
      final opacity = _rand(44011 + i * 89, cfg.tagOpacityMin, cfg.tagOpacityMax);
      const tint = Color(0xFFB6B1B8);
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: tag,
        center: resolved + Offset(0, ctx.cellSize * 0.02),
        width: ctx.cellSize * scale * 1.1,
        height: ctx.cellSize * scale * 0.86,
        rotation: _rand(44012 + i * 93, -0.22, 0.22),
        opacity: opacity * 0.26,
        tint: tint,
      );
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: tag,
        center: resolved,
        width: ctx.cellSize * scale * 1.16,
        height: ctx.cellSize * scale * 0.92,
        rotation: _rand(44013 + i * 97, -0.3, 0.3),
        opacity: opacity,
        tint: tint,
      );
      if (cfg.debugMode) {
        debugPrint('[UrbanGraffitiTrail] tag spawned at $resolved');
      }
      return;
    }
  }

  static List<_UrbanAnchor> _collectUrbanGraffitiAnchors(TrailRenderContext ctx) {
    final points = ctx.pathPoints;
    if (points.length < 2) return const <_UrbanAnchor>[];
    final anchors = <_UrbanAnchor>[];

    void addAnchor(_UrbanAnchorType type, Offset center, Offset tangent) {
      if (tangent.distance <= 0.0001) return;
      for (final existing in anchors) {
        if ((existing.center - center).distance < ctx.cellSize * 0.26) return;
      }
      anchors.add(_UrbanAnchor(type: type, center: center, tangent: tangent));
    }

    for (var i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final cur = points[i];
      final next = points[i + 1];
      final v1 = cur - prev;
      final v2 = next - cur;
      final l1 = v1.distance;
      final l2 = v2.distance;
      if (l1 <= 0.001 || l2 <= 0.001) continue;
      final d1 = v1 / l1;
      final d2 = v2 / l2;
      final turn = acos((d1.dx * d2.dx + d1.dy * d2.dy).clamp(-1.0, 1.0));
      if (turn >= 0.62) {
        addAnchor(_UrbanAnchorType.sharpTurn, cur, d2);
      }
    }

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      for (final node in ctx.nodeCenters) {
        if ((node - p).distance <= ctx.cellSize * 0.19) {
          final idx = i.clamp(1, points.length - 1).toInt();
          final tangent = points[idx] - points[idx - 1];
          addAnchor(_UrbanAnchorType.nodeHit, node, tangent);
        }
      }
    }

    final totalLen = _polylineLength(points);
    if (totalLen > 0.001) {
      final spacing = _rand(
        45001 + ctx.visualFrame,
        ctx.trailSkin.urbanGraffiti.splashMilestoneSpacingMinPx,
        ctx.trailSkin.urbanGraffiti.splashMilestoneSpacingMaxPx,
      );
      for (double d = spacing; d < totalLen; d += spacing) {
        final p = _samplePointAtDistance(points, d);
        final tan = _sampleTangentAtDistance(points, d);
        if (p == null || tan == null) continue;
        addAnchor(_UrbanAnchorType.milestone, p, tan);
      }
    }
    final tailTan =
        points.length > 1 ? (points.last - points[points.length - 2]) : null;
    if (tailTan != null && tailTan.distance > 0.0001) {
      addAnchor(_UrbanAnchorType.milestone, points.last, tailTan);
    }
    return anchors;
  }

  static bool _canPlaceUrbanDecal(
    TrailRenderContext ctx, {
    required Offset center,
    required double radius,
    required List<_UrbanPlacement> placed,
    required UrbanGraffitiTrailConfig cfg,
  }) {
    if (!ctx.boardRect.inflate(2.0).contains(center)) return false;
    if (_distanceToPolyline(center, ctx.pathPoints) > ctx.cellSize * 0.72) {
      return false;
    }
    final nodeGuard = ctx.cellSize * cfg.nodeAvoidRadiusCells + radius * 0.45;
    for (final node in ctx.nodeCenters) {
      if ((node - center).distance < nodeGuard) return false;
    }
    for (final item in placed) {
      if ((item.center - center).distance < (item.radius + radius) * 0.92) {
        return false;
      }
    }
    return true;
  }

  static Offset? _resolveUrbanDecalCenter(
    TrailRenderContext ctx, {
    required Offset candidate,
    required Offset tangent,
    required double radius,
    required List<_UrbanPlacement> placed,
    required UrbanGraffitiTrailConfig cfg,
  }) {
    if (_canPlaceUrbanDecal(
      ctx,
      center: candidate,
      radius: radius,
      placed: placed,
      cfg: cfg,
    )) {
      return candidate;
    }
    final len = tangent.distance;
    final dir = len <= 0.0001 ? const Offset(1, 0) : tangent / len;
    final n = Offset(-dir.dy, dir.dx);
    for (var i = 0; i < 6; i++) {
      final side = i.isEven ? 1.0 : -1.0;
      final step = 0.24 + i * 0.08;
      final shifted = candidate +
          n * side * ctx.cellSize * step +
          dir * ctx.cellSize * (0.04 + i * 0.012);
      if (_canPlaceUrbanDecal(
        ctx,
        center: shifted,
        radius: radius,
        placed: placed,
        cfg: cfg,
      )) {
        return shifted;
      }
    }
    return null;
  }

  static void _paintHalftoneExplosionBase(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.halftoneExplosion;
    final pulse = 1 + sin(ctx.phase * pi * 2 * 1.8) * 0.1;
    final width =
        ctx.baseStrokeWidth * ctx.trailSkin.thickness * cfg.coreWidth * pulse;
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
      final fillColor =
          (i.isEven ? const Color(0xFFFFE84A) : const Color(0xFFFF3B30))
              .withOpacity(0.16 + fade * 0.34);
      final strokeColor =
          const Color(0xFF111827).withOpacity(0.26 + fade * 0.32);
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
    final maxFlashes =
        max(2, (ctx.pathPoints.length * cfg.impactFlashFrequency).round());
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
    final count =
        max(8, (ctx.pathPoints.length * cfg.stickerFrequency * 2.2).round());
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
      final rotation = _rand(
          15040 + i, -cfg.rotationVariance * pi, cfg.rotationVariance * pi);
      final scale = 1 + _rand(15060 + i, -cfg.scaleVariance, cfg.scaleVariance);
      final size = ctx.cellSize * (0.145 * scale.clamp(0.7, 1.55));
      final color = palette[i % palette.length].withOpacity(0.24 + fade * 0.52);
      _drawSticker(
          canvas: ctx.canvas,
          center: center,
          size: size,
          rotation: rotation,
          color: color);
    }
  }

  static void _paintStickerClusters(
    TrailRenderContext ctx,
    StickerBombTrailConfig cfg,
    List<Color> palette,
  ) {
    final clusterCount =
        max(2, (ctx.pathPoints.length * cfg.stickerFrequency * 0.8).round());
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
        final ang =
            (j / stickersInCluster) * pi * 2 + _rand(15140 + i + j, -0.3, 0.3);
        final r = ctx.cellSize * _rand(15160 + i + j, 0.05, 0.12);
        final pos = center + Offset(cos(ang) * r, sin(ang) * r);
        final rotation = _rand(
          15180 + i + j,
          -cfg.rotationVariance * pi,
          cfg.rotationVariance * pi,
        );
        final scale =
            1 + _rand(15200 + i + j, -cfg.scaleVariance, cfg.scaleVariance);
        final size = ctx.cellSize * (0.12 * scale.clamp(0.7, 1.55));
        final color = palette[(i + j + 2) % palette.length].withOpacity(0.32);
        _drawSticker(
            canvas: ctx.canvas,
            center: pos,
            size: size,
            rotation: rotation,
            color: color);
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
    final rect = Rect.fromCenter(
        center: Offset.zero, width: size * 1.1, height: size * 0.84);
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
    final jitter =
        sin(ctx.phase * pi * 2 * 3.1) * ctx.cellSize * cfg.glitchOffset;
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
    final count =
        max(8, (ctx.pathPoints.length * cfg.fragmentFrequency * 2.2).round());
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
    Color boltColor,
  ) {
    final count =
        max(7, (ctx.pathPoints.length * cfg.yellowBoltFrequency).round());
    final boltPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = max(1.0, ctx.cellSize * 0.026)
      ..color = boltColor.withOpacity(0.72);
    final boltGlow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = max(2.0, ctx.cellSize * 0.05)
      ..color = boltColor.withOpacity(0.42)
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
      final t =
          ((ctx.visualFrame * 0.029) + i * 0.163 + _rand(2200 + i, 0, 1)) % 1.0;
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
    Color colorA,
    Color colorB,
    Color colorMid,
  ) {
    final count =
        max(6, (ctx.pathPoints.length * cfg.inkSplashFrequency).round());
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
        colorA,
        colorB,
        colorMid,
        const Color(0xFF161616),
      ][i % 4]
          .withOpacity(0.28 + _rand(2660 + i, 0, 0.24));
      ctx.canvas.drawCircle(center, r, Paint()..color = color);
    }
  }

  static void _paintPunkHalftone(
    TrailRenderContext ctx,
    PunkRiffTrailConfig cfg,
    Color halftoneColor,
  ) {
    if (ctx.pathPoints.length < 2) return;
    const count = 4;
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = halftoneColor.withOpacity(cfg.halftoneOpacity);
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
  static Offset? _sampleTangentAtDistance(
      List<Offset> points, double distance) {
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
    painter.paint(
        canvas, position - Offset(painter.width * 0.5, painter.height * 0.5));
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

  static void _drawTrailSprite({
    required Canvas canvas,
    required ui.Image sprite,
    required Offset center,
    required double width,
    required double height,
    required double rotation,
    required double opacity,
    Color tint = Colors.white,
  }) {
    final src = Rect.fromLTWH(
      0,
      0,
      sprite.width.toDouble(),
      sprite.height.toDouble(),
    );
    final dst = Rect.fromCenter(
      center: center,
      width: max(1.0, width),
      height: max(1.0, height),
    );
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
        ..color = tint.withOpacity(opacity.clamp(0.0, 1.0)),
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
      final wave =
          sin(phase + i * 0.93) * 0.5 + cos(phase * 0.7 + i * 1.27) * 0.5;
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
  static void _paintWebTrail(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    _paintWebThreadSpriteOverlay(ctx);
    _paintWebHighlightPass(ctx);
    _paintWebSecondaryBridges(ctx);
    _paintWebMicroBridgeSprites(ctx);
    _paintWebNodeBursts(ctx);
    _paintWebNodeBurstSprites(ctx);
    _paintWebParticles(ctx);
    _paintWebSpriteParticles(ctx);
    _paintWebHeadPulse(ctx);
  }

  static void _paintWebLegendaryBase(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.webLegendary;
    const intensity = 0.68;
    final wBase =
        ctx.baseStrokeWidth * ctx.trailSkin.thickness * cfg.mainWidth * 1.08;
    final pulse =
        sin(ctx.phase * pi * 2 * (1.1 + cfg.highlightSpeed * 0.8)) * 0.5 + 0.5;
    final path = _buildSmoothPath(
      _jitterPolyline(
        ctx.pathPoints,
        amount: ctx.cellSize * 0.012 * (1 + pulse * 0.5),
        phase: ctx.phase * pi * 2,
      ),
    );

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = wBase + ctx.cellSize * 0.14
      ..color = const Color(0xFF8A5BFF).withOpacity(
        ((0.1 + cfg.glowIntensity * 0.17) * intensity).clamp(0.06, 0.24),
      );
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = wBase
      ..shader = LinearGradient(
        colors: <Color>[
          const Color(0xFFF5F5F1).withOpacity(0.8),
          const Color(0xFFD9E9FF).withOpacity(0.75),
          const Color(0xFFFF6FC9).withOpacity(0.28),
          const Color(0xFF7EE7FF).withOpacity(0.3),
        ],
        stops: const <double>[0.0, 0.42, 0.74, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(ctx.boardRect);

    final chromaA = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = max(0.8, wBase * 0.2)
      ..color = const Color(0xFFFF5BBE).withOpacity(0.18 + pulse * 0.1);
    final chromaB = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = max(0.8, wBase * 0.2)
      ..color = const Color(0xFF6EE7FF).withOpacity(0.17 + pulse * 0.09);

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    ctx.canvas.drawPath(path, glow);
    final chromaOffset = cfg.chromaticOffsetStrength * ctx.cellSize * 0.55;
    ctx.canvas.drawPath(path.shift(Offset(chromaOffset, 0)), chromaA);
    ctx.canvas.drawPath(path.shift(Offset(-chromaOffset, 0)), chromaB);
    ctx.canvas.drawPath(path, core);
    ctx.canvas.restore();
  }

  static void _paintWebLegendaryTrail(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    _paintWebLegendaryHighlight(ctx);
    _paintWebLegendaryBridges(ctx);
    _paintWebLegendaryNodeBursts(ctx);
    _paintWebLegendaryHalftone(ctx);
    _paintWebLegendaryParticles(ctx);
    _paintWebLegendaryGlitchFlash(ctx);
  }

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

  static void _paintComicSpiderverseBase(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.comicSpiderverse;
    final sprites = ctx.comicSpiderverseSprites;
    final steppedT = _comicSpiderverseStepTime(ctx);
    final baseOpacity = cfg.baseOpacityMin +
        (cfg.baseOpacityMax - cfg.baseOpacityMin) *
            (sin(steppedT * 4.6) * 0.5 + 0.5);
    final widthScale = cfg.scaleMin +
        (cfg.scaleMax - cfg.scaleMin) * (sin(steppedT * 3.7 + 0.8) * 0.5 + 0.5);
    final jitterDeg = cfg.rotationJitterDeg * sin(steppedT * 5.2 + 1.4);
    final jitterRad = jitterDeg * pi / 180.0;

    final w = ctx.baseStrokeWidth * ctx.trailSkin.thickness * 1.02 * widthScale;
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = w
      ..shader = LinearGradient(
        colors: <Color>[
          const Color(0xFFEAF1FF).withOpacity(baseOpacity * 0.9),
          const Color(0xFFA9C7FF).withOpacity(baseOpacity * 0.84),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(ctx.boardRect);

    final chromaOpacity = cfg.chromaticOpacity.clamp(0.3, 0.5);
    final chromaPx = cfg.chromaticOffsetPx;
    final cyan = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = w * 0.95
      ..color = const Color(0xFF6EE7FF).withOpacity(chromaOpacity);
    final magenta = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = w * 0.92
      ..color = const Color(0xFFFF5BBE).withOpacity(chromaOpacity * 0.95);

    final path = ctx.pathCurve;
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    ctx.canvas.drawPath(path.shift(Offset(-chromaPx, 0)), cyan);
    ctx.canvas.drawPath(path.shift(Offset(chromaPx, 0)), magenta);
    ctx.canvas.drawPath(path, basePaint);

    if (sprites.glitchStreak != null) {
      final totalLen = _polylineLength(ctx.pathPoints);
      final spacing = max(8.0, ctx.cellSize * 0.32);
      final count = (totalLen / spacing).floor().clamp(1, 56);
      for (var i = 0; i < count; i++) {
        final t = (i / max(1, count - 1));
        final p = _samplePoint(ctx.pathPoints, t);
        final tan = _sampleTangent(ctx.pathPoints, t);
        if (p == null || tan == null) continue;
        final angle = atan2(tan.dy, tan.dx) + jitterRad;
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: sprites.glitchStreak!,
          center: p,
          width: ctx.cellSize * 0.95,
          height: ctx.cellSize * 0.42,
          rotation: angle,
          opacity: baseOpacity * 0.9,
        );
      }
      if (ctx.pathPoints.length >= 3) {
        for (var i = 1; i < ctx.pathPoints.length - 1; i++) {
          final prev = ctx.pathPoints[i] - ctx.pathPoints[i - 1];
          final next = ctx.pathPoints[i + 1] - ctx.pathPoints[i];
          final prevLen = prev.distance;
          final nextLen = next.distance;
          if (prevLen <= 0.0001 || nextLen <= 0.0001) continue;
          final dot = (prev.dx / prevLen) * (next.dx / nextLen) +
              (prev.dy / prevLen) * (next.dy / nextLen);
          if (dot > 0.94) continue;
          _drawTrailSprite(
            canvas: ctx.canvas,
            sprite: sprites.glitchStreak!,
            center: ctx.pathPoints[i],
            width: ctx.cellSize * 1.18,
            height: ctx.cellSize * 0.58,
            rotation: atan2(next.dy, next.dx) + jitterRad,
            opacity: (baseOpacity * 0.98).clamp(0.0, 1.0),
          );
        }
      }
    }
    if (sprites.offsetShadow != null) {
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprites.offsetShadow!,
        center: ctx.pathPoints.last,
        width: ctx.cellSize * 0.82,
        height: ctx.cellSize * 0.34,
        rotation: jitterRad,
        opacity: 0.32,
      );
    }
    ctx.canvas.restore();
  }

  static void _paintComicSpiderverseVfx(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    _paintComicSpiderverseParticles(ctx);
    _paintComicSpiderverseNodeImpacts(ctx);
    _paintComicSpiderverseDrops(ctx);
    _paintComicSpiderverseGlitchSlices(ctx);
    _paintComicSpiderverseHalftone(ctx);
  }

  // Web Trail: Layer 1 + 2 (main silk thread + fiber texture)
  static void _paintWebBase(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.web;
    final wBase = ctx.baseStrokeWidth * ctx.trailSkin.thickness;
    final depthOffset = ctx.cellSize * cfg.depthOffset;
    final shimmer = (sin(ctx.phase * pi * 2 * cfg.shimmerSpeed) * 0.5 + 0.5);

    final underPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = const Color(0xFF9AA8BD).withOpacity(0.16);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..color = ctx.trailSkin.primaryColor.withOpacity(cfg.glowOpacity);

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);

    // Depth underlayer
    for (var i = 0; i < ctx.pathPoints.length - 1; i++) {
      final p0 = ctx.pathPoints[i];
      final p1 = ctx.pathPoints[i + 1];
      final t0 = i / max(1, ctx.pathPoints.length - 1);
      final t1 = (i + 1) / max(1, ctx.pathPoints.length - 1);
      final n = _segmentNormal(p0, p1);
      final offset = n * depthOffset;
      final wp = _webSegmentWidth(ctx, t0, t1, wBase, cfg);
      underPaint.strokeWidth = wp * 1.15;
      glowPaint.strokeWidth = wp + ctx.cellSize * 0.06;
      ctx.canvas.drawLine(p0 + offset, p1 + offset, underPaint);
      ctx.canvas.drawLine(p0, p1, glowPaint);
    }

    // Main silk strands
    for (var i = 0; i < ctx.pathPoints.length - 1; i++) {
      final p0 = ctx.pathPoints[i];
      final p1 = ctx.pathPoints[i + 1];
      final t0 = i / max(1, ctx.pathPoints.length - 1);
      final t1 = (i + 1) / max(1, ctx.pathPoints.length - 1);
      final n = _segmentNormal(p0, p1);
      final strandOffset = n * (ctx.cellSize * cfg.strandGap * 0.1);
      final wp = _webSegmentWidth(ctx, t0, t1, wBase, cfg);

      final gradientMain = LinearGradient(
        colors: <Color>[
          const Color(0xFFF4F3EF).withOpacity(cfg.strandOpacity * 0.92),
          const Color(0xFFFFFFFF).withOpacity(0.84 + shimmer * 0.12),
          const Color(0xFFDDE6F5).withOpacity(cfg.strandOpacity * 0.78),
        ],
        stops: const <double>[0.0, 0.5, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromPoints(p0, p1).inflate(ctx.cellSize * 0.16));

      final mainPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..strokeWidth = wp
        ..shader = gradientMain;

      final highlightPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..strokeWidth = max(1.0, wp * 0.38)
        ..color = const Color(0xFFFFFFFF).withOpacity(
          0.22 + cfg.highlightStrength * 0.24 + shimmer * 0.1,
        );

      final coolTintPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true
        ..strokeWidth = max(0.8, wp * 0.22)
        ..color = const Color(0xFFDDE6F5).withOpacity(0.2 + shimmer * 0.08);

      ctx.canvas.drawLine(p0 - strandOffset, p1 - strandOffset, mainPaint);
      ctx.canvas.drawLine(p0 + strandOffset, p1 + strandOffset, mainPaint);
      ctx.canvas.drawLine(p0, p1, highlightPaint);
      ctx.canvas.drawLine(
        p0 + n * (ctx.cellSize * 0.01),
        p1 + n * (ctx.cellSize * 0.01),
        coolTintPaint,
      );

      // Micro-fiber texture overlay
      final fiberCount = max(1, (3 + cfg.fiberNoise * 9).round());
      for (var f = 0; f < fiberCount; f++) {
        final seed = (i + 1) * 7919 + f * 131;
        final localA = _rand(seed + 7, 0.04, 0.46);
        final localB =
            (localA + _rand(seed + 11, 0.16, 0.42)).clamp(0.08, 0.98);
        final a = Offset.lerp(p0, p1, localA)!;
        final b = Offset.lerp(p0, p1, localB)!;
        final jitter = n * (ctx.cellSize * _rand(seed + 19, -0.02, 0.02));
        final fiber = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..isAntiAlias = true
          ..strokeWidth = max(0.35, wp * _rand(seed + 23, 0.09, 0.16))
          ..color = const Color(0xFFF9FAFB).withOpacity(
            cfg.fiberAlpha * _rand(seed + 29, 0.45, 1.0),
          );
        ctx.canvas.drawLine(a + jitter, b + jitter, fiber);
      }
    }
    ctx.canvas.restore();
  }

  // Web Trail: Layer 3 (secondary micro-threads)
  static void _paintWebSecondaryBridges(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.web;
    final points = ctx.pathPoints;
    if (points.length < 3) return;
    final key = _webPatternKey(points, cfg);
    final pattern = _webBridgeCache.putIfAbsent(
      key,
      () => _buildWebBridgePattern(points.length - 1, cfg),
    );
    if (_webBridgeCache.length > 96) {
      _webBridgeCache.clear();
    }

    final vibrate = sin(ctx.nowSeconds * (1.8 + cfg.tensionSpeed)) *
        (ctx.cellSize * cfg.tensionAmplitude * 0.12);
    final bridgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth =
          max(0.65, ctx.baseStrokeWidth * cfg.mainStrandWidth * 0.36)
      ..color = const Color(0xFFEFF4FB).withOpacity(cfg.bridgeOpacity);

    final depthPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = max(0.6, bridgePaint.strokeWidth * 0.84)
      ..color = const Color(0xFFA9B6C9).withOpacity(cfg.bridgeOpacity * 0.38);

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (final b in pattern.bridges) {
      final i0 = b.segA;
      final i1 = b.segB;
      if (i0 < 0 ||
          i1 < 0 ||
          i0 >= points.length - 1 ||
          i1 >= points.length - 1 ||
          (i1 - i0).abs() < 1) {
        continue;
      }
      final a0 = Offset.lerp(points[i0], points[i0 + 1], b.tA)!;
      final a1 = Offset.lerp(points[i1], points[i1 + 1], b.tB)!;
      final n0 = _segmentNormal(points[i0], points[i0 + 1]);
      final n1 = _segmentNormal(points[i1], points[i1 + 1]);
      final depth = (n0 + n1) * (ctx.cellSize * cfg.depthOffset * 0.34);
      final wobbleA = n0 * vibrate;
      final wobbleB = n1 * vibrate;
      ctx.canvas.drawLine(a0 + depth, a1 + depth, depthPaint);
      ctx.canvas.drawLine(a0 + wobbleA, a1 + wobbleB, bridgePaint);
    }
    ctx.canvas.restore();
  }

  static void _paintWebThreadSpriteOverlay(TrailRenderContext ctx) {
    final sprite = ctx.webSprites.threadSoft;
    if (sprite == null || ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.web;
    final spacing = max(8.0, ctx.cellSize * cfg.bridgeSpacing * 2.8);
    final totalLen = _polylineLength(ctx.pathPoints);
    if (totalLen <= 0.001) return;
    final count = (totalLen / spacing).floor().clamp(1, 64);
    final baseSize = ctx.cellSize * 0.8;
    final flow = (ctx.nowSeconds * (0.08 + cfg.shimmerSpeed * 0.08)) % 1.0;

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < count; i++) {
      final seed = 4001 + i * 131;
      final t = ((i / max(1, count - 1)) + flow * 0.17) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      final tan = _sampleTangent(ctx.pathPoints, t);
      if (p == null || tan == null) continue;
      final angle = atan2(tan.dy, tan.dx) + _rand(seed + 5, -0.12, 0.12);
      final scale = _rand(seed + 7, 0.82, 1.18);
      final opacity =
          (cfg.strandOpacity * _rand(seed + 11, 0.34, 0.62)).clamp(0.16, 0.68);
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: p,
        width: baseSize * (1.25 + scale * 0.35),
        height: max(4.0, baseSize * (0.18 + scale * 0.06)),
        rotation: angle,
        opacity: opacity,
      );
    }
    ctx.canvas.restore();
  }

  static void _paintWebHighlightPass(TrailRenderContext ctx) {
    final sprite = ctx.webSprites.highlightStreak;
    if (sprite == null || ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.web;
    final totalLen = _polylineLength(ctx.pathPoints);
    if (totalLen <= 0.001) return;
    final highlights = max(1, (cfg.sparkleFrequency * 8).round()).clamp(1, 4);
    final flow = (ctx.nowSeconds * (0.12 + cfg.shimmerSpeed * 0.2)) % 1.0;

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < highlights; i++) {
      final seed = 4441 + i * 211;
      final t = (flow + i / max(1, highlights)) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      final tan = _sampleTangent(ctx.pathPoints, t);
      if (p == null || tan == null) continue;
      final angle = atan2(tan.dy, tan.dx);
      final pulse = (sin(ctx.nowSeconds * 2.1 + i * 0.8) * 0.5 + 0.5);
      final opacity =
          (0.18 + cfg.highlightStrength * 0.3 + pulse * 0.18).clamp(0.12, 0.62);
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: p + Offset(-tan.dy, tan.dx) * (ctx.cellSize * 0.02),
        width: ctx.cellSize * _rand(seed + 3, 0.42, 0.78),
        height: ctx.cellSize * _rand(seed + 7, 0.08, 0.14),
        rotation: angle,
        opacity: opacity,
      );
    }
    ctx.canvas.restore();
  }

  static void _paintWebMicroBridgeSprites(TrailRenderContext ctx) {
    final sprite = ctx.webSprites.microBridge;
    if (sprite == null || ctx.pathPoints.length < 3) return;
    final cfg = ctx.trailSkin.web;
    final points = ctx.pathPoints;
    final key = _webPatternKey(points, cfg);
    final pattern = _webBridgeCache.putIfAbsent(
      key,
      () => _buildWebBridgePattern(points.length - 1, cfg),
    );

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < pattern.bridges.length; i++) {
      final b = pattern.bridges[i];
      if (b.segA < 0 ||
          b.segB < 0 ||
          b.segA >= points.length - 1 ||
          b.segB >= points.length - 1) {
        continue;
      }
      final a0 = Offset.lerp(points[b.segA], points[b.segA + 1], b.tA)!;
      final a1 = Offset.lerp(points[b.segB], points[b.segB + 1], b.tB)!;
      final mid = Offset((a0.dx + a1.dx) * 0.5, (a0.dy + a1.dy) * 0.5);
      final dir = a1 - a0;
      final len = dir.distance;
      if (len < 2.0) continue;
      final angle = atan2(dir.dy, dir.dx);
      final seed = 4881 + i * 97;
      final scale = _rand(seed + 9, 0.84, 1.16);
      final opacity =
          (cfg.bridgeOpacity * _rand(seed + 11, 0.45, 0.82)).clamp(0.12, 0.58);
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: mid,
        width: max(ctx.cellSize * 0.18, len * 0.55 * scale),
        height: max(ctx.cellSize * 0.04, ctx.cellSize * 0.08 * scale),
        rotation: angle + _rand(seed + 13, -0.16, 0.16),
        opacity: opacity,
      );
    }
    ctx.canvas.restore();
  }

  // Web Trail: Layer 4 (node web bursts)
  static void _paintWebNodeBursts(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.web;
    final points = ctx.pathPoints;
    if (points.isEmpty) return;
    final radialCount = cfg.nodeBurstLines.clamp(5, 8);
    final arcHints = cfg.nodeBurstArcHints.clamp(1, 3);
    final pulse =
        sin(ctx.phase * pi * 2 * (1.2 + cfg.shimmerSpeed)) * 0.5 + 0.5;
    final burstPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = const Color(0xFFF9FBFF).withOpacity(cfg.nodeBurstOpacity);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..strokeWidth = max(0.5, ctx.cellSize * 0.015)
      ..color =
          const Color(0xFFDDE6F5).withOpacity(cfg.nodeBurstOpacity * 0.72);

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < points.length; i++) {
      // Sparse anchor points + always include head.
      final isHead = i == points.length - 1;
      if (!isHead && i % 3 != 0) continue;
      final center = points[i];
      final localAlpha = isHead ? 1.0 : (0.55 + pulse * 0.2);
      final baseR = ctx.cellSize * cfg.nodeBurstScale * (isHead ? 1.12 : 0.84);
      burstPaint
        ..strokeWidth = max(0.6, ctx.cellSize * 0.017)
        ..color = const Color(0xFFFFFFFF)
            .withOpacity(cfg.nodeBurstOpacity * localAlpha);
      for (var l = 0; l < radialCount; l++) {
        final a =
            (l / radialCount) * pi * 2 + _rand(i * 97 + l * 13, -0.22, 0.22);
        final inner = baseR * _rand(i * 89 + l * 11, 0.18, 0.34);
        final outer = baseR * _rand(i * 79 + l * 7, 0.74, 1.0);
        final p0 = center + Offset(cos(a) * inner, sin(a) * inner);
        final p1 = center + Offset(cos(a) * outer, sin(a) * outer);
        ctx.canvas.drawLine(p0, p1, burstPaint);
      }
      for (var a = 0; a < arcHints; a++) {
        final start =
            (a / arcHints) * pi * 2 + _rand(i * 67 + a * 29, -0.2, 0.2);
        final sweep = _rand(i * 53 + a * 31, 0.48, 0.86);
        final rect =
            Rect.fromCircle(center: center, radius: baseR * (0.6 + a * 0.15));
        ctx.canvas.drawArc(rect, start, sweep, false, arcPaint);
      }
    }
    ctx.canvas.restore();
  }

  static void _paintWebNodeBurstSprites(TrailRenderContext ctx) {
    if (!ctx.webSprites.hasNodeBurst || ctx.pathPoints.isEmpty) return;
    final cfg = ctx.trailSkin.web;
    final points = ctx.pathPoints;
    final progress =
        Curves.easeOut.transform((ctx.phase % 1.0).clamp(0.0, 1.0));
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < points.length; i++) {
      final isHead = i == points.length - 1;
      if (!isHead && i % 3 != 0) continue;
      final seed = 5201 + i * 83;
      final sprite = _rand(seed + 3, 0, 1) < 0.5
          ? (ctx.webSprites.nodeBurst01 ?? ctx.webSprites.nodeBurst02)
          : (ctx.webSprites.nodeBurst02 ?? ctx.webSprites.nodeBurst01);
      if (sprite == null) continue;
      final p = points[i];
      final localScale =
          (0.6 + progress * 0.4) * (isHead ? 1.1 : 0.92) * cfg.nodeBurstScale;
      final opacity = (cfg.nodeBurstOpacity *
              (isHead ? 1.0 : 0.72) *
              (0.65 + progress * 0.35))
          .clamp(0.08, 0.8);
      final size = ctx.cellSize * (0.85 + localScale * 1.7);
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: p,
        width: size,
        height: size,
        rotation: _rand(seed + 7, -0.2, 0.2),
        opacity: opacity,
      );
    }
    ctx.canvas.restore();
  }

  // Web Trail: Layer 5 + 6 (dust + travelers + silk fragments + subtle tension)
  static void _paintWebParticles(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.web;
    if (ctx.pathPoints.length < 2) return;
    final travelers = cfg.silkTravelerCount.clamp(4, 12);
    final dustCount = cfg.dustParticleCount.clamp(8, 24);
    final speed = 0.14 + cfg.shimmerSpeed * 0.22;

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);

    for (var i = 0; i < travelers; i++) {
      final seed = 1103 + i * 97;
      final t = ((ctx.nowSeconds * speed) + _rand(seed, 0.0, 1.0)) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      final tan = _sampleTangent(ctx.pathPoints, t);
      if (p == null || tan == null) continue;
      final alphaPulse = sin(ctx.nowSeconds * (1.2 + i * 0.08) + i) * 0.5 + 0.5;
      final radius = ctx.cellSize * _rand(seed + 13, 0.018, 0.026);
      final n = Offset(-tan.dy, tan.dx);
      final offset = n * (ctx.cellSize * _rand(seed + 17, -0.015, 0.015));
      final paint = Paint()
        ..isAntiAlias = true
        ..color = const Color(0xFFFFFFFF).withOpacity(0.25 + alphaPulse * 0.42);
      ctx.canvas.drawCircle(p + offset, radius, paint);
    }

    for (var i = 0; i < dustCount; i++) {
      final seed = 3209 + i * 59;
      final t =
          ((ctx.nowSeconds * (speed * 0.42)) + _rand(seed, 0.0, 1.0)) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      if (p == null) continue;
      final tan = _sampleTangent(ctx.pathPoints, t) ?? const Offset(1, 0);
      final n = Offset(-tan.dy, tan.dx);
      final spread = ctx.cellSize * _rand(seed + 5, 0.04, 0.12);
      final drift = (sin(ctx.nowSeconds * 0.44 + i) * 0.5 + 0.5);
      final pos = p +
          n * (spread * _rand(seed + 7, -1.0, 1.0)) +
          tan * (spread * 0.35 * drift);
      final life = ((ctx.nowSeconds * 0.21) + _rand(seed + 11, 0.0, 1.0)) % 1.0;
      final alpha = (1 - (life - 0.5).abs() * 2).clamp(0.0, 1.0);
      final radius = ctx.cellSize * _rand(seed + 13, 0.008, 0.018);
      final dust = Paint()
        ..isAntiAlias = true
        ..color = const Color(0xFFEAF3FF).withOpacity(0.1 + alpha * 0.24);
      ctx.canvas.drawCircle(pos, radius, dust);
    }

    // Occasional detached silk fragments
    final fragmentChance = cfg.silkFragmentFrequency.clamp(0.0, 0.3);
    for (var i = 0; i < 6; i++) {
      final seed = 8801 + i * 137;
      final chance = _rand(seed + 3, 0.0, 1.0);
      if (chance > fragmentChance) continue;
      final t = ((ctx.nowSeconds * 0.16) + _rand(seed + 7, 0, 1)) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      final tan = _sampleTangent(ctx.pathPoints, t);
      if (p == null || tan == null) continue;
      final n = Offset(-tan.dy, tan.dx);
      final drift = (ctx.nowSeconds % 1.0);
      final pos = p +
          n * (ctx.cellSize * _rand(seed + 11, -0.12, 0.12)) +
          Offset(0, -ctx.cellSize * 0.03 * drift);
      final len = ctx.cellSize * _rand(seed + 13, 0.03, 0.07);
      final a = _rand(seed + 17, 0.0, pi);
      final dir = Offset(cos(a), sin(a));
      final frag = Paint()
        ..isAntiAlias = true
        ..strokeCap = StrokeCap.round
        ..strokeWidth = max(0.45, ctx.cellSize * 0.012)
        ..color = const Color(0xFFF7F8FB).withOpacity(0.16 + (1 - drift) * 0.2);
      ctx.canvas.drawLine(pos - dir * len * 0.5, pos + dir * len * 0.5, frag);
    }
    ctx.canvas.restore();
  }

  static void _paintWebSpriteParticles(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.web;
    final sparkle = ctx.webSprites.sparkle;
    final fragment = ctx.webSprites.silkFragment;
    if (sparkle == null && fragment == null) return;
    final sparkleCount = min(15, cfg.dustParticleCount.clamp(6, 24));
    final fragmentCount = min(
      10,
      max(2, (cfg.silkFragmentFrequency * 40).round()),
    );
    final flow = ctx.nowSeconds * (0.12 + cfg.shimmerSpeed * 0.16);

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);

    if (sparkle != null) {
      for (var i = 0; i < sparkleCount; i++) {
        final seed = 6101 + i * 47;
        final t = (flow + _rand(seed, 0.0, 1.0)) % 1.0;
        final p = _samplePoint(ctx.pathPoints, t);
        final tan = _sampleTangent(ctx.pathPoints, t);
        if (p == null || tan == null) continue;
        final n = Offset(-tan.dy, tan.dx);
        final drift = sin(ctx.nowSeconds * 0.8 + i * 0.7) * 0.5 + 0.5;
        final pos = p +
            n * (ctx.cellSize * _rand(seed + 3, -0.07, 0.07)) +
            tan * (ctx.cellSize * 0.05 * drift);
        final alpha = (0.18 + drift * 0.44).clamp(0.1, 0.62);
        final scale = _rand(seed + 5, 0.1, 0.3);
        final size = ctx.cellSize * scale;
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: sparkle,
          center: pos,
          width: size,
          height: size,
          rotation: _rand(seed + 7, -pi, pi),
          opacity: alpha,
        );
      }
    }

    if (fragment != null) {
      for (var i = 0; i < fragmentCount; i++) {
        final seed = 6901 + i * 59;
        final t = ((flow * 0.7) + _rand(seed + 1, 0.0, 1.0)) % 1.0;
        final p = _samplePoint(ctx.pathPoints, t);
        final tan = _sampleTangent(ctx.pathPoints, t);
        if (p == null || tan == null) continue;
        final n = Offset(-tan.dy, tan.dx);
        final life =
            ((ctx.nowSeconds * 0.22) + _rand(seed + 3, 0.0, 1.0)) % 1.0;
        final alpha = (1.0 - (life - 0.5).abs() * 2.0).clamp(0.0, 1.0);
        final pos = p +
            n * (ctx.cellSize * _rand(seed + 5, -0.12, 0.12)) +
            Offset(0, -ctx.cellSize * 0.09 * life);
        final scale = _rand(seed + 7, 0.14, 0.28);
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: fragment,
          center: pos,
          width: ctx.cellSize * scale * 1.5,
          height: ctx.cellSize * scale,
          rotation: _rand(seed + 9, -0.8, 0.8),
          opacity: (0.12 + alpha * 0.28).clamp(0.06, 0.4),
        );
      }
    }
    ctx.canvas.restore();
  }

  static void _paintWebHeadPulse(TrailRenderContext ctx) {
    final head = ctx.headPosition;
    if (head == null) return;
    final cfg = ctx.trailSkin.web;
    final pulse =
        sin(ctx.phase * pi * 2 * (1.35 + cfg.shimmerSpeed)) * 0.5 + 0.5;
    final radius = ctx.cellSize * (0.2 + cfg.nodeBurstScale * 0.5);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFFFFFFF).withOpacity(0.16 + pulse * 0.16),
          const Color(0xFFDDE6F5).withOpacity(0.1 + pulse * 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: head, radius: radius * 1.3));
    ctx.canvas.drawCircle(head, radius * (0.9 + pulse * 0.12), paint);
  }

  static void _paintWebLegendaryHighlight(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.webLegendary;
    final sprite = ctx.webLegendarySprites.highlightStreak;
    final totalLen = _polylineLength(ctx.pathPoints);
    if (totalLen <= 0.001) return;
    final t = (ctx.nowSeconds * (0.1 + cfg.highlightSpeed * 0.2)) % 1.0;
    final p = _samplePoint(ctx.pathPoints, t);
    final tan = _sampleTangent(ctx.pathPoints, t);
    if (p == null || tan == null) return;
    final angle = atan2(tan.dy, tan.dx);
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    if (sprite != null) {
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: p,
        width: ctx.cellSize * 1.04,
        height: ctx.cellSize * 0.18,
        rotation: angle,
        opacity: 0.33,
      );
      final n = Offset(-tan.dy, tan.dx);
      final fringeOffset = ctx.cellSize * 0.015;
      final magentaGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = max(0.8, ctx.cellSize * 0.026)
        ..color = const Color(0xFFFF5BBE).withOpacity(0.16);
      final cyanGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = max(0.8, ctx.cellSize * 0.024)
        ..color = const Color(0xFF6EE7FF).withOpacity(0.16);
      ctx.canvas.drawLine(
        p + n * fringeOffset - tan * (ctx.cellSize * 0.32),
        p + n * fringeOffset + tan * (ctx.cellSize * 0.32),
        magentaGlow,
      );
      ctx.canvas.drawLine(
        p - n * fringeOffset - tan * (ctx.cellSize * 0.3),
        p - n * fringeOffset + tan * (ctx.cellSize * 0.3),
        cyanGlow,
      );
    } else {
      final line = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = max(1.0, ctx.cellSize * 0.07)
        ..color = const Color(0xFFE8F2FF).withOpacity(0.34);
      ctx.canvas.drawLine(
        p - tan * (ctx.cellSize * 0.35),
        p + tan * (ctx.cellSize * 0.35),
        line,
      );
    }
    ctx.canvas.restore();
  }

  static void _paintWebLegendaryBridges(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.webLegendary;
    final points = ctx.pathPoints;
    if (points.length < 3) return;
    final key = (_webPatternKey(points, ctx.trailSkin.web) * 37) ^ 0x1A2B3C;
    final asWebCfg = WebTrailConfig(
      microBridgeDensity: (cfg.bridgeDensity * 0.7).clamp(0.0, 1.0),
      maxMicroBridgesPerSegment: max(1, cfg.maxBridgesPerSegment - 1),
      bridgeSpacing: 0.34,
    );
    final pattern = _webBridgeCache.putIfAbsent(
      key,
      () => _buildWebBridgePattern(points.length - 1, asWebCfg),
    );
    final sprite = ctx.webLegendarySprites.microBridge;
    final paintA = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(0.7, ctx.cellSize * 0.028)
      ..color = const Color(0xFFEFF7FF).withOpacity(0.26);
    final paintB = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(0.65, ctx.cellSize * 0.021)
      ..color = const Color(0xFF8BE9FF).withOpacity(0.14);

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < pattern.bridges.length; i++) {
      final b = pattern.bridges[i];
      if (b.segA >= points.length - 1 || b.segB >= points.length - 1) continue;
      final a0 = Offset.lerp(points[b.segA], points[b.segA + 1], b.tA)!;
      final a1 = Offset.lerp(points[b.segB], points[b.segB + 1], b.tB)!;
      ctx.canvas.drawLine(a0, a1, i.isEven ? paintA : paintB);
      if (sprite != null && i.isOdd) {
        final mid = Offset((a0.dx + a1.dx) * 0.5, (a0.dy + a1.dy) * 0.5);
        final d = a1 - a0;
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: sprite,
          center: mid,
          width: max(ctx.cellSize * 0.2, d.distance * 0.5),
          height: ctx.cellSize * 0.08,
          rotation: atan2(d.dy, d.dx),
          opacity: 0.18,
        );
      }
    }
    ctx.canvas.restore();
  }

  static void _paintWebLegendaryNodeBursts(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.webLegendary;
    final points = ctx.pathPoints;
    if (points.isEmpty) return;
    final phase = (ctx.phase % 1.0).clamp(0.0, 1.0);
    final pulse = Curves.easeOut.transform(phase);
    final fadeOut = (1.0 - phase * 0.6).clamp(0.45, 1.0);
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < points.length; i++) {
      final isHead = i == points.length - 1;
      if (!isHead && i % 4 != 0) continue;
      final p = points[i];
      final r = ctx.cellSize * cfg.nodeBurstScale * (0.76 + pulse * 0.24);
      final radial = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = max(0.85, ctx.cellSize * 0.02)
        ..color = const Color(0xFFF7FBFF)
            .withOpacity((isHead ? 0.48 : 0.3) * fadeOut);
      for (var j = 0; j < 7; j++) {
        final a = (j / 7) * pi * 2 + _rand(i * 131 + j * 29, -0.22, 0.22);
        ctx.canvas.drawLine(
          p + Offset(cos(a), sin(a)) * (r * 0.22),
          p + Offset(cos(a), sin(a)) * r,
          radial,
        );
      }
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.72, ctx.cellSize * 0.015)
        ..color = (i.isEven ? const Color(0xFFFF5BBE) : const Color(0xFF6EE7FF))
            .withOpacity(0.18 * fadeOut);
      ctx.canvas.drawCircle(p, r * 0.76, ring);

      final sprite = i.isEven
          ? (ctx.webLegendarySprites.nodeBurst01 ??
              ctx.webLegendarySprites.nodeBurst02)
          : (ctx.webLegendarySprites.nodeBurst02 ??
              ctx.webLegendarySprites.nodeBurst01);
      if (sprite != null) {
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: sprite,
          center: p,
          width: r * 2.3,
          height: r * 2.3,
          rotation: _rand(i * 19 + 5, -0.2, 0.2),
          opacity: (isHead ? 0.56 : 0.36) * fadeOut,
        );
      }
    }
    ctx.canvas.restore();
  }

  static void _paintWebLegendaryParticles(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.webLegendary;
    final sparkle = ctx.webLegendarySprites.sparkle;
    final flick = ctx.webLegendarySprites.energyFlick;
    final sparkCount = max(6, (cfg.sparkleCount * 0.62).round()).clamp(6, 14);
    final flickCount =
        max(2, (cfg.energyFlickCount * 0.42).round()).clamp(2, 7);
    final allowFlick = (ctx.visualFrame % 10 == 0) ||
        ((ctx.pathPoints.length % 5 == 0) &&
            _rand(ctx.visualFrame + 8867, 0, 1) < 0.15);
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < sparkCount; i++) {
      final seed = 7701 + i * 43;
      final flow = ctx.nowSeconds * (0.08 + cfg.sparkleRate * 0.18);
      final t = (((i + 0.5) / sparkCount) + flow) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      if (p == null) continue;
      final alpha = (0.11 + (sin(ctx.nowSeconds * 0.72 + i) * 0.5 + 0.5) * 0.28)
          .clamp(0.08, 0.4);
      if (sparkle != null) {
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: sparkle,
          center: p +
              Offset(_rand(seed + 3, -1, 1) * ctx.cellSize * 0.07,
                  _rand(seed + 5, -1, 1) * ctx.cellSize * 0.07),
          width: ctx.cellSize * _rand(seed + 7, 0.12, 0.31),
          height: ctx.cellSize * _rand(seed + 11, 0.12, 0.31),
          rotation: _rand(seed + 13, -pi, pi),
          opacity: alpha,
        );
      } else {
        ctx.canvas.drawCircle(
          p,
          ctx.cellSize * _rand(seed + 17, 0.01, 0.02),
          Paint()..color = const Color(0xFFE9F3FF).withOpacity(alpha),
        );
      }
    }
    if (!allowFlick) {
      ctx.canvas.restore();
      return;
    }
    for (var i = 0; i < flickCount; i++) {
      final seed = 8801 + i * 61;
      final t = ((ctx.nowSeconds * (0.16 + cfg.energyFlickRate * 0.24)) +
              _rand(seed + 1, 0.0, 1.0)) %
          1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      if (p == null) continue;
      final color =
          i.isEven ? const Color(0xFFFF5BBE) : const Color(0xFF6EE7FF);
      final opacity = (0.11 + _rand(seed + 3, 0.05, 0.14)).clamp(0.08, 0.26);
      if (flick != null) {
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: flick,
          center: p,
          width: ctx.cellSize * _rand(seed + 5, 0.16, 0.34),
          height: ctx.cellSize * _rand(seed + 7, 0.12, 0.24),
          rotation: _rand(seed + 9, -1.1, 1.1),
          opacity: opacity,
        );
      } else {
        final paint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = max(0.8, ctx.cellSize * 0.018)
          ..color = color.withOpacity(opacity);
        ctx.canvas.drawLine(
          p + Offset(-ctx.cellSize * 0.04, 0),
          p + Offset(ctx.cellSize * 0.04, 0),
          paint,
        );
      }
    }
    ctx.canvas.restore();
  }

  static void _paintWebLegendaryHalftone(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.webLegendary;
    final phase = (ctx.phase % 1.0).clamp(0.0, 1.0);
    if (phase > 0.34) return;
    if (_rand(ctx.visualFrame + 9203, 0, 1) > (cfg.halftoneFrequency * 0.45)) {
      return;
    }
    final sprite = ctx.webLegendarySprites.halftonePatch;
    final anchor = ctx.headPosition ?? _samplePoint(ctx.pathPoints, 0.82);
    if (anchor == null) return;
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    if (sprite != null) {
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: anchor,
        width: ctx.cellSize * 1.2,
        height: ctx.cellSize * 0.9,
        rotation: _rand(ctx.visualFrame + 9209, -0.3, 0.3),
        opacity: 0.08,
      );
    } else {
      final dot = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF7DD3FC).withOpacity(0.06);
      final step = max(2.0, ctx.cellSize * 0.05);
      final rect = Rect.fromCenter(
        center: anchor,
        width: ctx.cellSize * 0.9,
        height: ctx.cellSize * 0.6,
      );
      for (double y = rect.top; y <= rect.bottom; y += step) {
        for (double x = rect.left; x <= rect.right; x += step) {
          if ((((x / step) + (y / step)).floor()) % 2 != 0) continue;
          ctx.canvas.drawCircle(Offset(x, y), step * 0.14, dot);
        }
      }
    }
    ctx.canvas.restore();
  }

  static void _paintWebLegendaryGlitchFlash(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.webLegendary;
    if (_rand(ctx.visualFrame + 9901, 0, 1) >
        (cfg.glitchFlashProbability * 0.55)) {
      return;
    }
    final path = _buildSmoothPath(ctx.pathPoints);
    final offsetPx = ctx.cellSize * cfg.chromaticOffsetStrength * 0.62;
    final magenta = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = max(0.8, ctx.baseStrokeWidth * cfg.mainWidth * 0.26)
      ..color = const Color(0xFFFF5BBE).withOpacity(0.11);
    final cyan = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = max(0.8, ctx.baseStrokeWidth * cfg.mainWidth * 0.24)
      ..color = const Color(0xFF6EE7FF).withOpacity(0.1);
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    ctx.canvas.drawPath(path.shift(Offset(offsetPx, -offsetPx * 0.4)), magenta);
    ctx.canvas.drawPath(path.shift(Offset(-offsetPx, offsetPx * 0.4)), cyan);
    ctx.canvas.restore();
  }

  static void _paintComicSpiderverseParticles(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.comicSpiderverse;
    final sprites = ctx.comicSpiderverseSprites;
    final frameT = _comicSpiderverseStepTime(ctx);
    final count = cfg.maxParticles.clamp(20, 40);
    final flow = (frameT * 0.36) % 1.0;
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < count; i++) {
      final seed = 17011 + i * 61;
      final t = (flow + _rand(seed, 0.0, 1.0)) % 1.0;
      final p = _samplePoint(ctx.pathPoints, t);
      final tan = _sampleTangent(ctx.pathPoints, t);
      if (p == null || tan == null) continue;
      final isStar = _rand(seed + 3, 0, 1) < 0.2;
      final sprite = isStar ? sprites.starParticle : sprites.dotParticle;
      final lifeMs = _rand(seed + 5, cfg.particleLifeMinMs.toDouble(),
          cfg.particleLifeMaxMs.toDouble());
      final life = ((ctx.visualFrame * 41.0 + i * 37) % lifeMs) / lifeMs;
      final alpha = (1 - life).clamp(0.0, 1.0) * (isStar ? 0.58 : 0.42);
      final n = Offset(-tan.dy, tan.dx);
      final drift = n * (ctx.cellSize * (life * 0.08));
      final size = ctx.cellSize * _rand(seed + 7, 0.2, 0.5);
      if (sprite != null) {
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: sprite,
          center: p + drift,
          width: size,
          height: size,
          rotation: _rand(seed + 11, -0.9, 0.9),
          opacity: alpha,
        );
      } else {
        ctx.canvas.drawCircle(
          p + drift,
          size * 0.18,
          Paint()
            ..isAntiAlias = true
            ..color =
                (isStar ? const Color(0xFFFFF4B0) : const Color(0xFFBEE2FF))
                    .withOpacity(alpha),
        );
      }
    }
    ctx.canvas.restore();
  }

  static void _paintComicSpiderverseNodeImpacts(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.comicSpiderverse;
    final sprites = ctx.comicSpiderverseSprites;
    final points = ctx.pathPoints;
    if (points.isEmpty) return;
    final phase = (ctx.visualPhase % 1.0).clamp(0.0, 1.0);
    final pop =
        phase < 0.5 ? (phase / 0.5) * 1.2 : 1.2 - ((phase - 0.5) / 0.5) * 0.2;
    final active = min(cfg.maxBursts, max(1, points.length ~/ 6));
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < active; i++) {
      final idx = max(0, points.length - 1 - i * 3);
      final p = points[idx];
      final burst = sprites.bursts.isEmpty
          ? null
          : sprites.bursts[(ctx.visualFrame + i) % sprites.bursts.length];
      final ink = sprites.inks.isEmpty
          ? null
          : sprites.inks[(ctx.visualFrame + i * 2) % sprites.inks.length];
      final half = sprites.halftones.isEmpty
          ? null
          : sprites
              .halftones[(ctx.visualFrame + i * 3) % sprites.halftones.length];

      if (half != null) {
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: half,
          center: p,
          width: ctx.cellSize * 1.9,
          height: ctx.cellSize * 1.5,
          rotation: _rand(idx * 29 + 7, -0.35, 0.35),
          opacity: 0.14,
        );
      }
      if (ink != null) {
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: ink,
          center: p,
          width: ctx.cellSize * 1.45 * pop,
          height: ctx.cellSize * 1.45 * pop,
          rotation: _rand(idx * 31 + 11, -0.28, 0.28),
          opacity: 0.22,
        );
      }
      if (burst != null) {
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: burst,
          center: p,
          width: ctx.cellSize * 1.5 * pop,
          height: ctx.cellSize * 1.5 * pop,
          rotation: _rand(idx * 37 + 13, -0.22, 0.22),
          opacity: 0.74,
        );
      }

      if (_rand(idx * 41 + 17, 0, 1) < cfg.textSpawnChance &&
          sprites.texts.isNotEmpty) {
        final text =
            sprites.texts[(idx + ctx.visualFrame) % sprites.texts.length];
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: text,
          center: p + Offset(0, -ctx.cellSize * 0.45),
          width: ctx.cellSize * 0.95,
          height: ctx.cellSize * 0.62,
          rotation: _rand(idx * 43 + 19, -0.2, 0.2),
          opacity: 0.72,
        );
      }
    }
    ctx.canvas.restore();
  }

  static void _paintComicSpiderverseDrops(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.comicSpiderverse;
    final sprites = ctx.comicSpiderverseSprites;
    final pathLen = _polylineLength(ctx.pathPoints);
    if (pathLen < 20) return;
    final spacing = _rand(
      19001 + ctx.visualFrame,
      cfg.comicDropDistanceMin.toDouble(),
      cfg.comicDropDistanceMax.toDouble(),
    );
    final count = min(cfg.maxComicDrops, max(1, (pathLen / spacing).floor()));
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < count; i++) {
      final d = (i + 1) * spacing;
      final p = _samplePointAtDistance(ctx.pathPoints, d.clamp(0, pathLen));
      if (p == null) continue;
      final lifeMs = _rand(
        19111 + i * 17,
        cfg.comicDropLifeMinMs.toDouble(),
        cfg.comicDropLifeMaxMs.toDouble(),
      );
      final life = ((ctx.visualFrame * 41.0 + i * 53) % lifeMs) / lifeMs;
      final alpha = (1 - life).clamp(0, 1) * 0.62;
      final rise = Offset(0, -ctx.cellSize * 0.18 * life);
      final candidates = <ui.Image>[
        ...sprites.bubbles,
        ...sprites.texts,
        ...sprites.inks,
      ];
      if (candidates.isEmpty) continue;
      final sprite = candidates[(ctx.visualFrame + i * 5) % candidates.length];
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: p + rise,
        width: ctx.cellSize * _rand(19231 + i, 0.64, 0.94),
        height: ctx.cellSize * _rand(19237 + i, 0.5, 0.84),
        rotation: _rand(19241 + i, -20, 20) * pi / 180.0,
        opacity: alpha,
      );
    }
    ctx.canvas.restore();
  }

  static void _paintComicSpiderverseGlitchSlices(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.comicSpiderverse;
    final sprite = ctx.comicSpiderverseSprites.frameSlice;
    final gateMs = _rand(
      21001,
      cfg.glitchSliceMinMs.toDouble(),
      cfg.glitchSliceMaxMs.toDouble(),
    );
    final lifeMs = _rand(
      21017,
      cfg.glitchSliceLifeMinMs.toDouble(),
      cfg.glitchSliceLifeMaxMs.toDouble(),
    );
    final timeline = (ctx.visualFrame * 41.0) % gateMs;
    if (timeline > lifeMs) return;
    final p = _samplePoint(ctx.pathPoints, 0.5);
    if (p == null) return;
    final alpha = (1 - timeline / lifeMs).clamp(0.0, 1.0) * 0.5;
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    if (sprite != null) {
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: p + Offset(_rand(21031 + ctx.visualFrame, -3, 3), 0),
        width: ctx.cellSize * 1.6,
        height: ctx.cellSize * 0.34,
        rotation: 0,
        opacity: alpha,
      );
    } else {
      final paint = Paint()
        ..color = const Color(0xFFE2E8F0).withOpacity(alpha)
        ..style = PaintingStyle.fill;
      ctx.canvas.drawRect(
        Rect.fromCenter(
          center: p + Offset(_rand(21037 + ctx.visualFrame, -3, 3), 0),
          width: ctx.cellSize * 1.5,
          height: ctx.cellSize * 0.26,
        ),
        paint,
      );
    }
    ctx.canvas.restore();
  }

  static void _paintComicSpiderverseHalftone(TrailRenderContext ctx) {
    final sprites = ctx.comicSpiderverseSprites.halftones;
    final p = ctx.headPosition;
    if (p == null) return;
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    if (sprites.isNotEmpty) {
      final sprite = sprites[ctx.visualFrame % sprites.length];
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: p + Offset(0, ctx.cellSize * 0.12),
        width: ctx.cellSize * 2.2,
        height: ctx.cellSize * 1.7,
        rotation: _rand(23011 + ctx.visualFrame, -0.2, 0.2),
        opacity: 0.14,
      );
    }
    ctx.canvas.restore();
  }

  static double _comicSpiderverseStepTime(TrailRenderContext ctx) {
    return ctx.visualFrame / 24.0;
  }

  // ComicSpiderverseTrailV2: stronger, layered, stepped comic multiverse style.
  static void _paintComicSpiderverseV2Base(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.comicSpiderverseV2;
    final sprites = ctx.comicSpiderverseSprites;
    // Add classic WebTrail silk structure as procedural base
    // (no sprite cost, cleaner readability).
    _paintWebBase(ctx);
    final boost = cfg.enableDebugBoost ? 2.0 : 1.0;
    final stepped = _comicSpiderverseV2SteppedSeed(ctx);
    final rawBaseW =
        max(8.0, ctx.baseStrokeWidth * 0.2) * cfg.mainTrailWidth * boost;
    final minCellFill = ctx.cellSize * 0.74;
    final maxCellFill = ctx.cellSize * 0.92;
    final baseW = rawBaseW.clamp(minCellFill, maxCellFill).toDouble();

    final under = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = baseW * 1.2
      ..color =
          const Color(0xFF0B1020).withOpacity((0.34 * boost).clamp(0.0, 0.72));
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = baseW
      ..shader = LinearGradient(
        colors: <Color>[
          const Color(0xFFF8FCFF).withOpacity(cfg.baseTrailOpacity),
          const Color(0xFFB7D4FF).withOpacity(cfg.baseTrailOpacity * 0.92),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(ctx.boardRect);

    final cyan = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = baseW * 0.95
      ..color = const Color(0xFF63F0FF)
          .withOpacity((cfg.chromaticOpacity * 0.9 * boost).clamp(0.0, 0.95));
    final magenta = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = baseW * 0.95
      ..color = const Color(0xFFFF58C9)
          .withOpacity((cfg.chromaticOpacity * 0.9 * boost).clamp(0.0, 0.95));

    final dxJ = _rand(stepped + 7, -2, 2);
    final dyJ = _rand(stepped + 11, -1, 1);
    final cyanShift = Offset(cfg.cyanOffsetX + dxJ, cfg.cyanOffsetY + dyJ);
    final magentaShift =
        Offset(cfg.magentaOffsetX - dxJ, cfg.magentaOffsetY - dyJ);

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    ctx.canvas.drawPath(ctx.pathCurve, under);
    ctx.canvas.drawPath(ctx.pathCurve.shift(cyanShift), cyan);
    ctx.canvas.drawPath(ctx.pathCurve.shift(magentaShift), magenta);
    ctx.canvas.drawPath(ctx.pathCurve, base);

    final streak = sprites.glitchStreak;
    if (streak != null) {
      for (var i = 0; i < ctx.pathPoints.length - 1; i++) {
        // Lower PNG call volume: paint streak sprite only on alternating segments.
        if (i.isOdd) continue;
        final a = ctx.pathPoints[i];
        final b = ctx.pathPoints[i + 1];
        final d = b - a;
        final len = d.distance;
        if (len < 0.001) continue;
        final dir = d / len;
        final angle =
            atan2(dir.dy, dir.dx) + _rand(stepped + i * 17, -0.05, 0.05);
        final step = max(30.0, ctx.cellSize * 0.95);
        final count = (len / step).ceil().clamp(1, 3);
        for (var s = 0; s <= count; s++) {
          if (count > 2 && s.isOdd) continue;
          final t = s / max(1, count);
          final p = Offset.lerp(a, b, t)!;
          _drawTrailSprite(
            canvas: ctx.canvas,
            sprite: streak,
            center: p,
            width: ctx.cellSize * _rand(stepped + i * 31 + s * 5, 1.2, 1.75),
            height: ctx.cellSize * _rand(stepped + i * 37 + s * 7, 0.78, 1.12),
            rotation: angle,
            opacity:
                (0.94 + _rand(stepped + s * 13, -0.08, 0.08)).clamp(0.84, 1.0),
          );
        }
        if (i > 0 && i < ctx.pathPoints.length - 2) {
          final prev = ctx.pathPoints[i] - ctx.pathPoints[i - 1];
          final next = ctx.pathPoints[i + 1] - ctx.pathPoints[i];
          final prevLen = prev.distance;
          final nextLen = next.distance;
          if (prevLen > 0.0001 && nextLen > 0.0001) {
            final dot = (prev.dx / prevLen) * (next.dx / nextLen) +
                (prev.dy / prevLen) * (next.dy / nextLen);
            if (dot < 0.95) {
              _drawTrailSprite(
                canvas: ctx.canvas,
                sprite: streak,
                center: ctx.pathPoints[i],
                width: ctx.cellSize * _rand(stepped + i * 61, 1.45, 1.95),
                height: ctx.cellSize * _rand(stepped + i * 67, 0.96, 1.26),
                rotation: angle,
                opacity: 0.98,
              );
            }
          }
        }
      }
    }
    ctx.canvas.restore();
  }

  static void _paintComicSpiderverseV2Vfx(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    // Reuse classic WebTrail procedural vibe as additive style.
    _paintWebSecondaryBridges(ctx);
    _paintWebParticles(ctx);
    _paintWebHeadPulse(ctx);
    // Keep secondary comic layers very sparse to reduce PNG call count.
    if (ctx.visualFrame % 14 == 0) {
      _paintComicSpiderverseV2InkUnderlay(ctx);
    }
    if (ctx.visualFrame % 12 == 0) {
      _paintComicSpiderverseV2Halftone(ctx);
    }
    if (ctx.visualFrame % 10 == 0) {
      _paintComicSpiderverseV2Particles(ctx);
    }
    if (ctx.visualFrame % 16 == 0) {
      _paintComicSpiderverseV2ComicSpawns(ctx);
    }
    // Keep comic accents, but with reduced PNG pressure.
    _paintComicSpiderverseV2GlitchSlices(ctx);
    _paintComicSpiderverseV2NodeImpacts(ctx);
  }

  static void _paintComicSpiderverseV2InkUnderlay(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.comicSpiderverseV2;
    final sprites = ctx.comicSpiderverseSprites.inks;
    if (sprites.isEmpty) return;
    final boost = cfg.enableDebugBoost ? 2.0 : 1.0;
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    final step = max(2, (ctx.pathPoints.length / 5).floor());
    for (var i = 0; i < ctx.pathPoints.length; i += step) {
      final p = ctx.pathPoints[i];
      final sprite = sprites[(i + ctx.visualFrame) % sprites.length];
      final opacity = _rand(
        i * 19 + ctx.visualFrame,
        cfg.inkOpacityMin,
        cfg.inkOpacityMax,
      );
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: p,
        width: ctx.cellSize * _rand(i * 23 + 7, 0.5, 1.0) * boost,
        height: ctx.cellSize * _rand(i * 29 + 11, 0.5, 1.0) * boost,
        rotation: _rand(i * 31 + 13, -0.32, 0.32),
        opacity: (opacity * boost).clamp(0.0, 0.85),
      );
    }
    ctx.canvas.restore();
  }

  static void _paintComicSpiderverseV2Halftone(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.comicSpiderverseV2;
    final patches = ctx.comicSpiderverseSprites.halftones;
    if (patches.isEmpty) return;
    final boost = cfg.enableDebugBoost ? 2.0 : 1.0;
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < min(4, ctx.pathPoints.length ~/ 4 + 1); i++) {
      final idx = max(0, ctx.pathPoints.length - 1 - i * 2);
      final p = ctx.pathPoints[idx];
      final sprite = patches[(ctx.visualFrame + i) % patches.length];
      final opacity = _rand(
        idx * 41 + ctx.visualFrame,
        cfg.halftoneOpacityMin,
        cfg.halftoneOpacityMax,
      );
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: p + Offset(_rand(i * 17 + 3, -8, 8), _rand(i * 19 + 5, -8, 8)),
        width: ctx.cellSize * _rand(i * 23 + 7, 0.8, 2.0) * boost,
        height: ctx.cellSize * _rand(i * 29 + 9, 0.8, 2.0) * boost,
        rotation: _rand(i * 31 + 13, -0.6, 0.6),
        opacity: (opacity * boost).clamp(0.0, 0.9),
      );
    }
    ctx.canvas.restore();
  }

  static void _paintComicSpiderverseV2GlitchSlices(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.comicSpiderverseV2;
    final sprite = ctx.comicSpiderverseSprites.frameSlice;
    if (sprite == null) return;
    final stepped = _comicSpiderverseV2SteppedSeed(ctx);
    if (_rand(stepped + 5, 0, 1) > (cfg.glitchFrequency * 0.45)) return;
    final durMs = _rand(
      stepped + 11,
      cfg.glitchDurationMin.toDouble(),
      cfg.glitchDurationMax.toDouble(),
    );
    final gate = ((ctx.visualFrame * 41.0) % 1000);
    if (gate > durMs) return;

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    final slices = 1 + (_rand(stepped + 17, 0, 1.99)).floor();
    for (var i = 0; i < slices; i++) {
      final p = _samplePoint(ctx.pathPoints, _rand(stepped + i * 31, 0.1, 0.9));
      if (p == null) continue;
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: p +
            Offset(
                _rand(stepped + i * 37, 8, 22), _rand(stepped + i * 41, -2, 2)),
        width: ctx.cellSize * _rand(stepped + i * 43, 1.3, 2.2),
        height: ctx.cellSize * _rand(stepped + i * 47, 0.3, 0.5),
        rotation: _rand(stepped + i * 53, -0.08, 0.08),
        opacity: _rand(stepped + i * 59, 0.55, 0.95),
      );
    }
    ctx.canvas.restore();
  }

  static void _paintComicSpiderverseV2Particles(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.comicSpiderverseV2;
    final dot = ctx.comicSpiderverseSprites.dotParticle;
    final star = ctx.comicSpiderverseSprites.starParticle;
    if (dot == null && star == null) return;
    final boost = cfg.enableDebugBoost ? 2.0 : 1.0;
    final count = (cfg.particleMaxActive * boost).round().clamp(12, 24);
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < count; i++) {
      final seed = 26011 + i * 67 + _comicSpiderverseV2SteppedSeed(ctx);
      final t = _rand(seed, 0.0, 1.0);
      final p = _samplePoint(ctx.pathPoints, t);
      final tan = _sampleTangent(ctx.pathPoints, t);
      if (p == null || tan == null) continue;
      final isStar = _rand(seed + 3, 0, 1) < 0.18;
      final sprite = isStar ? star : dot;
      final lifeMs = _rand(seed + 7, 320, 620);
      final life = ((ctx.visualFrame * 41.0 + i * 31) % lifeMs) / lifeMs;
      final alpha = (1 - life) * (isStar ? 0.9 : 0.64);
      final n = Offset(-tan.dy, tan.dx);
      final center = p +
          n * (ctx.cellSize * _rand(seed + 11, -0.1, 0.1)) +
          tan * (ctx.cellSize * 0.06 * life);
      final scale =
          isStar ? _rand(seed + 13, 0.5, 1.1) : _rand(seed + 17, 0.4, 0.9);
      if (sprite != null) {
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: sprite,
          center: center,
          width: ctx.cellSize * scale,
          height: ctx.cellSize * scale,
          rotation: _rand(seed + 19, -1.2, 1.2),
          opacity: alpha.clamp(0.0, 1.0),
        );
      }
    }
    ctx.canvas.restore();
  }

  static void _paintComicSpiderverseV2ComicSpawns(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.comicSpiderverseV2;
    final bubbles = ctx.comicSpiderverseSprites.bubbles;
    final bursts = ctx.comicSpiderverseSprites.bursts;
    final texts = ctx.comicSpiderverseSprites.texts;
    final inks = ctx.comicSpiderverseSprites.inks;
    final sprites = <ui.Image>[
      ...bubbles,
      ...bubbles,
      ...texts,
      ...texts,
      ...bursts,
      ...inks,
    ];
    if (sprites.isEmpty) return;
    final pathLen = _polylineLength(ctx.pathPoints);
    if (pathLen < 12) return;
    final spacing = _rand(
      _comicSpiderverseV2SteppedSeed(ctx) + 5,
      cfg.comicElementSpawnDistanceMin.toDouble(),
      cfg.comicElementSpawnDistanceMax.toDouble(),
    );
    final active =
        min(cfg.comicElementMaxActive, max(2, (pathLen / spacing).floor()));
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < active; i++) {
      final d = ((i + 1) * spacing).clamp(0.0, pathLen);
      final p = _samplePointAtDistance(ctx.pathPoints, d);
      if (p == null) continue;
      final sprite = sprites[(ctx.visualFrame + i * 3) % sprites.length];
      final lifeMs = _rand(28011 + i * 17, 900, 1550);
      final life = ((ctx.visualFrame * 41.0 + i * 23) % lifeMs) / lifeMs;
      final alpha = max(0.34, (1 - life).clamp(0.0, 1.0) * 0.94);
      final pop = life < 0.26 ? (0.6 + (life / 0.26) * 0.55) : 1.0;
      final t = (pathLen <= 0.0001) ? 0.0 : (d / pathLen).clamp(0.0, 1.0);
      final tan = _sampleTangent(ctx.pathPoints, t) ?? const Offset(1, 0);
      final n = Offset(-tan.dy, tan.dx);
      final side = i.isEven ? 1.0 : -1.0;
      final decalOffset =
          n * (ctx.cellSize * _rand(28021 + i * 13, 0.22, 0.38) * side);
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: p + decalOffset + Offset(0, -ctx.cellSize * 0.1 * life),
        width: ctx.cellSize * _rand(28031 + i * 19, 0.78, 1.3) * pop,
        height: ctx.cellSize * _rand(28037 + i * 23, 0.68, 1.15) * pop,
        rotation: _rand(28041 + i * 29, -20, 20) * pi / 180.0,
        opacity: alpha,
      );
    }
    ctx.canvas.restore();
  }

  static void _paintComicSpiderverseV2NodeImpacts(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.comicSpiderverseV2;
    final points = ctx.pathPoints;
    if (points.isEmpty) return;
    final stepped = _comicSpiderverseV2SteppedSeed(ctx);
    if (ctx.visualFrame % 3 != 0 && _rand(stepped + 3, 0, 1) > 0.2) return;
    final bursts = ctx.comicSpiderverseSprites.bursts;
    if (bursts.isEmpty) return;
    final inks = ctx.comicSpiderverseSprites.inks;
    final half = ctx.comicSpiderverseSprites.halftones;
    final texts = ctx.comicSpiderverseSprites.texts;
    final p = points.last;
    final pop =
        Curves.easeOutBack.transform((ctx.visualPhase % 1.0).clamp(0.0, 1.0));
    final scale = _rand(
          stepped + 9,
          cfg.nodeBurstScaleMin,
          cfg.nodeBurstScaleMax,
        ) *
        (0.8 + pop * 0.4);
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    final drawInk = inks.isNotEmpty && _rand(stepped + 13, 0, 1) < 0.52;
    final drawHalftone = !drawInk && half.isNotEmpty;
    if (drawInk) {
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: inks[ctx.visualFrame % inks.length],
        center: p,
        width: ctx.cellSize * scale * 1.1,
        height: ctx.cellSize * scale * 1.1,
        rotation: _rand(ctx.visualFrame + 11, -0.26, 0.26),
        opacity:
            _rand(ctx.visualFrame + 13, cfg.inkOpacityMin, cfg.inkOpacityMax),
      );
    }
    if (drawHalftone) {
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: half[ctx.visualFrame % half.length],
        center: p,
        width: ctx.cellSize * scale * 1.35,
        height: ctx.cellSize * scale * 1.35,
        rotation: _rand(ctx.visualFrame + 17, -0.3, 0.3),
        opacity: _rand(
          ctx.visualFrame + 19,
          cfg.halftoneOpacityMin,
          cfg.halftoneOpacityMax,
        ),
      );
    }
    _drawTrailSprite(
      canvas: ctx.canvas,
      sprite: bursts[ctx.visualFrame % bursts.length],
      center: p,
      width: ctx.cellSize * scale * 1.2,
      height: ctx.cellSize * scale * 1.2,
      rotation: _rand(ctx.visualFrame + 23, -0.24, 0.24),
      opacity: 0.92,
    );
    if (texts.isNotEmpty &&
        _rand(ctx.visualFrame + 29, 0, 1) < (cfg.nodeTextSpawnChance * 0.6)) {
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: texts[ctx.visualFrame % texts.length],
        center: p + Offset(0, -ctx.cellSize * 0.52),
        width: ctx.cellSize * _rand(ctx.visualFrame + 31, 0.72, 1.18),
        height: ctx.cellSize * _rand(ctx.visualFrame + 37, 0.62, 1.08),
        rotation: _rand(ctx.visualFrame + 41, -0.25, 0.25),
        opacity: 0.97,
      );
    }
    ctx.canvas.restore();
  }

  static int _comicSpiderverseV2SteppedSeed(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.comicSpiderverseV2;
    final jitter =
        ((ctx.visualFrame * 17) % (max(1, cfg.steppedFrameJitter * 2 + 1))) -
            cfg.steppedFrameJitter;
    final stepMs = (cfg.steppedFrameMs + jitter).clamp(38, 46).toInt();
    final steppedMs = ((ctx.nowSeconds * 1000).floor() ~/ stepMs) * stepMs;
    return steppedMs;
  }

  static void _paintComicSpiderverseRebuiltBase(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.comicSpiderverseRebuilt;
    final sprites = ctx.comicSpiderverseRebuiltSprites;
    final debugBoost = cfg.debugMode ? 1.5 : 1.0;
    final stepped = _comicSpiderverseRebuiltSteppedSeed(ctx);
    final isImpactWindow = (ctx.visualFrame % 11) <= 2;
    final chromaPulse = isImpactWindow ? cfg.nodeHitChromaticBoost : 1.0;

    final computedSupportWidth =
        ctx.baseStrokeWidth * ctx.trailSkin.thickness * 2.1;
    final supportWidth = max(ctx.cellSize * 0.82, computedSupportWidth)
            .clamp(cfg.supportLineMinPx, cfg.supportLineMaxPx) *
        debugBoost;

    final support = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = supportWidth
      ..color = const Color(0xFFF4FAFF).withOpacity(cfg.supportLineOpacity);

    final cyan = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = supportWidth * 0.9
      ..color = const Color(0xFF68E8FF)
          .withOpacity((cfg.chromaticOpacity * 0.92).clamp(0.0, 1.0));
    final magenta = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..strokeWidth = supportWidth * 0.9
      ..color = const Color(0xFFFF5BCB)
          .withOpacity((cfg.chromaticOpacity * 0.9).clamp(0.0, 1.0));

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);

    // Layer C: offset shadow underlay.
    if (sprites.offsetShadow != null) {
      final totalLen = _polylineLength(ctx.pathPoints);
      final spacing = max(26.0, supportWidth * 2.05);
      final stamps = max(1, (totalLen / spacing).floor());
      for (var i = 0; i <= stamps; i++) {
        final d = (totalLen * i / max(1, stamps)).clamp(0.0, totalLen);
        final p = _samplePointAtDistance(ctx.pathPoints, d);
        final tan = _sampleTangentAtDistance(ctx.pathPoints, d);
        if (p == null || tan == null) continue;
        final n = Offset(-tan.dy, tan.dx);
        final center = p +
            n * (supportWidth * 0.15) +
            _rebuiltSwayOffset(
              tangent: tan,
              frame: ctx.visualFrame,
              slot: i,
              magnitudePx: supportWidth * cfg.swayAmount,
              speed: cfg.swaySpeed,
            );
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: sprites.offsetShadow!,
          center: center,
          width: supportWidth *
              cfg.offsetShadowScale *
              _rand(stepped + i * 17, 1.15, 1.75),
          height: supportWidth *
              cfg.offsetShadowScale *
              _rand(stepped + i * 23, 0.5, 0.82),
          rotation: atan2(tan.dy, tan.dx),
          opacity:
              (cfg.offsetShadowOpacity * _rand(stepped + i * 29, 0.78, 1.0))
                  .clamp(0.0, 1.0),
        );
      }
    }

    // Layer D: support line for readability.
    ctx.canvas.drawPath(ctx.pathCurve, support);

    // Layer E: main streak sprites (dominant visual).
    if (sprites.glitchStreak != null) {
      final totalLen = _polylineLength(ctx.pathPoints);
      final spacing = _rand(
        stepped + 41,
        cfg.streakSpacingMinPx,
        cfg.streakSpacingMaxPx,
      );
      final stamps =
          max(1, (totalLen / max(1.0, spacing / debugBoost)).floor());
      for (var i = 0; i <= stamps; i++) {
        final d = (totalLen * i / max(1, stamps)).clamp(0.0, totalLen);
        final p = _samplePointAtDistance(ctx.pathPoints, d);
        final tan = _sampleTangentAtDistance(ctx.pathPoints, d);
        if (p == null || tan == null) continue;
        final center = p +
            _rebuiltSwayOffset(
              tangent: tan,
              frame: ctx.visualFrame,
              slot: i + 19,
              magnitudePx: supportWidth * cfg.swayAmount * 0.7,
              speed: cfg.swaySpeed,
            );
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: sprites.glitchStreak!,
          center: center,
          width: supportWidth * _rand(stepped + i * 43, 1.55, 2.2) * debugBoost,
          height:
              supportWidth * _rand(stepped + i * 47, 0.88, 1.22) * debugBoost,
          rotation:
              atan2(tan.dy, tan.dx) + _rand(stepped + i * 53, -0.05, 0.05),
          opacity: (cfg.mainSpriteOpacity * _rand(stepped + i * 59, 0.95, 1.0))
              .clamp(0.0, 1.0),
        );
      }
      if (ctx.pathPoints.length >= 3) {
        for (var i = 1; i < ctx.pathPoints.length - 1; i++) {
          final prev = ctx.pathPoints[i] - ctx.pathPoints[i - 1];
          final next = ctx.pathPoints[i + 1] - ctx.pathPoints[i];
          final prevLen = prev.distance;
          final nextLen = next.distance;
          if (prevLen <= 0.0001 || nextLen <= 0.0001) continue;
          final dot = (prev.dx / prevLen) * (next.dx / nextLen) +
              (prev.dy / prevLen) * (next.dy / nextLen);
          if (dot > 0.95) continue;
          _drawTrailSprite(
            canvas: ctx.canvas,
            sprite: sprites.glitchStreak!,
            center: ctx.pathPoints[i],
            width: supportWidth * 2.35,
            height: supportWidth * 1.45,
            rotation: atan2(next.dy, next.dx),
            opacity: cfg.mainSpriteOpacity.clamp(0.0, 1.0),
          );
        }
      }
    }

    // Layer F: strong chromatic split.
    final swayChroma = sin(ctx.visualFrame * 0.22 * cfg.swaySpeed) * 0.45;
    final chromaDx =
        ((cfg.chromaticOffsetX * chromaPulse) + swayChroma).clamp(2.5, 5.0);
    final chromaDy = ((cfg.chromaticOffsetY * chromaPulse) + swayChroma * 0.45)
        .clamp(0.8, 1.8);
    ctx.canvas.drawPath(
      ctx.pathCurve.shift(Offset(-chromaDx, -chromaDy)),
      cyan,
    );
    ctx.canvas.drawPath(
      ctx.pathCurve.shift(Offset(chromaDx, chromaDy)),
      magenta,
    );

    ctx.canvas.restore();
  }

  static void _paintComicSpiderverseRebuiltVfx(TrailRenderContext ctx) {
    if (ctx.pathPoints.length < 2) return;
    final cfg = ctx.trailSkin.comicSpiderverseRebuilt;
    final anchors = _buildComicRebuiltAnchors(ctx, cfg);
    final placed = <_RebuiltPlacement>[];
    var bubbleCount = 0;
    var textCount = 0;

    _paintComicRebuiltHalftone(ctx, cfg, anchors, placed);
    _paintComicRebuiltInk(ctx, cfg, anchors, placed);
    _paintComicRebuiltBursts(ctx, cfg, anchors, placed, () {
      textCount += 1;
    });
    _paintComicRebuiltParticles(ctx, cfg, anchors);
    _paintComicRebuiltDecals(
      ctx,
      cfg,
      anchors,
      placed,
      onBubble: () => bubbleCount += 1,
      onText: () => textCount += 1,
      canSpawnBubble: () => bubbleCount < cfg.bubbleMaxActive,
      canSpawnText: () => textCount < cfg.textMaxActive,
    );
    _paintComicRebuiltLingeringCellDecals(ctx, cfg, placed);
    _paintComicRebuiltFrameSlice(ctx, cfg, anchors, placed);
  }

  static List<_RebuiltAnchor> _buildComicRebuiltAnchors(
    TrailRenderContext ctx,
    ComicSpiderverseRebuiltTrailConfig cfg,
  ) {
    final anchors = <_RebuiltAnchor>[];
    final points = ctx.pathPoints;
    final head = points.last;
    final headDir = (points.last - points[points.length - 2]);
    final headAngle = atan2(headDir.dy, headDir.dx);
    anchors.add(
      _RebuiltAnchor(
        type: _RebuiltAnchorType.nodeHit,
        center: head,
        angle: headAngle,
      ),
    );

    for (var i = max(1, points.length - 7); i < points.length - 1; i++) {
      if (i <= 0 || i >= points.length - 1) continue;
      final a = points[i] - points[i - 1];
      final b = points[i + 1] - points[i];
      final la = a.distance;
      final lb = b.distance;
      if (la < 0.0001 || lb < 0.0001) continue;
      final dot = (a.dx / la) * (b.dx / lb) + (a.dy / la) * (b.dy / lb);
      if (dot > 0.56) continue;
      anchors.add(
        _RebuiltAnchor(
          type: _RebuiltAnchorType.sharpTurn,
          center: points[i],
          angle: atan2(b.dy, b.dx),
        ),
      );
      break;
    }

    final pathLen = _polylineLength(points);
    if (pathLen >= cfg.longSegmentSpawnMinPx) {
      final spacing = _rand(ctx.visualFrame + 9107, cfg.longSegmentSpawnMinPx,
          cfg.longSegmentSpawnMaxPx);
      final d = (pathLen - spacing * 0.5).clamp(0.0, pathLen);
      final p = _samplePointAtDistance(points, d);
      final t = pathLen <= 0.0001 ? 0.0 : d / pathLen;
      final tan = _sampleTangent(points, t);
      if (p != null && tan != null) {
        anchors.add(
          _RebuiltAnchor(
            type: _RebuiltAnchorType.longSegmentMilestone,
            center: p,
            angle: atan2(tan.dy, tan.dx),
          ),
        );
      }
    }
    return anchors;
  }

  static void _paintComicRebuiltHalftone(
    TrailRenderContext ctx,
    ComicSpiderverseRebuiltTrailConfig cfg,
    List<_RebuiltAnchor> anchors,
    List<_RebuiltPlacement> placed,
  ) {
    final patches = ctx.comicSpiderverseRebuiltSprites.halftones;
    if (patches.isEmpty) return;
    var count = 0;
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < anchors.length && count < cfg.halftoneMaxActive; i++) {
      final a = anchors[i];
      if (a.type == _RebuiltAnchorType.longSegmentMilestone) continue;
      final sprite = patches[(ctx.visualFrame + i) % patches.length];
      final scale = a.type == _RebuiltAnchorType.nodeHit ? 1.05 : 0.85;
      final radius = ctx.cellSize * 0.46 * scale;
      final center = a.center;
      final allowed = _canPlaceRebuiltDecal(
        ctx,
        center: center,
        radius: radius,
        placed: placed,
        guardNodes: true,
      );
      if (!allowed) {
        _paintRebuiltDensityDebug(ctx, center, radius, false);
        continue;
      }
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: center,
        width: ctx.cellSize * scale,
        height: ctx.cellSize * scale,
        rotation: _rand(ctx.visualFrame + i * 31, -0.25, 0.25),
        opacity: cfg.halftoneOpacity,
      );
      placed.add(_RebuiltPlacement(center: center, radius: radius));
      count++;
      _paintRebuiltDensityDebug(ctx, center, radius, true);
    }
    ctx.canvas.restore();
  }

  static void _paintComicRebuiltInk(
    TrailRenderContext ctx,
    ComicSpiderverseRebuiltTrailConfig cfg,
    List<_RebuiltAnchor> anchors,
    List<_RebuiltPlacement> placed,
  ) {
    final inks = ctx.comicSpiderverseRebuiltSprites.inks;
    if (inks.isEmpty) return;
    var count = 0;
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < anchors.length && count < cfg.inkMaxActive; i++) {
      final a = anchors[i];
      if (a.type == _RebuiltAnchorType.longSegmentMilestone) continue;
      if (a.type == _RebuiltAnchorType.sharpTurn &&
          _rand(ctx.visualFrame + i * 41, 0, 1) > 0.6) {
        continue;
      }
      final n = Offset(-sin(a.angle), cos(a.angle));
      final center = a.center + n * (ctx.cellSize * 0.14);
      final radius = ctx.cellSize * 0.42;
      final allowed = _canPlaceRebuiltDecal(
        ctx,
        center: center,
        radius: radius,
        placed: placed,
        guardNodes: true,
      );
      if (!allowed) {
        _paintRebuiltDensityDebug(ctx, center, radius, false);
        continue;
      }
      final sprite = inks[(ctx.visualFrame + i * 3) % inks.length];
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: center,
        width: ctx.cellSize * _rand(ctx.visualFrame + i * 13, 0.72, 0.98),
        height: ctx.cellSize * _rand(ctx.visualFrame + i * 17, 0.68, 0.94),
        rotation: _rand(ctx.visualFrame + i * 19, -0.22, 0.22),
        opacity: cfg.inkOpacity,
      );
      placed.add(_RebuiltPlacement(center: center, radius: radius));
      count++;
      _paintRebuiltDensityDebug(ctx, center, radius, true);
    }
    ctx.canvas.restore();
  }

  static void _paintComicRebuiltBursts(
    TrailRenderContext ctx,
    ComicSpiderverseRebuiltTrailConfig cfg,
    List<_RebuiltAnchor> anchors,
    List<_RebuiltPlacement> placed,
    VoidCallback onTextSpawn,
  ) {
    final sprites = ctx.comicSpiderverseRebuiltSprites;
    final bursts = sprites.bursts;
    if (bursts.isEmpty) return;
    var count = 0;
    var textCount = 0;

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < anchors.length && count < cfg.burstMaxActive; i++) {
      final a = anchors[i];
      if (a.type == _RebuiltAnchorType.longSegmentMilestone) continue;
      if (a.type == _RebuiltAnchorType.sharpTurn &&
          _rand(ctx.visualFrame + i * 23, 0, 1) > 0.45) {
        continue;
      }
      final life = ((ctx.visualFrame + i * 3) % 10) / 10.0;
      final pop = life < 0.5
          ? 0.7 + (life / 0.5) * 0.45
          : 1.15 - ((life - 0.5) / 0.5) * 0.15;
      final scale = a.type == _RebuiltAnchorType.nodeHit ? 1.4 : 1.08;
      final radius = ctx.cellSize * 0.56 * scale;
      final center = a.center;
      final allowed = _canPlaceRebuiltDecal(
        ctx,
        center: center,
        radius: radius,
        placed: placed,
        guardNodes: false,
      );
      if (!allowed) continue;
      final sprite = bursts[(ctx.visualFrame + i) % bursts.length];
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: center,
        width: ctx.cellSize * scale * pop,
        height: ctx.cellSize * scale * pop,
        rotation: _rand(ctx.visualFrame + i * 31, -0.2, 0.2),
        opacity: cfg.burstOpacity,
      );
      placed.add(_RebuiltPlacement(center: center, radius: radius));
      count++;

      if (sprites.texts.isNotEmpty && textCount < cfg.textMaxActive) {
        final chance = a.type == _RebuiltAnchorType.nodeHit
            ? cfg.nodeTextSpawnChance
            : cfg.turnTextSpawnChance;
        if (_rand(ctx.visualFrame + i * 43, 0, 1) <= chance) {
          final n = Offset(-sin(a.angle), cos(a.angle));
          final textCenter = center +
              n * (ctx.cellSize * 0.38) +
              _rebuiltSwayOffset(
                tangent: Offset(cos(a.angle), sin(a.angle)),
                frame: ctx.visualFrame,
                slot: i + 101,
                magnitudePx: ctx.cellSize * 0.05,
                speed: cfg.swaySpeed,
              );
          final textRadius = ctx.cellSize * 0.38;
          if (_canPlaceRebuiltDecal(
            ctx,
            center: textCenter,
            radius: textRadius,
            placed: placed,
            guardNodes: true,
          )) {
            final text =
                sprites.texts[(ctx.visualFrame + i) % sprites.texts.length];
            _drawTrailSprite(
              canvas: ctx.canvas,
              sprite: text,
              center: textCenter,
              width: ctx.cellSize * _rand(ctx.visualFrame + i * 47, 0.82, 1.12),
              height:
                  ctx.cellSize * _rand(ctx.visualFrame + i * 53, 0.74, 1.02),
              rotation: _rand(ctx.visualFrame + i * 59, -0.2, 0.2),
              opacity: cfg.textOpacity,
            );
            placed
                .add(_RebuiltPlacement(center: textCenter, radius: textRadius));
            textCount++;
            onTextSpawn();
          }
        }
      }
    }
    ctx.canvas.restore();
    if (count > 0 && _rebuiltLastLoggedBurstFrame != ctx.visualFrame) {
      _rebuiltLastLoggedBurstFrame = ctx.visualFrame;
      debugPrint('[SpiderverseRebuilt] node hit burst spawned');
    }
  }

  static void _paintComicRebuiltParticles(
    TrailRenderContext ctx,
    ComicSpiderverseRebuiltTrailConfig cfg,
    List<_RebuiltAnchor> anchors,
  ) {
    final dot = ctx.comicSpiderverseRebuiltSprites.dotParticle;
    final star = ctx.comicSpiderverseRebuiltSprites.starParticle;
    if (dot == null && star == null) return;

    final stepped = _comicSpiderverseRebuiltSteppedSeed(ctx);
    final count = cfg.particleMaxActive.clamp(32, 60);
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var slot = 0; slot < count; slot++) {
      final seed = 61011 + slot * 31 + stepped;
      final t = _rand(seed + 3, 0.0, 1.0);
      final p = _samplePoint(ctx.pathPoints, t);
      final tan = _sampleTangent(ctx.pathPoints, t);
      if (p == null || tan == null) continue;
      var starChance = 0.08;
      if (anchors.any((a) => (a.center - p).distance < ctx.cellSize * 0.7)) {
        starChance = 0.18;
      }
      final isStar = _rand(seed + 7, 0, 1) < starChance;
      final sprite = isStar ? star : dot;
      if (sprite == null) continue;
      final lifeMs = _rand(seed + 11, 340, 700);
      final life = ((ctx.visualFrame * 41.0 + slot * 23) % lifeMs) / lifeMs;
      final alpha = (1 - life) * (isStar ? 0.84 : 0.56);
      final n = Offset(-tan.dy, tan.dx);
      final drift = n * (ctx.cellSize * _rand(seed + 13, -0.08, 0.08)) +
          tan * (ctx.cellSize * 0.06 * life);
      final scale =
          isStar ? _rand(seed + 17, 0.58, 1.02) : _rand(seed + 19, 0.42, 0.82);
      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: p + drift,
        width: ctx.cellSize * scale,
        height: ctx.cellSize * scale,
        rotation: _rand(seed + 23, -0.8, 0.8),
        opacity: alpha.clamp(0.0, 1.0),
      );
    }
    ctx.canvas.restore();
  }

  static void _paintComicRebuiltDecals(
    TrailRenderContext ctx,
    ComicSpiderverseRebuiltTrailConfig cfg,
    List<_RebuiltAnchor> anchors,
    List<_RebuiltPlacement> placed, {
    required VoidCallback onBubble,
    required VoidCallback onText,
    required bool Function() canSpawnBubble,
    required bool Function() canSpawnText,
  }) {
    if (anchors.isEmpty) return;
    final bubbles = ctx.comicSpiderverseRebuiltSprites.bubbles;
    final texts = ctx.comicSpiderverseRebuiltSprites.texts;
    final bursts = ctx.comicSpiderverseRebuiltSprites.bursts;

    var spawned = false;
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (final a in anchors) {
      if (a.type != _RebuiltAnchorType.longSegmentMilestone) continue;
      if (placed.length >= cfg.decalMaxActive + cfg.burstMaxActive) break;
      if (_rand(ctx.visualFrame + 7101, 0, 1) > 0.52) continue;
      final n = Offset(-sin(a.angle), cos(a.angle));
      final center = a.center +
          n * (ctx.cellSize * 0.34) +
          _rebuiltSwayOffset(
            tangent: Offset(cos(a.angle), sin(a.angle)),
            frame: ctx.visualFrame,
            slot: 201,
            magnitudePx: ctx.cellSize * 0.05,
            speed: cfg.swaySpeed,
          );
      final radius = ctx.cellSize * 0.4;
      if (!_canPlaceRebuiltDecal(
        ctx,
        center: center,
        radius: radius,
        placed: placed,
        guardNodes: true,
      )) {
        _paintRebuiltDensityDebug(ctx, center, radius, false);
        continue;
      }

      if (canSpawnBubble() && bubbles.isNotEmpty) {
        final bubble = bubbles[ctx.visualFrame % bubbles.length];
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: bubble,
          center: center,
          width: ctx.cellSize * _rand(ctx.visualFrame + 7111, 0.92, 1.26),
          height: ctx.cellSize * _rand(ctx.visualFrame + 7121, 0.82, 1.14),
          rotation: _rand(ctx.visualFrame + 7131, -0.16, 0.16),
          opacity: cfg.bubbleOpacity,
        );
        onBubble();
        spawned = true;
      } else if (canSpawnText() && texts.isNotEmpty) {
        final text = texts[ctx.visualFrame % texts.length];
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: text,
          center: center,
          width: ctx.cellSize * _rand(ctx.visualFrame + 7141, 0.88, 1.22),
          height: ctx.cellSize * _rand(ctx.visualFrame + 7151, 0.78, 1.12),
          rotation: _rand(ctx.visualFrame + 7161, -0.14, 0.14),
          opacity: cfg.textOpacity,
        );
        onText();
        spawned = true;
      } else if (bursts.isNotEmpty) {
        final burst = bursts[ctx.visualFrame % bursts.length];
        _drawTrailSprite(
          canvas: ctx.canvas,
          sprite: burst,
          center: center,
          width: ctx.cellSize * 0.96,
          height: ctx.cellSize * 0.96,
          rotation: _rand(ctx.visualFrame + 7171, -0.2, 0.2),
          opacity: cfg.burstOpacity * 0.7,
        );
        spawned = true;
      }
      placed.add(_RebuiltPlacement(center: center, radius: radius));
      _paintRebuiltDensityDebug(ctx, center, radius, true);
      break;
    }
    ctx.canvas.restore();
    if (spawned && _rebuiltLastLoggedDecalFrame != ctx.visualFrame) {
      _rebuiltLastLoggedDecalFrame = ctx.visualFrame;
      debugPrint('[SpiderverseRebuilt] decal spawned: bubble / POW / BZZ');
    }
  }

  static void _paintComicRebuiltFrameSlice(
    TrailRenderContext ctx,
    ComicSpiderverseRebuiltTrailConfig cfg,
    List<_RebuiltAnchor> anchors,
    List<_RebuiltPlacement> placed,
  ) {
    final slice = ctx.comicSpiderverseRebuiltSprites.frameSlice;
    if (slice == null || anchors.isEmpty) return;
    if (cfg.frameSliceMaxActive <= 0) return;
    final stepped = _comicSpiderverseRebuiltSteppedSeed(ctx);
    final trigger = (ctx.visualFrame % 12 == 0) ||
        (_rand(stepped + 8301, 0, 1) < 0.34 &&
            anchors
                .any((a) => a.type != _RebuiltAnchorType.longSegmentMilestone));
    if (!trigger) return;

    final a = anchors[(ctx.visualFrame + stepped) % anchors.length];
    final center = a.center +
        Offset(_rand(stepped + 17, -10, 10), _rand(stepped + 19, -3, 3));
    final radius = ctx.cellSize * 0.42;
    if (!_canPlaceRebuiltDecal(
      ctx,
      center: center,
      radius: radius,
      placed: placed,
      guardNodes: false,
    )) {
      return;
    }
    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    _drawTrailSprite(
      canvas: ctx.canvas,
      sprite: slice,
      center: center,
      width: ctx.cellSize * _rand(stepped + 23, 1.5, 2.2),
      height: ctx.cellSize * _rand(stepped + 29, 0.32, 0.48),
      rotation: _rand(stepped + 31, -0.05, 0.05),
      opacity: (cfg.frameSliceOpacity * _rand(stepped + 37, 0.9, 1.0))
          .clamp(0.0, 1.0),
    );
    ctx.canvas.restore();
    if (_rebuiltLastLoggedSliceFrame != ctx.visualFrame) {
      _rebuiltLastLoggedSliceFrame = ctx.visualFrame;
      debugPrint('[SpiderverseRebuilt] frame slice triggered');
    }
  }

  static bool _canPlaceRebuiltDecal(
    TrailRenderContext ctx, {
    required Offset center,
    required double radius,
    required List<_RebuiltPlacement> placed,
    required bool guardNodes,
  }) {
    final nearPath =
        _distanceToPolyline(center, ctx.pathPoints) <= ctx.cellSize * 0.95;
    if (!nearPath) return false;

    if (guardNodes) {
      for (final node in ctx.nodeCenters) {
        if ((node - center).distance < ctx.cellSize * 0.32 + radius * 0.55) {
          return false;
        }
      }
    }

    final boardCenter = ctx.boardRect.center;
    if ((boardCenter - center).distance < radius * 0.9) {
      return false;
    }

    for (final p in placed) {
      if ((p.center - center).distance < (p.radius + radius) * 0.78) {
        return false;
      }
    }
    return true;
  }

  static void _paintComicRebuiltLingeringCellDecals(
    TrailRenderContext ctx,
    ComicSpiderverseRebuiltTrailConfig cfg,
    List<_RebuiltPlacement> placed,
  ) {
    if (cfg.lingerDecalCount <= 0 || ctx.pathPoints.length < 2) return;
    final bubbles = ctx.comicSpiderverseRebuiltSprites.bubbles;
    final texts = ctx.comicSpiderverseRebuiltSprites.texts;
    final bursts = ctx.comicSpiderverseRebuiltSprites.bursts;
    if (bubbles.isEmpty && texts.isEmpty && bursts.isEmpty) return;

    final totalLen = _polylineLength(ctx.pathPoints);
    if (totalLen < ctx.cellSize) return;
    final holdFrames = max(6, cfg.lingerHoldFrames);
    final bucket = ctx.visualFrame ~/ holdFrames;
    final life = (ctx.visualFrame % holdFrames) / holdFrames;
    final fade = life < 0.18 ? (life / 0.18) : ((1 - life) / 0.82);
    final maxLingering = cfg.lingerDecalCount.clamp(1, 4).toInt();

    ctx.canvas.save();
    ctx.canvas.clipPath(ctx.clipPath);
    for (var i = 0; i < maxLingering; i++) {
      final seed = 98011 + bucket * 101 + i * 37;
      final d = _rand(seed + 3, 0.12, 0.92) * totalLen;
      final p = _samplePointAtDistance(ctx.pathPoints, d);
      final tan = _sampleTangentAtDistance(ctx.pathPoints, d);
      if (p == null || tan == null) continue;
      final n = Offset(-tan.dy, tan.dx);
      final jitter = n * (ctx.cellSize * _rand(seed + 5, -0.2, 0.2));
      final snapped = _snapToBoardCellCenter(ctx, p + jitter);
      if (snapped == null) continue;
      final center = snapped +
          _rebuiltSwayOffset(
            tangent: tan,
            frame: ctx.visualFrame,
            slot: 700 + i * 11,
            magnitudePx: ctx.cellSize * 0.04 * cfg.swayAmount.clamp(0.5, 1.4),
            speed: cfg.swaySpeed,
          );
      final radius = ctx.cellSize * 0.36;
      if (!_canPlaceRebuiltDecal(
        ctx,
        center: center,
        radius: radius,
        placed: placed,
        guardNodes: true,
      )) {
        continue;
      }

      final roll = _rand(seed + 7, 0, 1);
      ui.Image? sprite;
      double w = ctx.cellSize;
      double h = ctx.cellSize;
      double opacity = 0.9 * fade.clamp(0.25, 1.0);
      if (roll < 0.45 && bubbles.isNotEmpty) {
        sprite = bubbles[(bucket + i) % bubbles.length];
        w = ctx.cellSize * _rand(seed + 11, 0.96, 1.3);
        h = ctx.cellSize * _rand(seed + 13, 0.86, 1.22);
        opacity = cfg.bubbleOpacity * fade.clamp(0.28, 1.0);
      } else if (roll < 0.78 && texts.isNotEmpty) {
        sprite = texts[(bucket + i * 2) % texts.length];
        w = ctx.cellSize * _rand(seed + 17, 0.9, 1.2);
        h = ctx.cellSize * _rand(seed + 19, 0.8, 1.12);
        opacity = cfg.textOpacity * fade.clamp(0.22, 1.0);
      } else if (bursts.isNotEmpty) {
        sprite = bursts[(bucket + i * 3) % bursts.length];
        w = ctx.cellSize * _rand(seed + 23, 0.94, 1.22);
        h = ctx.cellSize * _rand(seed + 29, 0.94, 1.22);
        opacity = (cfg.burstOpacity * 0.82) * fade.clamp(0.26, 1.0);
      }
      if (sprite == null) continue;

      _drawTrailSprite(
        canvas: ctx.canvas,
        sprite: sprite,
        center: center,
        width: w,
        height: h,
        rotation: _rand(seed + 31, -0.2, 0.2),
        opacity: opacity.clamp(0.0, 1.0),
      );
      placed.add(_RebuiltPlacement(center: center, radius: radius));
      _paintRebuiltDensityDebug(ctx, center, radius, true);
    }
    ctx.canvas.restore();
  }

  static Offset? _snapToBoardCellCenter(TrailRenderContext ctx, Offset point) {
    final local = point - ctx.boardRect.topLeft;
    final cols = max(1, (ctx.boardRect.width / ctx.cellSize).floor());
    final rows = max(1, (ctx.boardRect.height / ctx.cellSize).floor());
    if (cols <= 0 || rows <= 0) return null;
    final c = (local.dx / ctx.cellSize).floor().clamp(0, cols - 1).toInt();
    final r = (local.dy / ctx.cellSize).floor().clamp(0, rows - 1).toInt();
    return Offset(
      ctx.boardRect.left + (c + 0.5) * ctx.cellSize,
      ctx.boardRect.top + (r + 0.5) * ctx.cellSize,
    );
  }

  static Offset _rebuiltSwayOffset({
    required Offset tangent,
    required int frame,
    required int slot,
    required double magnitudePx,
    required double speed,
  }) {
    final len = tangent.distance;
    if (len <= 0.0001 || magnitudePx <= 0.0001) return Offset.zero;
    final t = tangent / len;
    final n = Offset(-t.dy, t.dx);
    final phase = frame * 0.18 * speed + slot * 0.37;
    final sway = sin(phase) * magnitudePx;
    return n * sway;
  }

  static double _distanceToPolyline(Offset p, List<Offset> polyline) {
    if (polyline.length < 2) return double.infinity;
    var best = double.infinity;
    for (var i = 0; i < polyline.length - 1; i++) {
      final a = polyline[i];
      final b = polyline[i + 1];
      final d = _distanceToSegment(p, a, b);
      if (d < best) best = d;
    }
    return best;
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final abLen2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLen2 <= 0.000001) return (p - a).distance;
    final ap = p - a;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / abLen2).clamp(0.0, 1.0);
    final proj = a + ab * t;
    return (p - proj).distance;
  }

  static void _paintRebuiltDensityDebug(
    TrailRenderContext ctx,
    Offset center,
    double radius,
    bool allowed,
  ) {
    final cfg = ctx.trailSkin.comicSpiderverseRebuilt;
    if (!cfg.debugVisualDensity) return;
    ctx.canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color =
            (allowed ? Colors.greenAccent : Colors.redAccent).withOpacity(0.7),
    );
  }

  static int _comicSpiderverseRebuiltSteppedSeed(TrailRenderContext ctx) {
    final cfg = ctx.trailSkin.comicSpiderverseRebuilt;
    final jitter =
        ((ctx.visualFrame * 23) % (max(1, cfg.steppedFrameJitter * 2 + 1))) -
            cfg.steppedFrameJitter;
    final stepMs = (cfg.steppedFrameMs + jitter).clamp(38, 46).toInt();
    final steppedMs = ((ctx.nowSeconds * 1000).floor() ~/ stepMs) * stepMs;
    return steppedMs;
  }

  static double _webSegmentWidth(
    TrailRenderContext ctx,
    double t0,
    double t1,
    double base,
    WebTrailConfig cfg,
  ) {
    final t = (t0 + t1) * 0.5;
    final taper = 1.0 -
        (cfg.mainTaperStrength *
            (sin(t * pi) * 0.5 + 0.5) *
            (1.0 - ctx.phase * cfg.elasticity).clamp(0.85, 1.0));
    final noise = 1.0 +
        (sin((t * 13.0) + ctx.phase * pi * 2 * cfg.tensionSpeed) *
            cfg.mainThicknessVariance *
            0.5);
    return max(1.1, base * cfg.mainStrandWidth * taper * noise);
  }

  static Offset _segmentNormal(Offset a, Offset b) {
    final d = b - a;
    final len = d.distance;
    if (len <= 0.0001) return const Offset(0, 1);
    return Offset(-d.dy / len, d.dx / len);
  }

  static int _webPatternKey(List<Offset> points, WebTrailConfig cfg) {
    var hash = points.length * 131;
    for (var i = 0; i < points.length; i += max(1, points.length ~/ 5)) {
      final p = points[i];
      hash = (hash * 31) ^ p.dx.round();
      hash = (hash * 17) ^ p.dy.round();
    }
    hash = (hash * 13) ^ (cfg.bridgeSpacing * 1000).round();
    hash = (hash * 19) ^ (cfg.microBridgeDensity * 1000).round();
    return hash & 0x7fffffff;
  }

  static _WebBridgePattern _buildWebBridgePattern(
    int segmentCount,
    WebTrailConfig cfg,
  ) {
    final bridges = <_WebBridgeDef>[];
    final density = cfg.microBridgeDensity.clamp(0.0, 1.0);
    final maxPerSeg = cfg.maxMicroBridgesPerSegment.clamp(1, 4);
    for (var s = 0; s < segmentCount - 1; s++) {
      var countForSeg = 0;
      for (var k = 0; k < maxPerSeg; k++) {
        final seed = (s + 1) * 1009 + k * 199;
        if (_rand(seed, 0, 1) > density) continue;
        final jump = _rand(seed + 5, 1.0, 2.8).round();
        final target = s + jump;
        if (target >= segmentCount) continue;
        bridges.add(
          _WebBridgeDef(
            segA: s,
            segB: target,
            tA: _rand(seed + 11, 0.2, 0.85),
            tB: _rand(seed + 17, 0.12, 0.9),
          ),
        );
        countForSeg++;
        if (countForSeg >= maxPerSeg) break;
      }
    }
    return _WebBridgePattern(bridges: bridges);
  }

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

class _WebBridgePattern {
  const _WebBridgePattern({
    required this.bridges,
  });

  final List<_WebBridgeDef> bridges;
}

class _WebBridgeDef {
  const _WebBridgeDef({
    required this.segA,
    required this.segB,
    required this.tA,
    required this.tB,
  });

  final int segA;
  final int segB;
  final double tA;
  final double tB;
}

enum _UrbanAnchorType {
  nodeHit,
  sharpTurn,
  milestone,
}

class _UrbanAnchor {
  const _UrbanAnchor({
    required this.type,
    required this.center,
    required this.tangent,
  });

  final _UrbanAnchorType type;
  final Offset center;
  final Offset tangent;
}

class _UrbanPlacement {
  const _UrbanPlacement({
    required this.center,
    required this.radius,
  });

  final Offset center;
  final double radius;
}

enum _RebuiltAnchorType {
  nodeHit,
  sharpTurn,
  longSegmentMilestone,
}

class _RebuiltAnchor {
  const _RebuiltAnchor({
    required this.type,
    required this.center,
    required this.angle,
  });

  final _RebuiltAnchorType type;
  final Offset center;
  final double angle;
}

class _RebuiltPlacement {
  const _RebuiltPlacement({
    required this.center,
    required this.radius,
  });

  final Offset center;
  final double radius;
}
