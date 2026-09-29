import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The single reusable button style used across every screen. Presses
/// squash slightly for tactile feedback (per the 100-300ms animation
/// guideline).
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool filled;
  final bool compact;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    setState(() => _scale = pressed ? 0.94 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.filled ? AppColors.primary : AppColors.surface;
    final foreground =
        widget.filled ? AppColors.background : AppColors.textPrimary;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: AppTheme.shortAnim,
        curve: Curves.easeOut,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 20 : 32,
            vertical: widget.compact ? 12 : 18,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: foreground, size: 22),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: widget.compact ? 15 : 18,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
