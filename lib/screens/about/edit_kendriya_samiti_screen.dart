import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/providers/auth_provider.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/models/kendriya_samiti.dart';
import 'package:bhandari_pariwar/services/content_service.dart';
import 'package:bhandari_pariwar/services/storage_service.dart';

class EditKendriyaSamitiScreen extends ConsumerStatefulWidget {
  const EditKendriyaSamitiScreen({super.key});

  @override
  ConsumerState<EditKendriyaSamitiScreen> createState() =>
      _EditKendriyaSamitiScreenState();
}

class _EditKendriyaSamitiScreenState
    extends ConsumerState<EditKendriyaSamitiScreen> {
  List<KendriyaSamitiMember> _members = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = ref.read(contentServiceProvider);
    final content = await service.getKendriyaSamiti();
    if (mounted) {
      setState(() {
        _members = content?.members ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_ensureAdminAccess()) return;

    setState(() => _isSaving = true);
    try {
      final service = ref.read(contentServiceProvider);
      await service.updateKendriyaSamiti(
        KendriyaSamitiContent(
          members: _members,
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

  void _addMember() {
    if (!_ensureAdminAccess()) return;

    final nextSn = _members.isEmpty
        ? 1
        : _members.map((m) => m.serialNumber).reduce(
                (a, b) => a > b ? a : b) +
            1;

    _showEditDialog(
      KendriyaSamitiMember(
        serialNumber: nextSn,
        name: const {'en': '', 'ne': ''},
        position: const {'en': '', 'ne': ''},
        phone: '',
        address: const {'en': '', 'ne': ''},
      ),
      isNew: true,
    );
  }

  void _editMember(int index) {
    if (!_ensureAdminAccess()) return;
    _showEditDialog(_members[index], isNew: false, index: index);
  }

  void _deleteMember(int index) {
    if (!_ensureAdminAccess()) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.delete),
          content: Text(
              'Remove ${_members[index].localizedName('en')} from the list?'),
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
                setState(() => _members.removeAt(index));
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

  void _showEditDialog(KendriyaSamitiMember member,
      {required bool isNew, int? index}) {
    final nameEnCtrl = TextEditingController(text: member.name['en'] ?? '');
    final nameNeCtrl = TextEditingController(text: member.name['ne'] ?? '');
    final posEnCtrl =
        TextEditingController(text: member.position['en'] ?? '');
    final posNeCtrl =
        TextEditingController(text: member.position['ne'] ?? '');
    final phoneCtrl = TextEditingController(text: member.phone);
    final addrEnCtrl =
        TextEditingController(text: member.address['en'] ?? '');
    final addrNeCtrl =
        TextEditingController(text: member.address['ne'] ?? '');
    final snCtrl = TextEditingController(
        text: member.serialNumber.toString());
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
                    controller: snCtrl,
                    decoration:
                        const InputDecoration(labelText: 'S.N / क्र.सं'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameEnCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Name (English)'),
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
                    controller: posEnCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Position (English)'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: posNeCtrl,
                    decoration:
                        const InputDecoration(labelText: 'पद (नेपाली)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Phone / फोन'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: addrEnCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Address (English)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: addrNeCtrl,
                    decoration:
                        const InputDecoration(labelText: 'ठेगाना (नेपाली)'),
                  ),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (context, setDialogState) {
                      final hasNetworkPhoto =
                          !removePhoto &&
                          member.photoUrl != null &&
                          member.photoUrl!.isNotEmpty;
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
                                      ? NetworkImage(member.photoUrl!)
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

                final serialNumber = int.tryParse(snCtrl.text.trim());
                if (serialNumber == null || serialNumber <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Serial number must be greater than 0.'),
                    ),
                  );
                  return;
                }

                final duplicateSn = _members.asMap().entries.any((entry) =>
                    entry.value.serialNumber == serialNumber &&
                    (isNew || entry.key != index));
                if (duplicateSn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Serial number already exists.'),
                    ),
                  );
                  return;
                }

                setState(() => isUploadingPhoto = true);

                String? photoUrl = member.photoUrl;
                try {
                  if (selectedPhotoFile != null) {
                    final storageService = ref.read(storageServiceProvider);
                    final memberKey = _memberPhotoKey(
                      serialNumber,
                      nameEnCtrl.text.trim(),
                      nameNeCtrl.text.trim(),
                    );
                    photoUrl = await storageService.uploadKendriyaPhoto(
                      memberKey,
                      selectedPhotoFile!,
                      previousPublicUrl: member.photoUrl,
                    );
                  } else if (removePhoto) {
                    final storageService = ref.read(storageServiceProvider);
                    await storageService.deleteByPublicUrl(member.photoUrl);
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

                final updated = KendriyaSamitiMember(
                  serialNumber: serialNumber,
                  name: {
                    'en': nameEnCtrl.text.trim(),
                    'ne': nameNeCtrl.text.trim().isNotEmpty
                        ? nameNeCtrl.text.trim()
                        : nameEnCtrl.text.trim(),
                  },
                  position: {
                    'en': posEnCtrl.text.trim(),
                    'ne': posNeCtrl.text.trim().isNotEmpty
                        ? posNeCtrl.text.trim()
                        : posEnCtrl.text.trim(),
                  },
                  phone: phoneCtrl.text.trim(),
                  address: {
                    'en': addrEnCtrl.text.trim(),
                    'ne': addrNeCtrl.text.trim().isNotEmpty
                        ? addrNeCtrl.text.trim()
                        : addrEnCtrl.text.trim(),
                  },
                    photoUrl: photoUrl,
                );

                setState(() {
                  if (isNew) {
                    _members.add(updated);
                  } else if (index != null) {
                    _members[index] = updated;
                  }
                  // Sort by serial number
                  _members.sort(
                      (a, b) => a.serialNumber.compareTo(b.serialNumber));
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

  String _memberPhotoKey(int serialNumber, String nameEn, String nameNe) {
    final raw = 'sn_${serialNumber}_${nameEn}_$nameNe'.toLowerCase();
    final normalized = raw
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    return normalized.isEmpty ? 'sn_$serialNumber' : normalized;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = ref.watch(isAdminProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.kendriyaSamiti)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.editContent} — ${l10n.kendriyaSamiti}'),
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
        onPressed: isAdmin ? _addMember : null,
        child: const Icon(Icons.add),
      ),
      body: _members.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_add,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(l10n.noCommitteeMembers,
                      style: TextStyle(color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: isAdmin ? _addMember : null,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addMember),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _members.length,
              onReorder: (oldIndex, newIndex) {
                if (!isAdmin) return;
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _members.removeAt(oldIndex);
                  _members.insert(newIndex, item);
                  // Re-number
                  for (int i = 0; i < _members.length; i++) {
                    _members[i] = _members[i].copyWith(serialNumber: i + 1);
                  }
                });
              },
              itemBuilder: (context, index) {
                final member = _members[index];
                return Card(
                  key: ValueKey(
                      '${member.serialNumber}_${member.name['en']}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      child: Text(
                        '${member.serialNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      member.localizedName('en'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${member.localizedPosition('en')} • ${member.phone}',
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
                          onPressed: isAdmin ? () => _editMember(index) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 18, color: Colors.red),
                          onPressed: isAdmin ? () => _deleteMember(index) : null,
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
