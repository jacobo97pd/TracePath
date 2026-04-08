import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'leaderboard_service.dart';
import 'l10n/l10n.dart';
import 'services/friends_ranking_service.dart';
import 'ui/components/friends_ranking_list.dart';
import 'ui/components/game_card.dart';

class PuzzleLeaderboardScreen extends StatefulWidget {
  const PuzzleLeaderboardScreen({
    super.key,
    required this.packId,
    required this.levelIndex,
    required this.leaderboardService,
  });

  final String packId;
  final int levelIndex;
  final LeaderboardService leaderboardService;

  @override
  State<PuzzleLeaderboardScreen> createState() => _PuzzleLeaderboardScreenState();
}

class _PuzzleLeaderboardScreenState extends State<PuzzleLeaderboardScreen> {
  final FriendsRankingService _friendsRankingService = FriendsRankingService();
  late Future<List<FriendsRankingRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = _friendsRankingService.loadForLevel(_levelId);
  }

  String get _levelId => '${widget.packId}_${widget.levelIndex}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Text(
          l10n.leaderboardFriendsTitleWithLevel(widget.levelIndex),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/play/${widget.packId}');
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          children: [
            GameCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.leaderboardFriendsTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.leaderboardLevelPack(
                      widget.levelIndex,
                      widget.packId,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF9EB0D2),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FriendsRankingList(
                    future: _future,
                    currentUid: currentUid,
                    emptyText: l10n.leaderboardNoFriendsScores,
                    errorText: l10n.leaderboardUnavailable,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

