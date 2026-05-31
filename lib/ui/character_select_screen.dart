import 'package:flutter/material.dart';

import '../game/cat_bomber_game.dart';
import '../game/levels/level_registry.dart';
import '../services/save_service.dart';
import 'game_screen.dart';
import 'widgets/pixel_button.dart';

/// Shown before an offline match: pick which cat the single player controls.
/// The other cat becomes the AI companion.
class CharacterSelectScreen extends StatefulWidget {
  final int levelIndex;
  const CharacterSelectScreen({super.key, required this.levelIndex});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  late String _selected = SaveService.instance.lastCharacter;

  void _start() {
    SaveService.instance.lastCharacter = _selected;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: GameMode.offline,
          levelIndex: widget.levelIndex,
          playerCharacter: _selected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stage = LevelRegistry.byIndex(widget.levelIndex);
    return Scaffold(
      appBar: AppBar(title: Text('Stage ${stage.index}: ${stage.name}')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose your cat',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const Text(
              'The other cat is controlled by the AI companion.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _catCard(
                  charId: 'male_cat',
                  name: 'Male Cat',
                  frame:
                      'assets/game/characters/male_cat/frames/idle_front.png',
                ),
                const SizedBox(width: 24),
                _catCard(
                  charId: 'female_cat',
                  name: 'Female Cat',
                  frame:
                      'assets/game/characters/female_cat/frames/idle_front.png',
                ),
              ],
            ),
            const SizedBox(height: 28),
            PixelButton(label: 'START', icon: Icons.play_arrow, onTap: _start),
          ],
        ),
      ),
    );
  }

  Widget _catCard({
    required String charId,
    required String name,
    required String frame,
  }) {
    final selected = _selected == charId;
    return GestureDetector(
      onTap: () => setState(() => _selected = charId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3c2a73) : const Color(0xFF221842),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFffd34d) : Colors.black,
            width: 4,
          ),
          boxShadow: const [BoxShadow(color: Colors.black54, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            Image.asset(frame, width: 96, filterQuality: FilterQuality.none),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: selected ? const Color(0xFFffd34d) : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (selected)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.check_circle, color: Color(0xFFffd34d), size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
