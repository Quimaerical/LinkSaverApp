import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';

class ThemeController extends ChangeNotifier {
  final SharedPreferences prefs;
  AppThemeMode _currentMode;

  ThemeController(this.prefs)
      : _currentMode = _loadSavedMode(prefs);

  static const String _prefKey = 'app_theme_mode';

  AppThemeMode get currentMode => _currentMode;

  static AppThemeMode _loadSavedMode(SharedPreferences prefs) {
    final saved = prefs.getString(_prefKey);
    if (saved == 'light') return AppThemeMode.light;
    if (saved == 'oled') return AppThemeMode.oled;
    return AppThemeMode.dark;
  }

  ThemeData get themeData {
    switch (_currentMode) {
      case AppThemeMode.light:
        return AppTheme.lightTheme;
      case AppThemeMode.dark:
        return AppTheme.darkTheme;
      case AppThemeMode.oled:
        return AppTheme.oledTheme;
    }
  }

  void setThemeMode(AppThemeMode mode) {
    if (_currentMode == mode) return;
    _currentMode = mode;
    prefs.setString(_prefKey, mode.name);
    notifyListeners();
  }
}
