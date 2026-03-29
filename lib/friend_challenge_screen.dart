import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'l10n/l10n.dart';
import 'models/friend_challenge.dart';
import 'services/friend_challenge_service.dart';

class FriendChallengeScreen extends StatefulWidget {
  const FriendChallengeScreen({
    super.key,
    required this.challengeId,
  });

  final String challengeId;

  @override
  State<FriendChallengeScreen> createState() => _FriendChallengeScreenState();
}

class _FriendChallengeScreenState extends State<FriendChallengeScreen> {
  final FriendChallengeService _service = FriendChallengeService();
  late Future<FriendChallenge?> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getChallenge(widget.challengeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(context.l10n.friendChallengeTitle),
      ),
      body: FutureBuilder<FriendChallenge?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final challenge = snapshot.data;
          if (challenge == null) {
            return Center(
              child: Text(
                context.l10n.friendChallengeUnavailable,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2740),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF35507A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.friendChallengeTitle,
                        style: TextStyle(
                          color: Color(0xFF8DE3FF),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.friendChallengePuzzle(challenge.puzzleId),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.friendChallengeMode(challenge.mode),
                        style: const TextStyle(
                          color: Color(0xFFA9BBDC),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    context.go(
                      '/play/${challenge.packId}/${challenge.levelIndex}',
                      extra: FriendChallengeGameArgs(
                        challengeId: challenge.challengeId,
                        challengerUserId: challenge.challengerUserId,
                        challengedUserId: challenge.challengedUserId,
                        puzzleId: challenge.puzzleId,
                      ),
                    );
                  },
                  child: Text(context.l10n.friendChallengePlayButton),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
