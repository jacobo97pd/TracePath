import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/friend_profile.dart';
import 'models/inbox_item.dart';
import 'models/live_match.dart';
import 'services/friends_service.dart';
import 'services/inbox_service.dart';
import 'services/live_duel_service.dart';
import 'theme/app_colors.dart';
import 'l10n/l10n.dart';
import 'ui/components/game_card.dart';
import 'ui/components/presence_dot.dart';
import 'ui/components/primary_cta_button.dart';

class DuelScreen extends StatefulWidget {
  const DuelScreen({super.key});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  final LiveDuelService _liveDuelService = LiveDuelService();
  final InboxService _inboxService = InboxService();
  final FriendsService _friendsService = FriendsService();

  bool _creatingInvite = false;
  final Set<String> _processingInviteIds = <String>{};
  final Set<String> _processingActiveMatchIds = <String>{};

  String get _uid => FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryDark, AppColors.background],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _DuelHeader(),
                const SizedBox(height: 14),
                _DuelPrimaryCta(
                  busy: _creatingInvite,
                  onTap: _creatingInvite ? null : _challengeFriend,
                ),
                const SizedBox(height: 18),
                _DuelSectionTitle(
                  title: context.l10n.duelIncomingInvitesTitle,
                  subtitle: context.l10n.duelIncomingInvitesSubtitle,
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<InboxItem>>(
                  stream: _inboxService.watchInbox(),
                  builder: (context, snapshot) {
                    final items = (snapshot.data ?? const <InboxItem>[])
                        .where(
                          (e) =>
                              e.type == InboxItemType.liveDuelInvite &&
                              e.status.trim().toLowerCase() == 'pending' &&
                              e.ctaPayload.trim().isNotEmpty,
                        )
                        .toList(growable: false);
                    if (snapshot.hasError) {
                      return _InlineInfoCard(
                        icon: Icons.wifi_tethering_error_rounded,
                        title: context.l10n.duelInviteLoadErrorTitle,
                        subtitle: context.l10n.duelTryAgainLater,
                      );
                    }
                    if (items.isEmpty) {
                      return _InlineInfoCard(
                        icon: Icons.inbox_outlined,
                        title: context.l10n.duelNoPendingInvitesTitle,
                        subtitle: context.l10n.duelNoPendingInvitesSubtitle,
                      );
                    }
                    return Column(
                      children: [
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _InviteCard(
                              item: item,
                              busy: _processingInviteIds.contains(item.id),
                              onAccept: () => _acceptInvite(item),
                              onDecline: () => _declineInvite(item),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                _DuelSectionTitle(
                  title: context.l10n.duelActiveMatchesTitle,
                  subtitle: context.l10n.duelActiveMatchesSubtitle,
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<LiveMatch>>(
                  stream: _liveDuelService.watchMyActiveMatches(),
                  builder: (context, snapshot) {
                    final matches = (snapshot.data ?? const <LiveMatch>[])
                        .where((m) => !m.isTerminal)
                        .toList(growable: false);
                    if (snapshot.hasError) {
                      return _InlineInfoCard(
                        icon: Icons.error_outline_rounded,
                        title: context.l10n.duelActiveLoadErrorTitle,
                        subtitle: context.l10n.duelTryAgainLater,
                      );
                    }
                    if (matches.isEmpty) {
                      return _InlineInfoCard(
                        icon: Icons.sports_esports_outlined,
                        title: context.l10n.duelNoActiveTitle,
                        subtitle: context.l10n.duelNoActiveSubtitle,
                      );
                    }
                    return Column(
                      children: [
                        for (final match in matches.take(6))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ActiveMatchCard(
                              match: match,
                              currentUid: _uid,
                              removing:
                                  _processingActiveMatchIds.contains(match.id),
                              onResume: () =>
                                  context.go('/live-duel/${match.id}'),
                              onRemove: () => _removeActiveMatch(match),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                _DuelSectionTitle(
                  title: context.l10n.duelHistoryTitle,
                  subtitle: context.l10n.duelHistorySubtitle,
                ),
                const SizedBox(height: 10),
                _InlineInfoCard(
                  icon: Icons.history_rounded,
                  title: context.l10n.duelHistoryComingSoonTitle,
                  subtitle: context.l10n.duelHistoryComingSoonSubtitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _challengeFriend() async {
    setState(() => _creatingInvite = true);
    try {
      final friend = await _pickFriend();
      if (!mounted || friend == null) return;
      final created =
          await _liveDuelService.createRandomInvite(toUid: friend.uid);
      if (!mounted) return;
      context.go('/live-duel/${created.matchId}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mapCreateInviteError(e)),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingInvite = false);
      }
    }
  }

  Future<FriendProfile?> _pickFriend() async {
    return showModalBottomSheet<FriendProfile>(
      context: context,
      backgroundColor: const Color(0xFF121D34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.duelChooseFriend,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: StreamBuilder<List<FriendProfile>>(
                    stream: _friendsService.watchFriends(),
                    builder: (context, snapshot) {
                      final friends = (snapshot.data ?? const <FriendProfile>[])
                          .toList(growable: false)
                        ..sort((a, b) {
                          if (a.isOnline != b.isOnline) {
                            return a.isOnline ? -1 : 1;
                          }
                          return a.displayName
                              .toLowerCase()
                              .compareTo(b.displayName.toLowerCase());
                        });
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            context.l10n.duelCouldNotLoadFriends,
                            style: TextStyle(color: Color(0xFF9EB0D2)),
                          ),
                        );
                      }
                      if (friends.isEmpty) {
                        return Center(
                          child: Text(
                            context.l10n.duelNoFriendsYet,
                            style: TextStyle(color: Color(0xFF9EB0D2)),
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: friends.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final friend = friends[index];
                          final username = friend.username.trim().isNotEmpty
                              ? '@${friend.username.trim()}'
                              : friend.playerName;
                          return Material(
                            color: const Color(0xFF1A263B),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.of(context).pop(friend),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Icon(
                                          Icons.person_rounded,
                                          color: Color(0xFF9EC5FF),
                                          size: 20,
                                        ),
                                        Positioned(
                                          right: -4,
                                          bottom: -2,
                                          child: PresenceDot(
                                            isOnline: friend.isOnline,
                                            size: 8.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '$username · ${friend.isOnline ? 'Online' : 'Offline'}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFF9EB0D2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
  }

  Future<void> _acceptInvite(InboxItem item) async {
    final key = item.id.trim();
    if (key.isEmpty) return;
    setState(() => _processingInviteIds.add(key));
    try {
      final matchId = item.ctaPayload.trim();
      await _liveDuelService.acceptInvite(
        matchId: matchId,
        inboxMessageId: item.id,
      );
      if (!mounted) return;
      context.go('/live-duel/$matchId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.duelAcceptError('$e')),
          duration: const Duration(milliseconds: 1600),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingInviteIds.remove(key));
      }
    }
  }

  Future<void> _declineInvite(InboxItem item) async {
    final key = item.id.trim();
    if (key.isEmpty) return;
    setState(() => _processingInviteIds.add(key));
    try {
      await _liveDuelService.declineInvite(
        matchId: item.ctaPayload.trim(),
        inboxMessageId: item.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.duelDeclineError('$e')),
          duration: const Duration(milliseconds: 1600),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingInviteIds.remove(key));
      }
    }
  }

  String _mapCreateInviteError(Object error) {
    final text = error.toString();
    if (text.contains('ALREADY_IN_ACTIVE_DUEL')) {
      return context.l10n.duelErrorFinishCurrentFirst;
    }
    if (text.contains('TARGET_IN_ACTIVE_DUEL')) {
      return context.l10n.duelErrorFriendBusy;
    }
    if (text.contains('NO_PUZZLES_AVAILABLE')) {
      return context.l10n.duelErrorNoPuzzles;
    }
    if (text.contains('INVALID_DUEL_TARGET')) {
      return context.l10n.duelErrorInvalidTarget;
    }
    return context.l10n.duelErrorCreateInvite;
  }

  Future<void> _removeActiveMatch(LiveMatch match) async {
    final matchId = match.id.trim();
    if (matchId.isEmpty) return;
    if (_processingActiveMatchIds.contains(matchId)) return;
    final shouldRemove = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF111827),
            title: Text(
              context.l10n.duelRemoveActiveTitle,
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              context.l10n.duelRemoveActiveBody,
              style: const TextStyle(color: Color(0xFFB6C2DA)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(context.l10n.duelKeep),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(context.l10n.duelRemove),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldRemove || !mounted) return;

    setState(() => _processingActiveMatchIds.add(matchId));
    try {
      await _liveDuelService.markAbandoned(matchId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.duelRemovedActive),
          duration: const Duration(milliseconds: 1300),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.duelRemoveError('$e')),
          duration: const Duration(milliseconds: 1600),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingActiveMatchIds.remove(matchId));
      }
    }
  }
}

class _DuelHeader extends StatelessWidget {
  const _DuelHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF16233A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2B3F63)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flash_on_rounded, color: Color(0xFF9EC5FF), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.duelHubTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.duelHubSubtitle,
                  style: TextStyle(
                    color: Color(0xFF9EB0D2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DuelPrimaryCta extends StatelessWidget {
  const _DuelPrimaryCta({
    required this.busy,
    required this.onTap,
  });

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PrimaryCtaButton(
      label: busy ? context.l10n.duelCreating : context.l10n.duelChallengeFriend,
      icon: busy ? null : Icons.flash_on_rounded,
      onTap: onTap,
    );
  }
}

class _DuelSectionTitle extends StatelessWidget {
  const _DuelSectionTitle({
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
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
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

class _InlineInfoCard extends StatelessWidget {
  const _InlineInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9EB0D2)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF9EB0D2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.item,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final InboxItem item;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final sender = item.senderDisplayName;
    return GameCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.duelInviteSentText,
            style: TextStyle(
              color: Color(0xFF9EB0D2),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onDecline,
                  child: Text(context.l10n.decline),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onAccept,
                  child: Text(busy ? '...' : context.l10n.duelAccept),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveMatchCard extends StatelessWidget {
  const _ActiveMatchCard({
    required this.match,
    required this.currentUid,
    required this.onResume,
    required this.onRemove,
    this.removing = false,
  });

  final LiveMatch match;
  final String currentUid;
  final VoidCallback onResume;
  final VoidCallback onRemove;
  final bool removing;

  @override
  Widget build(BuildContext context) {
    final opponentUid = match.opponentUid(currentUid);
    final opponentPlayer = match.players[opponentUid];
    final opponentName = (opponentPlayer?.username.trim().isNotEmpty ?? false)
        ? opponentPlayer!.username.trim()
        : (opponentUid.isEmpty ? context.l10n.duelUnknownOpponent : opponentUid);
    final status = switch (match.status) {
      LiveMatchStatus.pending => context.l10n.duelStatusPending,
      LiveMatchStatus.countdown => context.l10n.duelStatusCountdown,
      LiveMatchStatus.playing => context.l10n.duelStatusPlaying,
      LiveMatchStatus.finished => context.l10n.duelStatusFinished,
      LiveMatchStatus.cancelled => context.l10n.duelStatusCancelled,
    };
    return GameCard(
      child: Row(
        children: [
          const Icon(Icons.flash_on_rounded, color: Color(0xFF9EC5FF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.duelVersusOpponent(opponentName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.duelLevelAndStatus(match.levelId, status),
                  style: const TextStyle(
                    color: Color(0xFF9EB0D2),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: removing ? null : onResume,
            child: Text(context.l10n.duelResume),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: removing ? null : onRemove,
            child: Text(
              removing ? context.l10n.duelRemoving : context.l10n.duelRemove,
            ),
          ),
        ],
      ),
    );
  }
}



