/// Supabase `recurring_transactions` tablosuna karşılık gelir.
class RecurringTransactionModel {
  final String id;
  final String userId;
  final String type; // 'income' veya 'expense'
  final String category;
  final double amount;

  const RecurringTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
  });

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionModel(
      id: json['Id'] as String? ?? json['id'] as String? ?? '',
      userId: json['User_id'] as String? ?? '',
      type: json['Type'] as String? ?? '',
      category: json['Category'] as String? ?? '',
      amount: (json['Amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get isIncome => type.toLowerCase() == 'income';
  bool get isExpense => type.toLowerCase() == 'expense';
  bool get isSaving => type.toLowerCase() == 'saving';
}
