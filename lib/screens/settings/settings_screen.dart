import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/providers/auth_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';
import 'package:bhandari_pariwar/services/auth_service.dart';
import 'package:bhandari_pariwar/services/notification_service.dart';
import 'package:bhandari_pariwar/services/seed_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const SettingsScreen({super.key, this.onBack});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isSeeding = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = ref.watch(isAdminProvider);
    final langCode = ref.watch(currentLanguageProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // Language
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.changeLanguage),
            subtitle: Text(langCode == 'en' ? l10n.english : l10n.nepali),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, ref),
          ),
          const Divider(),
          // Notifications
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: Text(l10n.enableNotifications),
            value: notificationsEnabled,
            onChanged: (enabled) async {
              ref
                  .read(notificationsEnabledProvider.notifier)
                  .setEnabled(enabled);
              if (!enabled) {
                await NotificationService.removeToken();
              } else {
                await NotificationService.initialize();
              }
            },
          ),
          const Divider(),
          // Admin section
          if (isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.cloud_upload, color: Colors.blue),
              title: Text(l10n.seedData),
              subtitle: Text(l10n.seedDataSubtitle),
              trailing: _isSeeding
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isSeeding ? null : () => _confirmSeedData(context),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(l10n.logout),
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
              },
            ),
          ] else
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(l10n.adminLogin),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin/login'),
            ),
          const Divider(),
          // App version
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appVersion),
            subtitle: const Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.changeLanguage),
        children: [
          SimpleDialogOption(
            onPressed: () {
              ref
                  .read(currentLanguageProvider.notifier)
                  .setLanguage('en');
              Navigator.pop(ctx);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n.english),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref
                  .read(currentLanguageProvider.notifier)
                  .setLanguage('ne');
              Navigator.pop(ctx);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n.nepali),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSeedData(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.seedData),
        content: Text(l10n.seedDataConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.continueButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSeeding = true);

    try {
      final seedService = ref.read(seedServiceProvider);
      final count = await seedService.seedMembersFromAsset(
        replaceExisting: true,
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.seedDataSuccess(count))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }
}
