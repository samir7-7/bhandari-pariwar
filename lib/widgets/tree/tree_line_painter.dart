import 'package:flutter/material.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_layout.dart';

class TreeLinePainter extends CustomPainter {
  final List<BracketLink> bracketLinks;
  final List<SpouseLink> spouseLinks;

  TreeLinePainter({
    required this.bracketLinks,
    required this.spouseLinks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF7A8B99)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final spousePaint = Paint()
      ..color = const Color(0xFFD4836B)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (final link in bracketLinks) {
      final midY = (link.parentBottomY + link.childTopY) / 2;

      canvas.drawLine(
        Offset(link.parentX, link.parentBottomY),
        Offset(link.parentX, midY),
        linePaint,
      );

      if (link.childXPositions.length == 1) {
        canvas.drawLine(
          Offset(link.parentX, midY),
          Offset(link.childXPositions.first, link.childTopY),
          linePaint,
        );
      } else {
        final leftX = link.childXPositions.first;
        final rightX = link.childXPositions.last;

        canvas.drawLine(
          Offset(leftX, midY),
          Offset(rightX, midY),
          linePaint,
        );

        for (final childX in link.childXPositions) {
          canvas.drawLine(
            Offset(childX, midY),
            Offset(childX, link.childTopY),
            linePaint,
          );
        }
      }
    }

    for (final link in spouseLinks) {
      canvas.drawLine(
        Offset(link.leftX, link.y),
        Offset(link.rightX, link.y),
        spousePaint,
      );
    }
  }

  @override
  bool shouldRepaint(TreeLinePainter oldDelegate) {
    return true;
  }
}
