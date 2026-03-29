import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'network_burst_overlay.dart';
import 'models/friend_profile.dart';
import 'services/friends_service.dart';
import 'services/friends_ranking_service.dart';
import 'services/live_duel_service.dart';
import 'ui/components/friends_ranking_list.dart';
import 'ui/components/game_button.dart';
import 'ui/components/game_card.dart';
import 'ui/components/presence_dot.dart';
import 'ui/components/stat_item.dart';

class VictoryScreenArgs {
  const VictoryScreenArgs({
    required this.zipNumber,
    required this.headline,
    required this.timeText,
    required this.averageText,
    required this.streak,
    required this.primaryLabel,
    required this.primaryActionId,
    required this.accentColor,
    required this.shareText,
    required this.copyText,
    this.coinsEarned = 0,
    this.adBonusCoins = 0,
    this.levelId = '',
  });

  final int zipNumber;
  final String headline;
  final String timeText;
  final String averageText;
  final int streak;
  final String primaryLabel;
  final String primaryActionId;
  final Color accentColor;
  final String shareText;
  final String copyText;
  final int coinsEarned;
  final int adBonusCoins;
  final String levelId;
}

String defaultVictoryHeadline(int seed) {
  const headlines = <String>[
    "You're on fire!",
    'Crushing it!',
    'Perfect run!',
    'Sharp move!',
  ];
  return headlines[seed.abs() % headlines.length];
}

class VictoryScreen extends StatefulWidget {
  const VictoryScreen({super.key, required this.args});

  final VictoryScreenArgs args;

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen>
    with TickerProviderStateMixin {
  final FriendsRankingService _friendsRankingService = FriendsRankingService();
  final FriendsService _friendsService = FriendsService();
  final LiveDuelService _liveDuelService = LiveDuelService();
  late Future<List<FriendsRankingRow>> _friendsRankingFuture;
  late final AnimationController _introController;
  late final AnimationController _ctaPulseController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _headlineScale;

  @override
  void initState() {
    super.initState();
    _friendsRankingFuture = _loadFriendsRanking();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ctaPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _headerFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.34, curve: Curves.easeOut),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.34, curve: Curves.easeOutCubic),
      ),
    );
    _headlineScale = TweenSequence<double>(
      <TweenSequenceItem<double>>[
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.92, end: 1.04)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 55,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.04, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 45,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.12, 0.48),
      ),
    );
    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _ctaPulseController.dispose();
    super.dispose();
  }

  Future<List<FriendsRankingRow>> _loadFriendsRanking() async {
    return _friendsRankingService.loadForLevel(widget.args.levelId);
  }

  Future<void> _sendChallengeToFriend() async {
    final levelId = widget.args.levelId.trim();
    if (levelId.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This challenge is only available for level runs.'),
          duration: Duration(milliseconds: 1100),
        ),
      );
      return;
    }
    List<FriendProfile> friends = const <FriendProfile>[];
    try {
      friends = await _friendsService.getFriends();
      friends = friends.toList(growable: false)
        ..sort((a, b) {
          if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
          return a.displayName
              .toLowerCase()
              .compareTo(b.displayName.toLowerCase());
        });
    } catch (_) {}
    if (!mounted) return;
    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add friends first to send in-game challenges.'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    final friend = await showModalBottomSheet<FriendProfile>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A2A45), Color(0xFF121D34)],
              ),
              border: Border.all(color: const Color(0xFF355687)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55102138),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Challenge a friend',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Send a live duel invite with a random puzzle',
                  style:
                      const TextStyle(color: Color(0xFF9EB0D2), fontSize: 12),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 340),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: friends.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final f = friends[index];
                      return Material(
                        color: const Color(0xFF1A2A43),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).pop(f),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFF2A3E63),
                                      child: Text(
                                        f.displayName.isNotEmpty
                                            ? f.displayName
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : 'P',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: -1,
                                      child: PresenceDot(
                                        isOnline: f.isOnline,
                                        size: 9,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        f.displayName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        f.isOnline
                                            ? 'Invite to a live 1v1 duel · Online'
                                            : 'Invite to a live 1v1 duel · Offline',
                                        style: const TextStyle(
                                          color: Color(0xFF9EB0D2),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.send_rounded,
                                  color: const Color(0xFFA9C4FF),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || friend == null) return;

    try {
      if (kDebugMode) {
        debugPrint('Challenge button pressed from [victory]');
      }
      final created = await _liveDuelService.createRandomInvite(
        toUid: friend.uid,
        excludedLevelId: levelId,
        preferredLevelId: levelId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Live duel invite sent'),
          duration: Duration(milliseconds: 1100),
        ),
      );
      context.go('/live-duel/${created.matchId}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[victory] sendLiveDuelInvite failed toUid=${friend.uid} levelId=$levelId error=$e');
      }
      if (!mounted) return;
      var message = 'Could not send challenge right now';
      if (e is FirebaseException && e.code == 'permission-denied') {
        message = 'Challenge blocked by Firestore rules';
      } else if (e is FirebaseException && e.code == 'failed-precondition') {
        message = 'Challenge setup is not ready yet. Try again in a moment.';
      } else if (e.toString().contains('ALREADY_IN_ACTIVE_DUEL')) {
        message = 'Finish your active duel first';
      } else if (e.toString().contains('TARGET_IN_ACTIVE_DUEL')) {
        message = '${friend.displayName} is already in another duel';
      } else if (e.toString().contains('NO_PUZZLES_AVAILABLE')) {
        message = 'No puzzles available for duel';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1100),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final stats = <({String label, String value})>[
      (label: 'Time', value: args.timeText),
      (label: 'Best time', value: args.averageText),
      (
        label: args.adBonusCoins > 0
            ? 'Coins (+${args.adBonusCoins} ad)'
            : 'Coins reward',
        value: '+${args.coinsEarned}',
      ),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Positioned.fill(
            child: NetworkBurstOverlay(
              visible: true,
              duration: const Duration(milliseconds: 2200),
              accentColor: args.accentColor,
              isDark: true,
              loop: true,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeTransition(
                    opacity: _headerFade,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/');
                              }
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF243044),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                          Text(
                            'LEVEL COMPLETE',
                            style: TextStyle(
                              color: args.accentColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeTransition(
                    opacity: _headerFade,
                    child: ScaleTransition(
                      scale: _headlineScale,
                      child: Text(
                        args.headline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var i = 0; i < stats.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _StaggerIn(
                            parent: _introController,
                            start: 0.34 + i * 0.06,
                            end: 0.6 + i * 0.06,
                            child: GameCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              child: StatItem(
                                label: stats[i].label,
                                value: stats[i].value,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StaggerIn(
                    parent: _introController,
                    start: 0.52,
                    end: 0.78,
                    child: GameCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFFF8A4A),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Current streak: ${args.streak}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (args.levelId.trim().isNotEmpty) ...[
                    _StaggerIn(
                      parent: _introController,
                      start: 0.58,
                      end: 0.86,
                      child: GameCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Friends ranking',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            FriendsRankingList(
                              future: _friendsRankingFuture,
                              currentUid: currentUid,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Spacer(),
                  _StaggerIn(
                    parent: _introController,
                    start: 0.82,
                    end: 1.0,
                    child: AnimatedBuilder(
                      animation: _ctaPulseController,
                      builder: (context, child) {
                        final pulse = 0.45 + (_ctaPulseController.value * 0.55);
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    args.accentColor.withOpacity(0.18 * pulse),
                                blurRadius: 24 + (8 * pulse),
                                spreadRadius: 0.5 + pulse,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: GameButton(
                        label: args.primaryLabel,
                        icon: Icons.skip_next_rounded,
                        expanded: true,
                        prominent: true,
                        onTap: () =>
                            Navigator.of(context).pop(args.primaryActionId),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StaggerIn(
                    parent: _introController,
                    start: 0.86,
                    end: 1.0,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 430;
                        final replayButton = GameButton(
                          label: 'Replay',
                          outlined: true,
                          expanded: true,
                          onTap: () => Navigator.of(context).pop('replay'),
                        );
                        final challengeButton = GameButton(
                          label: 'Challenge Friend',
                          outlined: true,
                          expanded: true,
                          onTap: _sendChallengeToFriend,
                        );
                        if (compact) {
                          return Column(
                            children: [
                              replayButton,
                              const SizedBox(height: 10),
                              challengeButton,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: replayButton),
                            const SizedBox(width: 10),
                            Expanded(child: challengeButton),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggerIn extends StatelessWidget {
  const _StaggerIn({
    required this.parent,
    required this.start,
    required this.end,
    required this.child,
  });

  final AnimationController parent;
  final double start;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final safeStart = start.clamp(0.0, 1.0);
    final safeEnd = end.clamp(safeStart + 0.001, 1.0);
    final curve = CurvedAnimation(
      parent: parent,
      curve: Interval(safeStart, safeEnd, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}
