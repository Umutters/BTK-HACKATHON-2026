import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/notifications_settings_viewmodel.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Bildirimler', style: AppTextStyles.appBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<NotificationsSettingsViewModel>(
        builder: (context, vm, _) {
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
            children: [
              // Introduction
              Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spaceXL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bildirim Tercihleri',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.neonLime,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    Text(
                      'Aldığınız bildirimleri özelleştirin',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Expense notifications
              _NotificationToggleCard(
                title: 'Harcama Bildirimleri',
                subtitle: 'Önemli harcama görevleri için bildir',
                icon: Icons.shopping_cart_rounded,
                value: vm.expenseNotifications,
                onChanged: vm.toggleExpenseNotifications,
                accentColor: AppColors.cyberBlue,
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Quest notifications
              _NotificationToggleCard(
                title: 'Görev Bildirimleri',
                subtitle: 'Yeni görevler ve günlük görevler için bildir',
                icon: Icons.assignment_rounded,
                value: vm.questNotifications,
                onChanged: vm.toggleQuestNotifications,
                accentColor: AppColors.neonLime,
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // AI suggestions
              _NotificationToggleCard(
                title: 'AI Önerileri',
                subtitle: 'Kâhın AI önerileri ve tavsiyeler için bildir',
                icon: Icons.auto_awesome_rounded,
                value: vm.aiSuggestionsNotifications,
                onChanged: vm.toggleAiSuggestionsNotifications,
                accentColor: AppColors.cyberMagenta,
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Crisis alerts
              _NotificationToggleCard(
                title: 'Kriz Uyarıları',
                subtitle: 'Finansal kriz durumları için uyarı al',
                icon: Icons.warning_rounded,
                value: vm.crisisAlerts,
                onChanged: vm.toggleCrisisAlerts,
                accentColor: AppColors.cyberMagenta,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;

  const _NotificationToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.accentColor,
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
          const SizedBox(width: AppDimensions.spaceL),
          Switch(value: value, onChanged: onChanged, activeColor: accentColor),
        ],
      ),
    );
  }
}
