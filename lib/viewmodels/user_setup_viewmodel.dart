import 'package:flutter/foundation.dart';

/// Para birimi seçenekleri — BudgetSetupScreen'den buraya taşındı.
enum SetupCurrency { usd, try_ }

/// Onboarding setup akışındaki (UserSetup → Age → Budget → Goal) tüm
/// kullanıcı verilerini tek yerde tutar. main.dart'tan provide edilir,
/// böylece hiçbir veri constructor param olarak iletilmek zorunda kalmaz.
class UserSetupViewModel extends ChangeNotifier {
  // ── Adım 1: İsim ────────────────────────────────────────────────────────
  String _userName = '';
  String get userName => _userName;

  void setUserName(String value) {
    _userName = value.trim();
    notifyListeners();
  }

  // ── Adım 2: Yaş ─────────────────────────────────────────────────────────
  int _age = 28;
  int get age => _age;

  void setAge(int value) {
    _age = value;
    notifyListeners();
  }

  // ── Adım 3: Bütçe ───────────────────────────────────────────────────────
  SetupCurrency _currency = SetupCurrency.usd;
  SetupCurrency get currency => _currency;

  double _budgetAmount = 10000;
  double get budgetAmount => _budgetAmount;

  String get currencySymbol => _currency == SetupCurrency.usd ? '\$' : '₺';
  String get currencyLabel => _currency == SetupCurrency.usd ? 'USD' : 'TRY';

  void setCurrency(SetupCurrency value) {
    _currency = value;
    notifyListeners();
  }

  void setBudgetAmount(double value) {
    _budgetAmount = value;
    notifyListeners();
  }

  // ── Adım 4: Hedef ───────────────────────────────────────────────────────
  String? _goalId;
  String? get goalId => _goalId;

  String _goalName = '';
  String get goalName => _goalName;

  String _goalCyberName = '';
  String get goalCyberName => _goalCyberName;

  void setGoal({
    required String id,
    required String name,
    required String cyberName,
  }) {
    _goalId = id;
    _goalName = name;
    _goalCyberName = cyberName;
    notifyListeners();
  }

  // ── Yardımcılar ─────────────────────────────────────────────────────────

  /// Akış tamamlanmış mı? (tüm zorunlu alanlar dolu)
  bool get isComplete => _userName.isNotEmpty && _goalId != null;

  /// Onboarding bittikten sonra sıfırla.
  void reset() {
    _userName = '';
    _age = 28;
    _currency = SetupCurrency.usd;
    _budgetAmount = 10000;
    _goalId = null;
    _goalName = '';
    _goalCyberName = '';
    notifyListeners();
  }
}
