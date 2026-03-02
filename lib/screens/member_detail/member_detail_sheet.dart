import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';

class MemberDetailSheet extends ConsumerWidget {
  final String memberId;

  const MemberDetailSheet({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberByIdProvider(memberId));
    final langCode = ref.watch(currentLanguageProvider);
    final l10n = AppLocalizations.of(context)!;
    final childrenMap = ref.watch(childrenMapProvider);

    if (member == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Member not found')),
      );
    }

    final children = childrenMap[member.id] ?? [];
    final spouse = member.spouseId != null
        ? ref.watch(memberByIdProvider(member.spouseId!))
        : null;
    final parent = member.parentId != null
        ? ref.watch(memberByIdProvider(member.parentId!))
        : null;

    final dateFormat = DateFormat('dd MMM yyyy');

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Photo
              if (member.photoUrl != null)
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      CachedNetworkImageProvider(member.photoUrl!),
                )
              else
                CircleAvatar(
                  radius: 50,
                  backgroundColor: member.isMale
                      ? const Color(0xFF4A90D9).withValues(alpha: 0.2)
                      : const Color(0xFFE91E8C).withValues(alpha: 0.2),
                  child: Icon(
                    member.isMale ? Icons.person : Icons.person_outline,
                    size: 50,
                    color: member.isMale
                        ? const Color(0xFF4A90D9)
                        : const Color(0xFFE91E8C),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                member.localizedName(langCode),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                member.isMale ? l10n.male : l10n.female,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              if (!member.isAlive)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.deceased,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Divider(),
              // Dates
              if (member.birthDate != null)
                _InfoRow(
                  icon: Icons.cake,
                  label: l10n.born,
                  value: dateFormat.format(member.birthDate!),
                ),
              if (member.deathDate != null)
                _InfoRow(
                  icon: Icons.star,
                  label: l10n.died,
                  value: dateFormat.format(member.deathDate!),
                ),
              // Relationships
              if (parent != null)
                _InfoRow(
                  icon: Icons.person,
                  label: l10n.parent,
                  value: parent.localizedName(langCode),
                ),
              if (spouse != null)
                _InfoRow(
                  icon: Icons.favorite,
                  label: l10n.spouse,
                  value: spouse.localizedName(langCode),
                ),
              if (children.isNotEmpty)
                _InfoRow(
                  icon: Icons.child_care,
                  label: l10n.children,
                  value: children
                      .map((c) => c.localizedName(langCode))
                      .join(', '),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
