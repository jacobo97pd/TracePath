import 'dart:math' as math;
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'auth_gate.dart';
import 'services/inbox_service.dart';
import 'startup_splash_gate.dart';

class NavShellScaffold extends StatefulWidget {
  const NavShellScaffold({
    super.key,
    required this.state,
    required this.child,
  });

  final GoRouterState state;
  final Widget child;

  @override
  State<NavShellScaffold> createState() => _NavShellScaffoldState();
}

class _NavShellScaffoldState extends State<NavShellScaffold>
    with TickerProviderStateMixin {
  static final InboxService _inboxService = InboxService();

  static const List<_TabItem> _tabs = <_TabItem>[
    _TabItem(
        id: 'home', route: '/home', label: 'Home', icon: Icons.home_rounded),
    _TabItem(
        id: 'shop',
        route: '/shop',
        label: 'Shop',
        icon: Icons.storefront_rounded),
    _TabItem(
        id: 'duel',
        route: '/duel',
        label: 'Duel',
        icon: Icons.flash_on_rounded),
    _TabItem(
        id: 'cards',
        route: '/cards',
        label: 'Cards',
        icon: Icons.style_rounded),
    _TabItem(
        id: 'profile',
        route: '/profile',
        label: 'Profile',
        icon: Icons.person_outline_rounded),
  ];

  static const List<_PlayModeItem> _playModes = <_PlayModeItem>[
    _PlayModeItem(
      id: 'worlds',
      route: '/play',
      label: 'Worlds',
      icon: Icons.public_rounded,
      angleDeg: 160,
    ),
    _PlayModeItem(
      id: 'daily',
      route: '/daily',
      label: 'Daily',
      icon: Icons.calendar_today_rounded,
      angleDeg: 125,
    ),
    _PlayModeItem(
      id: 'ranked',
      route: '/social',
      label: 'Ranked',
      icon: Icons.emoji_events_rounded,
      angleDeg: 90,
    ),
    _PlayModeItem(
      id: 'events',
      route: '/social',
      label: 'Events',
      icon: Icons.celebration_rounded,
      angleDeg: 55,
    ),
    _PlayModeItem(
      id: 'duels',
      route: '/duel',
      label: 'Duels',
      icon: Icons.flash_on_rounded,
      angleDeg: 20,
    ),
  ];

  static const double _barHeight = 62;
  static const double _playButtonSize = 58;
  static const double _radialItemSize = 46;
  static const double _radialRadius = 112;
  static const double _radialHitRadius = 38;
  static const double _playBottomOffset = 16;

  late final AnimationController _radialController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final AnimationController _playPulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  late final Animation<double> _playPulse = CurvedAnimation(
    parent: _playPulseController,
    curve: Curves.easeInOut,
  );

  bool _radialOpen = false;
  bool _navigating = false;
  String? _hoveredModeId;

  @override
  void dispose() {
    _radialController.dispose();
    _playPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final unreadStream = uid.isEmpty
        ? Stream<int>.value(0)
        : _inboxService.watchUnreadCount(uid: uid);
    return ValueListenableBuilder<bool>(
      valueListenable: startupSplashVisible,
      builder: (context, splashShowing, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: authScreenVisible,
          builder: (context, authShowing, _) {
            final hideNav = splashShowing || authShowing;
            return StreamBuilder<int>(
              stream: unreadStream,
              initialData: 0,
              builder: (context, snapshot) {
                final unread = snapshot.data ?? 0;
                return Scaffold(
                  body: PopScope(
                    canPop: !_radialOpen,
                    onPopInvokedWithResult: (didPop, _) {
                      if (!didPop && _radialOpen) {
                        _closeRadial();
                      }
                    },
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: _routeNeedsBottomClearance(
                                    widget.state.uri.path)
                                ? _playBottomOffset +
                                    _playButtonSize +
                                    MediaQuery.of(context).padding.bottom +
                                    8
                                : 0,
                          ),
                          child: widget.child,
                        ),
                        if (!hideNav) ...[
                          if (_radialOpen || _radialController.value > 0)
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _closeRadial,
                                onPanUpdate: (d) =>
                                    _updateHoveredByGlobal(d.globalPosition),
                                onPanEnd: (_) => _releaseDragSelection(),
                                child: AnimatedBuilder(
                                  animation: _radialController,
                                  builder: (context, _) {
                                    final opacity = Curves.easeOut.transform(
                                            _radialController.value) *
                                        0.24;
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Container(
                                          color:
                                              Colors.black.withOpacity(opacity),
                                        ),
                                        BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 4 * _radialController.value,
                                            sigmaY: 4 * _radialController.value,
                                          ),
                                          child: const SizedBox.expand(),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring:
                                  !(_radialOpen || _radialController.value > 0),
                              child: AnimatedBuilder(
                                animation: _radialController,
                                builder: (context, _) {
                                  final p = Curves.easeOutCubic
                                      .transform(_radialController.value);
                                  return Stack(
                                    children: [
                                      for (final mode in _playModes)
                                        _buildRadialModeItem(
                                          context,
                                          mode: mode,
                                          progress: p,
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: _buildBottomBar(context, unread),
                          ),
                          _buildFloatingPlayButton(context),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, int unreadCount) {
    final path = widget.state.uri.path;
    return Container(
      height: _barHeight + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 6,
        bottom: MediaQuery.of(context).padding.bottom + 6,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111C31), Color(0xFF0D1627)],
        ),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton(
              context, _tabs[0], _routeMatches(path, '/home'), unreadCount),
          _buildTabButton(
              context, _tabs[1], _routeMatches(path, '/shop'), unreadCount),
          const SizedBox(width: _playButtonSize + 18),
          _buildTabButton(
              context, _tabs[2], _routeMatches(path, '/duel'), unreadCount),
          _buildTabButton(
              context, _tabs[3], _routeMatches(path, '/cards'), unreadCount),
          _buildTabButton(
              context, _tabs[4], _routeMatches(path, '/profile'), unreadCount),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    _TabItem tab,
    bool active,
    int unreadCount,
  ) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _go(tab.route),
        child: SizedBox(
          height: 46,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    tab.icon,
                    size: 19,
                    color: active
                        ? const Color(0xFF9ED0FF)
                        : const Color(0xFF96A8C8),
                  ),
                  if (tab.id == 'profile' && unreadCount > 0)
                    Positioned(
                      right: -7,
                      top: -5,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? const Color(0xFFDCEEFF)
                      : const Color(0xFF96A8C8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingPlayButton(BuildContext context) {
    final path = widget.state.uri.path;
    final active = _routeMatches(path, '/play') || path.startsWith('/pack/');
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + _playBottomOffset,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _go('/play'),
          onLongPressStart: (details) {
            _openRadial();
            _updateHoveredByGlobal(details.globalPosition);
          },
          onLongPressMoveUpdate: (details) {
            _updateHoveredByGlobal(details.globalPosition);
          },
          onLongPressEnd: (_) => _releaseDragSelection(),
          child: AnimatedBuilder(
            animation: Listenable.merge([_radialController, _playPulse]),
            builder: (context, _) {
              final radial = Curves.easeOut.transform(_radialController.value);
              final pulse = 1 + (_playPulse.value * 0.035);
              return Transform.scale(
                scale: pulse + (radial * 0.015),
                child: Container(
                  width: _playButtonSize,
                  height: _playButtonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4AC6FF), Color(0xFF2563EB)],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(active ? 0.62 : 0.35),
                      width: active ? 1.7 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4AC6FF)
                            .withOpacity(active ? 0.45 : 0.32),
                        blurRadius: active ? 16 : 12,
                        spreadRadius: active ? 1.4 : 0.9,
                      ),
                      const BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 26,
                        color: Colors.white,
                      ),
                      SizedBox(height: 0.5),
                      Text(
                        'Play',
                        style: TextStyle(
                          color: Color(0xFFF4FAFF),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRadialModeItem(
    BuildContext context, {
    required _PlayModeItem mode,
    required double progress,
  }) {
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final center = Offset(
      size.width / 2,
      size.height - bottomInset - _playBottomOffset - (_playButtonSize / 2),
    );
    final rads = mode.angleDeg * math.pi / 180;
    final target = Offset(
      center.dx + math.cos(rads) * _radialRadius,
      center.dy - math.sin(rads) * _radialRadius,
    );
    final current = Offset.lerp(center, target, progress)!;
    final hovered = _hoveredModeId == mode.id;

    return Positioned(
      left: current.dx - _radialItemSize / 2,
      top: current.dy - _radialItemSize / 2,
      child: Opacity(
        opacity: progress,
        child: Transform.scale(
          scale: (0.78 + progress * 0.22) * (hovered ? 1.14 : 1.0),
          child: Column(
            children: [
              if (hovered)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xED0A1220),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF35527A)),
                  ),
                  child: Text(
                    mode.label,
                    style: const TextStyle(
                      color: Color(0xFFDCEEFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: progress > 0.9 ? () => _selectMode(mode) : null,
                child: Container(
                  width: _radialItemSize,
                  height: _radialItemSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: hovered
                          ? const [Color(0xFF4AB9FF), Color(0xFF1D4ED8)]
                          : const [Color(0xFF1B273A), Color(0xFF0E1627)],
                    ),
                    border: Border.all(
                      color: hovered
                          ? const Color(0xFFBFDBFE)
                          : const Color(0xFF2D4567),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4AB9FF)
                            .withOpacity(hovered ? 0.4 : 0.14),
                        blurRadius: hovered ? 15 : 9,
                        spreadRadius: hovered ? 1.2 : 0.2,
                      ),
                    ],
                  ),
                  child: Icon(
                    mode.icon,
                    size: 21,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRadial() {
    if (_radialOpen) return;
    _radialOpen = true;
    _hoveredModeId = null;
    _radialController.forward();
    HapticFeedback.selectionClick();
    setState(() {});
  }

  void _closeRadial() {
    if (!_radialOpen && !_radialController.isAnimating) return;
    _radialOpen = false;
    _hoveredModeId = null;
    _radialController.reverse();
    setState(() {});
  }

  void _updateHoveredByGlobal(Offset global) {
    if (!_radialOpen) return;
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final progress = Curves.easeOutCubic.transform(_radialController.value);
    if (progress < 0.3) return;

    final center = Offset(
      size.width / 2,
      size.height - bottomInset - _playBottomOffset - (_playButtonSize / 2),
    );

    String? bestId;
    var bestDistance = double.infinity;
    for (final mode in _playModes) {
      final rads = mode.angleDeg * math.pi / 180;
      final point = Offset(
        center.dx + math.cos(rads) * _radialRadius * progress,
        center.dy - math.sin(rads) * _radialRadius * progress,
      );
      final d = (global - point).distance;
      if (d <= _radialHitRadius && d < bestDistance) {
        bestDistance = d;
        bestId = mode.id;
      }
    }
    if (bestId != _hoveredModeId) {
      _hoveredModeId = bestId;
      if (bestId != null) HapticFeedback.lightImpact();
      setState(() {});
    }
  }

  void _releaseDragSelection() {
    if (_hoveredModeId == null) {
      _closeRadial();
      return;
    }
    _PlayModeItem? selected;
    for (final mode in _playModes) {
      if (mode.id == _hoveredModeId) {
        selected = mode;
        break;
      }
    }
    if (selected == null) {
      _closeRadial();
      return;
    }
    _selectMode(selected);
  }

  void _selectMode(_PlayModeItem mode) {
    _closeRadial();
    _go(mode.route);
  }

  void _go(String route) {
    if (_navigating) return;
    final path = widget.state.uri.path;
    if (_routeMatches(path, route)) return;
    _navigating = true;
    HapticFeedback.mediumImpact();
    context.go(route);
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      _navigating = false;
    });
  }

  static bool _routeMatches(String path, String route) {
    return path == route || path.startsWith('$route/');
  }

  static bool _routeNeedsBottomClearance(String path) {
    return _routeMatches(path, '/play') ||
        _routeMatches(path, '/daily') ||
        _routeMatches(path, '/social') ||
        _routeMatches(path, '/duel');
  }
}

class _TabItem {
  const _TabItem({
    required this.id,
    required this.route,
    required this.label,
    required this.icon,
  });

  final String id;
  final String route;
  final String label;
  final IconData icon;
}

class _PlayModeItem {
  const _PlayModeItem({
    required this.id,
    required this.route,
    required this.label,
    required this.icon,
    required this.angleDeg,
  });

  final String id;
  final String route;
  final String label;
  final IconData icon;
  final double angleDeg;
}
