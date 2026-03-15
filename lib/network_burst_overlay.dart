import 'dart:math';

import 'package:flutter/material.dart';

class NetworkBurstOverlay extends StatefulWidget {
  const NetworkBurstOverlay({
    super.key,
    required this.visible,
    required this.duration,
    required this.accentColor,
    required this.isDark,
    this.loop = false,
    this.onCompleted,
  });

  final bool visible;
  final Duration duration;
  final Color accentColor;
  final bool isDark;
  final bool loop;
  final VoidCallback? onCompleted;

  @override
  State<NetworkBurstOverlay> createState() => _NetworkBurstOverlayState();
}

class _NetworkBurstOverlayState extends State<NetworkBurstOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_BurstNode> _nodes;
  bool _notifiedCompletion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            !_notifiedCompletion &&
            widget.onCompleted != null) {
          _notifiedCompletion = true;
          widget.onCompleted!.call();
        }
      });
    _nodes = _buildNodes();
    if (widget.visible) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant NetworkBurstOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (!oldWidget.visible && widget.visible) {
      _notifiedCompletion = false;
      _startAnimation();
    } else if (oldWidget.visible && !widget.visible) {
      _controller.stop();
      _controller.value = 0;
    } else if (oldWidget.loop != widget.loop && widget.visible) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _controller.value == 0) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = widget.loop
                ? _controller.value
                : Curves.easeOut.transform(_controller.value);
            return CustomPaint(
              painter: _NetworkBurstPainter(
                progress: progress,
                accentColor: widget.accentColor,
                isDark: widget.isDark,
                nodes: _nodes,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }

  List<_BurstNode> _buildNodes() {
    final rng = Random(23);
    final nodes = <_BurstNode>[];
    for (var i = 0; i < 26; i++) {
      final x = 0.12 + rng.nextDouble() * 0.76;
      final y = 0.1 + rng.nextDouble() * 0.8;
      nodes.add(
        _BurstNode(
          x: x,
          y: y,
          radius: 1.6 + rng.nextDouble() * 2.5,
          phase: rng.nextDouble(),
        ),
      );
    }
    return nodes;
  }

  void _startAnimation() {
    if (widget.loop) {
      _controller.repeat();
    } else {
      _controller.forward(from: 0);
    }
  }
}

class _NetworkBurstPainter extends CustomPainter {
  _NetworkBurstPainter({
    required this.progress,
    required this.accentColor,
    required this.isDark,
    required this.nodes,
  });

  final double progress;
  final Color accentColor;
  final bool isDark;
  final List<_BurstNode> nodes;

  @override
  void paint(Canvas canvas, Size size) {
    final ambient = Paint()
      ..color = (isDark ? const Color(0xFF9CC8FF) : const Color(0xFF2A4B85))
          .withOpacity((1 - progress) * (isDark ? 0.035 : 0.025));
    canvas.drawRect(Offset.zero & size, ambient);

    final center = Offset(size.width * 0.5, size.height * 0.54);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          accentColor.withOpacity(0.24 * (1 - progress * 0.75)),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.shortestSide * 0.62),
      );
    canvas.drawCircle(center, size.shortestSide * 0.62, glow);

    final nodeOffsets = <Offset>[
      for (final n in nodes) Offset(n.x * size.width, n.y * size.height),
    ];

    final baseT = progress;
    final lineReveal = Curves.easeOutCubic.transform(baseT);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2
      ..color = accentColor.withOpacity(0.2 + 0.24 * (1 - progress));

    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5)
      ..color = accentColor.withOpacity(0.12 + 0.15 * (1 - progress));

    for (var i = 0; i < nodeOffsets.length; i++) {
      for (var j = i + 1; j < nodeOffsets.length; j++) {
        final a = nodeOffsets[i];
        final b = nodeOffsets[j];
        final d = (a - b).distance;
        if (d > size.shortestSide * 0.34) continue;
        final gate = ((i * 13 + j * 7) % 100) / 100.0;
        final live = ((lineReveal + gate * 0.45) % 1.0).clamp(0.0, 1.0);
        if (live < 0.08) continue;
        final t = Curves.easeOut.transform(live);
        final to = Offset.lerp(a, b, t)!;
        canvas.drawLine(a, to, haloPaint);
        canvas.drawLine(a, to, linePaint);
      }
    }

    for (var i = 0; i < nodeOffsets.length; i++) {
      final node = nodes[i];
      final pos = nodeOffsets[i];
      final pulse = 0.65 + 0.35 * sin((progress + node.phase) * pi * 2);
      final nodeRadius = node.radius * pulse;

      final outer = Paint()
        ..color = accentColor.withOpacity(0.18 + 0.2 * (1 - progress))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.5);
      canvas.drawCircle(pos, nodeRadius * 2.8, outer);

      final core = Paint()
        ..color = const Color(0xFFE0F2FE).withOpacity(0.8 - progress * 0.45);
      canvas.drawCircle(pos, nodeRadius, core);
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkBurstPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isDark != isDark;
  }
}

class _BurstNode {
  const _BurstNode({
    required this.x,
    required this.y,
    required this.radius,
    required this.phase,
  });

  final double x;
  final double y;
  final double radius;
  final double phase;
}
