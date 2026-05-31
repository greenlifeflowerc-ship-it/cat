import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/painting.dart';

import '../core/constants.dart';
import '../game_assets.dart';
import '../cat_bomber_game.dart';

/// Grid-based enemy. Behaviour varies by type (section 24) but all share the
/// same stepping locomotion so they stay aligned to the maze.
class EnemyComponent extends SpriteAnimationComponent
    with HasGameReference<CatBomberGame> {
  final String type;
  int col;
  int row;
  Direction facing = Direction.down;
  bool moving = false;
  bool alive = true;
  Vector2 _target = Vector2.zero();

  double _pauseTimer = 0;
  final Random _rng;

  // Per-type traits.
  late final double speedTiles;
  late final bool passesBreakable; // ghost
  late final bool straightPatrol; // robot / fire_bug

  final Map<String, SpriteAnimation> _anims = {};

  EnemyComponent({
    required this.type,
    required this.col,
    required this.row,
    required int seed,
  })  : _rng = Random(seed),
        super(
          size: Vector2.all(GameConfig.tileSize * 1.2),
          anchor: Anchor.center,
          priority: 25,
        ) {
    paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    switch (type) {
      case 'bat':
        speedTiles = 3.2;
        passesBreakable = false;
        straightPatrol = false;
        break;
      case 'robot':
        speedTiles = 2.4;
        passesBreakable = false;
        straightPatrol = true;
        break;
      case 'ghost':
        speedTiles = 2.0;
        passesBreakable = true;
        straightPatrol = false;
        break;
      case 'fire_bug':
        speedTiles = 3.4;
        passesBreakable = false;
        straightPatrol = true;
        break;
      case 'ice_turtle':
        speedTiles = 1.4;
        passesBreakable = false;
        straightPatrol = false;
        break;
      case 'slime':
      default:
        speedTiles = 1.8;
        passesBreakable = false;
        straightPatrol = false;
    }
  }

  Vector2 get centerPixel => Vector2(
        (col + 0.5) * GameConfig.tileSize,
        (row + 0.5) * GameConfig.tileSize,
      );

  @override
  Future<void> onLoad() async {
    for (final d in Direction.values) {
      _anims['move_${d.name}'] = await GameAssets.enemyMove(type, d);
      _anims['idle_${d.name}'] = await GameAssets.enemyIdle(type, d);
    }
    position = centerPixel;
    animation = _anims['idle_${facing.name}'];
  }

  bool _canEnter(int c, int r) {
    return game.isWalkableForEnemy(c, r, passesBreakable);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!alive) return;

    final scale = game.enemyFrozen ? 0.0 : (game.enemySlow ? 0.5 : 1.0);
    if (scale == 0.0) {
      animation = _anims['idle_${facing.name}'];
      return;
    }

    if (moving) {
      final dir = _target - position;
      final step = speedTiles * scale * GameConfig.tileSize * dt;
      if (dir.length <= step) {
        position = _target.clone();
        moving = false;
      } else {
        dir.normalize();
        position += dir * step;
      }
      _checkCatCollision();
      return;
    }

    if (_pauseTimer > 0) {
      _pauseTimer -= dt;
      animation = _anims['idle_${facing.name}'];
      return;
    }

    _decide();
    _checkCatCollision();
  }

  void _decide() {
    // Straight patrollers keep going; turn at walls. Others wander.
    final candidates = <Direction>[];
    if (straightPatrol && _canEnter(col + facing.delta.$1, row + facing.delta.$2)) {
      candidates.add(facing);
    } else {
      for (final d in Direction.values) {
        if (_canEnter(col + d.delta.$1, row + d.delta.$2)) candidates.add(d);
      }
    }
    if (candidates.isEmpty) {
      _pauseTimer = 0.4;
      return;
    }
    // Ice turtle hesitates.
    if (type == 'ice_turtle' && _rng.nextDouble() < 0.35) {
      _pauseTimer = 0.6;
      return;
    }
    final d = candidates[_rng.nextInt(candidates.length)];
    facing = d;
    col += d.delta.$1;
    row += d.delta.$2;
    _target = centerPixel;
    moving = true;
    animation = _anims['move_${facing.name}'];
  }

  void _checkCatCollision() {
    game.enemyTouchCats(this);
  }

  Future<void> die() async {
    if (!alive) return;
    alive = false;
    moving = false;
    animation = SpriteAnimation.spriteList(
      [await GameAssets.enemyDefeated(type)],
      stepTime: 0.4,
      loop: false,
    );
    add(RemoveEffect(delay: 0.4));
  }
}
