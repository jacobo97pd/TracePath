import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'coins_service.dart';
import 'progress_service.dart';
import 'ui/avatar_utils.dart';
import 'ui/components/coin_display.dart';
import 'ui/components/game_card.dart';
import 'ui/components/game_toast.dart';
import 'ui/components/network_image_compat.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.progressService,
    required this.coinsService,
  });

  final ProgressService progressService;
  final CoinsService coinsService;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([progressService, coinsService]),
      builder: (context, _) {
        final solved = progressService.totalCampaignSolved;
        final streakRaw = progressService.getDailyStreak();
        final streak = streakRaw > 0 ? streakRaw : 1;
        final dailySolved = progressService.totalDailySolved;
        final bestStreak = progressService.bestDailyStreak;
        final highestReachedRaw = solved + 1;
        final highestReached = highestReachedRaw > 0 ? highestReachedRaw : 1;
        final nextSuggestedLevel = highestReached <= 1 ? 1 : highestReached;
        final equippedSkin = coinsService.selectedSkinAssetPath;
        final isDefaultSkinSelected = isDefaultSkinId(coinsService.selectedSkin);
        final googleAvatarUrl = _resolveGoogleAvatarUrl();

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF101A30),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  22 + _homeBottomClearance(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopPlayerBar(
                      playerName: 'Player',
                      streak: streak,
                      highestLevel: highestReached,
                      coins: coinsService.coins,
                      equippedSkinPath:
                          isDefaultSkinSelected ? null : equippedSkin,
                      googleAvatarUrl: googleAvatarUrl,
                      onWalletTap: () => context.go('/shop'),
                    ),
                    const SizedBox(height: 18),
                    const _HeroBanner(),
                    const SizedBox(height: 14),
                    _PrimaryPlayCta(onTap: () => context.go('/play')),
                    const SizedBox(height: 12),
                    _ContinueCard(
                      nextLevel: nextSuggestedLevel,
                      solved: solved,
                      onTap: () => context.go('/play'),
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      title: 'Quick Access',
                      subtitle: 'Jump directly into your favorite modes',
                    ),
                    const SizedBox(height: 10),
                    _QuickAccessGrid(
                      onDaily: () => context.go('/daily'),
                      onLevels: () => context.go('/play'),
                      onSocial: () => context.go('/social'),
                      onDuelFriends: () => _showInviteFriendsPopup(context),
                    ),
                    const SizedBox(height: 22),
                    const _SectionTitle(
                      title: 'Progress',
                      subtitle: 'Your latest performance and momentum',
                    ),
                    const SizedBox(height: 10),
                    _ProgressDashboard(
                      solved: solved,
                      streak: streak,
                      bestStreak: bestStreak,
                      highestLevel: highestReached,
                    ),
                    const SizedBox(height: 10),
                    _DailySummaryCard(
                      dailySolved: dailySolved,
                      onProfileTap: () => context.go('/profile'),
                    ),
                    const SizedBox(height: 10),
                    _ProfileShortcutCard(
                      playerName: 'Player',
                      streak: streak,
                      onTap: () => context.go('/profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showInviteFriendsPopup(BuildContext context) async {
    debugPrint('[home] Duel Friends tapped');
    debugPrint('[home] Invite popup opened');
    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'Invite friends',
      barrierDismissible: true,
      barrierColor: const Color(0xCC020817),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _InviteFriendsPromoDialog(
          onInvite: () async {
            debugPrint('[home] Invite CTA tapped');
            const inviteText =
                "Join me on TracePath! Let's compete on the leaderboard. "
                'https://tracepath.app/invite';
            await Clipboard.setData(const ClipboardData(text: inviteText));
            if (!context.mounted) return;
            Navigator.of(context).pop();
            unawaited(
              GameToast.show(
                context,
                type: GameToastType.social,
                title: 'Invite Ready',
                message: 'Invite copied. Share it on WhatsApp, email, or any app.',
                duration: const Duration(milliseconds: 1800),
              ),
            );
          },
          onMaybeLater: () {
            debugPrint('[home] Maybe later tapped');
            Navigator.of(context).pop();
          },
          onGoToSocial: () {
            debugPrint('[home] Go to Social tapped');
            Navigator.of(context).pop();
            context.go('/social');
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  String _resolveGoogleAvatarUrl() {
    final user = FirebaseAuth.instance.currentUser;
    final candidates = <String>[
      (user?.photoURL ?? '').trim(),
      if (user != null)
        ...user.providerData
            .map((p) => (p.photoURL ?? '').trim())
            .where((v) => v.isNotEmpty),
    ];
    for (final c in candidates) {
      final normalized = _normalizeAvatarPath(c);
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }

  String _normalizeAvatarPath(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:image') ||
        value.startsWith('assets/')) {
      return value;
    }
    return '';
  }

  double _homeBottomClearance(BuildContext context) {
    final inset = MediaQuery.of(context).padding.bottom;
    return 96 + inset;
  }
}

class _TopPlayerBar extends StatelessWidget {
  const _TopPlayerBar({
    required this.playerName,
    required this.streak,
    required this.highestLevel,
    required this.coins,
    required this.equippedSkinPath,
    required this.googleAvatarUrl,
    required this.onWalletTap,
  });

  final String playerName;
  final int streak;
  final int highestLevel;
  final int coins;
  final String? equippedSkinPath;
  final String googleAvatarUrl;
  final VoidCallback onWalletTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16233A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2B3F63)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF0E1729),
              border: Border.all(color: const Color(0xFF3A547D)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _TopAvatar(
                skinPath: equippedSkinPath,
                googleAvatarUrl: googleAvatarUrl,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TracePath',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  playerName,
                  style: const TextStyle(
                    color: Color(0xFF9EB6E3),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Pill(text: 'Streak $streak'),
                    _Pill(text: 'Lv $highestLevel'),
                  ],
                ),
              ],
            ),
          ),
          CoinDisplay(
            coins: coins,
            onTap: onWalletTap,
            prominent: true,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1F3152),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF3E5F97)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD7E5FF),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TopAvatar extends StatelessWidget {
  const _TopAvatar({
    required this.skinPath,
    required this.googleAvatarUrl,
  });

  final String? skinPath;
  final String googleAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final skin = (skinPath ?? '').trim();
    final google = googleAvatarUrl.trim();
    if (skin.isNotEmpty) {
      return _EquippedSkinImage(path: skin);
    }
    if (google.isNotEmpty) {
      return Image.network(
        google,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person_rounded,
          color: Color(0xFFD5E3FF),
        ),
      );
    }
    return const Icon(Icons.person_rounded, color: Color(0xFFD5E3FF));
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2850), Color(0xFF152347), Color(0xFF131C35)],
        ),
        border: Border.all(color: const Color(0xFF3B4F77)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -8,
            child: Icon(
              Icons.hub_rounded,
              size: 110,
              color: const Color(0xFF74A3FF).withOpacity(0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Train your brain',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Trace paths faster, improve precision, and climb every challenge.',
                style: TextStyle(
                  color: Color(0xFFACB9D3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _PrimaryPlayCta extends StatelessWidget {
  const _PrimaryPlayCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF06B6D4),
                  Color(0xFF3B82F6),
                  Color(0xFF8B5CF6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x8806B6D4),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: Color(0x668B5CF6),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                ),
              ],
              border: Border.all(color: const Color(0xCCFFFFFF), width: 1.4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.bolt_rounded, size: 28, color: Colors.white),
                SizedBox(width: 10),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'START SOLVING!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Jump into your next puzzle',
            style: TextStyle(
              color: Color(0xFFAFC0DF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.nextLevel,
    required this.solved,
    required this.onTap,
  });

  final int nextLevel;
  final int solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF243044),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF8AA8FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  solved > 0
                      ? 'Level $nextLevel · Pick up where you left off'
                      : 'Start your first run',
                  style: const TextStyle(
                    color: Color(0xFF9BA8C3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB8C4DE)),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid({
    required this.onDaily,
    required this.onLevels,
    required this.onSocial,
    required this.onDuelFriends,
  });

  final VoidCallback onDaily;
  final VoidCallback onLevels;
  final VoidCallback onSocial;
  final VoidCallback onDuelFriends;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _QuickCard(
          icon: Icons.calendar_month_rounded,
          title: 'Daily Puzzle',
          subtitle: 'One challenge each day',
          onTap: onDaily,
        ),
        const SizedBox(height: 10),
        _QuickCard(
          icon: Icons.grid_view_rounded,
          title: 'Levels',
          subtitle: 'Choose any available level',
          onTap: onLevels,
        ),
        const SizedBox(height: 10),
        _QuickCard(
          icon: Icons.groups_rounded,
          title: 'Social',
          subtitle: 'Friends, inbox and multiplayer',
          onTap: onSocial,
        ),
        const SizedBox(height: 10),
        _QuickCard(
          icon: Icons.emoji_events_outlined,
          title: 'Duel Friends',
          subtitle: 'Social rankings and challenges',
          onTap: onDuelFriends,
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF243044),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF8AA8FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9BA8C3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB8C4DE)),
        ],
      ),
    );
  }
}

class _ProgressDashboard extends StatelessWidget {
  const _ProgressDashboard({
    required this.solved,
    required this.streak,
    required this.bestStreak,
    required this.highestLevel,
  });

  final int solved;
  final int streak;
  final int bestStreak;
  final int highestLevel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Levels solved',
                value: '$solved',
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Current streak',
                value: '$streak',
                icon: Icons.local_fire_department_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Best streak',
                value: '$bestStreak',
                icon: Icons.workspace_premium_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Highest level',
                value: '$highestLevel',
                icon: Icons.flag_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2538),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF304560)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8AA8FF), size: 16),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9BA8C3),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({
    required this.dailySolved,
    required this.onProfileTap,
  });

  final int dailySolved;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFF8AA8FF)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Daily puzzles solved: $dailySolved',
              style: const TextStyle(
                color: Color(0xFFD8E0F5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onProfileTap,
            child: const Text('View profile'),
          ),
        ],
      ),
    );
  }
}

class _ProfileShortcutCard extends StatelessWidget {
  const _ProfileShortcutCard({
    required this.playerName,
    required this.streak,
    required this.onTap,
  });

  final String playerName;
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF243044),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFF8AA8FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Streak: $streak · Open your profile',
                  style: const TextStyle(
                    color: Color(0xFF9BA8C3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB8C4DE)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF9EB0D2),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EquippedSkinImage extends StatelessWidget {
  const _EquippedSkinImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return buildNetworkImageCompat(
        url: path,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        fallback:
            const Icon(Icons.broken_image_outlined, color: Colors.white70),
      );
    }
    if (path.startsWith('data:image')) {
      final comma = path.indexOf(',');
      if (comma > 0 && comma < path.length - 1) {
        final bytes = base64Decode(path.substring(comma + 1));
        return Image.memory(bytes, fit: BoxFit.cover);
      }
    }
    if (kIsWeb) {
      return const Icon(Icons.image_not_supported_outlined, color: Colors.white70);
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image_outlined, color: Colors.white70),
    );
  }
}

class _InviteFriendsPromoDialog extends StatelessWidget {
  const _InviteFriendsPromoDialog({
    required this.onInvite,
    required this.onMaybeLater,
    required this.onGoToSocial,
  });

  final Future<void> Function() onInvite;
  final VoidCallback onMaybeLater;
  final VoidCallback onGoToSocial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GameCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invite friend and earn 200 coins!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Challenge your friends, climb the leaderboard, and get rewarded when they join TracePath.',
                    style: TextStyle(
                      color: Color(0xFFBFCDE8),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onInvite,
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Invite Friend'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onMaybeLater,
                          child: const Text('Maybe later'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton(
                          onPressed: onGoToSocial,
                          child: const Text('Go to Social'),
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
}


