import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/datasources/local_datasource.dart';
import '../data/repositories/quest_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../domain/usecases/complete_quest_usecase.dart';
import '../domain/usecases/get_daily_quests_usecase.dart';
import '../domain/usecases/get_user_progress_usecase.dart';
import '../domain/usecases/start_quest_usecase.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';
import '../viewmodels/oracle_viewmodel.dart';
import '../viewmodels/recurring_rules_viewmodel.dart';
import '../viewmodels/simulation_viewmodel.dart';
import 'screens/ai_oracle_screen.dart';
import 'screens/home_screen.dart';
import 'screens/simulation_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/organisms/app_bottom_nav_bar.dart';
import 'widgets/organisms/quick_expense_sheet.dart';

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSource = LocalDataSource();
    final userRepo = UserRepositoryImpl(dataSource);
    final questRepo = QuestRepositoryImpl();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(
            getUserProgressUseCase: GetUserProgressUseCase(userRepo),
            getDailyQuestsUseCase: GetDailyQuestsUseCase(questRepo),
            startQuestUseCase: StartQuestUseCase(questRepo),
            completeQuestUseCase: CompleteQuestUseCase(questRepo),
          ),
        ),
        ChangeNotifierProvider(
          lazy: true,
          create: (_) => SimulationViewModel(),
        ),
        ChangeNotifierProvider(
          lazy: true,
          create: (_) => RecurringRulesViewModel(),
        ),
        ChangeNotifierProvider(lazy: true, create: (_) => OracleViewModel()),
      ],
      child: const _NavigationShell(),
    );
  }
}

class _NavigationShell extends StatefulWidget {
  const _NavigationShell();

  @override
  State<_NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<_NavigationShell> {
  final Map<int, Widget> _screenCache = {0: const HomeScreen()};

  Widget _buildScreen(int index) {
    return switch (index) {
      0 => const HomeScreen(),
      1 => const AiOracleScreen(),
      2 => const SimulationScreen(),
      3 => const SettingsScreen(),
      _ => const HomeScreen(),
    };
  }

  List<Widget> _buildIndexedChildren(int currentIndex) {
    _screenCache.putIfAbsent(currentIndex, () => _buildScreen(currentIndex));

    return List<Widget>.generate(4, (index) {
      return _screenCache[index] ?? const SizedBox.shrink();
    });
  }

  Future<void> _showTransactionSheet(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final result = await showModalBottomSheet<QuickTransactionResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const QuickExpenseSheet(),
    );

    if (result != null && context.mounted) {
      final homeVm = context.read<HomeViewModel>();
      homeVm.applyTransactionDelta(result.balanceDelta);
      await homeVm.processSavingsTransfer(result.transferredToSavings);
      await homeVm.refreshTransactions();
      await context.read<OracleViewModel>().refreshContextSilently();
      if (_screenCache.containsKey(2)) {
        await context.read<SimulationViewModel>().refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationViewModel>(
      builder: (context, vm, _) {
        final screens = _buildIndexedChildren(vm.currentIndex);
        return Scaffold(
          extendBody: true,
          body: IndexedStack(index: vm.currentIndex, children: screens),
          floatingActionButton: vm.currentIndex != 0
              ? null
              : AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  offset: vm.fabVisible ? Offset.zero : const Offset(0, 2.5),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: vm.fabVisible ? 1.0 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66DEFF9A),
                            blurRadius: 22,
                            spreadRadius: 2,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        onPressed: () => _showTransactionSheet(context),
                        backgroundColor: const Color(0xFFDEFF9A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.black,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: vm.currentIndex,
            onTap: vm.setIndex,
          ),
        );
      },
    );
  }
}
