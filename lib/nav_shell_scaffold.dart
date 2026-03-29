import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'auth_gate.dart';
import 'l10n/l10n.dart';
import 'services/inbox_service.dart';
import 'startup_splash_gate.dart';
import 'ui/components/app_bottom_navbar.dart';

class NavShellScaffold extends StatelessWidget {
  const NavShellScaffold({
    super.key,
    required this.state,
    required this.child,
  });

  final GoRouterState state;
  final Widget child;

  static final InboxService _inboxService = InboxService();

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
                  body: child,
                  extendBody: false,
                  bottomNavigationBar: hideNav
                      ? null
                      : AppBottomNavbar(
                          selectedTabId: _selectedTabId(state.uri.path),
                          profileBadgeCount: unread,
                          homeLabel: context.l10n.tabHome,
                          shopLabel: context.l10n.tabShop,
                          cardsLabel: context.l10n.tabCards,
                          duelLabel: context.l10n.tabDuel,
                          profileLabel: context.l10n.tabProfile,
                          onTabTap: (id) => _go(context, _routeForTabId(id)),
                        ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _selectedTabId(String path) {
    if (_matches(path, '/home')) return 'home';
    if (_matches(path, '/shop')) return 'shop';
    if (_matches(path, '/cards')) return 'cards';
    if (_matches(path, '/duel')) return 'duel';
    if (_matches(path, '/profile')) return 'profile';
    return 'home';
  }

  String _routeForTabId(String id) {
    return switch (id) {
      'home' => '/home',
      'shop' => '/shop',
      'cards' => '/cards',
      'duel' => '/duel',
      'profile' => '/profile',
      _ => '/home',
    };
  }

  void _go(BuildContext context, String route) {
    if (_matches(state.uri.path, route)) return;
    HapticFeedback.selectionClick();
    context.go(route);
  }

  static bool _matches(String path, String route) =>
      path == route || path.startsWith('$route/');
}
