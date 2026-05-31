import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/constants.dart';
import '../cat_bomber_game.dart';
import 'player_cat.dart';

/// A placed bomb. Counts down its fuse, animates its tick frames, then asks the
/// game to detonate it (which spawns the cross explosion). Can be detonated
/// early by the explosion of a neighbouring bomb (chain reaction) or by a
/// remote trigger.
class BombComponent extends SpriteAnimationComponent
    with HasGameReference<CatBomberGame> {
  int col;
  int row;
  final PlayerCat owner;
  final int range;
  double fuse;
  bool exploded = false;

  /// Whether the owner is still standing on the bomb (so they may walk off it).
  bool ownerStanding = true;

  BombComponent({
    required SpriteAnimation animation,
    required this.col,
    required this.row,
    required this.owner,
    required this.range,
    required this.fuse,
  }) : super(
          animation: animation,
          position: Vector2(col * GameConfig.tileSize, row * GameConfig.tileSize),
          size: Vector2.all(GameConfig.tileSize),
          priority: 8,
        ) {
    paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (exploded) return;
    fuse -= dt;
    if (fuse <= 0) {
      game.detonateBomb(this);
    }
  }

  /// Force an immediate detonation (chain reaction / remote trigger).
  void triggerNow() {
    if (!exploded) game.detonateBomb(this);
  }
}
