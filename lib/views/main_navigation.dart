import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datasources/mock_local_datasource.dart';
import '../data/repositories/quest_repository_impl.dart';
import '../data/repositories/user_repository_impl.dart';
import '../domain/usecases/get_daily_quests_usecase.dart';
import '../domain/usecases/get_user_progress_usecase.dart';
import '../domain/usecases/start_quest_usecase.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/navigation_viewmodel.dart';
import 'screens/ai_oracle_screen.dart';
import 'screens/home_screen.dart';
import 'screens/portfolio_screen.dart';
import 'widgets/organisms/app_bottom_nav_bar.dart';

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSource = MockLocalDataSource();
    final userRepo = UserRepositoryImpl(dataSource);
    final questRepo = QuestRepositoryImpl(dataSource);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationViewModel()),
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(
            getUserProgressUseCase: GetUserProgressUseCase(userRepo),
            getDailyQuestsUseCase: GetDailyQuestsUseCase(questRepo),
            startQuestUseCase: StartQuestUseCase(questRepo),
          ),
        ),
      ],
      child: const _NavigationShell(),
    );
  }
}

class _NavigationShell extends StatelessWidget {
  const _NavigationShell();

  static const List<Widget> _screens = [
    HomeScreen(),
    AiOracleScreen(),
    PortfolioScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          body: IndexedStack(index: vm.currentIndex, children: _screens),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: vm.currentIndex,
            onTap: vm.setIndex,
          ),
        );
      },
    );
  }
}
