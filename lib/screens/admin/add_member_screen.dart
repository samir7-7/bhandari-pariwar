import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/models/member.dart';
import 'package:bhandari_pariwar/services/member_service.dart';
import 'package:bhandari_pariwar/services/storage_service.dart';
import 'package:bhandari_pariwar/services/auth_service.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  final String? parentId;
  final bool asSpouse;
  final String? editMemberId;

  const AddMemberScreen({
    super.key,
    this.parentId,
    this.asSpouse = false,
    this.editMemberId,
  });

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameEnController = TextEditingController();
  final _nameNeController = TextEditingController();
  String _gender = 'male';
  DateTime? _birthDate;
  DateTime? _deathDate;
  bool _isAlive = true;
  File? _photoFile;
  bool _isLoading = false;
  int _birthOrder = 0;

  bool get _isEditing => widget.editMemberId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadMemberData();
    }
  }

  void _loadMemberData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final member = ref.read(memberByIdProvider(widget.editMemberId!));
      if (member != null) {
        _nameEnController.text = member.name['en'] ?? '';
        _nameNeController.text = member.name['ne'] ?? '';
        setState(() {
          _gender = member.gender;
          _birthDate = member.birthDate;
          _deathDate = member.deathDate;
          _isAlive = member.isAlive;
          _birthOrder = member.birthOrder;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameNeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editMember : l10n.addMember),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo picker
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        _photoFile != null ? FileImage(_photoFile!) : null,
                    child: _photoFile == null
                        ? const Icon(Icons.camera_alt, size: 32)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name (English)
              TextFormField(
                controller: _nameEnController,
                decoration: InputDecoration(
                  labelText: '${l10n.name} (English)',
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),

              // Name (Nepali)
              TextFormField(
                controller: _nameNeController,
                decoration: InputDecoration(
                  labelText: '${l10n.name} (${l10n.nepali})',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Gender
              Text(l10n.gender,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _gender,
                onChanged: (v) => setState(() => _gender = v ?? _gender),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(l10n.male),
                        value: 'male',
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(l10n.female),
                        value: 'female',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Birth date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cake),
                title: Text(l10n.birthDate),
                subtitle: Text(_birthDate != null
                    ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                    : 'Not set'),
                onTap: () => _pickDate(isBirth: true),
              ),
              const SizedBox(height: 8),

              // Alive toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_isAlive ? l10n.alive : l10n.deceased),
                value: _isAlive,
                onChanged: (v) => setState(() {
                  _isAlive = v;
                  if (v) _deathDate = null;
                }),
              ),

              // Death date
              if (!_isAlive) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.star),
                  title: Text(l10n.deathDate),
                  subtitle: Text(_deathDate != null
                      ? '${_deathDate!.day}/${_deathDate!.month}/${_deathDate!.year}'
                      : 'Not set'),
                  onTap: () => _pickDate(isBirth: false),
                ),
              ],
              const SizedBox(height: 16),

              // Birth order
              TextFormField(
                initialValue: _birthOrder.toString(),
                decoration: const InputDecoration(
                  labelText: 'Birth Order (0-based)',
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    _birthOrder = int.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final storageService = ref.read(storageServiceProvider);
    final file = await storageService.pickImage();
    if (file != null) {
      setState(() => _photoFile = File(file.path));
    }
  }

  Future<void> _pickDate({required bool isBirth}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isBirth ? (_birthDate ?? now) : (_deathDate ?? now),
      firstDate: DateTime(1800),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isBirth) {
          _birthDate = picked;
        } else {
          _deathDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final memberService = ref.read(memberServiceProvider);
      final storageService = ref.read(storageServiceProvider);
      final authService = ref.read(authServiceProvider);

      String? photoUrl;

      final name = <String, String>{
        'en': _nameEnController.text.trim(),
      };
      if (_nameNeController.text.trim().isNotEmpty) {
        name['ne'] = _nameNeController.text.trim();
      }

      if (_isEditing) {
        // Upload photo if changed.
        if (_photoFile != null) {
          photoUrl = await storageService.uploadMemberPhoto(
            widget.editMemberId!,
            _photoFile!,
          );
        }

        final updates = <String, dynamic>{
          'name': name,
          'gender': _gender,
          'birthDate': _birthDate?.toIso8601String(),
          'deathDate': _deathDate?.toIso8601String(),
          'isAlive': _isAlive,
          'birthOrder': _birthOrder,
        };
        if (photoUrl != null) {
          updates['photoUrl'] = photoUrl;
        }

        await memberService.updateMember(widget.editMemberId!, updates);
      } else {
        // Create new member.
        final newMember = Member(
          id: '',
          name: name,
          gender: _gender,
          birthDate: _birthDate,
          deathDate: _deathDate,
          isAlive: _isAlive,
          parentId: widget.asSpouse ? null : widget.parentId,
          birthOrder: _birthOrder,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: authService.currentUser?.uid,
        );

        final newId = await memberService.addMember(newMember);

        // Upload photo if selected.
        if (_photoFile != null) {
          photoUrl = await storageService.uploadMemberPhoto(newId, _photoFile!);
          await memberService.updateMember(newId, {'photoUrl': photoUrl});
        }

        // If adding as spouse, link both members.
        if (widget.asSpouse && widget.parentId != null) {
          await memberService.setSpouseLink(widget.parentId!, newId);
        }
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
