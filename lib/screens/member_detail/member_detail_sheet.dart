import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';

class MemberDetailSheet extends ConsumerWidget {
  final String memberId;
  final bool showAdminActions;

  const MemberDetailSheet({
    super.key,
    required this.memberId,
    this.showAdminActions = false,
  });

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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag handle.
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Photo with colored ring.
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: member.isMale
                          ? const Color(0xFF4A90D9)
                          : const Color(0xFFE91E8C),
                      width: 2,
                    ),
                  ),
                  child: member.photoUrl != null
                      ? CircleAvatar(
                          radius: 44,
                          backgroundImage:
                              CachedNetworkImageProvider(member.photoUrl!),
                        )
                      : CircleAvatar(
                          radius: 44,
                          backgroundColor: member.isMale
                              ? const Color(0xFF4A90D9)
                                  .withValues(alpha: 0.12)
                              : const Color(0xFFE91E8C)
                                  .withValues(alpha: 0.12),
                          child: Icon(
                            member.isMale
                                ? Icons.person
                                : Icons.person_outline,
                            size: 40,
                            color: member.isMale
                                ? const Color(0xFF4A90D9)
                                : const Color(0xFFE91E8C),
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                // Name.
                Text(
                  member.localizedName(langCode),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Gender + alive badge row.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: member.isMale
                            ? const Color(0xFFE8F0FE)
                            : const Color(0xFFFCE4EC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        member.isMale ? l10n.male : l10n.female,
                        style: TextStyle(
                          fontSize: 12,
                          color: member.isMale
                              ? const Color(0xFF5B8DB8)
                              : const Color(0xFFC48B9F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!member.isAlive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.deceased,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Info card.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      if (member.birthDate != null)
                        _InfoRow(
                          icon: Icons.cake_outlined,
                          label: l10n.born,
                          value: dateFormat.format(member.birthDate!),
                          iconColor: Colors.green.shade400,
                        ),
                      if (member.deathDate != null)
                        _InfoRow(
                          icon: Icons.star_outline,
                          label: l10n.died,
                          value: dateFormat.format(member.deathDate!),
                          iconColor: Colors.grey.shade500,
                        ),
                      if (parent != null)
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: l10n.parent,
                          value: parent.localizedName(langCode),
                          iconColor: primaryColor,
                        ),
                      if (spouse != null)
                        _InfoRow(
                          icon: Icons.favorite_outline,
                          label: l10n.spouse,
                          value: spouse.localizedName(langCode),
                          iconColor: Colors.red.shade300,
                        ),
                      if (children.isNotEmpty)
                        _InfoRow(
                          icon: Icons.child_care_outlined,
                          label: l10n.children,
                          value: children
                              .map((c) => c.localizedName(langCode))
                              .join(', '),
                          iconColor: Colors.orange.shade400,
                        ),
                      if (member.birthDate == null &&
                          member.deathDate == null &&
                          parent == null &&
                          spouse == null &&
                          children.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No additional details available',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Admin actions.
                if (showAdminActions) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.child_care,
                          label: l10n.addChildToMember,
                          color: Colors.green.shade600,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(
                              '/admin/add-member?parentId=${member.id}',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.favorite,
                          label: l10n.addSpouseToMember,
                          color: Colors.pink.shade400,
                          enabled: member.spouseId == null,
                          onTap: member.spouseId == null
                              ? () {
                                  Navigator.of(context).pop();
                                  context.push(
                                    '/admin/add-member?parentId=${member.id}&asSpouse=true',
                                  );
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.edit_outlined,
                          label: l10n.editThisMember,
                          color: primaryColor,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(
                              '/admin/edit-member/${member.id}',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : Colors.grey.shade400;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: effectiveColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: effectiveColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: effectiveColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
