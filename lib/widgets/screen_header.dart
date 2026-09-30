import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Consistent top bar for secondary screens: round glass back button,
/// title, optional trailing widget.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onTap, this.size = 42});

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassFill,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: size * 0.5),
      ),
    );
  }
}
