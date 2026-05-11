import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Neon pill badge — pill-shaped, high-saturation, black text
class XpBadge extends StatelessWidget {
  final int xp;

  const XpBadge({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceXS,
      ),
      decoration: BoxDecoration(
        color: AppColors.neonLime10,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.neonLime30, width: 1),
      ),
      child: Text(
        '+$xp XP',
        style: AppTextStyles.xpText.copyWith(color: AppColors.neonLime),
      ),
    );
  }
}
