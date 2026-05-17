import 'package:flutter/foundation.dart';

import '../data/datasources/local_datasource.dart';
import '../data/models/profile_model.dart';
import '../data/services/supabase_service.dart';

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

  /// Onboarding verilerini hem SharedPreferences'a hem Supabase'e kaydeder.
  Future<void> saveToLocal() async {
    final supabase = SupabaseService.instance;
    final userId = supabase.currentUserId ?? 'local';

    final profile = ProfileModel(
      id: userId,
      userName: _userName,
      age: _age,
      gender: '',
      initialBalance: _budgetAmount,
      currentBalance: _budgetAmount,
      savingsPool: 0,
      level: 1,
      xp: 0,
      dailyLimit: _budgetAmount / 30,
    );

    // Her zaman locale kaydet (offline fallback)
    final local = LocalDataSource();
    await local.saveProfile(profile);
    await local.saveSelectedGoal(goalId: _goalId ?? '', goalName: _goalName);
    await local.savePreferredCurrency(currencyLabel);
    await local.setOnboardingDone(true);

    // Supabase'e insert et (signed-in kullanıcı varsa)
    if (userId != 'local') {
      try {
        await supabase.insertProfile(profile);
      } catch (e) {
        // Supabase hatası varsa local kayıt yeterli
        debugPrint('Supabase insertProfile hatası: $e');
      }
    }
  }
}
