import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';
import 'package:bhandari_pariwar/providers/notice_provider.dart';

class DashboardScreen extends ConsumerWidget {
  final void Function(int tab) onNavigateToTab;

  const DashboardScreen({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(allMembersProvider);
    final noticesAsync = ref.watch(allNoticesProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero header with Vasista Guru image
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/vasista_guru.png',
                          height: 160,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appTitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.welcomeSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people,
                      label: l10n.totalMembers,
                      value: membersAsync.when(
                        data: (members) => '${members.length}',
                        loading: () => '...',
                        error: (_, __) => '-',
                      ),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.campaign,
                      label: l10n.recentNotices,
                      value: noticesAsync.when(
                        data: (notices) => '${notices.length}',
                        loading: () => '...',
                        error: (_, __) => '-',
                      ),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick links
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.quickLinks,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _QuickLinkCard(
                    icon: Icons.account_tree,
                    title: l10n.viewFamilyTree,
                    subtitle: membersAsync.when(
                      data: (m) => l10n.familyMembers(m.length),
                      loading: () => l10n.loading,
                      error: (_, __) => '',
                    ),
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () => onNavigateToTab(1),
                  ),
                  const SizedBox(height: 12),
                  _QuickLinkCard(
                    icon: Icons.campaign,
                    title: l10n.viewNotices,
                    subtitle: noticesAsync.when(
                      data: (n) => n.isNotEmpty
                          ? n.first.localizedTitle(
                              Localizations.localeOf(context).languageCode)
                          : l10n.noNotices,
                      loading: () => l10n.loading,
                      error: (_, __) => '',
                    ),
                    color: Colors.orange.shade700,
                    onTap: () => onNavigateToTab(2),
                  ),
                  const SizedBox(height: 12),
                  _QuickLinkCard(
                    icon: Icons.info_outline,
                    title: l10n.aboutFamily,
                    subtitle: l10n.historyAndSayings,
                    color: Colors.teal,
                    onTap: () => onNavigateToTab(3),
                  ),
                  const SizedBox(height: 12),
                  _QuickLinkCard(
                    icon: Icons.settings,
                    title: l10n.settings,
                    subtitle: l10n.changeLanguage,
                    color: Colors.grey.shade700,
                    onTap: () => onNavigateToTab(4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickLinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
