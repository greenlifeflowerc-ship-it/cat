import 'package:shared_preferences/shared_preferences.dart';

/// Persists progression and settings via shared_preferences (section 28).
class SaveService {
  SaveService._();
  static final SaveService instance = SaveService._();

  SharedPreferences? _prefs;

  static const _kUnlocked = 'unlocked_level';
  static const _kStarsPrefix = 'stars_level_';
  static const _kBestPrefix = 'best_seconds_level_';
  static const _kSound = 'sound_enabled';
  static const _kMusic = 'music_enabled';
  static const _kCharacter = 'last_character';
  static const _kPlayerName = 'last_player_name';

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
  }

  int get unlockedLevel => _prefs?.getInt(_kUnlocked) ?? 1;

  bool isUnlocked(int level) => level <= unlockedLevel;

  Future<void> unlock(int level) async {
    if (level > unlockedLevel) {
      await _prefs?.setInt(_kUnlocked, level.clamp(1, 10));
    }
  }

  int starsFor(int level) => _prefs?.getInt('$_kStarsPrefix$level') ?? 0;

  Future<void> recordResult(int level, int stars, int seconds) async {
    if (stars > starsFor(level)) {
      await _prefs?.setInt('$_kStarsPrefix$level', stars);
    }
    final prevBest = _prefs?.getInt('$_kBestPrefix$level') ?? 1 << 30;
    if (seconds < prevBest) {
      await _prefs?.setInt('$_kBestPrefix$level', seconds);
    }
    await unlock(level + 1);
  }

  int? bestSeconds(int level) {
    final v = _prefs?.getInt('$_kBestPrefix$level');
    return (v == null || v >= 1 << 30) ? null : v;
  }

  bool get soundEnabled => _prefs?.getBool(_kSound) ?? true;
  set soundEnabled(bool v) => _prefs?.setBool(_kSound, v);

  bool get musicEnabled => _prefs?.getBool(_kMusic) ?? true;
  set musicEnabled(bool v) => _prefs?.setBool(_kMusic, v);

  String get lastCharacter => _prefs?.getString(_kCharacter) ?? 'male_cat';
  set lastCharacter(String v) => _prefs?.setString(_kCharacter, v);

  String get lastPlayerName => _prefs?.getString(_kPlayerName) ?? 'Player';
  set lastPlayerName(String v) => _prefs?.setString(_kPlayerName, v);
}
