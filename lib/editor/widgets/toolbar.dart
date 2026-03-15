import 'package:flutter/material.dart';

import '../editor_state.dart';

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    super.key,
    required this.state,
    required this.onGridChanged,
    required this.onImport,
    required this.onExport,
    required this.onSaveToGeneral,
    required this.onValidate,
    required this.onClear,
  });

  final EditorState state;
  final void Function(int width, int height) onGridChanged;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onSaveToGeneral;
  final VoidCallback onValidate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final content = ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('ZIP Path Editor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: state.width,
                decoration: const InputDecoration(labelText: 'Width'),
                items: _sizeItems(),
                onChanged: (value) {
                  if (value != null) {
                    onGridChanged(value, state.height);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: state.height,
                decoration: const InputDecoration(labelText: 'Height'),
                items: _sizeItems(),
                onChanged: (value) {
                  if (value != null) {
                    onGridChanged(state.width, value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Grid: ${state.width}x${state.height}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
        const SizedBox(height: 12),
        const Text('Tool', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: EditorTool.values.map((tool) {
            final selected = state.tool == tool;
            return ChoiceChip(
              label: Text(_toolLabel(tool)),
              selected: selected,
              onSelected: (_) => state.setTool(tool),
            );
          }).toList(growable: false),
        ),
        const Divider(height: 24),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-number'),
          value: state.autoNumber,
          onChanged: state.setAutoNumber,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Snap strict'),
          value: state.snapStrict,
          onChanged: state.setSnapStrict,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Preview mode'),
          value: state.previewMode,
          onChanged: state.setPreviewMode,
        ),
        const Divider(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: state.canUndo ? state.undo : null,
              icon: const Icon(Icons.undo),
              label: const Text('Undo'),
            ),
            FilledButton.tonalIcon(
              onPressed: state.canRedo ? state.redo : null,
              icon: const Icon(Icons.redo),
              label: const Text('Redo'),
            ),
            FilledButton.tonalIcon(
              onPressed: onImport,
              icon: const Icon(Icons.file_download),
              label: const Text('Import JSON'),
            ),
            FilledButton.tonalIcon(
              onPressed: onExport,
              icon: const Icon(Icons.file_upload),
              label: const Text('Export JSON'),
            ),
            FilledButton.tonalIcon(
              onPressed: onSaveToGeneral,
              icon: const Icon(Icons.library_add),
              label: const Text('Save to Pack'),
            ),
            FilledButton.tonalIcon(
              onPressed: onValidate,
              icon: const Icon(Icons.rule),
              label: const Text('Validate'),
            ),
            FilledButton.tonalIcon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear'),
            ),
          ],
        ),
      ],
    );

    if (isDesktop) {
      return SizedBox(width: 280, child: content);
    }
    return SizedBox(height: 320, child: content);
  }

  List<DropdownMenuItem<int>> _sizeItems() {
    return List.generate(
      11,
      (index) {
        final size = index + 2;
        return DropdownMenuItem<int>(
          value: size,
          child: Text(size.toString()),
        );
      },
    );
  }

  String _toolLabel(EditorTool tool) {
    switch (tool) {
      case EditorTool.walls:
        return 'Walls';
      case EditorTool.clues:
        return 'Clues';
      case EditorTool.erase:
        return 'Erase';
      case EditorTool.select:
        return 'Select';
    }
  }
}
