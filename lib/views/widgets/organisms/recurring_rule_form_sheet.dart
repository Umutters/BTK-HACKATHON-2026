import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/recurring_rule_model.dart';
import '../../../data/services/supabase_service.dart';

class RecurringRuleFormSheet extends StatefulWidget {
  /// Null ise yeni kural eklenir; değer verilirse düzenleme modu açılır.
  final RecurringRuleModel? existing;

  const RecurringRuleFormSheet({super.key, this.existing});

  @override
  State<RecurringRuleFormSheet> createState() => _RecurringRuleFormSheetState();
}

class _RecurringRuleFormSheetState extends State<RecurringRuleFormSheet> {
  // ─── Kategori listeleri ───────────────────────────────────────────────────

  static const _incomeCategories = [
    _Cat('Maaş', Icons.account_balance_rounded),
    _Cat('Freelance', Icons.laptop_mac_rounded),
    _Cat('Kira Geliri', Icons.home_work_rounded),
    _Cat('Temettü', Icons.trending_up_rounded),
    _Cat('Prim', Icons.workspace_premium_rounded),
    _Cat('Burs', Icons.school_rounded),
  ];

  static const _expenseCategories = [
    _Cat('Kira', Icons.home_rounded),
    _Cat('Fatura', Icons.bolt_rounded),
    _Cat('Abonelik', Icons.subscriptions_rounded),
    _Cat('Ulaşım', Icons.directions_car_rounded),
    _Cat('Sigorta', Icons.shield_rounded),
    _Cat('Kredi', Icons.credit_card_rounded),
  ];

  // ─── Frekans ──────────────────────────────────────────────────────────────

  static const _freqLabels = {
    'daily': 'Günlük',
    'weekly': 'Haftalık',
    'monthly': 'Aylık',
    'yearly': 'Yıllık',
  };

  static const _weekDayLabels = [
    'Pzt',
    'Sal',
    'Çar',
    'Per',
    'Cum',
    'Cmt',
    'Paz',
  ];

  // ─── State ────────────────────────────────────────────────────────────────

  bool _isIncome = false;
  int _selectedCategoryIndex = 0;
  String _amountDigits = '0';
  String _frequency = 'monthly';
  int _dayOfMonth = 1; // 1-31
  int _dayOfWeek = 1; // 1=Pzt … 7=Paz
  bool _isSaving = false;

  List<_Cat> get _categories =>
      _isIncome ? _incomeCategories : _expenseCategories;

  double get _amount => double.tryParse(_amountDigits) ?? 0.0;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    if (r != null) {
      _isIncome = r.isIncome;
      _amountDigits = r.amount.toStringAsFixed(0);
      _frequency = r.frequency;
      _dayOfMonth = r.dayOfMonth ?? r.startDate.day;
      _dayOfWeek = r.dayOfWeek ?? r.startDate.weekday;
      // kategori index'ini bul
      final cats = r.isIncome ? _incomeCategories : _expenseCategories;
      final idx = cats.indexWhere((c) => c.label == r.category);
      _selectedCategoryIndex = idx >= 0 ? idx : 0;
    }
  }

  // ─── Numpad ───────────────────────────────────────────────────────────────

  void _addDigit(String d) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_amountDigits == '0') {
        _amountDigits = d;
      } else if (_amountDigits.length < 9) {
        _amountDigits += d;
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

  // ─── Kaydet ───────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_amount <= 0 || _isSaving) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final userId = SupabaseService.instance.currentUserId ?? 'local';
      final cats = _categories;
      final category = cats[_selectedCategoryIndex].label;

      final rule = RecurringRuleModel(
        id:
            widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        userId: userId,
        type: _isIncome ? 'income' : 'expense',
        category: category,
        amount: _amount,
        frequency: _frequency,
        dayOfMonth: (_frequency == 'monthly' || _frequency == 'yearly')
            ? _dayOfMonth
            : null,
        dayOfWeek: _frequency == 'weekly' ? _dayOfWeek : null,
        startDate: widget.existing?.startDate ?? DateTime.now(),
        lastAppliedDate: widget.existing?.lastAppliedDate,
        isActive: widget.existing?.isActive ?? true,
      );

      if (!mounted) return;
      Navigator.of(context).pop(rule);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(
                color: AppColors.cyberBlue.withValues(alpha: 0.22),
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
                  // ─── Handle ────────────────────────────────────────────────
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

                  // ─── Başlık ────────────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cyberBlue10,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.cyberBlue20,
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.repeat_rounded,
                          color: AppColors.cyberBlue,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceL),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.existing == null
                                  ? 'Düzenli İşlem Ekle'
                                  : 'İşlemi Düzenle',
                              style: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Maaş, kira, abonelik gibi tekrar eden kalemler.',
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

                  // ─── Tür seçici ────────────────────────────────────────────
                  _SectionLabel(label: 'TÜR'),
                  const SizedBox(height: AppDimensions.spaceS),
                  _TypeToggle(
                    isIncome: _isIncome,
                    onChanged: (v) => setState(() {
                      _isIncome = v;
                      _selectedCategoryIndex = 0;
                    }),
                  ),
                  const SizedBox(height: AppDimensions.spaceXL),

                  // ─── Kategori ──────────────────────────────────────────────
                  _SectionLabel(label: 'KATEGORİ'),
                  const SizedBox(height: AppDimensions.spaceS),
                  Wrap(
                    spacing: AppDimensions.spaceS,
                    runSpacing: AppDimensions.spaceS,
                    children: List.generate(_categories.length, (i) {
                      final cat = _categories[i];
                      final sel = i == _selectedCategoryIndex;
                      return ChoiceChip(
                        selected: sel,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategoryIndex = i);
                        },
                        label: Text(cat.label),
                        avatar: Icon(
                          cat.icon,
                          size: 16,
                          color: sel ? Colors.black : AppColors.cyberBlue,
                        ),
                        selectedColor: AppColors.cyberBlue,
                        backgroundColor: AppColors.glass08,
                        labelStyle: TextStyle(
                          color: sel ? Colors.black : AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: const BorderSide(color: AppColors.glass12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppDimensions.spaceXL),

                  // ─── Tutar ─────────────────────────────────────────────────
                  _SectionLabel(label: 'TUTAR (TL)'),
                  const SizedBox(height: AppDimensions.spaceS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceL,
                      vertical: AppDimensions.spaceM,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.glass08,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusL,
                      ),
                      border: Border.all(color: AppColors.glass12),
                    ),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _amountDigits,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onSurface,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'TL / ${_freqLabels[_frequency]}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.cyberBlueDim,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spaceM),
                        _Numpad(onDigit: _addDigit, onBackspace: _backspace),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXL),

                  // ─── Frekans ───────────────────────────────────────────────
                  _SectionLabel(label: 'TEKRAR PERİYODU'),
                  const SizedBox(height: AppDimensions.spaceS),
                  _FrequencySelector(
                    value: _frequency,
                    onChanged: (v) => setState(() => _frequency = v),
                  ),
                  const SizedBox(height: AppDimensions.spaceL),

                  // ─── Gün seçici ────────────────────────────────────────────
                  if (_frequency == 'weekly') ...[
                    _SectionLabel(label: 'HAFTANIN GÜNÜ'),
                    const SizedBox(height: AppDimensions.spaceS),
                    _WeekDaySelector(
                      value: _dayOfWeek,
                      labels: _weekDayLabels,
                      onChanged: (v) => setState(() => _dayOfWeek = v),
                    ),
                    const SizedBox(height: AppDimensions.spaceL),
                  ] else if (_frequency == 'monthly' ||
                      _frequency == 'yearly') ...[
                    _SectionLabel(
                      label: _frequency == 'yearly'
                          ? 'AYDA KAÇINCI GÜN'
                          : 'HER AYDA KAÇINCI GÜN',
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    _DayOfMonthSelector(
                      value: _dayOfMonth,
                      onChanged: (v) => setState(() => _dayOfMonth = v),
                    ),
                    const SizedBox(height: AppDimensions.spaceL),
                  ],

                  // ─── Kaydet ────────────────────────────────────────────────
                  const SizedBox(height: AppDimensions.spaceS),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _amount > 0 && !_isSaving ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyberBlue,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              widget.existing == null ? 'Kaydet' : 'Güncelle',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Alt bileşenler ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelCaps.copyWith(
        color: AppColors.onSurfaceVariant,
        letterSpacing: 1.4,
        fontSize: 11,
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  final bool isIncome;
  final ValueChanged<bool> onChanged;

  const _TypeToggle({required this.isIncome, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeTab(
              label: 'Gider',
              icon: Icons.arrow_upward_rounded,
              isSelected: !isIncome,
              accentColor: AppColors.cyberMagenta,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TypeTab(
              label: 'Gelir',
              icon: Icons.arrow_downward_rounded,
              isSelected: isIncome,
              accentColor: AppColors.neonLime,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: isSelected
              ? Border.all(color: accentColor.withValues(alpha: 0.4))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accentColor : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? accentColor : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FrequencySelector({required this.value, required this.onChanged});

  static const _options = [
    ('daily', 'Günlük', Icons.today_rounded),
    ('weekly', 'Haftalık', Icons.view_week_rounded),
    ('monthly', 'Aylık', Icons.calendar_month_rounded),
    ('yearly', 'Yıllık', Icons.calendar_today_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final (key, label, icon) = opt;
        final sel = value == key;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(key);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.cyberBlue.withValues(alpha: 0.15)
                      : AppColors.glass08,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(
                    color: sel ? AppColors.cyberBlue30 : AppColors.glass12,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: sel
                          ? AppColors.cyberBlue
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sel
                            ? AppColors.cyberBlue
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WeekDaySelector extends StatelessWidget {
  final int value; // 1-7
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _WeekDaySelector({
    required this.value,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final day = i + 1;
        final sel = value == day;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(day);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.cyberBlue : AppColors.glass08,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  border: Border.all(
                    color: sel ? AppColors.cyberBlue : AppColors.glass12,
                  ),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.black : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _DayOfMonthSelector extends StatelessWidget {
  final int value; // 1-31
  final ValueChanged<int> onChanged;

  const _DayOfMonthSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 18,
            color: AppColors.cyberBlue,
          ),
          const SizedBox(width: 12),
          Text(
            'Her ayın',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.cyberBlue,
                inactiveTrackColor: AppColors.glass12,
                thumbColor: AppColors.cyberBlue,
                overlayColor: AppColors.cyberBlue20,
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value.toDouble(),
                min: 1,
                max: 28,
                divisions: 27,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onChanged(v.round());
                },
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value. günü',
              textAlign: TextAlign.right,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.cyberBlue,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const _Numpad({required this.onDigit, required this.onBackspace});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['000', '0', '⌫'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: row.map((key) {
                final isBack = key == '⌫';
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: isBack ? onBackspace : () => onDigit(key),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isBack
                              ? AppColors.glass12
                              : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                        ),
                        child: Center(
                          child: isBack
                              ? const Icon(
                                  Icons.backspace_outlined,
                                  size: 18,
                                  color: AppColors.onSurfaceVariant,
                                )
                              : Text(
                                  key,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ─── Data holder ──────────────────────────────────────────────────────────────

class _Cat {
  final String label;
  final IconData icon;
  const _Cat(this.label, this.icon);
}
