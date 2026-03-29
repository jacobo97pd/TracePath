import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'trail_skin.dart';

const bool kDebugGalaxyRevealFullTexture = false;
const bool kDebugGalaxyRevealMaskPreview = false;
const bool kDebugGalaxyRevealMaskOnly = false;
const bool kGalaxyRevealWhiteEdgeBorder = true;
bool _didLogGalaxyPainterOnce = false;
int _lastGalaxyPaintDebugMs = 0;

class GalaxyRevealTrailController {
  final List<Offset> _anchorsUnit = <Offset>[];
  final List<GalaxyRevealSparkle> _sparkles = <GalaxyRevealSparkle>[];
  final math.Random _rng = math.Random();

  ui.ImageShader? _cachedShader;
  int? _cachedImageIdentity;
  Size? _cachedBoardSize;
  double? _cachedCellSize;

  double _lastRevealAtSec = -9999;
  Offset? _latestAnchorUnit;

  List<Offset> get anchorsUnit => _anchorsUnit;
  List<GalaxyRevealSparkle> get sparkles => _sparkles;
  double get lastRevealAtSec => _lastRevealAtSec;
  Offset? get latestAnchorUnit => _latestAnchorUnit;

  void reset() {
    _anchorsUnit.clear();
    _sparkles.clear();
    _latestAnchorUnit = null;
    _lastRevealAtSec = -9999;
  }

  void absorbPathUnit(
    List<Offset> pathUnit, {
    required bool enableSparkles,
    required double nowSec,
  }) {
    reset();
    if (pathUnit.isEmpty) return;
    _appendAnchor(pathUnit.first, nowSec, enableSparkles: false);
    for (var i = 1; i < pathUnit.length; i++) {
      addSegmentUnit(
        pathUnit[i - 1],
        pathUnit[i],
        enableSparkles: enableSparkles,
        nowSec: nowSec,
      );
    }
  }

  void addSegmentUnit(
    Offset from,
    Offset to, {
    required bool enableSparkles,
    required double nowSec,
  }) {
    final delta = to - from;
    final dist = delta.distance;
    if (dist <= 0.0001) {
      _appendAnchor(to, nowSec, enableSparkles: enableSparkles);
      return;
    }
    const step = 0.22; // unit interpolation to avoid reveal gaps
    final steps = math.max(1, (dist / step).ceil());
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      _appendAnchor(Offset.lerp(from, to, t)!, nowSec,
          enableSparkles: enableSparkles);
    }
  }

  void _appendAnchor(
    Offset point,
    double nowSec, {
    required bool enableSparkles,
  }) {
    if (_anchorsUnit.isNotEmpty) {
      final prev = _anchorsUnit.last;
      if ((prev - point).distance < 0.03) {
        _latestAnchorUnit = point;
        _lastRevealAtSec = nowSec;
        return;
      }
    }
    _anchorsUnit.add(point);
    if (_anchorsUnit.length > 2400) {
      _anchorsUnit.removeRange(0, _anchorsUnit.length - 2400);
    }
    _latestAnchorUnit = point;
    _lastRevealAtSec = nowSec;
    if (enableSparkles && _rng.nextDouble() < 0.22) {
      final lifetime = 0.2 + _rng.nextDouble() * 0.3;
      _sparkles.add(
        GalaxyRevealSparkle(
          pointUnit: point +
              Offset(
                (_rng.nextDouble() - 0.5) * 0.22,
                (_rng.nextDouble() - 0.5) * 0.22,
              ),
          bornAtSec: nowSec,
          lifetimeSec: lifetime,
          sizeMul: 0.7 + _rng.nextDouble() * 0.8,
        ),
      );
      if (_sparkles.length > 120) {
        _sparkles.removeRange(0, _sparkles.length - 120);
      }
    }
  }

  void pruneSparkles(double nowSec) {
    _sparkles.removeWhere((s) => (nowSec - s.bornAtSec) >= s.lifetimeSec);
  }

  ui.ImageShader obtainBoardShader({
    required ui.Image texture,
    required Rect boardRect,
    required double cellSize,
  }) {
    final imageIdentity = texture.hashCode;
    if (_cachedShader != null &&
        _cachedImageIdentity == imageIdentity &&
        _cachedBoardSize == boardRect.size &&
        _cachedCellSize == cellSize) {
      return _cachedShader!;
    }

    // Keep texture static in board space and preserve visible galaxy detail.
    // The previous larger scale could flatten detail into broad gradients.
    final textureScalePx = math.max(18.0, cellSize * 0.9);
    final scaleX = textureScalePx / texture.width;
    final scaleY = textureScalePx / texture.height;
    final matrix = Float64List.fromList(<double>[
      scaleX, 0, 0, 0,
      0, scaleY, 0, 0,
      0, 0, 1, 0,
      boardRect.left, boardRect.top, 0, 1,
    ]);
    final shader = ui.ImageShader(
      texture,
      TileMode.repeated,
      TileMode.repeated,
      matrix,
    );
    _cachedShader = shader;
    _cachedImageIdentity = imageIdentity;
    _cachedBoardSize = boardRect.size;
    _cachedCellSize = cellSize;
    return shader;
  }
}

class GalaxyRevealTrailPainter extends CustomPainter {
  const GalaxyRevealTrailPainter({
    required this.boardRect,
    required this.playableRect,
    required this.cellSize,
    required this.textureImage,
    required this.controller,
    required this.config,
    required this.nowSec,
  });

  final Rect boardRect;
  final Rect playableRect;
  final double cellSize;
  final ui.Image textureImage;
  final GalaxyRevealTrailController controller;
  final GalaxyRevealConfig config;
  final double nowSec;

  @override
  void paint(Canvas canvas, Size size) {
    final anchors = controller.anchorsUnit;
    if (anchors.isEmpty) return;

    controller.pruneSparkles(nowSec);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode && nowMs - _lastGalaxyPaintDebugMs > 400) {
      _lastGalaxyPaintDebugMs = nowMs;
      final bounds = _computeMaskBounds(
        anchors: anchors,
        radius: math.max(3.0, cellSize * config.radius),
      );
      debugPrint(
        'GALAXY PAINT start imageNull=${false} maskPoints=${anchors.length}',
      );
      debugPrint(
        'GALAXY MASK bounds=$bounds nonEmpty=${!bounds.isEmpty}',
      );
    }
    if (kDebugMode && !_didLogGalaxyPainterOnce) {
      _didLogGalaxyPainterOnce = true;
      debugPrint(
        'GALAXY PAINTER image=${textureImage.width}x${textureImage.height} playableRect=$playableRect anchors=${anchors.length}',
      );
    }

    final brushRadius = math.max(3.0, cellSize * config.radius);
    if (kDebugGalaxyRevealFullTexture) {
      canvas.save();
      canvas.clipRect(playableRect);
      canvas.drawImageRect(
        textureImage,
        Rect.fromLTWH(
          0,
          0,
          textureImage.width.toDouble(),
          textureImage.height.toDouble(),
        ),
        playableRect,
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
      return;
    }
    // True reveal-mask pipeline:
    // 1) Draw galaxy on a layer
    // 2) Build mask on a second layer
    // 3) Composite mask over galaxy with dstIn (single global mask application)
    canvas.save();
    canvas.clipRect(playableRect);
    if (kDebugGalaxyRevealMaskOnly) {
      _drawRevealMaskDebug(canvas, brushRadius);
      canvas.restore();
      return;
    }
    canvas.saveLayer(playableRect, Paint());
    canvas.drawImageRect(
      textureImage,
      Rect.fromLTWH(
        0,
        0,
        textureImage.width.toDouble(),
        textureImage.height.toDouble(),
      ),
      playableRect,
      Paint()..filterQuality = FilterQuality.medium,
    );

    if (kDebugGalaxyRevealMaskPreview) {
      _drawRevealMaskDebug(canvas, brushRadius);
    }

    // Apply mask as a full layer so outside-mask becomes fully transparent.
    // Using dstIn directly stamp-by-stamp leaves untouched destination outside stamps.
    canvas.saveLayer(
      playableRect,
      Paint()..blendMode = BlendMode.dstIn,
    );
    _drawRevealMask(
      canvas,
      brushRadius,
      blendMode: BlendMode.srcOver,
    );
    canvas.restore();

    if (kGalaxyRevealWhiteEdgeBorder) {
      _drawEdgeBorder(canvas, brushRadius);
    }

    _drawThemedOverlayFx(canvas, brushRadius);

    canvas.restore();
    canvas.restore();
  }

  void _drawRevealMask(
    Canvas canvas,
    double radius, {
    required BlendMode blendMode,
  }) {
    final innerStop = (1.0 - config.softness).clamp(0.05, 0.95);
    final maskPaint = Paint()..blendMode = blendMode;
    for (var i = 0; i < controller.anchorsUnit.length; i++) {
      final center = _unitToPixel(controller.anchorsUnit[i]);
      if (i == 0) {
        _drawFeatherStamp(
          canvas,
          center,
          radius,
          innerStop,
          maskPaint,
        );
        continue;
      }
      final prev = _unitToPixel(controller.anchorsUnit[i - 1]);
      _stampInterpolated(
        canvas: canvas,
        from: prev,
        to: center,
        radius: radius,
        innerStop: innerStop,
        paint: maskPaint,
      );
    }
  }

  void _stampInterpolated({
    required Canvas canvas,
    required Offset from,
    required Offset to,
    required double radius,
    required double innerStop,
    required Paint paint,
  }) {
    final dist = (to - from).distance;
    if (dist <= 0.001) {
      _drawFeatherStamp(canvas, to, radius, innerStop, paint);
      return;
    }
    final spacing = math.max(1.0, radius * 0.58);
    final steps = math.max(1, (dist / spacing).ceil());
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      _drawFeatherStamp(
        canvas,
        Offset.lerp(from, to, t)!,
        radius,
        innerStop,
        paint,
      );
    }
  }

  void _drawFeatherStamp(
    Canvas canvas,
    Offset center,
    double radius,
    double innerStop,
    Paint paint,
  ) {
    paint.shader = ui.Gradient.radial(
      center,
      radius,
      <Color>[
        Colors.white,
        Colors.white,
        Colors.white.withOpacity(0.0),
      ],
      <double>[
        0.0,
        innerStop,
        1.0,
      ],
    );
    canvas.drawCircle(center, radius, paint);
  }

  void _drawRevealMaskDebug(Canvas canvas, double radius) {
    final debugPaint = Paint()
      ..blendMode = BlendMode.srcOver
      ..color = const Color(0x66FF2D2D);
    for (final p in controller.anchorsUnit) {
      canvas.drawCircle(_unitToPixel(p), radius, debugPaint);
    }
  }

  void _drawEdgeBorder(Canvas canvas, double radius) {
    final anchors = controller.anchorsUnit;
    if (anchors.length < 2) {
      return;
    }

    final centerPath = Path();
    final first = _unitToPixel(anchors.first);
    centerPath.moveTo(first.dx, first.dy);
    for (var i = 1; i < anchors.length; i++) {
      final p = _unitToPixel(anchors[i]);
      centerPath.lineTo(p.dx, p.dy);
    }

    final borderThickness = math.max(0.7, radius * 0.10);
    final outerStrokeWidth = radius * 2.0 + borderThickness * 2.0;
    final innerStrokeWidth = radius * 2.0;

    canvas.saveLayer(playableRect, Paint());

    final outerPaint = Paint()
      ..blendMode = BlendMode.srcOver
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = outerStrokeWidth
      ..color = Colors.white.withOpacity(0.46);
    canvas.drawPath(centerPath, outerPaint);

    final clearInnerPaint = Paint()
      ..blendMode = BlendMode.clear
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = innerStrokeWidth;
    canvas.drawPath(centerPath, clearInnerPaint);

    canvas.restore();
  }

  void _drawThemedOverlayFx(Canvas canvas, double radius) {
    final textureKey = config.textureAsset.toLowerCase();
    if (textureKey.contains('electric_trail_reveal')) {
      _drawElectricRevealFx(canvas, radius);
      return;
    }
    if (textureKey.contains('golden_trail_reveal')) {
      _drawGoldenRevealFx(canvas, radius);
      return;
    }
    if (textureKey.contains('comic_trail_reveal')) {
      _drawComicRevealFx(canvas, radius);
    }
  }

  void _drawElectricRevealFx(Canvas canvas, double radius) {
    final anchors = controller.anchorsUnit;
    if (anchors.length < 3) return;
    final segmentCount = math.min(5, anchors.length - 1);
    final segmentStride = math.max(1, anchors.length ~/ 6);
    final start = math.max(1, anchors.length - segmentCount * segmentStride);

    for (var i = start; i < anchors.length; i += segmentStride) {
      final from = _unitToPixel(anchors[i - 1]);
      final to = _unitToPixel(anchors[i]);
      final dir = to - from;
      if (dir.distance < 0.1) continue;
      final norm = Offset(-dir.dy, dir.dx) / dir.distance;

      final jagPath = Path()..moveTo(from.dx, from.dy);
      const subdivisions = 5;
      for (var s = 1; s < subdivisions; s++) {
        final t = s / subdivisions;
        final base = Offset.lerp(from, to, t)!;
        final amp = radius * 0.22 * math.sin(nowSec * 11 + i * 0.7 + s * 1.2);
        final p = base + norm * amp;
        jagPath.lineTo(p.dx, p.dy);
      }
      jagPath.lineTo(to.dx, to.dy);

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(1.2, radius * 0.34)
        ..color = const Color(0xFF60D8FF).withOpacity(0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8);
      final corePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = math.max(0.9, radius * 0.12)
        ..color = const Color(0xFFEFFAFF).withOpacity(0.9);

      canvas.drawPath(jagPath, glowPaint);
      canvas.drawPath(jagPath, corePaint);
    }
  }

  void _drawGoldenRevealFx(Canvas canvas, double radius) {
    final anchors = controller.anchorsUnit;
    if (anchors.isEmpty) return;
    final sparkleCount = math.min(14, anchors.length);
    final stride = math.max(1, anchors.length ~/ sparkleCount);
    final latest = anchors.length - 1;

    for (var i = 0; i < sparkleCount; i++) {
      final idx = math.max(0, latest - i * stride);
      final center = _unitToPixel(anchors[idx]);
      final pulse = 0.5 + 0.5 * math.sin(nowSec * 3.2 + i * 0.9);
      final offset = Offset(
        math.sin(nowSec * 1.8 + i * 1.4) * radius * 0.42,
        math.cos(nowSec * 1.6 + i * 1.1) * radius * 0.3,
      );
      final p = center + offset;
      final dotR = math.max(0.8, radius * (0.06 + pulse * 0.05));
      canvas.drawCircle(
        p,
        dotR,
        Paint()..color = const Color(0xFFFFE28A).withOpacity(0.42 + pulse * 0.35),
      );

      if (i % 4 == 0) {
        final glint = Paint()
          ..color = const Color(0xFFFFF4D2).withOpacity(0.55 + pulse * 0.3)
          ..strokeWidth = math.max(0.9, radius * 0.06)
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          p + Offset(-radius * 0.22, 0),
          p + Offset(radius * 0.22, 0),
          glint,
        );
        canvas.drawLine(
          p + Offset(0, -radius * 0.22),
          p + Offset(0, radius * 0.22),
          glint,
        );
      }
    }
  }

  void _drawComicRevealFx(Canvas canvas, double radius) {
    final anchors = controller.anchorsUnit;
    if (anchors.length < 3) return;

    final pivotA = _unitToPixel(anchors[anchors.length ~/ 3]);
    final pivotB = _unitToPixel(anchors[(anchors.length * 2) ~/ 3]);
    final latest = _unitToPixel(anchors.last);

    _drawComicBubble(
      canvas,
      center: pivotA + Offset(radius * 1.4, -radius * 1.2),
      width: radius * 2.9,
      height: radius * 1.8,
      pulse: 0.5 + 0.5 * math.sin(nowSec * 2.1),
    );
    _drawComicBubble(
      canvas,
      center: pivotB + Offset(-radius * 1.5, radius * 1.1),
      width: radius * 2.4,
      height: radius * 1.5,
      pulse: 0.5 + 0.5 * math.cos(nowSec * 2.4),
    );

    _drawMiniWeb(
      canvas,
      center: latest + Offset(radius * 1.1, -radius * 1.1),
      radius: radius * 0.95,
    );
  }

  void _drawComicBubble(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required double pulse,
  }) {
    final bubbleRect =
        Rect.fromCenter(center: center, width: width, height: height);
    final bubblePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, width * 0.04)
      ..color = const Color(0xFFAEEBFF).withOpacity(0.4 + pulse * 0.25);
    canvas.drawOval(bubbleRect, bubblePaint);

    final tail = Path()
      ..moveTo(center.dx - width * 0.1, center.dy + height * 0.5)
      ..lineTo(center.dx - width * 0.24, center.dy + height * 0.78)
      ..lineTo(center.dx + width * 0.02, center.dy + height * 0.58);
    canvas.drawPath(tail, bubblePaint);
  }

  void _drawMiniWeb(Canvas canvas, {required Offset center, required double radius}) {
    final webPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, radius * 0.08)
      ..color = const Color(0xFFE8F5FF).withOpacity(0.48);

    for (var i = 0; i < 5; i++) {
      final ang = i * (math.pi / 4.0) + nowSec * 0.08;
      final p2 = center + Offset(math.cos(ang), math.sin(ang)) * radius;
      canvas.drawLine(center, p2, webPaint);
    }
    for (var ring = 1; ring <= 2; ring++) {
      final rr = radius * (ring / 2.2);
      final arcRect = Rect.fromCircle(center: center, radius: rr);
      canvas.drawArc(arcRect, -math.pi * 0.85, math.pi * 1.7, false, webPaint);
    }
  }

  Rect _computeMaskBounds({
    required List<Offset> anchors,
    required double radius,
  }) {
    if (anchors.isEmpty) {
      return Rect.zero;
    }
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    for (final unit in anchors) {
      final p = _unitToPixel(unit);
      minX = math.min(minX, p.dx - radius);
      minY = math.min(minY, p.dy - radius);
      maxX = math.max(maxX, p.dx + radius);
      maxY = math.max(maxY, p.dy + radius);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY).intersect(playableRect);
  }

  Offset _unitToPixel(Offset unit) {
    return Offset(
      boardRect.left + unit.dx * cellSize,
      boardRect.top + unit.dy * cellSize,
    );
  }

  @override
  bool shouldRepaint(covariant GalaxyRevealTrailPainter oldDelegate) {
    return oldDelegate.boardRect != boardRect ||
        oldDelegate.playableRect != playableRect ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.textureImage != textureImage ||
        oldDelegate.controller != controller ||
        oldDelegate.config != config ||
        oldDelegate.nowSec != nowSec;
  }
}

class GalaxyRevealSparkle {
  const GalaxyRevealSparkle({
    required this.pointUnit,
    required this.bornAtSec,
    required this.lifetimeSec,
    required this.sizeMul,
  });

  final Offset pointUnit;
  final double bornAtSec;
  final double lifetimeSec;
  final double sizeMul;
}
