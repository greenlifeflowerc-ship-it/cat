import 'package:flutter/material.dart';

import '../game/levels/level_registry.dart';
import '../services/save_service.dart';
import 'character_select_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  @override
  Widget build(BuildContext context) {
    final save = SaveService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Select Stage')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: LevelRegistry.stages.length,
          itemBuilder: (context, i) {
            final stage = LevelRegistry.stages[i];
            final unlocked = save.isUnlocked(stage.index);
            final stars = save.starsFor(stage.index);
            return GestureDetector(
              onTap: unlocked
                  ? () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CharacterSelectScreen(levelIndex: stage.index),
                        ),
                      );
                      if (mounted) setState(() {});
                    }
                  : null,
              child: Opacity(
                opacity: unlocked ? 1 : 0.4,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2b1d52),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Image.asset(
                          'assets/game/${stage.iconAsset}',
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stage.index}. ${stage.name}',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (s) => Icon(
                            s < stars ? Icons.star : Icons.star_border,
                            size: 12,
                            color: const Color(0xFFffd34d),
                          ),
                        ),
                      ),
                      if (!unlocked)
                        const Icon(Icons.lock, size: 14, color: Colors.white54),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
