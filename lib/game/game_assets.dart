import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import 'core/constants.dart';

/// Loads sprites and animations from the generated asset pack. All paths are
/// relative to `assets/game/` because we set `Flame.images.prefix` to that.
class GameAssets {
  static const String prefix = 'assets/game/';

  static void configure() {
    Flame.images.prefix = prefix;
  }

  static Future<Sprite> sprite(String path) async {
    final image = await Flame.images.load(path);
    return Sprite(image);
  }

  static Future<SpriteAnimation> animFromFrames(
    List<String> paths,
    double stepTime, {
    bool loop = true,
  }) async {
    final sprites = <Sprite>[];
    for (final p in paths) {
      sprites.add(await sprite(p));
    }
    return SpriteAnimation.spriteList(sprites, stepTime: stepTime, loop: loop);
  }

  // ---- Cats -------------------------------------------------------------
  // charId is 'male_cat' or 'female_cat'.

  static String _catFrame(String charId, String frame) =>
      'characters/$charId/frames/$frame.png';

  static Future<SpriteAnimation> catIdle(String charId, Direction dir) {
    final f = dir.faceWord;
    return animFromFrames([_catFrame(charId, 'idle_$f')], 1.0);
  }

  static Future<SpriteAnimation> catWalk(String charId, Direction dir) {
    final f = dir.faceWord;
    return animFromFrames(
      [_catFrame(charId, 'walk_${f}_1'), _catFrame(charId, 'walk_${f}_2')],
      0.14,
    );
  }

  static Future<Sprite> catFace(String charId, String name) =>
      sprite(_catFrame(charId, name)); // hurt / happy / defeated / place_bomb

  // ---- Enemies ----------------------------------------------------------
  // Each enemy folder uses a different "move word".

  static const Map<String, String> enemyMoveWord = {
    'slime': 'move',
    'bat': 'fly',
    'robot': 'walk',
    'ghost': 'float',
    'fire_bug': 'walk',
    'ice_turtle': 'walk',
  };

  static String _enemyFrame(String type, String frame) =>
      'enemies/$type/frames/$frame.png';

  static Future<SpriteAnimation> enemyIdle(String type, Direction dir) {
    return animFromFrames([_enemyFrame(type, 'idle_${dir.faceWord}')], 1.0);
  }

  static Future<SpriteAnimation> enemyMove(String type, Direction dir) {
    final word = enemyMoveWord[type] ?? 'move';
    final f = dir.faceWord;
    return animFromFrames(
      [_enemyFrame(type, '${word}_${f}_1'), _enemyFrame(type, '${word}_${f}_2')],
      0.16,
    );
  }

  static Future<Sprite> enemyDefeated(String type) =>
      sprite(_enemyFrame(type, 'defeated'));
}
