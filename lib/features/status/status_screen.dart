import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/status_chip.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_state.dart';
import 'bloc/status_bloc.dart';
import 'bloc/status_event.dart';
import 'bloc/status_state.dart';
import 'widgets/user_status_tile.dart';
import '../../core/models/user.dart';
import '../auth/widgets/join_squad_dialog.dart';
import '../auth/widgets/create_squad_dialog.dart';
import '../../core/services/notification_service.dart';
import 'package:iconsax/iconsax.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  void _updateStatus(
    BuildContext context,
    String userId,
    UserStatus newStatus,
  ) {
    context.read<StatusBloc>().add(
      StatusUpdateUserStatus(userId: userId, newStatus: newStatus),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;

    return BlocBuilder<StatusBloc, StatusState>(
      builder: (context, state) {
        // Check if user has a squad
        final authState = context.watch<AuthBloc>().state;
        if (authState.squadId == null) {
          return EmptyState(
            icon: Iconsax.people,
            title: 'No Squad Found',
            description:
                'You are not part of any squad yet. Create one or join your team!',
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
          );
        }

        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = state.users;
        if (users.isEmpty) {
          return const EmptyState(
            icon: Icons.people_outline,
            title: 'Quiet here...',
            description:
                'No one has joined your squad yet. Invite your friends to get started!',
          );
        }

        final currentUser = users.firstWhere(
          (u) => u.id == firebaseUser?.uid,
          orElse: () => users.first,
        );
        final currentUserStatus = currentUser.status;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme),
              const SizedBox(height: AppSpacing.xl),
              _buildStatusSelector(
                context,
                theme,
                currentUser,
                currentUserStatus,
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildSquadListHeader(theme, users.length),
              const SizedBox(height: AppSpacing.md),
              ...users.map((user) {
                final isCurrentUser = user.id == currentUser.id;
                return UserStatusTile(
                  user: user,
                  isCurrentUser: isCurrentUser,
                  index: users.indexOf(user),
                );
              }),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Who\'s Free?', style: AppTextStyles.h2),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'See what your squad is up to',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildSquadIdCopy(theme),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.people_outline,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }

  Widget _buildSquadIdCopy(ThemeData theme) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState.squadId == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: authState.squadId!));
            NotificationService().showTopNotification(
              context,
              title: 'Copied',
              body: 'Squad ID copied to clipboard',
              icon: Icons.copy,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.secondary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy, size: 12, color: theme.colorScheme.secondary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'ID: ${authState.squadId}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSelector(
    BuildContext context,
    ThemeData theme,
    User currentUser,
    UserStatus currentUserStatus,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Set your status',
                style: AppTextStyles.h3.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: UserStatus.values.map((status) {
              final isSelected = currentUserStatus == status;
              return StatusChip(
                status: status,
                isSelected: isSelected,
                onTap: () => _updateStatus(context, currentUser.id, status),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSquadListHeader(ThemeData theme, int count) {
    return Row(
      children: [
        Text('Squad Status', style: AppTextStyles.h3),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.bodySmall.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
