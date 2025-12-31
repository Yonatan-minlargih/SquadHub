import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/empty_state.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'widgets/join_squad_dialog.dart';
import 'widgets/create_squad_dialog.dart';

class JoinCreateSquadScreen extends StatelessWidget {
  const JoinCreateSquadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('SquadHub'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.logout, color: Colors.red),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogout());
            },
          ),
        ],
      ),
      body: EmptyState(
        icon: Iconsax.people,
        title: 'No Squad Found',
        description:
            'You are not part of any squad yet. Create one or join your team to get started!',
        onActionPressed: () {
          showDialog(
            context: context,
            builder: (context) => const JoinSquadDialog(),
          );
        },
        actionLabel: 'Join a Squad',
        secondaryActionLabel: 'Create New Squad',
        onSecondaryActionPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateSquadDialog(),
          );
        },
      ),
    );
  }
}
