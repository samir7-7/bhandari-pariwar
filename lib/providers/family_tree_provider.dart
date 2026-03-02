import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/models/member.dart';
import 'package:bhandari_pariwar/services/member_service.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_layout.dart';

final allMembersProvider = StreamProvider<List<Member>>((ref) {
  final service = ref.watch(memberServiceProvider);
  return service.watchAllMembers();
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
      if (r.spouseId != null) {
        expanded.add(r.spouseId!);
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
}

final childrenMapProvider =
    Provider<Map<String, List<Member>>>((ref) {
  final members = ref.watch(allMembersProvider).valueOrNull ?? [];
  final map = <String, List<Member>>{};
  for (final m in members) {
    if (m.parentId != null) {
      map.putIfAbsent(m.parentId!, () => []).add(m);
    }
  }
  for (final children in map.values) {
    children.sort((a, b) => a.birthOrder.compareTo(b.birthOrder));
  }
  return map;
});

final rootMembersProvider = Provider<List<Member>>((ref) {
  final members = ref.watch(allMembersProvider).valueOrNull ?? [];
  final childrenMap = ref.watch(childrenMapProvider);

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
    return members.where((m) => m.isRoot).toList();
  }
  return roots;
});

final treeLayoutProvider =
    Provider<Map<String, Offset>>((ref) {
  final members = ref.watch(allMembersProvider).valueOrNull ?? [];
  if (members.isEmpty) return {};

  final expanded = ref.watch(expandedNodesProvider);
  final childrenMap = ref.watch(childrenMapProvider);
  final roots = ref.watch(rootMembersProvider);
  if (roots.isEmpty) return {};

  final spouseMap = <String, String>{};
  for (final m in members) {
    if (m.spouseId != null) {
      spouseMap[m.id] = m.spouseId!;
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

final filteredMembersProvider = Provider<List<Member>>((ref) {
  final members = ref.watch(allMembersProvider).valueOrNull ?? [];
  final query = ref.watch(memberSearchProvider).toLowerCase();
  if (query.isEmpty) return members;

  return members.where((m) {
    return m.name.values.any((n) => n.toLowerCase().contains(query));
  }).toList();
});
