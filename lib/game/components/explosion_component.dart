import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/constants.dart';

/// One flame cell of an explosion. Lives briefly then removes itself. While
/// present it marks its cell as deadly (the game scans active explosions).
class ExplosionComponent extends SpriteComponent {
  final int col;
  final int row;
  double _life = GameConfig.explosionSeconds;

  ExplosionComponent({
    required Sprite sprite,
    required this.col,
    required this.row,
  }) : super(
          sprite: sprite,
          position: Vector2(col * GameConfig.tileSize, row * GameConfig.tileSize),
          size: Vector2.all(GameConfig.tileSize),
          priority: 50,
        ) {
    paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    // Fade out near the end of life.
    final a = (_life / GameConfig.explosionSeconds).clamp(0.0, 1.0);
    paint.color = paint.color.withValues(alpha: 0.4 + 0.6 * a);
    if (_life <= 0) removeFromParent();
  }
}
