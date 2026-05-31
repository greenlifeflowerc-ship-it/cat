import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'save_service.dart';

/// Thin wrapper around flame_audio. Every gameplay sound has a named hook
/// (section 27). Audio files are optional — if a clip is missing the play call
/// is swallowed so gameplay never breaks.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  /// Logical sound name -> asset filename under assets/audio/.
  /// Files are not shipped by default; drop matching .wav/.mp3 files in
  /// assets/audio/ and register the folder in pubspec to enable them.
  static const Map<String, String> sfx = {
    'button_click': 'button_click.wav',
    'bomb_place': 'bomb_place.wav',
    'bomb_tick': 'bomb_tick.wav',
    'explosion': 'explosion.wav',
    'block_break': 'block_break.wav',
    'powerup_pickup': 'powerup_pickup.wav',
    'cat_hurt': 'cat_hurt.wav',
    'enemy_defeated': 'enemy_defeated.wav',
    'level_win': 'level_win.wav',
    'level_lose': 'level_lose.wav',
    'online_join': 'online_join.wav',
    'connection_lost': 'connection_lost.wav',
  };

  bool _ready = false;

  Future<void> init() async {
    // Pre-caching is best-effort: missing files simply leave audio silent.
    _ready = true;
  }

  void play(String name) {
    if (!_ready || !SaveService.instance.soundEnabled) return;
    final file = sfx[name];
    if (file == null) return;
    try {
      FlameAudio.play('audio/$file');
    } catch (e) {
      // Placeholder assets are allowed to be absent.
      debugPrint('audio: skipped "$name" ($e)');
    }
  }
}
