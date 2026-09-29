import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;

import '../../theme/app_theme.dart';

/// The water droplet the player controls. Drawn as a simple teardrop shape
/// (cute but not overly cartoonish) so no external art asset is required.
class PlayerComponent extends PositionComponent {
  PlayerComponent({required super.position, required super.size});

  /// Animates a grid-to-grid move. [onComplete] fires once the tween ends.
  void animateMoveTo(Vector2 targetPosition, {VoidCallback? onComplete}) {
    add(
      MoveToEffect(
        targetPosition,
        EffectController(duration: 0.13, curve: Curves.easeOut),
        onComplete: onComplete,
      ),
    );
  }

  /// Quick squash-and-fade played when the player hits a trap/obstacle.
  void playDeathAnimation({VoidCallback? onComplete}) {
    add(
      SequenceEffect(
        [
          ScaleEffect.to(
            Vector2.all(1.3),
            EffectController(duration: 0.1, curve: Curves.easeOut),
          ),
          ScaleEffect.to(
            Vector2.all(0.0),
            EffectController(duration: 0.15, curve: Curves.easeIn),
          ),
        ],
        onComplete: onComplete,
      ),
    );
  }

  void playSpawnAnimation() {
    scale = Vector2.zero();
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.2, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..quadraticBezierTo(w * 0.9, h * 0.55, w * 0.82, h * 0.72)
      ..arcToPoint(
        Offset(w * 0.18, h * 0.72),
        radius: Radius.circular(w * 0.4),
        clockwise: true,
      )
      ..quadraticBezierTo(w * 0.1, h * 0.55, w * 0.5, h * 0.08)
      ..close();

    final shadow = Paint()..color = const Color(0x33000000);
    canvas.save();
    canvas.translate(0, h * 0.05);
    canvas.drawPath(path, shadow);
    canvas.restore();

    final fill = Paint()..color = AppColors.primary;
    canvas.drawPath(path, fill);

    final highlight = Paint()..color = AppColors.textPrimary.withAlpha(90);
    canvas.drawCircle(Offset(w * 0.38, h * 0.45), w * 0.1, highlight);
  }
}
