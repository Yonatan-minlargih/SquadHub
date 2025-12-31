import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../core/theme/bloc/theme_bloc.dart';
import '../../core/theme/bloc/theme_event.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../auth/bloc/auth_state.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeBloc>().state.themeMode;
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final currentUser = auth.FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                (currentUser?.displayName ?? 'M').substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            accountName: Text(
              currentUser?.displayName ?? 'Squad Member',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            accountEmail: Text(
              currentUser?.email ?? 'No email',
              style: TextStyle(color: Colors.grey),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
          ListTile(
            leading: const Icon(Iconsax.user),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return ListTile(
                leading: const Icon(Iconsax.notification),
                title: const Text('Notifications'),
                trailing: Switch(
                  value: state.notificationsEnabled,
                  onChanged: (val) {
                    context.read<AuthBloc>().add(AuthToggleNotifications(val));
                  },
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(isDark ? Iconsax.moon : Iconsax.sun),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: isDark,
              onChanged: (value) {
                context.read<ThemeBloc>().add(ThemeToggled());
              },
            ),
          ),
          const Spacer(),
          if (context.read<AuthBloc>().state.squadId != null)
            ListTile(
              leading: const Icon(Iconsax.logout_1, color: Colors.orange),
              title: const Text(
                'Leave Squad',
                style: TextStyle(color: Colors.orange),
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Leave Squad?'),
                    content: const Text(
                      'Are you sure you want to leave your current squad? You can rejoin later using the Squad ID.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx); // Close dialog
                          Navigator.pop(context); // Close drawer
                          context.read<AuthBloc>().add(AuthLeaveSquad());
                        },
                        child: const Text(
                          'Leave',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ListTile(
            leading: const Icon(Iconsax.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () {
              context.read<AuthBloc>().add(AuthLogout());
              Navigator.of(context).pop(); // Just close the drawer
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
