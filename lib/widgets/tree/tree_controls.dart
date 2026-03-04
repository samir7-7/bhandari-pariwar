import 'package:flutter/material.dart';

/// Floating vintage-styled controls for the family tree canvas.
/// Provides zoom in/out, fit-to-screen, and center-on-root actions.
class TreeControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitToScreen;
  final VoidCallback onCenterRoot;
  final int currentGenDepth;
  final int maxGenDepth;
  final ValueChanged<int> onGenDepthChanged;

  const TreeControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitToScreen,
    required this.onCenterRoot,
    required this.currentGenDepth,
    required this.maxGenDepth,
    required this.onGenDepthChanged,
  });

  static const _panelBg = Color(0xFFF5E6C8);
  static const _panelBorder = Color(0xFFB8860B);
  static const _iconColor = Color(0xFF4A3728);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom controls panel
        _buildPanel(
          children: [
            _ControlButton(
              icon: Icons.add,
              onTap: onZoomIn,
              tooltip: 'Zoom in',
            ),
            _divider(),
            _ControlButton(
              icon: Icons.remove,
              onTap: onZoomOut,
              tooltip: 'Zoom out',
            ),
            _divider(),
            _ControlButton(
              icon: Icons.fit_screen_outlined,
              onTap: onFitToScreen,
              tooltip: 'Fit to screen',
            ),
            _divider(),
            _ControlButton(
              icon: Icons.gps_fixed,
              onTap: onCenterRoot,
              tooltip: 'Center on root',
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Generation depth control
        _buildPanel(
          children: [
            _ControlButton(
              icon: Icons.unfold_less,
              onTap: currentGenDepth > 1
                  ? () => onGenDepthChanged(currentGenDepth - 1)
                  : null,
              tooltip: 'Show fewer generations',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '$currentGenDepth',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _iconColor,
                ),
              ),
            ),
            _ControlButton(
              icon: Icons.unfold_more,
              onTap: currentGenDepth < maxGenDepth
                  ? () => onGenDepthChanged(currentGenDepth + 1)
                  : null,
              tooltip: 'Show more generations',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: _panelBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _panelBorder.withValues(alpha: 0.4), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D4037).withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 24,
      height: 0.5,
      color: _panelBorder.withValues(alpha: 0.25),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? TreeControls._iconColor
                : TreeControls._iconColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
