import 'package:flutter/material.dart';

class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.levelNumber,
    required this.completed,
    required this.unlocked,
    required this.onTap,
    this.bestTime,
  });

  final int levelNumber;
  final bool completed;
  final bool unlocked;
  final VoidCallback onTap;
  final String? bestTime;

  @override
  Widget build(BuildContext context) {
    final bg = unlocked ? const Color(0xFF151D2A) : const Color(0xFF0E131C);
    final border = unlocked ? const Color(0xFF2E3D57) : const Color(0xFF232A36);
    final fg = unlocked ? Colors.white : const Color(0xFF717D93);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: unlocked ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '#$levelNumber',
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    completed
                        ? Icons.check_circle_rounded
                        : (unlocked ? Icons.play_circle_fill_rounded : Icons.lock_rounded),
                    color: completed ? const Color(0xFF45D98A) : fg,
                    size: 18,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                unlocked ? (bestTime ?? '--:--') : 'Locked',
                style: TextStyle(
                  color: fg.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

