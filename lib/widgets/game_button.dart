import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The single reusable button style used across every screen. Presses
/// squash slightly for tactile feedback (per the 100-300ms animation
/// guideline). Filled buttons carry the primary gradient and a soft glow.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.subtitle,
    this.filled = true,
    this.compact = false,
    this.expand = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final String? subtitle;
  final bool filled;
  final bool compact;
  final bool expand;
  final bool danger;

  /// Global hook so every button can play the same click sound without
  /// threading an AudioManager through every screen. Set once in main().
  static VoidCallback? onAnyPress;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _pressed = false;

  void _setPressed(bool pressed) => setState(() => _pressed = pressed);

  @override
  Widget build(BuildContext context) {
    final foreground = widget.filled ? AppColors.background : AppColors.textPrimary;
    final decoration = widget.filled
        ? BoxDecoration(
            gradient: widget.danger
                ? const LinearGradient(colors: [AppColors.danger, Color(0xFFD63A4C)])
                : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (widget.danger ? AppColors.danger : AppColors.primary).withAlpha(90),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          )
        : BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          );

    final textStyle = TextStyle(
      color: foreground,
      fontWeight: FontWeight.w800,
      fontSize: widget.compact ? 15 : 18,
      letterSpacing: 0.6,
    );

    Widget content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: foreground, size: widget.compact ? 20 : 24),
          const SizedBox(width: 10),
        ],
        if (widget.subtitle == null)
          Text(widget.label, style: textStyle)
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.label, style: textStyle),
              Text(
                widget.subtitle!,
                style: TextStyle(
                  color: foreground.withAlpha(180),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: () {
        GameButton.onAnyPress?.call();
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: AppTheme.shortAnim,
        curve: Curves.easeOut,
        child: Container(
          width: widget.expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 18 : 28,
            vertical: widget.compact ? 12 : 16,
          ),
          decoration: decoration,
          child: content,
        ),
      ),
    );
  }
}
