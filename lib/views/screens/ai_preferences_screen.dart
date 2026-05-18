import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/ai_preferences_viewmodel.dart';

class AiPreferencesScreen extends StatelessWidget {
  const AiPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('AI Tercihleri', style: AppTextStyles.appBarTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AiPreferencesViewModel>(
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
                      'Kâhın AI Ayarları',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.neonLime,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    Text(
                      'AI asistanının davranışını özelleştir',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Response Length Selection
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
                            color: AppColors.cyberMagenta.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.message_rounded,
                            color: AppColors.cyberMagenta,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceL),
                        Text(
                          'Cevap Uzunluğu',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceL),
                    _ResponseLengthOption(
                      label: 'Kısa',
                      description: 'Hızlı ve özlü cevaplar',
                      value: 'short',
                      selected: vm.responseLength == 'short',
                      onSelect: () => vm.setResponseLength('short'),
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    _ResponseLengthOption(
                      label: 'Orta',
                      description: 'Dengeli ve kapsamlı cevaplar',
                      value: 'moderate',
                      selected: vm.responseLength == 'moderate',
                      onSelect: () => vm.setResponseLength('moderate'),
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    _ResponseLengthOption(
                      label: 'Detaylı',
                      description: 'Derinlemesine açıklamalar',
                      value: 'detailed',
                      selected: vm.responseLength == 'detailed',
                      onSelect: () => vm.setResponseLength('detailed'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXL),

              // Use Images toggle
              _AiPreferenceCard(
                title: 'Grafik Veriler',
                subtitle: 'Cevaplarda grafik ve görseller kullan',
                icon: Icons.image_rounded,
                value: vm.useImages,
                onChanged: vm.toggleUseImages,
                accentColor: AppColors.cyberBlue,
              ),
              const SizedBox(height: AppDimensions.spaceL),

              // Use Tables toggle
              _AiPreferenceCard(
                title: 'Tablo Veriler',
                subtitle: 'Cevaplarda tablo formatı kullan',
                icon: Icons.table_chart_rounded,
                value: vm.useTables,
                onChanged: vm.toggleUseTables,
                accentColor: AppColors.neonLime,
              ),
              const SizedBox(height: AppDimensions.spaceXL),

              // Confidence Threshold Slider
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
                            Icons.verified_rounded,
                            color: AppColors.cyberBlue,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceL),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Güven Eşiği',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Minimum güven seviyesi (${vm.confidenceThreshold}/10)',
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
                      value: vm.confidenceThreshold.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${vm.confidenceThreshold}',
                      activeColor: AppColors.cyberBlue,
                      onChanged: (value) =>
                          vm.setConfidenceThreshold(value.toInt()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spaceXL),

              // Language Selection
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
                            color: AppColors.neonLime.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.language_rounded,
                            color: AppColors.neonLime,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceL),
                        Text(
                          'Dil',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spaceL),
                    _LanguageOption(
                      label: 'Türkçe',
                      value: 'tr',
                      selected: vm.language == 'tr',
                      onSelect: () => vm.setLanguage('tr'),
                    ),
                    const SizedBox(height: AppDimensions.spaceM),
                    _LanguageOption(
                      label: 'English',
                      value: 'en',
                      selected: vm.language == 'en',
                      onSelect: () => vm.setLanguage('en'),
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

class _ResponseLengthOption extends StatelessWidget {
  final String label;
  final String description;
  final String value;
  final bool selected;
  final VoidCallback onSelect;

  const _ResponseLengthOption({
    required this.label,
    required this.description,
    required this.value,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.cyberMagenta.withValues(alpha: 0.1)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: selected ? AppColors.cyberMagenta : AppColors.glass12,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: selected ? value : 'none',
              onChanged: (_) => onSelect(),
              activeColor: AppColors.cyberMagenta,
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.onSurfaceVariant,
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

class _LanguageOption extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onSelect;

  const _LanguageOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.neonLime.withValues(alpha: 0.1)
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: selected ? AppColors.neonLime : AppColors.glass12,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: selected ? value : 'none',
              onChanged: (_) => onSelect(),
              activeColor: AppColors.neonLime,
            ),
            const SizedBox(width: AppDimensions.spaceM),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiPreferenceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accentColor;

  const _AiPreferenceCard({
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
