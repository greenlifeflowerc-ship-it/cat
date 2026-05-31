import 'package:flutter/material.dart';

import '../services/save_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final save = SaveService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Sound effects'),
                value: save.soundEnabled,
                onChanged: (v) => setState(() => save.soundEnabled = v),
              ),
              SwitchListTile(
                title: const Text('Music'),
                value: save.musicEnabled,
                onChanged: (v) => setState(() => save.musicEnabled = v),
              ),
              const SizedBox(height: 20),
              const Text(
                'Controls: Arrow keys / WASD to move,\nSpace to drop a bomb, E to remote-detonate.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
