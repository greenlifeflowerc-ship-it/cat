import 'package:flutter/material.dart';

import '../../game/cat_bomber_game.dart';

/// Top bar: hearts/bomb/range for the local cat, timer in the centre, score
/// and pause button on the right. Rebuilds cheaply off the game's hudTick.
class HudOverlay extends StatelessWidget {
  final CatBomberGame game;
  final String stageName;
  const HudOverlay({super.key, required this.game, required this.stageName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: ValueListenableBuilder<PlayState>(
          valueListenable: game.state,
          builder: (context, st, _) {
            // Cats aren't spawned until the level finishes loading.
            if (st == PlayState.loading) return const SizedBox.shrink();
            return ValueListenableBuilder<int>(
              valueListenable: game.hudTick,
              builder: (context, _, child) => _bar(),
            );
          },
        ),
      ),
    );
  }

  Widget _bar() {
    final cat = game.localCat;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statChip(
                  'assets/game/ui/heart_ui.png',
                  '${cat.lives}',
                ),
                const SizedBox(width: 6),
                _statChip(
                  'assets/game/ui/bomb_ui_icon.png',
                  '${cat.maxBombs}',
                ),
                const SizedBox(width: 6),
                _statChip(
                  'assets/game/ui/range_ui_icon.png',
                  '${cat.bombRange}',
                ),
                const Spacer(),
                Column(
                  children: [
                    _timer(),
                    Text(
                      stageName,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${game.score}',
                  style: const TextStyle(
                    color: Color(0xFFffd34d),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: game.pauseGame,
                  child: Image.asset(
                    'assets/game/ui/pause_button.png',
                    width: 32,
                    filterQuality: FilterQuality.none,
                  ),
                ),
              ],
            );
  }

  Widget _timer() {
    return ValueListenableBuilder<int>(
      valueListenable: game.elapsedSeconds,
      builder: (context, s, _) {
        final mm = (s ~/ 60).toString().padLeft(2, '0');
        final ss = (s % 60).toString().padLeft(2, '0');
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/game/ui/timer_icon.png',
                width: 18, filterQuality: FilterQuality.none),
            const SizedBox(width: 4),
            Text('$mm:$ss',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        );
      },
    );
  }

  Widget _statChip(String asset, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(asset, width: 18, filterQuality: FilterQuality.none),
          const SizedBox(width: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
