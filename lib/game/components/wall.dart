import 'dart:ui';
import 'package:flame/components.dart';

import '../../models/level_object.dart';
import '../../theme/app_theme.dart';
import '../maze_drop_game.dart';
import '../render_utils.dart';

class WallComponent extends PositionComponent {
  WallComponent({required super.position, required super.size});

  @override
  void render(Canvas canvas) {
    drawRoundedTile(canvas, size, AppColors.wall, radiusFactor: 0.1, inset: 1);
  }
}

/// A wall segment that periodically slides open, per [MovingWall.isOpenAt].
class MovingWallComponent extends PositionComponent
    with HasGameReference<MazeDropGame> {
  MovingWallComponent({
    required this.data,
    required super.position,
    required super.size,
  });

  final MovingWall data;

  bool get isOpen => data.isOpenAt(game.elapsedMs);

  @override
  void render(Canvas canvas) {
    if (isOpen) {
      drawRoundedTile(
        canvas,
        size,
        AppColors.wall,
        radiusFactor: 0.1,
        inset: size.x * 0.3,
      );
    } else {
      drawRoundedTile(canvas, size, AppColors.wall, radiusFactor: 0.1, inset: 1);
    }
  }
}
