import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/ghost_service.dart';

class GhostReplayOverlay extends StatefulWidget {
  const GhostReplayOverlay({
    super.key,
    required this.run,
    required this.startedAt,
    this.color = const Color(0xFF6DD6FF),
  });

  final GhostRun run;
  final DateTime startedAt;
  final Color color;

  @override
  State<GhostReplayOverlay> createState() => _GhostReplayOverlayState();
}

class _GhostReplayOverlayState extends State<GhostReplayOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 86400),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frames = widget.run.frames;
    if (frames.length < 2) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _ticker,
          builder: (context, _) {
            final elapsedMs = DateTime.now()
                .difference(widget.startedAt)
                .inMilliseconds
                .clamp(0, widget.run.totalTimeMs);
            final sample = _sampleGhost(frames, elapsedMs);
            if (sample == null || sample.path.length < 2) {
              return const SizedBox.shrink();
            }
            return CustomPaint(
              painter: _GhostPainter(
                path: sample.path,
                head: sample.head,
                color: widget.color,
              ),
            );
          },
        ),
      ),
    );
  }

  _GhostSample? _sampleGhost(List<GhostFrame> frames, int elapsedMs) {
    if (frames.isEmpty) return null;
    if (elapsedMs <= frames.first.timeMs) {
      final p = Offset(frames.first.x, frames.first.y);
      return _GhostSample(path: <Offset>[p], head: p);
    }

    var lo = 0;
    var hi = frames.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (frames[mid].timeMs <= elapsedMs) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    final idx = lo.clamp(0, frames.length - 1);
    final current = frames[idx];
    GhostFrame? next;
    if (idx + 1 < frames.length) {
      next = frames[idx + 1];
    }

    final path = <Offset>[];
    for (var i = 0; i <= idx; i++) {
      path.add(Offset(frames[i].x, frames[i].y));
    }

    var head = Offset(current.x, current.y);
    if (next != null && next.timeMs > current.timeMs) {
      final span = next.timeMs - current.timeMs;
      final localT = ((elapsedMs - current.timeMs) / span).clamp(0.0, 1.0);
      head = Offset.lerp(
            Offset(current.x, current.y),
            Offset(next.x, next.y),
            Curves.easeInOut.transform(localT),
          ) ??
          head;
      path.add(head);
    }
    return _GhostSample(path: path, head: head);
  }
}

class _GhostSample {
  const _GhostSample({
    required this.path,
    required this.head,
  });

  final List<Offset> path;
  final Offset head;
}

class _GhostPainter extends CustomPainter {
  const _GhostPainter({
    required this.path,
    required this.head,
    required this.color,
  });

  final List<Offset> path;
  final Offset head;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;
    final scaled = path
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList(growable: false);
    final ghostPath = _buildSmoothPath(scaled);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(4, size.width * 0.012)
      ..color = color.withOpacity(0.12);
    canvas.drawPath(ghostPath, glowPaint);

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(2.2, size.width * 0.0065)
      ..color = color.withOpacity(0.42);
    canvas.drawPath(ghostPath, linePaint);

    final headPx = Offset(head.dx * size.width, head.dy * size.height);
    final headRadius = math.max(4.5, size.width * 0.012);
    canvas.drawCircle(
      headPx,
      headRadius * 1.6,
      Paint()..color = color.withOpacity(0.15),
    );
    canvas.drawCircle(
      headPx,
      headRadius,
      Paint()..color = color.withOpacity(0.7),
    );
  }

  Path _buildSmoothPath(List<Offset> points) {
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
    for (var i = 1; i < points.length - 1; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final next = points[i + 1];
      final midpointA =
          Offset((prev.dx + current.dx) / 2, (prev.dy + current.dy) / 2);
      final midpointB =
          Offset((current.dx + next.dx) / 2, (current.dy + next.dy) / 2);
      if (i == 1) {
        pathShape.lineTo(midpointA.dx, midpointA.dy);
      }
      pathShape.quadraticBezierTo(
          current.dx, current.dy, midpointB.dx, midpointB.dy);
    }
    pathShape.lineTo(points.last.dx, points.last.dy);
    return pathShape;
  }

  @override
  bool shouldRepaint(covariant _GhostPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.head != head ||
        oldDelegate.color != color;
  }
}
