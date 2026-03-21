import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/models/elder_saying.dart';
import 'package:bhandari_pariwar/providers/content_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';
import 'package:bhandari_pariwar/providers/auth_provider.dart';
import 'package:bhandari_pariwar/screens/about/edit_elder_sayings_screen.dart';

class ElderSayingsScreen extends ConsumerWidget {
  const ElderSayingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sayingsAsync = ref.watch(elderSayingsProvider);
    final langCode = ref.watch(currentLanguageProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.elderSayings),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n.editContent,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EditElderSayingsScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: sayingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (content) {
          if (content == null || content.sayings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.format_quote,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(l10n.noElderSayings,
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth >= 900
              ? 4
              : screenWidth >= 640
                  ? 3
                  : 2;

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.82,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: content.sayings.length,
            itemBuilder: (context, index) {
              final saying = content.sayings[index];
              return _ElderPreviewCard(
                saying: saying,
                langCode: langCode,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _ElderSayingDetailScreen(
                        saying: saying,
                        langCode: langCode,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ElderSayingDetailScreen extends StatelessWidget {
  final ElderSaying saying;
  final String langCode;

  const _ElderSayingDetailScreen({
    required this.saying,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.elderSayings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          _ElderSayingCard(saying: saying, langCode: langCode),
        ],
      ),
    );
  }
}

class _ElderPreviewCard extends StatelessWidget {
  final ElderSaying saying;
  final String langCode;
  final VoidCallback onTap;

  const _ElderPreviewCard({
    required this.saying,
    required this.langCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9EFE0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFB8860B).withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6D4C2A).withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
          child: Column(
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFB8860B),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _buildPhoto(saying.photoUrl, 74),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                saying.localizedName(langCode),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A3520),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                saying.localizedTitle(langCode),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFF8B5A2B).withValues(alpha: 0.9),
                  fontStyle: FontStyle.italic,
                  height: 1.25,
                ),
              ),
              const Spacer(),
              Text(
                'Tap to read',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B5A2B).withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(String? photoUrl, double size) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => SizedBox(
          width: size,
          height: size,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => _placeholderIcon(size),
      );
    }
    return _placeholderIcon(size);
  }

  Widget _placeholderIcon(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFF5E6C8),
      child: Icon(
        Icons.person,
        size: size * 0.45,
        color: const Color(0xFF6D4C2A),
      ),
    );
  }
}

class _ElderSayingCard extends StatelessWidget {
  final ElderSaying saying;
  final String langCode;

  const _ElderSayingCard({
    required this.saying,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Photo with decorative frame
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer golden ring
              Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFB8860B),
                      const Color(0xFFDAA520),
                      const Color(0xFFB8860B).withValues(alpha: 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB8860B).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
              // Photo circle
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF5E6C8),
                ),
                child: ClipOval(
                  child: _buildPhoto(saying.photoUrl, 140),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Elder name
          Text(
            saying.localizedName(langCode),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6D4C2A),
                ),
            textAlign: TextAlign.center,
          ),

          // Title / description
          if (saying.localizedTitle(langCode).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              saying.localizedTitle(langCode),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB8860B),
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 20),

          // Quote card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6C8).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFB8860B).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                // Opening quote mark
                Text(
                  '\u201C',
                  style: TextStyle(
                    fontSize: 48,
                    fontFamily: 'Georgia',
                    height: 0.7,
                    color: const Color(0xFFB8860B).withValues(alpha: 0.4),
                  ),
                ),

                const SizedBox(height: 4),

                // Saying text
                Text(
                  saying.localizedSaying(langCode),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.8,
                        color: const Color(0xFF4A3520),
                        fontSize: 15,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // Closing quote mark
                Text(
                  '\u201D',
                  style: TextStyle(
                    fontSize: 48,
                    fontFamily: 'Georgia',
                    height: 0.7,
                    color: const Color(0xFFB8860B).withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Decorative divider
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 1,
                color: const Color(0xFFB8860B).withValues(alpha: 0.3),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.auto_awesome,
                size: 14,
                color: const Color(0xFFB8860B).withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 1,
                color: const Color(0xFFB8860B).withValues(alpha: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(String? photoUrl, double size) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => SizedBox(
          width: size,
          height: size,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, __, ___) => _placeholderIcon(size),
      );
    }
    return _placeholderIcon(size);
  }

  Widget _placeholderIcon(double size) {
    return Container(
      width: size,
      height: size,
      color: const Color(0xFFF5E6C8),
      child: Icon(
        Icons.person,
        size: size * 0.45,
        color: const Color(0xFF6D4C2A),
      ),
    );
  }
}
