import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../viewmodels/user_setup_viewmodel.dart';
import '../../widgets/atoms/ff_button.dart';
import 'age_setup_screen.dart';

/// Identity setup screen — user enters their operator name.
/// Shown after the onboarding slides, before the main app.
class UserSetupScreen extends StatefulWidget {
  const UserSetupScreen({super.key});

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _nameController = TextEditingController();
  final _focusNode = FocusNode();
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      final has = _nameController.text.trim().isNotEmpty;
      if (has != _canProceed) setState(() => _canProceed = has);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _proceed() {
    if (!_canProceed) return;
    _focusNode.unfocus();
    context.read<UserSetupViewModel>().setUserName(_nameController.text);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const AgeSetupScreen(),
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
    return GestureDetector(
      onTap: () => _focusNode.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              _TopStepHeader(currentStep: 1, totalSteps: 4, onBack: _goBack),
              Container(height: 1, color: AppColors.glass08),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pagePaddingH,
                    vertical: AppDimensions.spaceXXL,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppDimensions.spaceL),
                      const _OracleAvatar(),
                      const SizedBox(height: AppDimensions.spaceL),
                      const SizedBox(height: AppDimensions.space3XL),
                      _IdentityCard(
                        controller: _nameController,
                        focusNode: _focusNode,
                        canProceed: _canProceed,
                        onProceed: _proceed,
                      ),
                    ],
                  ),
                ),
              ),
              // ── Protocol ticker ──
              const _ProtocolTicker(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Kâhin yapay zeka avatar çemberi ────────────────────────────────────────

class _OracleAvatar extends StatelessWidget {
  const _OracleAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cyberBlue10,
        border: Border.all(color: AppColors.cyberBlue30, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cyberBlue20,
            blurRadius: 48,
            spreadRadius: 12,
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _TopStepHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  const _TopStepHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePaddingH,
        vertical: AppDimensions.spaceL,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.glass08,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(color: AppColors.glass12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                'ADIM ${currentStep.toString().padLeft(2, '0')}/${totalSteps.toString().padLeft(2, '0')}',
                style: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              SizedBox(
                width: 80,
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

// ─── Identity card ────────────────────────────────────────────────────────────

class _IdentityCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canProceed;
  final VoidCallback onProceed;

  const _IdentityCard({
    required this.controller,
    required this.focusNode,
    required this.canProceed,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spaceXL,
        AppDimensions.spaceXL,
        AppDimensions.spaceXL,
        AppDimensions.spaceXXL,
      ),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Center(
            child: Text(
              'Size nasıl\nhitap edelim?',
              style: AppTextStyles.displayLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          // Subtitle
          const Center(
            child: Text(
              'Finansal yolculuğunuza başlamak için\nisminizi girin.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppDimensions.space3XL),

          // ── Name input field ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Input container
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  border: Border.all(color: AppColors.glass12),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: AppTextStyles.bodyLarge,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onProceed(),
                  inputFormatters: [LengthLimitingTextInputFormatter(32)],
                  decoration: InputDecoration(
                    hintText: 'İsminizi buraya yazın...👆',
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.outline,
                    ),
                    suffixIcon: const Icon(
                      Icons.fingerprint_rounded,
                      color: AppColors.cyberBlue,
                      size: AppDimensions.iconM,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceL,
                      vertical: AppDimensions.spaceL,
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
              ),
              // Floating "OPERATÖR ADI" label
              Positioned(
                top: -10,
                left: AppDimensions.spaceM,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceXS,
                  ),
                  color: AppColors.background,
                  child: Text(
                    'KULLANICI ADI',
                    style: AppTextStyles.labelCaps.copyWith(
                      color: AppColors.cyberBlue,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spaceXL),

          // ── CTA button ──
          FfButton(
            label: 'DEVAM ET →',
            onTap: canProceed ? onProceed : null,
            variant: FfButtonVariant.primary,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}

// ─── Bottom protocol ticker ───────────────────────────────────────────────────

class _ProtocolTicker extends StatelessWidget {
  const _ProtocolTicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePaddingH,
        vertical: AppDimensions.spaceS,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.glass08)),
      ),
      child: Text(
        'PROTOKOL: FX_COMMAND // KÖK: 0X8A2C // DURUM: YETKİLENDİRME BEKLENİYOR',
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.outlineVariant,
          fontSize: 9,
          letterSpacing: 0.8,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
