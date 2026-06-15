import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system) {
    _loadSavedTheme();
  }

  static const String _themeModeKey = 'gearhub_theme_mode';

  ///set theme mode dựa trên lựa chọn của người dùng
  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    await _persist(mode);
  }

  Future<void> useSystemTheme() => setThemeMode(ThemeMode.system);
  Future<void> useLightTheme() => setThemeMode(ThemeMode.light);
  Future<void> useDarkTheme() => setThemeMode(ThemeMode.dark);

  ///helper
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeModeKey);
      emit(_parseThemeMode(saved));
    } catch (_) {
      emit(ThemeMode.system);
    }
  }

  Future<void> _persist(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _themeModeToString(mode));
    } catch (_) {}
  }

  static ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
