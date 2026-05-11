import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/entities/quest_entity.dart';
import '../atoms/ff_button.dart';
import '../atoms/xp_badge.dart';

/// Glass quest card — glassmorphic panel with cyber blue icon bg
class QuestCard extends StatelessWidget {
  final QuestEntity quest;
  final VoidCallback? onStartQuest;

  const QuestCard({super.key, required this.quest, this.onStartQuest});

  @override
  Widget build(BuildContext context) {
    final isActive = quest.status == QuestStatus.inProgress;
    return Container(
      width: AppDimensions.questCardWidth,
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glass05,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: isActive ? AppColors.cyberBlue : AppColors.glass12,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _QuestIcon(iconName: quest.iconName),
              XpBadge(xp: quest.xpReward),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            quest.title,
            style: AppTextStyles.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            quest.description,
            style: AppTextStyles.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          FfButton(
            label: _label(quest.status),
            onTap: quest.status == QuestStatus.notStarted ? onStartQuest : null,
            variant: FfButtonVariant.outlined,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  String _label(QuestStatus s) => switch (s) {
    QuestStatus.inProgress => 'IN PROGRESS',
    QuestStatus.completed => 'COMPLETED',
    QuestStatus.notStarted => 'START QUEST',
  };
}

class _QuestIcon extends StatelessWidget {
  final String iconName;

  const _QuestIcon({required this.iconName});

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (iconName) {
      'bar_chart' => Icons.bar_chart_rounded,
      'savings' => Icons.savings_rounded,
      'trending_up' => Icons.trending_up_rounded,
      _ => Icons.stars_rounded,
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.cyberBlue10,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.cyberBlue20, width: 1),
      ),
      child: Icon(icon, color: AppColors.cyberBlue, size: AppDimensions.iconM),
    );
  }
}
