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
import 'ui/components/game_card.dart';

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

  String get _uid => FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF101A30), Color(0xFF0F172A)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 140),
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
                const _DuelSectionTitle(
                  title: 'Incoming Invites',
                  subtitle: 'Accept or decline live duel requests',
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
                      return const _InlineInfoCard(
                        icon: Icons.wifi_tethering_error_rounded,
                        title: 'Could not load invites',
                        subtitle: 'Try again in a moment.',
                      );
                    }
                    if (items.isEmpty) {
                      return const _InlineInfoCard(
                        icon: Icons.inbox_outlined,
                        title: 'No pending invites',
                        subtitle: 'New challenges will appear here.',
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
                const _DuelSectionTitle(
                  title: 'Active Matches',
                  subtitle: 'Resume your current live duels',
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<LiveMatch>>(
                  stream: _liveDuelService.watchMyActiveMatches(),
                  builder: (context, snapshot) {
                    final matches = (snapshot.data ?? const <LiveMatch>[])
                        .where((m) => !m.isTerminal)
                        .toList(growable: false);
                    if (snapshot.hasError) {
                      return const _InlineInfoCard(
                        icon: Icons.error_outline_rounded,
                        title: 'Could not load active matches',
                        subtitle: 'Try again in a moment.',
                      );
                    }
                    if (matches.isEmpty) {
                      return const _InlineInfoCard(
                        icon: Icons.sports_esports_outlined,
                        title: 'No active duels',
                        subtitle: 'Start a challenge to play live.',
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
                              onResume: () =>
                                  context.go('/live-duel/${match.id}'),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                const _DuelSectionTitle(
                  title: 'History',
                  subtitle: 'Recent duel results',
                ),
                const SizedBox(height: 10),
                const _InlineInfoCard(
                  icon: Icons.history_rounded,
                  title: 'History coming soon',
                  subtitle: 'Your last duels will be shown here.',
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
                const Text(
                  'Choose a friend',
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
                      final friends = snapshot.data ?? const <FriendProfile>[];
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text(
                            'Could not load friends',
                            style: TextStyle(color: Color(0xFF9EB0D2)),
                          ),
                        );
                      }
                      if (friends.isEmpty) {
                        return const Center(
                          child: Text(
                            'No friends yet',
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
                                    const Icon(
                                      Icons.person_rounded,
                                      color: Color(0xFF9EC5FF),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        username,
                                        style: const TextStyle(
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
          content: Text('Could not accept duel invite: $e'),
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
          content: Text('Could not decline duel invite: $e'),
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
      return 'Finish your current live duel first.';
    }
    if (text.contains('TARGET_IN_ACTIVE_DUEL')) {
      return 'This friend is already in another duel.';
    }
    if (text.contains('NO_PUZZLES_AVAILABLE')) {
      return 'No puzzles available right now.';
    }
    if (text.contains('INVALID_DUEL_TARGET')) {
      return 'Could not start duel with this friend.';
    }
    return 'Could not create duel invite right now.';
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
      child: const Row(
        children: [
          Icon(Icons.flash_on_rounded, color: Color(0xFF9EC5FF), size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duel Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Challenge friends and play live matches.',
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
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: const Color(0xFF2F7BFF),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.flash_on_rounded, size: 18),
      label: Text(
        busy ? 'Creating duel...' : 'Challenge a Friend',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: 0.2,
        ),
      ),
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
          const Text(
            'sent you a live duel invite.',
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
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : onAccept,
                  child: Text(busy ? '...' : 'Accept'),
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
  });

  final LiveMatch match;
  final String currentUid;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final opponentUid = match.opponentUid(currentUid);
    final opponentPlayer = match.players[opponentUid];
    final opponentName = (opponentPlayer?.username.trim().isNotEmpty ?? false)
        ? opponentPlayer!.username.trim()
        : (opponentUid.isEmpty ? 'Unknown' : opponentUid);
    final status = switch (match.status) {
      LiveMatchStatus.pending => 'Pending',
      LiveMatchStatus.countdown => 'Countdown',
      LiveMatchStatus.playing => 'Playing',
      LiveMatchStatus.finished => 'Finished',
      LiveMatchStatus.cancelled => 'Cancelled',
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
                  'VS $opponentName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Level: ${match.levelId} · $status',
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
            onPressed: onResume,
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }
}
