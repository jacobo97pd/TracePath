import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'coins_service.dart';
import 'pack_level_repository.dart';
import 'progress_service.dart';
import 'ui/components/coin_display.dart';
import 'ui/components/game_button.dart';
import 'ui/components/game_card.dart';
import 'ui/components/section_header.dart';

class _PackTabOption {
  const _PackTabOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class PlayLevelsScreen extends StatefulWidget {
  const PlayLevelsScreen({
    super.key,
    required this.progressService,
    required this.coinsService,
    this.packId = 'all',
  });

  final ProgressService progressService;
  final CoinsService coinsService;
  final String packId;

  @override
  State<PlayLevelsScreen> createState() => _PlayLevelsScreenState();
}

class _PlayLevelsScreenState extends State<PlayLevelsScreen> {
  static const String _firestoreDatabaseId = 'tracepath-database';
  static const List<_PackTabOption> _packTabs = <_PackTabOption>[
    _PackTabOption(id: 'all', label: 'General'),
    _PackTabOption(id: 'linkedin', label: 'LinkedIn'),
    _PackTabOption(id: 'linkedin_editor', label: 'Editor'),
    _PackTabOption(id: 'linkedin_js_generated', label: 'JS Generated'),
    _PackTabOption(id: 'bulk_variant_100', label: 'Variants 100'),
    _PackTabOption(id: 'bulk_variant_200', label: 'Variants 200'),
  ];
  static const double _mapNodeExtent = 122;

  final ScrollController _mapScrollController = ScrollController();

  int? _count;
  Set<int> _remoteCompleted = <int>{};
  int? _lastAutoScrollTarget;

  @override
  void initState() {
    super.initState();
    _load();
    _syncRemoteCompletedLevels();
  }

  @override
  void didUpdateWidget(covariant PlayLevelsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packId != widget.packId) {
      _count = null;
      _lastAutoScrollTarget = null;
      _load();
      _syncRemoteCompletedLevels();
    }
  }

  @override
  void dispose() {
    _mapScrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final total = await PackLevelRepository.instance.totalLevels(widget.packId);
    if (!mounted) return;
    setState(() {
      _count = total;
    });
  }

  Future<void> _syncRemoteCompletedLevels() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _remoteCompleted = <int>{};
        });
      }
      return;
    }
    try {
      final snap = await _db()
          .collection('users')
          .doc(uid)
          .collection('completed_levels')
          .get();
      final next = <int>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final levelId = (data['levelId'] as String?)?.trim().isNotEmpty == true
            ? (data['levelId'] as String).trim()
            : doc.id.trim();
        final parsed = _parseLevelIndexForPack(levelId, widget.packId);
        if (parsed != null) {
          next.add(parsed);
          if (!widget.progressService.isCompleted(widget.packId, parsed)) {
            await widget.progressService.markCompleted(widget.packId, parsed);
          }
        }
      }
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
          '[play] remote completed ids pack=${widget.packId} count=${next.length} ids=${next.toList()..sort()}',
        );
      }
      setState(() {
        _remoteCompleted = next;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[play] failed to sync completed_levels for ${widget.packId}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _count;
    if (total == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (total <= 0) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: Text('No levels available')),
      );
    }
    return AnimatedBuilder(
      animation: widget.progressService,
      builder: (context, _) {
        var solved = 0;
        for (var i = 1; i <= total; i++) {
          if (_isCompleted(i)) {
            solved++;
          }
        }
        final highestCompletedLevel = _highestSequentialCompleted(total);
        final continueIndex =
            highestCompletedLevel >= total ? total : (highestCompletedLevel + 1);
        _scheduleAutoScroll(continueIndex);
        final progress = total <= 0 ? 0.0 : (solved / total).clamp(0.0, 1.0);
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            title: Text(_activePackTab?.label ?? 'Levels'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: CoinDisplay(
                    coins: widget.coinsService.coins,
                    onTap: () => context.go('/shop'),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _packTabs.map((option) {
                    final selected = option.id == widget.packId;
                    return ChoiceChip(
                      label: Text(option.label),
                      selected: selected,
                      selectedColor: const Color(0xFF243044),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : const Color(0xFFADBBD8),
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => context.go('/play/${option.id}'),
                    );
                  }).toList(growable: false),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: GameCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Pack Progress'),
                      const SizedBox(height: 6),
                      Text(
                        '$solved / $total solved · ${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: Color(0xFF9DAECC),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 9,
                          value: progress,
                          backgroundColor: const Color(0xFF1A2438),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF4F8BFF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GameButton(
                        label: 'Continue from Level $continueIndex',
                        icon: Icons.play_arrow_rounded,
                        expanded: true,
                        onTap: () => context.go('/play/${widget.packId}/$continueIndex'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: _mapScrollController,
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
                  itemCount: total,
                  itemBuilder: (context, index) {
                    final levelIndex = index + 1;
                    final completed = _isCompleted(levelIndex);
                    final isCurrent = !completed && levelIndex == continueIndex;
                    final unlocked = completed || isCurrent;
                    final hasNext = levelIndex < total;
                    final align = _nodeAlignment(index);
                    final nextAlign = hasNext ? _nodeAlignment(index + 1) : align;
                    return _MapLevelNode(
                      levelNumber: levelIndex,
                      completed: completed,
                      unlocked: unlocked,
                      isCurrent: isCurrent,
                      alignmentX: align,
                      nextAlignmentX: nextAlign,
                      drawConnector: hasNext,
                      onTap: () => _handleLevelTap(levelIndex, unlocked),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _nodeAlignment(int index) {
    const pattern = <double>[0.2, 0.76, 0.34, 0.68];
    return pattern[index % pattern.length];
  }

  void _scheduleAutoScroll(int continueIndex) {
    if (_lastAutoScrollTarget == continueIndex) return;
    _lastAutoScrollTarget = continueIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapScrollController.hasClients) return;
      final position = _mapScrollController.position;
      final target = math.max(
        0.0,
        ((continueIndex - 1) * _mapNodeExtent) - (position.viewportDimension * 0.34),
      );
      final clamped = target.clamp(0.0, position.maxScrollExtent);
      _mapScrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  int _highestSequentialCompleted(int total) {
    var highest = 0;
    for (var i = 1; i <= total; i++) {
      if (_isCompleted(i)) {
        highest = i;
      } else {
        break;
      }
    }
    return highest;
  }

  void _handleLevelTap(int levelIndex, bool unlocked) {
    if (!unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Level locked'),
          duration: Duration(milliseconds: 1100),
        ),
      );
      return;
    }
    context.go('/play/${widget.packId}/$levelIndex');
  }

  bool _isCompleted(int levelIndex) {
    return widget.progressService.isCompleted(widget.packId, levelIndex) ||
        _remoteCompleted.contains(levelIndex);
  }

  int? _parseLevelIndexForPack(String levelId, String packId) {
    final trimmed = levelId.trim();
    if (trimmed.isEmpty) return null;
    if (!trimmed.startsWith('${packId}_')) return null;
    final match = RegExp(r'^(.*)_(\d+)$').firstMatch(trimmed);
    if (match == null) return null;
    if (match.group(1) != packId) return null;
    return int.tryParse(match.group(2)!);
  }

  FirebaseFirestore _db() {
    try {
      return FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: _firestoreDatabaseId,
      );
    } catch (_) {
      return FirebaseFirestore.instance;
    }
  }

  _PackTabOption? get _activePackTab {
    for (final option in _packTabs) {
      if (option.id == widget.packId) return option;
    }
    return null;
  }
}

class _MapLevelNode extends StatelessWidget {
  const _MapLevelNode({
    required this.levelNumber,
    required this.completed,
    required this.unlocked,
    required this.isCurrent,
    required this.alignmentX,
    required this.nextAlignmentX,
    required this.drawConnector,
    required this.onTap,
  });

  final int levelNumber;
  final bool completed;
  final bool unlocked;
  final bool isCurrent;
  final double alignmentX;
  final double nextAlignmentX;
  final bool drawConnector;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = !unlocked
        ? const Color(0xFF121A29)
        : (isCurrent ? const Color(0xFF213457) : const Color(0xFF1A2438));
    final border = !unlocked
        ? const Color(0xFF2A3345)
        : (isCurrent ? const Color(0xFF66A3FF) : const Color(0xFF334661));
    final titleColor = !unlocked
        ? const Color(0xFF667890)
        : Colors.white;
    final subtitleColor = !unlocked
        ? const Color(0xFF5F6D83)
        : const Color(0xFFA8BCDA);
    final iconColor = completed
        ? const Color(0xFF45D98A)
        : (isCurrent ? const Color(0xFF8BC2FF) : const Color(0xFFADBBD8));
    final status = !unlocked
        ? 'Locked'
        : (completed ? 'Done' : (isCurrent ? 'Play' : 'Open'));
    final icon = !unlocked
        ? Icons.lock_rounded
        : (completed ? Icons.check_circle_rounded : Icons.play_arrow_rounded);

    return SizedBox(
      height: 122,
      child: Stack(
        children: [
          if (drawConnector)
            Positioned.fill(
              top: 58,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _MapConnectorPainter(
                    startX: alignmentX,
                    endX: nextAlignmentX,
                    active: completed || isCurrent,
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment((alignmentX * 2) - 1, -0.4),
            child: AnimatedScale(
              scale: isCurrent ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: unlocked ? onTap : null,
                  child: Container(
                    width: isCurrent ? 170 : 156,
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border, width: isCurrent ? 1.6 : 1.2),
                      boxShadow: [
                        if (isCurrent)
                          const BoxShadow(
                            color: Color(0x443C8CFF),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: Offset(0, 8),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0D1525),
                            border: Border.all(
                              color: iconColor.withOpacity(0.7),
                            ),
                          ),
                          child: Icon(icon, size: 20, color: iconColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Level $levelNumber',
                                style: TextStyle(
                                  color: titleColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                status,
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapConnectorPainter extends CustomPainter {
  const _MapConnectorPainter({
    required this.startX,
    required this.endX,
    required this.active,
  });

  final double startX;
  final double endX;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    const yTop = 0.0;
    final yBottom = size.height;
    final x1 = startX * size.width;
    final x2 = endX * size.width;
    final midY = size.height * 0.54;
    final controlOffset = (x2 - x1) * 0.38;

    final path = Path()
      ..moveTo(x1, yTop)
      ..cubicTo(
        x1 + controlOffset,
        midY * 0.36,
        x2 - controlOffset,
        midY * 0.88,
        x2,
        yBottom,
      );

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = active ? 2.8 : 2.0
      ..color = active
          ? const Color(0xFF4F8BFF).withOpacity(0.72)
          : const Color(0xFF334661).withOpacity(0.62);
    canvas.drawPath(path, stroke);

    if (active) {
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 7.0
        ..color = const Color(0xFF4F8BFF).withOpacity(0.11)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.5);
      canvas.drawPath(path, glow);
    }
  }

  @override
  bool shouldRepaint(covariant _MapConnectorPainter oldDelegate) {
    return oldDelegate.startX != startX ||
        oldDelegate.endX != endX ||
        oldDelegate.active != active;
  }
}
