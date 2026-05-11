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

/// Step 04/05 — Financial goal selection.
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

  void _proceed() {
    if (!_canProceed) return;
    final selected = _goals.firstWhere((g) => g.id == _selectedId);
    final vm = context.read<UserSetupViewModel>();
    vm.setGoal(
      id: selected.id,
      name: selected.name,
      cyberName: selected.cyberName,
    );
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const LoadingScreen(),
        transitionsBuilder: (_, animation, __, child) =>
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
            // ── App header ───────────────────────────────────────────────────
            _AppHeader(),
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
                    // Step label
                    Text(
                      'ADIM 04 / 05',
                      style: AppTextStyles.labelCaps.copyWith(
                        color: AppColors.cyberBlue,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceS),

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
                      "Oracle'ın size hangi yönde rehberlik etmesini istersiniz?\nStratejinizi belirleyin, komutları biz hazırlayalım.",
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
            _BottomBar(
              progress: 4 / 5,
              canProceed: _canProceed,
              onBack: _goBack,
              onProceed: _proceed,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App header ───────────────────────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePaddingH,
        vertical: AppDimensions.spaceL,
      ),
      child: Row(
        children: [
          // Hamburger icon
          const Icon(
            Icons.menu_rounded,
            color: AppColors.onSurface,
            size: AppDimensions.iconM,
          ),
          const Spacer(),
          // Brand
          Text(
            'FX COMMAND',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.neonLime,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.glass10,
              border: Border.all(color: AppColors.neonLime30, width: 1.5),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.onSurfaceVariant,
              size: 22,
            ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: icon + optional recommended badge ───────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon box
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: goal.iconBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(goal.icon, color: goal.iconColor, size: 28),
                ),
                const Spacer(),
                if (goal.isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spaceM,
                      vertical: AppDimensions.spaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neonLime20,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                      border: Border.all(color: AppColors.neonLime, width: 1),
                    ),
                    child: Text(
                      'ÖNERİLEN',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.neonLime,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceL),

            // ── Name ─────────────────────────────────────────────────────────
            Text(
              goal.name,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXS),

            // ── Cyber name badge ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spaceS,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.glass10,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
              ),
              child: Text(
                goal.cyberName,
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceM),

            // ── Description ──────────────────────────────────────────────────
            Text(
              goal.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceL),

            // Divider
            Container(height: 1, color: AppColors.glass08),
            const SizedBox(height: AppDimensions.spaceM),

            // ── Action row ───────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSelected ? 'AKTİF' : 'SEÇ',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: isSelected
                        ? AppColors.neonLime
                        : AppColors.onSurface,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: isSelected
                      ? AppColors.neonLime
                      : AppColors.onSurfaceVariant,
                  size: AppDimensions.iconM,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final double progress;
  final bool canProceed;
  final VoidCallback onBack;
  final VoidCallback onProceed;

  const _BottomBar({
    required this.progress,
    required this.canProceed,
    required this.onBack,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress label row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İLERLEME',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 1.5,
                  fontSize: 10,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.neonLime,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXS),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.glass08,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.neonLime,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),

          // Buttons row
          Row(
            children: [
              // Geri
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spaceL,
                    ),
                    side: const BorderSide(color: AppColors.glass15, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
                    ),
                    backgroundColor: AppColors.glass05,
                  ),
                  child: Text(
                    'Geri',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),

              // Devam Et
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: canProceed ? onProceed : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canProceed
                        ? AppColors.neonLime
                        : AppColors.glass08,
                    foregroundColor: AppColors.background,
                    disabledBackgroundColor: AppColors.glass08,
                    disabledForegroundColor: AppColors.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.spaceL,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusM,
                      ),
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
            ],
          ),
        ],
      ),
    );
  }
}
