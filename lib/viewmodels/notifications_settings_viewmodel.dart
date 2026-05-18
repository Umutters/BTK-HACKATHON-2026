import 'package:flutter/foundation.dart';

import '../data/datasources/local_datasource.dart';

class NotificationsSettingsViewModel extends ChangeNotifier {
  final LocalDataSource _dataSource;

  // Notification settings
  bool _expenseNotifications = true;
  bool _questNotifications = true;
  bool _aiSuggestionsNotifications = true;
  bool _crisisAlerts = true;

  bool get expenseNotifications => _expenseNotifications;
  bool get questNotifications => _questNotifications;
  bool get aiSuggestionsNotifications => _aiSuggestionsNotifications;
  bool get crisisAlerts => _crisisAlerts;

  NotificationsSettingsViewModel({LocalDataSource? dataSource})
    : _dataSource = dataSource ?? LocalDataSource() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _dataSource.getNotificationsSettings();
    _expenseNotifications = settings['expenseNotifications'] ?? true;
    _questNotifications = settings['questNotifications'] ?? true;
    _aiSuggestionsNotifications =
        settings['aiSuggestionsNotifications'] ?? true;
    _crisisAlerts = settings['crisisAlerts'] ?? true;
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    await _dataSource.saveNotificationsSettings({
      'expenseNotifications': _expenseNotifications,
      'questNotifications': _questNotifications,
      'aiSuggestionsNotifications': _aiSuggestionsNotifications,
      'crisisAlerts': _crisisAlerts,
    });
  }

  Future<void> toggleExpenseNotifications(bool value) async {
    _expenseNotifications = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleQuestNotifications(bool value) async {
    _questNotifications = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleAiSuggestionsNotifications(bool value) async {
    _aiSuggestionsNotifications = value;
    notifyListeners();
    await _saveSettings();
  }

  Future<void> toggleCrisisAlerts(bool value) async {
    _crisisAlerts = value;
    notifyListeners();
    await _saveSettings();
  }
}
