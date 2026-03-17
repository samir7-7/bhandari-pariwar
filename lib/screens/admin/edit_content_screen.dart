import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/services/content_service.dart';
import 'package:bhandari_pariwar/services/auth_service.dart';

class EditContentScreen extends ConsumerStatefulWidget {
  final String contentId;

  const EditContentScreen({super.key, required this.contentId});

  @override
  ConsumerState<EditContentScreen> createState() => _EditContentScreenState();
}

class _EditContentScreenState extends ConsumerState<EditContentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleEnController = TextEditingController();
  final _titleNeController = TextEditingController();
  final _bodyEnController = TextEditingController();
  final _bodyNeController = TextEditingController();
  bool _isLoading = false;
  bool _dataLoaded = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    final contentService = ref.read(contentServiceProvider);
    final content = await contentService.getContent(widget.contentId);
    if (content != null && mounted) {
      setState(() {
        _titleEnController.text = content.title['en'] ?? '';
        _titleNeController.text = content.title['ne'] ?? '';
        if (content.body != null) {
          _bodyEnController.text = content.body!['en'] ?? '';
          _bodyNeController.text = content.body!['ne'] ?? '';
        }
        _dataLoaded = true;
      });
    } else {
      setState(() => _dataLoaded = true);
    }
  }

  @override
  void dispose() {
    _titleEnController.dispose();
    _titleNeController.dispose();
    _bodyEnController.dispose();
    _bodyNeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_dataLoaded) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editContent)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackPressed,
        ),
        title: Text(l10n.editContent),
      ),
      body: WillPopScope(
        onWillPop: _handleSystemBack,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            onChanged: _markDirty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text('Title', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleEnController,
                decoration: const InputDecoration(
                  labelText: 'Title (English)',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleNeController,
                decoration: const InputDecoration(
                  labelText: 'Title (Nepali)',
                ),
              ),
              const SizedBox(height: 24),
              Text('Content', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyEnController,
                decoration: const InputDecoration(
                  labelText: 'Content (English)',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bodyNeController,
                decoration: const InputDecoration(
                  labelText: 'Content (Nepali)',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
              ),
              const SizedBox(height: 32),
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
      ),
    );
  }

  void _markDirty() {
    if (_isLoading || !_dataLoaded || _hasUnsavedChanges) return;
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
      context.go('/home?tab=about');
    }
  }

  Future<bool> _handleSystemBack() async {
    return _confirmDiscardChanges();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final contentService = ref.read(contentServiceProvider);
      final authService = ref.read(authServiceProvider);

      final title = <String, String>{
        'en': _titleEnController.text.trim(),
      };
      if (_titleNeController.text.trim().isNotEmpty) {
        title['ne'] = _titleNeController.text.trim();
      }

      final body = <String, String>{};
      if (_bodyEnController.text.trim().isNotEmpty) {
        body['en'] = _bodyEnController.text.trim();
      }
      if (_bodyNeController.text.trim().isNotEmpty) {
        body['ne'] = _bodyNeController.text.trim();
      }

      await contentService.updateContent(widget.contentId, {
        'title': title,
        'body': body,
        'updatedBy': authService.currentUser?.uid,
      });

      if (mounted) {
        _hasUnsavedChanges = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content saved successfully')),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home?tab=about');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save content. $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
