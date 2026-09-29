import 'dart:ui';
import 'package:flame/components.dart';

import '../../models/level_object.dart';
import '../../theme/app_theme.dart';
import '../maze_drop_game.dart';
import '../render_utils.dart';

/// A spike trap. Permanently dangerous unless [TrapObject.isTimed], in
/// which case it blinks between active (dangerous) and inactive (safe).
class TrapComponent extends PositionComponent
    with HasGameReference<MazeDropGame> {
  TrapComponent({
    required this.data,
    required super.position,
    required super.size,
  });

  final TrapObject data;

  bool get isActive => data.isDangerousAt(game.elapsedMs);

  @override
  void render(Canvas canvas) {
    final base = isActive ? AppColors.danger : AppColors.locked;
    drawRoundedTile(canvas, size, base, radiusFactor: 0.3, inset: 4);

    final spikeAlpha = isActive ? 220 : 70;
    final spikePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withAlpha(spikeAlpha);
    final w = size.x;
    final path = Path()
      ..moveTo(w * 0.22, size.y * 0.72)
      ..lineTo(w * 0.36, size.y * 0.32)
      ..lineTo(w * 0.5, size.y * 0.72)
      ..lineTo(w * 0.64, size.y * 0.32)
      ..lineTo(w * 0.78, size.y * 0.72)
      ..close();
    canvas.drawPath(path, spikePaint);
  }
}
