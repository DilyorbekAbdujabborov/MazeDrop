import 'dart:ui';
import 'package:flame/components.dart';

import '../../theme/app_theme.dart';

/// An optional collectible. Never blocks the path to the exit.
class CoinComponent extends PositionComponent {
  CoinComponent({required super.position, required super.size});

  bool collected = false;

  @override
  void render(Canvas canvas) {
    if (collected) return;
    final center = Offset(size.x / 2, size.y / 2);
    final fill = Paint()..color = AppColors.gold;
    canvas.drawCircle(center, size.x * 0.22, fill);
    final ring = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.03;
    canvas.drawCircle(center, size.x * 0.22, ring);
  }
}
