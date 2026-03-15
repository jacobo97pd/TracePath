import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_data.dart';
import 'progress_service.dart';

class LevelsScreen extends StatelessWidget {
  const LevelsScreen({
    super.key,
    required this.packId,
    required this.progressService,
  });

  final String packId;
  final ProgressService progressService;

  @override
  Widget build(BuildContext context) {
    if (getPackById(packId) == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Pack not found')),
      );
    }
    if (!progressService.isPackUnlocked(packId)) {
      return Scaffold(
        appBar: AppBar(title: Text('$packId levels')),
        body: Center(
          child: Text(progressService.packUnlockRequirementText(packId)),
        ),
      );
    }

    return AnimatedBuilder(
      animation: progressService,
      builder: (context, child) {
        var nextLevel = 1;
        for (var i = 1; i <= displayedLevelCount; i++) {
          if (!progressService.isCompleted(packId, i)) {
            nextLevel = i;
            break;
          }
          if (i == displayedLevelCount) {
            nextLevel = displayedLevelCount;
          }
        }
        final solvedCount = List<int>.generate(displayedLevelCount, (i) => i + 1)
            .where((i) => progressService.isCompleted(packId, i))
            .length;
        return Scaffold(
          appBar: AppBar(
            title: Text('${_titleCase(packId)} Levels'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    '$solvedCount/$displayedLevelCount',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          body: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: displayedLevelCount,
            itemBuilder: (context, index) {
              final levelIndex = index + 1;
              final completed = progressService.isCompleted(packId, levelIndex);
              final isNext = levelIndex == nextLevel;
              final borderColor = Theme.of(context).dividerColor;
              final fg = Theme.of(context).colorScheme.onSurface;

              return Stack(
                children: [
                  Positioned.fill(
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      shape: CircleBorder(
                        side: BorderSide(
                          color: borderColor,
                          width: isNext ? 1.8 : 1,
                        ),
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.go('/game/$packId/$levelIndex'),
                        child: Center(
                          child: Text(
                            levelIndex.toString(),
                            style: TextStyle(
                              color: fg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (completed)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: fg.withOpacity(0.85),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}
