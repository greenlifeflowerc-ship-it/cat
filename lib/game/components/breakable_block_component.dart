import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/constants.dart';

/// A destructible block. Occupies its cell until an explosion reaches it.
class BreakableBlockComponent extends SpriteComponent {
  final int col;
  final int row;
  bool destroyed = false;

  BreakableBlockComponent({
    required Sprite sprite,
    required this.col,
    required this.row,
  }) : super(
          sprite: sprite,
          position: Vector2(col * GameConfig.tileSize, row * GameConfig.tileSize),
          size: Vector2.all(GameConfig.tileSize),
          priority: 5,
        ) {
    paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
  }
}
