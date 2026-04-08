import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'curation/batch_detector.dart';
import 'curation/batch_models.dart';
import 'curation/batch_session_store.dart';
import 'curation/curation_validator.dart';
import 'curation/file_download.dart';
import 'engine/level.dart';

class CurateBatchScreen extends StatefulWidget {
  const CurateBatchScreen({super.key});

  @override
  State<CurateBatchScreen> createState() => _CurateBatchScreenState();
}

enum _EditorMode { clues, walls }

class _CurateBatchScreenState extends State<CurateBatchScreen> {
  final BatchAutoDetector _detector = const BatchAutoDetector();
  final BatchSessionStore _store = const BatchSessionStore();
  final CurationValidator _validator = const CurationValidator();

  List<CurationBatchItem> _items = <CurationBatchItem>[];
  int _selectedIndex = -1;
  BatchItemStatus? _statusFilter;
  _EditorMode _mode = _EditorMode.clues;
  bool _numberingMode = true;
  bool _eraseClue = false;
  int _currentNumber = 1;
  String _digitBuffer = '';
  DateTime? _lastDigitAt;
  bool _busy = false;
  int _detectDone = 0;
  int _detectTotal = 0;

  final Map<String, List<List<CurationClue>>> _undoStacks =
      <String, List<List<CurationClue>>>{};

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final loaded = await _store.load();
    if (!mounted) return;
    setState(() {
      _items = loaded;
      _selectedIndex = loaded.isEmpty ? -1 : 0;
    });
  }

  Future<void> _persist() => _store.save(_items);

  CurationBatchItem? get _selected {
    if (_selectedIndex < 0 || _selectedIndex >= _items.length) {
      return null;
    }
    return _items[_selectedIndex];
  }

  Future<void> _importScreenshots() async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final next = List<CurationBatchItem>.from(_items);
      final now = DateTime.now().millisecondsSinceEpoch;
      final pendingIndexes = <int>[];
      for (var i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        final bytes = file.bytes;
        if (bytes == null) continue;
        final id = 'batch-$now-$i';
        next.add(
          CurationBatchItem(
            id: id,
            fileName: file.name,
            imageBytes: base64Encode(bytes),
            gridSize: 8,
            clues: const <CurationClue>[],
            walls: const <Wall>[],
            status: BatchItemStatus.imported,
            confidence: 0,
            confidenceBoard: 0,
            confidenceGrid: 0,
            confidenceWalls: 0,
            confidenceTrim: 0,
            alignment: GridAlignment.defaults,
            notes: 'Queued for auto-detection',
            fingerprint: null,
            solution: const <int>[],
            lastValidation: null,
          ),
        );
        pendingIndexes.add(next.length - 1);
      }

      setState(() {
        _items = next;
        if (_selectedIndex < 0 && _items.isNotEmpty) {
          _selectedIndex = 0;
        }
      });
      await _persist();

      await _runBatchDetection(pendingIndexes);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _runBatchDetection(List<int> indexes) async {
    if (indexes.isEmpty) return;
    setState(() {
      _detectDone = 0;
      _detectTotal = indexes.length;
    });

    const chunkSize = 12;
    for (var offset = 0; offset < indexes.length; offset += chunkSize) {
      final chunk =
          indexes.skip(offset).take(chunkSize).toList(growable: false);
      for (final index in chunk) {
        if (index < 0 || index >= _items.length) continue;
        final item = _items[index];
        if (item.imageBytes == null) continue;

        final bytes = base64Decode(item.imageBytes!);
        final detected = _detector.detect(bytes, fileName: item.fileName);

        final autoReady = detected.confidenceBoard >= 0.70 &&
            detected.confidenceGrid >= 0.70 &&
            detected.confidenceWalls >= 0.70;
        final hasUnnumbered = detected.clues.any((c) => c.n <= 0);
        final status = autoReady
            ? (hasUnnumbered
                ? BatchItemStatus.needsNumbering
                : BatchItemStatus.autoDetected)
            : BatchItemStatus.needsQa;

        _items[index] = item.copyWith(
          gridSize: detected.gridSize,
          clues: detected.clues,
          walls: detected.walls,
          status: status,
          confidence: detected.confidence,
          confidenceBoard: detected.confidenceBoard,
          confidenceGrid: detected.confidenceGrid,
          confidenceWalls: detected.confidenceWalls,
          confidenceTrim: detected.confidenceTrim,
          alignment: detected.alignment,
          notes: detected.notes,
        );
        setState(() {
          _detectDone++;
        });
      }
      await _persist();
      if (mounted) setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 12));
    }
  }

  void _applyValidation(int index) {
    final item = _items[index];
    if (item.clues.isEmpty || item.clues.any((c) => c.n <= 0)) {
      _items[index] = item.copyWith(
        status: BatchItemStatus.needsNumbering,
        notes: 'Needs numbering',
        lastValidation: DateTime.now().toIso8601String(),
      );
      return;
    }
    final result = _validator.validate(item);
    final status = result.valid
        ? BatchItemStatus.valid
        : (result.reason == 'Needs numbering'
            ? BatchItemStatus.needsNumbering
            : BatchItemStatus.needsQa);
    _items[index] = item.copyWith(
      status: status,
      notes: result.reason,
      solution: result.solution,
      fingerprint: result.fingerprint,
      lastValidation: DateTime.now().toIso8601String(),
    );
  }

  Future<void> _validateCurrent() async {
    final idx = _selectedIndex;
    if (idx < 0 || idx >= _items.length) return;
    _applyValidation(idx);
    setState(() {});
    await _persist();
  }

  Future<void> _validateAll() async {
    setState(() => _busy = true);
    try {
      for (var i = 0; i < _items.length; i++) {
        _applyValidation(i);
      }
      await _persist();
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _autoAcceptValid() async {
    setState(() => _busy = true);
    try {
      for (var i = 0; i < _items.length; i++) {
        final item = _items[i];
        if (item.clues.isEmpty || item.clues.any((c) => c.n <= 0)) {
          continue;
        }
        _applyValidation(i);
      }
      await _persist();
      if (mounted) setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _updateSelected(CurationBatchItem next) {
    if (_selectedIndex < 0 || _selectedIndex >= _items.length) return;
    final items = List<CurationBatchItem>.from(_items);
    items[_selectedIndex] = next;
    setState(() => _items = items);
    _persist();
  }

  void _pushUndo(String id, List<CurationClue> clues) {
    final stack = _undoStacks.putIfAbsent(id, () => <List<CurationClue>>[]);
    stack.add(List<CurationClue>.from(clues));
    if (stack.length > 40) {
      stack.removeAt(0);
    }
  }

  void _undoNumbering() {
    final selected = _selected;
    if (selected == null) return;
    final stack = _undoStacks[selected.id];
    if (stack == null || stack.isEmpty) return;
    final previous = stack.removeLast();
    _updateSelected(
      selected.copyWith(
        clues: previous,
        status: BatchItemStatus.needsNumbering,
        notes: 'Numbering undone',
      ),
    );
  }

  void _assignNumberAtCell(int x, int y) {
    final selected = _selected;
    if (selected == null) return;
    _pushUndo(selected.id, selected.clues);
    final clues = List<CurationClue>.from(selected.clues);

    if (_eraseClue) {
      clues.removeWhere((c) => c.x == x && c.y == y);
    } else if (_numberingMode) {
      clues.removeWhere((c) => c.n == _currentNumber || (c.x == x && c.y == y));
      clues.add(CurationClue(n: _currentNumber, x: x, y: y));
      _currentNumber++;
    } else {
      final existing = clues.indexWhere((c) => c.x == x && c.y == y);
      if (existing >= 0) {
        clues[existing] = CurationClue(n: 0, x: x, y: y);
      } else {
        clues.add(CurationClue(n: 0, x: x, y: y));
      }
    }
    clues.sort((a, b) => a.n.compareTo(b.n));

    _updateSelected(
      selected.copyWith(
        clues: clues,
        status: clues.any((c) => c.n <= 0)
            ? BatchItemStatus.needsNumbering
            : BatchItemStatus.needsQa,
        notes: 'Clues edited',
      ),
    );
    setState(() {});
  }

  void _toggleWall(int cellA, int cellB) {
    final selected = _selected;
    if (selected == null) return;
    final a = math.min(cellA, cellB);
    final b = math.max(cellA, cellB);
    final walls = List<Wall>.from(selected.walls);
    final existing = walls.indexWhere((w) => w.cell1 == a && w.cell2 == b);
    if (existing >= 0) {
      walls.removeAt(existing);
    } else {
      walls.add(Wall(cell1: a, cell2: b));
    }
    _updateSelected(
      selected.copyWith(
        walls: walls,
        status: BatchItemStatus.needsQa,
        notes: 'Walls edited',
      ),
    );
  }

  void _autoNumberSelected() {
    final selected = _selected;
    if (selected == null) return;
    final cells =
        selected.clues.map((c) => (c.x, c.y)).toSet().toList(growable: false);
    if (cells.isEmpty) return;

    final center = (selected.gridSize - 1) / 2.0;
    cells.sort((a, b) {
      double d((int, int) p) => (p.$1 - center).abs() + (p.$2 - center).abs();
      return d(a).compareTo(d(b));
    });

    final ordered = <(int, int)>[];
    var current = cells.first;
    ordered.add(current);
    final remaining = cells.skip(1).toList(growable: true);
    while (remaining.isNotEmpty) {
      remaining.sort((a, b) {
        final da = (a.$1 - current.$1).abs() + (a.$2 - current.$2).abs();
        final db = (b.$1 - current.$1).abs() + (b.$2 - current.$2).abs();
        return da.compareTo(db);
      });
      current = remaining.removeAt(0);
      ordered.add(current);
    }

    final clues = <CurationClue>[];
    for (var i = 0; i < ordered.length; i++) {
      clues.add(CurationClue(n: i + 1, x: ordered[i].$1, y: ordered[i].$2));
    }

    _updateSelected(
      selected.copyWith(
        clues: clues,
        status: BatchItemStatus.needsQa,
        notes: 'Auto-numbered with nearest-neighbor heuristic',
      ),
    );
    setState(() {
      _currentNumber = clues.length + 1;
    });
  }

  void _onDigit(int digit) {
    final now = DateTime.now();
    if (_lastDigitAt == null ||
        now.difference(_lastDigitAt!) > const Duration(milliseconds: 850)) {
      _digitBuffer = '$digit';
    } else {
      _digitBuffer = '$_digitBuffer$digit';
    }
    _lastDigitAt = now;
    final parsed = int.tryParse(_digitBuffer);
    if (parsed != null && parsed > 0) {
      setState(() => _currentNumber = parsed);
    }
  }

  Future<void> _exportValidLevels() async {
    final valid = _items.where((e) => e.status == BatchItemStatus.valid);
    final dedupe = <String>{};
    final levels = <Map<String, dynamic>>[];
    for (final item in valid) {
      final fp = item.fingerprint;
      if (fp == null || fp.isEmpty) continue;
      if (!dedupe.add(fp)) continue;

      final clues = List<CurationClue>.from(item.clues)
        ..sort((a, b) => a.n.compareTo(b.n));
      final walls = List<Wall>.from(item.walls)
        ..sort((a, b) {
          final c = a.cell1.compareTo(b.cell1);
          if (c != 0) return c;
          return a.cell2.compareTo(b.cell2);
        });
      levels.add(<String, dynamic>{
        'id': 'linkedin-${item.id}',
        'size': <String, int>{'w': item.gridSize, 'h': item.gridSize},
        'difficultyTag': 'd5',
        'source': 'linkedin',
        'origin': 'curated',
        'tags': const <String>['linkedin'],
        'fingerprint': fp,
        'clues': clues.map((e) => e.toJson()).toList(growable: false),
        'walls': walls.map((e) => e.toJson()).toList(growable: false),
        'solution': item.solution,
      });
    }

    final payload = <String, dynamic>{
      'schemaVersion': 'linkedin-import-v1',
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'count': levels.length,
      'levels': levels,
    };
    downloadTextFile(
      fileName: 'linkedin_imports.json',
      content: const JsonEncoder.withIndent('  ').convert(payload),
    );

    final next = _items
        .map((e) => e.status == BatchItemStatus.valid
            ? e.copyWith(status: BatchItemStatus.exported)
            : e)
        .toList(growable: false);
    setState(() => _items = next);
    await _persist();
  }

  void _clearSession() {
    _store.clear();
    setState(() {
      _items = <CurationBatchItem>[];
      _selectedIndex = -1;
      _detectDone = 0;
      _detectTotal = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(child: Text('Batch curation is available on Web only.')),
      );
    }

    final filtered = _statusFilter == null
        ? _items
        : _items
            .where((e) => e.status == _statusFilter)
            .toList(growable: false);

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyN): const _NextIntent(),
        const SingleActivator(LogicalKeyboardKey.keyP): const _PrevIntent(),
        const SingleActivator(LogicalKeyboardKey.keyV): const _ValidateIntent(),
        const SingleActivator(LogicalKeyboardKey.keyA): const _AcceptIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const _AcceptIntent(),
        const SingleActivator(LogicalKeyboardKey.backspace):
            const _UndoIntent(),
        const SingleActivator(LogicalKeyboardKey.digit0): const _DigitIntent(0),
        const SingleActivator(LogicalKeyboardKey.digit1): const _DigitIntent(1),
        const SingleActivator(LogicalKeyboardKey.digit2): const _DigitIntent(2),
        const SingleActivator(LogicalKeyboardKey.digit3): const _DigitIntent(3),
        const SingleActivator(LogicalKeyboardKey.digit4): const _DigitIntent(4),
        const SingleActivator(LogicalKeyboardKey.digit5): const _DigitIntent(5),
        const SingleActivator(LogicalKeyboardKey.digit6): const _DigitIntent(6),
        const SingleActivator(LogicalKeyboardKey.digit7): const _DigitIntent(7),
        const SingleActivator(LogicalKeyboardKey.digit8): const _DigitIntent(8),
        const SingleActivator(LogicalKeyboardKey.digit9): const _DigitIntent(9),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _NextIntent: CallbackAction<_NextIntent>(onInvoke: (_) {
            if (_items.isEmpty) return null;
            setState(
              () => _selectedIndex =
                  math.min(_items.length - 1, _selectedIndex + 1),
            );
            return null;
          }),
          _PrevIntent: CallbackAction<_PrevIntent>(onInvoke: (_) {
            if (_items.isEmpty) return null;
            setState(() => _selectedIndex = math.max(0, _selectedIndex - 1));
            return null;
          }),
          _ValidateIntent: CallbackAction<_ValidateIntent>(onInvoke: (_) {
            _validateCurrent();
            return null;
          }),
          _AcceptIntent: CallbackAction<_AcceptIntent>(onInvoke: (_) {
            final selected = _selected;
            if (selected != null && selected.clues.every((c) => c.n > 0)) {
              _validateCurrent();
            }
            return null;
          }),
          _UndoIntent: CallbackAction<_UndoIntent>(onInvoke: (_) {
            _undoNumbering();
            return null;
          }),
          _DigitIntent: CallbackAction<_DigitIntent>(onInvoke: (intent) {
            _onDigit(intent.digit);
            return null;
          }),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Batch Curator (Debug)'),
              actions: [
                TextButton.icon(
                  onPressed: _busy ? null : _importScreenshots,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import Screenshots (multi-select)'),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _validateAll,
                  icon: const Icon(Icons.rule_rounded),
                  label: const Text('Validate All'),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _autoAcceptValid,
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('Auto-Accept Valid'),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _exportValidLevels,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export Valid Levels'),
                ),
                IconButton(
                  onPressed: _busy ? null : _clearSession,
                  tooltip: 'Clear session',
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            body: Column(
              children: [
                _buildProgressBar(),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(width: 380, child: _buildListPane(filtered)),
                      const VerticalDivider(width: 1),
                      Expanded(child: _buildEditorPane(_selected)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    int count(BatchItemStatus s) => _items.where((e) => e.status == s).length;
    final imported = _items.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              Text('Imported: $imported'),
              Text('Auto-detected: ${count(BatchItemStatus.autoDetected)}'),
              Text('Needs Numbering: ${count(BatchItemStatus.needsNumbering)}'),
              Text('Needs QA: ${count(BatchItemStatus.needsQa)}'),
              Text('Valid: ${count(BatchItemStatus.valid)}'),
              Text('Exported: ${count(BatchItemStatus.exported)}'),
              DropdownButton<BatchItemStatus?>(
                value: _statusFilter,
                hint: const Text('Filter'),
                items: <DropdownMenuItem<BatchItemStatus?>>[
                  const DropdownMenuItem<BatchItemStatus?>(
                    value: null,
                    child: Text('All'),
                  ),
                  for (final status in BatchItemStatus.values)
                    DropdownMenuItem<BatchItemStatus?>(
                      value: status,
                      child: Text(status.name),
                    ),
                ],
                onChanged: (value) => setState(() => _statusFilter = value),
              ),
            ],
          ),
          if (_detectTotal > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _detectDone / math.max(1, _detectTotal),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Detection $_detectDone/$_detectTotal'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListPane(List<CurationBatchItem> filtered) {
    if (_items.isEmpty) {
      return const Center(child: Text('Import screenshots to begin.'));
    }
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final globalIndex = _items.indexWhere((e) => e.id == item.id);
        final selected = globalIndex == _selectedIndex;
        return ListTile(
          selected: selected,
          onTap: () => setState(() => _selectedIndex = globalIndex),
          title:
              Text(item.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${item.status.name} - ${item.gridSize}x${item.gridSize} - conf ${(item.confidence * 100).toStringAsFixed(0)}%',
          ),
          leading: item.imageBytes == null
              ? CircleAvatar(child: Text('${globalIndex + 1}'))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(item.imageBytes!),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
          trailing: item.fingerprint == null
              ? const Icon(Icons.warning_amber_rounded, color: Colors.orange)
              : const Icon(Icons.verified_rounded, color: Colors.green),
        );
      },
    );
  }

  Widget _buildEditorPane(CurationBatchItem? item) {
    if (item == null) {
      return const Center(child: Text('Select an item'));
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<_EditorMode>(
                segments: const [
                  ButtonSegment<_EditorMode>(
                    value: _EditorMode.clues,
                    label: Text('Clues'),
                  ),
                  ButtonSegment<_EditorMode>(
                    value: _EditorMode.walls,
                    label: Text('Walls'),
                  ),
                ],
                selected: <_EditorMode>{_mode},
                onSelectionChanged: (set) => setState(() => _mode = set.first),
              ),
              FilterChip(
                selected: _numberingMode,
                label: const Text('Numbering Mode'),
                onSelected: (v) => setState(() => _numberingMode = v),
              ),
              FilterChip(
                selected: _eraseClue,
                label: const Text('Erase Clue'),
                onSelected: (v) => setState(() => _eraseClue = v),
              ),
              Text('N=$_currentNumber'),
              IconButton(
                onPressed: () => setState(
                    () => _currentNumber = math.max(1, _currentNumber - 1)),
                icon: const Icon(Icons.remove),
              ),
              IconButton(
                onPressed: () => setState(() => _currentNumber++),
                icon: const Icon(Icons.add),
              ),
              TextButton.icon(
                onPressed: _autoNumberSelected,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Auto Number'),
              ),
              TextButton.icon(
                onPressed: _undoNumbering,
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Undo (Backspace)'),
              ),
              TextButton.icon(
                onPressed: _validateCurrent,
                icon: const Icon(Icons.rule_rounded),
                label: const Text('Validate (V)'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _BatchEditorCanvas(
                  item: item,
                  mode: _mode,
                  onCellTap: _assignNumberAtCell,
                  onWallToggle: _toggleWall,
                  onAlignmentChanged: (alignment) {
                    _updateSelected(
                      item.copyWith(
                        alignment: alignment,
                        status: BatchItemStatus.needsQa,
                      ),
                    );
                  },
                  maxSize: Size(constraints.maxWidth, constraints.maxHeight),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'B:${item.confidenceBoard.toStringAsFixed(2)} G:${item.confidenceGrid.toStringAsFixed(2)} '
                  'W:${item.confidenceWalls.toStringAsFixed(2)} T:${item.confidenceTrim.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BatchEditorCanvas extends StatelessWidget {
  const _BatchEditorCanvas({
    required this.item,
    required this.mode,
    required this.onCellTap,
    required this.onWallToggle,
    required this.onAlignmentChanged,
    required this.maxSize,
  });

  final CurationBatchItem item;
  final _EditorMode mode;
  final void Function(int x, int y) onCellTap;
  final void Function(int cellA, int cellB) onWallToggle;
  final ValueChanged<GridAlignment> onAlignmentChanged;
  final Size maxSize;

  @override
  Widget build(BuildContext context) {
    final imageBytes =
        item.imageBytes == null ? null : base64Decode(item.imageBytes!);
    final side = math.min(maxSize.width, maxSize.height);

    return Center(
      child: SizedBox(
        width: side,
        height: side,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final boardRect = Rect.fromLTRB(
              item.alignment.left * constraints.maxWidth,
              item.alignment.top * constraints.maxHeight,
              item.alignment.right * constraints.maxWidth,
              item.alignment.bottom * constraints.maxHeight,
            );

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) {
                final local = d.localPosition;
                if (!boardRect.contains(local)) return;
                final cell = _cellFromPos(local, boardRect, item.gridSize);
                if (cell == null) return;
                if (mode == _EditorMode.clues) {
                  onCellTap(cell.$1, cell.$2);
                } else {
                  final edge = _edgeFromPos(local, boardRect, item.gridSize);
                  if (edge != null) {
                    onWallToggle(edge.$1, edge.$2);
                  }
                }
              },
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade500),
                      ),
                      child: imageBytes == null
                          ? const Center(
                              child: Text('Image bytes not available'))
                          : Image.memory(imageBytes, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: boardRect,
                    child: CustomPaint(painter: _GridPainter(item: item)),
                  ),
                  ..._buildHandles(context, boardRect, constraints.biggest),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildHandles(BuildContext context, Rect rect, Size bounds) {
    Widget handle(double x, double y, String corner) {
      return Positioned(
        left: x - 10,
        top: y - 10,
        child: GestureDetector(
          onPanUpdate: (d) {
            final dx = d.delta.dx / bounds.width;
            final dy = d.delta.dy / bounds.height;
            var a = item.alignment;
            switch (corner) {
              case 'tl':
                a = a.copyWith(left: a.left + dx, top: a.top + dy);
                break;
              case 'tr':
                a = a.copyWith(right: a.right + dx, top: a.top + dy);
                break;
              case 'bl':
                a = a.copyWith(left: a.left + dx, bottom: a.bottom + dy);
                break;
              case 'br':
                a = a.copyWith(right: a.right + dx, bottom: a.bottom + dy);
                break;
            }
            const minSize = 0.25;
            final left = a.left.clamp(0.0, a.right - minSize);
            final top = a.top.clamp(0.0, a.bottom - minSize);
            final right = a.right.clamp(left + minSize, 1.0);
            final bottom = a.bottom.clamp(top + minSize, 1.0);
            onAlignmentChanged(
              GridAlignment(left: left, top: top, right: right, bottom: bottom),
            );
          },
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      );
    }

    return <Widget>[
      handle(rect.left, rect.top, 'tl'),
      handle(rect.right, rect.top, 'tr'),
      handle(rect.left, rect.bottom, 'bl'),
      handle(rect.right, rect.bottom, 'br'),
    ];
  }

  (int, int)? _cellFromPos(Offset pos, Rect rect, int size) {
    final cw = rect.width / size;
    final ch = rect.height / size;
    final x = ((pos.dx - rect.left) / cw).floor();
    final y = ((pos.dy - rect.top) / ch).floor();
    if (x < 0 || y < 0 || x >= size || y >= size) return null;
    return (x, y);
  }

  (int, int)? _edgeFromPos(Offset pos, Rect rect, int size) {
    final cw = rect.width / size;
    final ch = rect.height / size;
    final gx = (pos.dx - rect.left) / cw;
    final gy = (pos.dy - rect.top) / ch;

    final vx = gx.roundToDouble();
    final vy = gy.roundToDouble();
    final distV = (gx - vx).abs();
    final distH = (gy - vy).abs();

    const threshold = 0.18;
    if (distV <= distH && distV < threshold) {
      final edgeX = vx.toInt();
      final y = gy.floor();
      if (edgeX <= 0 || edgeX >= size || y < 0 || y >= size) return null;
      final left = y * size + (edgeX - 1);
      final right = y * size + edgeX;
      return (left, right);
    }
    if (distH < threshold) {
      final edgeY = vy.toInt();
      final x = gx.floor();
      if (edgeY <= 0 || edgeY >= size || x < 0 || x >= size) return null;
      final top = (edgeY - 1) * size + x;
      final bottom = edgeY * size + x;
      return (top, bottom);
    }
    return null;
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.item});

  final CurationBatchItem item;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 1;
    final wallPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4;

    final cellW = size.width / item.gridSize;
    final cellH = size.height / item.gridSize;
    for (var i = 0; i <= item.gridSize; i++) {
      final x = i * cellW;
      final y = i * cellH;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (final wall in item.walls) {
      final a = wall.cell1;
      final b = wall.cell2;
      final ax = a % item.gridSize;
      final ay = a ~/ item.gridSize;
      final bx = b % item.gridSize;
      final by = b ~/ item.gridSize;
      if (ax == bx) {
        final y = math.max(ay, by) * cellH;
        canvas.drawLine(
          Offset(ax * cellW, y),
          Offset((ax + 1) * cellW, y),
          wallPaint,
        );
      } else {
        final x = math.max(ax, bx) * cellW;
        canvas.drawLine(
          Offset(x, ay * cellH),
          Offset(x, (ay + 1) * cellH),
          wallPaint,
        );
      }
    }

    for (final clue in item.clues) {
      final cx = (clue.x + 0.5) * cellW;
      final cy = (clue.y + 0.5) * cellH;
      canvas.drawCircle(
        Offset(cx, cy),
        math.min(cellW, cellH) * 0.27,
        Paint()..color = Colors.black,
      );
      final label = clue.n <= 0 ? '?' : '${clue.n}';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.item != item;
  }
}

class _NextIntent extends Intent {
  const _NextIntent();
}

class _PrevIntent extends Intent {
  const _PrevIntent();
}

class _ValidateIntent extends Intent {
  const _ValidateIntent();
}

class _AcceptIntent extends Intent {
  const _AcceptIntent();
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _DigitIntent extends Intent {
  const _DigitIntent(this.digit);
  final int digit;
}
