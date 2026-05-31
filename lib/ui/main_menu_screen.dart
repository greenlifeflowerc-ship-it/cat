import 'package:flutter/material.dart';

import 'mode_select_screen.dart';
import 'settings_screen.dart';
import 'widgets/pixel_button.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2b1d52), Color(0xFF120d24)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/game/ui/player_1_cat_icon.png',
                    width: 84,
                    filterQuality: FilterQuality.none,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'CAT BOMBER',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFffd34d),
                      letterSpacing: 3,
                      shadows: [Shadow(color: Colors.black, offset: Offset(0, 3))],
                    ),
                  ),
                  const Text(
                    'Paw Rescue',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 28),
                  PixelButton(
                    label: 'PLAY',
                    icon: Icons.play_arrow,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ModeSelectScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PixelButton(
                    label: 'SETTINGS',
                    icon: Icons.settings,
                    color: const Color(0xFF6fa8ff),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
