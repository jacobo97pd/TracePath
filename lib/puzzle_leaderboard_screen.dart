import 'package:flutter/material.dart';

import 'leaderboard_service.dart';
import 'puzzle_attempt.dart';

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
  late Future<List<PuzzleAttempt>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.leaderboardService.getPuzzleLeaderboard(
      widget.packId,
      widget.levelIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leaderboard ${widget.packId} #${widget.levelIndex}'),
      ),
      body: FutureBuilder<List<PuzzleAttempt>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final attempts = snapshot.data!;
          if (attempts.isEmpty) {
            return const Center(child: Text('No attempts yet'));
          }

          final personalAttempts = attempts.where((a) => a.playerName == 'You').toList();
          final personalBestRunId =
              personalAttempts.isEmpty ? null : personalAttempts.first.runId;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: attempts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              final rank = _rankAtIndexByTime(
                attempts.map((a) => a.timeMs).toList(growable: false),
                index,
              );
              final isTop1 = rank == 1;
              final isPersonalBest =
                  personalBestRunId != null && attempt.runId == personalBestRunId;
              return Card(
                color: isTop1
                    ? Colors.amber.withOpacity(0.12)
                    : isPersonalBest
                        ? Colors.blue.withOpacity(0.08)
                        : null,
                child: ListTile(
                  leading: Text(
                    '#$rank',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  title: Text(_formatMs(attempt.timeMs)),
                  subtitle: Text(
                    'h:${attempt.hintsUsed}  r:${attempt.rewindsUsed}  '
                    '${_formatDate(attempt.createdAtIso)}'
                    '${attempt.score == null ? '' : '  s:${attempt.score}'}',
                  ),
                  trailing: isTop1
                      ? const Icon(Icons.emoji_events_outlined)
                      : isPersonalBest
                          ? const Icon(Icons.person)
                          : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatMs(int ms) {
    final seconds = (ms / 1000).round();
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) {
      return iso;
    }
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  int _rankAtIndexByTime(List<int> timesMs, int index) {
    if (index <= 0) return 1;
    var rank = index + 1;
    for (var j = index - 1; j >= 0; j--) {
      if (timesMs[j] == timesMs[index]) {
        rank = j + 1;
      } else {
        break;
      }
    }
    return rank;
  }
}
