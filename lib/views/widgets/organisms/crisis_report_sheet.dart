import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/crisis_event_model.dart';
import '../../../data/services/supabase_service.dart';

class CrisisReportSheet extends StatefulWidget {
  const CrisisReportSheet({super.key});

  @override
  State<CrisisReportSheet> createState() => _CrisisReportSheetState();
}

class _CrisisReportSheetState extends State<CrisisReportSheet> {
  final _nameController = TextEditingController();
  String _amountDigits = '0';
  bool _isSending = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountDigits) ?? 0.0;

  String get _formattedAmount {
    final value = _amount.round();
    return value == 0 ? '0' : value.toString();
  }

  void _addDigit(String digit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_amountDigits == '0') {
        _amountDigits = digit;
      } else if (_amountDigits.length < 9) {
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

  Future<void> _sendCrisis() async {
    if (_isSending) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = 'Kriz adını gir.');
      return;
    }
    if (_amount <= 0) {
      setState(() => _errorText = 'Tutar girmeden gönderilemez.');
      return;
    }

    setState(() {
      _isSending = true;
      _errorText = null;
    });

    try {
      final userId = SupabaseService.instance.currentUserId;
      final CrisisEventModel crisis = CrisisEventModel(
        id: '',
        userId: userId ?? 'local',
        eventName: name,
        amount: _amount,
        resolutionStrategy: 'pending',
      );

      if (userId != null) {
        await SupabaseService.instance.insertCrisisEvent(crisis);
        final events = await SupabaseService.instance.getCrisisEvents(userId);
        final inserted = events.firstWhere(
          (e) =>
              e.eventName == name &&
              e.amount == _amount &&
              e.resolutionStrategy == 'pending',
          orElse: () => events.isNotEmpty ? events.first : crisis,
        );
        if (!mounted) return;
        Navigator.of(context).pop(inserted);
      } else {
        if (!mounted) return;
        Navigator.of(context).pop(crisis);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorText = 'Hata: $e';
      });
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
              color: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
              border: Border(
                top: BorderSide(
                  color: AppColors.cyberMagenta.withValues(alpha: 0.35),
                  width: 1.5,
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
                    // Drag handle
                    Center(
                      child: Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.cyberMagenta.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceL),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.cyberMagenta20,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyberMagenta.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: AppColors.cyberMagenta,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceL),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ZAMAN KIRILMASI',
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: AppColors.cyberMagenta,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Krizi bildir, Oracle anında devreye girer.',
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

                    // Kriz adı text field
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.glass08,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusL,
                        ),
                        border: Border.all(color: AppColors.cyberMagenta30),
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Kriz adı (ör: Araba tamiri, Acil hastane…)',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          prefixIcon: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.cyberMagenta,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spaceM,
                            vertical: AppDimensions.spaceM,
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 60,
                        buildCounter:
                            (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceL),

                    // Tutar göstergesi
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
                              color: AppColors.cyberMagenta,
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
                            _amount > 0
                                ? 'Oracle bu tutarın 2045 hedefine etkisini analiz edecek.'
                                : 'Kriz tutarını gir, Oracle stratejini belirlesin.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceL),

                    // Keypad
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.spaceL),
                      decoration: BoxDecoration(
                        color: AppColors.glass08,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusXL,
                        ),
                        border: Border.all(color: AppColors.glass12),
                      ),
                      child: GridView.builder(
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
                    ),
                    const SizedBox(height: AppDimensions.spaceXL),

                    // Hata mesajı
                    if (_errorText != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spaceM,
                          vertical: AppDimensions.spaceS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyberMagenta.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                          border: Border.all(
                            color: AppColors.cyberMagenta.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.cyberMagenta,
                              size: 16,
                            ),
                            const SizedBox(width: AppDimensions.spaceS),
                            Expanded(
                              child: Text(
                                _errorText!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.cyberMagenta,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spaceM),
                    ],

                    // Gönder butonu
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _sendCrisis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cyberMagenta,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.cyberMagenta
                              .withValues(alpha: 0.4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '🚨  Krizi Gönder',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceS),
                    Text(
                      'Kaydedilince Oracle devreye girer ve çözüm stratejini sunar.',
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
              color: isAction ? AppColors.cyberMagenta : AppColors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
