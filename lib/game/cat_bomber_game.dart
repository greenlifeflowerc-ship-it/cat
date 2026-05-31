import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'core/constants.dart';
import 'game_assets.dart';
import 'input/input_state.dart';
import 'levels/level_data.dart';
import 'levels/level_registry.dart';
import 'components/tile_component.dart';
import 'components/breakable_block_component.dart';
import 'components/meeting_goal_component.dart';
import 'components/player_cat.dart';
import 'components/enemy_component.dart';
import 'components/bomb_component.dart';
import 'components/explosion_component.dart';
import 'components/powerup_component.dart';
import 'networking/websocket_client.dart';
import 'networking/online_sync.dart';
import '../services/audio_service.dart';
import '../services/save_service.dart';

enum GameMode { offline, onlineHost, onlineClient }

enum PlayState { loading, playing, paused, won, lost }

class GameResult {
  final bool win;
  final int seconds;
  final int stars;
  final int score;
  const GameResult(this.win, this.seconds, this.stars, this.score);
}

/// Main Flame game. Owns the maze, both cats, enemies, bombs and the win/lose
/// rules. Rendering uses fixed-resolution camera scaling so the 15x13 maze
/// always fits the landscape screen while staying pixel-crisp.
class CatBomberGame extends FlameGame with KeyboardEvents {
  final GameMode mode;
  final int levelIndex; // 1-based
  final void Function(GameResult result)? onEnd;

  /// Which cat the local human controls: 'male_cat' or 'female_cat'. In offline
  /// mode the other cat becomes the AI companion.
  final String playerCharacter;

  // Online session wiring (null offline).
  final GameSocket? socket;
  final String? myPlayerId;
  final String? roomId;

  CatBomberGame({
    required this.mode,
    required this.levelIndex,
    this.onEnd,
    this.playerCharacter = 'male_cat',
    this.socket,
    this.myPlayerId,
    this.roomId,
  });

  OnlineSync? online;

  bool get humanIsMale => playerCharacter == 'male_cat';

  bool get isOnline => mode != GameMode.offline;
  bool get isHost => mode == GameMode.onlineHost;
  bool get isClient => mode == GameMode.onlineClient;

  /// Offline is a solo run: only the human cat is on the map and the goal is to
  /// reach the meeting-goal tile alone. Online spawns both cats.
  bool get isSolo => mode == GameMode.offline;

  /// The cat driven by local input.
  late PlayerCat human;

  /// The partner cat (AI/remote). Null in offline solo mode.
  PlayerCat? companion;

  PlayerCat get localCat => human;

  List<PlayerCat> get activeCats =>
      companion == null ? [human] : [human, companion!];

  late LevelData level;
  late StageInfo stage;

  final InputState input = InputState();

  late PlayerCat male;
  late PlayerCat female;

  // Occupancy maps keyed by row*cols+col.
  final Map<int, BreakableBlockComponent> _blocks = {};
  final Map<int, BombComponent> _bombs = {};
  final List<EnemyComponent> _enemies = [];
  final List<ExplosionComponent> _explosions = [];
  final Map<int, PowerUpComponent> _powerups = {};

  // Online client mirrors of host-authoritative world objects.
  final Map<int, EnemyComponent> _remoteEnemies = {};
  final Set<int> _clientExplosionCells = {};

  // Reusable sprites/animations.
  late SpriteAnimation _bombAnim;
  final Map<String, Sprite> _explosionSprites = {};

  late final Random _rng = Random(levelSeed);
  int get levelSeed => 1000 + levelIndex;

  // HUD-observable state.
  final ValueNotifier<PlayState> state = ValueNotifier(PlayState.loading);
  final ValueNotifier<int> elapsedSeconds = ValueNotifier(0);
  final ValueNotifier<int> hudTick = ValueNotifier(0);
  int score = 0;
  int scoreMultiplier = 1;

  double _timeAcc = 0;
  bool _ended = false;

  // Enemy status effects.
  double _freezeTimer = 0;
  double _slowTimer = 0;
  bool get enemyFrozen => _freezeTimer > 0;
  bool get enemySlow => _slowTimer > 0;

  int _key(int col, int row) => row * level.cols + col;

  @override
  Color backgroundColor() => const Color(0xFF120d24);

  @override
  Future<void> onLoad() async {
    GameAssets.configure();
    level = await LevelLoader.load(levelIndex);
    stage = LevelRegistry.byIndex(levelIndex);

    final w = level.cols * GameConfig.tileSize;
    final h = level.rows * GameConfig.tileSize;
    camera.viewfinder
      ..visibleGameSize = Vector2(w, h)
      ..position = Vector2(w / 2, h / 2)
      ..anchor = Anchor.center;

    await _loadSharedSprites();
    await _buildMap();
    await _spawnCats();
    await _spawnEnemies();

    if (isOnline && socket != null) {
      online = OnlineSync(
        game: this,
        socket: socket!,
        myPlayerId: myPlayerId ?? 'player_1',
        roomId: roomId ?? '',
      )..start();
    }

    state.value = PlayState.playing;
  }

  Future<void> _loadSharedSprites() async {
    _bombAnim = await GameAssets.animFromFrames(
      [
        'bombs/bomb_tick_1.png',
        'bombs/bomb_tick_2.png',
        'bombs/bomb_tick_red.png',
        'bombs/bomb_about_to_explode.png',
      ],
      0.18,
    );
    for (final name in [
      'explosion_center',
      'explosion_horizontal',
      'explosion_vertical',
      'explosion_end_up',
      'explosion_end_down',
      'explosion_end_left',
      'explosion_end_right',
    ]) {
      _explosionSprites[name] = await GameAssets.sprite('explosions/$name.png');
    }
  }

  Future<void> _buildMap() async {
    final floor = await GameAssets.sprite(level.floorAsset);
    final wall = await GameAssets.sprite(level.wallAsset);
    final breakable = await GameAssets.sprite(level.breakableAsset);
    final goal = await GameAssets.sprite(level.goalAsset);

    for (var r = 0; r < level.rows; r++) {
      for (var c = 0; c < level.cols; c++) {
        // Floor everywhere under everything.
        world.add(TileComponent(sprite: floor, col: c, row: r, priority: 0));
        final cell = level.cellAt(c, r);
        if (cell == CellType.wall) {
          world.add(TileComponent(sprite: wall, col: c, row: r, priority: 4));
        } else if (cell == CellType.breakable) {
          final b = BreakableBlockComponent(
            sprite: breakable,
            col: c,
            row: r,
          );
          _blocks[_key(c, r)] = b;
          world.add(b);
        }
      }
    }

    final (gc, gr) = level.meetingGoal;
    world.add(MeetingGoalComponent(sprite: goal, col: gc, row: gr));
  }

  Future<void> _spawnCats() async {
    final (mc, mr) = level.maleStart;
    final (fc, fr) = level.femaleStart;

    male = PlayerCat(
      charId: 'male_cat',
      isMale: true,
      col: mc,
      row: mr,
      localControlled: humanIsMale,
      aiControlled: false,
    );
    female = PlayerCat(
      charId: 'female_cat',
      isMale: false,
      col: fc,
      row: fr,
      localControlled: !humanIsMale,
      aiControlled: false,
    );

    human = humanIsMale ? male : female;
    final partner = humanIsMale ? female : male;

    if (isSolo) {
      // One player, one cat. The partner cat is not spawned.
      companion = null;
      await world.add(human);
    } else {
      // Online co-op: I drive my cat from local input; the partner cat is
      // interpolated from network snapshots.
      companion = partner;
      human.networkControlled = false;
      partner.localControlled = false;
      partner.aiControlled = false;
      partner.networkControlled = true;
      await world.addAll([human, partner]);
    }
  }

  Future<void> _spawnEnemies() async {
    // The online client receives enemies from host snapshots, not local sim.
    if (isClient) return;
    // Place a themed roster on open floor tiles away from both spawns.
    final spots = <(int, int)>[];
    for (var r = 1; r < level.rows - 1; r++) {
      for (var c = 1; c < level.cols - 1; c++) {
        if (level.cellAt(c, r) == CellType.floor &&
            !_blocks.containsKey(_key(c, r))) {
          final farFromMale =
              (c - level.maleStart.$1).abs() + (r - level.maleStart.$2).abs() > 4;
          final farFromFemale =
              (c - level.femaleStart.$1).abs() + (r - level.femaleStart.$2).abs() >
                  4;
          if (farFromMale && farFromFemale) spots.add((c, r));
        }
      }
    }
    spots.shuffle(_rng);
    final count = (2 + levelIndex ~/ 2).clamp(2, 7);
    for (var i = 0; i < count && i < spots.length; i++) {
      final type = stage.enemyTypes[i % stage.enemyTypes.length];
      final (c, r) = spots[i];
      final e = EnemyComponent(type: type, col: c, row: r, seed: levelSeed + i);
      _enemies.add(e);
      world.add(e);
    }
  }

  // ---- Update / win-lose ------------------------------------------------

  @override
  void update(double dt) {
    super.update(dt);
    if (state.value != PlayState.playing) return;

    _timeAcc += dt;
    if (_timeAcc >= 1.0) {
      _timeAcc -= 1.0;
      elapsedSeconds.value += 1;
    }
    hudTick.value++;

    if (_freezeTimer > 0) _freezeTimer -= dt;
    if (_slowTimer > 0) _slowTimer -= dt;

    // Consume edge-triggered bomb input for the local cat.
    if (input.placeBomb) {
      input.placeBomb = false;
      if (isClient) {
        online?.sendPlaceBomb();
      } else {
        localCat.placeBomb();
      }
    }
    if (input.remoteDetonate) {
      input.remoteDetonate = false;
      if (!isClient && localCat.hasRemoteBomb) _detonateOwnerBombs(localCat);
    }

    // The host (and offline) own the authoritative world simulation. The online
    // client renders host snapshots instead.
    if (!isClient) {
      _applyExplosionDamage();
      _checkWinLose();
    }

    online?.update(dt);
  }

  void _applyExplosionDamage() {
    if (_explosions.isEmpty) return;
    final deadly = HashSet<int>();
    for (final e in _explosions) {
      deadly.add(_key(e.col, e.row));
    }
    for (final cat in activeCats) {
      if (cat.alive && deadly.contains(_key(cat.col, cat.row))) {
        cat.hit();
      }
    }
    for (final e in _enemies) {
      if (e.alive && deadly.contains(_key(e.col, e.row))) {
        e.die();
        addScore(100);
        AudioService.instance.play('enemy_defeated');
      }
    }
  }

  void _checkWinLose() {
    // Lose if any active cat is defeated.
    for (final cat in activeCats) {
      if (!cat.alive) {
        _finish(false);
        return;
      }
    }

    if (isSolo) {
      // Solo: reach the meeting-goal tile alone.
      final (gc, gr) = level.meetingGoal;
      if (human.col == gc && human.row == gr) _finish(true);
      return;
    }

    // Co-op: the two cats must meet.
    final dist = (human.col - companion!.col).abs() +
        (human.row - companion!.row).abs();
    if (dist <= 1) _finish(true);
  }

  Future<void> _finish(bool win) async {
    if (_ended) return;
    _ended = true;
    state.value = win ? PlayState.won : PlayState.lost;
    final seconds = elapsedSeconds.value;
    if (win) {
      for (final cat in activeCats) {
        cat.celebrate();
      }
      AudioService.instance.play('level_win');
    } else {
      AudioService.instance.play('level_lose');
    }
    final stars = win ? (seconds < 60 ? 3 : (seconds < 120 ? 2 : 1)) : 0;
    if (win) {
      await SaveService.instance.recordResult(levelIndex, stars, seconds);
    }
    // Host tells the client the authoritative result.
    if (isHost) {
      online?.sendGameEnd(win: win, seconds: seconds, stars: stars);
    }
    onEnd?.call(GameResult(win, seconds, stars, score));
  }

  /// Online client: apply the host's authoritative match result.
  void handleRemoteEnd(bool win, int seconds, int stars) {
    if (_ended) return;
    _ended = true;
    state.value = win ? PlayState.won : PlayState.lost;
    AudioService.instance.play(win ? 'level_win' : 'level_lose');
    onEnd?.call(GameResult(win, seconds, stars, score));
  }

  /// Host: the remote (client) cat requested a bomb at its current tile.
  void placeBombForRemote() {
    if (companion != null) companion!.placeBomb();
  }

  // ---- Online snapshot (host builds, client applies) --------------------

  Map<String, dynamic> _catSnap(PlayerCat c) => {
        'id': c.charId,
        'x': c.position.x,
        'y': c.position.y,
        'dir': c.facing.name,
        'alive': c.alive,
        'maxBombs': c.maxBombs,
        'bombRange': c.bombRange,
        'lives': c.lives,
        'speed': c.speedTiles,
      };

  /// Host: serialize the full authoritative world for the client.
  Map<String, dynamic> buildSnapshot() {
    final gs = switch (state.value) {
      PlayState.won => 'won',
      PlayState.lost => 'lost',
      _ => 'playing',
    };
    return {
      'type': 'snapshot',
      'tick': hudTick.value,
      'cats': [_catSnap(male), _catSnap(female)],
      'enemies': [
        for (var i = 0; i < _enemies.length; i++)
          {
            'i': i,
            'type': _enemies[i].type,
            'x': _enemies[i].position.x,
            'y': _enemies[i].position.y,
            'dir': _enemies[i].facing.name,
            'alive': _enemies[i].alive,
          }
      ],
      'bombs': [
        for (final b in _bombs.values)
          {'k': _key(b.col, b.row), 'x': b.position.x, 'y': b.position.y}
      ],
      'explosions': [
        for (final e in _explosions) {'c': e.col, 'r': e.row}
      ],
      'blocks': [for (final k in _blocks.keys) k],
      'powerups': [
        for (final entry in _powerups.entries)
          {
            'k': entry.key,
            'type': entry.value.type.name,
            'c': entry.value.col,
            'r': entry.value.row,
          }
      ],
      'gameState': gs,
    };
  }

  /// Client: reconcile local visuals with the host snapshot.
  Future<void> applySnapshot(Map<String, dynamic> s) async {
    const tile = GameConfig.tileSize;

    // Cats.
    for (final cs in (s['cats'] as List)) {
      final id = cs['id'] as String;
      final cat = id == male.charId ? male : female;
      final x = (cs['x'] as num).toDouble();
      final y = (cs['y'] as num).toDouble();
      final alive = cs['alive'] == true;
      if (cat == human) {
        // Mirror authoritative stats; keep locally-predicted position.
        cat.maxBombs = cs['maxBombs'] as int;
        cat.bombRange = cs['bombRange'] as int;
        cat.lives = cs['lives'] as int;
        cat.speedTiles = (cs['speed'] as num).toDouble();
        if (!alive) cat.forceDefeat();
      } else {
        cat.applyNetwork(x, y, cs['dir'] as String, alive);
      }
    }

    // Enemies.
    final seenEnemies = <int>{};
    for (final es in (s['enemies'] as List)) {
      final i = es['i'] as int;
      seenEnemies.add(i);
      final x = (es['x'] as num).toDouble();
      final y = (es['y'] as num).toDouble();
      var e = _remoteEnemies[i];
      if (e == null) {
        final col = ((x / tile) - 0.5).round();
        final row = ((y / tile) - 0.5).round();
        e = EnemyComponent(type: es['type'] as String, col: col, row: row, seed: i)
          ..remote = true;
        _remoteEnemies[i] = e;
        world.add(e);
      }
      e.applyNetwork(x, y, es['dir'] as String, es['alive'] == true);
    }
    for (final i in _remoteEnemies.keys.toList()) {
      if (!seenEnemies.contains(i)) {
        _remoteEnemies.remove(i)!.removeFromParent();
      }
    }

    // Bombs.
    final bombKeys = <int>{};
    for (final bs in (s['bombs'] as List)) {
      final k = bs['k'] as int;
      bombKeys.add(k);
      if (!_bombs.containsKey(k)) {
        final x = (bs['x'] as num).toDouble();
        final y = (bs['y'] as num).toDouble();
        final b = BombComponent(
          animation: _bombAnim,
          col: (x / tile).round(),
          row: (y / tile).round(),
          owner: human,
          range: 1,
          fuse: 99,
        )..remote = true;
        _bombs[k] = b;
        world.add(b);
      }
    }
    for (final k in _bombs.keys.toList()) {
      if (!bombKeys.contains(k)) {
        _bombs.remove(k)!.removeFromParent();
      }
    }

    // Breakable blocks: drop any the host has destroyed.
    final aliveBlocks = {for (final k in (s['blocks'] as List)) k as int};
    for (final k in _blocks.keys.toList()) {
      if (!aliveBlocks.contains(k)) {
        _blocks.remove(k)!.removeFromParent();
      }
    }

    // Power-ups.
    final puKeys = <int>{};
    for (final ps in (s['powerups'] as List)) {
      final k = ps['k'] as int;
      puKeys.add(k);
      if (!_powerups.containsKey(k)) {
        final type = PowerUpType.values.firstWhere(
          (t) => t.name == ps['type'],
          orElse: () => PowerUpType.speedUp,
        );
        final pu = await PowerUpComponent.create(
            type, ps['c'] as int, ps['r'] as int);
        _powerups[k] = pu;
        world.add(pu);
      }
    }
    for (final k in _powerups.keys.toList()) {
      if (!puKeys.contains(k)) {
        _powerups.remove(k)!.removeFromParent();
      }
    }

    // Explosions: flash newly-appearing cells.
    final cells = <int>{};
    for (final xs in (s['explosions'] as List)) {
      cells.add(_key(xs['c'] as int, xs['r'] as int));
    }
    for (final ck in cells) {
      if (!_clientExplosionCells.contains(ck)) {
        final c = ck % level.cols;
        final r = ck ~/ level.cols;
        world.add(ExplosionComponent(
          sprite: _explosionSprites['explosion_center']!,
          col: c,
          row: r,
        ));
      }
    }
    _clientExplosionCells
      ..clear()
      ..addAll(cells);
  }

  void addScore(int base) {
    score += base * scoreMultiplier;
  }

  // ---- Walkability ------------------------------------------------------

  bool _hasBomb(int c, int r) => _bombs.containsKey(_key(c, r));

  bool isWalkableForCat(int c, int r, PlayerCat cat) {
    if (level.cellAt(c, r) == CellType.wall) return false;
    if (_blocks.containsKey(_key(c, r))) return cat.wallPass;
    final bomb = _bombs[_key(c, r)];
    if (bomb != null) {
      if (cat.canPassBombs) return true;
      // Allow the owner to remain on / step off the bomb they just placed.
      if (bomb.owner == cat && bomb.ownerStanding) return true;
      return false;
    }
    return true;
  }

  bool isWalkableForEnemy(int c, int r, bool passesBreakable) {
    if (level.cellAt(c, r) == CellType.wall) return false;
    if (_blocks.containsKey(_key(c, r))) return passesBreakable;
    if (_hasBomb(c, r)) return false;
    return true;
  }

  // ---- Tile events ------------------------------------------------------

  void onCatEnteredTile(PlayerCat cat) {
    // The owner has stepped off their bomb's tile -> bomb becomes solid.
    for (final bomb in _bombs.values) {
      if (bomb.owner == cat && (bomb.col != cat.col || bomb.row != cat.row)) {
        bomb.ownerStanding = false;
      }
    }
    // Collect power-up on this tile.
    final pu = _powerups.remove(_key(cat.col, cat.row));
    if (pu != null) {
      cat.collect(pu);
      pu.removeFromParent();
      AudioService.instance.play('powerup_pickup');
    }
  }

  void enemyTouchCats(EnemyComponent e) {
    for (final cat in activeCats) {
      if (cat.alive && cat.col == e.col && cat.row == e.row) {
        cat.hit();
        AudioService.instance.play('cat_hurt');
      }
    }
  }

  // ---- Bombs ------------------------------------------------------------

  Future<void> placeBomb(PlayerCat cat) async {
    final k = _key(cat.col, cat.row);
    if (_bombs.containsKey(k)) return;
    final bomb = BombComponent(
      animation: _bombAnim,
      col: cat.col,
      row: cat.row,
      owner: cat,
      range: cat.bombRange,
      fuse: cat.fastBombs ? 1.4 : GameConfig.bombFuseSeconds,
    );
    bomb.ownerStanding = true;
    _bombs[k] = bomb;
    cat.activeBombs++;
    world.add(bomb);
    AudioService.instance.play('bomb_place');
  }

  void _detonateOwnerBombs(PlayerCat cat) {
    final owned = _bombs.values.where((b) => b.owner == cat && !b.exploded).toList();
    for (final b in owned) {
      b.triggerNow();
    }
  }

  Future<void> detonateBomb(BombComponent bomb) async {
    if (bomb.exploded) return;
    bomb.exploded = true;
    _bombs.remove(_key(bomb.col, bomb.row));
    bomb.owner.activeBombs = (bomb.owner.activeBombs - 1).clamp(0, 99);
    bomb.removeFromParent();
    AudioService.instance.play('explosion');

    final affected = <(int, int, String)>[];
    affected.add((bomb.col, bomb.row, 'explosion_center'));

    for (final d in Direction.values) {
      final (dx, dy) = d.delta;
      for (var i = 1; i <= bomb.range; i++) {
        final c = bomb.col + dx * i;
        final r = bomb.row + dy * i;
        if (level.cellAt(c, r) == CellType.wall) break;

        // Chain reaction: a bomb in the path detonates immediately.
        final chained = _bombs[_key(c, r)];

        final block = _blocks[_key(c, r)];
        if (block != null) {
          await _destroyBlock(block);
          affected.add((c, r, _armSprite(d, true)));
          break; // explosion stops after destroying a block
        }

        final isTip = i == bomb.range;
        affected.add((c, r, _armSprite(d, isTip)));

        if (chained != null) {
          chained.triggerNow();
        }
      }
    }

    for (final (c, r, spriteName) in affected) {
      final exp = ExplosionComponent(
        sprite: _explosionSprites[spriteName] ??
            _explosionSprites['explosion_center']!,
        col: c,
        row: r,
      );
      _explosions.add(exp);
      world.add(exp);
      exp.add(_ExplosionReaper(() => _explosions.remove(exp)));
    }
  }

  String _armSprite(Direction d, bool tip) {
    if (!tip) {
      return (d == Direction.left || d == Direction.right)
          ? 'explosion_horizontal'
          : 'explosion_vertical';
    }
    return switch (d) {
      Direction.up => 'explosion_end_up',
      Direction.down => 'explosion_end_down',
      Direction.left => 'explosion_end_left',
      Direction.right => 'explosion_end_right',
    };
  }

  Future<void> _destroyBlock(BreakableBlockComponent block) async {
    if (block.destroyed) return;
    block.destroyed = true;
    _blocks.remove(_key(block.col, block.row));
    block.removeFromParent();
    AudioService.instance.play('block_break');
    addScore(20);

    if (_rng.nextDouble() < GameConfig.powerupDropChance) {
      final type = PowerUpType
          .dropPool[_rng.nextInt(PowerUpType.dropPool.length)];
      final pu = await PowerUpComponent.create(type, block.col, block.row);
      _powerups[_key(block.col, block.row)] = pu;
      world.add(pu);
    }
  }

  void tryKickBomb(PlayerCat cat, Direction d) {
    final (dx, dy) = d.delta;
    final bc = cat.col + dx;
    final br = cat.row + dy;
    final bomb = _bombs[_key(bc, br)];
    if (bomb == null) return;
    // Slide the bomb one tile if the next cell is free.
    final nc = bc + dx;
    final nr = br + dy;
    if (level.cellAt(nc, nr) != CellType.wall &&
        !_blocks.containsKey(_key(nc, nr)) &&
        !_bombs.containsKey(_key(nc, nr))) {
      _bombs.remove(_key(bc, br));
      bomb.col = nc;
      bomb.row = nr;
      bomb.position =
          Vector2(nc * GameConfig.tileSize, nr * GameConfig.tileSize);
      _bombs[_key(nc, nr)] = bomb;
    }
  }

  // ---- Enemy effects ----------------------------------------------------

  void freezeEnemies(double seconds) => _freezeTimer = seconds;
  void slowEnemies(double seconds) => _slowTimer = seconds;
  void revealGoalPath() {
    // Lightweight reveal: briefly mark the goal cell brighter is handled by
    // the pulsing goal component; here we just grant a small score bonus.
    addScore(10);
  }

  // ---- AI companion (offline female) ------------------------------------

  Direction? aiDirectionFor(PlayerCat cat) {
    final danger = _dangerCells();
    final here = _key(cat.col, cat.row);

    // Flee if standing in danger.
    if (danger.contains(here)) {
      for (final d in Direction.values) {
        final nc = cat.col + d.delta.$1;
        final nr = cat.row + d.delta.$2;
        if (isWalkableForCat(nc, nr, cat) && !danger.contains(_key(nc, nr))) {
          return d;
        }
      }
      return null;
    }

    // Target: meet the human-controlled cat.
    final human = cat == male ? female : male;
    final target = (human.col, human.row);
    final step = _bfsStep(cat, target, danger);
    if (step != null) return step;

    // Blocked by breakable: bomb toward target, then it will flee next ticks.
    final toward = _towardBreakable(cat, target);
    if (toward != null && cat.activeBombs < cat.maxBombs) {
      cat.facing = toward;
      cat.placeBomb();
      return null;
    }

    // Otherwise wander somewhere safe.
    for (final d in Direction.values) {
      final nc = cat.col + d.delta.$1;
      final nr = cat.row + d.delta.$2;
      if (isWalkableForCat(nc, nr, cat) && !danger.contains(_key(nc, nr))) {
        return d;
      }
    }
    return null;
  }

  HashSet<int> _dangerCells() {
    final danger = HashSet<int>();
    for (final e in _explosions) {
      danger.add(_key(e.col, e.row));
    }
    for (final bomb in _bombs.values) {
      danger.add(_key(bomb.col, bomb.row));
      for (final d in Direction.values) {
        for (var i = 1; i <= bomb.range; i++) {
          final c = bomb.col + d.delta.$1 * i;
          final r = bomb.row + d.delta.$2 * i;
          if (level.cellAt(c, r) == CellType.wall) break;
          danger.add(_key(c, r));
          if (_blocks.containsKey(_key(c, r))) break;
        }
      }
    }
    return danger;
  }

  /// BFS over safe floor cells; returns the first step direction toward target.
  Direction? _bfsStep(PlayerCat cat, (int, int) target, HashSet<int> danger) {
    final start = (cat.col, cat.row);
    if (start == target) return null;
    final queue = Queue<(int, int)>()..add(start);
    final cameFrom = <int, (int, int)>{};
    final visited = HashSet<int>()..add(_key(start.$1, start.$2));

    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      for (final d in Direction.values) {
        final nc = cur.$1 + d.delta.$1;
        final nr = cur.$2 + d.delta.$2;
        final k = _key(nc, nr);
        if (visited.contains(k)) continue;
        final isTarget = (nc, nr) == target;
        final passable = level.cellAt(nc, nr) != CellType.wall &&
            !_blocks.containsKey(k) &&
            !_hasBomb(nc, nr) &&
            !danger.contains(k);
        if (!passable && !isTarget) continue;
        visited.add(k);
        cameFrom[k] = cur;
        if (isTarget) {
          return _firstStepDir(start, (nc, nr), cameFrom);
        }
        queue.add((nc, nr));
      }
    }
    return null;
  }

  Direction _firstStepDir(
    (int, int) start,
    (int, int) goal,
    Map<int, (int, int)> cameFrom,
  ) {
    var cur = goal;
    while (cameFrom[_key(cur.$1, cur.$2)] != start) {
      cur = cameFrom[_key(cur.$1, cur.$2)]!;
    }
    final dx = cur.$1 - start.$1;
    final dy = cur.$2 - start.$2;
    if (dx > 0) return Direction.right;
    if (dx < 0) return Direction.left;
    if (dy > 0) return Direction.down;
    return Direction.up;
  }

  Direction? _towardBreakable(PlayerCat cat, (int, int) target) {
    Direction? best;
    var bestDist = 1 << 30;
    for (final d in Direction.values) {
      final nc = cat.col + d.delta.$1;
      final nr = cat.row + d.delta.$2;
      if (_blocks.containsKey(_key(nc, nr))) {
        final dist = (nc - target.$1).abs() + (nr - target.$2).abs();
        if (dist < bestDist) {
          bestDist = dist;
          best = d;
        }
      }
    }
    return best;
  }

  // ---- Pause / keyboard -------------------------------------------------

  @override
  void onRemove() {
    online?.dispose();
    super.onRemove();
  }

  void pauseGame() {
    if (state.value == PlayState.playing) state.value = PlayState.paused;
  }

  void resumeGame() {
    if (state.value == PlayState.paused) state.value = PlayState.playing;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    bool down(LogicalKeyboardKey a, LogicalKeyboardKey b) =>
        keysPressed.contains(a) || keysPressed.contains(b);
    input
      ..up = down(LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW)
      ..down = down(LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS)
      ..left = down(LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA)
      ..right = down(LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD);

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        input.placeBomb = true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyE) {
        input.remoteDetonate = true;
      }
    }
    return KeyEventResult.handled;
  }
}

/// Tiny helper that runs a callback when its parent explosion is removed, so
/// the game can drop it from the active-explosion list.
class _ExplosionReaper extends Component {
  final void Function() callback;
  _ExplosionReaper(this.callback);
  @override
  void onRemove() {
    callback();
    super.onRemove();
  }
}
