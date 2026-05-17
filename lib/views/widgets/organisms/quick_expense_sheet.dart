import 'dart:math';
import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/datasources/local_datasource.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/models/recurring_transaction_model.dart';
import '../../../data/services/gemini_service.dart';
import '../../../data/services/supabase_service.dart';

class QuickTransactionResult {
  final double balanceDelta;
  final double transferredToSavings;

  const QuickTransactionResult({
    required this.balanceDelta,
    required this.transferredToSavings,
  });
}

class QuickExpenseSheet extends StatefulWidget {
  const QuickExpenseSheet({super.key});

  @override
  State<QuickExpenseSheet> createState() => _QuickExpenseSheetState();
}

class _QuickExpenseSheetState extends State<QuickExpenseSheet> {
  static const _expenseCategories = [
    _CategoryData('Kahve', Icons.local_cafe_rounded),
    _CategoryData('Yemek', Icons.fastfood_rounded),
    _CategoryData('Ulaşım', Icons.directions_car_rounded),
    _CategoryData('Eğlence', Icons.sports_esports_rounded),
  ];

  static const _incomeCategories = [
    _CategoryData('Maaş', Icons.account_balance_rounded),
    _CategoryData('Freelance', Icons.laptop_mac_rounded),
    _CategoryData('Prim', Icons.workspace_premium_rounded),
    _CategoryData('Satış', Icons.storefront_rounded),
  ];

  static const _savingsCategories = [
    _CategoryData('Birikim Transferi', Icons.savings_rounded),
    _CategoryData('Acil Fon', Icons.shield_rounded),
  ];

  String _amountDigits = '0';
  _EntryType _entryType = _EntryType.expense;
  int _selectedCategoryIndex = 0;
  ProfileModel? _profile;
  bool _isSaving = false;
  bool _isScanning = false;
  final GeminiService _geminiService = GeminiService();
  Timer? _previewDebounce;
  String? _aiSimulationPreview;
  String? _scanAnalysis;
  bool _isAiPreviewLoading = false;
  bool _isScanAnalysisLoading = false;
  int _previewRequestId = 0;
  int _scanRequestId = 0;

  List<_CategoryData> get _categories => _entryType == _EntryType.expense
      ? _expenseCategories
      : _entryType == _EntryType.income
      ? _incomeCategories
      : _savingsCategories;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await LocalDataSource().getProfile();
    if (!mounted) return;
    setState(() => _profile = profile);
    _schedulePreviewAnalysis();
  }

  double get _amount => double.tryParse(_amountDigits) ?? 0.0;

  String get _formattedAmount {
    final value = _amount.round();
    return value == 0 ? '0' : value.toString();
  }

  String get _fallbackSimulationPreview {
    if (_amount <= 0) {
      return 'Tutar girince uzun vade etkisini anında göstereceğiz.';
    }

    if (_entryType == _EntryType.income) {
      final boost = max(1, (_amount / 250).round());
      return 'Bu gelir hedef hızını yaklaşık $boost gün öne çekebilir.';
    }

    if (_entryType == _EntryType.savings) {
      return 'Bu aktarım birikim havuzunu doğrudan güçlendirir ve görev ilerletir.';
    }

    final dailyLimit = (_profile?.dailyLimit ?? 0).clamp(0.0, double.infinity);
    final divisor = dailyLimit > 0 ? max(dailyLimit * 0.35, 1.0) : 250.0;
    final days = max(1, (_amount / divisor).ceil());
    return 'Bu harcama finansal rotanı yaklaşık $days gün geciktirebilir.';
  }

  String get _simulationPreview =>
      _aiSimulationPreview ?? _fallbackSimulationPreview;

  void _schedulePreviewAnalysis() {
    _previewDebounce?.cancel();

    if (_amount <= 0) {
      if (!mounted) return;
      setState(() {
        _isAiPreviewLoading = false;
        _aiSimulationPreview = null;
      });
      return;
    }

    _previewDebounce = Timer(
      const Duration(milliseconds: 550),
      _analyzePreviewWithGemini,
    );
  }

  Future<void> _analyzePreviewWithGemini() async {
    final amount = _amount;
    if (amount <= 0) return;

    final requestId = ++_previewRequestId;
    if (mounted) {
      setState(() => _isAiPreviewLoading = true);
    }

    try {
      final profile = _profile;
      final preview = await _geminiService.generateQuickTransactionPreview(
        entryType: switch (_entryType) {
          _EntryType.expense => 'Gider',
          _EntryType.income => 'Gelir',
          _EntryType.savings => 'Birikim',
        },
        category: _categories[_selectedCategoryIndex].label,
        amount: amount,
        currentBalance: profile?.currentBalance ?? 0,
        savingsPool: profile?.savingsPool ?? 0,
        dailyLimit: profile?.dailyLimit ?? 0,
      );

      if (!mounted || requestId != _previewRequestId) return;
      setState(() {
        _aiSimulationPreview = preview;
        _isAiPreviewLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _previewRequestId) return;
      setState(() {
        _aiSimulationPreview = null;
        _isAiPreviewLoading = false;
      });
    }
  }

  void _setEntryType(_EntryType type) {
    if (_entryType == type) return;
    HapticFeedback.selectionClick();
    setState(() {
      _entryType = type;
      _selectedCategoryIndex = 0;
      _aiSimulationPreview = null;
      _scanAnalysis = null;
      _isScanAnalysisLoading = false;
    });
    _schedulePreviewAnalysis();
  }

  void _addDigit(String digit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_amountDigits == '0') {
        _amountDigits = digit;
      } else {
        _amountDigits += digit;
      }
      _aiSimulationPreview = null;
      _scanAnalysis = null;
      _isScanAnalysisLoading = false;
    });
    _schedulePreviewAnalysis();
  }

  void _backspace() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_amountDigits.length <= 1) {
        _amountDigits = '0';
      } else {
        _amountDigits = _amountDigits.substring(0, _amountDigits.length - 1);
      }
      _aiSimulationPreview = null;
      _scanAnalysis = null;
      _isScanAnalysisLoading = false;
    });
    _schedulePreviewAnalysis();
  }

  void _clear() {
    HapticFeedback.selectionClick();
    setState(() {
      _amountDigits = '0';
      _aiSimulationPreview = null;
      _scanAnalysis = null;
      _isScanAnalysisLoading = false;
    });
    _schedulePreviewAnalysis();
  }

  Future<void> _scanReceipt() async {
    HapticFeedback.mediumImpact();
    setState(() => _isScanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final amount = _amount;
    if (amount <= 0) {
      setState(() {
        _isScanning = false;
        _scanAnalysis = 'Gemini Scan için önce bir tutar gir.';
      });
      return;
    }

    final requestId = ++_scanRequestId;
    if (mounted) {
      setState(() {
        _isScanning = false;
        _isScanAnalysisLoading = true;
        _scanAnalysis = null;
      });
    }

    final profile = _profile;
    final analysis = await _geminiService.generateQuickScanAnalysis(
      entryType: switch (_entryType) {
        _EntryType.expense => 'Gider',
        _EntryType.income => 'Gelir',
        _EntryType.savings => 'Birikim',
      },
      category: _categories[_selectedCategoryIndex].label,
      amount: amount,
      currentBalance: profile?.currentBalance ?? 0,
      savingsPool: profile?.savingsPool ?? 0,
      dailyLimit: profile?.dailyLimit ?? 0,
    );

    if (!mounted || requestId != _scanRequestId) return;
    setState(() {
      _scanAnalysis =
          analysis ??
          'Gemini şu an kısa analizi veremedi. Mevcut tutar üzerinden devam edebilirsin.';
      _isScanAnalysisLoading = false;
    });
  }

  Future<void> _saveTransaction() async {
    if (_amount <= 0 || _isSaving) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final signedDelta = switch (_entryType) {
        _EntryType.expense => -_amount,
        _EntryType.income => _amount,
        _EntryType.savings => -_amount,
      };
      final transferredToSavings = _entryType == _EntryType.savings
          ? _amount
          : 0.0;
      final profile = _profile;
      final txn = RecurringTransactionModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        userId: profile?.id ?? 'local',
        type: _entryType == _EntryType.expense
            ? 'expense'
            : _entryType == _EntryType.income
            ? 'income'
            : 'saving',
        category: _categories[_selectedCategoryIndex].label,
        amount: _amount,
      );

      final dataSource = LocalDataSource();
      await dataSource.addRecurringTransaction(txn);
      if (_entryType == _EntryType.expense) {
        await dataSource.logDailySpending(
          spentAmount: _amount,
          transferredToSavings: 0,
          dailyLimit: profile?.dailyLimit,
        );
      } else if (_entryType == _EntryType.savings) {
        await dataSource.logDailySpending(
          spentAmount: 0,
          transferredToSavings: transferredToSavings,
        );
      }

      // İşlemi profil bakiyesine yansıt.
      if (profile != null) {
        final newBalance = (profile.currentBalance + signedDelta)
            .clamp(0.0, double.infinity)
            .toDouble();
        final updatedProfile = ProfileModel(
          id: profile.id,
          userName: profile.userName,
          age: profile.age,
          gender: profile.gender,
          initialBalance: profile.initialBalance,
          currentBalance: newBalance,
          savingsPool: profile.savingsPool + transferredToSavings,
          level: profile.level,
          xp: profile.xp,
          dailyLimit: profile.dailyLimit,
        );
        await dataSource.saveProfile(updatedProfile);
        _profile = updatedProfile;

        final authUserId = SupabaseService.instance.currentUserId;
        if (authUserId != null) {
          await SupabaseService.instance.updateProfile(authUserId, {
            'current_balance': newBalance,
            'savings_pool': updatedProfile.savingsPool,
          });
          if (_entryType == _EntryType.expense) {
            await SupabaseService.instance.insertDailyLog(
              userId: authUserId,
              spentAmount: _amount,
              transferredToSavings: 0,
              dailyLimit: profile.dailyLimit,
            );
          } else if (_entryType == _EntryType.savings) {
            await SupabaseService.instance.insertDailyLog(
              userId: authUserId,
              spentAmount: 0,
              transferredToSavings: transferredToSavings,
            );
          }
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(
        QuickTransactionResult(
          balanceDelta: signedDelta,
          transferredToSavings: transferredToSavings,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_entryType == _EntryType.expense
                ? 'Gider'
                : _entryType == _EntryType.income
                ? 'Gelir'
                : 'Birikim'} kaydedildi: ${_categories[_selectedCategoryIndex].label} - $_formattedAmount TL',
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
  void dispose() {
    _previewDebounce?.cancel();
    super.dispose();
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
                                _entryType == _EntryType.expense
                                    ? 'Hızlı Gider Girişi'
                                    : _entryType == _EntryType.income
                                    ? 'Hızlı Gelir Girişi'
                                    : 'Birikime Aktar',
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
                      padding: const EdgeInsets.all(AppDimensions.spaceXS),
                      decoration: BoxDecoration(
                        color: AppColors.glass08,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
                        border: Border.all(color: AppColors.glass12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TypeTabButton(
                              label: 'Gider',
                              isSelected: _entryType == _EntryType.expense,
                              onTap: () => _setEntryType(_EntryType.expense),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceXS),
                          Expanded(
                            child: _TypeTabButton(
                              label: 'Gelir',
                              isSelected: _entryType == _EntryType.income,
                              onTap: () => _setEntryType(_EntryType.income),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spaceXS),
                          Expanded(
                            child: _TypeTabButton(
                              label: 'Birikim',
                              isSelected: _entryType == _EntryType.savings,
                              onTap: () => _setEntryType(_EntryType.savings),
                            ),
                          ),
                        ],
                      ),
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
                              color: _isAiPreviewLoading
                                  ? AppColors.onSurfaceVariant
                                  : AppColors.cyberBlueDim,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_scanAnalysis != null || _isScanAnalysisLoading) ...[
                      const SizedBox(height: AppDimensions.spaceM),
                      _GeminiBubble(
                        isLoading: _isScanAnalysisLoading,
                        text: _scanAnalysis,
                      ),
                    ],
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
                            setState(() {
                              _selectedCategoryIndex = index;
                              _aiSimulationPreview = null;
                            });
                            _schedulePreviewAnalysis();
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
                                  onPressed:
                                      _isScanning ||
                                          _entryType == _EntryType.savings
                                      ? null
                                      : _scanReceipt,
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
                        onPressed: _isSaving ? null : _saveTransaction,
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
                            : Text(
                                _entryType == _EntryType.expense
                                    ? 'Gideri Kaydet'
                                    : _entryType == _EntryType.income
                                    ? 'Geliri Kaydet'
                                    : 'Birikime Aktar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    Text(
                      _entryType == _EntryType.expense
                          ? 'Kaydedilen gider, günlük log ve AI analizine eklenir.'
                          : _entryType == _EntryType.income
                          ? 'Kaydedilen gelir bakiyene eklenir ve analizde kullanılır.'
                          : 'Aktarılan tutar birikim havuzuna yazılır ve görev ilerletir.',
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

class _GeminiBubble extends StatelessWidget {
  final bool isLoading;
  final String? text;

  const _GeminiBubble({required this.isLoading, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: AppColors.cyberBlue20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.cyberBlue, AppColors.neonLime],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gemini',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.cyberBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading
                          ? 'Analiz ediliyor...'
                          : (text ?? 'Analiz alınamadı.'),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurface,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _EntryType { expense, income, savings }

class _TypeTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.neonLime : Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceS),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelLarge.copyWith(
              color: isSelected ? Colors.black : AppColors.onSurface,
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
