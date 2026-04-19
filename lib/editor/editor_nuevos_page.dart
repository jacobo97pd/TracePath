import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/level.dart';
import '../game_board.dart';
import '../game_theme.dart';
import 'editor_canvas.dart';
import 'editor_codec.dart';
import 'editor_state.dart';
import 'editor_validator.dart';
import 'level_pack_writer.dart';
import 'widgets/clue_dialog.dart';
import 'widgets/toolbar.dart';

class EditorNuevosPage extends StatefulWidget {
  const EditorNuevosPage({super.key});

  @override
  State<EditorNuevosPage> createState() => _EditorNuevosPageState();
}

class _EditorNuevosPageState extends State<EditorNuevosPage> {
  late final EditorState _state;
  Map<int, String> _displayLabels = <int, String>{};
  Map<String, dynamic> _meta = const <String, dynamic>{};
  String _levelId = 'editor_nuevos_preview';

  @override
  void initState() {
    super.initState();
    _state = EditorState(initialWidth: 7, initialHeight: 7);
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final canvas = Container(
      color: const Color(0xFFF8F8F8),
      padding: const EdgeInsets.all(12),
      child: EditorCanvas(
        state: _state,
        onRequestClue: _requestClue,
        clueLabelBuilder: (number) => _displayLabels[number] ?? number.toString(),
      ),
    );
    final toolbar = AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return Column(
          children: [
            Expanded(
              child: EditorToolbar(
                state: _state,
                onGridChanged: (width, height) =>
                    _state.resize(width: width, height: height),
                onImport: _showImportDialog,
                onExport: _showExportDialog,
                onSaveToGeneral: _saveToGeneralPack,
                onValidate: _validate,
                onClear: _clearEditor,
              ),
            ),
            const Divider(height: 1),
            _buildNuevosPanel(context),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('ZIP Path Editor - Nuevos')),
      body: isDesktop
          ? Row(
              children: [
                Container(
                  width: 320,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFFDDDDDD))),
                  ),
                  child: toolbar,
                ),
                Expanded(child: canvas),
              ],
            )
          : Column(
              children: [
                Expanded(child: canvas),
                const Divider(height: 1),
                SizedBox(height: 340, child: toolbar),
              ],
            ),
    );
  }

  Widget _buildNuevosPanel(BuildContext context) {
    final variant = _meta['variant']?.toString().trim();
    final difficulty = _meta['difficulty_target']?.toString().trim();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Editor Nuevos',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetaChip(label: 'id', value: _levelId),
              _MetaChip(label: 'variant', value: variant?.isNotEmpty == true ? variant! : '-'),
              _MetaChip(
                label: 'difficulty',
                value: difficulty?.isNotEmpty == true ? difficulty! : '-',
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickAndImportJsonFile,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Import JSON file'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _playCurrentLevel,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Probar nivel'),
          ),
        ],
      ),
    );
  }

  void _clearEditor() {
    _state.clear();
    setState(() {
      _displayLabels = <int, String>{};
      _meta = const <String, dynamic>{};
      _levelId = 'editor_nuevos_preview';
    });
  }

  Future<void> _requestClue(Point<int> cell) async {
    final current = _state.clueAt(cell.x, cell.y);
    final suggested = _state.autoNumber ? _state.suggestNextClueNumber() : null;
    final result = await showClueDialog(
      context,
      initialValue: current,
      suggestedValue: suggested,
    );
    if (!mounted || result == null) {
      return;
    }
    if (result.delete) {
      _state.setClue(cell.x, cell.y, null);
      return;
    }
    _state.setClue(cell.x, cell.y, result.value);
  }

  Future<void> _showExportDialog() async {
    final data = _state.toLevelData();
    final baseJson = EditorCodec.toJson(data);
    if (_meta.isNotEmpty || _displayLabels.isNotEmpty) {
      final exportMeta = Map<String, dynamic>.from(_meta);
      if (_displayLabels.isNotEmpty) {
        exportMeta['display_labels'] = _displayLabels.map(
          (k, v) => MapEntry(k.toString(), v),
        );
      }
      baseJson['meta'] = exportMeta;
    }
    final jsonText = const JsonEncoder.withIndent('  ').convert(baseJson);
    final controller = TextEditingController(text: jsonText);
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export JSON'),
          content: SizedBox(
            width: 640,
            child: TextField(
              controller: controller,
              maxLines: 20,
              minLines: 10,
              readOnly: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: controller.text));
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('JSON copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImportDialog() async {
    final controller = TextEditingController();
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import JSON'),
          content: SizedBox(
            width: 640,
            child: TextField(
              controller: controller,
              minLines: 10,
              maxLines: 20,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                hintText:
                    '{ "size": {"w":7,"h":6}, "clues": [], "walls": {"h":[],"v":[]}, "meta": {} }',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _importFromJsonString(controller.text, sourceName: 'paste');
                Navigator.of(context).pop();
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickAndImportJsonFile() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        withData: true,
        allowedExtensions: const ['json'],
      );
      if (!mounted || picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read selected file')),
        );
        return;
      }
      final text = utf8.decode(bytes);
      _importFromJsonString(text, sourceName: file.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import file error: $e')),
      );
    }
  }

  void _importFromJsonString(String rawJson, {required String sourceName}) {
    try {
      final decoded = jsonDecode(rawJson);
      final map = Map<String, dynamic>.from(decoded as Map);
      final data = EditorCodec.fromJsonMap(map);
      final errors = EditorValidator.validate(data);
      if (errors.isNotEmpty) {
        throw FormatException(errors.join('\n'));
      }
      final labels = _extractDisplayLabels(map);
      final loadedMeta = _extractMeta(map);
      final levelId = _extractId(map, sourceName: sourceName);
      _state.loadLevelData(data);
      setState(() {
        _displayLabels = labels;
        _meta = loadedMeta;
        _levelId = levelId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Level imported (${data.width}x${data.height}) variant=${_meta['variant'] ?? 'classic'}',
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import error: $error')),
      );
    }
  }

  String _extractId(Map<String, dynamic> map, {required String sourceName}) {
    final fromJson = map['id'];
    if (fromJson is String && fromJson.trim().isNotEmpty) {
      return fromJson.trim();
    }
    final cleanSource = sourceName
        .replaceAll(RegExp(r'\.json$', caseSensitive: false), '')
        .trim();
    if (cleanSource.isNotEmpty && cleanSource != 'paste') {
      return cleanSource;
    }
    return 'editor_nuevos_preview';
  }

  Map<String, dynamic> _extractMeta(Map<String, dynamic> map) {
    final rawMeta = map['meta'];
    if (rawMeta is! Map) return const <String, dynamic>{};
    final normalized = Map<String, dynamic>.from(rawMeta);
    normalized.remove('display_labels');
    return normalized;
  }

  Map<int, String> _extractDisplayLabels(Map<String, dynamic> map) {
    final rawMeta = map['meta'];
    if (rawMeta is! Map) return <int, String>{};
    final meta = Map<String, dynamic>.from(rawMeta);
    final rawLabels = meta['display_labels'];
    if (rawLabels is! Map) return <int, String>{};
    final labels = <int, String>{};
    for (final entry in rawLabels.entries) {
      final key = int.tryParse(entry.key.toString());
      final value = entry.value?.toString().trim() ?? '';
      if (key == null || value.isEmpty) continue;
      labels[key] = value;
    }
    return labels;
  }

  void _playCurrentLevel() {
    final data = _state.toLevelData();
    final errors = EditorValidator.validate(data);
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fix validation errors first:\n${errors.first}')),
      );
      return;
    }
    final level = _buildLevelForPreview(data);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _EditorNuevosPlayPage(level: level),
      ),
    );
  }

  Level _buildLevelForPreview(EditorLevelData data) {
    final numbers = <int, int>{};
    for (final entry in data.clues.entries) {
      final x = entry.key.x;
      final y = entry.key.y;
      final index = y * data.width + x;
      numbers[index] = entry.value;
    }

    final walls = <Wall>[];
    final seen = <String>{};
    for (var y = 1; y < data.height; y++) {
      for (var x = 0; x < data.width; x++) {
        if (!data.hWalls[y][x]) continue;
        final cellA = (y - 1) * data.width + x;
        final cellB = y * data.width + x;
        final minCell = min(cellA, cellB);
        final maxCell = max(cellA, cellB);
        final key = '$minCell:$maxCell';
        if (!seen.add(key)) continue;
        walls.add(Wall(cell1: minCell, cell2: maxCell));
      }
    }
    for (var y = 0; y < data.height; y++) {
      for (var x = 1; x < data.width; x++) {
        if (!data.vWalls[y][x]) continue;
        final cellA = y * data.width + (x - 1);
        final cellB = y * data.width + x;
        final minCell = min(cellA, cellB);
        final maxCell = max(cellA, cellB);
        final key = '$minCell:$maxCell';
        if (!seen.add(key)) continue;
        walls.add(Wall(cell1: minCell, cell2: maxCell));
      }
    }

    return Level(
      id: _levelId,
      width: data.width,
      height: data.height,
      numbers: numbers,
      walls: walls,
      solution: const <int>[],
      difficulty: 1,
      pack: 'editor_nuevos',
    );
  }

  void _validate() {
    final errors = EditorValidator.validate(_state.toLevelData());
    if (errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Validation OK')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Validation errors'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Text(errors.join('\n')),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveToGeneralPack() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await saveLevelToGeneralPack(_state.toLevelData());
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        duration: Duration(seconds: result.added ? 2 : 4),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text('$label: $value'),
    );
  }
}

class _EditorNuevosPlayPage extends StatefulWidget {
  const _EditorNuevosPlayPage({required this.level});

  final Level level;

  @override
  State<_EditorNuevosPlayPage> createState() => _EditorNuevosPlayPageState();
}

class _EditorNuevosPlayPageState extends State<_EditorNuevosPlayPage> {
  final GameBoardController _controller = GameBoardController();
  GameBoardStatus _status = const GameBoardStatus(
    path: <int>[],
    nextRequiredNumber: 1,
    lastSequentialNumber: 0,
    maxNumber: 0,
    solved: false,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeGenerator.generateTheme(seed: 1, brightness: Brightness.dark);
    return Scaffold(
      appBar: AppBar(
        title: Text('Probar nivel: ${widget.level.id}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: widget.level.width / widget.level.height,
                    child: GameBoard(
                      controller: _controller,
                      level: widget.level,
                      gameTheme: theme,
                      onStatusChanged: (status) {
                        setState(() {
                          _status = status;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Path: ${_status.path.length} | Next: ${_status.nextRequiredNumber} | Solved: ${_status.solved ? 'YES' : 'NO'}',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _controller.undo(),
                      child: const Text('Undo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _controller.reset(),
                      child: const Text('Restart'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
