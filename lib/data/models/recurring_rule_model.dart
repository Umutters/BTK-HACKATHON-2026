/// `recurring_rules` Supabase tablosuna karşılık gelir.
/// Kullanıcının tanımladığı sabit gelir/gider kurallarını (maaş, kira,
/// abonelik vb.) temsil eder. Tek seferlik harcama logu olan
/// `recurring_transactions` tablosundan bağımsızdır.
class RecurringRuleModel {
  final String id;
  final String userId;

  /// 'income' veya 'expense'
  final String type;
  final String category;
  final double amount;

  /// 'daily' | 'weekly' | 'monthly' | 'yearly'
  final String frequency;

  /// Aylık/Yıllık kurallar için (1-31). Haftalık için null.
  final int? dayOfMonth;

  /// Haftalık kurallar için (1=Pazartesi … 7=Pazar). Aylık için null.
  final int? dayOfWeek;

  final String? description;
  final DateTime startDate;

  /// Son uygulama tarihi. Aynı gün iki kez uygulanmayı önler.
  final DateTime? lastAppliedDate;

  final bool isActive;

  const RecurringRuleModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    required this.frequency,
    this.dayOfMonth,
    this.dayOfWeek,
    this.description,
    required this.startDate,
    this.lastAppliedDate,
    this.isActive = true,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory RecurringRuleModel.fromJson(Map<String, dynamic> json) {
    return RecurringRuleModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: json['type'] as String? ?? 'expense',
      category: json['category'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      frequency: json['frequency'] as String? ?? 'monthly',
      dayOfMonth: json['day_of_month'] as int?,
      dayOfWeek: json['day_of_week'] as int?,
      description: json['description'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastAppliedDate: json['last_applied_date'] != null
          ? DateTime.tryParse(json['last_applied_date'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'type': type,
    'category': category,
    'amount': amount,
    'frequency': frequency,
    'day_of_month': dayOfMonth,
    'day_of_week': dayOfWeek,
    'description': description,
    'start_date': startDate.toIso8601String().substring(0, 10),
    'last_applied_date': lastAppliedDate?.toIso8601String().substring(0, 10),
    'is_active': isActive,
  };

  RecurringRuleModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? category,
    double? amount,
    String? frequency,
    Object? dayOfMonth = _sentinel,
    Object? dayOfWeek = _sentinel,
    Object? description = _sentinel,
    DateTime? startDate,
    Object? lastAppliedDate = _sentinel,
    bool? isActive,
  }) {
    return RecurringRuleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      dayOfMonth: identical(dayOfMonth, _sentinel)
          ? this.dayOfMonth
          : dayOfMonth as int?,
      dayOfWeek: identical(dayOfWeek, _sentinel)
          ? this.dayOfWeek
          : dayOfWeek as int?,
      description: identical(description, _sentinel)
          ? this.description
          : description as String?,
      startDate: startDate ?? this.startDate,
      lastAppliedDate: identical(lastAppliedDate, _sentinel)
          ? this.lastAppliedDate
          : lastAppliedDate as DateTime?,
      isActive: isActive ?? this.isActive,
    );
  }

  /// İzin verilen frekans değerleri.
  static const List<String> frequencies = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  static const String _sentinel = '__sentinel__';

  /// Bu kuralın [date] tarihinde uygulanması gerekip gerekmediğini döndürür.
  bool isDueOn(DateTime date) {
    if (!isActive) return false;

    final today = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    if (today.isBefore(start)) return false;

    // Bugün zaten uygulandıysa tekrar uygulama
    if (lastAppliedDate != null) {
      final last = DateTime(
        lastAppliedDate!.year,
        lastAppliedDate!.month,
        lastAppliedDate!.day,
      );
      if (!last.isBefore(today)) return false; // last >= today → zaten yapıldı
    }

    // Son uygulama tarihinden (veya başlangıç tarihinden) bu yana
    // kural tetiklenecek bir tarih geçti mi?
    final since = lastAppliedDate != null
        ? DateTime(
            lastAppliedDate!.year,
            lastAppliedDate!.month,
            lastAppliedDate!.day,
          )
        : start.subtract(const Duration(days: 1));

    switch (frequency) {
      case 'daily':
        // Her gün — since'den sonra en az 1 gün geçti mi?
        return today.isAfter(since);

      case 'weekly':
        final targetWeekday = dayOfWeek ?? startDate.weekday;
        // since ile today arasında hedef haftanın günü geçti mi?
        for (
          var d = since.add(const Duration(days: 1));
          !d.isAfter(today);
          d = d.add(const Duration(days: 1))
        ) {
          if (d.weekday == targetWeekday) return true;
        }
        return false;

      case 'monthly':
        final targetDay = dayOfMonth ?? startDate.day;
        // since ile today arasında herhangi bir ayın targetDay'i geçti mi?
        for (
          var d = since.add(const Duration(days: 1));
          !d.isAfter(today);
          d = d.add(const Duration(days: 1))
        ) {
          if (d.day == targetDay) return true;
        }
        return false;

      case 'yearly':
        final targetDay = dayOfMonth ?? startDate.day;
        final targetMonth = startDate.month;
        for (
          var d = since.add(const Duration(days: 1));
          !d.isAfter(today);
          d = d.add(const Duration(days: 1))
        ) {
          if (d.day == targetDay && d.month == targetMonth) return true;
        }
        return false;

      default:
        return false;
    }
  }
}
