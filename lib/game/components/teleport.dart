import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../../models/level_object.dart';
import '../../theme/app_theme.dart';

/// One end of a teleport pair. Stepping onto either pad instantly moves the
/// player to the other pad sharing the same [TeleportObject.pairId].
class TeleportComponent extends PositionComponent {
  TeleportComponent({
    required this.data,
    required super.position,
    required super.size,
  }) {
    add(
      RotateEffect.by(
        6.28318,
        EffectController(duration: 3, infinite: true),
      ),
    );
  }

  final TeleportObject data;

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final outer = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.05;
    canvas.drawCircle(center, size.x * 0.38, outer);
    final inner = Paint()..color = AppColors.primaryDark;
    canvas.drawCircle(center, size.x * 0.22, inner);
  }
}
