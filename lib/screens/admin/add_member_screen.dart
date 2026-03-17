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
import 'package:bhandari_pariwar/providers/settings_provider.dart';

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
  bool _hasUnsavedChanges = false;
  int _birthOrder = 0;

  // Smart parent matching fields.
  String? _selectedParentId;
  final _fatherNameController = TextEditingController();
  final _grandfatherNameController = TextEditingController();
  final _birthDateBsController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _mobilePrimaryController = TextEditingController();
  final _mobileSecondaryController = TextEditingController();
  final _emailController = TextEditingController();
  final _educationController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _familyCountController = TextEditingController();
  final _sonsCountController = TextEditingController();
  final _daughtersCountController = TextEditingController();
  final _notesController = TextEditingController();
  List<Member> _parentCandidates = [];

  bool get _isEditing => widget.editMemberId != null;

  @override
  void initState() {
    super.initState();
    _selectedParentId = widget.parentId;
    if (_isEditing) {
      _loadMemberData();
    }
    // Default gender to opposite of spouse target.
    if (widget.asSpouse && widget.parentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = ref.read(memberByIdProvider(widget.parentId!));
        if (target != null) {
          setState(() {
            _gender = target.isMale ? 'female' : 'male';
          });
        }
      });
    }
  }

  void _loadMemberData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final member = ref.read(memberByIdProvider(widget.editMemberId!));
      if (member != null) {
        _nameEnController.text = member.name['en'] ?? '';
        _nameNeController.text = member.name['ne'] ?? '';
        _birthDateBsController.text = member.birthDateBs ?? '';
        _birthPlaceController.text = member.birthPlace['en'] ?? '';
        _currentAddressController.text = member.currentAddress['en'] ?? '';
        _permanentAddressController.text = member.permanentAddress['en'] ?? '';
        _fatherNameController.text = member.fatherName['en'] ?? '';
        _motherNameController.text = member.motherName['en'] ?? '';
        _mobilePrimaryController.text = member.mobilePrimary ?? '';
        _mobileSecondaryController.text = member.mobileSecondary ?? '';
        _emailController.text = member.email ?? '';
        _educationController.text = member.educationOrProfession['en'] ?? '';
        _bloodGroupController.text = member.bloodGroup ?? '';
        _familyCountController.text = member.familyCount?.toString() ?? '';
        _sonsCountController.text = member.sonsCount?.toString() ?? '';
        _daughtersCountController.text = member.daughtersCount?.toString() ?? '';
        _notesController.text = member.notes['en'] ?? '';
        setState(() {
          _gender = member.gender;
          _birthDate = member.birthDateAd ?? member.birthDate;
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
    _fatherNameController.dispose();
    _grandfatherNameController.dispose();
    _birthDateBsController.dispose();
    _birthPlaceController.dispose();
    _currentAddressController.dispose();
    _permanentAddressController.dispose();
    _motherNameController.dispose();
    _mobilePrimaryController.dispose();
    _mobileSecondaryController.dispose();
    _emailController.dispose();
    _educationController.dispose();
    _bloodGroupController.dispose();
    _familyCountController.dispose();
    _sonsCountController.dispose();
    _daughtersCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Match members by father + grandfather name.
  void _smartMatchParent() {
    final members = ref.read(allMembersProvider).valueOrNull ?? [];
    final memberMap = {for (final m in members) m.id: m};

    final fatherQuery = _fatherNameController.text.trim().toLowerCase();
    final gfQuery = _grandfatherNameController.text.trim().toLowerCase();

    if (fatherQuery.isEmpty) {
      setState(() => _parentCandidates = []);
      return;
    }

    final candidates = <Member>[];
    for (final m in members) {
      // Check if any name value matches the father-name query.
      final nameMatch =
          m.name.values.any((n) => n.toLowerCase().contains(fatherQuery));
      if (!nameMatch) continue;

      if (gfQuery.isNotEmpty) {
        // Also check grandfather match (parent of this candidate).
        final parent = m.parentId != null ? memberMap[m.parentId] : null;
        if (parent == null) continue;
        final gfMatch =
            parent.name.values.any((n) => n.toLowerCase().contains(gfQuery));
        if (!gfMatch) continue;
      }

      candidates.add(m);
    }

    setState(() => _parentCandidates = candidates);
  }

  String _getAncestryChain(Member member) {
    final members = ref.read(allMembersProvider).valueOrNull ?? [];
    final memberMap = {for (final m in members) m.id: m};
    final langCode = ref.read(currentLanguageProvider);

    final parts = <String>[];
    String? currentId = member.parentId;
    int depth = 0;
    while (currentId != null && depth < 3) {
      final ancestor = memberMap[currentId];
      if (ancestor == null) break;
      parts.add(ancestor.localizedName(langCode));
      currentId = ancestor.parentId;
      depth++;
    }
    return parts.isNotEmpty ? parts.join(' → ') : '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langCode = ref.watch(currentLanguageProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Resolve pre-selected parent for display.
    final preSelectedParent =
        _selectedParentId != null && !widget.asSpouse
            ? ref.watch(memberByIdProvider(_selectedParentId!))
            : null;
    final spouseTarget =
        widget.asSpouse && widget.parentId != null
            ? ref.watch(memberByIdProvider(widget.parentId!))
            : null;

    return WillPopScope(
      onWillPop: _handleSystemBack,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackPressed,
          ),
          title: Text(_isEditing
              ? l10n.editMember
              : widget.asSpouse
                  ? l10n.addSpouseToMember
                  : l10n.addMember),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            onChanged: _markDirty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Context banner: who are we adding under/to?
              if (spouseTarget != null)
                _ContextBanner(
                  icon: Icons.favorite,
                  color: Colors.pink.shade400,
                  label: '${l10n.addSpouseToMember}:',
                  memberName: spouseTarget.localizedName(langCode),
                ),
              if (preSelectedParent != null && !widget.asSpouse)
                _ContextBanner(
                  icon: Icons.person,
                  color: primaryColor,
                  label: '${l10n.parent}:',
                  memberName: preSelectedParent.localizedName(langCode),
                ),
              if (spouseTarget != null || preSelectedParent != null)
                const SizedBox(height: 16),

              // Photo picker.
              Center(
                child: GestureDetector(
                  onTap: _isLoading ? null : _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _photoFile != null
                            ? FileImage(_photoFile!)
                            : null,
                        child: _photoFile == null
                            ? Icon(Icons.camera_alt,
                                size: 32, color: Colors.grey.shade400)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name (English).
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

              // Name (Nepali).
              TextFormField(
                controller: _nameNeController,
                decoration: InputDecoration(
                  labelText: '${l10n.name} (${l10n.nepali})',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              // Gender selector.
              Text(l10n.gender,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _gender,
                onChanged: (v) => setState(() {
                  _gender = v ?? _gender;
                  _markDirty();
                }),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(l10n.male),
                        value: 'male',
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text(l10n.female),
                        value: 'female',
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Parent selection (when not editing and no parentId).
              if (!_isEditing && !widget.asSpouse && widget.parentId == null)
                _buildParentSelector(l10n, langCode),

              // Birth date.
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.cake, color: Colors.green.shade400),
                title: Text(l10n.birthDate),
                subtitle: Text(
                  _birthDate != null
                      ? '${_birthDate!.year}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.day.toString().padLeft(2, '0')}'
                      : 'Not set',
                  style: TextStyle(
                    color: _birthDate != null
                        ? Colors.black87
                        : Colors.grey.shade400,
                  ),
                ),
                trailing: Icon(Icons.calendar_today,
                    size: 18, color: Colors.grey.shade400),
                onTap: () => _pickDate(isBirth: true),
              ),
              const SizedBox(height: 8),

              // Alive toggle.
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_isAlive ? l10n.alive : l10n.deceased),
                value: _isAlive,
                activeThumbColor: primaryColor,
                onChanged: (v) => setState(() {
                  _isAlive = v;
                  if (v) _deathDate = null;
                  _markDirty();
                }),
              ),

              // Death date.
              if (!_isAlive) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.star, color: Colors.grey.shade500),
                  title: Text(l10n.deathDate),
                  subtitle: Text(
                    _deathDate != null
                        ? '${_deathDate!.year}/${_deathDate!.month.toString().padLeft(2, '0')}/${_deathDate!.day.toString().padLeft(2, '0')}'
                        : 'Not set',
                    style: TextStyle(
                      color: _deathDate != null
                          ? Colors.black87
                          : Colors.grey.shade400,
                    ),
                  ),
                  trailing: Icon(Icons.calendar_today,
                      size: 18, color: Colors.grey.shade400),
                  onTap: () => _pickDate(isBirth: false),
                ),
              ],
              const SizedBox(height: 16),

              // Birth order (only for children, not spouses).
              if (!widget.asSpouse) ...[              TextFormField(
                initialValue: _birthOrder.toString(),
                decoration: InputDecoration(
                  labelText: 'Birth Order (0-based)',
                  prefixIcon: Icon(Icons.format_list_numbered,
                      color: Colors.grey.shade600),
                  helperText: 'Position among siblings (0 = eldest)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => _birthOrder = int.tryParse(v) ?? 0,
              ),
              ],
              const SizedBox(height: 12),

              TextFormField(
                controller: _birthDateBsController,
                decoration: const InputDecoration(
                  labelText: 'Birth Date (BS)',
                  prefixIcon: Icon(Icons.event_note_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthPlaceController,
                decoration: const InputDecoration(
                  labelText: 'Birth Place',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currentAddressController,
                decoration: const InputDecoration(
                  labelText: 'Current Address',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _permanentAddressController,
                decoration: const InputDecoration(
                  labelText: 'Permanent Address',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _motherNameController,
                decoration: const InputDecoration(
                  labelText: 'Mother Name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobilePrimaryController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Primary Mobile',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mobileSecondaryController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Secondary Mobile',
                  prefixIcon: Icon(Icons.phone_android_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _educationController,
                decoration: const InputDecoration(
                  labelText: 'Education / Profession',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bloodGroupController,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _familyCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Family Count',
                        prefixIcon: Icon(Icons.groups_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sonsCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sons',
                        prefixIcon: Icon(Icons.boy_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _daughtersCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Daughters',
                        prefixIcon: Icon(Icons.girl_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.sticky_note_2_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Save button.
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _save,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(l10n.save,
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _markDirty() {
    if (_isLoading || _hasUnsavedChanges) return;
    _hasUnsavedChanges = true;
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_hasUnsavedChanges || _isLoading) return true;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Leave this page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return shouldDiscard ?? false;
  }

  Future<void> _handleBackPressed() async {
    final canLeave = await _confirmDiscardChanges();
    if (!canLeave || !mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home?tab=tree');
    }
  }

  Future<bool> _handleSystemBack() async {
    return _confirmDiscardChanges();
  }

  /// Builds the parent selector section with smart matching.
  Widget _buildParentSelector(AppLocalizations l10n, String langCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header.
        Row(
          children: [
            Icon(Icons.account_tree_outlined,
                size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              l10n.selectParent,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const Spacer(),
            if (_selectedParentId != null)
              TextButton.icon(
                onPressed: () => setState(() {
                  _selectedParentId = null;
                  _parentCandidates = [];
                  _fatherNameController.clear();
                  _grandfatherNameController.clear();
                }),
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.selectParentHint,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 12),

        // Selected parent chip (if one is picked).
        if (_selectedParentId != null) ...[
          Builder(builder: (_) {
            final parent = ref.watch(memberByIdProvider(_selectedParentId!));
            if (parent == null) return const SizedBox.shrink();
            final ancestry = _getAncestryChain(parent);
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.green.shade600, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parent.localizedName(langCode),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        if (ancestry.isNotEmpty)
                          Text(
                            ancestry,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Smart matching: Father + Grandfather name.
        if (_selectedParentId == null) ...[
          TextFormField(
            controller: _fatherNameController,
            decoration: InputDecoration(
              labelText: l10n.fatherName,
              prefixIcon: const Icon(Icons.person_search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _smartMatchParent,
              ),
            ),
            onChanged: (_) => _smartMatchParent(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _grandfatherNameController,
            decoration: InputDecoration(
              labelText: l10n.grandfatherName,
              prefixIcon: const Icon(Icons.person_pin),
              helperText: 'Optional – narrows the search',
            ),
            onChanged: (_) => _smartMatchParent(),
          ),
          const SizedBox(height: 12),

          // Matching results.
          if (_fatherNameController.text.trim().isNotEmpty) ...[
            if (_parentCandidates.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_parentCandidates.length} match${_parentCandidates.length == 1 ? '' : 'es'} found',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _parentCandidates.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final candidate = _parentCandidates[index];
                    final ancestry = _getAncestryChain(candidate);
                    final childrenMap = ref.watch(childrenMapProvider);
                    final childCount =
                        childrenMap[candidate.id]?.length ?? 0;

                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: candidate.isMale
                            ? const Color(0xFFE8F0FE)
                            : const Color(0xFFFCE4EC),
                        child: Icon(
                          candidate.isMale
                              ? Icons.person
                              : Icons.person_outline,
                          size: 16,
                          color: candidate.isMale
                              ? const Color(0xFF5B8DB8)
                              : const Color(0xFFC48B9F),
                        ),
                      ),
                      title: Text(
                        candidate.localizedName(langCode),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        ancestry.isNotEmpty
                            ? '$ancestry • $childCount children'
                            : '$childCount children',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      onTap: () => setState(() {
                        _selectedParentId = candidate.id;
                      }),
                    );
                  },
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.noMatchFound,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
        ],

        Divider(color: Colors.grey.shade200),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _pickPhoto() async {
    final storageService = ref.read(storageServiceProvider);
    final file = await storageService.pickImage();
    if (file != null) {
      setState(() {
        _photoFile = File(file.path);
      });
      _markDirty();
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
      _markDirty();
    }
  }

  String? get _resolvedParentId {
    if (widget.asSpouse) return null;
    return _selectedParentId ?? widget.parentId;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Require parent for new non-spouse members unless editing.
    if (!_isEditing && !widget.asSpouse && _resolvedParentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectParent),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final memberService = ref.read(memberServiceProvider);
      final storageService = ref.read(storageServiceProvider);
      final authService = ref.read(authServiceProvider);
      final l10n = AppLocalizations.of(context)!;

      String? photoUrl;

      final name = <String, String>{
        'en': _nameEnController.text.trim(),
      };
      if (_nameNeController.text.trim().isNotEmpty) {
        name['ne'] = _nameNeController.text.trim();
      }

      final fatherNameMap = _localizedMap(_fatherNameController.text);
      final motherNameMap = _localizedMap(_motherNameController.text);
      final birthPlaceMap = _localizedMap(_birthPlaceController.text);
      final currentAddressMap = _localizedMap(_currentAddressController.text);
      final permanentAddressMap = _localizedMap(_permanentAddressController.text);
      final educationMap = _localizedMap(_educationController.text);
      final notesMap = _localizedMap(_notesController.text);

      if (_isEditing) {
        // Upload photo if changed.
        if (_photoFile != null) {
          final existing = ref.read(memberByIdProvider(widget.editMemberId!));
          photoUrl = await storageService.uploadMemberPhoto(
            widget.editMemberId!,
            _photoFile!,
            previousPublicUrl: existing?.photoUrl,
          );
        }

        final updates = <String, dynamic>{
          'name': name,
          'gender': _gender,
          'birthDate': _birthDate?.toIso8601String(),
          'birthDateAd': _birthDate?.toIso8601String(),
          'birthDateBs': _birthDateBsController.text.trim().isEmpty
              ? null
              : _birthDateBsController.text.trim(),
          'deathDate': _deathDate?.toIso8601String(),
          'isAlive': _isAlive,
          'birthOrder': _birthOrder,
          'fatherName': fatherNameMap,
          'motherName': motherNameMap,
          'birthPlace': birthPlaceMap,
          'currentAddress': currentAddressMap,
          'permanentAddress': permanentAddressMap,
          'mobilePrimary': _nullIfEmpty(_mobilePrimaryController.text),
          'mobileSecondary': _nullIfEmpty(_mobileSecondaryController.text),
          'email': _nullIfEmpty(_emailController.text),
          'educationOrProfession': educationMap,
          'bloodGroup': _nullIfEmpty(_bloodGroupController.text),
          'familyCount': _parseOptionalInt(_familyCountController.text),
          'sonsCount': _parseOptionalInt(_sonsCountController.text),
          'daughtersCount': _parseOptionalInt(_daughtersCountController.text),
          'notes': notesMap,
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
          birthDateAd: _birthDate,
          birthDateBs: _nullIfEmpty(_birthDateBsController.text),
          deathDate: _deathDate,
          isAlive: _isAlive,
          parentId: _resolvedParentId,
          fatherName: fatherNameMap,
          motherName: motherNameMap,
          birthPlace: birthPlaceMap,
          currentAddress: currentAddressMap,
          permanentAddress: permanentAddressMap,
          mobilePrimary: _nullIfEmpty(_mobilePrimaryController.text),
          mobileSecondary: _nullIfEmpty(_mobileSecondaryController.text),
          email: _nullIfEmpty(_emailController.text),
          educationOrProfession: educationMap,
          bloodGroup: _nullIfEmpty(_bloodGroupController.text),
          familyCount: _parseOptionalInt(_familyCountController.text),
          sonsCount: _parseOptionalInt(_sonsCountController.text),
          daughtersCount: _parseOptionalInt(_daughtersCountController.text),
          notes: notesMap,
          birthOrder: _birthOrder,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: authService.currentUser?.uid,
        );

        final newId = await memberService.addMember(newMember);

        // Upload photo if selected.
        if (_photoFile != null) {
          photoUrl =
              await storageService.uploadMemberPhoto(newId, _photoFile!);
          await memberService.updateMember(newId, {'photoUrl': photoUrl});
        }

        // If adding as spouse, link both members.
        if (widget.asSpouse && widget.parentId != null) {
          await memberService.setSpouseLink(widget.parentId!, newId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.memberAdded),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        _hasUnsavedChanges = false;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home?tab=tree');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save member. $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  String? _nullIfEmpty(String value) {
    final v = value.trim();
    return v.isEmpty ? null : v;
  }

  int? _parseOptionalInt(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  Map<String, String?> _localizedMap(String englishValue) {
    final value = englishValue.trim();
    if (value.isEmpty) return const {};
    return {'en': value};
  }
}

/// Banner showing context about who this member is being added to.
class _ContextBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String memberName;

  const _ContextBanner({
    required this.icon,
    required this.color,
    required this.label,
    required this.memberName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$label ',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: memberName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
