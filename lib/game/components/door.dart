import 'dart:ui';
import 'package:flame/components.dart';

import '../../models/level_object.dart';
import '../../theme/app_theme.dart';
import '../render_utils.dart';

/// A locked door. Blocks movement until the matching key is collected,
/// then stays open for the rest of the level attempt.
class DoorComponent extends PositionComponent {
  DoorComponent({
    required this.data,
    required super.position,
    required super.size,
  });

  final DoorObject data;
  bool isOpen = false;

  @override
  void render(Canvas canvas) {
    if (isOpen) {
      drawRoundedTile(
        canvas,
        size,
        AppColors.wall,
        radiusFactor: 0.1,
        inset: size.x * 0.32,
      );
      return;
    }
    drawRoundedTile(canvas, size, AppColors.locked, radiusFactor: 0.1, inset: 1);
    final knob = Paint()..color = AppColors.gold;
    canvas.drawCircle(
      Offset(size.x * 0.72, size.y * 0.5),
      size.x * 0.08,
      knob,
    );
  }
}
