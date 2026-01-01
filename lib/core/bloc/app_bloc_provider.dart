import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/bloc/theme_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/chat/bloc/chat_bloc.dart';
import '../../features/status/bloc/status_bloc.dart';
import '../../features/ledger/bloc/ledger_bloc.dart';
import '../../features/watchlist/bloc/watchlist_bloc.dart';

import '../../core/services/auth_service.dart';

class AppBlocProvider extends StatelessWidget {
  final Widget child;

  const AppBlocProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(create: (context) => ThemeBloc()),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authService: AuthService()),
        ),
        BlocProvider<ChatBloc>(create: (context) => ChatBloc()),
        BlocProvider<StatusBloc>(create: (context) => StatusBloc()),
        BlocProvider<LedgerBloc>(create: (context) => LedgerBloc()),
        BlocProvider<WatchlistBloc>(create: (context) => WatchlistBloc()),
      ],
      child: child,
    );
  }
}
