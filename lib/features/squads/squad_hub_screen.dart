import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'dart:async';
import '../profile/profile_drawer.dart';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/widgets/app_scaffold.dart';
import '../status/status_screen.dart';
import '../ledger/ledger_screen.dart';
import '../watchlist/watchlist_screen.dart';
import '../safewalk/safewalk_screen.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/movie_notification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_state.dart';
import '../status/bloc/status_bloc.dart';
import '../status/bloc/status_event.dart';
import '../ledger/bloc/ledger_bloc.dart';
import '../ledger/bloc/ledger_event.dart';
import '../watchlist/bloc/watchlist_bloc.dart';
import '../watchlist/bloc/watchlist_event.dart';
import '../chat/bloc/chat_bloc.dart';
import '../chat/bloc/chat_event.dart';

class SquadHubScreen extends StatefulWidget {
  const SquadHubScreen({super.key});

  @override
  State<SquadHubScreen> createState() => _SquadHubScreenState();
}

class _SquadHubScreenState extends State<SquadHubScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  StreamSubscription? _alertSubscription;
  final Set<String> _alertsShown = {};

  @override
  void initState() {
    super.initState();
    _screens = [
      const StatusScreen(),
      const LedgerScreen(),
      const WatchlistScreen(),
      const SafewalkScreen(),
    ];
    _startAlertListener();
    _triggerMovieNotification();

    // Trigger initial data load if squad already exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState.squadId != null) {
        context.read<StatusBloc>().add(StatusLoadUsers(authState.squadId!));
        context.read<LedgerBloc>().add(LedgerLoadExpenses(authState.squadId!));
        context.read<WatchlistBloc>().add(
          WatchlistLoadItems(authState.squadId!),
        );
        context.read<ChatBloc>().add(ChatLoadMessages(authState.squadId!));
      }
    });
  }

  void _triggerMovieNotification() {
    // Schedule/Show movie of the day for engagement
    MovieNotificationService().scheduleMovieOfTheDay();
  }

  void _startAlertListener() {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _alertSubscription = FirebaseFirestore.instance
        .collection('safewalk_sessions')
        .where('guardianId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'emergency')
        .snapshots()
        .listen((snapshot) {
          for (final doc in snapshot.docs) {
            if (!_alertsShown.contains(doc.id)) {
              final data = doc.data();
              _showAlert(doc.id, data['userId'] ?? 'A friend');
            }
          }
        });
  }

  Future<void> _showAlert(String sessionId, String userId) async {
    _alertsShown.add(sessionId);

    // Fetch user name
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final name = userDoc.data()?['name'] ?? 'Your friend';

    if (!mounted) return;

    // Trigger Local Notification
    NotificationService().showLocalNotification(
      title: 'EMERGENCY!',
      body: '$name\'s Safewalk timer has expired!',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Iconsax.danger, color: Colors.white),
            SizedBox(width: 10),
            Text('EMERGENCY!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '$name\'s Safewalk timer has expired! They might need help.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String appBarTitle = 'SquadHub';
    List<Widget> actions = [];

    switch (_currentIndex) {
      case 0:
        appBarTitle = 'Status';
        break;
      case 1:
        appBarTitle = 'Ledger';
        actions.add(
          IconButton(
            icon: const Icon(Iconsax.add_circle),
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState.squadId != null) {
                LedgerScreen.showAddExpenseModal(context, authState.squadId!);
              }
            },
          ),
        );
        break;
      case 2:
        appBarTitle = 'Watchlist';
        actions.add(
          IconButton(
            icon: const Icon(Iconsax.add_circle),
            onPressed: () => WatchlistScreen.showAddItemModal(context),
          ),
        );
        break;
      case 3:
        appBarTitle = 'Walk Safe Anywhere';
        break;
    }

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState.squadId != null) {
          context.read<StatusBloc>().add(StatusLoadUsers(authState.squadId!));
          context.read<LedgerBloc>().add(
            LedgerLoadExpenses(authState.squadId!),
          );
          context.read<WatchlistBloc>().add(
            WatchlistLoadItems(authState.squadId!),
          );
          context.read<ChatBloc>().add(ChatLoadMessages(authState.squadId!));
        }
      },
      child: AppScaffold(
        drawer: const ProfileDrawer(),
        extendBody: true,
        appBar: AppBar(
          title: Text(appBarTitle),
          centerTitle: true,
          actions: actions,
        ),
        body: _screens[_currentIndex],
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/chat');
          },
          backgroundColor: isDark ? Colors.white : Colors.black,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: const CircleBorder(),
          elevation: 8,
          child: const Icon(Iconsax.message),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.zero,
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  0,
                  Iconsax.people,
                  Iconsax.people5,
                  'Status',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  1,
                  Iconsax.wallet_1,
                  Iconsax.wallet_1,
                  'Ledger',
                ),
              ),
              const SizedBox(width: 64),
              Expanded(
                child: _buildNavItem(
                  2,
                  Iconsax.video_circle,
                  Iconsax.video_circle5,
                  'Watchlist',
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  3,
                  Iconsax.shield,
                  Iconsax.shield_security,
                  'Safe Walk',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
