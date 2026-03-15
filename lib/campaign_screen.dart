import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_data.dart';
import 'progress_service.dart';

const _packDescriptions = <String, String>{
  'classic': 'Balanced introduction',
  'architect': 'More walls and tighter planning',
  'expert': 'Larger boards and harder routes',
};

class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key, required this.progressService});

  final ProgressService progressService;

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  late Future<List<_PackTileModel>> _packsFuture;

  @override
  void initState() {
    super.initState();
    widget.progressService.addListener(_reloadPackStates);
    _packsFuture = _loadPackStates();
    assert(() {
      debugPrint('[Campaign] initState');
      return true;
    }());
  }

  @override
  void didUpdateWidget(covariant CampaignScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progressService == widget.progressService) {
      return;
    }
    oldWidget.progressService.removeListener(_reloadPackStates);
    widget.progressService.addListener(_reloadPackStates);
    _reloadPackStates();
  }

  @override
  void dispose() {
    widget.progressService.removeListener(_reloadPackStates);
    super.dispose();
  }

  void _reloadPackStates() {
    if (!mounted) {
      return;
    }
    setState(() {
      _packsFuture = _loadPackStates();
    });
  }

  Future<List<_PackTileModel>> _loadPackStates() async {
    assert(() {
      debugPrint('[Campaign] load start');
      return true;
    }());
    await Future<void>.delayed(Duration.zero);

    final items = appPacks.map((pack) {
      final unlocked = widget.progressService.isPackUnlocked(pack.id);
      final description = _packDescriptions[pack.id] ?? '';
      final requirement =
          widget.progressService.packUnlockRequirementText(pack.id);
      final subtitle = unlocked ? description : '$description\n$requirement';
      return _PackTileModel(
        packId: pack.id,
        unlocked: unlocked,
        subtitle: subtitle,
      );
    }).toList(growable: false);

    assert(() {
      debugPrint('[Campaign] load complete count=${items.length}');
      return true;
    }());
    return items;
  }

  @override
  Widget build(BuildContext context) {
    assert(() {
      debugPrint('[Campaign] build');
      return true;
    }());
    return Scaffold(
      appBar: AppBar(title: const Text('Campaign')),
      body: FutureBuilder<List<_PackTileModel>>(
        future: _packsFuture.timeout(const Duration(seconds: 3)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appPacks.length,
              itemBuilder: (context, index) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.grid_view_rounded),
                    title: Text('Loading...'),
                    subtitle: Text('Preparing pack status'),
                  ),
                );
              },
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load campaign packs.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reloadPackStates,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final packs = snapshot.data ?? const <_PackTileModel>[];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: packs.length,
            itemBuilder: (context, index) {
              final pack = packs[index];
              return Card(
                child: ListTile(
                  leading: Icon(pack.unlocked ? Icons.lock_open : Icons.lock),
                  title: Text(
                    _titleCase(pack.packId),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    pack.subtitle,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: pack.unlocked ? 14 : 13,
                      height: 1.35,
                    ),
                  ),
                  onTap: pack.unlocked
                      ? () {
                          assert(() {
                            debugPrint('[Campaign] tap pack=${pack.packId}');
                            return true;
                          }());
                          context.go('/pack/${pack.packId}');
                        }
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _PackTileModel {
  const _PackTileModel({
    required this.packId,
    required this.unlocked,
    required this.subtitle,
  });

  final String packId;
  final bool unlocked;
  final String subtitle;
}
