import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A single tile in the level-select grid: locked, unlocked, current
/// (next to play, pulsing ring), or completed with 1-3 stars.
class LevelCard extends StatefulWidget {
  const LevelCard({
    super.key,
    required this.levelId,
    required this.unlocked,
    required this.stars,
    required this.onTap,
    this.isCurrent = false,
  });

  final int levelId;
  final bool unlocked;
  final int stars;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  State<LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<LevelCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isCurrent) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant LevelCard old) {
    super.didUpdateWidget(old);
    if (widget.isCurrent && !_pulse.isAnimating) _pulse.repeat(reverse: true);
    if (!widget.isCurrent && _pulse.isAnimating) _pulse.stop();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completed = widget.stars > 0;
    final perfect = widget.stars == 3;

    final Decoration decoration;
    if (!widget.unlocked) {
      decoration = BoxDecoration(
        color: AppColors.locked.withAlpha(110),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      );
    } else if (completed) {
      decoration = BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceHigh, AppColors.surface],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: perfect ? AppColors.gold : AppColors.gold.withAlpha(120),
          width: perfect ? 2 : 1.2,
        ),
        boxShadow: perfect
            ? [BoxShadow(color: AppColors.gold.withAlpha(70), blurRadius: 14)]
            : null,
      );
    } else {
      decoration = BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withAlpha(110), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      );
    }

    final numberColor = widget.unlocked && !completed ? AppColors.background : AppColors.textPrimary;

    Widget card = Container(
      decoration: decoration,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!widget.unlocked)
              Icon(Icons.lock_rounded, color: AppColors.textSecondary.withAlpha(160), size: 20)
            else
              Text(
                '${widget.levelId}',
                style: TextStyle(
                  color: numberColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            if (widget.unlocked && completed) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Icon(
                    Icons.star_rounded,
                    size: 11,
                    color: i < widget.stars ? AppColors.gold : AppColors.textSecondary.withAlpha(90),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (widget.isCurrent) {
      card = AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_pulse.value);
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withAlpha((60 + 100 * t).round()),
                  blurRadius: 12 + 10 * t,
                  spreadRadius: 1 + 2 * t,
                ),
              ],
            ),
            child: child,
          );
        },
        child: card,
      );
    }

    return GestureDetector(
      onTap: widget.unlocked ? widget.onTap : null,
      child: card,
    );
  }
}
