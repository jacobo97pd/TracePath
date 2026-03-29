import 'dart:async';

import 'package:flutter/material.dart';

bool _didShowStartupSplash = false;
final ValueNotifier<bool> startupSplashVisible =
    ValueNotifier<bool>(!_didShowStartupSplash);

class StartupSplashGate extends StatefulWidget {
  const StartupSplashGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<StartupSplashGate> createState() => _StartupSplashGateState();
}

class _StartupSplashGateState extends State<StartupSplashGate> {
  bool _showSplash = !_didShowStartupSplash;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    startupSplashVisible.value = _showSplash;
    if (_showSplash) {
      _timer = Timer(const Duration(milliseconds: 1300), () {
        if (!mounted) return;
        _didShowStartupSplash = true;
        setState(() {
          _showSplash = false;
        });
        startupSplashVisible.value = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    startupSplashVisible.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) {
      return widget.child;
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        builder: (context, t, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.25),
                      radius: 0.95,
                      colors: [
                        const Color(0xFF1A2C4D).withOpacity(0.55),
                        const Color(0xFF0F172A),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: Container(
                          width: 114,
                          height: 114,
                          color: const Color(0xFF0A1323),
                          child: OverflowBox(
                            maxWidth: 146,
                            maxHeight: 146,
                            child: Image.asset(
                              'assets/branding/logo_tracePath.png',
                              width: 146,
                              height: 146,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'TracePath',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          value: t,
                          minHeight: 4,
                          backgroundColor: const Color(0xFF1A2233),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF3D79FF),
                          ),
                        ),
                      ),
                    ],
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
