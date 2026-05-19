import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../viewmodels/user_setup_viewmodel.dart';
import '../loading_screen.dart';

// ─── Data model ───────────────────────────────────────────────────────────────

class _GoalData {
  final String id;
  final String name;
  final String cyberName;
  final String description;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool isRecommended;

  const _GoalData({
    required this.id,
    required this.name,
    required this.cyberName,
    required this.description,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.isRecommended = false,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────

/// Step 04/04 — Financial goal selection.
class GoalSetupScreen extends StatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  State<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends State<GoalSetupScreen> {
  String? _selectedId;

  static const List<_GoalData> _goals = [
    _GoalData(
      id: 'education',
      name: 'Eğitim',
      cyberName: 'Knowledge Upgrade',
      description: 'Yüksek lisans, kurs veya sertifika.',
      icon: Icons.school_rounded,
      iconBg: Color(0x1A00E5FF), // cyberBlue 10%
      iconColor: AppColors.cyberBlue,
    ),
    _GoalData(
      id: 'debt',
      name: 'Borç Kapatma',
      cyberName: 'System Recovery',
      description: 'Kredi kartı veya KYK borçları.',
      icon: Icons.credit_card_rounded,
      iconBg: Color(0x1A00E5FF),
      iconColor: AppColors.cyberBlue,
    ),
    _GoalData(
      id: 'emergency',
      name: 'Acil Durum Fonu',
      cyberName: 'Shield Activation',
      description: '6 aylık gideri kenara koymak.',
      icon: Icons.shield_rounded,
      iconBg: Color(0x1ADEFF9A), // neonLime 10%
      iconColor: AppColors.neonLime,
      isRecommended: true,
    ),
    _GoalData(
      id: 'startup',
      name: 'Girişimcilik',
      cyberName: 'Startup Launch',
      description: 'Kendi işini kurma sermayesi.',
      icon: Icons.rocket_launch_rounded,
      iconBg: Color(0x1A00E5FF),
      iconColor: AppColors.cyberBlue,
    ),
    _GoalData(
      id: 'family',
      name: 'Evlilik / Aile',
      cyberName: 'Alliance Protocol',
      description: 'Düğün veya aile kurma masrafı.',
      icon: Icons.favorite_rounded,
      iconBg: Color(0x1AFF007A), // cyberMagenta 10%
      iconColor: AppColors.cyberMagenta,
    ),
    _GoalData(
      id: 'digital',
      name: 'Dijital Varlık',
      cyberName: 'Crypto/NFT Mining',
      description: 'Teknoloji ve dijital yatırım portföyü.',
      icon: Icons.currency_bitcoin_rounded,
      iconBg: Color(0x1ADEFF9A),
      iconColor: AppColors.neonLime,
    ),
  ];

  bool get _canProceed => _selectedId != null;

  void _toggle(String id) {
    HapticFeedback.selectionClick();
    setState(() => _selectedId = id);
  }

  void _proceed() async {
    if (!_canProceed) return;
    final selected = _goals.firstWhere((g) => g.id == _selectedId);
    final vm = context.read<UserSetupViewModel>();
    vm.setGoal(
      id: selected.id,
      name: selected.name,
      cyberName: selected.cyberName,
    );
    await vm.saveToLocal();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const LoadingScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _goBack() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top header ───────────────────────────────────────────────────
            _TopHeader(onBack: _goBack),
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
                    // Title
                    Text(
                      'Finansal Hedefiniz',
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spaceM),

                    // Subtitle
                    Text(
                      'Yapay zekanin rehberlik edecegi ana hedefi secin.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.spaceXXL),

                    // Goal cards
                    ..._goals.map(
                      (goal) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDimensions.spaceM,
                        ),
                        child: _GoalCard(
                          goal: goal,
                          isSelected: _selectedId == goal.id,
                          onTap: () => _toggle(goal.id),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.spaceS),
                  ],
                ),
              ),
            ),

            // ── Bottom bar ───────────────────────────────────────────────────
            _BottomBar(canProceed: _canProceed, onProceed: _proceed),
          ],
        ),
      ),
    );
  }
}

// ─── App header ───────────────────────────────────────────────────────────────

class _TopHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _TopHeader({required this.onBack});

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
                color: AppColors.onSurface,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                'ADIM 04/04',
                style: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              SizedBox(
                width: 48,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  child: const SizedBox(
                    height: 3,
                    child: LinearProgressIndicator(
                      value: 1,
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
    );
  }
}

// ─── Goal card ────────────────────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final _GoalData goal;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goal,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x1ADEFF9A) : AppColors.glass08,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: isSelected ? AppColors.neonLime : AppColors.glass12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: goal.iconBg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(goal.icon, color: goal.iconColor, size: 26),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXS),
                  Text(
                    goal.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.neonLime : AppColors.outline,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool canProceed;
  final VoidCallback onProceed;

  const _BottomBar({required this.canProceed, required this.onProceed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pagePaddingH,
        AppDimensions.spaceL,
        AppDimensions.pagePaddingH,
        AppDimensions.spaceXL,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.glass08)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canProceed ? onProceed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canProceed
                ? AppColors.neonLime
                : AppColors.glass08,
            foregroundColor: AppColors.background,
            disabledBackgroundColor: AppColors.glass08,
            disabledForegroundColor: AppColors.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceL),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            elevation: 0,
          ),
          child: Text(
            'Devam Et',
            style: AppTextStyles.labelLarge.copyWith(
              color: canProceed
                  ? AppColors.background
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
