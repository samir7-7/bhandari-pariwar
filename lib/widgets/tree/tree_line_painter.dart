import 'package:flutter/material.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_layout.dart';

/// Vintage / ancient styled tree connection line painter.
/// Uses warm bronze/gold tones and slightly thicker strokes
/// to evoke a hand-drawn genealogical scroll.
class TreeLinePainter extends CustomPainter {
  final List<BracketLink> bracketLinks;
  final List<SpouseLink> spouseLinks;

  TreeLinePainter({
    required this.bracketLinks,
    required this.spouseLinks,
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

    for (final link in bracketLinks) {
      final midY = (link.parentBottomY + link.childTopY) / 2;

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
        canvas.drawLine(
          Offset(link.parentX, midY),
          Offset(link.childXPositions.first, link.childTopY),
          lineShadowPaint,
        );
        canvas.drawLine(
          Offset(link.parentX, midY),
          Offset(link.childXPositions.first, link.childTopY),
          linePaint,
        );
      } else {
        final leftX = link.childXPositions.first;
        final rightX = link.childXPositions.last;

        // Horizontal bracket
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

        // Verticals from bracket to each child
        for (final childX in link.childXPositions) {
          canvas.drawLine(
            Offset(childX, midY),
            Offset(childX, link.childTopY),
            lineShadowPaint,
          );
          canvas.drawLine(
            Offset(childX, midY),
            Offset(childX, link.childTopY),
            linePaint,
          );
          // Small dot at junction
          canvas.drawCircle(Offset(childX, midY), 1.2, dotPaint);
        }
      }

      // Small dot at parent junction point
      canvas.drawCircle(
          Offset(link.parentX, link.parentBottomY + 0.5), 1.2, dotPaint);
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
    return true;
  }
}
