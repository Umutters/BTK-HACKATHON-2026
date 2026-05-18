import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/recurring_rules_viewmodel.dart';
import '../../viewmodels/notifications_settings_viewmodel.dart';
import '../../viewmodels/theme_settings_viewmodel.dart';
import '../../viewmodels/ai_preferences_viewmodel.dart';
import '../../viewmodels/data_management_viewmodel.dart';
import 'recurring_rules_screen.dart';
import 'notifications_settings_screen.dart';
import 'theme_settings_screen.dart';
import 'ai_preferences_screen.dart';
import 'data_management_screen.dart';

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
            title: 'Düzenli İşlemler',
            subtitle: 'Maaş, kira, abonelik gibi tekrar eden gelir ve giderler',
            icon: Icons.repeat_rounded,
            accentColor: AppColors.cyberBlue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => RecurringRulesViewModel(),
                  child: const RecurringRulesScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          _SettingsCard(
            title: 'Bildirimler',
            subtitle: 'Harcama, görev ve AI önerileri için uyarılar',
            icon: Icons.notifications_active_rounded,
            accentColor: AppColors.cyberMagenta,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => NotificationsSettingsViewModel(),
                  child: const NotificationsSettingsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          _SettingsCard(
            title: 'Tema ve görünüm',
            subtitle: 'Neon / glass tasarım ayarlarını yönet',
            icon: Icons.palette_rounded,
            accentColor: AppColors.neonLime,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => ThemeSettingsViewModel(),
                  child: const ThemeSettingsScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          _SettingsCard(
            title: 'AI tercihleri',
            subtitle: 'Gemini davranışı ve cevap yoğunluğunu ayarla',
            icon: Icons.auto_awesome_rounded,
            accentColor: AppColors.cyberBlue,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => AiPreferencesViewModel(),
                  child: const AiPreferencesScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          _SettingsCard(
            title: 'Veri yönetimi',
            subtitle: 'Yerel kayıtları temizle, yedek al veya senkronize et',
            icon: Icons.storage_rounded,
            accentColor: AppColors.cyberMagenta,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => DataManagementViewModel(),
                  child: const DataManagementScreen(),
                ),
              ),
            ),
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
  final Color accentColor;
  final VoidCallback? onTap;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accentColor = AppColors.neonLime,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceL),
        decoration: BoxDecoration(
          color: AppColors.glass08,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(
            color: onTap != null
                ? accentColor.withValues(alpha: 0.2)
                : AppColors.glass12,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accentColor),
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
      ),
    );
  }
}
