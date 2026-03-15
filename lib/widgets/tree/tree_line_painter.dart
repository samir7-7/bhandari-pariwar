import 'package:flutter/material.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_layout.dart';

/// Vintage / ancient styled tree connection line painter.
/// Uses warm bronze/gold tones and slightly thicker strokes
/// to evoke a hand-drawn genealogical scroll.
class TreeLinePainter extends CustomPainter {
  final List<BracketLink> bracketLinks;
  final List<SpouseLink> spouseLinks;
  final Set<String> highlightedIds;

  TreeLinePainter({
    required this.bracketLinks,
    required this.spouseLinks,
    this.highlightedIds = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Bronze-gold connection lines
    final linePaint = Paint()
      ..color = const Color(0xFF8B7355) // warm brown
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Shadow/depth line drawn behind
    final lineShadowPaint = Paint()
      ..color = const Color(0xFF5D4037).withValues(alpha: 0.12)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Spouse connection — deep red/maroon ribbon
    final spousePaint = Paint()
      ..color = const Color(0xFFA0522D) // sienna
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Small dot paint for junction decorations
    final dotPaint = Paint()
      ..color = const Color(0xFFB8860B).withValues(alpha: 0.45) // gold
      ..style = PaintingStyle.fill;

    // Highlighted path lines — gold, thicker
    final highlightLinePaint = Paint()
      ..color = const Color(0xFFC9A84C) // gold accent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final highlightShadowPaint = Paint()
      ..color = const Color(0xFFC9A84C).withValues(alpha: 0.3)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final highlightDotPaint = Paint()
      ..color = const Color(0xFFC9A84C) // gold
      ..style = PaintingStyle.fill;

    for (final link in bracketLinks) {
      final midY = (link.parentBottomY + link.childTopY) / 2;

      // Determine if any child in this bracket is on the highlighted path
      final parentIsHighlighted = highlightedIds.contains(link.parentId);

      // Draw shadow first, then line on top
      // Vertical from parent to midpoint
      canvas.drawLine(
        Offset(link.parentX, link.parentBottomY),
        Offset(link.parentX, midY),
        lineShadowPaint,
      );
      canvas.drawLine(
        Offset(link.parentX, link.parentBottomY),
        Offset(link.parentX, midY),
        linePaint,
      );

      if (link.childXPositions.length == 1) {
        final childHighlighted = parentIsHighlighted &&
            link.childIds.isNotEmpty &&
            highlightedIds.contains(link.childIds.first);

        canvas.drawLine(
          Offset(link.parentX, midY),
          Offset(link.childXPositions.first, link.childTopY),
          childHighlighted ? highlightShadowPaint : lineShadowPaint,
        );
        canvas.drawLine(
          Offset(link.parentX, midY),
          Offset(link.childXPositions.first, link.childTopY),
          childHighlighted ? highlightLinePaint : linePaint,
        );

        // Re-draw parent vertical with highlight if needed
        if (childHighlighted) {
          canvas.drawLine(
            Offset(link.parentX, link.parentBottomY),
            Offset(link.parentX, midY),
            highlightShadowPaint,
          );
          canvas.drawLine(
            Offset(link.parentX, link.parentBottomY),
            Offset(link.parentX, midY),
            highlightLinePaint,
          );
        }
      } else {
        final leftX = link.childXPositions.first;
        final rightX = link.childXPositions.last;

        // Horizontal bracket (normal)
        canvas.drawLine(
          Offset(leftX, midY),
          Offset(rightX, midY),
          lineShadowPaint,
        );
        canvas.drawLine(
          Offset(leftX, midY),
          Offset(rightX, midY),
          linePaint,
        );

        bool anyChildHighlighted = false;

        // Verticals from bracket to each child
        for (int i = 0; i < link.childXPositions.length; i++) {
          final childX = link.childXPositions[i];
          final childHighlighted = parentIsHighlighted &&
              i < link.childIds.length &&
              highlightedIds.contains(link.childIds[i]);

          if (childHighlighted) anyChildHighlighted = true;

          canvas.drawLine(
            Offset(childX, midY),
            Offset(childX, link.childTopY),
            childHighlighted ? highlightShadowPaint : lineShadowPaint,
          );
          canvas.drawLine(
            Offset(childX, midY),
            Offset(childX, link.childTopY),
            childHighlighted ? highlightLinePaint : linePaint,
          );
          // Small dot at junction
          canvas.drawCircle(
            Offset(childX, midY),
            childHighlighted ? 2.0 : 1.2,
            childHighlighted ? highlightDotPaint : dotPaint,
          );

          // Draw highlighted horizontal segment from parentX to this child
          if (childHighlighted) {
            canvas.drawLine(
              Offset(link.parentX, midY),
              Offset(childX, midY),
              highlightShadowPaint,
            );
            canvas.drawLine(
              Offset(link.parentX, midY),
              Offset(childX, midY),
              highlightLinePaint,
            );
          }
        }

        // Re-draw parent vertical with highlight if any child is highlighted
        if (anyChildHighlighted) {
          canvas.drawLine(
            Offset(link.parentX, link.parentBottomY),
            Offset(link.parentX, midY),
            highlightShadowPaint,
          );
          canvas.drawLine(
            Offset(link.parentX, link.parentBottomY),
            Offset(link.parentX, midY),
            highlightLinePaint,
          );
        }
      }

      // Small dot at parent junction point
      final parentDotHighlighted = parentIsHighlighted &&
          link.childIds.any((id) => highlightedIds.contains(id));
      canvas.drawCircle(
          Offset(link.parentX, link.parentBottomY + 0.5),
          parentDotHighlighted ? 2.0 : 1.2,
          parentDotHighlighted ? highlightDotPaint : dotPaint);
    }

    // Spouse links — a double line for marriage bond
    for (final link in spouseLinks) {
      canvas.drawLine(
        Offset(link.leftX, link.y - 0.6),
        Offset(link.rightX, link.y - 0.6),
        spousePaint,
      );
      canvas.drawLine(
        Offset(link.leftX, link.y + 0.6),
        Offset(link.rightX, link.y + 0.6),
        spousePaint,
      );
    }
  }

  @override
  bool shouldRepaint(TreeLinePainter oldDelegate) {
    if (oldDelegate.bracketLinks.length != bracketLinks.length) {
      return true;
    }
    if (oldDelegate.spouseLinks.length != spouseLinks.length) {
      return true;
    }
    if (oldDelegate.highlightedIds.length != highlightedIds.length) {
      return true;
    }
    for (final id in highlightedIds) {
      if (!oldDelegate.highlightedIds.contains(id)) {
        return true;
      }
    }

    for (int i = 0; i < bracketLinks.length; i++) {
      final oldLink = oldDelegate.bracketLinks[i];
      final link = bracketLinks[i];
      if (oldLink.parentId != link.parentId ||
          oldLink.parentX != link.parentX ||
          oldLink.parentBottomY != link.parentBottomY ||
          oldLink.childTopY != link.childTopY ||
          oldLink.childIds.length != link.childIds.length ||
          oldLink.childXPositions.length != link.childXPositions.length) {
        return true;
      }

      for (int j = 0; j < link.childIds.length; j++) {
        if (oldLink.childIds[j] != link.childIds[j]) {
          return true;
        }
      }
      for (int j = 0; j < link.childXPositions.length; j++) {
        if (oldLink.childXPositions[j] != link.childXPositions[j]) {
          return true;
        }
      }
    }

    for (int i = 0; i < spouseLinks.length; i++) {
      final oldLink = oldDelegate.spouseLinks[i];
      final link = spouseLinks[i];
      if (oldLink.leftX != link.leftX ||
          oldLink.rightX != link.rightX ||
          oldLink.y != link.y) {
        return true;
      }
    }

    return false;
  }
}
