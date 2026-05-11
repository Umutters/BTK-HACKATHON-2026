import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../atoms/ff_progress_bar.dart';

/// Glass panel showing level + XP progress
class LevelProgressCard extends StatelessWidget {
  final int level;
  final int currentXp;
  final int maxXp;

  const LevelProgressCard({
    super.key,
    required this.level,
    required this.currentXp,
    required this.maxXp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceXXL),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level $level', style: AppTextStyles.displayMedium),
              Text(
                '${_fmt(currentXp)} / ${_fmt(maxXp)} XP',
                style: AppTextStyles.dataMono.copyWith(
                  color: AppColors.cyberBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceL),
          FfProgressBar(progress: currentXp / maxXp),
        ],
      ),
    );
  }

  String _fmt(int v) => v.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}
