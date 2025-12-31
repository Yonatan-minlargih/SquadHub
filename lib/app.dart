import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/bloc/theme_bloc.dart';
import 'core/theme/bloc/theme_state.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_state.dart';
import 'routes/app_routes.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/squads/squad_hub_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/chat/chat_screen.dart';
import 'core/widgets/loading_screen.dart';
import 'features/auth/join_create_squad_screen.dart';

class SquadHubApp extends StatelessWidget {
  const SquadHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return MaterialApp(
          title: 'SquadHub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeState.themeMode,
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState.isLoading) {
                return const LoadingScreen();
              }

              if (authState.isAuthenticated) {
                if (authState.squadId != null) {
                  return const SquadHubScreen();
                } else {
                  return const JoinCreateSquadScreen();
                }
              } else {
                return const OnboardingScreen();
              }
            },
          ),
          routes: {
            AppRoutes.onboarding: (context) => const OnboardingScreen(),
            AppRoutes.login: (context) => const LoginScreen(),
            AppRoutes.squadHub: (context) => const SquadHubScreen(),
            AppRoutes.profile: (context) => const ProfileScreen(),
            AppRoutes.chat: (context) => const ChatScreen(),
          },
        );
      },
    );
  }
}
