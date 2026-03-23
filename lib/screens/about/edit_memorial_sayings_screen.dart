import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/providers/auth_provider.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/models/elder_saying.dart';
import 'package:bhandari_pariwar/services/content_service.dart';
import 'package:bhandari_pariwar/services/storage_service.dart';

class EditMemorialSayingsScreen extends ConsumerStatefulWidget {
  const EditMemorialSayingsScreen({super.key});

  @override
  ConsumerState<EditMemorialSayingsScreen> createState() =>
      _EditMemorialSayingsScreenState();
}

class _EditMemorialSayingsScreenState
    extends ConsumerState<EditMemorialSayingsScreen> {
  List<ElderSaying> _sayings = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = ref.read(contentServiceProvider);
    final content = await service.getMemorialSayings();
    if (mounted) {
      setState(() {
        _sayings = content?.sayings ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_ensureAdminAccess()) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(contentServiceProvider);
      await service.updateMemorialSayings(
        ElderSayingsContent(
          sayings: _sayings,
          updatedAt: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _ensureAdminAccess() {
    final isAdmin = ref.read(isAdminProvider);
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only admins can make changes.')),
      );
      return false;
    }
    return true;
  }

  void _addSaying() {
    if (!_ensureAdminAccess()) return;

    final nextOrder = _sayings.isEmpty
        ? 1
        : _sayings.map((s) => s.order).reduce((a, b) => a > b ? a : b) + 1;

    _showEditDialog(
      ElderSaying(
        id: 'memorial_${DateTime.now().millisecondsSinceEpoch}',
        name: const {'en': '', 'ne': ''},
        title: const {'en': '', 'ne': ''},
        saying: const {'en': '', 'ne': ''},
        order: nextOrder,
      ),
      isNew: true,
    );
  }

  void _editSaying(int index) {
    if (!_ensureAdminAccess()) return;
    _showEditDialog(_sayings[index], isNew: false, index: index);
  }

  void _deleteSaying(int index) {
    if (!_ensureAdminAccess()) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.delete),
          content: Text(
              'Remove ${_sayings[index].localizedName('en')}\'s entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                if (!_ensureAdminAccess()) {
                  Navigator.pop(ctx);
                  return;
                }
                setState(() => _sayings.removeAt(index));
                Navigator.pop(ctx);
              },
              child: Text(l10n.delete,
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(ElderSaying saying,
      {required bool isNew, int? index}) {
    final nameEnCtrl =
        TextEditingController(text: saying.name['en'] ?? '');
    final nameNeCtrl =
        TextEditingController(text: saying.name['ne'] ?? '');
    final titleEnCtrl =
        TextEditingController(text: saying.title['en'] ?? '');
    final titleNeCtrl =
        TextEditingController(text: saying.title['ne'] ?? '');
    final sayingEnCtrl =
        TextEditingController(text: saying.saying['en'] ?? '');
    final sayingNeCtrl =
        TextEditingController(text: saying.saying['ne'] ?? '');
    final orderCtrl =
        TextEditingController(text: saying.order.toString());
    final formKey = GlobalKey<FormState>();
    File? selectedPhotoFile;
    bool removePhoto = false;
    bool isUploadingPhoto = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(isNew ? l10n.addMember : l10n.editMember),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: orderCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Order / क्रम'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameEnCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Name (English)'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameNeCtrl,
                    decoration:
                        const InputDecoration(labelText: 'नाम (नेपाली)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: titleEnCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Title (English)',
                        hintText: 'e.g. Beloved Father'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: titleNeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'शीर्षक (नेपाली)',
                        hintText: 'जस्तै: प्रिय बुबा'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: sayingEnCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Memorial Message (English)',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: sayingNeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'स्मृति सन्देश (नेपाली)',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (context, setDialogState) {
                      final hasNetworkPhoto =
                          !removePhoto &&
                          saying.photoUrl != null &&
                          saying.photoUrl!.isNotEmpty;
                      final hasLocalPhoto = selectedPhotoFile != null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Photo',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: CircleAvatar(
                              radius: 36,
                              backgroundImage: hasLocalPhoto
                                  ? FileImage(selectedPhotoFile!)
                                  : hasNetworkPhoto
                                      ? NetworkImage(saying.photoUrl!)
                                      : null,
                              child: (!hasLocalPhoto && !hasNetworkPhoto)
                                  ? const Icon(Icons.person, size: 32)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: isUploadingPhoto
                                    ? null
                                    : () async {
                                        final storageService =
                                            ref.read(storageServiceProvider);
                                        final picked =
                                            await storageService.pickImage();
                                        if (picked == null) return;

                                        setDialogState(() {
                                          selectedPhotoFile = File(picked.path);
                                          removePhoto = false;
                                        });
                                      },
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Choose from gallery'),
                              ),
                              if (hasLocalPhoto || hasNetworkPhoto)
                                TextButton.icon(
                                  onPressed: isUploadingPhoto
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            selectedPhotoFile = null;
                                            removePhoto = true;
                                          });
                                        },
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Remove photo'),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final order = int.tryParse(orderCtrl.text.trim());
                if (order == null || order <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order must be greater than 0.'),
                    ),
                  );
                  return;
                }

                final duplicateOrder = _sayings.asMap().entries.any((entry) =>
                    entry.value.order == order &&
                    (isNew || entry.key != index));
                if (duplicateOrder) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order already exists.'),
                    ),
                  );
                  return;
                }

                setState(() => isUploadingPhoto = true);

                String? photoUrl = saying.photoUrl;
                try {
                  if (selectedPhotoFile != null) {
                    final storageService = ref.read(storageServiceProvider);
                    photoUrl = await storageService.uploadMemorialSayingPhoto(
                      saying.id,
                      selectedPhotoFile!,
                      previousPublicUrl: saying.photoUrl,
                    );
                  } else if (removePhoto) {
                    final storageService = ref.read(storageServiceProvider);
                    await storageService.deleteByPublicUrl(saying.photoUrl);
                    photoUrl = null;
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Photo upload failed: $e')),
                    );
                  }
                  setState(() => isUploadingPhoto = false);
                  return;
                }

                final updated = ElderSaying(
                  id: saying.id,
                  order: order,
                  name: {
                    'en': nameEnCtrl.text.trim(),
                    'ne': nameNeCtrl.text.trim().isNotEmpty
                        ? nameNeCtrl.text.trim()
                        : nameEnCtrl.text.trim(),
                  },
                  title: {
                    'en': titleEnCtrl.text.trim(),
                    'ne': titleNeCtrl.text.trim().isNotEmpty
                        ? titleNeCtrl.text.trim()
                        : titleEnCtrl.text.trim(),
                  },
                  saying: {
                    'en': sayingEnCtrl.text.trim(),
                    'ne': sayingNeCtrl.text.trim().isNotEmpty
                        ? sayingNeCtrl.text.trim()
                        : sayingEnCtrl.text.trim(),
                  },
                    photoUrl: photoUrl,
                );

                setState(() {
                  if (isNew) {
                    _sayings.add(updated);
                  } else if (index != null) {
                    _sayings[index] = updated;
                  }
                  _sayings.sort((a, b) => a.order.compareTo(b.order));
                });

                setState(() => isUploadingPhoto = false);
                Navigator.pop(ctx);
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = ref.watch(isAdminProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.memorialSayings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.editContent} — ${l10n.memorialSayings}'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: l10n.save,
              onPressed: isAdmin ? _save : null,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isAdmin ? _addSaying : null,
        child: const Icon(Icons.add),
      ),
      body: _sayings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_florist,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(l10n.noMemorialSayings,
                      style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: isAdmin ? _addSaying : null,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addMember),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sayings.length,
              onReorder: (oldIndex, newIndex) {
                if (!isAdmin) return;
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _sayings.removeAt(oldIndex);
                  _sayings.insert(newIndex, item);
                  for (int i = 0; i < _sayings.length; i++) {
                    _sayings[i] = _sayings[i].copyWith(order: i + 1);
                  }
                });
              },
              itemBuilder: (context, index) {
                final saying = _sayings[index];
                return Card(
                  key: ValueKey(saying.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF6A1B9A)
                          .withValues(alpha: 0.1),
                      child: Text(
                        '${saying.order}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                    ),
                    title: Text(
                      saying.localizedName('en'),
                      style:
                          const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      saying.localizedSaying('en'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: isAdmin ? () => _editSaying(index) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 18, color: Colors.red),
                          onPressed: isAdmin ? () => _deleteSaying(index) : null,
                        ),
                        const Icon(Icons.drag_handle, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
