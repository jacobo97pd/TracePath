import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
  static const Duration _minVisibleDuration = Duration(milliseconds: 2200);
  bool _showSplash = !_didShowStartupSplash;
  bool _videoReady = false;
  bool _dismissed = false;
  DateTime? _shownAt;

  VideoPlayerController? _videoController;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    startupSplashVisible.value = _showSplash;
    if (_showSplash) {
      _initSplashVideo();
    }
  }

  Future<void> _initSplashVideo() async {
    // Safety timeout so splash never blocks startup.
    _fallbackTimer = Timer(const Duration(seconds: 12), _dismissSplash);
    _shownAt = DateTime.now();

    try {
      final controller = VideoPlayerController.asset(
        'assets/branding/splash_video_trace_path.mp4',
      );
      _videoController = controller;
      await controller.initialize();
      if (!mounted || _dismissed) return;

      controller
        ..setLooping(false)
        ..setVolume(0);
      controller.addListener(_onVideoTick);

      // Show the first frame as soon as initialization is done.
      setState(() {
        _videoReady = true;
      });

      // Do not fail the whole splash flow if speed is not supported on device.
      try {
        await controller.setPlaybackSpeed(1.5);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[splash] setPlaybackSpeed failed, fallback to 1.0: $e');
        }
        try {
          await controller.setPlaybackSpeed(1.0);
        } catch (_) {}
      }

      await controller.play();
    } catch (_) {
      // Keep startup flow alive with a short black fallback if video fails.
      if (kDebugMode) {
        debugPrint('[splash] video init failed, using black fallback.');
      }
      _fallbackTimer?.cancel();
      _fallbackTimer = Timer(const Duration(milliseconds: 1500), _dismissSplash);
    }
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
      _dismissSplash();
    }
  }

  void _dismissSplash() {
    if (_dismissed || !mounted) return;

    final shownAt = _shownAt;
    if (shownAt != null) {
      final elapsed = DateTime.now().difference(shownAt);
      if (elapsed < _minVisibleDuration) {
        final wait = _minVisibleDuration - elapsed;
        Future<void>.delayed(wait, () {
          if (mounted) _dismissSplash();
        });
        return;
      }
    }

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
  }

  @override
  void dispose() {
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
