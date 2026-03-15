import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';

enum GameToastType {
  achievement,
  coins,
  streak,
  social,
  info,
}

class GameToast {
  static final Queue<_ToastRequest> _queue = Queue<_ToastRequest>();
  static bool _showing = false;

  static Future<void> show(
    BuildContext context, {
    required GameToastType type,
    required String title,
    required String message,
    Duration? duration,
  }) async {
    final request = _ToastRequest(
      context: context,
      type: type,
      title: title,
      message: message,
      duration: duration ?? _defaultDuration(type),
    );
    _queue.add(request);
    if (_showing) return;
    _showing = true;
    while (_queue.isNotEmpty) {
      final next = _queue.removeFirst();
      await _showSingle(next);
    }
    _showing = false;
  }

  static Duration _defaultDuration(GameToastType type) {
    switch (type) {
      case GameToastType.achievement:
        return const Duration(milliseconds: 2500);
      case GameToastType.coins:
        return const Duration(milliseconds: 2100);
      case GameToastType.streak:
        return const Duration(milliseconds: 2300);
      case GameToastType.social:
        return const Duration(milliseconds: 1900);
      case GameToastType.info:
      default:
        return const Duration(milliseconds: 1800);
    }
  }

  static Future<void> _showSingle(_ToastRequest request) async {
    final overlay = Overlay.maybeOf(request.context, rootOverlay: true);
    if (overlay == null) return;
    final completer = Completer<void>();
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GameToastOverlay(
        type: request.type,
        title: request.title,
        message: request.message,
        holdDuration: request.duration,
        onDone: () {
          entry.remove();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    overlay.insert(entry);
    await completer.future;
  }
}

class _ToastRequest {
  const _ToastRequest({
    required this.context,
    required this.type,
    required this.title,
    required this.message,
    required this.duration,
  });

  final BuildContext context;
  final GameToastType type;
  final String title;
  final String message;
  final Duration duration;
}

class _GameToastOverlay extends StatefulWidget {
  const _GameToastOverlay({
    required this.type,
    required this.title,
    required this.message,
    required this.holdDuration,
    required this.onDone,
  });

  final GameToastType type;
  final String title;
  final String message;
  final Duration holdDuration;
  final VoidCallback onDone;

  @override
  State<_GameToastOverlay> createState() => _GameToastOverlayState();
}

class _GameToastOverlayState extends State<_GameToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(_fade);
    _scale = Tween<double>(
      begin: 0.98,
      end: 1,
    ).animate(_fade);
    _play();
  }

  Future<void> _play() async {
    await _controller.forward();
    if (!mounted) return;
    _dismissTimer = Timer(widget.holdDuration, () async {
      if (!mounted) return;
      await _controller.reverse();
      if (!mounted) return;
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleForType(widget.type);
    final bottom = MediaQuery.of(context).padding.bottom;
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: style.background,
                      border: Border.all(color: style.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: style.accent.withOpacity(0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 66,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: style.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: style.accent.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(style.icon, color: style.accent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFB8C7E7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastStyle {
  const _ToastStyle({
    required this.icon,
    required this.accent,
    required this.background,
    required this.border,
  });

  final IconData icon;
  final Color accent;
  final Color background;
  final Color border;
}

_ToastStyle _styleForType(GameToastType type) {
  switch (type) {
    case GameToastType.achievement:
      return const _ToastStyle(
        icon: Icons.emoji_events_rounded,
        accent: Color(0xFFF6C453),
        background: Color(0xFF2A2417),
        border: Color(0xFF7A6130),
      );
    case GameToastType.coins:
      return const _ToastStyle(
        icon: Icons.monetization_on_rounded,
        accent: Color(0xFFFFD166),
        background: Color(0xFF2B2416),
        border: Color(0xFF7E6530),
      );
    case GameToastType.streak:
      return const _ToastStyle(
        icon: Icons.local_fire_department_rounded,
        accent: Color(0xFFFF8A3D),
        background: Color(0xFF2C2119),
        border: Color(0xFF7E4B2D),
      );
    case GameToastType.social:
      return const _ToastStyle(
        icon: Icons.groups_rounded,
        accent: Color(0xFF63A7FF),
        background: Color(0xFF182538),
        border: Color(0xFF31557E),
      );
    case GameToastType.info:
    default:
      return const _ToastStyle(
        icon: Icons.info_outline_rounded,
        accent: Color(0xFF53C6FF),
        background: Color(0xFF152739),
        border: Color(0xFF2B5B7D),
      );
  }
}
