import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/crisis_event_model.dart';

class CrisisEventCard extends StatelessWidget {
  final CrisisEventModel crisis;

  const CrisisEventCard({super.key, required this.crisis});

  String _formatMoney(double amount) {
    final raw = amount.toStringAsFixed(0);
    final grouped = raw.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '$grouped TL';
  }

  @override
  Widget build(BuildContext context) {
    final strategy = crisis.resolutionStrategy;
    final (badgeColor, badgeText) = switch (strategy) {
      'pool' => (AppColors.cyberBlue, 'Havuzdan'),
      'budget' => (AppColors.cyberMagenta, 'Bütçeden'),
      _ => (const Color(0xFFFFD600), 'Bekliyor'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceM,
      ),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.cyberMagenta20),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.cyberMagenta20,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.cyberMagenta,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crisis.eventName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatMoney(crisis.amount),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.cyberMagenta,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceS,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              badgeText,
              style: AppTextStyles.labelSmall.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
