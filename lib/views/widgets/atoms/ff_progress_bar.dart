import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// Dual-gradient progress bar: Cyber Blue → Neon Lime with leading edge glow
class FfProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;

  const FfProgressBar({
    super.key,
    required this.progress,
    this.height = AppDimensions.progressBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.progressBackground,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.progressGradient,
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.neonLime30,
                  blurRadius: 6,
                  spreadRadius: 1,
                  offset: Offset(2, 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
