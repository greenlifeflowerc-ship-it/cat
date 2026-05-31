import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../core/constants.dart';
import '../game_assets.dart';
import 'player_cat.dart';

/// All power-up kinds from section 15, paired with their asset file name.
enum PowerUpType {
  bombCountUp('bomb_count_up'),
  explosionRangeUp('explosion_range_up'),
  speedUp('speed_up'),
  shield('shield'),
  kickBomb('kick_bomb'),
  remoteBomb('remote_bomb'),
  extraLifeHeart('extra_life_heart'),
  freezeEnemy('freeze_enemy'),
  revealPath('reveal_path'),
  doubleScoreStar('double_score_star'),
  temporaryInvincible('temporary_invincible'),
  bombPass('bomb_pass'),
  wallPass('wall_pass'),
  fastBombTimer('fast_bomb_timer'),
  slowEnemy('slow_enemy');

  final String asset;
  const PowerUpType(this.asset);

  String get path => 'powerups/$asset.png';

  /// Pool that can drop from breakable blocks. Heavier effects kept rarer by
  /// simply leaving them out of the common drop pool.
  static const List<PowerUpType> dropPool = [
    bombCountUp,
    explosionRangeUp,
    speedUp,
    shield,
    kickBomb,
    remoteBomb,
    extraLifeHeart,
    doubleScoreStar,
    freezeEnemy,
    slowEnemy,
  ];
}

/// Apply a collected power-up's effect to a cat / the game.
void applyPowerUp(PlayerCat cat, PowerUpType type) {
  final game = cat.game;
  switch (type) {
    case PowerUpType.bombCountUp:
      cat.maxBombs = (cat.maxBombs + 1).clamp(1, 8);
      break;
    case PowerUpType.explosionRangeUp:
      cat.bombRange = (cat.bombRange + 1).clamp(1, 8);
      break;
    case PowerUpType.speedUp:
      cat.speedTiles =
          (cat.speedTiles + GameConfig.speedUpStep).clamp(2.0, 9.0);
      break;
    case PowerUpType.shield:
      cat.shieldTimer = 8.0;
      break;
    case PowerUpType.kickBomb:
      cat.canKickBomb = true;
      break;
    case PowerUpType.remoteBomb:
      cat.hasRemoteBomb = true;
      break;
    case PowerUpType.extraLifeHeart:
      cat.lives += 1;
      break;
    case PowerUpType.temporaryInvincible:
      cat.shieldTimer = 6.0;
      break;
    case PowerUpType.bombPass:
      cat.canPassBombs = true;
      break;
    case PowerUpType.wallPass:
      cat.wallPassTimer = 8.0;
      break;
    case PowerUpType.fastBombTimer:
      cat.fastBombs = true;
      break;
    case PowerUpType.freezeEnemy:
      game.freezeEnemies(4.0);
      break;
    case PowerUpType.slowEnemy:
      game.slowEnemies(6.0);
      break;
    case PowerUpType.revealPath:
      game.revealGoalPath();
      break;
    case PowerUpType.doubleScoreStar:
      game.scoreMultiplier = 2;
      game.addScore(0);
      break;
  }
}

class PowerUpComponent extends SpriteComponent {
  final PowerUpType type;
  final int col;
  final int row;

  PowerUpComponent({
    required Sprite sprite,
    required this.type,
    required this.col,
    required this.row,
  }) : super(
          sprite: sprite,
          position: Vector2(col * GameConfig.tileSize, row * GameConfig.tileSize),
          size: Vector2.all(GameConfig.tileSize),
          priority: 6,
        ) {
    paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
  }

  static Future<PowerUpComponent> create(
    PowerUpType type,
    int col,
    int row,
  ) async {
    final s = await GameAssets.sprite(type.path);
    return PowerUpComponent(sprite: s, type: type, col: col, row: row);
  }
}
