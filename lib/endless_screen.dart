import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'progress_service.dart';
import 'stats_service.dart';

class EndlessScreen extends StatelessWidget {
  const EndlessScreen({
    super.key,
    required this.progressService,
    required this.statsService,
  });

  final ProgressService progressService;
  final StatsService statsService;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([progressService, statsService]),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Endless')),
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) {
              final difficulty = index + 1;
              final hasRun = progressService.getEndlessRunSeed(difficulty) != null;
              final currentIndex = progressService.getEndlessRunIndex(difficulty);
              final best = statsService.endlessBestForDifficulty(difficulty);
              final bestIndex = best.bestIndexReached;
              final bestScore = best.bestScore;
              final bestAvgMs = best.bestAvgTimeMs;

              return Card(
                child: ListTile(
                  title: Text('Difficulty $difficulty'),
                  isThreeLine: true,
                  trailing: hasRun
                      ? TextButton(
                          onPressed: () async {
                            await progressService.restartEndlessRun(difficulty);
                            if (!context.mounted) {
                              return;
                            }
                            context.go('/endless/$difficulty/1');
                          },
                          child: const Text('New'),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minVerticalPadding: 10,
                  dense: false,
                  subtitleTextStyle: Theme.of(context).textTheme.bodyMedium,
                  visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasRun
                            ? 'Resume at $currentIndex'
                            : 'Start a new endless run',
                      ),
                      Text(
                        'Best score: $bestScore | Best index: $bestIndex${bestAvgMs == null ? '' : ' | Best avg: ${_formatMs(bestAvgMs.round())}'}',
                      ),
                    ],
                  ),
                  onTap: () async {
                    final startIndex = progressService.getEndlessRunSeed(difficulty) == null
                        ? 1
                        : progressService.getEndlessRunIndex(difficulty);
                    await progressService.ensureEndlessRun(difficulty);
                    if (!context.mounted) {
                      return;
                    }
                    context.go('/endless/$difficulty/$startIndex');
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  static String _formatMs(int? ms) {
    if (ms == null || ms <= 0) {
      return '--';
    }
    final totalSeconds = (ms / 1000).round();
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
