import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Keys
  static const _kBaseUrl = 'mattergram_base_url';
  static const _kToken = 'mattergram_token';
  static const _kThemeId = 'mattergram_theme_id';
  static const _kIsDarkMode = 'mattergram_is_dark_mode';
  static const _kAnimationId = 'mattergram_animation_id';
  static const _kSoundEnabled = 'mattergram_sound_enabled';
  static const _kTimeFormat = 'mattergram_time_format';
  static const _kTimezone = 'mattergram_timezone';

  String? getBaseUrl() => _prefs?.getString(_kBaseUrl);
  Future<bool> setBaseUrl(String url) async =>
      await _prefs?.setString(_kBaseUrl, url) ?? false;

  String? getToken() => _prefs?.getString(_kToken);
  Future<bool> setToken(String? token) async {
    if (token == null) {
      return await _prefs?.remove(_kToken) ?? false;
    }
    return await _prefs?.setString(_kToken, token) ?? false;
  }

  String getThemeId() => _prefs?.getString(_kThemeId) ?? 'classic-dark';
  Future<bool> setThemeId(String themeId) async =>
      await _prefs?.setString(_kThemeId, themeId) ?? false;

  bool? getIsDarkMode() => _prefs?.getBool(_kIsDarkMode);
  Future<bool> setIsDarkMode(bool isDark) async =>
      await _prefs?.setBool(_kIsDarkMode, isDark) ?? false;

  String getAnimationId() => _prefs?.getString(_kAnimationId) ?? 'smooth';
  Future<bool> setAnimationId(String animId) async =>
      await _prefs?.setString(_kAnimationId, animId) ?? false;

  bool getSoundEnabled() => _prefs?.getBool(_kSoundEnabled) ?? true;
  Future<bool> setSoundEnabled(bool enabled) async =>
      await _prefs?.setBool(_kSoundEnabled, enabled) ?? false;

  String getTimeFormat() => _prefs?.getString(_kTimeFormat) ?? '24h';
  Future<bool> setTimeFormat(String format) async =>
      await _prefs?.setString(_kTimeFormat, format) ?? false;

  String? getTimezone() => _prefs?.getString(_kTimezone);
  Future<bool> setTimezone(String? tz) async {
    if (tz == null) return await _prefs?.remove(_kTimezone) ?? false;
    return await _prefs?.setString(_kTimezone, tz) ?? false;
  }

  Future<void> clearAuth() async {
    await _prefs?.remove(_kToken);
  }
}
