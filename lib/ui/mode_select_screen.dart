import 'package:flutter/material.dart';

import 'level_select_screen.dart';
import 'online_lobby_screen.dart';
import 'widgets/pixel_button.dart';

class ModeSelectScreen extends StatelessWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Mode')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Two cats. One maze.\nBomb your way to each other.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 28),
            PixelButton(
              label: 'OFFLINE',
              icon: Icons.smart_toy,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
              ),
            ),
            const SizedBox(height: 14),
            PixelButton(
              label: 'ONLINE CO-OP',
              icon: Icons.wifi,
              color: const Color(0xFF6fa8ff),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnlineLobbyScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
