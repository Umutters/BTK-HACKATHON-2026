import 'package:flutter/foundation.dart';

import '../data/datasources/local_datasource.dart';

class ThemeSettingsViewModel extends ChangeNotifier {
  final LocalDataSource _dataSource;

  // Theme settings
  bool _darkMode = true;
  bool _neonEffects = true;
  bool _glassEffect = true;
  int _brightnessLevel = 5; // 1-10 scale

  bool get darkMode => _darkMode;
  bool get neonEffects => _neonEffects;
  bool get glassEffect => _glassEffect;
  int get brightnessLevel => _brightnessLevel;

  ThemeSettingsViewModel({LocalDataSource? dataSource})
    : _dataSource = dataSource ?? LocalDataSource() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _dataSource.getThemeSettings();
    _darkMode = settings['darkMode'] as bool? ?? true;
    _neonEffects = settings['neonEffects'] as bool? ?? true;
    _glassEffect = settings['glassEffect'] as bool? ?? true;
    _brightnessLevel = settings['brightnessLevel'] as int? ?? 5;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    await _dataSource.saveThemeSettings({
      'darkMode': _darkMode,
      'neonEffects': _neonEffects,
      'glassEffect': _glassEffect,
      'brightnessLevel': _brightnessLevel,
    });
  }

  Future<void> toggleDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleNeonEffects(bool value) async {
    _neonEffects = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleGlassEffect(bool value) async {
    _glassEffect = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setBrightnessLevel(int value) async {
    _brightnessLevel = value.clamp(1, 10);
    notifyListeners();
    await _saveSettings();
  }
}
