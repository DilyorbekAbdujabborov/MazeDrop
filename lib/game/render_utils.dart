import 'dart:ui';

import 'package:flame/extensions.dart';

/// Draws a rounded rectangle filling most of a grid tile, used by every
/// static tile component (walls, doors, traps...) to keep a consistent,
/// soft-shadow "casual mobile game" look without needing image assets.
void drawRoundedTile(
  Canvas canvas,
  Vector2 size,
  Color color, {
  double radiusFactor = 0.18,
  double inset = 2,
}) {
  final rect = Rect.fromLTWH(
    inset,
    inset,
    size.x - inset * 2,
    size.y - inset * 2,
  );
  final radius = Radius.circular(size.x * radiusFactor);
  final rrect = RRect.fromRectAndRadius(rect, radius);

  final shadowPaint = Paint()..color = const Color(0x33000000);
  canvas.drawRRect(rrect.shift(const Offset(0, 2)), shadowPaint);

  final paint = Paint()..color = color;
  canvas.drawRRect(rrect, paint);
}
