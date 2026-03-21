import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';
import 'package:bhandari_pariwar/providers/notice_provider.dart';
import 'package:bhandari_pariwar/screens/about/kendriya_samiti_screen.dart';
import 'package:bhandari_pariwar/screens/about/bidesh_samiti_screen.dart';
import 'package:bhandari_pariwar/screens/about/elder_sayings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final void Function(int tab) onNavigateToTab;

  const DashboardScreen({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(allMembersProvider);
    final noticesAsync = ref.watch(allNoticesProvider);
    final maxGen = ref.watch(maxDisplayGenerationProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroHeight = (screenWidth * 0.9).clamp(280.0, 460.0).toDouble();
    final horizontalPadding =
      (screenWidth * 0.04).clamp(12.0, 28.0).toDouble();
    final heroMainTitleSize =
      (screenWidth * 0.058).clamp(18.0, 32.0).toDouble();
    final heroSubTitleSize =
      (screenWidth * 0.046).clamp(14.0, 24.0).toDouble();
    final heroThirdTitleSize =
      (screenWidth * 0.052).clamp(16.0, 28.0).toDouble();
    final chipTextSize = (screenWidth * 0.034).clamp(12.0, 15.0).toDouble();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero header with Rishi image and community banner text
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
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    30,
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: heroHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x33221A44),
                              Color(0x1AFFFFFF),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 12,
                              left: 8,
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0x33FFD77A),
                                  border: Border.all(
                                    color: const Color(0x55FFD77A),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 18,
                              right: 8,
                              child: Container(
                                width: 66,
                                height: 66,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0x22FFD77A),
                                  border: Border.all(
                                    color: const Color(0x44FFD77A),
                                  ),
                                ),
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/rishi_dashboard.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => Image.asset(
                                  'assets/images/vasista_guru.png',
                                  fit: BoxFit.cover,
                                  alignment: Alignment.topCenter,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  18,
                                  horizontalPadding,
                                  14,
                                ),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x00000000),
                                      Color(0x7F000000),
                                      Color(0xB2000000),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'वसिष्ठ भण्डारी समाज',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFFFFE082),
                                        fontSize: heroMainTitleSize,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'धर्मानन्द भण्डारीको',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: heroSubTitleSize,
                                        fontWeight: FontWeight.w700,
                                        height: 1.1,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'पारिवारिक विवरण स्मारिका',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFFFFF3CD),
                                        fontSize: heroThirdTitleSize,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.appTitle,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.welcomeSubtitle,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        child: const Text(
                          'वंश, परम्परा र सम्वन्धहरुको जीवित अभिलेख',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: chipTextSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Stats row — 4 cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: membersAsync.when(
                data: (members) {
                  final totalCount = members.length;

                  return Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people,
                          label: l10n.totalMembers,
                          value: '$totalCount',
                          color: const Color(0xFF6D4C2A),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.account_tree,
                          label: l10n.generation,
                          value: '$maxGen',
                          color: const Color(0xFFB8860B),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people,
                        label: l10n.totalMembers,
                        value: '...',
                        color: const Color(0xFF6D4C2A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.campaign,
                        label: l10n.recentNotices,
                        value: '...',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                error: (_, __) => const SizedBox.shrink(),
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
                    icon: Icons.groups,
                    title: l10n.kendriyaSamiti,
                    subtitle: l10n.bhandariSamajNepal,
                    color: const Color(0xFF8B4513),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const KendriyaSamitiScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _QuickLinkCard(
                    icon: Icons.public,
                    title: l10n.bideshSamiti,
                    subtitle: l10n.bhandariSamajNepal,
                    color: const Color(0xFF1B5E20),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BideshSamitiScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _QuickLinkCard(
                    icon: Icons.format_quote,
                    title: l10n.elderSayings,
                    subtitle: l10n.elderSayingsSubtitle,
                    color: const Color(0xFFB8860B),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ElderSayingsScreen(),
                        ),
                      );
                    },
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
