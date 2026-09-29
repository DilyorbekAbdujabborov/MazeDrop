import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single tile in the level-select grid: locked, unlocked, or completed
/// with 1-3 stars.
class LevelCard extends StatelessWidget {
  const LevelCard({
    super.key,
    required this.levelId,
    required this.unlocked,
    required this.stars,
    required this.onTap,
  });

  final int levelId;
  final bool unlocked;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = stars > 0;
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: AnimatedContainer(
        duration: AppTheme.shortAnim,
        decoration: BoxDecoration(
          color: unlocked ? AppColors.surface : AppColors.locked,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: completed ? AppColors.gold : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!unlocked)
                const Icon(Icons.lock, color: AppColors.textSecondary, size: 22)
              else
                Text(
                  '$levelId',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              if (unlocked && completed) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => Icon(
                      Icons.star,
                      size: 10,
                      color: i < stars ? AppColors.gold : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
