import 'package:flutter/material.dart';

import 'pixel_button.dart';

class PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;
  const PauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('PAUSED',
                style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4)),
            const SizedBox(height: 24),
            PixelButton(label: 'RESUME', icon: Icons.play_arrow, onTap: onResume),
            const SizedBox(height: 12),
            PixelButton(
                label: 'RESTART',
                icon: Icons.refresh,
                color: const Color(0xFF6fa8ff),
                onTap: onRestart),
            const SizedBox(height: 12),
            PixelButton(
                label: 'QUIT',
                icon: Icons.home,
                color: const Color(0xFFff5a4d),
                onTap: onQuit),
          ],
        ),
      ),
    );
  }
}
