import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'services/startup_diagnostics.dart';

// Diagnostics: set to true to skip the splash and go straight to the app.
// Revert to false before shipping.
const bool kSkipSplashForDiagnostics = false;

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

class _StartupSplashGateState extends State<StartupSplashGate>
    with WidgetsBindingObserver {
  static const Duration _minVisibleDuration = Duration(milliseconds: 1800);
  // Hard cap: splash never blocks the app for more than this, regardless of cause.
  static const Duration _hardTimeout = Duration(seconds: 5);

  bool _showSplash = !_didShowStartupSplash && !kSkipSplashForDiagnostics;
  bool _videoReady = false;
  bool _dismissed = false;
  DateTime? _shownAt;

  VideoPlayerController? _videoController;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    slog('SplashGate.initState skip=$kSkipSplashForDiagnostics');
    WidgetsBinding.instance.addObserver(this);
    if (kSkipSplashForDiagnostics) {
      _didShowStartupSplash = true;
      startupSplashVisible.value = false;
      slog('SplashGate: skipped (diag flag)');
      return;
    }
    startupSplashVisible.value = _showSplash;
    if (_showSplash) {
      _initSplashVideo();
    }
  }

  Future<void> _initSplashVideo() async {
    slog('SplashGate._initSplashVideo release=$kReleaseMode');
    _shownAt = DateTime.now();

    if (kReleaseMode) {
      _fallbackTimer = Timer(_hardTimeout, _forceDismiss);
      _scheduleMinDurationDismiss();
      return;
    }

    _fallbackTimer = Timer(_hardTimeout, _forceDismiss);

    try {
      final controller = VideoPlayerController.asset(
        'assets/branding/splash_video_trace_path.mp4',
      );
      _videoController = controller;
      slog('SplashGate: video controller.initialize...');
      await controller.initialize().timeout(const Duration(seconds: 4));
      slog('SplashGate: video initialized');
      if (!mounted || _dismissed) return;

      controller
        ..setLooping(false)
        ..setVolume(0);
      controller.addListener(_onVideoTick);

      setState(() {
        _videoReady = true;
      });

      try {
        await controller.setPlaybackSpeed(1.5);
      } catch (e) {
        try {
          await controller.setPlaybackSpeed(1.0);
        } catch (_) {}
      }

      await controller.play();
      slog('SplashGate: video playing');
    } catch (e) {
      slog('SplashGate: video FAIL $e');
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
      _scheduleMinDurationDismiss();
    }
  }

  void _scheduleMinDurationDismiss() {
    final shownAt = _shownAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(shownAt);
    final wait = elapsed < _minVisibleDuration
        ? _minVisibleDuration - elapsed
        : Duration.zero;
    Future<void>.delayed(wait, _forceDismiss);
  }

  void _onVideoTick() {
    final controller = _videoController;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;
    if (!controller.value.isPlaying) return;

    final duration = controller.value.duration;
    final position = controller.value.position;
    if (duration.inMilliseconds <= 0) return;
    if (position <= Duration.zero) return;

    if (position >= duration - const Duration(milliseconds: 80)) {
      _scheduleMinDurationDismiss();
    }
  }

  void _forceDismiss() {
    slog('SplashGate._forceDismiss dismissed=$_dismissed mounted=$mounted');
    if (_dismissed || !mounted) return;
    _dismissed = true;
    _didShowStartupSplash = true;

    final controller = _videoController;
    if (controller != null) {
      controller.removeListener(_onVideoTick);
      unawaited(controller.pause());
    }

    setState(() {
      _showSplash = false;
    });
    startupSplashVisible.value = false;
    slog('SplashGate: dismissed OK');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_showSplash || _dismissed) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        // If app goes to background during intro, mark splash as consumed
        // so it never replays on resume.
        _forceDismiss();
        break;
      case AppLifecycleState.resumed:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fallbackTimer?.cancel();
    final controller = _videoController;
    if (controller != null) {
      controller.removeListener(_onVideoTick);
      controller.dispose();
    }
    startupSplashVisible.value = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) {
      return widget.child;
    }

    final controller = _videoController;
    final hasVideo = _videoReady && controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (hasVideo)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else
            const ColoredBox(color: Colors.black),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
