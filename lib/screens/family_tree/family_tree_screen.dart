import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/l10n/app_localizations.dart';
import 'package:bhandari_pariwar/models/member.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_canvas.dart';

/// Provider for the currently highlighted member in the tree.
final highlightedMemberProvider = StateProvider<String?>((ref) => null);

class FamilyTreeScreen extends ConsumerStatefulWidget {
  final String? focusMemberId;

  const FamilyTreeScreen({super.key, this.focusMemberId});

  @override
  ConsumerState<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends ConsumerState<FamilyTreeScreen> {
  final _searchController = TextEditingController();
  List<Member> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final members = ref.read(allMembersProvider).valueOrNull ?? [];
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _searchResults = members.where((m) {
        return m.name.values.any((n) => n.toLowerCase().contains(lowerQuery));
      }).toList();
    });
  }

  void _selectMember(Member member) {
    final members = ref.read(allMembersProvider).valueOrNull ?? [];
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
    _searchResults = [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchBottomSheet(
        searchController: _searchController,
        onSearchChanged: (query) {
          _onSearchChanged(query);
          // Force rebuild of the sheet
          (ctx as Element).markNeedsBuild();
        },
        searchResults: _searchResults,
        onSelectMember: _selectMember,
        ref: ref,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(allMembersProvider);

    return Scaffold(
      appBar: AppBar(
        // Back button — always visible in tree screen
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(l10n.familyTree),
        actions: [
          // Search button opens bottom sheet
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearchSheet,
            tooltip: l10n.searchMember,
          ),
          // Member count badge
          membersAsync.whenOrNull(
                data: (members) => Center(
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
                        '${members.length}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ) ??
              const SizedBox.shrink(),
          // Overflow menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              final members =
                  ref.read(allMembersProvider).valueOrNull ?? [];
              if (value == 'expand') {
                ref.read(expandedNodesProvider.notifier).expandAll(members);
              } else if (value == 'collapse') {
                ref.read(expandedNodesProvider.notifier).collapseAll();
              } else if (value == 'save_pdf') {
                TreeCanvas.saveAsPdf(context);
              }
            },
            itemBuilder: (context) => [
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
          ),
        ],
      ),
      body: TreeCanvas(
        focusMemberId:
            widget.focusMemberId ?? ref.watch(highlightedMemberProvider),
      ),
    );
  }
}

/// Beautiful search bottom sheet with vintage styling.
class _SearchBottomSheet extends StatefulWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final List<Member> searchResults;
  final void Function(Member) onSelectMember;
  final WidgetRef ref;

  const _SearchBottomSheet({
    required this.searchController,
    required this.onSearchChanged,
    required this.searchResults,
    required this.onSelectMember,
    required this.ref,
  });

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  List<Member> _results = [];

  @override
  void initState() {
    super.initState();
    _results = widget.searchResults;
  }

  void _doSearch(String query) {
    final members =
        widget.ref.read(allMembersProvider).valueOrNull ?? [];
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
    final generations = widget.ref.watch(memberGenerationProvider);

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
                                        'Gen $gen',
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
