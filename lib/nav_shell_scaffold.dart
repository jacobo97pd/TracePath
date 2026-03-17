import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'auth_gate.dart';
import 'startup_splash_gate.dart';
import 'services/inbox_service.dart';

class NavShellScaffold extends StatelessWidget {
  const NavShellScaffold({
    super.key,
    required this.state,
    required this.child,
  });

  final GoRouterState state;
  final Widget child;
  static final InboxService _inboxService = InboxService();

  static const _tabs = <_TabItem>[
    _TabItem(route: '/home', label: 'Home', icon: Icons.home_rounded),
    _TabItem(
        route: '/play', label: 'Play', icon: Icons.play_circle_fill_rounded),
    _TabItem(route: '/shop', label: 'Shop', icon: Icons.storefront_rounded),
    _TabItem(route: '/social', label: 'Social', icon: Icons.groups_rounded),
    _TabItem(
        route: '/profile',
        label: 'Profile',
        icon: Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(state.uri.path);
    final borderColor = Theme.of(context).dividerColor;
    return ValueListenableBuilder<bool>(
      valueListenable: startupSplashVisible,
      builder: (context, splashShowing, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: authScreenVisible,
          builder: (context, authShowing, _) => Scaffold(
            body: child,
            bottomNavigationBar: (splashShowing || authShowing)
                ? null
                : Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: borderColor, width: 1)),
                    ),
                    child: _buildBottomNav(context, index),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context, int index) {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) {
      return BottomNavigationBar(
        currentIndex: index,
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
        onTap: (nextIndex) {
          final target = _tabs[nextIndex].route;
          if (target != state.uri.path) {
            context.go(target);
          }
        },
      );
    }

    return StreamBuilder<int>(
      stream: _inboxService.watchUnreadCount(uid: uid),
      initialData: 0,
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return BottomNavigationBar(
          currentIndex: index,
          items: _tabs
              .map(
                (tab) => BottomNavigationBarItem(
                  icon: _buildTabIcon(tab, unread),
                  label: tab.label,
                ),
              )
              .toList(),
          onTap: (nextIndex) {
            final target = _tabs[nextIndex].route;
            if (target != state.uri.path) {
              context.go(target);
            }
          },
        );
      },
    );
  }

  Widget _buildTabIcon(_TabItem tab, int unreadCount) {
    final isProfile = tab.route == '/profile';
    if (!isProfile || unreadCount <= 0) {
      return Icon(tab.icon);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(tab.icon),
        Positioned(
          right: -5,
          top: -3,
          child: Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '1',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _currentIndex(String path) {
    if (path == '/' || path.startsWith('/home')) {
      return 0;
    }
    if (path.startsWith('/play/') || path.startsWith('/pack/')) {
      return 1;
    }
    for (var i = 0; i < _tabs.length; i++) {
      if (path == _tabs[i].route || path.startsWith('${_tabs[i].route}/')) {
        return i;
      }
    }
    return 0;
  }
}

class _TabItem {
  const _TabItem({
    required this.route,
    required this.label,
    required this.icon,
  });

  final String route;
  final String label;
  final IconData icon;
}
