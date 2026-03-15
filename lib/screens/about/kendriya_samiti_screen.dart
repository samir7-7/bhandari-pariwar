import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/models/kendriya_samiti.dart';
import 'package:bhandari_pariwar/providers/content_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';
import 'package:bhandari_pariwar/providers/auth_provider.dart';
import 'package:bhandari_pariwar/screens/about/edit_kendriya_samiti_screen.dart';

class KendriyaSamitiScreen extends ConsumerWidget {
  const KendriyaSamitiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final samitiAsync = ref.watch(kendriyaSamitiProvider);
    final langCode = ref.watch(currentLanguageProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.kendriyaSamiti),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: l10n.editContent,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const EditKendriyaSamitiScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: samitiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (content) {
          if (content == null || content.members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(l10n.noCommitteeMembers,
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            );
          }

          // Separate president (serial 1) from the rest
          final president =
              content.members.where((m) => m.serialNumber == 1).toList();
          final others =
              content.members.where((m) => m.serialNumber != 1).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Organization title banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.bhandariSamajNepal,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.kendriyaSamiti,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // President — large featured card
                if (president.isNotEmpty)
                  _PresidentCard(
                    member: president.first,
                    langCode: langCode,
                  ),

                if (president.isNotEmpty) const SizedBox(height: 24),

                // Other members in a responsive grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount =
                        constraints.maxWidth > 500 ? 3 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: others.length,
                      itemBuilder: (context, index) {
                        return _MemberGridTile(
                          member: others[index],
                          langCode: langCode,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Large featured card for the president / head
class _PresidentCard extends StatelessWidget {
  final KendriyaSamitiMember member;
  final String langCode;

  const _PresidentCard({
    required this.member,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Photo
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildPhoto(member.photoUrl, 120),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          member.localizedName(langCode),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            member.localizedPosition(langCode),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        if (member.phone.isNotEmpty) ...[
          const SizedBox(height: 6),
          _PhoneChip(phone: member.phone),
        ],
      ],
    );
  }
}

/// Grid tile for each committee member (2-3 per row)
class _MemberGridTile extends StatelessWidget {
  final KendriyaSamitiMember member;
  final String langCode;

  const _MemberGridTile({
    required this.member,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Photo
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _buildPhoto(member.photoUrl, 72),
              ),
            ),
            const SizedBox(height: 8),
            // Name
            Text(
              member.localizedName(langCode),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            // Position
            Text(
              member.localizedPosition(langCode),
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (member.phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              _PhoneChip(phone: member.phone, compact: true),
            ],
          ],
        ),
      ),
    );
  }
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
      size: size * 0.5,
      color: const Color(0xFF6D4C2A),
    ),
  );
}

class _PhoneChip extends StatelessWidget {
  final String phone;
  final bool compact;

  const _PhoneChip({required this.phone, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (phone.isEmpty) return const SizedBox.shrink();

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _makeCall(phone),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone,
                size: compact ? 10 : 14, color: Colors.green),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                phone,
                style: TextStyle(
                  fontSize: compact ? 9 : 11,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
