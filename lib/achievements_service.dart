import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress_service.dart';
import 'stats_service.dart';
import 'services/achievement_persistence_service.dart';

class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

class AchievementState {
  const AchievementState({
    required this.def,
    required this.unlocked,
    required this.unlockedAt,
  });

  final AchievementDef def;
  final bool unlocked;
  final DateTime? unlockedAt;
}

class AchievementsService extends ChangeNotifier {
  AchievementsService(
    this._prefs,
    this._progressService,
    this._statsService, {
    this.speedrunnerThresholdMs = 30000,
    AchievementPersistenceService? persistenceService,
  }) {
    _load();
    _persistenceService = persistenceService ?? AchievementPersistenceService();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      unawaited(_hydrateForUid(user?.uid));
    });
    unawaited(_hydrateForUid(FirebaseAuth.instance.currentUser?.uid));
  }

  static const String _storageKeyBase = 'achievements_unlocked_at';

  static const List<AchievementDef> definitions = <AchievementDef>[
    AchievementDef(
      id: 'first_steps',
      title: 'First Steps',
      description: 'Complete 1 level',
    ),
    AchievementDef(
      id: 'no_help_needed',
      title: 'No Help Needed',
      description: 'Complete a level with 0 hints',
    ),
    AchievementDef(
      id: 'clean_run',
      title: 'Clean Run',
      description: 'Complete a level with 0 rewinds',
    ),
    AchievementDef(
      id: 'daily_habit',
      title: 'Daily Habit',
      description: 'Complete 3 dailies',
    ),
    AchievementDef(
      id: 'streak_7',
      title: 'Streak 7',
      description: 'Reach a 7-day daily streak',
    ),
    AchievementDef(
      id: 'hardcore',
      title: 'Hardcore',
      description: 'Complete difficulty 5 with 0 hints and 0 rewinds',
    ),
    AchievementDef(
      id: 'speedrunner',
      title: 'Speedrunner',
      description: 'Complete any level under 30 seconds',
    ),
  ];

  final SharedPreferences _prefs;
  final ProgressService _progressService;
  final StatsService _statsService;
  final int speedrunnerThresholdMs;
  late final AchievementPersistenceService _persistenceService;
  StreamSubscription<User?>? _authSub;
  final Map<String, int> _unlockedAtMs = <String, int>{};
  String? _activeUid;

  List<AchievementState> get states {
    return definitions.map((def) {
      final at = _unlockedAtMs[def.id];
      return AchievementState(
        def: def,
        unlocked: at != null,
        unlockedAt: at == null ? null : DateTime.fromMillisecondsSinceEpoch(at),
      );
    }).toList();
  }

  Future<List<AchievementDef>> evaluateAfterCompletion({
    required SolveMode mode,
    required int difficulty,
    required int solveTimeMs,
    required int hintsUsed,
    required int rewindsUsed,
  }) async {
    final unlockedNow = <AchievementDef>[];
    final totalSolved = _statsService.totalCampaignSolved +
        _statsService.totalDailySolved +
        _statsService.totalEndlessSolved;

    for (final def in definitions) {
      if (_unlockedAtMs.containsKey(def.id)) {
        continue;
      }
      if (_checkUnlocked(
        def.id,
        mode: mode,
        difficulty: difficulty,
        solveTimeMs: solveTimeMs,
        hintsUsed: hintsUsed,
        rewindsUsed: rewindsUsed,
        totalSolved: totalSolved,
      )) {
        final unlockedAtMs = await _persistUnlock(def.id);
        _unlockedAtMs[def.id] = unlockedAtMs;
        unlockedNow.add(def);
      }
    }

    if (unlockedNow.isNotEmpty) {
      await _save();
      notifyListeners();
    }
    return unlockedNow;
  }

  bool _checkUnlocked(
    String id, {
    required SolveMode mode,
    required int difficulty,
    required int solveTimeMs,
    required int hintsUsed,
    required int rewindsUsed,
    required int totalSolved,
  }) {
    switch (id) {
      case 'first_steps':
        return totalSolved >= 1;
      case 'no_help_needed':
        return hintsUsed == 0;
      case 'clean_run':
        return rewindsUsed == 0;
      case 'daily_habit':
        return _statsService.totalDailySolved >= 3;
      case 'streak_7':
        return _progressService.getDailyStreak() >= 7;
      case 'hardcore':
        return difficulty == 5 && hintsUsed == 0 && rewindsUsed == 0;
      case 'speedrunner':
        return solveTimeMs < speedrunnerThresholdMs;
      default:
        return false;
    }
  }

  void _load() {
    final raw = _prefs.getString(_storageKeyBase);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final ms = entry.value;
        if (ms is int) {
          _unlockedAtMs[entry.key] = ms;
        }
      }
    } catch (_) {
      // Ignore malformed payload.
    }
  }

  Future<void> _save() async {
    final key = _storageKeyForUid(_activeUid);
    await _prefs.setString(key, jsonEncode(_unlockedAtMs));
    if (key != _storageKeyBase) {
      await _prefs.remove(_storageKeyBase);
    }
  }

  Future<void> _hydrateForUid(String? uid) async {
    _activeUid = uid?.trim().isNotEmpty == true ? uid!.trim() : null;
    _unlockedAtMs
      ..clear()
      ..addAll(_loadMapFromPrefs(_storageKeyForUid(_activeUid)));

    if (_activeUid != null) {
      try {
        final remote = await _persistenceService.loadUserAchievements(_activeUid!);
        for (final entry in remote.entries) {
          if (!entry.value.unlocked) continue;
          final at = entry.value.unlockedAt ??
              _parseDateText(entry.value.unlockedDateText) ??
              DateTime.now();
          _unlockedAtMs[entry.key] = at.millisecondsSinceEpoch;
        }
      } catch (_) {
        // Keep local fallback if Firestore read fails.
      }
    }

    await _save();
    notifyListeners();
  }

  Future<int> _persistUnlock(String achievementId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final uid = _activeUid;
    if (uid == null) return now;
    try {
      final remote = await _persistenceService.unlockAchievement(
        uid: uid,
        achievementId: achievementId,
      );
      final at = remote?.unlockedAt ?? _parseDateText(remote?.unlockedDateText);
      return (at ?? DateTime.now()).millisecondsSinceEpoch;
    } catch (_) {
      return now;
    }
  }

  Map<String, int> _loadMapFromPrefs(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return <String, int>{};
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, int>{};
      for (final entry in decoded.entries) {
        final ms = entry.value;
        if (ms is int) {
          out[entry.key] = ms;
        } else if (ms is num) {
          out[entry.key] = ms.toInt();
        }
      }
      return out;
    } catch (_) {
      return <String, int>{};
    }
  }

  String _storageKeyForUid(String? uid) {
    if (uid == null || uid.isEmpty) return _storageKeyBase;
    return '${_storageKeyBase}_$uid';
  }

  DateTime? _parseDateText(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
