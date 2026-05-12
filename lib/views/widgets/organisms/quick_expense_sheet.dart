import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/datasources/local_datasource.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/recurring_transaction_model.dart';

class QuickExpenseSheet extends StatefulWidget {
  const QuickExpenseSheet({super.key});

  @override
  State<QuickExpenseSheet> createState() => _QuickExpenseSheetState();
}

class _QuickExpenseSheetState extends State<QuickExpenseSheet> {
  static const _categories = [
    _CategoryData('Kahve', Icons.local_cafe_rounded),
    _CategoryData('Yemek', Icons.fastfood_rounded),
    _CategoryData('Ulaşım', Icons.directions_car_rounded),
    _CategoryData('Eğlence', Icons.sports_esports_rounded),
  ];

  String _amountDigits = '0';
  int _selectedCategoryIndex = 0;
  ProfileModel? _profile;
  bool _isSaving = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await LocalDataSource().getProfile();
    if (!mounted) return;
    setState(() => _profile = profile);
  }

  double get _amount => double.tryParse(_amountDigits) ?? 0.0;

  String get _formattedAmount {
    final value = _amount.round();
    return value == 0 ? '0' : value.toString();
  }

  String get _simulationPreview {
    if (_amount <= 0) {
      return 'Tutar girince 2045 hedefine etkisini anında göstereceğiz.';
    }

    final dailyLimit = (_profile?.dailyLimit ?? 0).clamp(0.0, double.infinity);
    final divisor = dailyLimit > 0 ? max(dailyLimit * 0.35, 1.0) : 250.0;
    final days = max(1, (_amount / divisor).ceil());
    return 'Bu harcama 2045 hedefini $days gün geciktirecek.';
  }

  void _addDigit(String digit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_amountDigits == '0') {
        _amountDigits = digit;
      } else {
        _amountDigits += digit;
      }
    });
  }

  void _backspace() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_amountDigits.length <= 1) {
        _amountDigits = '0';
      } else {
        _amountDigits = _amountDigits.substring(0, _amountDigits.length - 1);
      }
    });
  }

  void _clear() {
    HapticFeedback.selectionClick();
    setState(() => _amountDigits = '0');
  }

  Future<void> _scanReceipt() async {
    HapticFeedback.mediumImpact();
    setState(() => _isScanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _amountDigits = '459';
      _selectedCategoryIndex = 0;
      _isScanning = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gemini Scan demo: 459 TL / Kahve algılandı'),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (_amount <= 0 || _isSaving) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final profile = _profile;
      final txn = RecurringTransactionModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        userId: profile?.id ?? 'local',
        type: 'expense',
        category: _categories[_selectedCategoryIndex].label,
        amount: _amount,
      );

      final dataSource = LocalDataSource();
      await dataSource.addRecurringTransaction(txn);
      await dataSource.logDailySpending(
        spentAmount: _amount,
        transferredToSavings: 0,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_categories[_selectedCategoryIndex].label} kaydedildi: $_formattedAmount TL',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppDimensions.blurCard,
            sigmaY: AppDimensions.blurCard,
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.88),
              border: Border(
                top: BorderSide(
                  color: AppColors.neonLime.withValues(alpha: 0.22),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pagePaddingH,
                  AppDimensions.spaceS,
                  AppDimensions.pagePaddingH,
                  AppDimensions.spaceXL,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.glass15,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceL),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.neonLime10,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.neonLime20,
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.payments_rounded,
                            color: AppColors.neonLime,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceL),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hızlı Harcama Girişi',
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kendi hızında gir, Gemini ile tara, simülasyonu anında gör.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceXL),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spaceL,
                        vertical: AppDimensions.spaceXL,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.glass08,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusXL,
                        ),
                        border: Border.all(color: AppColors.glass12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'TL',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.neonLime,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceS),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formattedAmount,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 58,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spaceS),
                          Text(
                            _simulationPreview,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.cyberBlueDim,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXL),
                    Text(
                      'Kategori seç',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    Wrap(
                      spacing: AppDimensions.spaceS,
                      runSpacing: AppDimensions.spaceS,
                      children: List.generate(_categories.length, (index) {
                        final item = _categories[index];
                        final selected = index == _selectedCategoryIndex;
                        return ChoiceChip(
                          selected: selected,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategoryIndex = index);
                          },
                          label: Text(item.label),
                          avatar: Icon(
                            item.icon,
                            size: 18,
                            color: selected ? Colors.black : AppColors.neonLime,
                          ),
                          selectedColor: AppColors.neonLime,
                          backgroundColor: AppColors.glass08,
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.black
                                : AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: const BorderSide(color: AppColors.glass12),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppDimensions.spaceXL),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceL),
                      decoration: BoxDecoration(
                        color: AppColors.glass08,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusXL,
                        ),
                        border: Border.all(color: AppColors.glass12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isScanning ? null : _scanReceipt,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.neonLime,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: _isScanning
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.black,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.document_scanner_rounded,
                                        ),
                                  label: Text(
                                    _isScanning
                                        ? 'Taranıyor...'
                                        : 'Gemini Scan',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spaceL),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 12,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.5,
                                ),
                            itemBuilder: (context, index) {
                              const values = [
                                '1',
                                '2',
                                '3',
                                '4',
                                '5',
                                '6',
                                '7',
                                '8',
                                '9',
                                'C',
                                '0',
                                '⌫',
                              ];
                              final value = values[index];
                              return _KeypadButton(
                                label: value,
                                onTap: () {
                                  if (value == 'C') {
                                    _clear();
                                  } else if (value == '⌫') {
                                    _backspace();
                                  } else {
                                    _addDigit(value);
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXL),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveExpense,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonLime,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Harcamayı Kaydet',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    Text(
                      'Kaydedilen harcama, günlük log ve AI analizine eklenir.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryData {
  final String label;
  final IconData icon;

  const _CategoryData(this.label, this.icon);
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _KeypadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAction = label == 'C' || label == '⌫';
    return Material(
      color: isAction ? AppColors.surfaceContainerLow : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isAction ? AppColors.neonLime : AppColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
