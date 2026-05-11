import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_env.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local_datasource.dart';
import 'data/services/supabase_service.dart';
import 'viewmodels/user_setup_viewmodel.dart';
import 'views/screens/onboarding screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // SharedPreferences başlatma (platform channel hazır olmadan önce)
  LocalDataSource.sharedPrefs = await SharedPreferences.getInstance();

  // Supabase başlatma
  if (AppEnv.supabaseUrl.isNotEmpty && AppEnv.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
    await SupabaseService.instance.ensureSignedIn();
  }

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
