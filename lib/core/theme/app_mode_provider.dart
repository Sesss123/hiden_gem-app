import 'package:flutter/material.dart';
import '../../data/datasources/user_preference_service.dart';

class AppModeProvider extends ChangeNotifier {
  ThemeMode _currentMode = ThemeMode.system;

  ThemeMode get currentMode => _currentMode;

  AppModeProvider() {
    _loadSaved();
  }

  void _loadSaved() {
    final profile = UserPreferenceService.getProfile();
    _currentMode = _parseMode(profile.themeMode);
  }

  ThemeMode _parseMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _currentMode = mode;
    notifyListeners();
    
    // Save to Hive
    final stringMode = _modeToString(mode);
    await UserPreferenceService.updateThemeMode(stringMode);
  }
}
