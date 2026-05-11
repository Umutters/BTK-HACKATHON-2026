import 'package:flutter/material.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../domain/entities/quest_entity.dart';
import '../molecules/quest_card.dart';
import '../molecules/section_header.dart';

class DailyQuestsSection extends StatelessWidget {
  final List<QuestEntity> quests;
  final int completedCount;
  final void Function(String questId)? onStartQuest;

  const DailyQuestsSection({
    super.key,
    required this.quests,
    required this.completedCount,
    this.onStartQuest,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pagePaddingH,
          ),
          child: SectionHeader(
            title: 'Daily Quests',
            subtitle: '$completedCount/${quests.length} COMPLETED',
          ),
        ),
        const SizedBox(height: AppDimensions.spaceL),
        SizedBox(
          height: AppDimensions.questCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
            ),
            itemCount: quests.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppDimensions.spaceL),
            itemBuilder: (context, index) {
              final quest = quests[index];
              return QuestCard(
                quest: quest,
                onStartQuest: () => onStartQuest?.call(quest.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
