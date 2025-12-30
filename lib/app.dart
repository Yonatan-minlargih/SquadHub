import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/squads/squad_hub_screen.dart';
import 'features/profile/profile_screen.dart';

class SquadHubApp extends StatelessWidget {
  const SquadHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SquadHub',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.onboarding,
      routes: {
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.squadHub: (context) => const SquadHubScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
      },
    );
  }
}
