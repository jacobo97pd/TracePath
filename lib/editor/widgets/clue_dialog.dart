import 'package:flutter/material.dart';

class ClueInputResult {
  const ClueInputResult({this.value, this.delete = false});

  final int? value;
  final bool delete;
}

Future<ClueInputResult?> showClueDialog(
  BuildContext context, {
  int? initialValue,
  int? suggestedValue,
}) async {
  final controller = TextEditingController(
    text: initialValue?.toString() ?? suggestedValue?.toString() ?? '',
  );

  return showDialog<ClueInputResult>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Set clue number'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter clue number',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(const ClueInputResult(delete: true)),
            child: const Text('Delete'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed <= 0) {
                return;
              }
              Navigator.of(context).pop(ClueInputResult(value: parsed));
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
