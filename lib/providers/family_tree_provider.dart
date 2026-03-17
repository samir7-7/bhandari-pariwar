import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/models/member.dart';
import 'package:bhandari_pariwar/services/member_service.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_layout.dart';

int _compareTreeOrder(Member a, Member b) {
  final birthOrderCompare = a.birthOrder.compareTo(b.birthOrder);
  if (birthOrderCompare != 0) return birthOrderCompare;

  final sourceA = a.sourceOrder ?? 1 << 30;
  final sourceB = b.sourceOrder ?? 1 << 30;
  final sourceCompare = sourceA.compareTo(sourceB);
  if (sourceCompare != 0) return sourceCompare;

  return a.id.compareTo(b.id);
}

Set<String> _collectDescendantIds(
  String rootId,
  Map<String, List<Member>> childrenMap,
) {
  final visited = <String>{};
  final stack = <String>[rootId];

  while (stack.isNotEmpty) {
    final current = stack.removeLast();
    if (!visited.add(current)) continue;
    final children = childrenMap[current] ?? const <Member>[];
    for (final child in children) {
      stack.add(child.id);
    }
  }

  return visited;
}

final allMembersProvider = StreamProvider<List<Member>>((ref) {
  final service = ref.watch(memberServiceProvider);
  return service.watchAllMembers();
});

/// When non-null, tree/list/report views are scoped to this member's lineage.
final branchRootMemberIdProvider = StateProvider<String?>((ref) => null);

/// Set of visible member IDs for selected branch root (descendants + spouses).
final branchMemberIdsProvider = Provider<Set<String>>((ref) {
  final members = ref.watch(allMembersProvider).valueOrNull ?? [];
  final branchRootId = ref.watch(branchRootMemberIdProvider);
  if (members.isEmpty || branchRootId == null) return {};

  final memberById = {for (final m in members) m.id: m};
  if (!memberById.containsKey(branchRootId)) return {};

  final childrenMap = <String, List<Member>>{};
  for (final m in members) {
    if (m.parentId != null) {
      childrenMap.putIfAbsent(m.parentId!, () => []).add(m);
    }
  }

  final visibleIds = _collectDescendantIds(branchRootId, childrenMap);

  // Include spouse cards for already visible lineage members.
  final toIncludeSpouses = visibleIds.toList(growable: false);
  for (final id in toIncludeSpouses) {
    final member = memberById[id];
    if (member == null) continue;
    for (final spouseId in member.allSpouseIds) {
      visibleIds.add(spouseId);
    }
  }

  return visibleIds;
});

/// Members used by tree/list/report area (full tree unless branch filter is set).
final treeMembersProvider = Provider<List<Member>>((ref) {
  final members = ref.watch(allMembersProvider).valueOrNull ?? [];
  final branchRootId = ref.watch(branchRootMemberIdProvider);
  if (members.isEmpty || branchRootId == null) return members;

  final visibleIds = ref.watch(branchMemberIdsProvider);
  if (visibleIds.isEmpty) return members;

  return members.where((m) => visibleIds.contains(m.id)).toList();
});

final memberByIdProvider =
    Provider.family<Member?, String>((ref, memberId) {
  final members = ref.watch(allMembersProvider).valueOrNull ?? [];
  try {
    return members.firstWhere((m) => m.id == memberId);
  } catch (_) {
    return null;
  }
});

final expandedNodesProvider =
    StateNotifierProvider<ExpandedNodesNotifier, Set<String>>((ref) {
  return ExpandedNodesNotifier();
});

class ExpandedNodesNotifier extends StateNotifier<Set<String>> {
  ExpandedNodesNotifier() : super({});

  bool _initialized = false;

  void initializeDefaults(List<Member> members, int depth) {
    if (_initialized) return;
    _initialized = true;

    final root = members.where((m) => m.isRoot).toList();
    if (root.isEmpty) return;

    final childrenMap = <String, List<Member>>{};
    for (final m in members) {
      if (m.parentId != null) {
        childrenMap.putIfAbsent(m.parentId!, () => []).add(m);
      }
    }

    final expanded = <String>{};
    void expand(String id, int currentDepth) {
      if (currentDepth >= depth) return;
      expanded.add(id);
      final children = childrenMap[id] ?? [];
      for (final child in children) {
        expand(child.id, currentDepth + 1);
      }
    }

    for (final r in root) {
      expand(r.id, 0);
      final primarySpouseId = r.primarySpouseId;
      if (primarySpouseId != null) {
        expanded.add(primarySpouseId);
      }
    }

    state = expanded;
  }

  void toggle(String nodeId) {
    if (state.contains(nodeId)) {
      state = {...state}..remove(nodeId);
    } else {
      state = {...state, nodeId};
    }
  }

  void expandAll(List<Member> members) {
    state = members.map((m) => m.id).toSet();
  }

  void collapseAll() {
    state = {};
  }

  /// Expand tree to a specific generation depth from root.
  void expandToDepth(List<Member> members, int depth) {
    final childrenMap = <String, List<Member>>{};
    for (final m in members) {
      if (m.parentId != null) {
        childrenMap.putIfAbsent(m.parentId!, () => []).add(m);
      }
    }

    final root = members.where((m) {
      if (!m.isRoot) return false;
      if (childrenMap.containsKey(m.id)) return true;
      return false;
    }).toList();
    if (root.isEmpty) return;

    final expanded = <String>{};
    void expand(String id, int currentDepth) {
      if (currentDepth >= depth) return;
      expanded.add(id);
      final children = childrenMap[id] ?? [];
      for (final child in children) {
        expand(child.id, currentDepth + 1);
      }
    }

    for (final r in root) {
      expand(r.id, 0);
      final primarySpouseId = r.primarySpouseId;
      if (primarySpouseId != null) {
        expanded.add(primarySpouseId);
      }
    }

    state = expanded;
  }
}

final childrenMapProvider =
    Provider<Map<String, List<Member>>>((ref) {
  final members = ref.watch(treeMembersProvider);
  final map = <String, List<Member>>{};
  for (final m in members) {
    if (m.parentId != null) {
      map.putIfAbsent(m.parentId!, () => []).add(m);
    }
  }
  for (final children in map.values) {
    children.sort(_compareTreeOrder);
  }
  return map;
});

final rootMembersProvider = Provider<List<Member>>((ref) {
  final members = ref.watch(treeMembersProvider);
  final childrenMap = ref.watch(childrenMapProvider);
  final branchRootId = ref.watch(branchRootMemberIdProvider);

  if (branchRootId != null) {
    final branchRoots = members.where((m) => m.id == branchRootId).toList();
    if (branchRoots.isNotEmpty) {
      return branchRoots;
    }
  }

  // Find the genealogical root: a member with no parent who has children.
  // Spouses also have parentId == null, but they don't have children
  // mapped to them (children point to father via parentId).
  final roots = members.where((m) {
    if (!m.isRoot) return false;
    // Prefer members who have children in the tree
    if (childrenMap.containsKey(m.id)) return true;
    return false;
  }).toList();

  // If no root with children found, fall back to any root member
  if (roots.isEmpty) {
    final fallbackRoots = members.where((m) => m.isRoot).toList()
      ..sort(_compareTreeOrder);
    return fallbackRoots;
  }
  roots.sort(_compareTreeOrder);
  return roots;
});

final treeLayoutProvider =
    Provider<Map<String, Offset>>((ref) {
  final members = ref.watch(treeMembersProvider);
  if (members.isEmpty) return {};

  final expanded = ref.watch(expandedNodesProvider);
  final childrenMap = ref.watch(childrenMapProvider);
  final roots = ref.watch(rootMembersProvider);
  if (roots.isEmpty) return {};

  final spouseMap = <String, List<String>>{};
  for (final m in members) {
    if (m.allSpouseIds.isNotEmpty) {
      spouseMap[m.id] = m.allSpouseIds;
    }
  }

  final rootId = roots.first.id;
  final engine = TreeLayoutEngine(
    childrenMap: childrenMap,
    spouseMap: spouseMap,
    expandedNodes: expanded,
  );
  return engine.computeLayout(rootId);
});

final treeCanvasSizeProvider = Provider<Size>((ref) {
  final positions = ref.watch(treeLayoutProvider);
  if (positions.isEmpty) return Size.zero;

  double maxX = 0;
  double maxY = 0;
  for (final offset in positions.values) {
    if (offset.dx + TreeLayoutEngine.nodeWidth > maxX) {
      maxX = offset.dx + TreeLayoutEngine.nodeWidth;
    }
    if (offset.dy + TreeLayoutEngine.nodeHeight > maxY) {
      maxY = offset.dy + TreeLayoutEngine.nodeHeight;
    }
  }
  return Size(maxX + 16, maxY + 16);
});

final memberSearchProvider = StateProvider<String>((ref) => '');

/// Display baseline for the genealogical root generation.
/// Dharmananda should appear as generation 13.
final generationBaseProvider = Provider<int>((ref) => 13);

final filteredMembersProvider = Provider<List<Member>>((ref) {
  final members = ref.watch(treeMembersProvider);
  final query = ref.watch(memberSearchProvider).toLowerCase();
  if (query.isEmpty) return members;

  return members.where((m) {
    return m.name.values.any((n) => n.toLowerCase().contains(query));
  }).toList();
});

/// Provides the generation depth for each member (root = 0).
final memberGenerationProvider =
    Provider<Map<String, int>>((ref) {
  final members = ref.watch(treeMembersProvider);
  if (members.isEmpty) return {};

  final childrenMap = ref.watch(childrenMapProvider);
  final roots = ref.watch(rootMembersProvider);

  final generations = <String, int>{};
  final memberById = {for (final member in members) member.id: member};

  void computeDepth(String id, int depth) {
    generations[id] = depth;
    // Also assign generation to spouse(s)
    final member = memberById[id];
    for (final spouseId in member?.allSpouseIds ?? const <String>[]) {
      generations[spouseId] = depth;
    }
    final children = childrenMap[id] ?? [];
    for (final child in children) {
      computeDepth(child.id, depth + 1);
    }
  }

  for (final root in roots) {
    computeDepth(root.id, 0);
  }

  return generations;
});

/// Display generation for each member after applying configured baseline.
final memberDisplayGenerationProvider = Provider<Map<String, int>>((ref) {
  final raw = ref.watch(memberGenerationProvider);
  if (raw.isEmpty) return const {};

  final base = ref.watch(generationBaseProvider);
  return {
    for (final entry in raw.entries) entry.key: entry.value + (base - 1),
  };
});

/// Maximum generation depth in the tree.
final maxGenerationDepthProvider = Provider<int>((ref) {
  final generations = ref.watch(memberGenerationProvider);
  if (generations.isEmpty) return 0;
  return generations.values.fold(0, (max, v) => v > max ? v : max);
});

/// Maximum display generation number with baseline applied.
final maxDisplayGenerationProvider = Provider<int>((ref) {
  final maxDepth = ref.watch(maxGenerationDepthProvider);
  final base = ref.watch(generationBaseProvider);
  if (maxDepth == 0) return base;
  return maxDepth + (base - 1);
});

/// Current generation depth setting for the slider.
final generationDepthSettingProvider = StateProvider<int>((ref) => 3);
