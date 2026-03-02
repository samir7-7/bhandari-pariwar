import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/models/member.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_layout.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_line_painter.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_node_widget.dart';
import 'package:bhandari_pariwar/screens/member_detail/member_detail_sheet.dart';

class TreeCanvas extends ConsumerStatefulWidget {
  final String? focusMemberId;

  const TreeCanvas({super.key, this.focusMemberId});

  @override
  ConsumerState<TreeCanvas> createState() => _TreeCanvasState();
}

class _TreeCanvasState extends ConsumerState<TreeCanvas> {
  final _transformController = TransformationController();
  bool _initialZoomApplied = false;

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
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.05, 1.0);

    final dx = (viewportSize.width - canvasSize.width * scale) / 2;

    _transformController.value = Matrix4.diagonal3Values(scale, scale, 1.0)
      ..setTranslationRaw(dx > 0 ? dx : 0.0, 0.0, 0.0);
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

        // Initialize default expanded nodes on first load.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(expandedNodesProvider.notifier)
              .initializeDefaults(members, 3);
        });

        return _buildTree(context, members);
      },
    );
  }

  /// Find which member is at a given canvas-space position.
  Member? _findMemberAtPosition(
    Offset canvasPosition,
    Map<String, Offset> positions,
    List<Member> members,
  ) {
    for (final entry in positions.entries) {
      final rect = Rect.fromLTWH(
        entry.value.dx,
        entry.value.dy,
        TreeLayoutEngine.nodeWidth,
        TreeLayoutEngine.nodeHeight,
      );
      if (rect.contains(canvasPosition)) {
        try {
          return members.firstWhere((m) => m.id == entry.key);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  Widget _buildTree(BuildContext context, List<Member> members) {
    final positions = ref.watch(treeLayoutProvider);
    final canvasSize = ref.watch(treeCanvasSizeProvider);
    final childrenMap = ref.watch(childrenMapProvider);
    final expanded = ref.watch(expandedNodesProvider);
    final langCode = ref.watch(currentLanguageProvider);

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

    return InteractiveViewer(
      transformationController: _transformController,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.03,
      maxScale: 4.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final member = _findMemberAtPosition(
            details.localPosition,
            positions,
            members,
          );
          if (member != null) {
            _showMemberDetail(context, member);
          }
        },
        onLongPressStart: (details) {
          final member = _findMemberAtPosition(
            details.localPosition,
            positions,
            members,
          );
          if (member == null) return;
          final children = childrenMap[member.id] ?? [];
          if (children.isNotEmpty) {
            ref.read(expandedNodesProvider.notifier).toggle(member.id);
          }
        },
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
              // Node widgets (purely visual, no gesture handling).
              ...positions.entries.map((entry) {
                final memberId = entry.key;
                final offset = entry.value;
                final member = members.cast<Member?>().firstWhere(
                      (m) => m?.id == memberId,
                      orElse: () => null,
                    );
                if (member == null) return const SizedBox.shrink();

                return Positioned(
                  left: offset.dx,
                  top: offset.dy,
                  child: TreeNodeWidget(
                    member: member,
                    languageCode: langCode,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberDetail(BuildContext context, Member member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MemberDetailSheet(memberId: member.id),
    );
  }
}
