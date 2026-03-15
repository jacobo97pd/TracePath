import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'skin_catalog_service.dart';

class SkinEditorScreen extends StatelessWidget {
  const SkinEditorScreen({
    super.key,
    required this.catalogService,
  });

  final SkinCatalogService catalogService;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: catalogService,
      builder: (context, _) {
        final items = catalogService.items;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Skin Editor'),
            actions: [
              TextButton(
                onPressed: () async {
                  await catalogService.resetToDefaults();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Catalog reset')),
                  );
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (kIsWeb) {
                            final picked = await FilePicker.platform.pickFiles(
                              dialogTitle: 'Select skins',
                              allowMultiple: true,
                              withData: true,
                              withReadStream: true,
                              type: FileType.custom,
                              allowedExtensions: const [
                                'png',
                                'jpg',
                                'jpeg',
                                'webp',
                              ],
                            );
                            final files = picked?.files ?? const <PlatformFile>[];
                            final added =
                                await catalogService.importFromWebFiles(files);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Selected ${files.length}, imported $added skins',
                                ),
                              ),
                            );
                            return;
                          }
                          final folder = await FilePicker.platform.getDirectoryPath(
                            dialogTitle: 'Select skins folder',
                            initialDirectory:
                                'C:\\Users\\jacob\\Downloads\\SKINS TRACE PATH',
                          );
                          if (folder == null || folder.trim().isEmpty) return;
                          final added =
                              await catalogService.importFromDirectory(folder);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Imported $added skins'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.folder_open_rounded),
                        label: const Text('Import from folder'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (kIsWeb) {
                            final picked = await FilePicker.platform.pickFiles(
                              dialogTitle: 'Select one skin image',
                              allowMultiple: false,
                              withData: true,
                              withReadStream: true,
                              type: FileType.custom,
                              allowedExtensions: const [
                                'png',
                                'jpg',
                                'jpeg',
                                'webp',
                              ],
                            );
                            final files = picked?.files ?? const <PlatformFile>[];
                            final added =
                                await catalogService.importFromWebFiles(files);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  added > 0
                                      ? 'Selected ${files.length}, imported $added skins'
                                      : 'Selected ${files.length}, imported 0 (duplicate/invalid)',
                                ),
                              ),
                            );
                            return;
                          }
                          final result = await FilePicker.platform.pickFiles(
                            dialogTitle: 'Select one skin image',
                            type: FileType.custom,
                            allowMultiple: false,
                            allowedExtensions: const [
                              'png',
                              'jpg',
                              'jpeg',
                              'webp',
                            ],
                          );
                          final path = result?.files.single.path;
                          if (path == null || path.trim().isEmpty) return;
                          final added = await catalogService.importSingleFile(path);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                added > 0
                                    ? 'Skin added'
                                    : 'Skin already exists or invalid file',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        label: const Text('Add one skin'),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Reorder drag handle + edit name/price/position',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9AA0AE)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                  itemCount: items.length,
                  onReorder: (oldIndex, newIndex) {
                    catalogService.reorder(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      key: ValueKey(item.id),
                      child: ListTile(
                        leading: _SkinThumb(path: item.imagePath),
                        title: Text(item.name),
                        subtitle: Text(
                          'id: ${item.id}\nprice: ${item.costCoins}  pos: (${item.posX}, ${item.posY})',
                        ),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_rounded),
                              onPressed: () => _openEditDialog(context, item),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: item.id == 'pointer_default'
                                  ? null
                                  : () => _deleteItem(context, item),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.drag_handle_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Future<void> _openEditDialog(BuildContext context, SkinCatalogItem item) async {
    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.costCoins.toString());
    final xCtrl = TextEditingController(text: item.posX.toString());
    final yCtrl = TextEditingController(text: item.posY.toString());
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit skin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price (coins)'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: xCtrl,
                  decoration: const InputDecoration(labelText: 'Pos X'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: yCtrl,
                  decoration: const InputDecoration(labelText: 'Pos Y'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final updated = item.copyWith(
                  name: nameCtrl.text.trim().isEmpty ? item.name : nameCtrl.text.trim(),
                  costCoins: int.tryParse(priceCtrl.text.trim()) ?? item.costCoins,
                  posX: int.tryParse(xCtrl.text.trim()) ?? item.posX,
                  posY: int.tryParse(yCtrl.text.trim()) ?? item.posY,
                );
                await catalogService.updateItem(updated);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Skin updated')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(BuildContext context, SkinCatalogItem item) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete skin'),
            content: Text('Remove "${item.name}" from catalog?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await catalogService.removeItem(item.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Skin deleted')),
    );
  }
}

class _SkinThumb extends StatelessWidget {
  const _SkinThumb({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.trim().isEmpty) {
      return const CircleAvatar(child: Icon(Icons.image_not_supported_outlined));
    }
    if (path.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(path, width: 44, height: 44, fit: BoxFit.cover),
      );
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          path,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.broken_image_outlined),
          ),
        ),
      );
    }
    if (path.startsWith('data:image')) {
      final comma = path.indexOf(',');
      if (comma > 0 && comma < path.length - 1) {
        final bytes = base64Decode(path.substring(comma + 1));
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(bytes, width: 44, height: 44, fit: BoxFit.cover),
        );
      }
    }
    if (kIsWeb) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Icon(Icons.image_not_supported_outlined),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(path),
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}
