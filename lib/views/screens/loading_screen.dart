import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/user_setup_viewmodel.dart';
import 'main_navigation_wrapper.dart';

/// Boot-sequence loading screen shown after onboarding.
/// Uses ShareTechMono for the terminal aesthetic and AnimatedSwitcher
/// to transition between log lines — creating perceived AI analysis value.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  int _phase = 0;
  late final List<String> _lines;
  late final AnimationController _progressCtrl;
  late final AnimationController _glowCtrl;
  late final Timer _timer;

  // How long each phase lasts
  static const _phaseMs = 620;

  @override
  void initState() {
    super.initState();

    final vm = context.read<UserSetupViewModel>();
    final userName = vm.userName;
    final age = vm.age;
    final goalCyberName = vm.goalCyberName;

    _lines = [
      '> OPERATÖR KİMLİĞİ DOĞRULANDI: ${userName.toUpperCase()}.EXE',
      '> YAŞ PROFİLİ TARANIDI: $age — RİSK MODELİ HESAPLANIYOR...',
      '> FİNANSAL HEDEF: ${goalCyberName.toUpperCase()} — AKTİF',
      '> KÜRESEL PİYASA VERİLERİ SENKRONİZE EDİLİYOR...',
      '> YAPAY ZEKA STRATEJİ MOTORU BAŞLATILIYOR...',
      '> KİŞİSEL ANALİZ TAMAMLANDI. HOŞ GELDİNİZ, ${userName.toUpperCase()}.',
    ];

    // Progress bar animates over total duration
    final totalMs = _phaseMs * _lines.length + 400;
    _progressCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    )..forward();

    // Pulsing glow on the cursor
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    // Advance phase every _phaseMs ms
    _timer = Timer.periodic(const Duration(milliseconds: _phaseMs), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_phase < _lines.length - 1) {
        setState(() => _phase++);
      } else {
        t.cancel();
        // Small extra pause after last line before navigating
        Future.delayed(const Duration(milliseconds: 600), _navigate);
      }
    });
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const MainNavigationWrapper(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _progressCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
            vertical: AppDimensions.spaceXXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Brand ──────────────────────────────────────────────────────
              Center(
                child: Text(
                  'FX COMMAND',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.neonLime,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXS),
              Center(
                child: Text(
                  'SYSTEM BOOT SEQUENCE',
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space3XL),

              // ── Terminal card ──────────────────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.spaceXL),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(color: AppColors.glass12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26DEFF9A), // neonLime glow
                        blurRadius: 24,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Terminal title bar ─────────────────────────────────
                      Row(
                        children: [
                          _DotIndicator(color: AppColors.cyberMagenta),
                          const SizedBox(width: AppDimensions.spaceXS),
                          _DotIndicator(color: AppColors.neonLimeDim),
                          const SizedBox(width: AppDimensions.spaceXS),
                          _DotIndicator(color: AppColors.neonLime),
                          const SizedBox(width: AppDimensions.spaceM),
                          const Text(
                            'fx_oracle — bash',
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 11,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spaceL),
                      Container(height: 1, color: AppColors.glass08),
                      const SizedBox(height: AppDimensions.spaceL),

                      // ── Log lines (already shown) ──────────────────────────
                      ...List.generate(
                        _phase,
                        (i) => _LogLine(
                          text: _lines[i],
                          color: i == _lines.length - 1
                              ? AppColors.neonLime
                              : AppColors.cyberBlue,
                        ),
                      ),

                      // ── Current active line with AnimatedSwitcher ──────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: const Offset(0, 0.3),
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
                        child: _ActiveLogLine(
                          key: ValueKey(_phase),
                          text: _lines[_phase],
                          glowCtrl: _glowCtrl,
                          isLast: _phase == _lines.length - 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space3XL),

              // ── Progress bar ───────────────────────────────────────────────
              _ProgressSection(controller: _progressCtrl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dot indicator (terminal title bar) ──────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final Color color;
  const _DotIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ─── Completed log line ───────────────────────────────────────────────────────

class _LogLine extends StatelessWidget {
  final String text;
  final Color color;
  const _LogLine({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceM),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 12,
          color: color.withOpacity(0.55),
          height: 1.5,
        ),
      ),
    );
  }
}

// ─── Active log line (highlighted + blinking cursor) ─────────────────────────

class _ActiveLogLine extends StatelessWidget {
  final String text;
  final AnimationController glowCtrl;
  final bool isLast;

  const _ActiveLogLine({
    super.key,
    required this.text,
    required this.glowCtrl,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 13,
              color: isLast ? AppColors.neonLime : AppColors.onSurface,
              height: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Blinking cursor
        AnimatedBuilder(
          animation: glowCtrl,
          builder: (_, _) => Opacity(
            opacity: glowCtrl.value,
            child: Container(
              width: 8,
              height: 16,
              margin: const EdgeInsets.only(
                left: AppDimensions.spaceXS,
                top: 4,
              ),
              decoration: BoxDecoration(
                color: isLast ? AppColors.neonLime : AppColors.cyberBlue,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Progress section ─────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final AnimationController controller;
  const _ProgressSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ANALİZ EDİLİYOR',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
                letterSpacing: 2,
              ),
            ),
            AnimatedBuilder(
              animation: controller,
              builder: (_, _) => Text(
                '${(controller.value * 100).round()}%',
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 10,
                  color: AppColors.neonLime,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceXS),
        AnimatedBuilder(
          animation: controller,
          builder: (_, _) => ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: controller.value,
                backgroundColor: AppColors.glass08,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.neonLime,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        Center(
          child: Text(
            'Lütfen bekleyin...',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 11,
              color: AppColors.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }
}
