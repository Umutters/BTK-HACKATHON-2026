import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../viewmodels/user_setup_viewmodel.dart';
import '../../widgets/atoms/ff_button.dart';
import 'budget_setup_screen.dart';

/// Step 02/04 — Age selection with animated ruler tick marks.
class AgeSetupScreen extends StatefulWidget {
  const AgeSetupScreen({super.key});

  @override
  State<AgeSetupScreen> createState() => _AgeSetupScreenState();
}

class _AgeSetupScreenState extends State<AgeSetupScreen> {
  int _age = 28;

  static const int _minAge = 1;
  static const int _maxAge = 80;

  void _increment() {
    if (_age < _maxAge) {
      HapticFeedback.selectionClick();
      setState(() => _age++);
    }
  }

  void _decrement() {
    if (_age > _minAge) {
      HapticFeedback.selectionClick();
      setState(() => _age--);
    }
  }

  void _proceed() {
    context.read<UserSetupViewModel>().setAge(_age);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const BudgetSetupScreen(),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── KOMUT KONSOLU başlığı ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pagePaddingH,
                vertical: AppDimensions.spaceL,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _goBack,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.glass08,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull,
                        ),
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
                        'ADIM 02/04',
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceM),
                      SizedBox(
                        width: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                          child: const SizedBox(
                            height: 3,
                            child: LinearProgressIndicator(
                              value: 2 / 4,
                              backgroundColor: AppColors.glass08,
                              valueColor: AlwaysStoppedAnimation<Color>(
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
            ),
            // thin divider
            Container(height: 1, color: AppColors.glass08),

            // ── Main card ───────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pagePaddingH,
                  vertical: AppDimensions.spaceXXL,
                ),
                child: Column(
                  children: [
                    _AgeCard(
                      age: _age,
                      minAge: _minAge,
                      maxAge: _maxAge,
                      onIncrement: _increment,
                      onDecrement: _decrement,
                      onProceed: _proceed,
                      onAgeChanged: (a) => setState(() => _age = a),
                    ),
                    const SizedBox(height: AppDimensions.spaceXL),
                    const _PrivacyNote(),
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

// ─── Age card ─────────────────────────────────────────────────────────────────

class _AgeCard extends StatelessWidget {
  final int age;
  final int minAge;
  final int maxAge;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onProceed;
  final void Function(int) onAgeChanged;

  const _AgeCard({
    required this.age,
    required this.minAge,
    required this.maxAge,
    required this.onIncrement,
    required this.onDecrement,
    required this.onProceed,
    required this.onAgeChanged,
  });

  double get _progress => 2 / 4;

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
          // Step indicator row
          _StepRow(progress: _progress),
          const SizedBox(height: AppDimensions.spaceXXL),

          // Title + subtitle
          Text(
            'Yaşınızı Belirleyin',
            style: AppTextStyles.displayLarge.copyWith(fontSize: 28),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          const Text(
            'Size en uygun döviz stratejilerini\nbelirlememize yardımcı olun.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.space3XL),

          // Counter row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CircleButton(
                icon: Icons.remove_rounded,
                onTap: onDecrement,
                enabled: age > minAge,
              ),
              const SizedBox(width: AppDimensions.space3XL),
              Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.35),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: child,
                      ),
                    ),
                    child: Text(
                      '$age',
                      key: ValueKey(age),
                      style: const TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cyberBlue,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXS),
                  const Text('YAŞINDA', style: AppTextStyles.labelCaps),
                ],
              ),
              const SizedBox(width: AppDimensions.space3XL),
              _CircleButton(
                icon: Icons.add_rounded,
                onTap: onIncrement,
                enabled: age < maxAge,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXXL),

          // Ruler
          _AgeRuler(
            age: age,
            minAge: minAge,
            maxAge: maxAge,
            onAgeChanged: onAgeChanged,
          ),
          const SizedBox(height: AppDimensions.space3XL),

          // CTA
          FfButton(
            label: 'DEVAM ET',
            onTap: onProceed,
            variant: FfButtonVariant.primary,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}

// ─── Step progress row ────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  final double progress; // 0.0 – 1.0

  const _StepRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'ADIM 02/04',
              style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceXS),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.glass08,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.cyberBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Circle ± button ──────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? AppColors.glass10 : AppColors.glass05,
          border: Border.all(
            color: enabled ? AppColors.glass15 : AppColors.glass08,
          ),
        ),
        child: Icon(
          icon,
          size: 26,
          color: enabled ? AppColors.onSurface : AppColors.outline,
        ),
      ),
    );
  }
}

// ─── Age ruler tick marks ─────────────────────────────────────────────────────

class _AgeRuler extends StatefulWidget {
  final int age;
  final int minAge;
  final int maxAge;
  final void Function(int) onAgeChanged;

  const _AgeRuler({
    required this.age,
    required this.minAge,
    required this.maxAge,
    required this.onAgeChanged,
  });

  @override
  State<_AgeRuler> createState() => _AgeRulerState();
}

class _AgeRulerState extends State<_AgeRuler> {
  double _dragAcc = 0;

  // pixels per age unit — matches tick spacing (~12px)
  static const double _pixelsPerUnit = 13.0;

  void _onDragUpdate(DragUpdateDetails d) {
    _dragAcc += d.delta.dx;
    final steps = (_dragAcc / _pixelsPerUnit).truncate();
    if (steps != 0) {
      _dragAcc -= steps * _pixelsPerUnit;
      // drag right → decrease age (ruler slides right showing smaller values)
      final newAge = (widget.age - steps).clamp(widget.minAge, widget.maxAge);
      if (newAge != widget.age) {
        HapticFeedback.selectionClick();
        widget.onAgeChanged(newAge);
      }
    }
  }

  void _onDragEnd(DragEndDetails _) => _dragAcc = 0;

  @override
  Widget build(BuildContext context) {
    const visibleCount = 21;
    const center = visibleCount ~/ 2;

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(visibleCount, (i) {
            final offset = i - center; // -10 .. 0 .. +10
            final tickAge = widget.age + offset;
            final inRange =
                tickAge >= widget.minAge && tickAge <= widget.maxAge;
            final dist = offset.abs();

            final height = inRange ? math.max(8.0, 40.0 - dist * 3.0) : 8.0;
            final opacity = inRange ? math.max(0.12, 1.0 - dist * 0.09) : 0.12;
            final color = offset == 0
                ? AppColors.cyberBlue
                : AppColors.onSurface.withValues(alpha: opacity);
            final width = dist <= 1 ? 2.5 : 1.5;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              width: width,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─── Privacy note ─────────────────────────────────────────────────────────────

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.shield_rounded,
          color: AppColors.neonLime,
          size: AppDimensions.iconM,
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: Text(
            'Verileriniz 256-bit AES şifreleme ile korunmaktadır ve risk profiliniz için kullanılır.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
