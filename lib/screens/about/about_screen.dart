import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/providers/content_provider.dart';
import 'package:bhandari_pariwar/providers/auth_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';
import 'package:bhandari_pariwar/screens/about/kendriya_samiti_screen.dart';
import 'package:bhandari_pariwar/screens/about/bidesh_samiti_screen.dart';
import 'package:bhandari_pariwar/screens/about/elder_sayings_screen.dart';
import 'package:bhandari_pariwar/screens/about/memorial_sayings_screen.dart';
import 'package:bhandari_pariwar/screens/about/acknowledgements_screen.dart';
import 'package:bhandari_pariwar/screens/about/gallery_screen.dart' as bhandari_gallery;

class AboutScreen extends ConsumerWidget {
  final VoidCallback? onBack;

  const AboutScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = ref.watch(isAdminProvider);
    final langCode = ref.watch(currentLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              )
            : null,
        title: Text(l10n.about),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FamilyOverviewCard(langCode: langCode, isAdmin: isAdmin),
          const SizedBox(height: 16),
          _AcknowledgementsCard(langCode: langCode),
          const SizedBox(height: 16),
          _HistoryCard(langCode: langCode, isAdmin: isAdmin),
          const SizedBox(height: 16),
          _KendriyaSamitiCard(langCode: langCode),
          const SizedBox(height: 16),
          _BideshSamitiCard(langCode: langCode),
          const SizedBox(height: 16),
          _MemorialSayingsCard(langCode: langCode),
          const SizedBox(height: 16),
          _ElderSayingsCard(langCode: langCode),
          const SizedBox(height: 16),
          _GalleryCard(langCode: langCode),
        ],
      ),
    );
  }
}

class _AcknowledgementsCard extends StatelessWidget {
  final String langCode;

  const _AcknowledgementsCard({required this.langCode});

  @override
  Widget build(BuildContext context) {
    final isNepali = langCode == 'ne';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.workspace_premium, color: Color(0xFF8B5A2B)),
        title: Text(
          isNepali ? 'कृतज्ञता तथा धन्यवाद' : 'Acknowledgements & Thanks',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isNepali
              ? 'पारिवारिक विवरण लेखन कार्यमा सहयोग गर्नुहुने सबैप्रति सम्मान'
              : 'Gratitude to everyone who made this family documentation possible',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AcknowledgementsScreen(),
            ),
          );
        },
      ),
    );
  }
}

class _FamilyOverviewCard extends ConsumerWidget {
  final String langCode;
  final bool isAdmin;

  const _FamilyOverviewCard({
    required this.langCode,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contentAsync = ref.watch(familyOverviewProvider);

    return Card(
      child: contentAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${l10n.error}: $e'),
        ),
        data: (content) {
          if (content == null) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.familyOverview),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.home, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        content.localizedTitle(langCode),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => context
                            .push('/admin/edit-content/family_overview'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  content.localizedBody(langCode),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(height: 1.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  final String langCode;
  final bool isAdmin;

  const _HistoryCard({
    required this.langCode,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final contentAsync = ref.watch(historyContentProvider);

    return Card(
      child: contentAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${l10n.error}: $e'),
        ),
        data: (content) {
          if (content == null) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.historyAndSayings),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        content.localizedTitle(langCode),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () =>
                            context.push('/admin/edit-content/history'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (content.body != null)
                  Text(
                    content.localizedBody(langCode),
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.5),
                  ),
                if (content.sections != null)
                  ...content.sections!.map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.localizedHeading(langCode),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            section.localizedBody(langCode),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MemorialSayingsCard extends StatelessWidget {
  final String langCode;

  const _MemorialSayingsCard({required this.langCode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.local_florist, color: Color(0xFF6A1B9A)),
        title: Text(
          l10n.memorialSayings,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(l10n.memorialSayingsSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const MemorialSayingsScreen(),
            ),
          );
        },
      ),
    );
  }
}

class _KendriyaSamitiCard extends StatelessWidget {
  final String langCode;

  const _KendriyaSamitiCard({required this.langCode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.groups, color: Color(0xFF8B4513)),
        title: Text(
          l10n.kendriyaSamiti,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(l10n.bhandariSamajNepal),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const KendriyaSamitiScreen(),
            ),
          );
        },
      ),
    );
  }
}

class _BideshSamitiCard extends StatelessWidget {
  final String langCode;

  const _BideshSamitiCard({required this.langCode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.public, color: Color(0xFF1B5E20)),
        title: Text(
          l10n.bideshSamiti,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(l10n.bhandariSamajNepal),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const BideshSamitiScreen(),
            ),
          );
        },
      ),
    );
  }
}

class _ElderSayingsCard extends StatelessWidget {
  final String langCode;

  const _ElderSayingsCard({required this.langCode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.format_quote, color: Color(0xFFB8860B)),
        title: Text(
          l10n.elderSayings,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(l10n.elderSayingsSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ElderSayingsScreen(),
            ),
          );
        },
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  final String langCode;

  const _GalleryCard({required this.langCode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.photo_library, color: Color(0xFFC2185B)),
        title: Text(
          l10n.gallery,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(l10n.gallerySubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const bhandari_gallery.GalleryScreen(),
            ),
          );
        },
      ),
    );
  }
}
