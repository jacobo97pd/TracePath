import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';

import 'adaptive_difficulty_service.dart';
import 'achievements_service.dart';
import 'app_theme.dart';
import 'auth_gate.dart';
import 'auth_service.dart';
import 'campaign_screen.dart';
import 'coins_service.dart';
import 'curate_batch_screen.dart';
import 'daily_screen.dart';
import 'game_screen.dart';
import 'home_screen.dart';
import 'editor/editor_page.dart';
import 'editor/editor_nuevos_page.dart';
import 'leaderboard_service.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    } catch (_) {
      // Android/iOS native config may be added later (google-services.json / plist).
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
  await notificationService.initialize(progressService: progressService);
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

  late final GoRouter _router = GoRouter(
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
          return GameScreen(
            packId: packId,
            levelIndex: levelIndex,
            progressService: widget.progressService,
            coinsService: widget.coinsService,
            statsService: widget.statsService,
            achievementsService: widget.achievementsService,
            leaderboardService: widget.leaderboardService,
          );
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
            return const Scaffold(
              body: Center(child: Text('Victory data missing')),
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
    widget.skinCatalogService.addListener(_queueShopImageWarmup);
    _queueShopImageWarmup();
  }

  @override
  void dispose() {
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
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final network = NetworkImage(trimmed);
      provider = isThumb
          ? ResizeImage.resizeIfNeeded(256, 256, network)
          : network;
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
      themeMode: ThemeMode.dark,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
    );
  }
}
