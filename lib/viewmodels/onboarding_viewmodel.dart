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
      title: 'FortuneFlow\nYapay Zeka\'ya Hoş Geldin',
      description:
          'Finans yolculuğunu destansı bir göreve dönüştür. XP kazan, seviye atla ve para hedeflerini fethet.',
      icon: Icons.bolt_rounded,
      accent: AppColors.neonLime,
      accentSoft: AppColors.neonLime10,
      accentGlow: AppColors.neonLime30,
    ),
    OnboardingPageData(
      title: 'Günlük\nGörevleri Tamamla',
      description:
          'Her akıllı finans hamlesi XP kazandırır. Para biriktir, portföyünü analiz et ve yatırım yapmayı öğren; hepsi ödüllendirilir.',
      icon: Icons.military_tech_rounded,
      accent: AppColors.cyberBlue,
      accentSoft: AppColors.cyberBlue10,
      accentGlow: AppColors.cyberBlue30,
    ),
    OnboardingPageData(
      title: 'Yapay Zeka\nKâhini Seni Bekliyor',
      description:
          'Gelişmiş yapay zeka ile kişiselleştirilmiş finans içgörüleri al. İstediğini sor, anlık yönlendirme al.',
      icon: Icons.smart_toy_rounded,
      accent: AppColors.cyberMagenta,
      accentSoft: AppColors.cyberMagenta20,
      accentGlow: AppColors.cyberMagenta30,
    ),
    OnboardingPageData(
      title: 'Seviye Atlamaya\nHazır mısın?',
      description:
          'Finansal stresi finansal güce dönüştüren yeni nesil yatırımcıların arasına katıl.',
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
