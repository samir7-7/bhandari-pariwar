import 'package:flutter/material.dart';
import 'package:bhandari_pariwar/models/member.dart';
import 'package:bhandari_pariwar/widgets/tree/tree_layout.dart';

/// Ancient/vintage themed tree node widget.
/// Styled like traditional family scrolls with parchment colors,
/// ornate borders, and classical aesthetics.
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

  // Ancient color palette
  static const _parchmentMale = Color(0xFFF5E6C8);
  static const _parchmentFemale = Color(0xFFF2DDD0);
  static const _goldHighlight = Color(0xFFFFF4D4);
  static const _goldAccent = Color(0xFFC9A84C);
  static const _bronzeBorder = Color(0xFFB8860B);
  static const _siennaBorder = Color(0xFFA0522D);
  static const _darkBrown = Color(0xFF3E2723);
  static const _fadedBrown = Color(0xFF8B7355);
  static const _deepRed = Color(0xFF8B1A1A);

  @override
  Widget build(BuildContext context) {
    final name = member.localizedName(languageCode);
    final isMale = member.isMale;
    final indicatorH = hasChildren ? 9.0 : 0.0;

    final bgColor = isHighlighted
        ? _goldHighlight
        : isMale
            ? _parchmentMale
            : _parchmentFemale;
    final borderColor = isHighlighted
        ? _goldAccent
        : isMale
            ? _bronzeBorder
            : _siennaBorder;
    final textColor = member.isAlive ? _darkBrown : _fadedBrown;

    return SizedBox(
      width: TreeLayoutEngine.nodeWidth,
      height: TreeLayoutEngine.nodeHeight + indicatorH,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main node card — ancient scroll style
          Container(
            width: TreeLayoutEngine.nodeWidth,
            height: TreeLayoutEngine.nodeHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  bgColor,
                  Color.lerp(bgColor, const Color(0xFFD4B896), 0.15)!,
                  bgColor,
                ],
              ),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: borderColor,
                width: isHighlighted ? 1.4 : 0.8,
              ),
              boxShadow: [
                if (isHighlighted)
                  BoxShadow(
                    color: _goldAccent.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                else
                  BoxShadow(
                    color: const Color(0xFF5D4037).withValues(alpha: 0.18),
                    blurRadius: 2,
                    offset: const Offset(0.5, 1),
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Inner ornate border
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5),
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.25),
                        width: 0.4,
                      ),
                    ),
                  ),
                ),
                // Tiny corner dots (ornate corners)
                ..._buildCornerDots(borderColor),
                // Gender symbol on left
                Positioned(
                  left: 3,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      isMale ? '\u2642' : '\u2640',
                      style: TextStyle(
                        fontSize: 6.5,
                        color: isMale
                            ? _bronzeBorder.withValues(alpha: 0.7)
                            : _deepRed.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Hindu Om symbol on right
                Positioned(
                  right: 3,
                  top: 2,
                  child: Text(
                    '\u0950', // ॐ Om
                    style: TextStyle(
                      fontSize: 6,
                      color: _bronzeBorder.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                // Name text — centered
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 8.0,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.15,
                        letterSpacing: 0.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Expand/collapse indicator — vintage style
          if (hasChildren)
            Container(
              width: 12,
              height: indicatorH,
              alignment: Alignment.topCenter,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEDE0CA),
                  border: Border.all(
                    color: _bronzeBorder.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 7,
                  color: _darkBrown,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerDots(Color color) {
    return List.generate(4, (i) {
      final isLeft = i % 2 == 0;
      final isTop = i < 2;
      return Positioned(
        left: isLeft ? 2.5 : null,
        right: !isLeft ? 2.5 : null,
        top: isTop ? 2.5 : null,
        bottom: !isTop ? 2.5 : null,
        child: Container(
          width: 2,
          height: 2,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
        ),
      );
    });
  }
}
