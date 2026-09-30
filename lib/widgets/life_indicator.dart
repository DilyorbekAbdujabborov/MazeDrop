import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shows the player's remaining lives as hearts. A lost heart pops out;
/// a regained one pops back in.
class LifeIndicator extends StatelessWidget {
  const LifeIndicator({super.key, required this.lives, this.maxLives = 3, this.size = 22});

  final int lives;
  final int maxLives;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLives, (i) {
        final filled = i < lives;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedSwitcher(
            duration: AppTheme.mediumAnim,
            switchInCurve: Curves.elasticOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              filled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey('$i-$filled'),
              color: filled ? AppColors.danger : AppColors.textSecondary.withAlpha(120),
              size: size,
              shadows: filled
                  ? const [Shadow(color: Color(0x80FF5C6C), blurRadius: 10)]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
