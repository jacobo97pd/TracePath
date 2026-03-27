import 'dart:async';

import 'package:animate_do/animate_do.dart';
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
  StreamSubscription<List<LiveMatchEmote>>? _emoteSub;
  Timer? _ticker;
  Timer? _heroEmoteTimer;
  OverlayEntry? _heroEmoteEntry;
  LiveMatch? _match;
  Object? _error;
  bool _loading = true;
  bool _accepting = false;
  bool _navigated = false;
  bool _rematchBusy = false;
  bool _readyBusy = false;
  bool _ensurePlayingBusy = false;
  int _lastEmoteSentAtMs = 0;
  String _heroIncomingEmoteMatchId = '';
  String _heroIncomingEmoteLastId = '';
  bool _heroIncomingEmotePrimed = false;

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
        if (match.status == LiveMatchStatus.finished) {
          _attachIncomingEmoteListener(match.id);
        } else {
          _detachIncomingEmoteListener(clearUi: true);
        }
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
    _emoteSub?.cancel();
    _ticker?.cancel();
    _clearHeroIncomingEmoteOverlay();
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

  void _attachIncomingEmoteListener(String matchId) {
    final normalized = matchId.trim();
    if (normalized.isEmpty) return;
    if (_heroIncomingEmoteMatchId == normalized && _emoteSub != null) return;
    _detachIncomingEmoteListener(clearUi: false);
    _heroIncomingEmoteMatchId = normalized;
    _heroIncomingEmotePrimed = false;
    _emoteSub = _service.watchMatchEmotes(normalized, limit: 6).listen((items) {
      if (!mounted) return;
      final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
      if (uid.isEmpty) return;
      final firstSnapshot = !_heroIncomingEmotePrimed;
      if (firstSnapshot) {
        _heroIncomingEmotePrimed = true;
      }
      if (items.isEmpty) return;
      LiveMatchEmote? incoming;
      for (final item in items) {
        final senderUid = item.sentByUid.trim();
        if (senderUid.isEmpty || senderUid == uid) continue;
        incoming = item;
        break;
      }
      if (incoming == null) return;
      if (firstSnapshot) {
        _heroIncomingEmoteLastId = incoming.id;
        return;
      }
      if (incoming.id == _heroIncomingEmoteLastId) return;
      _heroIncomingEmoteLastId = incoming.id;
      _showIncomingEmoteHero(incoming);
    });
  }

  void _detachIncomingEmoteListener({bool clearUi = false}) {
    _emoteSub?.cancel();
    _emoteSub = null;
    _heroIncomingEmoteMatchId = '';
    _heroIncomingEmotePrimed = false;
    if (clearUi) {
      _clearHeroIncomingEmoteOverlay();
    }
  }

  void _showIncomingEmoteHero(LiveMatchEmote emote) {
    if (!mounted) return;
    final sender = emote.senderUsername.trim().isNotEmpty
        ? emote.senderUsername.trim()
        : 'Opponent';
    _showHeroIncomingEmoteOverlay(
      glyph: _emoteGlyph(emote.emoteId),
      sender: sender,
      eventId: _heroIncomingEmoteLastId,
    );
  }

  void _showHeroIncomingEmoteOverlay({
    required String glyph,
    required String sender,
    required String eventId,
  }) {
    if (!mounted) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _clearHeroIncomingEmoteOverlay();
    _heroEmoteEntry = OverlayEntry(
      builder: (overlayContext) {
        final shortest =
            MediaQuery.of(overlayContext).size.shortestSide.clamp(320.0, 560.0);
        final compact = shortest < 390;
        final emojiSize = compact ? 120.0 : 148.0;
        return Positioned.fill(
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black.withOpacity(0.46)),
                  Center(
                    child: ZoomIn(
                      key: ValueKey<String>('hero_incoming_emote_$eventId'),
                      duration: const Duration(milliseconds: 260),
                      child: BounceInDown(
                        duration: const Duration(milliseconds: 420),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: compact ? 24 : 34,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 22 : 28,
                            vertical: compact ? 16 : 20,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E1E33).withOpacity(0.95),
                            borderRadius: BorderRadius.circular(
                              compact ? 22 : 26,
                            ),
                            border: Border.all(
                              color: const Color(0xFF71E1FF),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF5FD8FF).withOpacity(0.42),
                                blurRadius: compact ? 24 : 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                glyph,
                                style: TextStyle(
                                  fontSize: emojiSize,
                                  height: 1,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0xFF79E7FF),
                                      blurRadius: 22,
                                    ),
                                  ],
                                ),
                              ),
                              if (sender.trim().isNotEmpty) ...[
                                SizedBox(height: compact ? 6 : 8),
                                Text(
                                  '$sender reacted',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFFD8EEFF),
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 15 : 17,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_heroEmoteEntry!);
    _heroEmoteTimer = Timer(const Duration(milliseconds: 1450), () {
      _clearHeroIncomingEmoteOverlay();
    });
  }

  void _clearHeroIncomingEmoteOverlay() {
    _heroEmoteTimer?.cancel();
    _heroEmoteTimer = null;
    _heroEmoteEntry?.remove();
    _heroEmoteEntry = null;
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxHeight < 760 || constraints.maxWidth < 390;
            final dense =
                constraints.maxHeight < 680 || constraints.maxWidth < 360;
            final horizontalPadding = compact ? 10.0 : 14.0;
            final verticalPadding = dense ? 6.0 : (compact ? 8.0 : 10.0);
            final sectionGap = compact ? 6.0 : 9.0;
            final centerGap = compact ? 8.0 : 10.0;
            final minHeight = constraints.maxHeight - (verticalPadding * 2);
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
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
                          : Stack(
                              children: [
                                SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints:
                                        BoxConstraints(minHeight: minHeight),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        _HeaderCard(
                                          title: title,
                                          subtitle: match.levelId,
                                          compact: compact,
                                        ),
                                        SizedBox(height: sectionGap),
                                        _PlayerRow(
                                          label: 'You',
                                          username:
                                              myPlayer?.username.isNotEmpty ==
                                                      true
                                                  ? myPlayer!.username
                                                  : 'Player',
                                          state: myPlayer?.state ??
                                              LiveMatchPlayerState.joined,
                                          compact: compact,
                                        ),
                                        SizedBox(height: compact ? 6 : 8),
                                        _PlayerRow(
                                          label: 'Opponent',
                                          username:
                                              opponent?.username.isNotEmpty ==
                                                      true
                                                  ? opponent!.username
                                                  : 'Waiting player...',
                                          state: opponent?.state ??
                                              LiveMatchPlayerState.invited,
                                          compact: compact,
                                        ),
                                        SizedBox(height: centerGap),
                                        _buildCenter(
                                          match,
                                          myPlayer: myPlayer,
                                          opponent: opponent,
                                          compact: compact,
                                          dense: dense,
                                        ),
                                        SizedBox(height: sectionGap),
                                        OutlinedButton(
                                          onPressed: () async {
                                            final active = _match;
                                            if (active != null &&
                                                active.status ==
                                                    LiveMatchStatus.pending &&
                                                uid == active.invitedUid) {
                                              await _service.declineInvite(
                                                matchId: active.id,
                                              );
                                            } else {
                                              await _service.markAbandoned(
                                                  widget.matchId);
                                            }
                                            if (!context.mounted) return;
                                            context.go('/play');
                                          },
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: Size.fromHeight(
                                              compact ? 40 : 44,
                                            ),
                                            visualDensity: compact
                                                ? const VisualDensity(
                                                    horizontal: -1,
                                                    vertical: -1,
                                                  )
                                                : null,
                                          ),
                                          child: const Text('Leave duel'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: _buildLiveHeroOverlay(
                                      match: match,
                                      compact: compact,
                                    ),
                                  ),
                                ),
                              ],
                            ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLiveHeroOverlay({
    required LiveMatch match,
    required bool compact,
  }) {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();
    if (match.status == LiveMatchStatus.countdown) {
      final leftMs = _countdownRemainingMs(match);
      final text = leftMs > 2000
          ? '3'
          : leftMs > 1000
              ? '2'
              : leftMs > 0
                  ? '1'
                  : 'GO!';
      return Align(
        alignment: Alignment.center,
        child: BounceInDown(
          key: ValueKey<String>('hero_countdown_$text'),
          duration: Duration(milliseconds: text == 'GO!' ? 380 : 300),
          child: ZoomIn(
            duration: Duration(milliseconds: text == 'GO!' ? 320 : 260),
            delay: const Duration(milliseconds: 40),
            child: Transform.translate(
              offset: Offset(0, text == 'GO!' ? -14 : -8),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: text == 'GO!'
                      ? const Color(0xFFA8F4FF)
                      : const Color(0xFF8AE7FF),
                  fontSize: compact ? 112 : 136,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: text == 'GO!' ? 1.5 : 0.9,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF59DFFF)
                          .withOpacity(text == 'GO!' ? 0.66 : 0.46),
                      blurRadius: text == 'GO!' ? 34 : 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (match.status == LiveMatchStatus.finished) {
      final me = match.players[uid];
      final opponentUid = match.opponentUid(uid);
      final opp = match.players[opponentUid];
      final winnerUid = match.winnerUid.trim();
      final myAbandoned = me?.state == LiveMatchPlayerState.abandoned;
      final oppAbandoned = opp?.state == LiveMatchPlayerState.abandoned;
      final draw = winnerUid.isEmpty;
      final won = winnerUid == uid;
      final emoji = myAbandoned
          ? '\u{1F622}'
          : oppAbandoned
              ? '\u{1F3C6}'
              : draw
                  ? '\u{1F91D}'
                  : (won ? '\u{1F3C6}' : '\u{1F622}');
      final title = myAbandoned
          ? 'YOU ABANDONED'
          : oppAbandoned
              ? 'YOU WIN!'
              : draw
                  ? 'DRAW'
                  : (won ? 'YOU WIN!' : 'YOU LOST');
      final glow = won || oppAbandoned
          ? const Color(0xFF6CF0C2)
          : const Color(0xFFFF79A8);
      return Align(
        alignment: Alignment.center,
        child: Transform.translate(
          offset: const Offset(0, -16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BounceInDown(
                key: ValueKey<String>('hero_result_emoji_${match.id}_$emoji'),
                duration: const Duration(milliseconds: 420),
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: compact ? 96 : 118,
                    height: 1,
                    shadows: [
                      Shadow(
                        color: glow.withOpacity(0.56),
                        blurRadius: compact ? 22 : 30,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: compact ? 2 : 4),
              FadeInUp(
                key: ValueKey<String>('hero_result_title_${match.id}_$title'),
                duration: const Duration(milliseconds: 360),
                delay: const Duration(milliseconds: 90),
                from: 16,
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 30 : 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    shadows: [
                      Shadow(
                        color: glow.withOpacity(0.42),
                        blurRadius: compact ? 14 : 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCenter(
    LiveMatch match, {
    required LiveMatchPlayer? myPlayer,
    required LiveMatchPlayer? opponent,
    required bool compact,
    required bool dense,
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
        return Align(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                size: compact ? 38 : 44,
                color: const Color(0xFF8FB9FF),
              ),
              SizedBox(height: compact ? 8 : 10),
              Text(
                isInvited
                    ? 'Invitation received'
                    : 'Waiting for your friend to join...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: compact ? 8 : 10),
              Text(
                opponentJoined
                    ? (opponentReady
                        ? 'Opponent is ready'
                        : 'Opponent joined, waiting ready')
                    : 'Opponent has not joined yet',
                style: TextStyle(
                  color: Color(0xFFAED2FF),
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: compact ? 10 : 12),
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
                  style: FilledButton.styleFrom(
                    minimumSize: Size(compact ? 148 : 172, compact ? 40 : 44),
                    visualDensity: compact
                        ? const VisualDensity(horizontal: -1, vertical: -1)
                        : null,
                  ),
                  child: Text(_accepting ? 'Accepting...' : 'Accept duel'),
                ),
              SizedBox(height: compact ? 6 : 8),
              FilledButton(
                onPressed: (_readyBusy || inviteNotAccepted)
                    ? null
                    : () => _toggleReady(match),
                style: FilledButton.styleFrom(
                  minimumSize: Size(compact ? 126 : 148, compact ? 40 : 44),
                  visualDensity: compact
                      ? const VisualDensity(horizontal: -1, vertical: -1)
                      : null,
                ),
                child: Text(
                  _readyBusy ? 'Saving...' : (iAmReady ? 'Unready' : 'Ready'),
                ),
              ),
              if (inviteNotAccepted) ...[
                SizedBox(height: compact ? 6 : 8),
                Text(
                  'Accept first, then mark Ready.',
                  style: TextStyle(
                    color: Color(0xFFAED2FF),
                    fontSize: compact ? 11 : 12,
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
        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF142744),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF345E93)),
            ),
            child: Text(
              text == 'GO!' ? 'GO!' : 'Starting in $text...',
              style: TextStyle(
                color: const Color(0xFFAED2FF),
                fontSize: compact ? 12.5 : 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      case LiveMatchStatus.playing:
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: compact ? 6 : 8),
            child: Text(
              'Starting match...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 14 : 15,
              ),
            ),
          ),
        );
      case LiveMatchStatus.finished:
        return _buildFinished(match, compact: compact, dense: dense);
      case LiveMatchStatus.cancelled:
        return Align(
          alignment: Alignment.topCenter,
          child: _buildCancelled(match),
        );
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

  Widget _buildFinished(
    LiveMatch match, {
    required bool compact,
    required bool dense,
  }) {
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
            ? 'You won \u{1F642}'
            : draw
                ? 'Draw'
                : (won ? 'You won \u{1F642}' : 'Defeat');
    final subtitle = myAbandoned
        ? 'Defeat by abandon'
        : oppAbandoned
            ? 'Win by abandon'
            : (won ? 'You won the duel' : (draw ? 'No winner' : 'You lost'));
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 12,
        compact ? 8 : 10,
        compact ? 10 : 12,
        compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF132238).withOpacity(0.9),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: const Color(0xFF2E4A72)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: compact ? 2 : 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 20 : 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 3 : 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFAED2FF),
              fontSize: compact ? 11.5 : 12.5,
            ),
          ),
          SizedBox(height: compact ? 8 : 10),
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
          SizedBox(height: compact ? 6 : 8),
          _buildEmoteTray(match.id),
          SizedBox(height: compact ? 8 : 10),
          FilledButton(
            onPressed: _rematchBusy
                ? null
                : () async {
                    setState(() => _rematchBusy = true);
                    try {
                      final created = await _service.createRematch(
                          previousMatchId: match.id);
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
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 40 : 44),
              visualDensity: compact
                  ? const VisualDensity(horizontal: -1, vertical: -1)
                  : null,
            ),
            child: Text(_rematchBusy ? 'Creating rematch...' : 'Rematch'),
          ),
          SizedBox(height: dense ? 4 : 6),
          OutlinedButton(
            onPressed: () => context.go('/play'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 40 : 44),
              visualDensity: compact
                  ? const VisualDensity(horizontal: -1, vertical: -1)
                  : null,
            ),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmoteTray(String matchId) {
    const emotes = <MapEntry<String, String>>[
      MapEntry('laugh', '\u{1F602}'),
      MapEntry('cool', '\u{1F60E}'),
      MapEntry('wow', '\u{1F62E}'),
      MapEntry('cry', '\u{1F622}'),
      MapEntry('clap', '\u{1F44F}'),
      MapEntry('heart', '\u{2764}\u{FE0F}'),
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
        return '\u{1F602}';
      case 'cool':
        return '\u{1F60E}';
      case 'cry':
        return '\u{1F622}';
      case 'clap':
        return '\u{1F44F}';
      case 'heart':
        return '\u{2764}\u{FE0F}';
      case 'wow':
      default:
        return '\u{1F62E}';
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
      _showHeroIncomingEmoteOverlay(
        glyph: _emoteGlyph(emoteId),
        sender: '',
        eventId: 'local_${nowMs}_$emoteId',
      );
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
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16253A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E4B72)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Duel cancelled',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFFAED2FF),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.go('/play'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
            ),
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
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
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
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 17 : 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Color(0xFF9DB3D8),
              fontSize: compact ? 12 : 13,
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
    this.compact = false,
  });

  final String label;
  final String username;
  final LiveMatchPlayerState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF152339),
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: const Color(0xFF2D4566)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF9FB4D7),
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12.5 : 13.5,
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Text(
              username,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 13 : 14,
              ),
            ),
          ),
          Text(
            _stateLabel(state),
            style: TextStyle(
              color: Color(0xFF7DE2FF),
              fontWeight: FontWeight.w700,
              fontSize: compact ? 12 : 13,
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
