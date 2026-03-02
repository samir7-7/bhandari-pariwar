import 'package:flutter/material.dart';
import 'package:bhandari_pariwar/models/member.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_layout.dart';

class TreeNodeWidget extends StatelessWidget {
  final Member member;
  final String languageCode;

  const TreeNodeWidget({
    super.key,
    required this.member,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final name = member.localizedName(languageCode);
    final isMale = member.isMale;

    final bgColor = isMale
        ? const Color(0xFFE8F0FE)
        : const Color(0xFFFCE4EC);
    final borderColor = isMale
        ? const Color(0xFF5B8DB8)
        : const Color(0xFFC48B9F);
    final textColor = member.isAlive
        ? const Color(0xFF333333)
        : const Color(0xFF999999);

    return SizedBox(
      width: TreeLayoutEngine.nodeWidth,
      height: TreeLayoutEngine.nodeHeight,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
