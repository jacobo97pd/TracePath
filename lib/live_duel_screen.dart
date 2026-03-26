import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/live_match.dart';
import 'services/live_duel_service.dart';

class LiveDuelScreen extends StatefulWidget {
  const LiveDuelScreen({
    super.key,
    required this.matchId,
  });

  final String matchId;

  @override
  State<LiveDuelScreen> createState() => _LiveDuelScreenState();
}

class _LiveDuelScreenState extends State<LiveDuelScreen> {
  final LiveDuelService _service = LiveDuelService();
  StreamSubscription<LiveMatch?>? _sub;
  Timer? _ticker;
  LiveMatch? _match;
  Object? _error;
  bool _loading = true;
  bool _accepting = false;
  bool _navigated = false;
  bool _rematchBusy = false;
  bool _readyBusy = false;
  bool _ensurePlayingBusy = false;
  int _lastEmoteSentAtMs = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!mounted) return;
      final active = _match;
      if (active != null &&
          active.status == LiveMatchStatus.countdown &&
          !_ensurePlayingBusy &&
          _countdownRemainingMs(active) <= 0) {
        _ensurePlayingBusy = true;
        unawaited(
          _service.ensurePlaying(active.id).whenComplete(() {
            _ensurePlayingBusy = false;
          }),
        );
      }
      setState(() {});
    });
    _sub = _service.watchMatch(widget.matchId).listen(
      (match) async {
        if (!mounted) return;
        if (match == null) {
          setState(() {
            _loading = false;
            _error = StateError('MATCH_NOT_FOUND');
          });
          return;
        }
        setState(() {
          _match = match;
          _loading = false;
          _error = null;
        });
        await _service.expireIfStale(match.id);
        await _maybeAutoStart(match);
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = e;
        });
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _toggleReady(LiveMatch match) async {
    if (_readyBusy) return;
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) return;
    final me = match.players[uid];
    final currentlyReady = me?.state == LiveMatchPlayerState.ready;
    setState(() => _readyBusy = true);
    try {
      await _service.setReady(
        matchId: match.id,
        ready: !currentlyReady,
      );
    } catch (e) {
      if (!mounted) return;
      var message = 'Could not update ready state';
      final error = e.toString();
      if (error.contains('INVITE_NOT_ACCEPTED')) {
        message = 'Accept the duel invite first';
      } else if (error.contains('MATCH_CLOSED')) {
        message = 'This duel is already closed';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _readyBusy = false);
      }
    }
  }

  Future<void> _maybeAutoStart(LiveMatch match) async {
    if (_navigated) return;
    if (match.status == LiveMatchStatus.playing) {
      await _goToGame(match);
      return;
    }
    if (match.status != LiveMatchStatus.countdown) return;
    final ms = _countdownRemainingMs(match);
    if (ms <= 0) {
      await _service.ensurePlaying(match.id);
    }
  }

  int _countdownRemainingMs(LiveMatch match) {
    final acceptedAt = match.acceptedAt;
    if (acceptedAt == null) return (match.countdownSeconds * 1000);
    final end =
        acceptedAt.millisecondsSinceEpoch + (match.countdownSeconds * 1000);
    return end - DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _goToGame(LiveMatch match) async {
    if (_navigated) return;
    _navigated = true;
    final info = LiveDuelService.parseLevelRouteInfo(match.levelId);
    if (info == null) {
      if (!mounted) return;
      context.go('/play');
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final opponentUid = match.opponentUid(uid);
    if (!mounted) return;
    context.go(
      '/play/${info.packId}/${info.levelIndex}',
      extra: LiveDuelGameArgs(
        matchId: match.id,
        levelId: match.levelId,
        opponentUid: opponentUid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = _match;
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final opponentUid = match?.opponentUid(uid) ?? '';
    final opponent = opponentUid.isEmpty ? null : match?.players[opponentUid];
    final myPlayer = uid.isEmpty ? null : match?.players[uid];
    final title = _titleFor(match);

    return Scaffold(
      backgroundColor: const Color(0xFF071022),
      appBar: AppBar(
        title: const Text('Live Duel'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorCard(
                      message: 'Live duel unavailable right now.',
                      detail: _error.toString(),
                    )
                  : match == null
                      ? const _ErrorCard(
                          message: 'Match not found',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeaderCard(
                              title: title,
                              subtitle: match.levelId,
                            ),
                            const SizedBox(height: 12),
                            _PlayerRow(
                              label: 'You',
                              username: myPlayer?.username.isNotEmpty == true
                                  ? myPlayer!.username
                                  : 'Player',
                              state: myPlayer?.state ??
                                  LiveMatchPlayerState.joined,
                            ),
                            const SizedBox(height: 8),
                            _PlayerRow(
                              label: 'Opponent',
                              username: opponent?.username.isNotEmpty == true
                                  ? opponent!.username
                                  : 'Waiting player...',
                              state: opponent?.state ??
                                  LiveMatchPlayerState.invited,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _buildCenter(
                                match,
                                myPlayer: myPlayer,
                                opponent: opponent,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () async {
                                final active = _match;
                                if (active != null &&
                                    active.status == LiveMatchStatus.pending &&
                                    uid == active.invitedUid) {
                                  await _service.declineInvite(
                                    matchId: active.id,
                                  );
                                } else {
                                  await _service.markAbandoned(widget.matchId);
                                }
                                if (!context.mounted) return;
                                context.go('/play');
                              },
                              child: const Text('Leave duel'),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }

  Widget _buildCenter(
    LiveMatch match, {
    required LiveMatchPlayer? myPlayer,
    required LiveMatchPlayer? opponent,
  }) {
    switch (match.status) {
      case LiveMatchStatus.pending:
        final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
        final isInvited = uid == match.invitedUid;
        final inviteNotAccepted = isInvited &&
            (myPlayer == null ||
                myPlayer.state == LiveMatchPlayerState.invited);
        final iAmReady = myPlayer?.state == LiveMatchPlayerState.ready;
        final opponentReady = opponent?.state == LiveMatchPlayerState.ready;
        final opponentJoined = opponent?.state == LiveMatchPlayerState.joined ||
            opponent?.state == LiveMatchPlayerState.ready;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 44, color: Color(0xFF8FB9FF)),
              const SizedBox(height: 10),
              Text(
                isInvited
                    ? 'Invitation received'
                    : 'Waiting for your friend to join...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                opponentJoined
                    ? (opponentReady
                        ? 'Opponent is ready'
                        : 'Opponent joined, waiting ready')
                    : 'Opponent has not joined yet',
                style: const TextStyle(
                  color: Color(0xFFAED2FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (isInvited)
                FilledButton(
                  onPressed: _accepting
                      ? null
                      : () async {
                          setState(() => _accepting = true);
                          try {
                            await _service.acceptInvite(matchId: match.id);
                          } finally {
                            if (mounted) setState(() => _accepting = false);
                          }
                        },
                  child: Text(_accepting ? 'Accepting...' : 'Accept duel'),
                ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: (_readyBusy || inviteNotAccepted)
                    ? null
                    : () => _toggleReady(match),
                child: Text(
                  _readyBusy ? 'Saving...' : (iAmReady ? 'Unready' : 'Ready'),
                ),
              ),
              if (inviteNotAccepted) ...[
                const SizedBox(height: 8),
                const Text(
                  'Accept first, then mark Ready.',
                  style: TextStyle(
                    color: Color(0xFFAED2FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      case LiveMatchStatus.countdown:
        final leftMs = _countdownRemainingMs(match);
        final text = leftMs > 2000
            ? '3'
            : leftMs > 1000
                ? '2'
                : leftMs > 0
                    ? '1'
                    : 'GO!';
        return Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween<double>(begin: 0.86, end: 1).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Text(
              text,
              key: ValueKey<String>(text),
              style: const TextStyle(
                color: Color(0xFF7DE2FF),
                fontSize: 72,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      case LiveMatchStatus.playing:
        return const Center(
          child: Text(
            'Starting match...',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        );
      case LiveMatchStatus.finished:
        return _buildFinished(match);
      case LiveMatchStatus.cancelled:
        return _buildCancelled(match);
    }
  }

  String _titleFor(LiveMatch? match) {
    if (match == null) return 'Live Duel';
    switch (match.status) {
      case LiveMatchStatus.pending:
        return 'Waiting Room';
      case LiveMatchStatus.countdown:
        return 'Get Ready';
      case LiveMatchStatus.playing:
        return 'Match Started';
      case LiveMatchStatus.finished:
        return 'Match Result';
      case LiveMatchStatus.cancelled:
        return 'Match Cancelled';
    }
  }

  Widget _buildFinished(LiveMatch match) {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final opponentUid = match.opponentUid(uid);
    final me = match.players[uid];
    final opp = match.players[opponentUid];
    final winnerUid = match.winnerUid.trim();
    final myAbandoned = me?.state == LiveMatchPlayerState.abandoned;
    final oppAbandoned = opp?.state == LiveMatchPlayerState.abandoned;
    final draw = winnerUid.isEmpty;
    final won = winnerUid == uid;
    final title = myAbandoned
        ? 'You abandoned'
        : oppAbandoned
            ? 'Opponent abandoned'
            : draw
                ? 'Draw'
                : (won ? 'Victory' : 'Defeat');
    final subtitle = myAbandoned
        ? 'Defeat by abandon'
        : oppAbandoned
            ? 'Win by abandon'
            : (won ? 'You won the duel' : (draw ? 'No winner' : 'You lost'));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFAED2FF)),
        ),
        const SizedBox(height: 14),
        _resultRow('Your time', _formatTime(me?.finishedAtMsFromStart ?? 0)),
        _resultRow(
            'Opponent',
            (opp?.username.trim().isNotEmpty == true)
                ? opp!.username.trim()
                : 'Player'),
        _resultRow(
          'Opponent time',
          _formatTime(opp?.finishedAtMsFromStart ?? 0),
        ),
        const SizedBox(height: 10),
        _buildEmoteFeed(match.id),
        const SizedBox(height: 8),
        _buildEmoteTray(match.id),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _rematchBusy
              ? null
              : () async {
                  setState(() => _rematchBusy = true);
                  try {
                    final created =
                        await _service.createRematch(previousMatchId: match.id);
                    if (!mounted) return;
                    context.go('/live-duel/${created.matchId}');
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _rematchBusy = false);
                    var msg = 'Could not create rematch';
                    final txt = e.toString();
                    if (txt.contains('TARGET_IN_ACTIVE_DUEL')) {
                      msg = 'Opponent is busy in another duel';
                    } else if (txt.contains('ALREADY_IN_ACTIVE_DUEL')) {
                      msg = 'Finish your active duel first';
                    }
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
          child: Text(_rematchBusy ? 'Creating rematch...' : 'Rematch'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.go('/play'),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _buildEmoteFeed(String matchId) {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    return StreamBuilder<List<LiveMatchEmote>>(
      stream: _service.watchMatchEmotes(matchId, limit: 8),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <LiveMatchEmote>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.take(4).map((e) {
            final mine = e.sentByUid == uid;
            final glyph = _emoteGlyph(e.emoteId);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: mine
                    ? const Color(0xFF1E3658).withOpacity(0.9)
                    : const Color(0xFF24334B).withOpacity(0.9),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color:
                      mine ? const Color(0xFF68A3FF) : const Color(0xFF486182),
                ),
              ),
              child: Text(
                '$glyph ${mine ? "You" : "Opponent"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }

  Widget _buildEmoteTray(String matchId) {
    const emotes = <MapEntry<String, String>>[
      MapEntry('laugh', '😂'),
      MapEntry('cool', '😎'),
      MapEntry('wow', '😮'),
      MapEntry('cry', '😢'),
      MapEntry('clap', '👏'),
      MapEntry('heart', '❤️'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: emotes.map((item) {
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _sendEmote(matchId: matchId, emoteId: item.key),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A43),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3F5E88)),
            ),
            child: Text(
              item.value,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  String _emoteGlyph(String emoteId) {
    switch (emoteId) {
      case 'laugh':
        return '😂';
      case 'cool':
        return '😎';
      case 'cry':
        return '😢';
      case 'clap':
        return '👏';
      case 'heart':
        return '❤️';
      case 'wow':
      default:
        return '😮';
    }
  }

  Future<void> _sendEmote({
    required String matchId,
    required String emoteId,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_lastEmoteSentAtMs > 0 && nowMs - _lastEmoteSentAtMs < 1600) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emote cooldown'),
          duration: Duration(milliseconds: 900),
        ),
      );
      return;
    }
    try {
      await _service.sendMatchEmote(matchId: matchId, emoteId: emoteId);
      _lastEmoteSentAtMs = nowMs;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send emote'),
          duration: Duration(milliseconds: 900),
        ),
      );
    }
  }

  Widget _buildCancelled(LiveMatch match) {
    final reason = match.reason.trim();
    final message = reason == 'invite_expired'
        ? 'Invitation expired'
        : reason == 'countdown_timeout'
            ? 'Countdown expired'
            : reason == 'playing_timeout'
                ? 'Match timed out'
                : 'Duel cancelled';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Duel cancelled',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Color(0xFFAED2FF)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/play'),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9FB4D7),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int ms) {
    if (ms <= 0) return '--.--s';
    final seconds = ms / 1000.0;
    return '${seconds.toStringAsFixed(2)}s';
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF172741), Color(0xFF0F1A32)],
        ),
        border: Border.all(color: const Color(0xFF2C4A78)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF9DB3D8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.label,
    required this.username,
    required this.state,
  });

  final String label;
  final String username;
  final LiveMatchPlayerState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF152339),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2D4566)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9FB4D7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            _stateLabel(state),
            style: const TextStyle(
              color: Color(0xFF7DE2FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _stateLabel(LiveMatchPlayerState state) {
    switch (state) {
      case LiveMatchPlayerState.invited:
        return 'Invited';
      case LiveMatchPlayerState.joined:
        return 'Joined';
      case LiveMatchPlayerState.ready:
        return 'Ready';
      case LiveMatchPlayerState.playing:
        return 'Playing';
      case LiveMatchPlayerState.finished:
        return 'Finished';
      case LiveMatchPlayerState.abandoned:
        return 'Abandoned';
    }
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    this.detail = '',
  });

  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2233),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3D4B66)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            if (detail.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: const TextStyle(
                  color: Color(0xFF95A5C3),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
