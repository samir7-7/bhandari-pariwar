import 'package:flutter/material.dart';
import 'package:bhandari_pariwar/models/member.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_layout.dart';

class TreeNodeWidget extends StatelessWidget {
  final Member member;
  final String languageCode;
  final bool isHighlighted;
  final bool hasChildren;
  final bool isExpanded;

  const TreeNodeWidget({
    super.key,
    required this.member,
    required this.languageCode,
    this.isHighlighted = false,
    this.hasChildren = false,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = member.localizedName(languageCode);
    final isMale = member.isMale;

    final bgColor = isHighlighted
        ? const Color(0xFFFFF9C4) // Yellow highlight
        : isMale
            ? const Color(0xFFE8F0FE)
            : const Color(0xFFFCE4EC);
    final borderColor = isHighlighted
        ? const Color(0xFFFF8F00) // Orange border when highlighted
        : isMale
            ? const Color(0xFF5B8DB8)
            : const Color(0xFFC48B9F);
    final textColor = member.isAlive
        ? const Color(0xFF333333)
        : const Color(0xFF999999);

    return SizedBox(
      width: TreeLayoutEngine.nodeWidth,
      height: TreeLayoutEngine.nodeHeight + (hasChildren ? 6 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: TreeLayoutEngine.nodeWidth,
            height: TreeLayoutEngine.nodeHeight,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                  color: borderColor,
                  width: isHighlighted ? 1.2 : 0.6),
              boxShadow: isHighlighted
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF8F00).withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 7.0,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Expand/collapse indicator for nodes with children.
          if (hasChildren)
            Container(
              width: 10,
              height: 6,
              alignment: Alignment.topCenter,
              child: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 6,
                color: const Color(0xFF7A8B99),
              ),
            ),
        ],
      ),
    );
  }
}
