import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bhandari_pariwar/models/member.dart';
import 'package:bhandari_pariwar/providers/family_tree_provider.dart';
import 'package:bhandari_pariwar/providers/settings_provider.dart';
import 'package:bhandari_pariwar/providers/auth_provider.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_layout.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_line_painter.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_node_widget.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_controls.dart';
import 'package:bhandari_pariwar/screens/member_detail/member_detail_sheet.dart';
import 'package:bhandari_pariwar/screens/family_tree/family_tree_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TreeCanvas extends ConsumerStatefulWidget {
  final String? focusMemberId;

  /// Global key for the repaint boundary wrapping the tree content.
  static final repaintBoundaryKey = GlobalKey();

  const TreeCanvas({super.key, this.focusMemberId});

  /// Captures the tree canvas as an image and generates a shareable PDF.
  static Future<void> saveAsPdf(BuildContext context) async {
    final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;

    // Show a loading indicator
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Generating PDF...'),
          ],
        ),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final pdfDoc = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);

      // Use landscape A3 or larger to fit the tree
      final pageFormat = PdfPageFormat(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      pdfDoc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context ctx) {
            return pw.Center(
              child: pw.Image(pdfImage,
                  fit: pw.BoxFit.contain,
                  width: pageFormat.width,
                  height: pageFormat.height),
            );
          },
        ),
      );

      messenger.hideCurrentSnackBar();

      final pdfBytes = await pdfDoc.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'bhandari_family_tree.pdf',
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
  }

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

  /// Centers on the root member at a comfortable zoom level
  /// so the head of the tree is in the middle of the screen.
  void _centerOnRoot(Map<String, Offset> positions, Size viewportSize) {
    final roots = ref.read(rootMembersProvider);
    if (roots.isEmpty) return;
    final rootPos = positions[roots.first.id];
    if (rootPos == null) return;

    final spouseMap = <String, String>{};
    final members = ref.read(allMembersProvider).valueOrNull ?? [];
    for (final m in members) {
      if (m.spouseId != null) spouseMap[m.id] = m.spouseId!;
    }
    final hasSpouse = spouseMap.containsKey(roots.first.id);

    final rootCenterX = hasSpouse
        ? rootPos.dx + TreeLayoutEngine.nodeWidth + TreeLayoutEngine.coupleGap / 2
        : rootPos.dx + TreeLayoutEngine.nodeWidth / 2;
    final rootCenterY = rootPos.dy + TreeLayoutEngine.nodeHeight / 2;

    const scale = 1.8;
    final dx = viewportSize.width / 2 - rootCenterX * scale;
    final dy = viewportSize.height / 2 - rootCenterY * scale;

    _transformController.value =
        Matrix4.diagonal3Values(scale, scale, 1.0)
          ..setTranslationRaw(dx, dy, 0.0);
  }

  void _applyInitialZoom(
      Size canvasSize, Size viewportSize, Map<String, Offset> positions) {
    if (_initialZoomApplied) return;
    _initialZoomApplied = true;

    // Center on the root member in the middle of the screen
    _centerOnRoot(positions, viewportSize);
  }

  void _focusOnMember(
      String memberId, Map<String, Offset> positions, Size viewportSize) {
    final pos = positions[memberId];
    if (pos == null) return;

    const focusScale = 2.0;
    final memberCenterX = pos.dx + TreeLayoutEngine.nodeWidth / 2;
    final memberCenterY = pos.dy + TreeLayoutEngine.nodeHeight / 2;

    final dx = viewportSize.width / 2 - memberCenterX * focusScale;
    final dy = viewportSize.height / 2 - memberCenterY * focusScale;

    _transformController.value =
        Matrix4.diagonal3Values(focusScale, focusScale, 1.0)
          ..setTranslationRaw(dx, dy, 0.0);
  }

  void _fitToScreen(Size canvasSize, Size viewportSize) {
    final scaleX = viewportSize.width / canvasSize.width;
    final scaleY = viewportSize.height / canvasSize.height;
    final scale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.05, 1.0);

    final dx = (viewportSize.width - canvasSize.width * scale) / 2;
    const dy = 20.0; // Small top padding

    _transformController.value = Matrix4.diagonal3Values(scale, scale, 1.0)
      ..setTranslationRaw(dx > 0 ? dx : 0.0, dy, 0.0);
  }

  void _zoomIn() {
    final current = _transformController.value.clone();
    final scale = current.getMaxScaleOnAxis();
    final newScale = (scale * 1.3).clamp(0.05, 5.0);
    final ratio = newScale / scale;

    final viewportSize = MediaQuery.of(context).size;
    final focalX = viewportSize.width / 2;
    final focalY = viewportSize.height / 2;

    final translation = current.getTranslation();
    final newDx = focalX - (focalX - translation.x) * ratio;
    final newDy = focalY - (focalY - translation.y) * ratio;

    _transformController.value =
        Matrix4.diagonal3Values(newScale, newScale, 1.0)
          ..setTranslationRaw(newDx, newDy, 0.0);
  }

  void _zoomOut() {
    final current = _transformController.value.clone();
    final scale = current.getMaxScaleOnAxis();
    final newScale = (scale / 1.3).clamp(0.05, 5.0);
    final ratio = newScale / scale;

    final viewportSize = MediaQuery.of(context).size;
    final focalX = viewportSize.width / 2;
    final focalY = viewportSize.height / 2;

    final translation = current.getTranslation();
    final newDx = focalX - (focalX - translation.x) * ratio;
    final newDy = focalY - (focalY - translation.y) * ratio;

    _transformController.value =
        Matrix4.diagonal3Values(newScale, newScale, 1.0)
          ..setTranslationRaw(newDx, newDy, 0.0);
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
    final maxGenDepth = ref.watch(maxGenerationDepthProvider);
    final genDepth = ref.watch(generationDepthSettingProvider);

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

    // Auto-zoom: center on root head on initial load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewportSize = MediaQuery.of(context).size;
      _applyInitialZoom(canvasSize, viewportSize, positions);
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

    // Ancient parchment background color
    const parchmentBg = Color(0xFFF9F0E1);

    return Stack(
      children: [
        // Parchment background
        Container(color: parchmentBg),

        // Interactive tree
        InteractiveViewer(
          transformationController: _transformController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(300),
          minScale: 0.05,
          maxScale: 5.0,
          child: RepaintBoundary(
            key: TreeCanvas.repaintBoundaryKey,
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
                          // Center view on the expanded/collapsed node
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final vp = MediaQuery.of(context).size;
                            final updatedPositions =
                                ref.read(treeLayoutProvider);
                            _focusOnMember(
                                member.id, updatedPositions, vp);
                          });
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
          ),
        ),

        // Floating zoom & generation controls — bottom right
        Positioned(
          right: 12,
          bottom: 16,
          child: TreeControls(
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
            onFitToScreen: () {
              final viewportSize = MediaQuery.of(context).size;
              _fitToScreen(canvasSize, viewportSize);
            },
            onCenterRoot: () {
              final viewportSize = MediaQuery.of(context).size;
              _centerOnRoot(positions, viewportSize);
            },
            currentGenDepth: genDepth,
            maxGenDepth: maxGenDepth > 0 ? maxGenDepth : 10,
            onGenDepthChanged: (depth) {
              ref.read(generationDepthSettingProvider.notifier).state = depth;
              ref
                  .read(expandedNodesProvider.notifier)
                  .expandToDepth(members, depth);
              // Reset zoom after depth change
              _initialZoomApplied = false;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final vp = MediaQuery.of(context).size;
                final newCanvasSize = ref.read(treeCanvasSizeProvider);
                if (newCanvasSize != Size.zero) {
                  _fitToScreen(newCanvasSize, vp);
                }
              });
            },
          ),
        ),


      ],
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
