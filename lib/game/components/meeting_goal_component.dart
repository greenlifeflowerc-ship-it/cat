import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/constants.dart';

/// The cooperative meeting-goal tile. Purely a visual marker that gently
/// pulses; the win check lives in the game's win-condition logic.
class MeetingGoalComponent extends SpriteComponent {
  final int col;
  final int row;
  double _t = 0;

  MeetingGoalComponent({
    required Sprite sprite,
    required this.col,
    required this.row,
  }) : super(
          sprite: sprite,
          position: Vector2(col * GameConfig.tileSize, row * GameConfig.tileSize),
          size: Vector2.all(GameConfig.tileSize),
          priority: 1,
          anchor: Anchor.topLeft,
        ) {
    paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    final pulse = 1.0 + 0.06 * math.sin(_t * 3);
    final s = GameConfig.tileSize * pulse;
    size = Vector2.all(s);
    position = Vector2(
      col * GameConfig.tileSize - (s - GameConfig.tileSize) / 2,
      row * GameConfig.tileSize - (s - GameConfig.tileSize) / 2,
    );
  }
}
