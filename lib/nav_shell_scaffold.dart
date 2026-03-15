import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'auth_gate.dart';
import 'startup_splash_gate.dart';

class NavShellScaffold extends StatelessWidget {
  const NavShellScaffold({
    super.key,
    required this.state,
    required this.child,
  });

  final GoRouterState state;
  final Widget child;

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
                    child: BottomNavigationBar(
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
                    ),
                  ),
          ),
        );
      },
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
