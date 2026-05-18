import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/theme_settings_viewmodel.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Tema ve Görünüm', style: AppTextStyles.appBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ThemeSettingsViewModel>(
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
                      'Tema Ayarları',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.neonLime,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    Text(
                      'Görünümü ve tasarımı kişiselleştirin',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Dark mode toggle
              _ThemeToggleCard(
                title: 'Koyu Mod',
                subtitle: 'Gözleri korumak için koyu tema kullan',
                icon: Icons.dark_mode_rounded,
                value: vm.darkMode,
                onChanged: vm.toggleDarkMode,
                accentColor: AppColors.cyberBlue,
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Neon effects toggle
              _ThemeToggleCard(
                title: 'Neon Efektler',
                subtitle: 'Parlak neon renk efektlerini etkinleştir',
                icon: Icons.flash_on_rounded,
                value: vm.neonEffects,
                onChanged: vm.toggleNeonEffects,
                accentColor: AppColors.neonLime,
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Glass effect toggle
              _ThemeToggleCard(
                title: 'Glass Efekti',
                subtitle: 'Glassmorphism tasarımını etkinleştir',
                icon: Icons.blur_on_rounded,
                value: vm.glassEffect,
                onChanged: vm.toggleGlassEffect,
                accentColor: AppColors.cyberMagenta,
              ),
              const SizedBox(height: AppDimensions.spaceXL),

              // Brightness slider
              Container(
                padding: const EdgeInsets.all(AppDimensions.spaceL),
                decoration: BoxDecoration(
                  color: AppColors.glass08,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(color: AppColors.glass12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.cyberBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.brightness_4_rounded,
                            color: AppColors.cyberBlue,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceL),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Parlaklık Seviyesi',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ekran parlaklığını ayarla (${vm.brightnessLevel}/10)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceL),
                    Slider(
                      value: vm.brightnessLevel.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${vm.brightnessLevel}',
                      activeColor: AppColors.cyberBlue,
                      onChanged: (value) =>
                          vm.setBrightnessLevel(value.toInt()),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeToggleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;

  const _ThemeToggleCard({
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
