import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'l10n/l10n.dart';
import 'models/friend_profile.dart';
import 'models/leaderboard_entry.dart';
import 'services/friends_service.dart';
import 'services/leaderboard_service.dart';
import 'services/live_duel_service.dart';
import 'services/user_profile_service.dart';
import 'ui/avatar_utils.dart';
import 'ui/components/game_button.dart';
import 'ui/components/game_card.dart';
import 'ui/components/game_toast.dart';
import 'ui/components/network_image_compat.dart';
import 'ui/components/presence_dot.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  static const String _firestoreDatabaseId = 'tracepath-database';

  final FriendsService _friendsService = FriendsService();
  final LiveDuelService _liveDuelService = LiveDuelService();
  final SocialLeaderboardService _leaderboardService =
      SocialLeaderboardService();
  final UserProfileService _profileService = UserProfileService();
  final TextEditingController _friendIdCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();

  final Map<String, Map<String, dynamic>> _leaderboardUserCache =
      <String, Map<String, dynamic>>{};
  final Map<String, Future<Map<String, dynamic>>> _leaderboardUserInflight =
      <String, Future<Map<String, dynamic>>>{};
  final Map<String, String?> _skinPreviewUrlCache = <String, String?>{};
  final Map<String, Future<String?>> _skinPreviewInflight =
      <String, Future<String?>>{};
  final Map<String, Future<_LeaderboardPresentationData>>
      _presentationInflight = <String, Future<_LeaderboardPresentationData>>{};

  late Future<List<FriendProfile>> _friendsFuture;
  late Future<List<LeaderboardEntry>> _leaderboardFuture;
  bool _friendsExpanded = false;

  @override
  void initState() {
    super.initState();
    _friendsFuture = _friendsService.getFriends();
    _leaderboardFuture = _leaderboardService.getGlobalTopScores(limit: 10);
  }

  @override
  void dispose() {
    _friendIdCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(l10n.socialTitle),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(),
            const SizedBox(height: 16),
            _buildFriendActions(),
            const SizedBox(height: 16),
            _buildFriends(),
            const SizedBox(height: 16),
            _buildRanking(),
            const SizedBox(height: 16),
            _buildCtas(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final l10n = context.l10n;
    return StreamBuilder<List<FriendProfile>>(
      stream: _friendsService.watchFriends(),
      builder: (context, friendSnapshot) {
        final friendCount = friendSnapshot.data?.length ?? 0;
        return StreamBuilder<List<LeaderboardEntry>>(
          stream: _leaderboardService.watchGlobalTopScores(limit: 10),
          builder: (context, rankSnapshot) {
            final entries = rankSnapshot.data ?? const <LeaderboardEntry>[];
            return StreamBuilder<Map<String, dynamic>?>(
              stream: _leaderboardService.watchCurrentGlobalProfile(),
              builder: (context, myProfileSnapshot) {
                return StreamBuilder<int?>(
                  stream: _leaderboardService.watchCurrentGlobalRank(),
                  builder: (context, myRankSnapshot) {
                    final myProfile = myProfileSnapshot.data;
                    final myBestTimeMs =
                        LeaderboardEntry.readInt(myProfile?['bestTimeMs']);
                    final myBestTime = myBestTimeMs > 0
                        ? _formatMs(myBestTimeMs)
                        : (entries.isEmpty
                            ? '--:--'
                            : _formatMs(entries.first.bestTimeMs));
                    final myRank = myRankSnapshot.data;
                    final globalTier = (myProfile?['globalTier'] as String?)
                                ?.trim()
                                .isNotEmpty ==
                            true
                        ? (myProfile?['globalTier'] as String).trim()
                        : '--';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1A2950),
                            Color(0xFF15264A),
                            Color(0xFF141E39)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                            color: const Color(0xFF365588), width: 1.1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x331A5CF6),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.socialHubTitle,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.socialHubSubtitle,
                            style: TextStyle(
                              color: Color(0xFFAEC2E8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _HeroChip(
                                  icon: Icons.groups_rounded,
                                  label: l10n.socialFriendsLabel,
                                  value: '$friendCount',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _HeroChip(
                                  icon: Icons.workspace_premium_rounded,
                                  label: l10n.socialBestRankLabel,
                                  value: myRank != null ? '#$myRank' : '--',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _HeroChip(
                                  icon: Icons.bolt_rounded,
                                  label: l10n.socialTopTimeLabel,
                                  value: myBestTime,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _HeroChip(
                            icon: Icons.auto_awesome_rounded,
                            label: l10n.socialGlobalTierLabel,
                            value: globalTier,
                          ),
                        ],
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

  Widget _buildFriendActions() {
    final l10n = context.l10n;
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: l10n.socialFriendActionsTitle,
            subtitle: l10n.socialFriendActionsSubtitle,
          ),
          const SizedBox(height: 10),
          _InputActionRow(
            controller: _usernameCtrl,
            hint: l10n.socialSetUsernameHint,
            buttonLabel: l10n.socialSave,
            icon: Icons.badge_rounded,
            onTap: _setUsername,
          ),
          const SizedBox(height: 10),
          _InputActionRow(
            controller: _friendIdCtrl,
            hint: l10n.socialFriendLookupHint,
            buttonLabel: l10n.socialAdd,
            icon: Icons.person_add_alt_1_rounded,
            onTap: _addFriend,
          ),
        ],
      ),
    );
  }

  Widget _buildFriends() {
    final l10n = context.l10n;
    return StreamBuilder<List<FriendProfile>>(
      stream: _friendsService.watchFriends(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: l10n.socialFriendsSectionTitle,
              subtitle: l10n.socialFriendsSectionSubtitle,
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1B2740),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2E466B), width: 1),
              ),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _friendsExpanded = !_friendsExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.groups_rounded,
                              color: Color(0xFF9EC5FF),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                count == null
                                    ? l10n.socialFriendsSectionTitle
                                    : l10n.socialFriendsWithCount(count),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              duration: const Duration(milliseconds: 180),
                              turns: _friendsExpanded ? 0.5 : 0.0,
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF9EB0D2),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: _friendsExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: _buildFriendsListContent(snapshot.data),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFriendsListContent(List<FriendProfile>? friends) {
    final l10n = context.l10n;
    if (friends == null) {
      return FutureBuilder<List<FriendProfile>>(
        future: _friendsFuture,
        builder: (context, fs) {
          final items = fs.data ?? const <FriendProfile>[];
          if (items.isEmpty) {
            return _EmptyHint(
              icon: Icons.people_outline_rounded,
              title: l10n.socialNoFriendsTitle,
              text: l10n.socialNoFriendsSubtitle,
            );
          }
          return Column(
            children: items
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FriendCard(
                      friend: f,
                      onRemove: () => _removeFriend(f.uid),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        },
      );
    }
    if (friends.isEmpty) {
      return _EmptyHint(
        icon: Icons.people_outline_rounded,
        title: l10n.socialNoFriendsTitle,
        text: l10n.socialNoFriendsSubtitle,
      );
    }
    return Column(
      children: friends
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FriendCard(
                friend: f,
                onRemove: () => _removeFriend(f.uid),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildRanking() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: l10n.socialGlobalTop10Title,
          subtitle: l10n.socialGlobalTop10Subtitle,
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<LeaderboardEntry>>(
          stream: _leaderboardService.watchGlobalTopScores(limit: 10),
          builder: (context, snapshot) {
            final entries = snapshot.data;
            if (entries == null) {
              return FutureBuilder<List<LeaderboardEntry>>(
                future: _leaderboardFuture,
                builder: (context, fs) {
                  final items = fs.data ?? const <LeaderboardEntry>[];
                  if (items.isEmpty) {
                    return _EmptyHint(
                      icon: Icons.bar_chart_rounded,
                      title: l10n.socialNoGlobalScoresTitle,
                      text: l10n.socialNoGlobalScoresSubtitle,
                    );
                  }
                  return _buildLeaderboardCard(items);
                },
              );
            }
            if (entries.isEmpty) {
              return _EmptyHint(
                icon: Icons.bar_chart_rounded,
                title: l10n.socialNoGlobalScoresTitle,
                text: l10n.socialNoGlobalScoresSubtitle,
              );
            }
            return _buildLeaderboardCard(entries);
          },
        ),
      ],
    );
  }

  Widget _buildLeaderboardCard(List<LeaderboardEntry> entries) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ranks = _computeRanksByTime(
      entries.map((e) => e.bestTimeMs).toList(growable: false),
    );
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C283E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF314563), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A4D82FF),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              _RankRow(
                rank: ranks[i],
                presentationFuture: _presentationForEntry(entries[i]),
                bestTimeMs: entries[i].bestTimeMs,
                moves: entries[i].moves,
                stars: entries[i].stars,
                isCurrentUser: entries[i].uid == uid,
              ),
              if (i < entries.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xFF2B3A56), height: 1),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCtas() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: l10n.socialChallengesTitle,
          subtitle: l10n.socialChallengesSubtitle,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0x1F4A86FF), Color(0x0824477E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFF365588), width: 1),
          ),
          child: Column(
            children: [
              GameButton(
                label: l10n.socialChallengeFriend,
                icon: Icons.sports_esports_rounded,
                expanded: true,
                prominent: true,
                onTap: _challengeFriendInGame,
              ),
              const SizedBox(height: 10),
              GameButton(
                label: l10n.socialInviteFriend,
                icon: Icons.share_rounded,
                expanded: true,
                outlined: true,
                onTap: _inviteFriend,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addFriend() async {
    final l10n = context.l10n;
    final value = _friendIdCtrl.text.trim();
    if (value.isEmpty) return;
    try {
      if (value.contains('@')) {
        await _friendsService.sendFriendRequestByEmail(value);
      } else {
        await _friendsService.sendFriendRequestByUsername(value);
      }
      _friendIdCtrl.clear();
      if (!mounted) return;
      unawaited(
          GameToast.show(
            context,
            type: GameToastType.social,
            title: l10n.socialFriendRequestTitle,
            message: l10n.socialFriendRequestSent,
          duration: const Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[social] addFriend primary error=$e');
      }
      final primary = e.toString().toUpperCase();
      final shouldTryUid = !value.contains('@') &&
          (primary.contains('FRIEND_USERNAME_NOT_FOUND') ||
              primary.contains('FRIEND_NOT_FOUND'));

      if (shouldTryUid) {
        if (!mounted) return;
        try {
          await _friendsService.sendFriendRequestByUid(value);
          _friendIdCtrl.clear();
          if (!mounted) return;
          unawaited(
              GameToast.show(
                context,
                type: GameToastType.social,
                title: l10n.socialFriendRequestTitle,
                message: l10n.socialFriendRequestSent,
              duration: const Duration(milliseconds: 1500),
            ),
          );
          return;
        } catch (e2) {
          if (!mounted) return;
          final combined = '${e.toString()} ${e2.toString()}'.toUpperCase();
          var message = l10n.socialCouldNotSendRequest;
          if (combined.contains('SELF_ADD') ||
              combined.contains('INVALID_FRIEND_UID')) {
            message = l10n.socialCannotAddSelf;
          } else if (combined.contains('FRIEND_EMAIL_INVALID')) {
            message = l10n.socialInvalidEmail;
          } else if (combined.contains('FRIEND_USERNAME_NOT_FOUND') ||
              combined.contains('FRIEND_EMAIL_NOT_FOUND') ||
              combined.contains('FRIEND_NOT_FOUND')) {
            message = l10n.socialUserNotFound;
          } else if (combined.contains('ALREADY_FRIENDS')) {
            message = l10n.socialAlreadyFriends;
          } else if (combined.contains('REQUEST_ALREADY_SENT')) {
            message = l10n.socialRequestAlreadySent;
          } else if (combined.contains('REQUEST_ALREADY_RECEIVED')) {
            message = l10n.socialRequestAlreadyReceived;
          } else if (combined.contains('AUTH_REQUIRED')) {
            message = l10n.socialNeedSignIn;
          } else if ((e is FirebaseException &&
                  e.code == 'permission-denied') ||
              (e2 is FirebaseException && e2.code == 'permission-denied')) {
            message = l10n.socialRulesBlockedAction;
          }
          unawaited(
            GameToast.show(
              context,
              type: GameToastType.info,
              title: l10n.socialTitle,
              message: message,
              duration: const Duration(milliseconds: 1700),
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      var message = l10n.socialCouldNotSendRequest;
      if (primary.contains('SELF_ADD') ||
          primary.contains('INVALID_FRIEND_UID')) {
        message = l10n.socialCannotAddSelf;
      } else if (primary.contains('FRIEND_EMAIL_INVALID')) {
        message = l10n.socialInvalidEmail;
      } else if (primary.contains('ALREADY_FRIENDS')) {
        message = l10n.socialAlreadyFriends;
      } else if (primary.contains('REQUEST_ALREADY_SENT')) {
        message = l10n.socialRequestAlreadySent;
      } else if (primary.contains('REQUEST_ALREADY_RECEIVED')) {
        message = l10n.socialRequestAlreadyReceived;
      } else if (primary.contains('AUTH_REQUIRED')) {
        message = l10n.socialNeedSignIn;
      } else if (e is FirebaseException && e.code == 'permission-denied') {
        message = l10n.socialRulesBlockedAction;
      } else if (primary.contains('FRIEND_USERNAME_NOT_FOUND') ||
          primary.contains('FRIEND_EMAIL_NOT_FOUND') ||
          primary.contains('FRIEND_NOT_FOUND')) {
        message = l10n.socialUserNotFound;
      }
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.info,
          title: l10n.socialTitle,
          message: message,
          duration: const Duration(milliseconds: 1700),
        ),
      );
    }
  }

  Future<void> _challengeFriendInGame() async {
    final l10n = context.l10n;
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
      unawaited(
        GameToast.show(
          context,
          type: GameToastType.social,
          title: l10n.socialChallengesTitle,
          message: l10n.socialAddFriendsFirstForChallenges,
          duration: const Duration(milliseconds: 1500),
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
                Text(
                  l10n.socialChallengeFriendSheetTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.socialChallengeFriendSheetSubtitle,
                  style: TextStyle(color: Color(0xFF9EB0D2), fontSize: 12),
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
                                            ? l10n.socialLiveInviteOnline
                                            : l10n.socialLiveInviteOffline,
                                        style: TextStyle(
                                          color: const Color(0xFF9EB0D2),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
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
        debugPrint('Challenge button pressed from [social]');
      }
      final created = await _liveDuelService.createRandomInvite(
        toUid: friend.uid,
      );
      if (!mounted) return;
      unawaited(
          GameToast.show(
            context,
            type: GameToastType.social,
            title: l10n.socialLiveInviteSentTitle,
            message: l10n.socialLiveInviteSentBody(friend.displayName),
          duration: const Duration(milliseconds: 1700),
        ),
      );
      context.go('/live-duel/${created.matchId}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[social] send live duel invite failed toUid=${friend.uid} error=$e');
      }
      if (!mounted) return;
      var message = l10n.socialCouldNotSendChallenge;
      if (e is FirebaseException && e.code == 'permission-denied') {
        message = l10n.socialChallengeBlockedByRules;
      } else if (e is FirebaseException && e.code == 'failed-precondition') {
        message = l10n.socialChallengeSetupNotReady;
      } else if (e.toString().contains('ALREADY_IN_ACTIVE_DUEL')) {
        message = l10n.socialFinishCurrentLiveDuelFirst;
      } else if (e.toString().contains('TARGET_IN_ACTIVE_DUEL')) {
        message = l10n.socialFriendAlreadyInLiveDuel(friend.displayName);
      } else if (e.toString().contains('NO_PUZZLES_AVAILABLE')) {
        message = l10n.socialNoPuzzlesForLiveDuel;
      }
      unawaited(
          GameToast.show(
            context,
            type: GameToastType.info,
            title: l10n.socialChallengesTitle,
            message: message,
          duration: const Duration(milliseconds: 1600),
        ),
      );
    }
  }

  Future<void> _removeFriend(String uid) async {
    final l10n = context.l10n;
    final shouldRemove = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF111827),
            title: Text(
              l10n.socialRemoveFriendTitle,
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              l10n.socialRemoveFriendBody,
              style: TextStyle(color: Color(0xFFB6C2DA)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.profileCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.socialRemove),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldRemove) return;
    await _friendsService.removeFriend(uid);
    if (!mounted) return;
    setState(() {
      _friendsFuture = _friendsService.getFriends();
    });
  }

  Future<void> _setUsername() async {
    final l10n = context.l10n;
    final value = _usernameCtrl.text.trim();
    if (value.isEmpty) return;
    try {
      final available = await _profileService.isUsernameAvailable(value);
      if (!available) {
        if (!mounted) return;
        unawaited(
          GameToast.show(
            context,
            type: GameToastType.info,
            title: l10n.socialUsernameTitle,
            message: l10n.socialUsernameNotAvailable,
            duration: const Duration(milliseconds: 1600),
          ),
        );
        return;
      }
      await _profileService.setUsername(value);
      _usernameCtrl.clear();
      if (!mounted) return;
      unawaited(
          GameToast.show(
            context,
            type: GameToastType.social,
            title: l10n.tabProfile,
            message: l10n.socialUsernameUpdated,
          duration: const Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      String message;
      if (e.toString().contains('USERNAME_TAKEN')) {
        message = l10n.socialUsernameAlreadyUsed;
      } else if (e.toString().contains('INVALID_USERNAME')) {
        message = l10n.socialUsernameInvalid;
      } else if (e.toString().contains('AUTH_REQUIRED')) {
        message = l10n.socialNeedSignIn;
      } else if (e is FirebaseException && e.code == 'permission-denied') {
        message = l10n.socialRulesBlockedUsernameWrite;
      } else {
        message = l10n.socialCouldNotSaveUsername;
      }
      if (!mounted) return;
      unawaited(
          GameToast.show(
            context,
            type: GameToastType.info,
            title: l10n.tabProfile,
            message: message,
          duration: const Duration(milliseconds: 1700),
        ),
      );
    }
  }

  Future<void> _inviteFriend() async {
    final l10n = context.l10n;
    const inviteText =
        "Join me on TracePath! Let's compete on the leaderboard. "
        'https://tracepath.app/invite';
    await Clipboard.setData(const ClipboardData(text: inviteText));
    if (!mounted) return;
    unawaited(
      GameToast.show(
        context,
        type: GameToastType.social,
        title: l10n.socialInviteReadyTitle,
        message: l10n.socialInviteReadyBody,
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  Future<_LeaderboardPresentationData> _presentationForEntry(
    LeaderboardEntry entry,
  ) {
    final key = '${entry.uid}|${entry.updatedAt?.millisecondsSinceEpoch ?? 0}';
    final inflight = _presentationInflight[key];
    if (inflight != null) return inflight;

    final future = _buildPresentation(entry);
    _presentationInflight[key] = future;
    return future.whenComplete(() {
      _presentationInflight.remove(key);
    });
  }

  Future<_LeaderboardPresentationData> _buildPresentation(
    LeaderboardEntry entry,
  ) async {
    final l10n = context.l10n;
    final profile = await _getLeaderboardUserProfile(entry.uid);
    final username = entry.username.trim().isNotEmpty
        ? entry.username.trim()
        : ((profile['username'] as String?)?.trim() ?? '');
    final playerName = entry.playerName.trim().isNotEmpty
        ? entry.playerName.trim()
        : ((profile['playerName'] as String?)?.trim() ?? '');
    final profilePhotoUrl = _firstNonEmptyString(<Object?>[
      profile['photoUrl'],
      profile['photoURL'],
      profile['avatarUrl'],
      profile['avatarURL'],
    ]);
    final authPhotoUrl = entry.uid == FirebaseAuth.instance.currentUser?.uid
        ? (FirebaseAuth.instance.currentUser?.photoURL ?? '').trim()
        : '';
    final photoUrl = _pickAvatarUrl(<String>[
      entry.photoUrl,
      profilePhotoUrl,
      authPhotoUrl,
    ]);
    final equippedSkinId = entry.equippedSkinId.trim().isNotEmpty
        ? entry.equippedSkinId.trim()
        : _firstNonEmptyString(<Object?>[
            profile['equippedSkinId'],
            profile['equippedSkin'],
          ]);
    final preferSkinAvatar = !isDefaultSkinId(equippedSkinId);

    late final String displayName;
    late final String nameSource;
    if (username.isNotEmpty) {
      displayName = username;
      nameSource = 'username';
    } else if (playerName.isNotEmpty) {
      displayName = playerName;
      nameSource = 'playerName';
    } else {
      displayName = l10n.socialPlayerFallback;
      nameSource = 'fallback';
    }

    String? secondaryText;
    if (username.isNotEmpty &&
        playerName.isNotEmpty &&
        username != playerName) {
      secondaryText = playerName;
    } else if (entry.moves > 0 || entry.stars > 0) {
      final parts = <String>[
        if (entry.moves > 0) l10n.socialMovesShort(entry.moves),
        if (entry.stars > 0) l10n.socialStarsShort(entry.stars),
      ];
      secondaryText = parts.isEmpty ? null : parts.join(' - ');
    }

    final skinPreviewUrl = await _getSkinPreviewUrl(equippedSkinId);

    if (kDebugMode) {
      debugPrint(
        '[social-rank] ${entry.uid} displayName=$displayName source=$nameSource',
      );
      debugPrint(
        '[social-rank] ${entry.uid} avatar source='
        '${preferSkinAvatar ? (skinPreviewUrl?.isNotEmpty == true ? 'equippedSkin' : (photoUrl.isNotEmpty ? 'photoUrl' : 'default')) : (photoUrl.isNotEmpty ? 'photoUrl' : (skinPreviewUrl?.isNotEmpty == true ? 'equippedSkin' : 'default'))}',
      );
    }

    return _LeaderboardPresentationData(
      displayName: displayName,
      secondaryText: secondaryText,
      photoUrl: photoUrl,
      skinPreviewUrl: skinPreviewUrl ?? '',
      preferSkin: preferSkinAvatar,
    );
  }

  Future<Map<String, dynamic>> _getLeaderboardUserProfile(String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return Future.value(const <String, dynamic>{});
    final cached = _leaderboardUserCache[normalizedUid];
    if (cached != null) return Future.value(cached);
    final inflight = _leaderboardUserInflight[normalizedUid];
    if (inflight != null) return inflight;

    final future = () async {
      try {
        final snap = await _db().collection('users').doc(normalizedUid).get();
        final data = snap.data() ?? <String, dynamic>{};
        _leaderboardUserCache[normalizedUid] = data;
        return data;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[social-rank] failed loading users/$normalizedUid: $e');
        }
        return const <String, dynamic>{};
      }
    }();

    _leaderboardUserInflight[normalizedUid] = future;
    return future.whenComplete(() {
      _leaderboardUserInflight.remove(normalizedUid);
    });
  }

  String _pickAvatarUrl(List<String> candidates) {
    for (final raw in candidates) {
      final normalized = _normalizeAvatarPath(raw);
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
    if (value.startsWith('gs://')) {
      final withoutPrefix = value.replaceFirst('gs://', '');
      final slash = withoutPrefix.indexOf('/');
      if (slash <= 0 || slash >= withoutPrefix.length - 1) return '';
      final bucket = withoutPrefix.substring(0, slash);
      final objectPath = withoutPrefix.substring(slash + 1);
      return 'https://firebasestorage.googleapis.com/v0/b/'
          '$bucket/o/${Uri.encodeComponent(objectPath)}?alt=media';
    }
    return '';
  }

  Future<String?> _getSkinPreviewUrl(String skinId) {
    final normalizedSkinId = skinId.trim();
    if (normalizedSkinId.isEmpty ||
        normalizedSkinId == 'default' ||
        normalizedSkinId == 'pointer_default') {
      return Future.value(null);
    }

    if (_skinPreviewUrlCache.containsKey(normalizedSkinId)) {
      return Future.value(_skinPreviewUrlCache[normalizedSkinId]);
    }
    final inflight = _skinPreviewInflight[normalizedSkinId];
    if (inflight != null) return inflight;

    final future = () async {
      try {
        final idCandidates = <String>{
          normalizedSkinId,
          normalizedSkinId.replaceAll('_', '-'),
          normalizedSkinId.replaceAll('-', '_'),
        };
        Map<String, dynamic> data = const <String, dynamic>{};
        for (final candidate in idCandidates) {
          final snap =
              await _db().collection('skins_catalog').doc(candidate).get();
          final candidateData = snap.data() ?? const <String, dynamic>{};
          if (snap.exists && candidateData.isNotEmpty) {
            data = candidateData;
            break;
          }
        }
        if (data.isEmpty) {
          for (final candidate in idCandidates) {
            final q = await _db()
                .collection('skins_catalog')
                .where('id', isEqualTo: candidate)
                .limit(1)
                .get();
            if (q.docs.isNotEmpty) {
              data = q.docs.first.data();
              break;
            }
          }
        }
        final imageRaw = data['image'];
        Map<String, dynamic>? imageMap;
        if (imageRaw is Map<String, dynamic>) {
          imageMap = imageRaw;
        } else if (imageRaw is Map) {
          imageMap = Map<String, dynamic>.from(imageRaw);
        }
        final rawPath = _readString(imageMap?['previewPath']) ??
            _readString(data['thumbPath']) ??
            _readString(data['thumbnailPath']) ??
            _readString(imageMap?['iconPath']) ??
            _readString(imageMap?['fullPath']) ??
            _readString(data['imagePath']);
        final resolved = await _resolveToDownloadUrl(rawPath);
        _skinPreviewUrlCache[normalizedSkinId] = resolved;
        return resolved;
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            '[social-rank] failed loading skin preview for $normalizedSkinId: $e',
          );
        }
        _skinPreviewUrlCache[normalizedSkinId] = null;
        return null;
      }
    }();

    _skinPreviewInflight[normalizedSkinId] = future;
    return future.whenComplete(() {
      _skinPreviewInflight.remove(normalizedSkinId);
    });
  }

  FirebaseFirestore _db() {
    try {
      return FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: _firestoreDatabaseId,
      );
    } catch (_) {
      return FirebaseFirestore.instance;
    }
  }

  List<int> _computeRanksByTime(List<int> bestTimesMs) {
    final ranks = List<int>.filled(bestTimesMs.length, 0);
    var currentRank = 0;
    var lastTime = -1;
    for (var i = 0; i < bestTimesMs.length; i++) {
      final t = bestTimesMs[i];
      if (i == 0 || t != lastTime) {
        currentRank = i + 1;
        lastTime = t;
      }
      ranks[i] = currentRank;
    }
    return ranks;
  }

  String? _readString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  String _firstNonEmptyString(List<Object?> values) {
    for (final value in values) {
      if (value is String) {
        final t = value.trim();
        if (t.isNotEmpty) return t;
      }
    }
    return '';
  }

  Future<String?> _resolveToDownloadUrl(String? rawPath) async {
    final raw = (rawPath ?? '').trim();
    if (raw.isEmpty) return null;
    if (raw.startsWith('http://') ||
        raw.startsWith('https://') ||
        raw.startsWith('assets/') ||
        raw.startsWith('data:image')) {
      return raw;
    }
    if (raw.startsWith('gs://')) {
      try {
        return await FirebaseStorage.instance.refFromURL(raw).getDownloadURL();
      } catch (_) {
        return null;
      }
    }
    final objectPath = raw.replaceAll('\\', '/');
    if (!objectPath.contains('/')) return null;
    try {
      return await FirebaseStorage.instance.ref(objectPath).getDownloadURL();
    } catch (_) {
      final bucket = Firebase.app().options.storageBucket?.trim() ?? '';
      if (bucket.isEmpty) return null;
      return 'https://firebasestorage.googleapis.com/v0/b/'
          '$bucket/o/${Uri.encodeComponent(objectPath)}?alt=media';
    }
  }

  String _formatMs(int ms) {
    if (ms <= 0) return '--:--';
    final seconds = (ms / 1000).round();
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }
}

class SocialGuestLockedScreen extends StatelessWidget {
  const SocialGuestLockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(l10n.socialTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: GameCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: Color(0xFF8AA8FF),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.socialGuestLockedTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.socialGuestLockedSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF9EB0D2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                GameButton(
                  label: l10n.socialGoHome,
                  icon: Icons.home_rounded,
                  onTap: () => context.go('/home'),
                  expanded: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1A9BC2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x334A77C0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9AC2FF)),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFAEC2E8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
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

class _InputActionRow extends StatelessWidget {
  const _InputActionRow({
    required this.controller,
    required this.hint,
    required this.buttonLabel,
    required this.icon,
    required this.onTap,
  });

  final TextEditingController controller;
  final String hint;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF18243A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D4267), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF7F8FAF), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF7F8FAF)),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GameButton(
            label: buttonLabel,
            icon: icon,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.onRemove,
  });

  final FriendProfile friend;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GameCard(
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF1B2A43),
                    child: Text(
                      friend.playerName.isNotEmpty
                          ? friend.playerName.substring(0, 1).toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: PresenceDot(isOnline: friend.isOnline, size: 11),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.socialSkinTrail(
                        friend.equippedSkinId,
                        friend.equippedTrailId,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF96A7C7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      friend.isOnline
                          ? l10n.socialOnline
                          : l10n.socialOffline,
                      style: TextStyle(
                        color: friend.isOnline
                            ? const Color(0xFF6EE7A0)
                            : const Color(0xFFFCA5A5),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: l10n.socialRemoveFriendTitle,
                icon: const Icon(
                  Icons.person_remove_alt_1_rounded,
                  color: Color(0xFF9AB6E0),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TinyInfoChip(
                icon: Icons.flag_rounded,
                label: l10n.socialStatusLabel,
                value: friend.isOnline
                    ? l10n.socialOnline
                    : l10n.socialOffline,
              ),
              _TinyInfoChip(
                icon: Icons.auto_awesome_rounded,
                label: l10n.socialSkinLabel,
                value: friend.equippedSkinId,
              ),
              _TinyInfoChip(
                icon: Icons.timeline_rounded,
                label: l10n.socialTrailLabel,
                value: friend.equippedTrailId,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyInfoChip extends StatelessWidget {
  const _TinyInfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2740),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF304563), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF98B6E8)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Color(0xFF9DB0D4),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.presentationFuture,
    required this.bestTimeMs,
    required this.moves,
    required this.stars,
    required this.isCurrentUser,
  });

  final int rank;
  final Future<_LeaderboardPresentationData> presentationFuture;
  final int bestTimeMs;
  final int moves;
  final int stars;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final medal = _medalForIndex(rank);
    return FutureBuilder<_LeaderboardPresentationData>(
      future: presentationFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ??
            const _LeaderboardPresentationData(
              displayName: '',
              secondaryText: null,
              photoUrl: '',
              skinPreviewUrl: '',
              preferSkin: false,
            );
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isCurrentUser
                ? const Color(0x252D7BFF)
                : const Color(0x14000000),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrentUser
                  ? const Color(0xFF3D74DA)
                  : const Color(0xFF2B3A56),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: medal.gradient,
                  border: Border.all(color: medal.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: medal.text,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _LeaderboardAvatar(data: data),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (data.secondaryText ?? '').isNotEmpty
                          ? data.secondaryText!
                          : l10n.socialReadyToCompete,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A8CE),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatMs(bestTimeMs),
                    style: TextStyle(
                      color: medal.timeColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (moves > 0) l10n.socialMovesShort(moves),
                      if (stars > 0) l10n.socialStarsShort(stars),
                    ].join(' - '),
                    style: const TextStyle(
                      color: Color(0xFF8FA6CF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatMs(int ms) {
    if (ms <= 0) return '--:--';
    final seconds = (ms / 1000).round();
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  _MedalStyle _medalForIndex(int index) {
    if (index == 1) {
      return const _MedalStyle(
        gradient:
            LinearGradient(colors: [Color(0xFFFFD978), Color(0xFFE7A819)]),
        border: Color(0xFFFFE3A0),
        text: Color(0xFF4F3200),
        timeColor: Color(0xFFFFD56B),
      );
    }
    if (index == 2) {
      return const _MedalStyle(
        gradient:
            LinearGradient(colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8)]),
        border: Color(0xFFE6EEFF),
        text: Color(0xFF1E293B),
        timeColor: Color(0xFFBED2FF),
      );
    }
    if (index == 3) {
      return const _MedalStyle(
        gradient:
            LinearGradient(colors: [Color(0xFFF4B183), Color(0xFFA66332)]),
        border: Color(0xFFF9C8A4),
        text: Color(0xFF3D1F08),
        timeColor: Color(0xFFD9B08C),
      );
    }
    return const _MedalStyle(
      gradient: LinearGradient(colors: [Color(0xFF34445F), Color(0xFF263349)]),
      border: Color(0xFF4D5F7A),
      text: Color(0xFFCBD5E1),
      timeColor: Color(0xFF9DB0D7),
    );
  }
}

class _MedalStyle {
  const _MedalStyle({
    required this.gradient,
    required this.border,
    required this.text,
    required this.timeColor,
  });

  final Gradient gradient;
  final Color border;
  final Color text;
  final Color timeColor;
}

class _LeaderboardAvatar extends StatefulWidget {
  const _LeaderboardAvatar({required this.data});

  final _LeaderboardPresentationData data;

  @override
  State<_LeaderboardAvatar> createState() => _LeaderboardAvatarState();
}

class _LeaderboardAvatarState extends State<_LeaderboardAvatar> {
  int _index = 0;

  List<_AvatarSource> get _sources {
    final paths = orderedAvatarCandidates(
      photoUrl: widget.data.photoUrl,
      skinUrl: widget.data.skinPreviewUrl,
      preferSkin: widget.data.preferSkin,
    );
    return paths
        .map(
          (p) => _AvatarSource(
            type: p == widget.data.skinPreviewUrl.trim() ? 'skin' : 'photo',
            path: p,
          ),
        )
        .toList(growable: false);
  }

  @override
  void didUpdateWidget(covariant _LeaderboardAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.photoUrl != widget.data.photoUrl ||
        oldWidget.data.skinPreviewUrl != widget.data.skinPreviewUrl) {
      _index = 0;
    }
  }

  void _onFailed(String type) {
    final sources = _sources;
    if (_index < sources.length - 1) {
      if (kDebugMode) {
        debugPrint('[social-rank] avatar $type failed -> fallback');
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _index += 1;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = _sources;
    Widget child = const _LeaderboardAvatarPlaceholder();
    if (_index < sources.length) {
      final source = sources[_index];
      child = _RankAvatarImageCandidate(
        source: source,
        onFailed: () => _onFailed(source.type),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF415A82), width: 1.1),
        color: const Color(0xFF182234),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _RankAvatarImageCandidate extends StatelessWidget {
  const _RankAvatarImageCandidate({
    required this.source,
    required this.onFailed,
  });

  final _AvatarSource source;
  final VoidCallback onFailed;

  @override
  Widget build(BuildContext context) {
    final url = source.path.trim();
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _RankAvatarFailureSignal(onFailed: onFailed),
      );
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      if (_isGoogleAvatarUrl(url)) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) =>
              _RankAvatarFailureSignal(onFailed: onFailed),
        );
      }
      return buildNetworkImageCompat(
        url: url,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        fallback: _RankAvatarFailureSignal(onFailed: onFailed),
      );
    }
    return _RankAvatarFailureSignal(onFailed: onFailed);
  }

  bool _isGoogleAvatarUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host.contains('googleusercontent.com') ||
        host.contains('gstatic.com') ||
        host.contains('googleapis.com');
  }
}

class _RankAvatarFailureSignal extends StatefulWidget {
  const _RankAvatarFailureSignal({required this.onFailed});

  final VoidCallback onFailed;

  @override
  State<_RankAvatarFailureSignal> createState() =>
      _RankAvatarFailureSignalState();
}

class _RankAvatarFailureSignalState extends State<_RankAvatarFailureSignal> {
  bool _fired = false;

  @override
  Widget build(BuildContext context) {
    if (!_fired) {
      _fired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onFailed();
      });
    }
    return const _LeaderboardAvatarPlaceholder();
  }
}

class _AvatarSource {
  const _AvatarSource({required this.type, required this.path});

  final String type;
  final String path;
}

class _LeaderboardAvatarPlaceholder extends StatelessWidget {
  const _LeaderboardAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF182234),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: Color(0xFF9EB0D2),
          size: 20,
        ),
      ),
    );
  }
}

class _LeaderboardPresentationData {
  const _LeaderboardPresentationData({
    required this.displayName,
    required this.secondaryText,
    required this.photoUrl,
    required this.skinPreviewUrl,
    required this.preferSkin,
  });

  final String displayName;
  final String? secondaryText;
  final String photoUrl;
  final String skinPreviewUrl;
  final bool preferSkin;
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A2740),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF344A73), width: 1),
              ),
              child: Icon(icon, color: const Color(0xFF9EB0D2)),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9EB0D2),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
