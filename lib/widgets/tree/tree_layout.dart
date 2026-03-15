import 'dart:ui';
import 'dart:math' as math;
import 'package:bhandari_pariwar/models/member.dart';

class TreeLayoutEngine {
  static const double nodeWidth = 90.0;
  static const double nodeHeight = 36.0;
  static const double coupleGap = 5.0;
  static const double siblingGap = 6.0;
  static const double generationGap = 42.0;
  static const double padding = 12.0;

  final Map<String, List<Member>> childrenMap;
  final Map<String, List<String>> spouseMap;
  final Set<String> expandedNodes;

  final Map<String, double> _subtreeWidths = {};

  TreeLayoutEngine({
    required this.childrenMap,
    required this.spouseMap,
    required this.expandedNodes,
  });

  Map<String, Offset> computeLayout(String rootId) {
    _subtreeWidths.clear();
    _computeSubtreeWidth(rootId);

    final positions = <String, Offset>{};
    final totalWidth = _subtreeWidths[rootId] ?? _unitWidth(rootId);
    _assignPositions(rootId, padding, padding, totalWidth, positions);
    return positions;
  }

  double _unitWidth(String nodeId) {
    final spouseCount = spouseMap[nodeId]?.length ?? 0;
    if (spouseCount <= 0) return nodeWidth;
    return nodeWidth + spouseCount * (nodeWidth + coupleGap);
  }

  double _computeSubtreeWidth(String nodeId) {
    if (_subtreeWidths.containsKey(nodeId)) {
      return _subtreeWidths[nodeId]!;
    }

    final unitW = _unitWidth(nodeId);
    final children = childrenMap[nodeId] ?? [];

    if (children.isEmpty || !expandedNodes.contains(nodeId)) {
      _subtreeWidths[nodeId] = unitW;
      return unitW;
    }

    double childrenTotalWidth = 0;
    for (int i = 0; i < children.length; i++) {
      childrenTotalWidth += _computeSubtreeWidth(children[i].id);
      if (i < children.length - 1) {
        childrenTotalWidth += siblingGap;
      }
    }

    final width = math.max(unitW, childrenTotalWidth);
    _subtreeWidths[nodeId] = width;
    return width;
  }

  void _assignPositions(
    String nodeId,
    double left,
    double top,
    double allocatedWidth,
    Map<String, Offset> positions,
  ) {
    final unitW = _unitWidth(nodeId);
    final spouses = spouseMap[nodeId] ?? const <String>[];

    // Center the node (or couple) within allocated width.
    final nodeLeft = left + (allocatedWidth - unitW) / 2;
    positions[nodeId] = Offset(nodeLeft, top);

    for (int i = 0; i < spouses.length; i++) {
      final spouseId = spouses[i];
      positions[spouseId] =
          Offset(nodeLeft + nodeWidth + coupleGap + i * (nodeWidth + coupleGap), top);
    }

    final children = childrenMap[nodeId] ?? [];
    if (children.isEmpty || !expandedNodes.contains(nodeId)) return;

    double childrenTotalWidth = 0;
    for (int i = 0; i < children.length; i++) {
      childrenTotalWidth += (_subtreeWidths[children[i].id] ?? _unitWidth(children[i].id));
      if (i < children.length - 1) {
        childrenTotalWidth += siblingGap;
      }
    }

    double childLeft = left + (allocatedWidth - childrenTotalWidth) / 2;
    final childTop = top + nodeHeight + generationGap;

    for (final child in children) {
      final childAllocatedWidth =
          _subtreeWidths[child.id] ?? _unitWidth(child.id);
      _assignPositions(child.id, childLeft, childTop, childAllocatedWidth, positions);
      childLeft += childAllocatedWidth + siblingGap;
    }
  }

  /// Returns bracket-style connection data for the line painter.
  /// Groups all children of a parent into one bracket link.
  static List<BracketLink> buildBracketLinks(
    Map<String, Offset> positions,
    Map<String, List<Member>> childrenMap,
    Map<String, List<String>> spouseMap,
    Set<String> expandedNodes,
  ) {
    final links = <BracketLink>[];

    for (final entry in childrenMap.entries) {
      final parentId = entry.key;
      final children = entry.value;

      if (!positions.containsKey(parentId)) continue;
      if (!expandedNodes.contains(parentId)) continue;

      final parentPos = positions[parentId]!;
        final spouseCount = spouseMap[parentId]?.length ?? 0;
        final parentGroupWidth = spouseCount <= 0
          ? nodeWidth
          : nodeWidth + spouseCount * (nodeWidth + coupleGap);

      // Parent connection point: bottom center of couple or single node.
        final parentCenterX = parentPos.dx + parentGroupWidth / 2;
      final parentBottomY = parentPos.dy + nodeHeight;

      final childXPositions = <double>[];
      double? childTopY;

      for (final child in children) {
        if (!positions.containsKey(child.id)) continue;
        final childPos = positions[child.id]!;
        final childSpouseCount = spouseMap[child.id]?.length ?? 0;
        final childGroupWidth = childSpouseCount <= 0
          ? nodeWidth
          : nodeWidth + childSpouseCount * (nodeWidth + coupleGap);
        final childCenterX = childPos.dx + childGroupWidth / 2;
        childXPositions.add(childCenterX);
        childTopY ??= childPos.dy;
      }

      if (childXPositions.isNotEmpty && childTopY != null) {
        links.add(BracketLink(
          parentId: parentId,
          childIds: children
              .where((c) => positions.containsKey(c.id))
              .map((c) => c.id)
              .toList(),
          parentX: parentCenterX,
          parentBottomY: parentBottomY,
          childXPositions: childXPositions,
          childTopY: childTopY,
        ));
      }
    }

    return links;
  }

  /// Returns list of spouse connection bars (horizontal line between couples).
  static List<SpouseLink> buildSpouseLinks(
    Map<String, Offset> positions,
    Map<String, List<String>> spouseMap,
  ) {
    final links = <SpouseLink>[];
    final visitedPairs = <String>{};

    for (final entry in spouseMap.entries) {
      for (final spouseId in entry.value) {
        final pair = [entry.key, spouseId]..sort();
        final pairKey = '${pair[0]}::${pair[1]}';
        if (visitedPairs.contains(pairKey)) continue;
        visitedPairs.add(pairKey);

        final pos1 = positions[entry.key];
        final pos2 = positions[spouseId];
        if (pos1 == null || pos2 == null) continue;

        final leftX = math.min(pos1.dx, pos2.dx) + nodeWidth;
        final rightX = math.max(pos1.dx, pos2.dx);

        links.add(SpouseLink(
          leftX: leftX,
          rightX: rightX,
          y: pos1.dy + nodeHeight / 2,
        ));
      }
    }

    return links;
  }
}

class BracketLink {
  final String parentId;
  final List<String> childIds;
  final double parentX;
  final double parentBottomY;
  final List<double> childXPositions;
  final double childTopY;

  const BracketLink({
    required this.parentId,
    required this.childIds,
    required this.parentX,
    required this.parentBottomY,
    required this.childXPositions,
    required this.childTopY,
  });
}

class SpouseLink {
  final double leftX;
  final double rightX;
  final double y;

  const SpouseLink({
    required this.leftX,
    required this.rightX,
    required this.y,
  });
}
