import 'package:shared_preferences/shared_preferences.dart';

/// Wraps [SharedPreferences] for all progress/settings persistence.
///
/// Every read is defensive: a corrupt or missing value falls back to a
/// sane default instead of throwing, so a damaged preferences store can
/// never crash the app (per the robustness requirement).
class StorageService {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;

  static const int totalLevels = 30;

  static const _kUnlockedCount = 'unlocked_count';
  static const _kSound = 'settings_sound';
  static const _kMusic = 'settings_music';
  static const _kVibration = 'settings_vibration';
  static const _kControlScheme = 'settings_control_scheme';

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  int _safeInt(String key, int fallback) {
    try {
      return _prefs.getInt(key) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  bool _safeBool(String key, bool fallback) {
    try {
      return _prefs.getBool(key) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  // --- Level progress -------------------------------------------------

  int get unlockedCount {
    final value = _safeInt(_kUnlockedCount, 1);
    return value.clamp(1, totalLevels);
  }

  bool isLevelUnlocked(int levelId) => levelId <= unlockedCount;

  bool isLevelCompleted(int levelId) => starsFor(levelId) > 0;

  int starsFor(int levelId) => _safeInt('stars_$levelId', 0).clamp(0, 3);

  int? bestMovesFor(int levelId) {
    final v = _safeInt('best_moves_$levelId', -1);
    return v < 0 ? null : v;
  }

  int? bestTimeFor(int levelId) {
    final v = _safeInt('best_time_$levelId', -1);
    return v < 0 ? null : v;
  }

  /// Records the outcome of a completed level, keeping the best stars/time
  /// /moves seen so far and unlocking the next level.
  Future<void> recordLevelResult({
    required int levelId,
    required int stars,
    required int timeSeconds,
    required int moves,
  }) async {
    final prevStars = starsFor(levelId);
    if (stars > prevStars) {
      await _prefs.setInt('stars_$levelId', stars.clamp(0, 3));
    }
    final prevTime = bestTimeFor(levelId);
    if (prevTime == null || timeSeconds < prevTime) {
      await _prefs.setInt('best_time_$levelId', timeSeconds);
    }
    final prevMoves = bestMovesFor(levelId);
    if (prevMoves == null || moves < prevMoves) {
      await _prefs.setInt('best_moves_$levelId', moves);
    }
    if (levelId >= unlockedCount && levelId < totalLevels) {
      await _prefs.setInt(_kUnlockedCount, levelId + 1);
    }
  }

  // --- Settings ---------------------------------------------------------

  bool get soundEnabled => _safeBool(_kSound, true);
  Future<void> setSoundEnabled(bool value) => _prefs.setBool(_kSound, value);

  bool get musicEnabled => _safeBool(_kMusic, true);
  Future<void> setMusicEnabled(bool value) => _prefs.setBool(_kMusic, value);

  bool get vibrationEnabled => _safeBool(_kVibration, true);
  Future<void> setVibrationEnabled(bool value) =>
      _prefs.setBool(_kVibration, value);

  /// 'swipe' or 'dpad'.
  String get controlScheme {
    try {
      return _prefs.getString(_kControlScheme) ?? 'swipe';
    } catch (_) {
      return 'swipe';
    }
  }

  Future<void> setControlScheme(String scheme) =>
      _prefs.setString(_kControlScheme, scheme);

  Future<void> resetProgress() async {
    final keys = _prefs.getKeys().where(
          (k) =>
              k.startsWith('stars_') ||
              k.startsWith('best_time_') ||
              k.startsWith('best_moves_') ||
              k == _kUnlockedCount,
        );
    for (final key in keys.toList()) {
      await _prefs.remove(key);
    }
  }
}
