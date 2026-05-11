import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: AppTextStyles.headlineLarge),
        if (subtitle != null)
          Text(
            subtitle!,
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
