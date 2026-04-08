import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
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
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
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
    if (widget.visible) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant CelebrationOverlay oldWidget) {
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

  void _startAnimation() {
    _controller.stop();
    _controller.forward(from: 0);
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
            final t = _controller.value.clamp(0.0, 1.0);

            final dimOpacity = _intervalValue(
              t,
              start: 0.0,
              end: 0.22,
              from: 0.0,
              to: widget.isDark ? 0.38 : 0.30,
            );

            final fadeIn = _intervalValue(
              t,
              start: 0.0,
              end: 0.24,
              from: 0.0,
              to: 1.0,
            );
            final fadeOut = 1.0 -
                _intervalValue(
                  t,
                  start: 0.78,
                  end: 1.0,
                  from: 0.0,
                  to: 1.0,
                );
            final contentOpacity = (fadeIn * fadeOut).clamp(0.0, 1.0);

            final scale = _scaleWithOvershoot(t);

            final blurSigma = _intervalValue(
              t,
              start: 0.0,
              end: 0.20,
              from: 5.5,
              to: 0.0,
            );

            final glowPulse = _intervalValue(
              t,
              start: 0.30,
              end: 0.58,
              from: 0.0,
              to: 1.0,
            );

            final burstOpacity =
                (0.14 + glowPulse * 0.22) * fadeOut * (widget.isDark ? 1 : 0.85);
            final burstRadius = 210.0 + glowPulse * 42.0;

            final ringProgress = _intervalValue(
              t,
              start: 0.08,
              end: 0.56,
              from: 0.0,
              to: 1.0,
            );
            final ringOpacity = (1.0 - ringProgress).clamp(0.0, 1.0) * fadeOut;
            final ringScale = 0.74 + ringProgress * 0.62;

            return Container(
              color: Colors.black.withOpacity(dimOpacity),
              child: Center(
                child: Opacity(
                  opacity: contentOpacity,
                  child: Transform.scale(
                    scale: scale,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: blurSigma,
                        sigmaY: blurSigma,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: burstRadius,
                            height: burstRadius,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  widget.accentColor.withOpacity(burstOpacity),
                                  const Color(0xFF7C3AED).withOpacity(
                                    burstOpacity * 0.45,
                                  ),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.42, 1.0],
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: ringScale,
                            child: Opacity(
                              opacity: ringOpacity,
                              child: Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF9CC2FF).withOpacity(0.55),
                                    width: 2.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _CompletedBadge(
                            accentColor: widget.accentColor,
                            glowPulse: glowPulse,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _scaleWithOvershoot(double t) {
    if (t < 0.58) {
      return _intervalValue(
        t,
        start: 0.0,
        end: 0.58,
        from: 0.75,
        to: 1.08,
      );
    }
    return _intervalValue(
      t,
      start: 0.58,
      end: 0.84,
      from: 1.08,
      to: 1.0,
    );
  }

  double _intervalValue(
    double t, {
    required double start,
    required double end,
    required double from,
    required double to,
  }) {
    if (t <= start) return from;
    if (t >= end) return to;
    final local = (t - start) / (end - start);
    return lerpDouble(from, to, Curves.easeOut.transform(local)) ?? to;
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge({
    required this.accentColor,
    required this.glowPulse,
  });

  static const String _completedLottieAsset =
      'assets/ui/completed_animation.json';

  final Color accentColor;
  final double glowPulse;

  @override
  Widget build(BuildContext context) {
    final glowStrength = 0.28 + (glowPulse * 0.22);
    final maxBadgeWidth = (MediaQuery.sizeOf(context).width - 28).clamp(
      220.0,
      520.0,
    );
    return Container(
      constraints: BoxConstraints(maxWidth: maxBadgeWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B2642),
            Color(0xFF16203A),
            Color(0xFF141B31),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFA8BEEC).withOpacity(0.78),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(glowStrength),
            blurRadius: 24 + (glowPulse * 12),
            spreadRadius: 1.0 + (glowPulse * 1.4),
          ),
          const BoxShadow(
            color: Color(0xCC0B1326),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        height: 170,
        child: Center(
          child: Transform.scale(
            scale: 2.6,
            child: Lottie.asset(
              _completedLottieAsset,
              fit: BoxFit.contain,
              repeat: true,
              errorBuilder: (context, error, stackTrace) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StarGlyph(rotation: -0.22),
                      const SizedBox(width: 10),
                      Text(
                        'COMPLETED!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFF6FAFF),
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: 2.7,
                          shadows: [
                            const Shadow(
                              color: Color(0xE60C152A),
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                            Shadow(
                              color: accentColor
                                  .withOpacity(0.35 + glowPulse * 0.22),
                              blurRadius: 22 + glowPulse * 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StarGlyph(rotation: 0.22),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StarGlyph extends StatelessWidget {
  const _StarGlyph({required this.rotation});

  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * math.pi,
      child: const Text(
        '*',
        style: TextStyle(
          color: Color(0xFFDCE8FF),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
