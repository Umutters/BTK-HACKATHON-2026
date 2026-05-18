import 'package:flutter/foundation.dart';

import '../data/datasources/local_datasource.dart';

class AiPreferencesViewModel extends ChangeNotifier {
  final LocalDataSource _dataSource;

  // AI preferences
  String _responseLength = 'moderate'; // short, moderate, detailed
  bool _useImages = true;
  bool _useTables = true;
  int _confidenceThreshold = 7; // 1-10 scale
  String _language = 'tr'; // tr, en

  String get responseLength => _responseLength;
  bool get useImages => _useImages;
  bool get useTables => _useTables;
  int get confidenceThreshold => _confidenceThreshold;
  String get language => _language;

  AiPreferencesViewModel({LocalDataSource? dataSource})
    : _dataSource = dataSource ?? LocalDataSource() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _dataSource.getAiPreferences();
    _responseLength = prefs['responseLength'] as String? ?? 'moderate';
    _useImages = prefs['useImages'] as bool? ?? true;
    _useTables = prefs['useTables'] as bool? ?? true;
    _confidenceThreshold = prefs['confidenceThreshold'] as int? ?? 7;
    _language = prefs['language'] as String? ?? 'tr';
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    await _dataSource.saveAiPreferences({
      'responseLength': _responseLength,
      'useImages': _useImages,
      'useTables': _useTables,
      'confidenceThreshold': _confidenceThreshold,
      'language': _language,
    });
  }

  Future<void> setResponseLength(String value) async {
    _responseLength = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> toggleUseImages(bool value) async {
    _useImages = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> toggleUseTables(bool value) async {
    _useTables = value;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> setConfidenceThreshold(int value) async {
    _confidenceThreshold = value.clamp(1, 10);
    notifyListeners();
    await _savePreferences();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    notifyListeners();
    await _savePreferences();
  }
}
