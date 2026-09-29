import 'dart:ui';
import 'package:flame/components.dart';

import '../../models/level_object.dart';
import '../../theme/app_theme.dart';

/// A pickup that unlocks the [DoorObject] sharing the same id. Named
/// KeyComponent (not `Key`) to avoid clashing with Flutter's widget Key.
class KeyComponent extends PositionComponent {
  KeyComponent({
    required this.data,
    required super.position,
    required super.size,
  });

  final KeyObject data;
  bool collected = false;

  @override
  void render(Canvas canvas) {
    if (collected) return;
    final paint = Paint()..color = AppColors.gold;
    final center = Offset(size.x / 2, size.y * 0.42);
    canvas.drawCircle(center, size.x * 0.2, paint);

    final ring = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.06;
    canvas.drawCircle(center, size.x * 0.1, ring);

    final shaft = Rect.fromLTWH(
      size.x * 0.47,
      size.y * 0.42,
      size.x * 0.06,
      size.y * 0.34,
    );
    canvas.drawRect(shaft, paint);

    final tooth = Rect.fromLTWH(
      size.x * 0.53,
      size.y * 0.66,
      size.x * 0.14,
      size.y * 0.06,
    );
    canvas.drawRect(tooth, paint);
  }
}
