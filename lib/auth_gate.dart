import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'login_screen.dart';

final ValueNotifier<bool> authScreenVisible = ValueNotifier<bool>(false);

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.child,
  });

  final AuthService authService;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authService,
      builder: (context, _) {
        if (!authService.isReady) {
          _setAuthScreenVisible(true);
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final showAuth = !authService.isAuthenticated;
        _setAuthScreenVisible(showAuth);
        if (showAuth) {
          return LoginScreen(authService: authService);
        }
        return child;
      },
    );
  }

  void _setAuthScreenVisible(bool value) {
    if (authScreenVisible.value == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authScreenVisible.value != value) {
        authScreenVisible.value = value;
      }
    });
  }
}
