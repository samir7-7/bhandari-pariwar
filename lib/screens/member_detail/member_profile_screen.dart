import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/models/member.dart';
import 'package:bhandari_pariwar/providers/auth_provider.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MemberProfileScreen extends ConsumerWidget {
  final String memberId;

  const MemberProfileScreen({
    super.key,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(allMembersProvider);
    final langCode = ref.watch(currentLanguageProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home?tab=tree');
                  }
                },
              )
            : null,
        title: Text(l10n.familyTree),
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.error,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3E2723),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(allMembersProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (members) {
          final memberMap = {for (final member in members) member.id: member};
          final member = memberMap[memberId];
          if (member == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.noResults,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/home?tab=tree'),
                      icon: const Icon(Icons.account_tree),
                      label: Text(l10n.goToInTree),
                    ),
                  ],
                ),
              ),
            );
          }

          final childrenMap = ref.watch(childrenMapProvider);
          final generations = ref.watch(memberDisplayGenerationProvider);
          final isAdmin = ref.watch(isAdminProvider);

          final parent =
              member.parentId == null ? null : memberMap[member.parentId!];
          final children = childrenMap[member.id] ?? const <Member>[];
          final spouses = member.allSpouseIds
              .map((id) => memberMap[id])
              .whereType<Member>()
              .toList();

          final fatherName = member.localizedFatherName(langCode).trim();
          final motherName = member.localizedMotherName(langCode).trim();

          final explicitFather = _findByName(members, fatherName, langCode);
          final explicitMother = _findByName(members, motherName, langCode);

          final father = parent?.isMale == true
              ? parent
              : (explicitFather ??
                  (parent == null
                      ? null
                      : _firstSpouseByGender(parent, memberMap, male: true)));

          final mother = parent?.isMale == false
              ? parent
              : (explicitMother ??
                  (father == null
                      ? null
                      : _firstSpouseByGender(father, memberMap, male: false)));

          final grandfather = father?.parentId == null
              ? null
              : memberMap[father!.parentId!];
          final sons = children.where((child) => child.isMale).toList();
          final daughters = children.where((child) => !child.isMale).toList();

          final dateFormat = DateFormat('dd MMM yyyy');
          final baseGeneration = ref.watch(generationBaseProvider);
          final int gen = generations[member.id] ?? baseGeneration;

          final displayBirthDateAd = member.birthDateAd ?? member.birthDate;
          final birthPlace = member.localizedBirthPlace(langCode).trim();
          final currentAddress = member.localizedCurrentAddress(langCode).trim();
          final permanentAddress =
              member.localizedPermanentAddress(langCode).trim();
          final education =
              member.localizedEducationOrProfession(langCode).trim();
          final note = member.localizedNote(langCode).trim();

          return Container(
            color: const Color(0xFFF9F0E1),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                _ProfileHeader(member: member, langCode: langCode, gen: gen),
                const SizedBox(height: 12),
                _DetailSection(
                  title: l10n.personalDetails,
                  children: [
                    if (displayBirthDateAd != null)
                      _DetailRow(
                        icon: Icons.cake_outlined,
                        label: l10n.birthAD,
                        value: dateFormat.format(displayBirthDateAd),
                      ),
                    if ((member.birthDateBs ?? '').trim().isNotEmpty)
                      _DetailRow(
                        icon: Icons.event_note_outlined,
                        label: l10n.birthBS,
                        value: member.birthDateBs!.trim(),
                      ),
                    if (member.deathDate != null)
                      _DetailRow(
                        icon: Icons.history_toggle_off,
                        label: l10n.died,
                        value: dateFormat.format(member.deathDate!),
                      ),
                    if (birthPlace.isNotEmpty)
                      _DetailRow(
                        icon: Icons.place_outlined,
                        label: l10n.birthPlace,
                        value: birthPlace,
                      ),
                    if (currentAddress.isNotEmpty)
                      _DetailRow(
                        icon: Icons.home_outlined,
                        label: l10n.currentAddress,
                        value: currentAddress,
                      ),
                    if (permanentAddress.isNotEmpty)
                      _DetailRow(
                        icon: Icons.location_city_outlined,
                        label: l10n.permanentAddress,
                        value: permanentAddress,
                      ),
                    if ((member.mobilePrimary ?? '').trim().isNotEmpty)
                      _DetailRow(
                        icon: Icons.phone_outlined,
                        label: l10n.mobile,
                        value: member.mobilePrimary!.trim(),
                      ),
                    if ((member.mobileSecondary ?? '').trim().isNotEmpty)
                      _DetailRow(
                        icon: Icons.phone_android_outlined,
                        label: l10n.altMobile,
                        value: member.mobileSecondary!.trim(),
                      ),
                    if ((member.email ?? '').trim().isNotEmpty)
                      _DetailRow(
                        icon: Icons.email_outlined,
                        label: l10n.email,
                        value: member.email!.trim(),
                      ),
                    if (education.isNotEmpty)
                      _DetailRow(
                        icon: Icons.school_outlined,
                        label: l10n.educationProfession,
                        value: education,
                      ),
                    if ((member.bloodGroup ?? '').trim().isNotEmpty)
                      _DetailRow(
                        icon: Icons.bloodtype_outlined,
                        label: l10n.bloodGroup,
                        value: member.bloodGroup!.trim(),
                      ),
                    if (member.familyCount != null)
                      _DetailRow(
                        icon: Icons.groups_outlined,
                        label: l10n.familyCount,
                        value: member.familyCount.toString(),
                      ),
                    if (note.isNotEmpty)
                      _DetailRow(
                        icon: Icons.format_quote_outlined,
                        label: l10n.notes,
                        value: note,
                      ),
                    if (displayBirthDateAd == null &&
                        (member.birthDateBs ?? '').trim().isEmpty &&
                        member.deathDate == null &&
                        birthPlace.isEmpty &&
                        currentAddress.isEmpty &&
                        permanentAddress.isEmpty &&
                        (member.mobilePrimary ?? '').trim().isEmpty &&
                        (member.mobileSecondary ?? '').trim().isEmpty &&
                        (member.email ?? '').trim().isEmpty &&
                        education.isEmpty &&
                        (member.bloodGroup ?? '').trim().isEmpty &&
                        member.familyCount == null &&
                        note.isEmpty)
                      Text(
                        l10n.noAdditionalDetails,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _DetailSection(
                  title: l10n.relationships,
                  children: [
                    if (parent != null)
                      _LinkedMemberRow(
                        icon: Icons.person_outline,
                        label: l10n.parent,
                        member: parent,
                        langCode: langCode,
                        onTap: (target) => _openMember(context, target),
                      ),
                    _LinkedMemberRow(
                      icon: Icons.badge_outlined,
                      label: l10n.fatherName,
                      member: father,
                      langCode: langCode,
                      fallbackText: fatherName,
                      onTap: (target) => _openMember(context, target),
                    ),
                    _LinkedMemberRow(
                      icon: Icons.badge,
                      label: l10n.grandfatherName,
                      member: grandfather,
                      langCode: langCode,
                      onTap: (target) => _openMember(context, target),
                    ),
                    _LinkedMemberRow(
                      icon: Icons.badge_outlined,
                      label: l10n.motherName,
                      member: mother,
                      langCode: langCode,
                      fallbackText: motherName,
                      onTap: (target) => _openMember(context, target),
                    ),
                    _LinkedMemberWrap(
                      icon: Icons.favorite_outline,
                      label: spouses.length > 1
                          ? '${l10n.spouse}s'
                          : l10n.spouse,
                      members: spouses,
                      langCode: langCode,
                      onTap: (target) => _openMember(context, target),
                    ),
                    _LinkedMemberWrap(
                      icon: Icons.child_care_outlined,
                      label: l10n.children,
                      members: children,
                      langCode: langCode,
                      onTap: (target) => _openMember(context, target),
                    ),
                    _LinkedMemberWrap(
                      icon: Icons.boy_outlined,
                      label: l10n.sons,
                      members: sons,
                      langCode: langCode,
                      onTap: (target) => _openMember(context, target),
                    ),
                    _LinkedMemberWrap(
                      icon: Icons.girl_outlined,
                      label: l10n.daughters,
                      members: daughters,
                      langCode: langCode,
                      onTap: (target) => _openMember(context, target),
                    ),
                  ],
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 12),
                  _DetailSection(
                    title: l10n.adminActions,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ActionChip(
                            icon: Icons.child_care,
                            label: l10n.addChildToMember,
                            onTap: () =>
                                context.push('/admin/add-member?parentId=${member.id}'),
                          ),
                          _ActionChip(
                            icon: Icons.favorite,
                            label: l10n.addSpouseToMember,
                            onTap: () => context.push(
                              '/admin/add-member?parentId=${member.id}&asSpouse=true',
                            ),
                          ),
                          _ActionChip(
                            icon: Icons.edit_outlined,
                            label: l10n.editThisMember,
                            onTap: () => context.push('/admin/edit-member/${member.id}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  static void _openMember(BuildContext context, Member member) {
    context.push('/member/${member.id}');
  }

  static Member? _firstSpouseByGender(
    Member member,
    Map<String, Member> memberMap, {
    required bool male,
  }) {
    for (final spouseId in member.allSpouseIds) {
      final spouse = memberMap[spouseId];
      if (spouse == null) continue;
      if (spouse.isMale == male) return spouse;
    }
    return null;
  }

  static Member? _findByName(
      List<Member> members, String name, String languageCode) {
    if (name.isEmpty) return null;
    final target = name.toLowerCase();
    for (final member in members) {
      if (member.localizedName(languageCode).toLowerCase() == target) {
        return member;
      }
      final names = member.name.values.map((value) => value.toLowerCase());
      if (names.contains(target)) {
        return member;
      }
    }
    return null;
  }
}

class _ProfileHeader extends StatelessWidget {
  final Member member;
  final String langCode;
  final int gen;

  const _ProfileHeader({
    required this.member,
    required this.langCode,
    required this.gen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCFB27A).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: member.isMale
                    ? const Color(0xFFB8860B)
                    : const Color(0xFFA0522D),
                width: 2,
              ),
            ),
            child: member.photoUrl != null
                ? CircleAvatar(
                    radius: 34,
                    backgroundImage: CachedNetworkImageProvider(member.photoUrl!),
                  )
                : CircleAvatar(
                    radius: 34,
                    backgroundColor:
                        (member.isMale ? const Color(0xFF4A90D9) : const Color(0xFFE91E8C))
                            .withValues(alpha: 0.14),
                    child: Icon(
                      member.isMale ? Icons.person : Icons.person_outline,
                      size: 30,
                      color: member.isMale
                          ? const Color(0xFF4A90D9)
                          : const Color(0xFFE91E8C),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.localizedName(langCode),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3E2723),
                      ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _HeaderTag(
                      text: member.isMale ? l10n.male : l10n.female,
                      color: member.isMale
                          ? const Color(0xFF5B8DB8)
                          : const Color(0xFFC48B9F),
                    ),
                    _HeaderTag(
                      text: '${l10n.generation} $gen',
                      color: const Color(0xFF8B7355),
                    ),
                    if (!member.isAlive)
                      _HeaderTag(text: l10n.deceased, color: const Color(0xFF7D7D7D)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTag extends StatelessWidget {
  final String text;
  final Color color;

  const _HeaderTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCFB27A).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3E2723),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8B7355)),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF5D4037), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedMemberRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Member? member;
  final String langCode;
  final String fallbackText;
  final void Function(Member member) onTap;

  const _LinkedMemberRow({
    required this.icon,
    required this.label,
    required this.member,
    required this.langCode,
    required this.onTap,
    this.fallbackText = '',
  });

  @override
  Widget build(BuildContext context) {
    if (member == null && fallbackText.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8B7355)),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: member != null
                ? InkWell(
                    onTap: () => onTap(member!),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      child: Text(
                        member!.localizedName(langCode),
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  )
                : Text(
                    fallbackText,
                    style: const TextStyle(color: Color(0xFF5D4037), fontSize: 13),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LinkedMemberWrap extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Member> members;
  final String langCode;
  final void Function(Member member) onTap;

  const _LinkedMemberWrap({
    required this.icon,
    required this.label,
    required this.members,
    required this.langCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8B7355)),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: members
                  .map(
                    (member) => InkWell(
                      onTap: () => onTap(member),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1565C0).withValues(alpha: 0.24),
                          ),
                        ),
                        child: Text(
                          member.localizedName(langCode),
                          style: const TextStyle(
                            color: Color(0xFF1565C0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFB8860B).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFB8860B).withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF8B7355)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8B7355),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}