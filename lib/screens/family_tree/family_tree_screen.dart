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
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  List<Member> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });
    _searchFocusNode.requestFocus();
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
    });
    ref.read(highlightedMemberProvider.notifier).state = null;
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
    // Ensure their ancestors are expanded so they're visible.
    final members = ref.read(allMembersProvider).valueOrNull ?? [];
    _expandAncestors(member, members);

    // Highlight and focus.
    ref.read(highlightedMemberProvider.notifier).state = member.id;

    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
    });

    // Clear highlight after 4 seconds.
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        ref.read(highlightedMemberProvider.notifier).state = null;
      }
    });
  }

  void _expandAncestors(Member member, List<Member> members) {
    final memberMap = {for (final m in members) m.id: m};
    final toExpand = <String>[];

    // Walk up the parent chain to expand all ancestors.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(allMembersProvider);
    final langCode = ref.watch(currentLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white70,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              )
            : Text(l10n.familyTree),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _stopSearch,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _startSearch,
              tooltip: l10n.searchMember,
            ),
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                final members =
                    ref.read(allMembersProvider).valueOrNull ?? [];
                if (value == 'expand') {
                  ref
                      .read(expandedNodesProvider.notifier)
                      .expandAll(members);
                } else if (value == 'collapse') {
                  ref.read(expandedNodesProvider.notifier).collapseAll();
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
              ],
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          TreeCanvas(
            focusMemberId: widget.focusMemberId ??
                ref.watch(highlightedMemberProvider),
          ),
          // Search results overlay.
          if (_isSearching && _searchResults.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 4,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final member = _searchResults[index];
                      final name = member.localizedName(langCode);
                      final isMale = member.isMale;

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: isMale
                              ? const Color(0xFFE8F0FE)
                              : const Color(0xFFFCE4EC),
                          child: Icon(
                            isMale ? Icons.person : Icons.person_outline,
                            size: 16,
                            color: isMale
                                ? const Color(0xFF5B8DB8)
                                : const Color(0xFFC48B9F),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: member.parentId != null
                            ? Builder(builder: (_) {
                                final parent = ref.watch(
                                    memberByIdProvider(member.parentId!));
                                return Text(
                                  parent?.localizedName(langCode) ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                );
                              })
                            : null,
                        trailing: Icon(
                          Icons.my_location,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onTap: () => _selectMember(member),
                      );
                    },
                  ),
                ),
              ),
            ),
          // Empty search hint.
          if (_isSearching &&
              _searchController.text.isNotEmpty &&
              _searchResults.isEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off,
                            size: 32, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noResults,
                          style:
                              TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
