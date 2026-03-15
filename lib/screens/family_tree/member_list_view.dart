import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/models/member.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberListView extends ConsumerStatefulWidget {
  final void Function(Member member) onOpenMember;

  const MemberListView({
    super.key,
    required this.onOpenMember,
  });

  @override
  ConsumerState<MemberListView> createState() => _MemberListViewState();
}

class _MemberListViewState extends ConsumerState<MemberListView> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(allMembersProvider);
    final langCode = ref.watch(currentLanguageProvider);
    final generations = ref.watch(memberGenerationProvider);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: const Color(0xFFF9F0E1),
      child: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (members) {
          final memberMap = {for (final member in members) member.id: member};
          final lowerQuery = _query.trim().toLowerCase();

          final filtered = members.where((member) {
            if (lowerQuery.isEmpty) return true;

            final hasName = member.name.values.any(
              (name) => name.toLowerCase().contains(lowerQuery),
            );
            final hasId = member.id.toLowerCase().contains(lowerQuery);
            return hasName || hasId;
          }).toList()
            ..sort((a, b) {
              final genA = generations[a.id] ?? 0;
              final genB = generations[b.id] ?? 0;
              final genCompare = genA.compareTo(genB);
              if (genCompare != 0) return genCompare;

              final birthOrderCompare = a.birthOrder.compareTo(b.birthOrder);
              if (birthOrderCompare != 0) return birthOrderCompare;

              final sourceA = a.sourceOrder ?? 1 << 30;
              final sourceB = b.sourceOrder ?? 1 << 30;
              final sourceCompare = sourceA.compareTo(sourceB);
              if (sourceCompare != 0) return sourceCompare;

              return a.id.compareTo(b.id);
            });

          final grouped = <int, List<Member>>{};
          for (final member in filtered) {
            final generation = generations[member.id] ?? 0;
            grouped.putIfAbsent(generation, () => []).add(member);
          }

          final generationKeys = grouped.keys.toList()..sort();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFB8860B).withValues(alpha: 0.35),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFB8860B),
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noResults,
                          style: TextStyle(
                            color: Colors.brown.shade400,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
                        itemCount: generationKeys.length,
                        itemBuilder: (context, index) {
                          final generation = generationKeys[index];
                          final generationMembers = grouped[generation]!;
                          return _GenerationSection(
                            generationLabel: 'Generation ${generation + 1}',
                            members: generationMembers,
                            langCode: langCode,
                            memberMap: memberMap,
                            onOpenMember: widget.onOpenMember,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GenerationSection extends StatelessWidget {
  final String generationLabel;
  final List<Member> members;
  final String langCode;
  final Map<String, Member> memberMap;
  final void Function(Member member) onOpenMember;

  const _GenerationSection({
    required this.generationLabel,
    required this.members,
    required this.langCode,
    required this.memberMap,
    required this.onOpenMember,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCFB27A).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFB8860B).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$generationLabel (${members.length})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8B7355),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...members.map((member) {
            final spouses = member.allSpouseIds
                .map((spouseId) => memberMap[spouseId])
                .whereType<Member>()
                .map((spouse) => spouse.localizedName(langCode))
                .toList();

            final parent =
                member.parentId == null ? null : memberMap[member.parentId!];

            return InkWell(
              onTap: () => onOpenMember(member),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (member.isMale
                            ? const Color(0xFFB8860B)
                            : const Color(0xFFA0522D))
                        .withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: member.isMale
                          ? const Color(0xFFE8F0FE)
                          : const Color(0xFFFCE4EC),
                      child: Icon(
                        member.isMale ? Icons.male : Icons.female,
                        color: member.isMale
                            ? const Color(0xFF5B8DB8)
                            : const Color(0xFFC48B9F),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.localizedName(langCode),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _buildRelationshipLine(parent, spouses, langCode),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.brown.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF8B7355),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  static String _buildRelationshipLine(
    Member? parent,
    List<String> spouses,
    String langCode,
  ) {
    final chunks = <String>[];
    if (parent != null) {
      chunks.add('Parent: ${parent.localizedName(langCode)}');
    }
    if (spouses.isNotEmpty) {
      chunks.add('Spouse: ${spouses.join(', ')}');
    }
    if (chunks.isEmpty) {
      return 'Tap to view full profile';
    }
    return chunks.join('  |  ');
  }
}