import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/constants.dart';

/// Static sprite snapped to a grid cell. Used for floor and solid walls.
/// Pixel art is kept crisp with nearest-neighbour filtering.
class TileComponent extends SpriteComponent {
  TileComponent({
    required Sprite sprite,
    required int col,
    required int row,
    int priority = 0,
  }) : super(
          sprite: sprite,
          position: Vector2(col * GameConfig.tileSize, row * GameConfig.tileSize),
          size: Vector2.all(GameConfig.tileSize),
          priority: priority,
        ) {
    paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
  }
}
