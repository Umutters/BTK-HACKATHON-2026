import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../atoms/glowing_ring.dart';

/// AI Oracle avatar with concentric neon rings and glass circle
class AiAvatarSection extends StatelessWidget {
  const AiAvatarSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 270,
        height: 270,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer rings — alternating cyber blue / neon lime
            GlowingRing(
              size: 270,
              glowColor: AppColors.cyberBlue,
              strokeWidth: 0.8,
            ),
            GlowingRing(
              size: 238,
              glowColor: AppColors.neonLime,
              strokeWidth: 1.2,
            ),
            GlowingRing(
              size: 206,
              glowColor: AppColors.cyberBlue,
              strokeWidth: 0.8,
            ),
            // Glass avatar circle
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh,
                border: Border.all(color: AppColors.neonLime, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.neonLime30,
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: AppColors.cyberBlue20,
                    blurRadius: 56,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 80,
                color: AppColors.cyberBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
