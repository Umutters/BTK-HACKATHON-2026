import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// UI-only data class for a single onboarding page.
/// Not a domain entity — purely presentation config.
class OnboardingPageData {
  final String title;
  final String description;
  final IconData icon;
  final Color accent; // full-opacity accent
  final Color accentSoft; // ~10% fill
  final Color accentGlow; // ~30% border + shadow

  const OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.accentGlow,
  });
}

class OnboardingViewModel extends ChangeNotifier {
  int _currentPage = 0;

  int get currentPage => _currentPage;
  bool get isLastPage => _currentPage == pages.length - 1;

  static const List<OnboardingPageData> pages = [
    OnboardingPageData(
      title: 'Welcome to\nFortuneFlow AI',
      description:
          'Transform your financial journey into an epic quest. Earn XP, level up, and conquer your money goals.',
      icon: Icons.bolt_rounded,
      accent: AppColors.neonLime,
      accentSoft: AppColors.neonLime10,
      accentGlow: AppColors.neonLime30,
    ),
    OnboardingPageData(
      title: 'Complete\nDaily Quests',
      description:
          'Every smart financial move earns XP. Save money, analyse your portfolio, and learn to invest — all rewarded.',
      icon: Icons.military_tech_rounded,
      accent: AppColors.cyberBlue,
      accentSoft: AppColors.cyberBlue10,
      accentGlow: AppColors.cyberBlue30,
    ),
    OnboardingPageData(
      title: 'Your AI\nOracle Awaits',
      description:
          'Get personalised financial insights powered by advanced AI. Ask anything, receive real-time guidance.',
      icon: Icons.smart_toy_rounded,
      accent: AppColors.cyberMagenta,
      accentSoft: AppColors.cyberMagenta20,
      accentGlow: AppColors.cyberMagenta30,
    ),
    OnboardingPageData(
      title: 'Ready to\nLevel Up?',
      description:
          'Join the next generation of investors who turned financial stress into financial power.',
      icon: Icons.rocket_launch_rounded,
      accent: AppColors.neonLime,
      accentSoft: AppColors.neonLime10,
      accentGlow: AppColors.neonLime30,
    ),
  ];

  void setPage(int index) {
    if (_currentPage != index) {
      _currentPage = index;
      notifyListeners();
    }
  }
}
