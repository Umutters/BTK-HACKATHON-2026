import 'package:flutter/material.dart';

import '../main_navigation.dart';

/// Thin wrapper that carries setup data from onboarding into MainNavigation.
/// User setup data is now accessible via UserSetupViewModel (provided globally).
class MainNavigationWrapper extends StatelessWidget {
  const MainNavigationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigation();
  }
}
