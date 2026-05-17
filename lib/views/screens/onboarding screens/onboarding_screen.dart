import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../viewmodels/onboarding_viewmodel.dart';
import '../../widgets/atoms/ff_button.dart';
import 'user_setup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const UserSetupScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: Consumer<OnboardingViewModel>(
        builder: (context, vm, _) {
          final page = OnboardingViewModel.pages[vm.currentPage];
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  // ── Üst satır: logo + atla ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.pagePaddingH,
                      AppDimensions.spaceM,
                      AppDimensions.pagePaddingH,
                      0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Brand wordmark
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.neonLime,
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: AppColors.background,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spaceS),
                            const Text(
                              'FortuneFlow',
                              style: AppTextStyles.appBarTitle,
                            ),
                          ],
                        ),
                        // Atla düğmesi
                        AnimatedOpacity(
                          opacity: vm.isLastPage ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(
                            ignoring: vm.isLastPage,
                            child: TextButton(
                              onPressed: _finish,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.onSurfaceVariant,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.spaceM,
                                  vertical: AppDimensions.spaceXS,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'ATLA',
                                style: AppTextStyles.labelMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Page content ─────────────────────────────────────────
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: OnboardingViewModel.pages.length,
                      onPageChanged: vm.setPage,
                      itemBuilder: (_, i) =>
                          _PageContent(data: OnboardingViewModel.pages[i]),
                    ),
                  ),

                  // ── Bottom: dots + CTA ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.pagePaddingH,
                      0,
                      AppDimensions.pagePaddingH,
                      AppDimensions.spaceXXL,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DotRow(
                          count: OnboardingViewModel.pages.length,
                          current: vm.currentPage,
                          accent: page.accent,
                        ),
                        const SizedBox(height: AppDimensions.spaceXXL),
                        FfButton(
                          label: vm.isLastPage ? 'BAŞLA' : 'İLERİ',
                          onTap: vm.isLastPage
                              ? _finish
                              : () => _controller.nextPage(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeInOut,
                                ),
                          variant: FfButtonVariant.primary,
                          width: double.infinity,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Single page content — fades + slides up on enter ────────────────────────

class _PageContent extends StatefulWidget {
  final OnboardingPageData data;

  const _PageContent({required this.data});

  @override
  State<_PageContent> createState() => _PageContentState();
}

class _PageContentState extends State<_PageContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePaddingH,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon: scale + fade
          FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: _GlowIcon(data: widget.data),
            ),
          ),
          const SizedBox(height: AppDimensions.space3XL),
          // Text: slide up + fade
          FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                children: [
                  Text(
                    widget.data.title,
                    style: AppTextStyles.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spaceL),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceXL,
                    ),
                    child: Text(
                      widget.data.description,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Glowing icon circle ──────────────────────────────────────────────────────

class _GlowIcon extends StatelessWidget {
  final OnboardingPageData data;

  const _GlowIcon({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: data.accentSoft,
        border: Border.all(color: data.accentGlow, width: 1.5),
        boxShadow: [
          BoxShadow(color: data.accentGlow, blurRadius: 60, spreadRadius: 16),
        ],
      ),
      child: Icon(data.icon, size: 80, color: data.accent),
    );
  }
}

// ─── Animated pill dot indicators ────────────────────────────────────────────

class _DotRow extends StatelessWidget {
  final int count;
  final int current;
  final Color accent;

  const _DotRow({
    required this.count,
    required this.current,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24.0 : 8.0,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? accent : AppColors.glass15,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
        );
      }),
    );
  }
}
