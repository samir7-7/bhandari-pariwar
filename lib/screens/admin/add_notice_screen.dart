import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/models/notice.dart';
import 'package:bhandari_pariwar/services/notice_service.dart';
import 'package:bhandari_pariwar/services/storage_service.dart';
import 'package:bhandari_pariwar/services/auth_service.dart';

class AddNoticeScreen extends ConsumerStatefulWidget {
  const AddNoticeScreen({super.key});

  @override
  ConsumerState<AddNoticeScreen> createState() => _AddNoticeScreenState();
}

class _AddNoticeScreenState extends ConsumerState<AddNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleEnController = TextEditingController();
  final _titleNeController = TextEditingController();
  final _bodyEnController = TextEditingController();
  final _bodyNeController = TextEditingController();
  bool _sendNotification = true;
  File? _imageFile;
  bool _isLoading = false;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addNotice),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title (English)
              TextFormField(
                controller: _titleEnController,
                decoration: InputDecoration(
                  labelText: '${l10n.noticeTitle} (English)',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Title (Nepali)
              TextFormField(
                controller: _titleNeController,
                decoration: InputDecoration(
                  labelText: '${l10n.noticeTitle} (${l10n.nepali})',
                ),
              ),
              const SizedBox(height: 16),

              // Body (English)
              TextFormField(
                controller: _bodyEnController,
                decoration: InputDecoration(
                  labelText: '${l10n.noticeBody} (English)',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Body is required' : null,
              ),
              const SizedBox(height: 16),

              // Body (Nepali)
              TextFormField(
                controller: _bodyNeController,
                decoration: InputDecoration(
                  labelText: '${l10n.noticeBody} (${l10n.nepali})',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),

              // Image picker
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: Text(_imageFile != null ? 'Image selected' : l10n.photo),
              ),
              if (_imageFile != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _imageFile!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Send notification toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.sendNotification),
                value: _sendNotification,
                onChanged: (v) => setState(() => _sendNotification = v),
              ),
              const SizedBox(height: 24),

              // Publish button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _publish,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.publish),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final storageService = ref.read(storageServiceProvider);
    final file = await storageService.pickImage();
    if (file != null) {
      setState(() => _imageFile = File(file.path));
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final noticeService = ref.read(noticeServiceProvider);
      final storageService = ref.read(storageServiceProvider);
      final authService = ref.read(authServiceProvider);

      final title = <String, String>{
        'en': _titleEnController.text.trim(),
      };
      if (_titleNeController.text.trim().isNotEmpty) {
        title['ne'] = _titleNeController.text.trim();
      }

      final body = <String, String>{
        'en': _bodyEnController.text.trim(),
      };
      if (_bodyNeController.text.trim().isNotEmpty) {
        body['ne'] = _bodyNeController.text.trim();
      }

      final notice = Notice(
        id: '',
        title: title,
        body: body,
        publishedAt: DateTime.now(),
        createdBy: authService.currentUser?.uid ?? '',
        notifyUsers: _sendNotification,
      );

      final noticeId = await noticeService.addNotice(notice);

      // Upload image if selected.
      if (_imageFile != null) {
        final imageUrl =
            await storageService.uploadNoticeImage(noticeId, _imageFile!);
        await noticeService.updateNotice(noticeId, {
          'imageUrl': imageUrl,
        });
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
