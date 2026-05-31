import 'package:flutter/material.dart';

import 'ui/main_menu_screen.dart';

/// Root app. Pixel-art game, so no Material chrome — just a dark canvas the
/// Flame game and overlay screens draw on top of.
class CatBomberApp extends StatelessWidget {
  const CatBomberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cat Bomber: Paw Rescue',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'monospace',
        scaffoldBackgroundColor: const Color(0xFF1a1430),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFff8a3d),
          brightness: Brightness.dark,
        ),
      ),
      home: const MainMenuScreen(),
    );
  }
}
