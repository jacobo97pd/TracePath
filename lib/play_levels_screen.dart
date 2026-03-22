import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'coins_service.dart';
import 'pack_level_repository.dart';
import 'progress_service.dart';
import 'ui/components/coin_display.dart';

class _WorldTabOption {
  const _WorldTabOption({
    required this.packId,
    required this.title,
    required this.subtitle,
  });

  final String packId;
  final String title;
  final String subtitle;
}

const List<_WorldTabOption> _worldTabs = <_WorldTabOption>[
  _WorldTabOption(
    packId: 'world_01',
    title: 'W1 Forest',
    subtitle: 'Gentle opener',
  ),
  _WorldTabOption(
    packId: 'world_02',
    title: 'W2 Coast',
    subtitle: 'Clean flows',
  ),
  _WorldTabOption(
    packId: 'world_03',
    title: 'W3 Dunes',
    subtitle: 'Longer reads',
  ),
  _WorldTabOption(
    packId: 'world_04',
    title: 'W4 Grove',
    subtitle: 'Tighter turns',
  ),
  _WorldTabOption(
    packId: 'world_05',
    title: 'W5 Peaks',
    subtitle: 'Steeper climb',
  ),
  _WorldTabOption(
    packId: 'world_06',
    title: 'W6 Neon',
    subtitle: 'Variant hints',
  ),
  _WorldTabOption(
    packId: 'world_07',
    title: 'W7 Echo',
    subtitle: 'False comfort',
  ),
  _WorldTabOption(
    packId: 'world_08',
    title: 'W8 Tundra',
    subtitle: 'Cool precision',
  ),
  _WorldTabOption(
    packId: 'world_09',
    title: 'W9 Ember',
    subtitle: 'Hot rhythm',
  ),
  _WorldTabOption(
    packId: 'world_10',
    title: 'W10 Ruins',
    subtitle: 'Dense layouts',
  ),
  _WorldTabOption(
    packId: 'world_11',
    title: 'W11 Vault',
    subtitle: 'Careful reads',
  ),
  _WorldTabOption(
    packId: 'world_12',
    title: 'W12 Orbit',
    subtitle: 'Mixed rules',
  ),
  _WorldTabOption(
    packId: 'world_13',
    title: 'W13 Rift',
    subtitle: 'Hard pivots',
  ),
  _WorldTabOption(
    packId: 'world_14',
    title: 'W14 Tempest',
    subtitle: 'Faster thinking',
  ),
  _WorldTabOption(
    packId: 'world_15',
    title: 'W15 Obsidian',
    subtitle: 'Heavy pressure',
  ),
  _WorldTabOption(
    packId: 'world_16',
    title: 'W16 Zenith',
    subtitle: 'Late game mix',
  ),
  _WorldTabOption(
    packId: 'world_17',
    title: 'W17 Crown',
    subtitle: 'Final challenge',
  ),
];

class PlayLevelsScreen extends StatefulWidget {
  const PlayLevelsScreen({
    super.key,
    required this.progressService,
    required this.coinsService,
    this.packId = 'world_01',
  });

  final ProgressService progressService;
  final CoinsService coinsService;
  final String packId;

  @override
  State<PlayLevelsScreen> createState() => _PlayLevelsScreenState();
}

class _PlayLevelsScreenState extends State<PlayLevelsScreen>
    with SingleTickerProviderStateMixin {
  double get _mapRowExtent => _compact ? 92 : 112;
  bool get _compact => _screenWidth < 390;
  double _screenWidth = 390;

  final ScrollController _mapScrollController = ScrollController();
  final ScrollController _chipScrollController = ScrollController();

  late final AnimationController _ambientController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);

  int _totalLevels = 0;
  int _selectedLevelIndex = 1;
  PackLevelRecord? _selectedRecord;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPack();
  }

  @override
  void didUpdateWidget(covariant PlayLevelsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packId != widget.packId) {
      _loadPack();
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _mapScrollController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPack() async {
    setState(() {
      _isLoading = true;
    });
    await PackLevelRepository.instance.loadPack(widget.packId);
    final total = await PackLevelRepository.instance.totalLevels(widget.packId);
    final continueIndex = _continueIndex(total);
    final savedCurrent = widget.progressService.getCurrentLevelForPack(
      widget.packId,
      fallback: continueIndex,
    );
    final initialLevel = total <= 0 ? 1 : savedCurrent.clamp(1, total);
    final record =
        await PackLevelRepository.instance.getLevel(widget.packId, initialLevel);
    if (!mounted) return;
    setState(() {
      _totalLevels = total;
      _selectedLevelIndex = initialLevel;
      _selectedRecord = record;
      _isLoading = false;
    });
    _scheduleAutoScroll(initialLevel);
    _scheduleChipReveal();
  }

  int _continueIndex(int total) {
    if (total <= 0) {
      return 1;
    }
    final highestCompleted = _highestSequentialCompleted(total);
    final sequential = math.min(highestCompleted + 1, total);
    return sequential.clamp(1, total);
  }

  int _highestSequentialCompleted(int total) {
    var solved = 0;
    for (var i = 1; i <= total; i++) {
      if (!widget.progressService.isCompleted(widget.packId, i)) {
        break;
      }
      solved = i;
    }
    return solved;
  }

  Future<void> _selectLevel(int levelIndex) async {
    final record =
        await PackLevelRepository.instance.getLevel(widget.packId, levelIndex);
    if (!mounted) return;
    setState(() {
      _selectedLevelIndex = levelIndex;
      _selectedRecord = record;
    });
  }

  void _scheduleAutoScroll(int levelIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_mapScrollController.hasClients) return;
      final target = math.max(0.0, (levelIndex - 1) * _mapRowExtent - 220);
      _mapScrollController.animateTo(
        math.min(target, _mapScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _scheduleChipReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chipScrollController.hasClients) return;
      final worldIndex = _worldTabs.indexWhere((tab) => tab.packId == widget.packId);
      if (worldIndex < 0) return;
      final target = math.max(0.0, worldIndex * 112.0 - 40.0);
      _chipScrollController.animateTo(
        math.min(target, _chipScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _handleNodeTap(int levelIndex, bool unlocked) {
    _selectLevel(levelIndex);
  }

  void _playSelectedLevel() {
    unawaited(
      widget.progressService.setCurrentLevelForPack(
        widget.packId,
        _selectedLevelIndex,
      ),
    );
    context.go('/play/${widget.packId}/$_selectedLevelIndex');
  }

  void _openSelectedLevelRanking() {
    context.push('/leaderboard/${widget.packId}/$_selectedLevelIndex');
  }

  bool _isCompleted(int levelIndex) {
    return widget.progressService.isCompleted(widget.packId, levelIndex);
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    final palette = _paletteForPack(widget.packId);
    final worldInfo = _worldInfoForPack(widget.packId);

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        widget.progressService,
        widget.coinsService,
        _ambientController,
      ]),
      builder: (context, _) {
        final solvedCount = List<int>.generate(_totalLevels, (i) => i + 1)
            .where(_isCompleted)
            .length;
        final continueIndex = _continueIndex(_totalLevels);
        final currentNode = continueIndex;

        return Scaffold(
          backgroundColor: const Color(0xFF08111F),
          body: Stack(
            children: [
              _AmbientBackdrop(
                palette: palette,
                progress: _ambientController.value,
              ),
              SafeArea(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              _compact ? 12 : 16,
                              _compact ? 8 : 10,
                              _compact ? 12 : 16,
                              0,
                            ),
                            child: _WorldHeaderBar(
                              title: worldInfo.title,
                              subtitle:
                                  '${_totalLevels.toString()} levels - $solvedCount completed',
                              coins: widget.coinsService.coins,
                              accent: palette.accent,
                              compact: _compact,
                            ),
                          ),
                          SizedBox(height: _compact ? 10 : 18),
                          _WorldChipSelector(
                            controller: _chipScrollController,
                            tabs: _worldTabs,
                            selectedPackId: widget.packId,
                            onSelected: (packId) => context.go('/play/$packId'),
                            accent: palette.accent,
                            compact: _compact,
                          ),
                          SizedBox(height: _compact ? 10 : 18),
                          Expanded(
                            child: CustomScrollView(
                              controller: _mapScrollController,
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding:
                                      EdgeInsets.symmetric(
                                          horizontal: _compact ? 12 : 16),
                                  sliver: SliverToBoxAdapter(
                                    child: _WorldProgressCard(
                                      title: worldInfo.title,
                                      subtitle: worldInfo.subtitle,
                                      solvedCount: solvedCount,
                                      totalLevels: _totalLevels,
                                      continueIndex: continueIndex,
                                      accent: palette.accent,
                                      compact: _compact,
                                      onContinue: () {
                                        _selectLevel(continueIndex);
                                        _scheduleAutoScroll(continueIndex);
                                      },
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: EdgeInsets.fromLTRB(
                                    _compact ? 12 : 16,
                                    _compact ? 14 : 22,
                                    _compact ? 12 : 16,
                                    _compact ? 150 : 180,
                                  ),
                                  sliver: SliverList.builder(
                                    itemCount: _totalLevels,
                                    itemBuilder: (context, index) {
                                      final levelIndex = index + 1;
                                      final completed = _isCompleted(levelIndex);
                                      final unlocked = levelIndex <= continueIndex;
                                      final isCurrent = levelIndex == currentNode;
                                      final isSelected =
                                          levelIndex == _selectedLevelIndex;
                                      final alignment =
                                          index.isEven ? -0.82 : 0.82;

                                      return SizedBox(
                                        height: _mapRowExtent,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            if (index < _totalLevels - 1)
                                              Positioned.fill(
                                                child: IgnorePointer(
                                                  child: CustomPaint(
                                                    painter: _LevelConnectorPainter(
                                                      startAlignment: alignment,
                                                      endAlignment: index.isEven
                                                          ? 0.82
                                                          : -0.82,
                                                      color: unlocked
                                                          ? palette.line
                                                          : Colors.white
                                                              .withOpacity(0.08),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            Align(
                                              alignment: Alignment(alignment, 0),
                                              child: _LevelMapNode(
                                                levelIndex: levelIndex,
                                                completed: completed,
                                                unlocked: unlocked,
                                                current: isCurrent,
                                                selected: isSelected,
                                                accent: palette.accent,
                                                compact: _compact,
                                                onTap: () => _handleNodeTap(
                                                  levelIndex,
                                                  unlocked,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          bottomNavigationBar: _isLoading
              ? null
              : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: _SelectedLevelCard(
                    record: _selectedRecord,
                    levelIndex: _selectedLevelIndex,
                    accent: palette.accent,
                    canPlay: true,
                    onPlay: _playSelectedLevel,
                    onRanking: _openSelectedLevelRanking,
                    compact: _compact,
                  ),
                ),
        );
      },
    );
  }
}

class _WorldHeaderBar extends StatelessWidget {
  const _WorldHeaderBar({
    required this.title,
    required this.subtitle,
    required this.coins,
    required this.accent,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final int coins;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderIconButton(
          compact: compact,
          onTap: () => context.go('/home'),
        ),
        SizedBox(width: compact ? 10 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 19 : 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.64),
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: compact ? 8 : 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CoinDisplay(coins: coins),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.onTap, required this.compact});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF162235).withOpacity(0.95),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: compact ? 44 : 52,
          height: compact ? 44 : 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _WorldChipSelector extends StatelessWidget {
  const _WorldChipSelector({
    required this.controller,
    required this.tabs,
    required this.selectedPackId,
    required this.onSelected,
    required this.accent,
    required this.compact,
  });

  final ScrollController controller;
  final List<_WorldTabOption> tabs;
  final String selectedPackId;
  final ValueChanged<String> onSelected;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 62 : 76,
      child: ListView.separated(
        controller: controller,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = tab.packId == selectedPackId;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        accent.withOpacity(0.95),
                        accent.withOpacity(0.62),
                      ],
                    )
                  : null,
              color: selected ? null : const Color(0xFF152234),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? Colors.white.withOpacity(0.16)
                    : Colors.white.withOpacity(0.08),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withOpacity(0.26),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelected(tab.packId),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: compact ? 10 : 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tab.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 12 : 14,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tab.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(selected ? 0.84 : 0.56),
                        fontSize: compact ? 10 : 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: tabs.length,
      ),
    );
  }
}

class _WorldProgressCard extends StatelessWidget {
  const _WorldProgressCard({
    required this.title,
    required this.subtitle,
    required this.solvedCount,
    required this.totalLevels,
    required this.continueIndex,
    required this.accent,
    required this.compact,
    required this.onContinue,
  });

  final String title;
  final String subtitle;
  final int solvedCount;
  final int totalLevels;
  final int continueIndex;
  final Color accent;
  final bool compact;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final progress = totalLevels == 0 ? 0.0 : solvedCount / totalLevels;
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xE622324B),
            Color(0xE0141E2E),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 17 : 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: compact ? 2 : 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.66),
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _MiniStatPill(
                icon: Icons.check_circle_outline_rounded,
                label: '$solvedCount / $totalLevels',
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: compact ? 12 : 14,
              color: Colors.white.withOpacity(0.06),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: progress),
                builder: (context, value, _) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent.withOpacity(0.95),
                              Colors.white.withOpacity(0.92),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$solvedCount completed - ${math.max(totalLevels - solvedCount, 0)} to go',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0A1220),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 16,
                    vertical: compact ? 11 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: Icon(Icons.play_arrow_rounded, size: compact ? 16 : 18),
                label: Text('Continue L$continueIndex'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStatPill extends StatelessWidget {
  const _MiniStatPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.88), size: 15),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelMapNode extends StatelessWidget {
  const _LevelMapNode({
    required this.levelIndex,
    required this.completed,
    required this.unlocked,
    required this.current,
    required this.selected,
    required this.accent,
    required this.compact,
    required this.onTap,
  });

  final int levelIndex;
  final bool completed;
  final bool unlocked;
  final bool current;
  final bool selected;
  final Color accent;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = unlocked ? const Color(0xFF1A2840) : const Color(0xFF111A29);
    final glowColor = completed ? const Color(0xFF38D996) : accent;

    final node = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: selected ? (compact ? 80 : 96) : (compact ? 72 : 84),
      height: selected ? (compact ? 80 : 96) : (compact ? 72 : 84),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: unlocked
              ? <Color>[
                  glowColor.withOpacity(current ? 0.28 : 0.18),
                  base,
                ]
              : <Color>[
                  const Color(0xFF1A2433),
                  base,
                ],
        ),
        border: Border.all(
          color: completed
              ? const Color(0xFF4AF0A9)
              : unlocked
                  ? Colors.white.withOpacity(selected ? 0.42 : 0.18)
                  : Colors.white.withOpacity(0.08),
          width: selected ? 2.2 : 1.2,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(current ? 0.32 : 0.14),
                  blurRadius: current ? 26 : 16,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (current)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.92, end: 1.08),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withOpacity(0.20),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                completed
                    ? Icons.check_rounded
                    : unlocked
                        ? Icons.radio_button_checked_rounded
                        : Icons.lock_rounded,
                color: completed
                    ? Colors.white
                    : unlocked
                        ? Colors.white.withOpacity(0.92)
                        : Colors.white.withOpacity(0.36),
                size: completed ? 22 : 18,
              ),
              const SizedBox(height: 4),
              Text(
                '$levelIndex',
                style: TextStyle(
                  color: unlocked
                      ? Colors.white
                      : Colors.white.withOpacity(0.38),
                  fontSize: selected
                      ? (compact ? 16 : 19)
                      : (compact ? 14 : 17),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: node,
        ),
      ),
    );
  }
}

class _SelectedLevelCard extends StatelessWidget {
  const _SelectedLevelCard({
    required this.record,
    required this.levelIndex,
    required this.accent,
    required this.canPlay,
    required this.onPlay,
    required this.onRanking,
    required this.compact,
  });

  final PackLevelRecord? record;
  final int levelIndex;
  final Color accent;
  final bool canPlay;
  final VoidCallback? onPlay;
  final VoidCallback onRanking;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final level = record?.level;
    final difficultyLabel = _difficultyLabel(record?.difficultyTag);
    final variant = _variantLabel(level?.id);
    final sizeLabel = level == null ? '--' : '${level.width}x${level.height}';

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xF0192435),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: accent.withOpacity(0.14),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 48 : 58,
            height: compact ? 48 : 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withOpacity(0.95),
                  accent.withOpacity(0.55),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              'L$levelIndex',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 16 : 18,
              ),
            ),
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selected Level',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.56),
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: compact ? 2 : 4),
                Text(
                  'Level $levelIndex • $variant',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(label: sizeLabel),
                    _MetaChip(label: difficultyLabel),
                    if (record != null) _MetaChip(label: variant),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: onPlay,
                style: FilledButton.styleFrom(
                  backgroundColor: canPlay ? Colors.white : Colors.white24,
                  foregroundColor:
                      canPlay ? const Color(0xFF0A1220) : Colors.white70,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(canPlay ? 'Play' : 'Locked'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onRanking,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.26)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Ranking'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LevelConnectorPainter extends CustomPainter {
  _LevelConnectorPainter({
    required this.startAlignment,
    required this.endAlignment,
    required this.color,
  });

  final double startAlignment;
  final double endAlignment;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final start = Offset(
      size.width * ((startAlignment + 1) / 2),
      30,
    );
    final end = Offset(
      size.width * ((endAlignment + 1) / 2),
      size.height - 18,
    );
    final control1 = Offset(start.dx, size.height * 0.34);
    final control2 = Offset(end.dx, size.height * 0.66);

    path.moveTo(start.dx, start.dy);
    path.cubicTo(
      control1.dx,
      control1.dy,
      control2.dx,
      control2.dy,
      end.dx,
      end.dy,
    );

    canvas.drawPath(path, paint);
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(covariant _LevelConnectorPainter oldDelegate) {
    return oldDelegate.startAlignment != startAlignment ||
        oldDelegate.endAlignment != endAlignment ||
        oldDelegate.color != color;
  }
}

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop({
    required this.palette,
    required this.progress,
  });

  final _WorldPalette palette;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final drift = (progress - 0.5) * 36;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: palette.background,
            ),
          ),
        ),
        Positioned(
          top: -80 + drift,
          left: -40,
          child: _BlurOrb(color: palette.accent.withOpacity(0.18), size: 220),
        ),
        Positioned(
          top: 180 - drift,
          right: -60,
          child: _BlurOrb(color: palette.secondary.withOpacity(0.15), size: 240),
        ),
        Positioned(
          bottom: 70 + drift,
          left: 40,
          child: _BlurOrb(color: Colors.white.withOpacity(0.05), size: 180),
        ),
      ],
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.42,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}

class _WorldInfo {
  const _WorldInfo({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class _WorldPalette {
  const _WorldPalette({
    required this.background,
    required this.accent,
    required this.secondary,
    required this.line,
  });

  final List<Color> background;
  final Color accent;
  final Color secondary;
  final Color line;
}

_WorldInfo _worldInfoForPack(String packId) {
  final index = _worldTabs.indexWhere((tab) => tab.packId == packId);
  if (index < 0) {
    return const _WorldInfo(
      title: 'World',
      subtitle: 'Puzzle journey',
    );
  }
  final tab = _worldTabs[index];
  return _WorldInfo(
    title: tab.title.replaceFirst('W${index + 1} ', 'World ${index + 1} - '),
    subtitle: tab.subtitle,
  );
}

_WorldPalette _paletteForPack(String packId) {
  final index = math.max(0, _worldTabs.indexWhere((tab) => tab.packId == packId));
  const accents = <Color>[
    Color(0xFF6EE7FF),
    Color(0xFF71D7FF),
    Color(0xFF67DFA8),
    Color(0xFF88D56B),
    Color(0xFFFFC56B),
    Color(0xFFFF8D72),
    Color(0xFFFF73B2),
    Color(0xFF9F88FF),
    Color(0xFF718BFF),
    Color(0xFF5FD4FF),
    Color(0xFF54E0CE),
    Color(0xFFFFC46C),
    Color(0xFFFF9B7D),
    Color(0xFFFF7AE7),
    Color(0xFF9D86FF),
    Color(0xFF6AA8FF),
    Color(0xFFE9C46A),
  ];
  final accent = accents[index % accents.length];
  return _WorldPalette(
    background: <Color>[
      Color.lerp(const Color(0xFF08111F), accent, 0.08)!,
      const Color(0xFF0A1220),
      const Color(0xFF07101D),
    ],
    accent: accent,
    secondary: Color.lerp(accent, Colors.white, 0.35)!,
    line: accent.withOpacity(0.7),
  );
}

String _difficultyLabel(String? difficultyTag) {
  switch (difficultyTag) {
    case 'd1':
      return 'Warm-up';
    case 'd2':
      return 'Easy';
    case 'd3':
      return 'Medium';
    case 'd4':
      return 'Hard';
    case 'd5':
      return 'Expert';
    default:
      return 'Classic';
  }
}

String _variantLabel(String? levelId) {
  final id = (levelId ?? '').toLowerCase();
  if (id.contains('multiples_roman') || id.contains('multiples-roman')) {
    return 'Multiples Roman';
  }
  if (id.contains('alphabet_reverse') || id.contains('alphabet-reverse')) {
    return 'Alphabet Reverse';
  }
  if (id.contains('alphabet')) {
    return 'Alphabet';
  }
  if (id.contains('multiples')) {
    return 'Multiples';
  }
  if (id.contains('roman')) {
    return 'Roman';
  }
  return 'Classic';
}
