import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/constants.dart';
import '../game_assets.dart';
import '../cat_bomber_game.dart';
import 'powerup_component.dart';

/// A playable cat. Handles grid-locked stepping movement, animation state and
/// its own stat block. Driven either by local input, the AI companion logic,
/// or (in online mode) the network sync layer writing its target tile.
class PlayerCat extends SpriteAnimationComponent
    with HasGameReference<CatBomberGame> {
  final String charId; // 'male_cat' | 'female_cat'
  final bool isMale;

  /// True if this cat reads from the local InputState. The other cat is the
  /// AI companion (offline) or a remote player (online).
  bool localControlled;
  bool aiControlled;

  int col;
  int row;
  Direction facing = Direction.down;
  bool moving = false;
  Vector2 _target = Vector2.zero();

  // Stats (section 12).
  double speedTiles = GameConfig.baseMoveTilesPerSec;
  int maxBombs = GameConfig.defaultBombCount;
  int bombRange = GameConfig.defaultBombRange;
  int activeBombs = 0;
  bool canKickBomb = false;
  bool hasRemoteBomb = false;
  bool canPassBombs = false;
  bool fastBombs = false;
  double shieldTimer = 0;
  double wallPassTimer = 0;
  int lives = 1;
  bool alive = true;

  double _hurtFlash = 0;

  final Map<String, SpriteAnimation> _anims = {};

  PlayerCat({
    required this.charId,
    required this.isMale,
    required this.col,
    required this.row,
    this.localControlled = true,
    this.aiControlled = false,
  }) : super(
          size: Vector2.all(GameConfig.tileSize * 1.3),
          anchor: Anchor.center,
          priority: 30,
        ) {
    paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
  }

  bool get wallPass => wallPassTimer > 0;
  bool get shielded => shieldTimer > 0;

  Vector2 get centerPixel => Vector2(
        (col + 0.5) * GameConfig.tileSize,
        (row + 0.5) * GameConfig.tileSize,
      );

  @override
  Future<void> onLoad() async {
    for (final d in Direction.values) {
      _anims['idle_${d.name}'] = await GameAssets.catIdle(charId, d);
      _anims['walk_${d.name}'] = await GameAssets.catWalk(charId, d);
    }
    position = centerPixel;
    animation = _anims['idle_${facing.name}'];
  }

  void _setAnim(String key) {
    final a = _anims[key];
    if (a != null && animation != a) animation = a;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!alive) return;

    if (shieldTimer > 0) shieldTimer -= dt;
    if (wallPassTimer > 0) wallPassTimer -= dt;
    if (_hurtFlash > 0) {
      _hurtFlash -= dt;
      paint.color = const Color(0xFFFFFFFF).withValues(
        alpha: 0.5 + 0.5 * (1 - _hurtFlash),
      );
    } else {
      paint.color = const Color(0xFFFFFFFF);
    }

    if (moving) {
      final dir = (_target - position);
      final step = speedTiles * GameConfig.tileSize * dt;
      if (dir.length <= step) {
        position = _target.clone();
        moving = false;
        _onArrive();
      } else {
        dir.normalize();
        position += dir * step;
        _setAnim('walk_${facing.name}');
      }
      return;
    }

    // Aligned on a tile: decide the next step.
    final desired = aiControlled
        ? game.aiDirectionFor(this)
        : (localControlled ? game.input.heldDirection : null);

    if (desired != null) {
      _tryStep(desired);
    } else {
      _setAnim('idle_${facing.name}');
    }
  }

  void _tryStep(Direction d) {
    facing = d;
    final (dx, dy) = d.delta;
    final nc = col + dx;
    final nr = row + dy;
    if (game.isWalkableForCat(nc, nr, this)) {
      col = nc;
      row = nr;
      _target = centerPixel;
      moving = true;
      _setAnim('walk_${facing.name}');
    } else {
      _setAnim('idle_${facing.name}');
      // Try to kick a bomb that's blocking us.
      if (canKickBomb) game.tryKickBomb(this, d);
    }
  }

  void _onArrive() {
    game.onCatEnteredTile(this);
  }

  void placeBomb() {
    if (!alive) return;
    if (activeBombs >= maxBombs) return;
    game.placeBomb(this);
  }

  void collect(PowerUpComponent p) {
    applyPowerUp(this, p.type);
    game.addScore(50);
  }

  /// Returns true if the hit was absorbed (shield), false if it killed/used a
  /// life.
  bool hit() {
    if (!alive) return true;
    if (shielded) return true;
    lives -= 1;
    if (lives > 0) {
      shieldTimer = 2.0; // brief respawn protection
      _hurtFlash = 0.6;
      return true;
    }
    alive = false;
    _die();
    return false;
  }

  Future<void> _die() async {
    moving = false;
    animation = SpriteAnimation.spriteList(
      [await GameAssets.catFace(charId, 'defeated')],
      stepTime: 1,
      loop: false,
    );
  }

  Future<void> celebrate() async {
    moving = false;
    animation = SpriteAnimation.spriteList(
      [await GameAssets.catFace(charId, 'happy')],
      stepTime: 1,
      loop: false,
    );
  }
}
