import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/models/member.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';
import 'package:bhandari_pariwar/screens/family_tree/member_list_view.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_canvas.dart';
import 'package:go_router/go_router.dart';

/// Provider for the currently highlighted member in the tree.
final highlightedMemberProvider = StateProvider<String?>((ref) => null);

/// Provider for the full ancestor path of the highlighted member.
/// Contains the highlighted member + all ancestors up to the root.
final highlightedPathProvider = Provider<Set<String>>((ref) {
  final highlightedId = ref.watch(highlightedMemberProvider);
  if (highlightedId == null) return {};

  final members = ref.watch(allMembersProvider).valueOrNull ?? [];
  if (members.isEmpty) return {};

  final memberMap = {for (final m in members) m.id: m};
  final path = <String>{highlightedId};
  String? currentId = memberMap[highlightedId]?.parentId;
  while (currentId != null) {
    path.add(currentId);
    currentId = memberMap[currentId]?.parentId;
  }
  return path;
});

class FamilyTreeScreen extends ConsumerStatefulWidget {
  final String? focusMemberId;

  const FamilyTreeScreen({super.key, this.focusMemberId});

  @override
  ConsumerState<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends ConsumerState<FamilyTreeScreen> {
  final _searchController = TextEditingController();
  bool _isListView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectMember(Member member) {
    final members = ref.read(treeMembersProvider);
    _expandAncestors(member, members);
    ref.read(highlightedMemberProvider.notifier).state = member.id;

    Navigator.of(context).pop(); // Close search bottom sheet

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        ref.read(highlightedMemberProvider.notifier).state = null;
      }
    });
  }

  void _expandAncestors(Member member, List<Member> members) {
    final memberMap = {for (final m in members) m.id: m};
    final toExpand = <String>[];
    String? currentId = member.parentId;
    while (currentId != null) {
      toExpand.add(currentId);
      final parent = memberMap[currentId];
      currentId = parent?.parentId;
    }
    final notifier = ref.read(expandedNodesProvider.notifier);
    for (final id in toExpand.reversed) {
      final current = ref.read(expandedNodesProvider);
      if (!current.contains(id)) {
        notifier.toggle(id);
      }
    }
  }

  void _openSearchSheet() {
    _searchController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchBottomSheet(
        searchController: _searchController,
        onSelectMember: _selectMember,
        ref: ref,
      ),
    );
  }

  void _openMemberProfile(Member member) {
    context.push('/member/${member.id}');
  }

  Member? _findDharmananda(List<Member> members) {
    for (final member in members) {
      final hasMatch = member.name.values.any(
        (value) => value.toLowerCase().contains('dharmananda'),
      );
      if (hasMatch) return member;
    }
    return null;
  }

  List<Member> _getDharmanandaSons(List<Member> members) {
    final dharmananda = _findDharmananda(members);
    if (dharmananda == null) return [];

    final sons = members
        .where((m) => m.parentId == dharmananda.id && m.isMale)
        .toList()
      ..sort((a, b) {
        final birthOrderCompare = a.birthOrder.compareTo(b.birthOrder);
        if (birthOrderCompare != 0) return birthOrderCompare;
        final sourceA = a.sourceOrder ?? 1 << 30;
        final sourceB = b.sourceOrder ?? 1 << 30;
        final sourceCompare = sourceA.compareTo(sourceB);
        if (sourceCompare != 0) return sourceCompare;
        return a.id.compareTo(b.id);
      });
    return sons;
  }

  Future<void> _openBranchSelector() async {
    final members = ref.read(allMembersProvider).valueOrNull ?? [];
    if (members.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Members are still loading.')),
      );
      return;
    }

    final langCode = ref.read(currentLanguageProvider);
    final currentBranchId = ref.read(branchRootMemberIdProvider);
    final sons = _getDharmanandaSons(members);
    final memberMap = {for (final m in members) m.id: m};

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_tree_outlined),
                title: const Text('Show Full Family Tree'),
                trailing: currentBranchId == null
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  ref.read(branchRootMemberIdProvider.notifier).state = null;
                  ref.read(highlightedMemberProvider.notifier).state = null;
                  Navigator.of(sheetContext).pop();
                },
              ),
              const Divider(height: 1),
              if (sons.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Could not find sons under Dharmananda in current data.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...sons.map((son) {
                  final spouseNames = son.allSpouseIds
                      .map((id) => memberMap[id])
                      .whereType<Member>()
                      .map((sp) => sp.localizedName(langCode))
                      .toList();

                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(son.localizedName(langCode)),
                    subtitle: spouseNames.isEmpty
                        ? null
                        : Text('Spouse: ${spouseNames.join(', ')}'),
                    trailing: currentBranchId == son.id
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      ref.read(branchRootMemberIdProvider.notifier).state = son.id;
                      ref.read(highlightedMemberProvider.notifier).state = son.id;
                      Navigator.of(sheetContext).pop();
                    },
                  );
                }),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(allMembersProvider);
    final visibleMembers = ref.watch(treeMembersProvider);
    final branchRootId = ref.watch(branchRootMemberIdProvider);
    final activeBranchMember = branchRootId == null
        ? null
        : ref.watch(memberByIdProvider(branchRootId));
    final langCode = ref.watch(currentLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        // Back button — always visible in tree screen
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    // Safety fallback: never allow router stack to become empty.
                    context.go('/home?tab=tree');
                  }
                },
              )
            : null,
        title: Text(l10n.familyTree),
        actions: [
          IconButton(
            icon: Icon(_isListView ? Icons.account_tree : Icons.view_list),
            tooltip: _isListView ? 'Tree view' : 'List view',
            onPressed: () {
              setState(() {
                _isListView = !_isListView;
              });
            },
          ),
          if (!_isListView)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _openSearchSheet,
              tooltip: l10n.searchMember,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: () => ref.invalidate(allMembersProvider),
          ),
          // Member count badge
          membersAsync.whenOrNull(
                data: (_) => Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${visibleMembers.length}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ) ??
              const SizedBox.shrink(),
          PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'expand') {
                  ref
                      .read(expandedNodesProvider.notifier)
                      .expandAll(ref.read(treeMembersProvider));
                } else if (value == 'collapse') {
                  ref.read(expandedNodesProvider.notifier).collapseAll();
                } else if (value == 'save_pdf') {
                  TreeCanvas.saveAsPdf(context);
                } else if (value == 'branch') {
                  _openBranchSelector();
                } else if (value == 'clear_branch') {
                  ref.read(branchRootMemberIdProvider.notifier).state = null;
                  ref.read(highlightedMemberProvider.notifier).state = null;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'branch',
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Select Dharmananda Branch'),
                    ],
                  ),
                ),
                if (branchRootId != null)
                  const PopupMenuItem(
                    value: 'clear_branch',
                    child: Row(
                      children: [
                        Icon(Icons.filter_alt_off_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Clear Branch Filter'),
                      ],
                    ),
                  ),
                if (!_isListView) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'expand',
                    child: Row(
                      children: [
                        const Icon(Icons.unfold_more, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.expandAll),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'collapse',
                    child: Row(
                      children: [
                        const Icon(Icons.unfold_less, size: 20),
                        const SizedBox(width: 12),
                        Text(l10n.collapseAll),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'save_pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, size: 20),
                        SizedBox(width: 12),
                        Text('Save as PDF'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (activeBranchMember != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF5ED),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCFB27A).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 18, color: Color(0xFF8B7355)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing branch: ${activeBranchMember.localizedName(langCode)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(branchRootMemberIdProvider.notifier).state = null;
                      ref.read(highlightedMemberProvider.notifier).state = null;
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isListView
                ? MemberListView(onOpenMember: _openMemberProfile)
                : TreeCanvas(
                    focusMemberId:
                        widget.focusMemberId ?? ref.watch(highlightedMemberProvider),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Beautiful search bottom sheet with vintage styling.
class _SearchBottomSheet extends StatefulWidget {
  final TextEditingController searchController;
  final void Function(Member) onSelectMember;
  final WidgetRef ref;

  const _SearchBottomSheet({
    required this.searchController,
    required this.onSelectMember,
    required this.ref,
  });

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  List<Member> _results = [];

  void _doSearch(String query) {
    final members = widget.ref.read(treeMembersProvider);
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _results = members.where((m) {
        return m.name.values
            .any((n) => n.toLowerCase().contains(lowerQuery));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langCode = widget.ref.watch(currentLanguageProvider);
    final generations = widget.ref.watch(memberDisplayGenerationProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFAF5ED), // warm parchment
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8860B).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  l10n.searchMember,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3E2723),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              // Search input
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFB8860B).withValues(alpha: 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5D4037)
                            .withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: widget.searchController,
                    autofocus: true,
                    onChanged: _doSearch,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF3E2723),
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      hintStyle: TextStyle(
                        color: const Color(0xFF8B7355).withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFFB8860B),
                        size: 22,
                      ),
                      suffixIcon:
                          widget.searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    size: 18,
                                    color: Color(0xFF8B7355),
                                  ),
                                  onPressed: () {
                                    widget.searchController.clear();
                                    _doSearch('');
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              // Result count
              if (_results.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8860B)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_results.length} found',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8B7355),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Results list
              Expanded(
                child: _results.isEmpty &&
                        widget.searchController.text.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off,
                                size: 40,
                                color: const Color(0xFF8B7355)
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noResults,
                              style: TextStyle(
                                color: const Color(0xFF8B7355)
                                    .withValues(alpha: 0.6),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_search,
                                    size: 48,
                                    color: const Color(0xFFB8860B)
                                        .withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                Text(
                                  l10n.searchHint,
                                  style: TextStyle(
                                    color: const Color(0xFF8B7355)
                                        .withValues(alpha: 0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: const Color(0xFFB8860B)
                                  .withValues(alpha: 0.12),
                              indent: 56,
                            ),
                            itemBuilder: (context, index) {
                              final member = _results[index];
                              final name =
                                  member.localizedName(langCode);
                              final isMale = member.isMale;
                              final gen = generations[member.id] ?? 0;
                              final parent = member.parentId != null
                                  ? widget.ref.watch(
                                      memberByIdProvider(
                                          member.parentId!))
                                  : null;

                              return ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isMale
                                        ? const Color(0xFFF5E6C8)
                                        : const Color(0xFFF2DDD0),
                                    border: Border.all(
                                      color: isMale
                                          ? const Color(0xFFB8860B)
                                              .withValues(alpha: 0.5)
                                          : const Color(0xFFA0522D)
                                              .withValues(alpha: 0.5),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      isMale ? '\u2642' : '\u2640',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isMale
                                            ? const Color(0xFFB8860B)
                                            : const Color(0xFF8B1A1A),
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3E2723),
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    if (parent != null)
                                      Flexible(
                                        child: Text(
                                          parent.localizedName(langCode),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: const Color(0xFF8B7355)
                                                .withValues(alpha: 0.7),
                                          ),
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (parent != null)
                                      const SizedBox(width: 6),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFB8860B)
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${l10n.generation} $gen',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF8B7355),
                                        ),
                                      ),
                                    ),
                                    if (!member.isAlive) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '\u2020',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: const Color(0xFF8B7355)
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFB8860B)
                                        .withValues(alpha: 0.1),
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    size: 16,
                                    color: Color(0xFFB8860B),
                                  ),
                                ),
                                onTap: () =>
                                    widget.onSelectMember(member),
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
