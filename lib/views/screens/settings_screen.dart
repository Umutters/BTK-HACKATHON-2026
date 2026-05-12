import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Ayarlar', style: AppTextStyles.appBarTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        children: [
          _SettingsCard(
            title: 'Bildirimler',
            subtitle: 'Harcama, görev ve AI önerileri için uyarılar',
            icon: Icons.notifications_active_rounded,
          ),
          const SizedBox(height: AppDimensions.spaceL),
          _SettingsCard(
            title: 'Tema ve görünüm',
            subtitle: 'Neon / glass tasarım ayarlarını yönet',
            icon: Icons.palette_rounded,
          ),
          const SizedBox(height: AppDimensions.spaceL),
          _SettingsCard(
            title: 'AI tercihleri',
            subtitle: 'Gemini davranışı ve cevap yoğunluğunu ayarla',
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: AppDimensions.spaceL),
          _SettingsCard(
            title: 'Veri yönetimi',
            subtitle: 'Yerel kayıtları temizle, yedek al veya senkronize et',
            icon: Icons.storage_rounded,
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neonLime10,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.neonLime),
          ),
          const SizedBox(width: AppDimensions.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
