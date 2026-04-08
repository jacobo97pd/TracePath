import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../progress_service.dart';

enum OnboardingStep {
  playTutorialLevel,
  visitShop,
  viewCards,
  lockerLocation,
  checkInbox,
  socialSetup,
  duelIntro,
  completed,
}

class OnboardingStepInfo {
  const OnboardingStepInfo({
    required this.stepNumber,
    required this.totalSteps,
    required this.targetRoute,
    required this.titleEs,
    required this.descriptionEs,
    required this.titleEn,
    required this.descriptionEn,
    this.routeAutoAdvance = false,
    this.needsManualConfirm = false,
    this.isActionDriven = false,
    this.manualButtonEs = 'Continuar',
    this.manualButtonEn = 'Continue',
  });

  final int stepNumber;
  final int totalSteps;
  final String targetRoute;
  final String titleEs;
  final String descriptionEs;
  final String titleEn;
  final String descriptionEn;
  final bool routeAutoAdvance;
  final bool needsManualConfirm;
  final bool isActionDriven;
  final String manualButtonEs;
  final String manualButtonEn;

  String title(String languageCode) =>
      languageCode.toLowerCase().startsWith('es') ? titleEs : titleEn;

  String description(String languageCode) =>
      languageCode.toLowerCase().startsWith('es')
          ? descriptionEs
          : descriptionEn;

  String manualButton(String languageCode) =>
      languageCode.toLowerCase().startsWith('es')
          ? manualButtonEs
          : manualButtonEn;
}

class OnboardingService extends ChangeNotifier {
  OnboardingService._();

  static final OnboardingService instance = OnboardingService._();

  static const String _storagePrefix = 'onboarding_v2_step_';
  static const String _guestStorageKey = '${_storagePrefix}guest';
  static const String tutorialPackId = 'tutorial';
  static const int tutorialLevelIndex = 1;

  SharedPreferences? _prefs;
  ProgressService? _progressService;
  StreamSubscription<User?>? _authSub;
  String _activeUid = '';
  bool _initialized = false;
  OnboardingStep _step = OnboardingStep.completed;
  String _lastRoutePath = '';
  OnboardingStep _lastRouteStage = OnboardingStep.completed;

  final GlobalKey homePlayCtaKey =
      GlobalKey(debugLabel: 'onboarding_home_play_cta');
  final GlobalKey shopTabsKey = GlobalKey(debugLabel: 'onboarding_shop_tabs');
  final GlobalKey profileOpenVaultKey =
      GlobalKey(debugLabel: 'onboarding_profile_open_vault');
  final GlobalKey profileInboxKey =
      GlobalKey(debugLabel: 'onboarding_profile_inbox');
  final GlobalKey socialUsernameKey =
      GlobalKey(debugLabel: 'onboarding_social_username');
  final GlobalKey duelChallengeKey =
      GlobalKey(debugLabel: 'onboarding_duel_challenge');

  OnboardingStep get step => _step;
  bool get isActive => _step != OnboardingStep.completed;
  String get requiredRoute => infoForStep(_step).targetRoute;
  bool get shouldLaunchTutorialFromHomeCta =>
      _step == OnboardingStep.playTutorialLevel;
  String get tutorialRoute => '/play/$tutorialPackId/$tutorialLevelIndex';

  Future<void> initialize({
    required SharedPreferences prefs,
    required ProgressService progressService,
  }) async {
    if (_initialized) return;
    _initialized = true;
    _prefs = prefs;
    _progressService = progressService;
    _progressService?.addListener(_onProgressChanged);
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    await _loadStepForUid(FirebaseAuth.instance.currentUser?.uid ?? '');
    _onProgressChanged();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _progressService?.removeListener(_onProgressChanged);
    super.dispose();
  }

  Future<void> _onAuthChanged(User? user) async {
    await _loadStepForUid(user?.uid ?? '');
    _onProgressChanged();
  }

  String _storageKeyForUid(String uid) {
    final normalized = uid.trim();
    if (normalized.isEmpty) return _guestStorageKey;
    return '$_storagePrefix$normalized';
  }

  Future<void> _loadStepForUid(String uid) async {
    final prefs = _prefs;
    if (prefs == null) return;
    _activeUid = uid.trim();
    final key = _storageKeyForUid(_activeUid);
    final saved = prefs.getString(key);
    if (saved == null) {
      final solved = _progressService?.totalCampaignSolved ?? 0;
      _step = solved > 0
          ? OnboardingStep.completed
          : OnboardingStep.playTutorialLevel;
      await prefs.setString(key, _step.name);
    } else {
      _step = _fromStoredStep(saved);
    }
    _lastRoutePath = '';
    _lastRouteStage = OnboardingStep.completed;
    notifyListeners();
  }

  Future<void> _persistStep() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_storageKeyForUid(_activeUid), _step.name);
  }

  Future<void> _advanceTo(OnboardingStep next) async {
    if (_step == next) return;
    _step = next;
    _lastRoutePath = '';
    _lastRouteStage = OnboardingStep.completed;
    notifyListeners();
    await _persistStep();
    if (kDebugMode) {
      debugPrint('[onboarding] step -> ${_step.name}');
    }
  }

  OnboardingStepInfo infoForStep(OnboardingStep value) {
    switch (value) {
      case OnboardingStep.playTutorialLevel:
        return const OnboardingStepInfo(
          stepNumber: 1,
          totalSteps: 7,
          targetRoute: '/home',
          titleEs: 'Paso 1: Aprende a jugar',
          descriptionEs:
              'Pulsa Jugar y completa el nivel tutorial. Te guiara para entender la mecanica.',
          titleEn: 'Step 1: Learn how to play',
          descriptionEn:
              'Tap Play and complete the tutorial level to learn the core mechanics.',
          isActionDriven: true,
        );
      case OnboardingStep.visitShop:
        return const OnboardingStepInfo(
          stepNumber: 2,
          totalSteps: 7,
          targetRoute: '/shop',
          titleEs: 'Paso 2: Tienda de skins y estelas',
          descriptionEs:
              'En Tienda veras dos pestanas: Skins y Estelas. Aqui compras personalizacion.',
          titleEn: 'Step 2: Skins and trails shop',
          descriptionEn:
              'In Shop you have two tabs: Skins and Trails. This is where you buy customization.',
          needsManualConfirm: true,
          manualButtonEs: 'Ya vi skins y estelas',
          manualButtonEn: 'I reviewed skins and trails',
        );
      case OnboardingStep.viewCards:
        return const OnboardingStepInfo(
          stepNumber: 3,
          totalSteps: 7,
          targetRoute: '/cards',
          titleEs: 'Paso 3: Cartas coleccionables',
          descriptionEs:
              'Las skins tambien son cartas. Revisa tu coleccion para conocer rarezas y progreso.',
          titleEn: 'Step 3: Collectible cards',
          descriptionEn:
              'Skins are also collectible cards. Check your collection and rarities.',
          needsManualConfirm: true,
          manualButtonEs: 'Entendido',
          manualButtonEn: 'Understood',
        );
      case OnboardingStep.lockerLocation:
        return const OnboardingStepInfo(
          stepNumber: 4,
          totalSteps: 7,
          targetRoute: '/profile',
          titleEs: 'Paso 4: Donde equipar',
          descriptionEs:
              'Cuando compres skins o estelas, puedes equiparlas desde Perfil > Boveda/Cofre.',
          titleEn: 'Step 4: Where to equip',
          descriptionEn:
              'After buying skins or trails, equip them from Profile > Vault/Locker.',
          needsManualConfirm: true,
          manualButtonEs: 'Ya se donde equipar',
          manualButtonEn: 'I know where to equip',
        );
      case OnboardingStep.checkInbox:
        return const OnboardingStepInfo(
          stepNumber: 5,
          totalSteps: 7,
          targetRoute: '/profile',
          titleEs: 'Paso 5: Inbox',
          descriptionEs:
              'En el inbox recibes comunicaciones, solicitudes y recompensas del juego.',
          titleEn: 'Step 4: Inbox',
          descriptionEn:
              'Inbox is where you receive communications, requests and rewards.',
          needsManualConfirm: true,
          manualButtonEs: 'Ya revisado',
          manualButtonEn: 'Got it',
        );
      case OnboardingStep.socialSetup:
        return const OnboardingStepInfo(
          stepNumber: 6,
          totalSteps: 7,
          targetRoute: '/social',
          titleEs: 'Paso 6: Social',
          descriptionEs:
              'Explora la seccion social. Puedes configurar tu username y agregar amigos mas adelante.',
          titleEn: 'Step 5: Social',
          descriptionEn:
              'Explore the social section. You can set your username and add friends later.',
          needsManualConfirm: true,
          manualButtonEs: 'Continuar',
          manualButtonEn: 'Continue',
        );
      case OnboardingStep.duelIntro:
        return const OnboardingStepInfo(
          stepNumber: 7,
          totalSteps: 7,
          targetRoute: '/duel',
          titleEs: 'Paso 7: Duelo',
          descriptionEs:
              'Aqui puedes invitar amigos y jugar 1v1 en vivo. Cuando quieras, inicia tu primer duelo.',
          titleEn: 'Step 6: Duel',
          descriptionEn:
              'Invite friends and play live 1v1 duels here. Start your first duel when you are ready.',
          needsManualConfirm: true,
          manualButtonEs: 'Terminar tutorial',
          manualButtonEn: 'Finish tutorial',
        );
      case OnboardingStep.completed:
        return const OnboardingStepInfo(
          stepNumber: 7,
          totalSteps: 7,
          targetRoute: '/home',
          titleEs: '',
          descriptionEs: '',
          titleEn: '',
          descriptionEn: '',
        );
    }
  }

  bool isCurrentRouteTarget(String currentPath) {
    return _matches(currentPath, requiredRoute);
  }

  bool isRouteAllowed(String targetPath) {
    if (!isActive) return true;
    if (_matches(targetPath, requiredRoute)) return true;
    if (_matches(targetPath, '/home')) return true;
    if (_step == OnboardingStep.playTutorialLevel &&
        (_matches(targetPath, tutorialRoute) ||
            _matches(targetPath, '/play/$tutorialPackId'))) {
      return true;
    }
    return false;
  }

  String blockedMessage(String languageCode) {
    final info = infoForStep(_step);
    if (languageCode.toLowerCase().startsWith('es')) {
      return 'Primero completa: ${info.titleEs.replaceFirst('Paso ${info.stepNumber}: ', '')}';
    }
    return 'Complete this first: ${info.titleEn.replaceFirst('Step ${info.stepNumber}: ', '')}';
  }

  void markRouteSeen(String path) {
    if (!isActive) return;
    final normalized = path.trim();
    if (normalized.isEmpty) return;
    if (normalized == _lastRoutePath && _lastRouteStage == _step) return;
    _lastRoutePath = normalized;
    _lastRouteStage = _step;
    final info = infoForStep(_step);
    if (info.routeAutoAdvance && _matches(normalized, info.targetRoute)) {
      switch (_step) {
        case OnboardingStep.visitShop:
          unawaited(_advanceTo(OnboardingStep.viewCards));
          break;
        case OnboardingStep.viewCards:
          unawaited(_advanceTo(OnboardingStep.lockerLocation));
          break;
        default:
          break;
      }
    }
  }

  GlobalKey? currentSpotlightKey(String currentPath) {
    if (!isActive || !isCurrentRouteTarget(currentPath)) return null;
    switch (_step) {
      case OnboardingStep.playTutorialLevel:
        return homePlayCtaKey;
      case OnboardingStep.visitShop:
        return shopTabsKey;
      case OnboardingStep.lockerLocation:
        return profileOpenVaultKey;
      case OnboardingStep.checkInbox:
        return profileInboxKey;
      case OnboardingStep.socialSetup:
        return socialUsernameKey;
      case OnboardingStep.duelIntro:
        return duelChallengeKey;
      case OnboardingStep.viewCards:
      case OnboardingStep.completed:
        return null;
    }
  }

  Future<void> completeManualStep() async {
    if (!isActive) return;
    switch (_step) {
      case OnboardingStep.visitShop:
        await _advanceTo(OnboardingStep.viewCards);
        break;
      case OnboardingStep.viewCards:
        await _advanceTo(OnboardingStep.lockerLocation);
        break;
      case OnboardingStep.lockerLocation:
        await _advanceTo(OnboardingStep.checkInbox);
        break;
      case OnboardingStep.checkInbox:
        await _advanceTo(OnboardingStep.socialSetup);
        break;
      case OnboardingStep.socialSetup:
        await _advanceTo(OnboardingStep.duelIntro);
        break;
      case OnboardingStep.duelIntro:
        await _advanceTo(OnboardingStep.completed);
        break;
      default:
        break;
    }
  }

  Future<void> markFirstLevelCompleted() async {
    if (_step == OnboardingStep.playTutorialLevel) {
      await _advanceTo(OnboardingStep.visitShop);
    }
  }

  Future<void> markSocialActionCompleted() async {
    if (_step == OnboardingStep.socialSetup) {
      await _advanceTo(OnboardingStep.duelIntro);
    }
  }

  void _onProgressChanged() {
    if (_step == OnboardingStep.playTutorialLevel &&
        (_progressService?.totalCampaignSolved ?? 0) > 0) {
      unawaited(_advanceTo(OnboardingStep.visitShop));
    }
  }

  OnboardingStep _fromStoredStep(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return OnboardingStep.completed;
    if (normalized == 'playFirstLevel') return OnboardingStep.playTutorialLevel;
    if (normalized == 'equipFromLocker') return OnboardingStep.lockerLocation;
    return OnboardingStep.values.firstWhere(
      (s) => s.name == normalized,
      orElse: () => OnboardingStep.completed,
    );
  }

  static bool _matches(String path, String route) =>
      path == route || path.startsWith('$route/');
}

