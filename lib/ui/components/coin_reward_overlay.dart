import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/coin_reward_overlay_service.dart';

class CoinRewardOverlay extends StatelessWidget {
  const CoinRewardOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<CoinRewardRequest?>(
        valueListenable: CoinRewardOverlayService.instance.activeRequest,
        builder: (context, request, _) {
          if (request == null) return const SizedBox.shrink();
          return _CoinBurstAnimation(request: request);
        },
      ),
    );
  }
}

class CoinRewardVisualTuning {
  const CoinRewardVisualTuning._();

  static const double baseCoinSizeMin = 22;
  static const double baseCoinSizeMax = 34;
  static const double initialBurstRadiusMin = 58;
  static const double initialBurstRadiusMax = 124;
  static const double trailOpacity = 0.14;
  static const double burstPhasePortion = 0.32;
}

class _CoinBurstAnimation extends StatefulWidget {
  const _CoinBurstAnimation({required this.request});

  final CoinRewardRequest request;

  @override
  State<_CoinBurstAnimation> createState() => _CoinBurstAnimationState();
}

class _CoinBurstAnimationState extends State<_CoinBurstAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_CoinParticle> _particles;
  late final Rect _targetRect;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.request.duration);
    _particles = _buildParticles(widget.request.visualCount, widget.request.id);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        CoinRewardOverlayService.instance.completeRequest(widget.request);
      }
    });
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    final target = CoinRewardOverlayService.instance.resolveTargetRect();
    final fallback = Rect.fromCenter(
      center: Offset(size.width - 68, 56),
      width: 24,
      height: 24,
    );
    _targetRect = target ?? fallback;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_CoinParticle> _buildParticles(int count, int seed) {
    final random = math.Random(seed);
    return List<_CoinParticle>.generate(count, (i) {
      final theta = (math.pi * 2 * i / count) + (random.nextDouble() * 0.42);
      final radius = CoinRewardVisualTuning.initialBurstRadiusMin +
          random.nextDouble() *
              (CoinRewardVisualTuning.initialBurstRadiusMax -
                  CoinRewardVisualTuning.initialBurstRadiusMin);
      final lift = 22 + random.nextDouble() * 54;
      final size = CoinRewardVisualTuning.baseCoinSizeMin +
          random.nextDouble() *
              (CoinRewardVisualTuning.baseCoinSizeMax -
                  CoinRewardVisualTuning.baseCoinSizeMin);
      final delay = random.nextDouble() * 0.15;
      return _CoinParticle(
        angle: theta,
        radius: radius,
        lift: lift,
        size: size,
        delay: delay,
        spin: (random.nextDouble() * 2.0 - 1.0) * 2.8,
        curveSkew: 0.8 + (random.nextDouble() * 0.6),
      );
    });
  }

  Offset _resolveOrigin(Size screenSize) {
    final origin = widget.request.origin;
    final x = origin.dx.clamp(0.0, 1.0) * screenSize.width;
    final y = origin.dy.clamp(0.0, 1.0) * screenSize.height;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final origin = _resolveOrigin(screenSize);
    final target = _targetRect.center;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final tRaw = _controller.value;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BurstHaloPainter(
                    progress: tRaw,
                    origin: origin,
                  ),
                ),
              ),
              for (final p in _particles)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CoinParticlePainter(
                      progress: tRaw,
                      particle: p,
                      origin: origin,
                      target: target,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CoinParticle {
  const _CoinParticle({
    required this.angle,
    required this.radius,
    required this.lift,
    required this.size,
    required this.delay,
    required this.spin,
    required this.curveSkew,
  });

  final double angle;
  final double radius;
  final double lift;
  final double size;
  final double delay;
  final double spin;
  final double curveSkew;
}

class _BurstHaloPainter extends CustomPainter {
  _BurstHaloPainter({
    required this.progress,
    required this.origin,
  });

  final double progress;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    final burstT =
        (progress / CoinRewardVisualTuning.burstPhasePortion).clamp(0.0, 1.0);
    if (burstT <= 0 || burstT >= 1) return;

    final eased = Curves.easeOutCubic.transform(burstT);
    final alpha = (1 - eased).clamp(0.0, 1.0);
    final radius = lerpDouble(12, 84, eased)!;
    final rect = Rect.fromCircle(center: origin, radius: radius);

    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFFFD54A).withOpacity(0.34 * alpha),
          const Color(0xFFFFA800).withOpacity(0.18 * alpha),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawCircle(origin, radius, haloPaint);
  }

  @override
  bool shouldRepaint(covariant _BurstHaloPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.origin != origin;
  }
}

class _CoinParticlePainter extends CustomPainter {
  _CoinParticlePainter({
    required this.progress,
    required this.particle,
    required this.origin,
    required this.target,
  });

  final double progress;
  final _CoinParticle particle;
  final Offset origin;
  final Offset target;

  @override
  void paint(Canvas canvas, Size size) {
    var t = (progress - particle.delay) / (1 - particle.delay);
    t = t.clamp(0.0, 1.0);
    if (t <= 0) return;

    const burstPhase = CoinRewardVisualTuning.burstPhasePortion;
    final burstT =
        Curves.easeOutBack.transform((t / burstPhase).clamp(0.0, 1.0));
    final flyTRaw = ((t - burstPhase) / (1 - burstPhase)).clamp(0.0, 1.0);
    final flyTBase = Curves.easeInOutCubic.transform(flyTRaw);
    final magnetT = Curves.easeIn.transform(flyTRaw);
    final flyT = (flyTBase * 0.58) + (magnetT * 0.42);

    final burstOffset = Offset(
      math.cos(particle.angle) * particle.radius * burstT,
      math.sin(particle.angle) * (particle.radius * 0.72) * burstT -
          particle.lift * burstT,
    );
    final start = origin + burstOffset;
    final control = Offset(
      (start.dx + target.dx) * 0.5 +
          (math.sin(particle.angle) * 52 * particle.curveSkew),
      math.min(start.dy, target.dy) - (74 + particle.lift),
    );
    final end = target;
    final pos = _quadratic(start, control, end, flyT);
    final prevPos =
        _quadratic(start, control, end, (flyT - 0.07).clamp(0.0, 1.0));

    final popT = (t / 0.18).clamp(0.0, 1.0);
    final popScale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 58,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 42,
      ),
    ]).transform(popT);

    final flyScale = lerpDouble(1.0, 0.9, flyT)!;
    final scale = popScale * flyScale;
    final alpha = (1 - (flyT * 0.92)).clamp(0.0, 1.0);
    final coinRadius = (particle.size * 0.5) * scale;
    final angle = particle.spin * (0.3 + (flyT * 3.2));

    final trailPaint = Paint()
      ..color = const Color(0xFFFFD166).withOpacity(
        CoinRewardVisualTuning.trailOpacity * alpha,
      )
      ..strokeWidth = lerpDouble(1.0, 2.4, scale.clamp(0.0, 1.4))!
      ..strokeCap = StrokeCap.round;
    if ((pos - prevPos).distance > 0.2) {
      canvas.drawLine(prevPos, pos, trailPaint);
    }

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = const Color(0xFFFFC857).withOpacity(0.26 * alpha);
    canvas.drawCircle(pos, coinRadius * 1.12, glowPaint);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final coinRect = Rect.fromCenter(
      center: Offset.zero,
      width: coinRadius * 2.05,
      height: coinRadius * 1.72,
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFFF3A6),
          Color(0xFFFFD24B),
          Color(0xFFD68C00),
        ],
      ).createShader(coinRect)
      ..color = Colors.white.withOpacity(alpha);

    canvas.drawOval(coinRect, paint);
    canvas.drawOval(
      coinRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35
        ..color = const Color(0xFFFFF0A3).withOpacity(alpha * 0.94),
    );

    final shineRect = Rect.fromCenter(
      center: Offset(-coinRadius * 0.22, -coinRadius * 0.18),
      width: coinRadius * 0.85,
      height: coinRadius * 0.44,
    );
    canvas.drawOval(
      shineRect,
      Paint()..color = Colors.white.withOpacity(0.42 * alpha),
    );
    canvas.restore();
  }

  Offset _quadratic(Offset a, Offset b, Offset c, double t) {
    final mt = 1 - t;
    return Offset(
      (mt * mt * a.dx) + (2 * mt * t * b.dx) + (t * t * c.dx),
      (mt * mt * a.dy) + (2 * mt * t * b.dy) + (t * t * c.dy),
    );
  }

  @override
  bool shouldRepaint(covariant _CoinParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.origin != origin ||
        oldDelegate.target != target ||
        oldDelegate.particle != particle;
  }
}
