import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'auth_gate.dart';
import 'l10n/l10n.dart';
import 'services/inbox_service.dart';
import 'services/onboarding_service.dart';
import 'services/startup_diagnostics.dart';
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
    slog('NavShellScaffold.build path=${state.uri.path}');
    final uid = _firebaseAuthOrNull?.currentUser?.uid.trim() ?? '';
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
                final onboarding = OnboardingService.instance;
                onboarding.markRouteSeen(state.uri.path);
                if (onboarding.isActive &&
                    !onboarding.isRouteAllowed(state.uri.path) &&
                    !_matches(state.uri.path, onboarding.requiredRoute)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) return;
                    context.go(onboarding.requiredRoute);
                  });
                }
                final unread = snapshot.data ?? 0;
                return AnimatedBuilder(
                  animation: onboarding,
                  builder: (context, _) {
                    return Scaffold(
                      body: Stack(
                        fit: StackFit.expand,
                        children: [
                          child,
                          if (!hideNav)
                            _OnboardingSpotlightLayer(
                              currentPath: state.uri.path,
                            ),
                          if (!hideNav)
                            _OnboardingCoachBanner(
                              currentPath: state.uri.path,
                            ),
                        ],
                      ),
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
                              onTabTap: (id) =>
                                  _go(context, _routeForTabId(id)),
                            ),
                    );
                  },
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
    final onboarding = OnboardingService.instance;
    final lang = Localizations.localeOf(context).languageCode;
    if (!onboarding.isRouteAllowed(route)) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(onboarding.blockedMessage(lang)),
          duration: const Duration(milliseconds: 1200),
        ),
      );
      return;
    }
    HapticFeedback.selectionClick();
    context.go(route);
  }

  static bool _matches(String path, String route) =>
      path == route || path.startsWith('$route/');

  FirebaseAuth? get _firebaseAuthOrNull {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }
}

class _OnboardingCoachBanner extends StatelessWidget {
  const _OnboardingCoachBanner({
    required this.currentPath,
  });

  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final onboarding = OnboardingService.instance;
    if (!onboarding.isActive) return const SizedBox.shrink();
    final stepInfo = onboarding.infoForStep(onboarding.step);
    final onTarget = onboarding.isCurrentRouteTarget(currentPath);
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final subtitle = stepInfo.description(localeCode);
    final title = stepInfo.title(localeCode);
    final ctaLabel = onTarget
        ? (stepInfo.needsManualConfirm
            ? stepInfo.manualButton(localeCode)
            : l10n.onboardingInProgress)
        : l10n.onboardingGoNow;
    final canTap = onTarget
        ? stepInfo.needsManualConfirm
        : stepInfo.targetRoute.trim().isNotEmpty;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xEE12223C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF3B5B8F).withOpacity(0.95),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66102442),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${stepInfo.stepNumber}/${stepInfo.totalSteps}',
                        style: const TextStyle(
                          color: Color(0xFF9DC0FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFD0E1FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            value: stepInfo.stepNumber / stepInfo.totalSteps,
                            backgroundColor: const Color(0xFF20395D),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2EC4FF),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => _confirmSkipTutorial(context),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF9DC0FF),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(_skipLabel(context)),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: canTap
                              ? () {
                                  if (onTarget) {
                                    unawaited(onboarding.completeManualStep());
                                    return;
                                  }
                                  context.go(stepInfo.targetRoute);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A68FF),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: Text(ctaLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSkipTutorial(BuildContext context) async {
    final onboarding = OnboardingService.instance;
    if (!onboarding.isActive) return;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF13233E),
            title: Text(isEs ? 'Saltar tutorial' : 'Skip tutorial'),
            content: Text(
              isEs
                  ? 'Perderas la guia inicial. Podras jugar igualmente.'
                  : 'You will skip the guided walkthrough. You can still play normally.',
              style: const TextStyle(color: Color(0xFFD0E1FF)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(isEs ? 'Cancelar' : 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(isEs ? 'Saltar' : 'Skip'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    await onboarding.skipTutorial();
    if (!context.mounted) return;
    context.go('/home');
  }

  String _skipLabel(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'es'
          ? 'Saltar tutorial'
          : 'Skip tutorial';
}

class _OnboardingSpotlightLayer extends StatefulWidget {
  const _OnboardingSpotlightLayer({
    required this.currentPath,
  });

  final String currentPath;

  @override
  State<_OnboardingSpotlightLayer> createState() =>
      _OnboardingSpotlightLayerState();
}

class _OnboardingSpotlightLayerState extends State<_OnboardingSpotlightLayer> {
  Rect? _spotlightRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshRect());
  }

  @override
  void didUpdateWidget(covariant _OnboardingSpotlightLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPath != widget.currentPath) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refreshRect());
    }
  }

  void _refreshRect() {
    if (!mounted) return;
    final onboarding = OnboardingService.instance;
    final key = onboarding.currentSpotlightKey(widget.currentPath);
    final nextRect = _rectForKey(key);
    if (nextRect == _spotlightRect) return;
    setState(() {
      _spotlightRect = nextRect;
    });
  }

  Rect? _rectForKey(GlobalKey? key) {
    if (key == null) return null;
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final render = ctx.findRenderObject();
    if (render is! RenderBox || !render.attached) return null;
    final origin = render.localToGlobal(Offset.zero);
    final size = render.size;
    if (size.isEmpty) return null;
    final rect = origin & size;
    return rect.inflate(10);
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = OnboardingService.instance;
    if (!onboarding.isActive ||
        !onboarding.isCurrentRouteTarget(widget.currentPath)) {
      return const SizedBox.shrink();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshRect());
    if (_spotlightRect == null) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: true,
      child: CustomPaint(
        size: Size.infinite,
        painter: _SpotlightMaskPainter(holeRect: _spotlightRect!),
      ),
    );
  }
}

class _SpotlightMaskPainter extends CustomPainter {
  const _SpotlightMaskPainter({
    required this.holeRect,
  });

  final Rect holeRect;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final hole = RRect.fromRectAndRadius(holeRect, const Radius.circular(14));
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(full)
      ..addRRect(hole);
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xA0000000),
    );
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = const Color(0xFF5AD0FF),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightMaskPainter oldDelegate) {
    return oldDelegate.holeRect != holeRect;
  }
}
