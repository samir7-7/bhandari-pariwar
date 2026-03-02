import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/models/member.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';
import 'package:bhandari_pariwar/providers/auth_provider.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_layout.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_line_painter.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_node_widget.dart';
import 'package:bhandari_pariwar/screens/member_detail/member_detail_sheet.dart';
import 'package:bhandari_pariwar/screens/family_tree/family_tree_screen.dart';

class TreeCanvas extends ConsumerStatefulWidget {
  final String? focusMemberId;

  const TreeCanvas({super.key, this.focusMemberId});

  @override
  ConsumerState<TreeCanvas> createState() => _TreeCanvasState();
}

class _TreeCanvasState extends ConsumerState<TreeCanvas> {
  final _transformController = TransformationController();
  bool _initialZoomApplied = false;
  String? _lastFocusedId;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _applyInitialZoom(Size canvasSize, Size viewportSize) {
    if (_initialZoomApplied) return;
    _initialZoomApplied = true;

    final scaleX = viewportSize.width / canvasSize.width;
    final scaleY = viewportSize.height / canvasSize.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.1, 1.0);

    final dx = (viewportSize.width - canvasSize.width * scale) / 2;
    final dy = (viewportSize.height - canvasSize.height * scale) / 2;

    _transformController.value = Matrix4.diagonal3Values(scale, scale, 1.0)
      ..setTranslationRaw(dx > 0 ? dx : 0.0, dy > 0 ? dy : 0.0, 0.0);
  }

  void _focusOnMember(String memberId, Map<String, Offset> positions,
      Size viewportSize) {
    final pos = positions[memberId];
    if (pos == null) return;

    // Zoom to a readable level and center on the member.
    const focusScale = 1.5;
    final memberCenterX = pos.dx + TreeLayoutEngine.nodeWidth / 2;
    final memberCenterY = pos.dy + TreeLayoutEngine.nodeHeight / 2;

    final dx = viewportSize.width / 2 - memberCenterX * focusScale;
    final dy = viewportSize.height / 2 - memberCenterY * focusScale;

    _transformController.value =
        Matrix4.diagonal3Values(focusScale, focusScale, 1.0)
          ..setTranslationRaw(dx, dy, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(allMembersProvider);

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (members) {
        if (members.isEmpty) {
          return const Center(child: Text('No family members yet'));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(expandedNodesProvider.notifier)
              .initializeDefaults(members, 2);
        });

        return _buildTree(context, members);
      },
    );
  }

  Widget _buildTree(BuildContext context, List<Member> members) {
    final positions = ref.watch(treeLayoutProvider);
    final canvasSize = ref.watch(treeCanvasSizeProvider);
    final childrenMap = ref.watch(childrenMapProvider);
    final expanded = ref.watch(expandedNodesProvider);
    final langCode = ref.watch(currentLanguageProvider);
    final highlightedId = ref.watch(highlightedMemberProvider);
    final isAdmin = ref.watch(isAdminProvider);

    final spouseMap = <String, String>{};
    for (final m in members) {
      if (m.spouseId != null) {
        spouseMap[m.id] = m.spouseId!;
      }
    }

    final bracketLinks = TreeLayoutEngine.buildBracketLinks(
      positions,
      childrenMap,
      spouseMap,
      expanded,
    );
    final spouseLinks =
        TreeLayoutEngine.buildSpouseLinks(positions, spouseMap);

    if (canvasSize == Size.zero) {
      return const Center(child: CircularProgressIndicator());
    }

    // Auto-zoom to fit tree on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewportSize = MediaQuery.of(context).size;
      _applyInitialZoom(canvasSize, viewportSize);
    });

    // Focus on highlighted member when changed.
    final focusId = widget.focusMemberId ?? highlightedId;
    if (focusId != null && focusId != _lastFocusedId) {
      _lastFocusedId = focusId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final viewportSize = MediaQuery.of(context).size;
        _focusOnMember(focusId, positions, viewportSize);
      });
    }

    return InteractiveViewer(
      transformationController: _transformController,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.05,
      maxScale: 5.0,
      child: SizedBox(
        width: canvasSize.width,
        height: canvasSize.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Connection lines layer.
            Positioned.fill(
              child: CustomPaint(
                painter: TreeLinePainter(
                  bracketLinks: bracketLinks,
                  spouseLinks: spouseLinks,
                ),
              ),
            ),
            // Node widgets with individual gesture handling.
            ...positions.entries.map((entry) {
              final memberId = entry.key;
              final offset = entry.value;
              final member = members.cast<Member?>().firstWhere(
                    (m) => m?.id == memberId,
                    orElse: () => null,
                  );
              if (member == null) return const SizedBox.shrink();

              final isHighlighted = memberId == highlightedId;
              final hasChildren =
                  (childrenMap[member.id] ?? []).isNotEmpty;
              final isExpanded = expanded.contains(member.id);

              return Positioned(
                left: offset.dx,
                top: offset.dy,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _showMemberDetail(context, member, isAdmin);
                  },
                  onLongPress: () {
                    if (hasChildren) {
                      ref
                          .read(expandedNodesProvider.notifier)
                          .toggle(member.id);
                    }
                  },
                  child: TreeNodeWidget(
                    member: member,
                    languageCode: langCode,
                    isHighlighted: isHighlighted,
                    hasChildren: hasChildren,
                    isExpanded: isExpanded,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showMemberDetail(
      BuildContext context, Member member, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MemberDetailSheet(
        memberId: member.id,
        showAdminActions: isAdmin,
      ),
    );
  }
}
