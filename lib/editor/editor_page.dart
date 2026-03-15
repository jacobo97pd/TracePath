import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'editor_canvas.dart';
import 'editor_codec.dart';
import 'level_pack_writer.dart';
import 'editor_state.dart';
import 'editor_validator.dart';
import 'widgets/clue_dialog.dart';
import 'widgets/toolbar.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final EditorState _state;

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
      ),
    );
    final toolbar = AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        return EditorToolbar(
          state: _state,
          onGridChanged: (width, height) =>
              _state.resize(width: width, height: height),
          onImport: _showImportDialog,
          onExport: _showExportDialog,
          onSaveToGeneral: _saveToGeneralPack,
          onValidate: _validate,
          onClear: _state.clear,
        );
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('ZIP Path Level Editor')),
      body: isDesktop
          ? Row(
              children: [
                Container(
                  width: 280,
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
                toolbar,
                const Divider(height: 1),
                Expanded(child: canvas),
              ],
            ),
    );
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
    final jsonText = EditorCodec.toJsonString(_state.toLevelData());
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
                    '{ "size": {"w":7,"h":6}, "clues": [], "walls": {"h":[],"v":[]} }',
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
                try {
                  final decoded = jsonDecode(controller.text);
                  final map = Map<String, dynamic>.from(decoded as Map);
                  final data = EditorCodec.fromJsonMap(map);
                  final errors = EditorValidator.validate(data);
                  if (errors.isNotEmpty) {
                    throw FormatException(errors.join('\n'));
                  }
                  _state.loadLevelData(data);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Level imported')),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Import error: $error')),
                  );
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
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
    final icon = result.added ? Icons.check_circle : Icons.info_outline;
    final snackColor = result.added ? Colors.green.shade700 : null;
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: snackColor,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(result.message)),
          ],
        ),
        duration: Duration(seconds: result.added ? 2 : 4),
      ),
    );
  }
}
