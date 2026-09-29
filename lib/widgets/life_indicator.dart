import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shows the player's remaining lives as hearts, e.g. "❤️ ❤️ 🖤".
class LifeIndicator extends StatelessWidget {
  const LifeIndicator({super.key, required this.lives, this.maxLives = 3});

  final int lives;
  final int maxLives;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLives, (i) {
        final filled = i < lives;
        return AnimatedSwitcher(
          duration: AppTheme.shortAnim,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: Padding(
            key: ValueKey('$i-$filled'),
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              filled ? Icons.favorite : Icons.favorite_border,
              color: filled ? AppColors.danger : AppColors.textSecondary,
              size: 24,
            ),
          ),
        );
      }),
    );
  }
}
