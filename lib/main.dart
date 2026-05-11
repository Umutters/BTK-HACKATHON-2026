import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'viewmodels/user_setup_viewmodel.dart';
import 'views/screens/onboarding screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const FortuneFlowApp());
}

class FortuneFlowApp extends StatelessWidget {
  const FortuneFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserSetupViewModel(),
      child: MaterialApp(
        title: 'FortuneFlow AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const OnboardingScreen(),
      ),
    );
  }
}
