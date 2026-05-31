import 'package:flutter/material.dart';

import '../../game/cat_bomber_game.dart';
import '../../game/core/constants.dart';
import 'pixel_button.dart';

class ResultOverlay extends StatelessWidget {
  final GameResult result;
  final int levelIndex;
  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onMenu;

  const ResultOverlay({
    super.key,
    required this.result,
    required this.levelIndex,
    required this.onRetry,
    required this.onNext,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final win = result.win;
    final hasNext = levelIndex < GameConfig.totalLevels;
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              win
                  ? 'assets/game/ui/win_icon.png'
                  : 'assets/game/ui/lose_icon.png',
              width: 90,
              filterQuality: FilterQuality.none,
            ),
            const SizedBox(height: 8),
            Text(
              win ? 'STAGE CLEARED!' : 'OH NO...',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: win ? const Color(0xFFffd34d) : const Color(0xFFff5a4d),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            if (win)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final full = i < result.stars;
                  return Image.asset(
                    full
                        ? 'assets/game/ui/star_rating_full.png'
                        : 'assets/game/ui/star_rating_empty.png',
                    width: 40,
                    filterQuality: FilterQuality.none,
                  );
                }),
              ),
            const SizedBox(height: 6),
            Text(
              'Time ${result.seconds}s   Score ${result.score}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            if (win && hasNext)
              PixelButton(label: 'NEXT STAGE', icon: Icons.skip_next, onTap: onNext),
            if (win && hasNext) const SizedBox(height: 12),
            PixelButton(
              label: 'RETRY',
              icon: Icons.refresh,
              color: const Color(0xFF6fa8ff),
              onTap: onRetry,
            ),
            const SizedBox(height: 12),
            PixelButton(
              label: 'MENU',
              icon: Icons.home,
              color: const Color(0xFFff8a3d),
              onTap: onMenu,
            ),
          ],
        ),
      ),
    );
  }
}
