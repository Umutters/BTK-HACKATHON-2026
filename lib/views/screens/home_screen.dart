import 'package:btk_hackathon_2026/viewmodels/navigation_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/recurring_transaction_model.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../widgets/atoms/ff_button.dart';
import '../widgets/molecules/level_progress_card.dart';
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
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppDimensions.spaceL),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh,
                border: Border.all(color: AppColors.neonLime30, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cyberBlue20,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: AppColors.cyberBlue,
                size: 22,
              ),
            ),
          ],
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
          const SizedBox(height: AppDimensions.spaceL),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
            ),
            child: _BalanceSpotlightCard(
              currentBalance: vm.currentBalance,
              savingsPool: vm.savingsPool,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePaddingH,
            ),
            child: _TransactionsCard(
              transactions: vm.recentTransactions,
              allTransactions: vm.allTransactions,
            ),
          ),
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

class _BalanceSpotlightCard extends StatelessWidget {
  final double currentBalance;
  final double savingsPool;

  const _BalanceSpotlightCard({
    required this.currentBalance,
    required this.savingsPool,
  });

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        gradient: const LinearGradient(
          colors: [Color(0x221A1A1A), Color(0x1A00E5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.cyberBlue15),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cyberBlue20,
            blurRadius: 24,
            spreadRadius: 1,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.cyberBlue10,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.cyberBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.spaceM),
              Text(
                'BALANCE',
                style: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.cyberBlueDim,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            _formatMoney(currentBalance),
            style: AppTextStyles.displayMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceM),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceM,
              vertical: AppDimensions.spaceS,
            ),
            decoration: BoxDecoration(
              color: AppColors.neonLime10,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(color: AppColors.neonLime30),
            ),
            child: Text(
              'Savings Pool: ${_formatMoney(savingsPool)}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.neonLime,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsCard extends StatelessWidget {
  final List<RecurringTransactionModel> transactions;
  final List<RecurringTransactionModel> allTransactions;

  const _TransactionsCard({
    required this.transactions,
    required this.allTransactions,
  });

  String _formatMoney(double amount) {
    final raw = amount.toStringAsFixed(0);
    final grouped = raw.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '$grouped TL';
  }

  Future<void> _showAll(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllTransactionsSheet(transactions: allTransactions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.glass08,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.glass12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton(
                onPressed: allTransactions.isEmpty
                    ? null
                    : () => _showAll(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.cyberBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceS,
                    vertical: AppDimensions.spaceXS,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Hepsini Goster',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.cyberBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'SON ISLEMLER',
                style: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceM),
          if (transactions.isEmpty)
            Text(
              'Henuz islem yok. FAB ile gelir veya gider ekleyebilirsin.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            ...transactions.map(
              (tx) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.spaceS),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceM,
                    vertical: AppDimensions.spaceS,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tx.isIncome
                            ? Icons.arrow_downward_rounded
                            : tx.isSaving
                            ? Icons.savings_rounded
                            : Icons.arrow_upward_rounded,
                        color: tx.isIncome
                            ? AppColors.neonLime
                            : tx.isSaving
                            ? AppColors.cyberBlue
                            : AppColors.cyberMagenta,
                        size: AppDimensions.iconS,
                      ),
                      const SizedBox(width: AppDimensions.spaceS),
                      Expanded(
                        child: Text(
                          tx.category,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${tx.isIncome
                            ? '+'
                            : tx.isSaving
                            ? '→'
                            : '-'}${_formatMoney(tx.amount)}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: tx.isIncome
                              ? AppColors.neonLime
                              : tx.isSaving
                              ? AppColors.cyberBlue
                              : AppColors.cyberMagenta,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AllTransactionsSheet extends StatelessWidget {
  final List<RecurringTransactionModel> transactions;

  const _AllTransactionsSheet({required this.transactions});

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
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: AppColors.surfaceContainerLowest,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePaddingH,
              AppDimensions.spaceL,
              AppDimensions.pagePaddingH,
              AppDimensions.spaceL,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.glass15,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceL),
                Text('Tum Islemler', style: AppTextStyles.titleLarge),
                const SizedBox(height: AppDimensions.spaceL),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDimensions.spaceS),
                    itemBuilder: (_, index) {
                      final tx = transactions[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spaceM,
                          vertical: AppDimensions.spaceS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.glass08,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusM,
                          ),
                          border: Border.all(color: AppColors.glass12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tx.isIncome
                                  ? Icons.arrow_downward_rounded
                                  : tx.isSaving
                                  ? Icons.savings_rounded
                                  : Icons.arrow_upward_rounded,
                              color: tx.isIncome
                                  ? AppColors.neonLime
                                  : tx.isSaving
                                  ? AppColors.cyberBlue
                                  : AppColors.cyberMagenta,
                              size: AppDimensions.iconS,
                            ),
                            const SizedBox(width: AppDimensions.spaceS),
                            Expanded(
                              child: Text(
                                tx.category,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${tx.isIncome
                                  ? '+'
                                  : tx.isSaving
                                  ? '→'
                                  : '-'}${_formatMoney(tx.amount)}',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: tx.isIncome
                                    ? AppColors.neonLime
                                    : tx.isSaving
                                    ? AppColors.cyberBlue
                                    : AppColors.cyberMagenta,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
