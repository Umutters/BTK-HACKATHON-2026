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
import 'views/main_navigation.dart';
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

  final bool onboardingDone = await _checkOnboardingDone();

  runApp(FortuneFlowApp(onboardingDone: onboardingDone));
}

/// Supabase'de profil varsa true döner, yoksa local'e bakar.
Future<bool> _checkOnboardingDone() async {
  final supabase = SupabaseService.instance;
  final userId = supabase.currentUserId;

  if (userId != null) {
    try {
      final profile = await supabase.getProfile(userId);
      if (profile != null) {
        // Supabase'den çekilen profili local cache'e yaz
        await LocalDataSource().saveProfile(profile);
        return true;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Supabase getProfile hatası: $e');
      // Supabase erişilemiyorsa local'e bak
    }
  }

  return LocalDataSource().hasProfile();
}

class FortuneFlowApp extends StatelessWidget {
  final bool onboardingDone;

  const FortuneFlowApp({super.key, required this.onboardingDone});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserSetupViewModel(),
      child: MaterialApp(
        title: 'FortuneFlow AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: onboardingDone
            ? const MainNavigation()
            : const OnboardingScreen(),
      ),
    );
  }
}
