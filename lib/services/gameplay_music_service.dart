import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// Lightweight gameplay BGM manager.
///
/// - Starts music when at least one gameplay screen is active.
/// - Pauses when no gameplay screen is active.
/// - Pauses on app background and resumes on foreground.
/// - Keeps API ready for a future sound settings screen.
class GameplayMusicService with WidgetsBindingObserver {
  GameplayMusicService._() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadEnabledPreference());
  }

  static final GameplayMusicService instance = GameplayMusicService._();

  static const String _enabledPrefKey = 'gameplay_music_enabled_v1';
  static const String _assetPath = 'assets/branding/splash_video_trace_path.mp4';
  static const double _defaultVolume = 0.16;

  int _activeGameplayScreens = 0;
  bool _enabled = true;
  bool _prefLoaded = false;
  bool _initializing = false;
  VideoPlayerController? _controller;

  bool get isEnabled => _enabled;

  Future<void> attachGameplay() async {
    _activeGameplayScreens++;
    await _syncPlayback();
  }

  Future<void> detachGameplay() async {
    _activeGameplayScreens = math.max(0, _activeGameplayScreens - 1);
    await _syncPlayback();
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledPrefKey, enabled);
      _prefLoaded = true;
    } catch (_) {}
    await _syncPlayback();
  }

  Future<void> _loadEnabledPreference() async {
    if (_prefLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledPrefKey) ?? true;
      _prefLoaded = true;
    } catch (_) {
      _enabled = true;
      _prefLoaded = true;
    }
    await _syncPlayback();
  }

  Future<void> _syncPlayback() async {
    if (!_enabled || _activeGameplayScreens <= 0) {
      await _pause();
      return;
    }
    final controller = await _ensureController();
    if (controller == null) return;
    if (!controller.value.isPlaying) {
      try {
        await controller.play();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[bgm] play failed: $e');
        }
      }
    }
  }

  Future<VideoPlayerController?> _ensureController() async {
    final current = _controller;
    if (current != null && current.value.isInitialized) {
      return current;
    }
    if (_initializing) {
      while (_initializing) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      return _controller;
    }

    _initializing = true;
    try {
      final controller = VideoPlayerController.asset(_assetPath);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(_defaultVolume);
      _controller = controller;
      return controller;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[bgm] init failed for asset $_assetPath: $e');
      }
      return null;
    } finally {
      _initializing = false;
    }
  }

  Future<void> _pause() async {
    final controller = _controller;
    if (controller == null) return;
    if (!controller.value.isInitialized) return;
    if (!controller.value.isPlaying) return;
    try {
      await controller.pause();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_syncPlayback());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_pause());
        break;
    }
  }

  Future<void> disposeService() async {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }
}

