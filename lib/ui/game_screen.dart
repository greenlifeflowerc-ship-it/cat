import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/cat_bomber_game.dart';
import '../game/core/constants.dart';
import '../game/levels/level_registry.dart';
import '../game/networking/websocket_client.dart';
import 'widgets/touch_controls.dart';
import 'widgets/hud_overlay.dart';
import 'widgets/result_overlay.dart';
import 'widgets/pause_overlay.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final int levelIndex;
  final String playerCharacter;
  final GameSocket? socket;
  final String? myPlayerId;
  final String? roomId;
  const GameScreen({
    super.key,
    required this.mode,
    required this.levelIndex,
    this.playerCharacter = 'male_cat',
    this.socket,
    this.myPlayerId,
    this.roomId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late CatBomberGame _game;
  late int _levelIndex;
  GameResult? _result;

  @override
  void initState() {
    super.initState();
    _levelIndex = widget.levelIndex;
    _game = _build(_levelIndex);
  }

  CatBomberGame _build(int level) => CatBomberGame(
        mode: widget.mode,
        levelIndex: level,
        playerCharacter: widget.playerCharacter,
        socket: widget.socket,
        myPlayerId: widget.myPlayerId,
        roomId: widget.roomId,
        onEnd: (r) => setState(() => _result = r),
      );

  void _restart() {
    setState(() {
      _result = null;
      _game = _build(_levelIndex);
    });
  }

  void _next() {
    if (_levelIndex >= GameConfig.totalLevels) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _result = null;
      _levelIndex += 1;
      _game = _build(_levelIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stageName = LevelRegistry.byIndex(_levelIndex).name;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),
          // HUD + on-screen pause button.
          HudOverlay(game: _game, stageName: stageName),
          // Touch controls (hidden once the round ends).
          if (_result == null)
            TouchControls(input: _game.input),
          // Pause overlay.
          ValueListenableBuilder<PlayState>(
            valueListenable: _game.state,
            builder: (context, st, _) {
              if (st == PlayState.paused) {
                return PauseOverlay(
                  onResume: _game.resumeGame,
                  onRestart: _restart,
                  onQuit: () => Navigator.pop(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Win / lose overlay.
          if (_result != null)
            ResultOverlay(
              result: _result!,
              levelIndex: _levelIndex,
              onRetry: _restart,
              onNext: _next,
              onMenu: () => Navigator.pop(context),
            ),
        ],
      ),
    );
  }
}
