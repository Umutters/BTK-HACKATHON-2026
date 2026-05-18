import 'package:flutter/foundation.dart';

import '../data/datasources/local_datasource.dart';

class DataManagementViewModel extends ChangeNotifier {
  final LocalDataSource _dataSource;

  // Data management
  bool _autoBackup = true;
  int _autoBackupFrequency = 7; // days
  DateTime? _lastBackupDate;
  int _localDataSizeKb = 0; // Placeholder
  bool _isLoading = false;

  bool get autoBackup => _autoBackup;
  int get autoBackupFrequency => _autoBackupFrequency;
  DateTime? get lastBackupDate => _lastBackupDate;
  int get localDataSizeKb => _localDataSizeKb;
  bool get isLoading => _isLoading;

  DataManagementViewModel({LocalDataSource? dataSource})
    : _dataSource = dataSource ?? LocalDataSource() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _dataSource.getDataManagementSettings();
    _autoBackup = settings['autoBackup'] as bool? ?? true;
    _autoBackupFrequency = settings['autoBackupFrequency'] as int? ?? 7;
    final lastBackupStr = settings['lastBackupDate'] as String?;
    if (lastBackupStr != null) {
      _lastBackupDate = DateTime.tryParse(lastBackupStr);
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    await _dataSource.saveDataManagementSettings({
      'autoBackup': _autoBackup,
      'autoBackupFrequency': _autoBackupFrequency,
      'lastBackupDate': _lastBackupDate?.toIso8601String(),
    });
  }

  Future<void> toggleAutoBackup(bool value) async {
    _autoBackup = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> setAutoBackupFrequency(int days) async {
    _autoBackupFrequency = days.clamp(1, 30);
    notifyListeners();
    await _saveSettings();
  }

  Future<void> clearLocalData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Tüm ayar verilerini resetle
      await _dataSource.clearAll();

      // Local storage'ı yeniden başlat
      _autoBackup = true;
      _autoBackupFrequency = 7;
      _lastBackupDate = null;
      _localDataSizeKb = 0;

      await _loadSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createBackup() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Backup oluştur (şu anda mock)
      _lastBackupDate = DateTime.now();
      await _saveSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreBackup() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Backup'tan geri yükle (şu anda mock)
      await _loadSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDataInfo() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Veri boyutunu hesapla (şu anda mock)
      _localDataSizeKb = 1024; // ~1 MB
      await _loadSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
