import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../viewmodels/user_setup_viewmodel.dart';
import '../../widgets/atoms/ff_button.dart';
import 'goal_setup_screen.dart';

/// Step 03/05 — Starting budget selection.
class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key});

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  _Currency _currency = _Currency.usd;
  double _amount = 10000;
  late final TextEditingController _amountController;
  final FocusNode _amountFocus = FocusNode();

  // Preset quick-select amounts per currency
  static const Map<_Currency, List<double>> _presets = {
    _Currency.usd: [5000, 10000, 50000],
    _Currency.try_: [50000, 100000, 500000],
  };

  static const Map<_Currency, double> _minimums = {
    _Currency.usd: 1000,
    _Currency.try_: 10000,
  };

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '10000');
    _amountController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final raw = _amountController.text.replaceAll(',', '').replaceAll(' ', '');
    final parsed = double.tryParse(raw);
    if (parsed != null && parsed != _amount) {
      setState(() => _amount = parsed);
    } else if (parsed == null && _amountController.text.isNotEmpty) {
      setState(() => _amount = 0);
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_onTextChanged);
    _amountController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  bool get _canProceed => _amount >= (_minimums[_currency] ?? 0);

  void _selectCurrency(_Currency c) {
    HapticFeedback.selectionClick();
    final newAmount = _presets[c]![1];
    _amountController.text = newAmount.toStringAsFixed(0);
    setState(() {
      _currency = c;
      _amount = newAmount;
    });
  }

  void _selectPreset(double value) {
    HapticFeedback.selectionClick();
    _amountController.text = value.toStringAsFixed(0);
    setState(() => _amount = value);
  }

  void _proceed() {
    if (!_canProceed) return;
    _amountFocus.unfocus();
    final vm = context.read<UserSetupViewModel>();
    vm.setCurrency(
      _currency == _Currency.usd ? SetupCurrency.usd : SetupCurrency.try_,
    );
    vm.setBudgetAmount(_amount);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const GoalSetupScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top header bar ───────────────────────────────────────────────
            _TopHeader(currentStep: 3, totalSteps: 5),
            Container(height: 1, color: AppColors.glass08),

            // ── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH,
                  vertical: AppDimensions.spaceXXL,
                ),
                child: Column(
                  children: [
                    // Icon
                    _WalletIcon(),
                    const SizedBox(height: AppDimensions.spaceXL),

                    // Title
                    Text(
                      'Başlangıç Bütçeniz',
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spaceM),

                    // Subtitle
                    Text(
                      'Simülasyona başlamak için başlangıç\nsermayenizi girin.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spaceXXL),

                    // Main card
                    _BudgetCard(
                      currency: _currency,
                      amount: _amount,
                      presets: _presets[_currency]!,
                      minimum: _minimums[_currency]!,
                      amountController: _amountController,
                      amountFocus: _amountFocus,
                      onCurrencyChanged: _selectCurrency,
                      onPresetSelected: _selectPreset,
                    ),
                    const SizedBox(height: AppDimensions.spaceXXL),

                    // Devam Et button
                    FfButton(
                      label: 'DEVAM ET  →',
                      onTap: _canProceed ? _proceed : null,
                      variant: FfButtonVariant.primary,
                      width: double.infinity,
                    ),
                    const SizedBox(height: AppDimensions.spaceM),

                    // Geri Dön button
                    _BackButton(onTap: _goBack),
                    const SizedBox(height: AppDimensions.spaceXXL),

                    // Bottom info cards
                    Row(
                      children: const [
                        Expanded(
                          child: _InfoCard(
                            iconData: Icons.security_rounded,
                            iconColor: AppColors.cyberBlue,
                            label: 'GÜVENLİ İŞLEM',
                            description: 'Uçtan uca şifreli veri simülasyonu.',
                          ),
                        ),
                        SizedBox(width: AppDimensions.spaceM),
                        Expanded(
                          child: _InfoCard(
                            iconData: Icons.bar_chart_rounded,
                            iconColor: AppColors.neonLime,
                            label: 'GERÇEK VERİ',
                            description: 'Anlık global piyasa entegrasyonu.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top header ───────────────────────────────────────────────────────────────

class _TopHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _TopHeader({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePaddingH,
        vertical: AppDimensions.spaceL,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand name
          Text(
            'KOMUT KONSOLU',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.neonLime,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          // Step indicator
          Row(
            children: [
              Text(
                'ADIM ${currentStep.toString().padLeft(2, '0')}/${totalSteps.toString().padLeft(2, '0')}',
                style: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              // Progress line
              SizedBox(
                width: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  child: SizedBox(
                    height: 3,
                    child: LinearProgressIndicator(
                      value: currentStep / totalSteps,
                      backgroundColor: AppColors.glass08,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.neonLime,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Wallet icon ──────────────────────────────────────────────────────────────

class _WalletIcon extends StatelessWidget {
  const _WalletIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: const Icon(
        Icons.account_balance_wallet_rounded,
        color: AppColors.neonLime,
        size: AppDimensions.iconL,
      ),
    );
  }
}

// ─── Currency enum ────────────────────────────────────────────────────────────

enum _Currency { usd, try_ }

extension _CurrencyExt on _Currency {
  String get symbol => this == _Currency.usd ? '\$' : '₺';
}

// ─── Budget card ──────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  final _Currency currency;
  final double amount;
  final List<double> presets;
  final double minimum;
  final TextEditingController amountController;
  final FocusNode amountFocus;
  final void Function(_Currency) onCurrencyChanged;
  final void Function(double) onPresetSelected;

  const _BudgetCard({
    required this.currency,
    required this.amount,
    required this.presets,
    required this.minimum,
    required this.amountController,
    required this.amountFocus,
    required this.onCurrencyChanged,
    required this.onPresetSelected,
  });

  String _formatAmount(double v) {
    if (v >= 1000000) {
      return '${currency.symbol}${(v / 1000000).toStringAsFixed(1)}M';
    }
    final intPart = v
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '${currency.symbol}$intPart';
  }

  String _formatMin(double v) {
    final intPart = v
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+\.)'),
          (m) => '${m[1]},',
        );
    return '${currency.symbol}$intPart';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Currency tabs
          _CurrencyTabs(selected: currency, onChanged: onCurrencyChanged),
          const SizedBox(height: AppDimensions.spaceL),

          // Capital label
          Text(
            'KAPİTAL MİKTARI',
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),

          // Amount input
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceXL,
              vertical: AppDimensions.spaceS,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  currency.symbol,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: TextField(
                    controller: amountController,
                    focusNode: amountFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: AppDimensions.spaceM,
                      ),
                    ),
                    cursorColor: AppColors.neonLime,
                    cursorWidth: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),

          // Min + bonus row
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: AppDimensions.spaceXS),
              Text(
                'MİNİMUM: ${_formatMin(minimum)}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Text(
                '+ BAŞLANGIÇ BONUSU: %5',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.cyberBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXL),

          // Quick-select presets
          Row(
            children: presets.asMap().entries.map((entry) {
              final isSelected = amount == entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: entry.key == 0 ? 0 : AppDimensions.spaceS / 2,
                    right: entry.key == presets.length - 1
                        ? 0
                        : AppDimensions.spaceS / 2,
                  ),
                  child: _PresetButton(
                    label: _formatAmount(entry.value),
                    selected: isSelected,
                    onTap: () => onPresetSelected(entry.value),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Currency tabs ────────────────────────────────────────────────────────────

class _CurrencyTabs extends StatelessWidget {
  final _Currency selected;
  final void Function(_Currency) onChanged;

  const _CurrencyTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'USD (Amerikan\nDoları)',
            isSelected: selected == _Currency.usd,
            onTap: () => onChanged(_Currency.usd),
          ),
          _Tab(
            label: 'TRY (Türk\nLirası)',
            isSelected: selected == _Currency.try_,
            onTap: () => onChanged(_Currency.try_),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceM,
            vertical: AppDimensions.spaceM,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.neonLime : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? AppColors.background
                  : AppColors.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Preset button ────────────────────────────────────────────────────────────

class _PresetButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceS,
          vertical: AppDimensions.spaceM,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.neonLime10 : AppColors.glass05,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(
            color: selected ? AppColors.neonLime : AppColors.glass12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.neonLime : AppColors.onSurface,
          ),
        ),
      ),
    );
  }
}

// ─── Back button ──────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceL),
          side: const BorderSide(color: AppColors.glass15, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          backgroundColor: AppColors.glass05,
        ),
        child: Text(
          'GERİ DÖN',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.onSurface,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Bottom info card ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData iconData;
  final Color iconColor;
  final String label;
  final String description;

  const _InfoCard({
    required this.iconData,
    required this.iconColor,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glass05,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: iconColor, size: AppDimensions.iconM),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            label,
            style: AppTextStyles.labelCaps.copyWith(
              fontSize: 10,
              letterSpacing: 1.2,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            description,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
              height: 1.4,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
