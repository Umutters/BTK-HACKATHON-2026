import 'package:btk_hackathon_2026/viewmodels/navigation_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../widgets/atoms/ff_button.dart';
import '../widgets/molecules/level_progress_card.dart';
import '../widgets/organisms/ai_avatar_section.dart';
import '../widgets/organisms/daily_quests_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _AppBar(level: vm.user?.level, name: vm.user?.name),
          body: switch (vm.state) {
            HomeViewState.initial ||
            HomeViewState.loading => const _LoadingView(),
            HomeViewState.error => _ErrorView(message: vm.errorMessage),
            HomeViewState.loaded => _LoadedView(vm: vm),
          },
        );
      },
    );
  }
}

// ─── AppBar ──────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final int? level;
  final String? name;

  const _AppBar({this.level, this.name});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppDimensions.spaceL),
        child: Container(
          width: AppDimensions.levelBadgeSize,
          height: AppDimensions.levelBadgeSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonLime,
          ),
          child: Center(
            child: Text(
              'Lvl',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.background,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        name != null ? 'Merhaba, $name' : 'FortuneFlow AI',
        style: AppTextStyles.appBarTitle,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppDimensions.spaceXL),
          child: Icon(
            Icons.bolt_rounded,
            color: AppColors.neonLime,
            size: AppDimensions.iconM,
          ),
        ),
      ],
    );
  }
}

// ─── States ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.cyberBlue,
        strokeWidth: 2,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String? message;

  const _ErrorView({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pagePaddingH),
        child: Text(
          message ?? 'An error occurred',
          style: AppTextStyles.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final HomeViewModel vm;

  const _LoadedView({required this.vm});

  @override
  Widget build(BuildContext context) {
    final user = vm.user!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.spaceL),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
            ),
            child: LevelProgressCard(
              level: user.level,
              currentXp: user.currentXp,
              maxXp: user.maxXp,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXXL),
          const AiAvatarSection(),
          const SizedBox(height: AppDimensions.spaceXXL),
          DailyQuestsSection(
            quests: vm.quests,
            completedCount: vm.completedQuestsCount,
            onStartQuest: vm.startQuest,
          ),
          const SizedBox(height: AppDimensions.spaceXXL),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
            ),
            child: FfButton(
              label: 'Consult AI Oracle',
              onTap: () {
                context.read<NavigationViewModel>().setIndex(1);
              },
              variant: FfButtonVariant.primary,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: AppDimensions.space3XL),
        ],
      ),
    );
  }
}
