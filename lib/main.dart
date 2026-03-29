import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'dart:io';

import 'adaptive_difficulty_service.dart';
import 'achievements_service.dart';
import 'app_theme.dart';
import 'auth_gate.dart';
import 'auth_service.dart';
import 'campaign_screen.dart';
import 'cards_collection_screen.dart';
import 'coins_service.dart';
import 'curate_batch_screen.dart';
import 'daily_screen.dart';
import 'duel_screen.dart';
import 'game_screen.dart';
import 'home_screen.dart';
import 'live_duel_screen.dart';
import 'friend_challenge_screen.dart';
import 'editor/editor_page.dart';
import 'editor/editor_nuevos_page.dart';
import 'leaderboard_service.dart';
import 'models/live_match.dart';
import 'models/friend_challenge.dart';
import 'models/inbox_item.dart';
import 'nav_shell_scaffold.dart';
import 'notification_service.dart';
import 'profile_screen.dart';
import 'progress_service.dart';
import 'puzzle_leaderboard_screen.dart';
import 'shop_screen.dart';
import 'skin_catalog_service.dart';
import 'skin_editor_screen.dart';
import 'stats_service.dart';
import 'social_screen.dart';
import 'victory_screen.dart';
import 'level_fingerprint_store.dart';
import 'level_export_registry.dart';
import 'play_levels_screen.dart';
import 'startup_splash_gate.dart';
import 'storage_paths.dart';
import 'pack_level_repository.dart';
import 'services/ads_service.dart';
import 'services/inbox_service.dart';
import 'services/live_duel_service.dart';
import 'services/presence_service.dart';
import 'ui/components/coin_reward_overlay.dart';
import 'ui/components/app_game_backdrop.dart';
import 'l10n/l10n.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Temporary diagnostics switch:
// Set to true to skip notification initialization and isolate startup issues in release.
const bool kDisableNotificationsForReleaseDiagnostics = true;

Future<void> main() async {
  debugPrint('[Startup] main start');
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await MobileAds.instance.initialize();
    debugPrint('[ADS] MobileAds initialized');
    unawaited(AdsService.instance.loadRewardedAd());
  } catch (e, st) {
    debugPrint('[ADS] MobileAds init failed: $e');
    debugPrintStack(stackTrace: st);
  }
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBl0rILs5xgvJHsDO9TvU4e_8NgqP4l7fg',
        authDomain: 'tracepath-e2e90.firebaseapp.com',
        projectId: 'tracepath-e2e90',
        storageBucket: 'tracepath-e2e90.firebasestorage.app',
        messagingSenderId: '1025619399156',
        appId: '1:1025619399156:web:17c2abc833d673dde569a1',
        measurementId: 'G-PE5TF47PDE',
      ),
    );
  } else {
    try {
      await Firebase.initializeApp();
    } catch (e, st) {
      // Keep app startup alive in local-only mode when native Firebase files are missing.
      debugPrint('[Firebase] initializeApp failed on native platform: $e');
      debugPrintStack(stackTrace: st);
    }
  }
  final prefs = await SharedPreferences.getInstance();
  final progressService = ProgressService(prefs);
  final coinsService = CoinsService(prefs);
  final authService = AuthService(prefs);
  final skinCatalogService = SkinCatalogService(prefs);
  final statsService = StatsService(prefs, progressService);
  final adaptiveDifficultyService = AdaptiveDifficultyService(prefs);
  final leaderboardService = LeaderboardService(prefs);
  final notificationService = NotificationService(prefs);
  await LevelFingerprintStore.instance.initialize();
  final exportBasePath = await resolveExportBasePath();
  await LevelExportRegistry.instance.initialize(basePath: exportBasePath);
  await PackLevelRepository.instance.loadPack('all');

  const shouldSkipNotifications = kDisableNotificationsForReleaseDiagnostics;
  if (shouldSkipNotifications) {
    debugPrint(
      '[Startup] Notifications temporarily disabled for release diagnostics',
    );
  } else {
    debugPrint('[Startup] NotificationService.initialize start');
    try {
      await notificationService.initialize(progressService: progressService);
      debugPrint('[Startup] NotificationService.initialize ok');
    } catch (e, st) {
      debugPrint('[Startup] NotificationService.initialize failed: $e');
      debugPrintStack(stackTrace: st);
    }
  }
  debugPrint('[Startup] runApp()');
  runApp(
    MyApp(
      progressService: progressService,
      coinsService: coinsService,
      authService: authService,
      skinCatalogService: skinCatalogService,
      statsService: statsService,
      adaptiveDifficultyService: adaptiveDifficultyService,
      leaderboardService: leaderboardService,
      notificationService: notificationService,
      achievementsService: AchievementsService(
        prefs,
        progressService,
        statsService,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.progressService,
    required this.coinsService,
    required this.authService,
    required this.skinCatalogService,
    required this.statsService,
    required this.adaptiveDifficultyService,
    required this.leaderboardService,
    required this.notificationService,
    required this.achievementsService,
  });

  final ProgressService progressService;
  final CoinsService coinsService;
  final AuthService authService;
  final SkinCatalogService skinCatalogService;
  final StatsService statsService;
  final AdaptiveDifficultyService adaptiveDifficultyService;
  final LeaderboardService leaderboardService;
  final NotificationService notificationService;
  final AchievementsService achievementsService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _warmupQueued = false;
  final Set<String> _warmedShopPaths = <String>{};
  final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  final PresenceService _presenceService = PresenceService();

  late final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      ShellRoute(
        builder: (context, state, child) {
          return NavShellScaffold(
            state: state,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => StartupSplashGate(
              child: AuthGate(
                authService: widget.authService,
                child: HomeScreen(
                  progressService: widget.progressService,
                  coinsService: widget.coinsService,
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/play',
            builder: (context, state) {
              assert(() {
                debugPrint('[Route] build /play');
                return true;
              }());
              return PlayLevelsScreen(
                progressService: widget.progressService,
                coinsService: widget.coinsService,
              );
            },
          ),
          GoRoute(
            path: '/play/:packId',
            builder: (context, state) {
              final packId = state.pathParameters['packId']!;
              return PlayLevelsScreen(
                progressService: widget.progressService,
                coinsService: widget.coinsService,
                packId: packId,
              );
            },
          ),
          GoRoute(
            path: '/campaign',
            redirect: (context, state) => '/play',
          ),
          GoRoute(
            path: '/pack/:packId',
            redirect: (context, state) {
              final packId = state.pathParameters['packId']!;
              return '/play/$packId/1';
            },
          ),
          GoRoute(
            path: '/daily',
            builder: (context, state) => DailyScreen(
              progressService: widget.progressService,
              statsService: widget.statsService,
              achievementsService: widget.achievementsService,
            ),
          ),
          GoRoute(
            path: '/duel',
            builder: (context, state) => const DuelScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => ProfileScreen(
              statsService: widget.statsService,
              achievementsService: widget.achievementsService,
              notificationService: widget.notificationService,
              coinsService: widget.coinsService,
              skinCatalogService: widget.skinCatalogService,
              authService: widget.authService,
            ),
          ),
          GoRoute(
            path: '/social',
            builder: (context, state) => widget.authService.isGuest
                ? const SocialGuestLockedScreen()
                : const SocialScreen(),
          ),
          GoRoute(
            path: '/shop',
            builder: (context, state) => ShopScreen(
              coinsService: widget.coinsService,
              skinCatalogService: widget.skinCatalogService,
            ),
          ),
          GoRoute(
            path: '/cards',
            builder: (context, state) => CardsCollectionScreen(
              coinsService: widget.coinsService,
              skinCatalogService: widget.skinCatalogService,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/game/:packId/:level',
        redirect: (context, state) {
          final packId = state.pathParameters['packId']!;
          final level = state.pathParameters['level']!;
          return '/play/$packId/$level';
        },
      ),
      GoRoute(
        path: '/play/:packId/:level',
        builder: (context, state) {
          final packId = state.pathParameters['packId']!;
          final levelIndex = int.tryParse(state.pathParameters['level']!) ?? 1;
          final duelArgs = state.extra is LiveDuelGameArgs
              ? state.extra as LiveDuelGameArgs
              : null;
          final friendChallengeArgs = state.extra is FriendChallengeGameArgs
              ? state.extra as FriendChallengeGameArgs
              : null;
          return GameScreen(
            packId: packId,
            levelIndex: levelIndex,
            progressService: widget.progressService,
            coinsService: widget.coinsService,
            statsService: widget.statsService,
            achievementsService: widget.achievementsService,
            leaderboardService: widget.leaderboardService,
            liveDuelArgs: duelArgs,
            friendChallengeArgs: friendChallengeArgs,
          );
        },
      ),
      GoRoute(
        path: '/live-duel/:matchId',
        builder: (context, state) {
          final matchId = state.pathParameters['matchId'] ?? '';
          return LiveDuelScreen(matchId: matchId);
        },
      ),
      GoRoute(
        path: '/friend-challenge/:challengeId',
        builder: (context, state) {
          final challengeId = state.pathParameters['challengeId'] ?? '';
          return FriendChallengeScreen(challengeId: challengeId);
        },
      ),
      GoRoute(
        path: '/legacy-campaign',
        builder: (context, state) {
          return CampaignScreen(
            progressService: widget.progressService,
          );
        },
      ),
      if (kDebugMode)
        GoRoute(
          path: '/curate-batch',
          builder: (context, state) => const CurateBatchScreen(),
        ),
      GoRoute(
        path: '/leaderboard/:packId/:level',
        builder: (context, state) {
          final packId = state.pathParameters['packId']!;
          final levelIndex = int.tryParse(state.pathParameters['level']!) ?? 1;
          return PuzzleLeaderboardScreen(
            packId: packId,
            levelIndex: levelIndex,
            leaderboardService: widget.leaderboardService,
          );
        },
      ),
      GoRoute(
        path: '/victory',
        builder: (context, state) {
          final args = state.extra;
          if (args is! VictoryScreenArgs) {
            return Scaffold(
              body: Center(child: Text(context.l10n.victoryDataMissing)),
            );
          }
          return VictoryScreen(args: args);
        },
      ),
      GoRoute(
        path: '/editor',
        builder: (context, state) => const EditorPage(),
      ),
      GoRoute(
        path: '/editor-nuevos',
        builder: (context, state) => const EditorNuevosPage(),
      ),
      GoRoute(
        path: '/skin-editor',
        builder: (context, state) => SkinEditorScreen(
          catalogService: widget.skinCatalogService,
        ),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _presenceService.start();
    widget.skinCatalogService.addListener(_queueShopImageWarmup);
    _queueShopImageWarmup();
  }

  @override
  void dispose() {
    unawaited(_presenceService.stop());
    widget.skinCatalogService.removeListener(_queueShopImageWarmup);
    super.dispose();
  }

  void _queueShopImageWarmup() {
    if (_warmupQueued) return;
    _warmupQueued = true;
    Future<void>.microtask(() async {
      try {
        await _warmupShopImages();
      } finally {
        _warmupQueued = false;
      }
    });
  }

  Future<void> _warmupShopImages() async {
    final items = widget.skinCatalogService.items
        .where((e) => e.id != 'pointer_default' && e.enabled)
        .toList(growable: false);
    if (items.isEmpty) return;

    final thumbCandidates = <String>[];
    final fullCandidates = <String>[];
    for (final item in items) {
      final thumb = item.thumbnailPath.trim();
      final image = item.imagePath.trim();
      if (thumb.isNotEmpty) {
        thumbCandidates.add(widget.skinCatalogService.toRenderablePath(thumb));
      }
      if (image.isNotEmpty) {
        fullCandidates.add(widget.skinCatalogService.toRenderablePath(image));
      }
    }

    // Warm first the low-res previews used by Shop cards.
    var warmed = 0;
    for (final path in thumbCandidates) {
      if (warmed >= 48) break;
      if (_warmedShopPaths.contains(path)) continue;
      final ok = await _warmPath(path, isThumb: true);
      if (ok) {
        _warmedShopPaths.add(path);
        warmed++;
      }
    }

    // Then warm a small batch of full images for the tap-preview modal.
    var fullWarmed = 0;
    for (final path in fullCandidates) {
      if (fullWarmed >= 12) break;
      if (_warmedShopPaths.contains(path)) continue;
      final ok = await _warmPath(path, isThumb: false);
      if (ok) {
        _warmedShopPaths.add(path);
        fullWarmed++;
      }
    }

    if (kDebugMode) {
      debugPrint(
        '[ShopWarmup] thumbs=$warmed full=$fullWarmed totalCached=${_warmedShopPaths.length}',
      );
    }
  }

  Future<bool> _warmPath(String path, {required bool isThumb}) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return false;
    final sw = Stopwatch()..start();

    ImageProvider provider;
    if (trimmed.startsWith('assets/')) {
      provider = AssetImage(trimmed);
    } else if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://')) {
      final network = NetworkImage(trimmed);
      provider =
          isThumb ? ResizeImage.resizeIfNeeded(256, 256, network) : network;
    } else if (trimmed.startsWith('data:image')) {
      return false;
    } else {
      if (kIsWeb) return false;
      provider = FileImage(File(trimmed));
    }

    final completer = Completer<bool>();
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, synchronousCall) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
      onError: (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );
    stream.addListener(listener);
    final ok = await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => false,
    );
    stream.removeListener(listener);

    if (kDebugMode) {
      debugPrint(
        '[ShopWarmup][${isThumb ? 'thumb' : 'full'}] ${ok ? 'OK' : 'FAIL'} ${sw.elapsedMilliseconds}ms $trimmed',
      );
    }
    return ok;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      onGenerateTitle: (context) => context.l10n.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localeListResolutionCallback: (locales, supportedLocales) {
        if (locales == null || locales.isEmpty) {
          return const Locale('es');
        }
        for (final locale in locales) {
          final lang = locale.languageCode.toLowerCase();
          if (lang == 'es') return const Locale('es');
          if (lang == 'en') return const Locale('en');
        }
        return const Locale('es');
      },
      themeMode: ThemeMode.dark,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) {
        final content = Stack(
          fit: StackFit.expand,
          children: [
            const AppGameBackdrop(),
            if (child != null) child,
            const AppGameOverlay(),
            const CoinRewardOverlay(),
          ],
        );
        return _GlobalLiveInvitePopupHost(
          router: _router,
          navigatorKey: _rootNavigatorKey,
          child: content,
        );
      },
    );
  }
}

enum _GlobalLiveInviteAction {
  accept,
  decline,
}

class _GlobalLiveInvitePopupHost extends StatefulWidget {
  const _GlobalLiveInvitePopupHost({
    required this.child,
    required this.router,
    required this.navigatorKey,
  });

  final Widget child;
  final GoRouter router;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<_GlobalLiveInvitePopupHost> createState() =>
      _GlobalLiveInvitePopupHostState();
}

class _GlobalLiveInvitePopupHostState
    extends State<_GlobalLiveInvitePopupHost> {
  final InboxService _inboxService = InboxService();
  final LiveDuelService _liveDuelService = LiveDuelService();
  StreamSubscription<List<InboxItem>>? _inboxSub;
  StreamSubscription<User?>? _authSub;
  final Set<String> _handledInviteIds = <String>{};
  String _activeUid = '';
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final uid = user?.uid.trim() ?? '';
      _bindInbox(uid);
    });
    _bindInbox(FirebaseAuth.instance.currentUser?.uid.trim() ?? '');
  }

  @override
  void dispose() {
    _inboxSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  void _bindInbox(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid == _activeUid) return;
    _activeUid = normalizedUid;
    _inboxSub?.cancel();
    if (normalizedUid.isEmpty) return;
    _inboxSub = _inboxService.watchInbox(normalizedUid).listen(
          _handleInboxItems,
          onError: (_) {},
        );
  }

  void _handleInboxItems(List<InboxItem> items) {
    if (!mounted || _dialogOpen) return;
    InboxItem? next;
    for (final item in items) {
      if (item.type != InboxItemType.liveDuelInvite) continue;
      if (item.status.trim().toLowerCase() != 'pending') continue;
      if (_handledInviteIds.contains(item.id)) continue;
      if (item.ctaPayload.trim().isEmpty) continue;
      next = item;
      break;
    }
    if (next == null) return;
    _handledInviteIds.add(next.id);
    unawaited(_showInvitePopup(next));
  }

  Future<void> _showInvitePopup(InboxItem item) async {
    if (!mounted) return;
    final navContext = widget.navigatorKey.currentContext;
    final messengerState =
        navContext != null ? ScaffoldMessenger.maybeOf(navContext) : null;
    if (navContext == null) {
      if (kDebugMode) {
        debugPrint(
          '[live-invite-popup] navigator context unavailable '
          'inviteId=${item.id} matchId=${item.ctaPayload}',
        );
      }
      return;
    }
    _dialogOpen = true;
    try {
      final action = await showDialog<_GlobalLiveInviteAction>(
        context: navContext,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (ctx) {
          final from = item.senderDisplayName;
          final l10n = ctx.l10n;
          return AlertDialog(
            backgroundColor: const Color(0xFF111C33),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFF355687)),
            ),
            title: Text(
              l10n.liveDuelInviteTitle,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
            content: Text(
              l10n.liveDuelInviteBody(from),
              style: const TextStyle(color: Color(0xFFD3E5FF)),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(ctx).pop(_GlobalLiveInviteAction.decline),
                child: Text(l10n.decline),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(ctx).pop(_GlobalLiveInviteAction.accept),
                child: Text(l10n.accept),
              ),
            ],
          );
        },
      );
      if (!mounted || action == null) return;
      final matchId = item.ctaPayload.trim();
      if (action == _GlobalLiveInviteAction.accept) {
        await _liveDuelService.acceptInvite(
          matchId: matchId,
          inboxMessageId: item.id,
        );
        if (!mounted) return;
        widget.router.go('/live-duel/$matchId');
        return;
      }
      await _liveDuelService.declineInvite(
        matchId: matchId,
        inboxMessageId: item.id,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[live-invite-popup] firestore error '
          'code=${e.code} message=${e.message} '
          'inviteId=${item.id} matchId=${item.ctaPayload}',
        );
      }
      final txt = '${e.code} ${e.message ?? ''}';
      var msg = context.l10n.liveInviteCouldNotProcess;
      var shouldDropInvite = false;
      if (txt.contains('MATCH_NOT_FOUND')) {
        msg = context.l10n.liveInviteNoLongerAvailable;
        shouldDropInvite = true;
      } else if (txt.contains('MATCH_CLOSED')) {
        msg = context.l10n.liveInviteAlreadyClosed;
        shouldDropInvite = true;
      } else if (txt.contains('MATCH_ACCESS_DENIED')) {
        msg = context.l10n.liveInviteInvalidAccount;
        shouldDropInvite = true;
      } else if (txt.contains('INVALID_MATCH_ID')) {
        msg = context.l10n.liveInviteInvalidPayload;
        shouldDropInvite = true;
      } else if (e.code == 'permission-denied') {
        msg = context.l10n.liveInvitePermissionsBlocked;
      } else if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        msg = context.l10n.liveInviteNetworkIssue;
      }
      if (shouldDropInvite) {
        try {
          await _inboxService.deleteInboxItem(
            uid: _activeUid,
            messageId: item.id,
          );
        } catch (_) {}
      }
      if (!mounted) return;
      messengerState?.showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[live-invite-popup] error '
          'inviteId=${item.id} matchId=${item.ctaPayload} error=$e',
        );
      }
      final txt = e.toString();
      var msg = context.l10n.liveInviteCouldNotProcess;
      var shouldDropInvite = false;
      if (txt.contains('MATCH_NOT_FOUND')) {
        msg = context.l10n.liveInviteNoLongerAvailable;
        shouldDropInvite = true;
      } else if (txt.contains('MATCH_CLOSED')) {
        msg = context.l10n.liveInviteAlreadyClosed;
        shouldDropInvite = true;
      } else if (txt.contains('MATCH_ACCESS_DENIED')) {
        msg = context.l10n.liveInviteInvalidAccount;
        shouldDropInvite = true;
      } else if (txt.contains('INVALID_MATCH_ID')) {
        msg = context.l10n.liveInviteInvalidPayload;
        shouldDropInvite = true;
      }
      if (shouldDropInvite) {
        try {
          await _inboxService.deleteInboxItem(
            uid: _activeUid,
            messageId: item.id,
          );
        } catch (_) {}
      }
      if (!mounted) return;
      messengerState?.showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
