import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;

import '../../theme/app_theme.dart';

/// The maze exit portal the droplet must reach. Pulses gently to draw the
/// eye without being distracting.
class ExitComponent extends PositionComponent {
  ExitComponent({required super.position, required super.size}) {
    add(
      ScaleEffect.by(
        Vector2.all(1.1),
        EffectController(
          duration: 0.7,
          reverseDuration: 0.7,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x * 0.4;

    final ring = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.06;
    canvas.drawCircle(center, radius, ring);

    final fill = Paint()..color = AppColors.primaryDark;
    canvas.drawCircle(center, radius * 0.7, fill);
  }
}
