import 'package:flutter/material.dart';
import '../auth/bloc/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/user.dart';
import 'bloc/ledger_bloc.dart';
import 'bloc/ledger_event.dart';
import 'bloc/ledger_state.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/services/notification_service.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  void _showSettleUpConfirmation(
    BuildContext context,
    User user,
    double amount,
    bool isIOwe,
    NumberFormat currencyFormat,
    String squadId,
  ) {
    final message = isIOwe
        ? 'Mark as settled with ${user.name}?\nYou owe them ${currencyFormat.format(amount)}'
        : 'Mark as settled with ${user.name}?\nThey owe you ${currencyFormat.format(amount)}';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Settlement'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              dialogContext.read<LedgerBloc>().add(
                LedgerSettleUp(
                  user: user,
                  squadId: squadId,
                  amount: amount,
                  isIOwe: isIOwe,
                ),
              );
              NotificationService().showTopNotification(
                context,
                title: 'Settled Up',
                body: 'Settled with ${user.name}!',
                icon: Icons.check_circle_outline,
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  double _calculatePairwiseBalance(
    List<dynamic> expenses,
    String myId,
    String theirId,
  ) {
    double balance = 0.0;
    for (var expense in expenses) {
      if (expense.paidBy.id == myId) {
        // I paid, they borrowed -> They owe me (Positive)
        balance += (expense.splits[theirId] as num? ?? 0.0).toDouble();
      } else if (expense.paidBy.id == theirId) {
        // They paid, I borrowed -> I owe them (Negative)
        balance -= (expense.splits[myId] as num? ?? 0.0).toDouble();
      }
    }
    return balance;
  }

  static void showAddExpenseModal(BuildContext context, String squadId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AddExpenseSheet(squadId: squadId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ');

    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    final currentUser = User(
      id: firebaseUser?.uid ?? 'anon',
      name: firebaseUser?.displayName ?? 'Me',
      avatarUrl: (firebaseUser?.displayName ?? 'M').substring(0, 1),
    );

    final authState = context.watch<AuthBloc>().state;
    final squadId = authState.squadId ?? '';

    return BlocListener<LedgerBloc, LedgerState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: BlocBuilder<LedgerBloc, LedgerState>(
        builder: (context, state) {
          if (state.isLoading && state.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeDebts = state.users
              .where((u) => u.id != currentUser.id)
              .toList();

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SplitIt', style: AppTextStyles.h2),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Track shared expenses',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Friends Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Text('Friends', style: AppTextStyles.h3),
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
                            '${activeDebts.length}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Friends List
                SliverToBoxAdapter(
                  child: activeDebts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.lg,
                          ),
                          child: EmptyState(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'All Settled Up!',
                            description:
                                'No active debts in your squad right now. Great job!',
                          ),
                        )
                      : SizedBox(
                          height: 160,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: activeDebts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final user = activeDebts[index];
                              // Calculate DIRECT pairwise balance
                              final balance = _calculatePairwiseBalance(
                                state.expenses,
                                currentUser.id,
                                user.id,
                              );

                              final isOwed =
                                  balance > 0; // Positive = They owe me
                              final isDebt =
                                  balance < 0; // Negative = I owe them
                              final isSettled = balance == 0;

                              return TweenAnimationBuilder<double>(
                                duration: Duration(
                                  milliseconds: 200 + (index * 50),
                                ),
                                tween: Tween(begin: 0.0, end: 1.0),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: 0.9 + (0.1 * value),
                                    child: Opacity(
                                      opacity: value,
                                      child: child,
                                    ),
                                  );
                                },
                                child: GestureDetector(
                                  onTap: isSettled
                                      ? null
                                      : () => _showSettleUpConfirmation(
                                          context,
                                          user,
                                          balance.abs(),
                                          isDebt,
                                          currencyFormat,
                                          squadId,
                                        ),
                                  child: Container(
                                    width: 110,
                                    padding: const EdgeInsets.all(
                                      AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSettled
                                            ? Colors.grey.withValues(alpha: 0.3)
                                            : (isOwed
                                                  ? Colors.green
                                                  : Colors.red),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 28,
                                          backgroundColor: theme
                                              .colorScheme
                                              .primaryContainer,
                                          child: Text(
                                            user.avatarUrl,
                                            style: TextStyle(
                                              color: theme
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          user.name.split(' ').first,
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (isSettled)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Settled',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ),
                                        if (isOwed)
                                          Column(
                                            children: [
                                              Text(
                                                'owes you',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                currencyFormat.format(balance),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        if (isDebt)
                                          Column(
                                            children: [
                                              Text(
                                                'you owe',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                currencyFormat.format(
                                                  balance.abs(),
                                                ),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                // Recent Activity Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Text('Recent Activity', style: AppTextStyles.h3),
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
                            '${state.expenses.length}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Expenses List
                state.expenses.isEmpty
                    ? SliverToBoxAdapter(
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No activity yet',
                          description:
                              'Your squad\'s shared expenses will appear here.',
                          onActionPressed: () =>
                              LedgerScreen.showAddExpenseModal(
                                context,
                                squadId,
                              ),
                          actionLabel: 'Add Expense',
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final expense = state.expenses[index];
                          final isMe = expense.paidBy.id == currentUser.id;
                          return TweenAnimationBuilder<double>(
                            duration: Duration(
                              milliseconds: 200 + (index * 30),
                            ),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(opacity: value, child: child),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 4,
                              ),
                              child: Card(
                                margin: EdgeInsets.zero,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    child: Text(
                                      expense.paidBy.avatarUrl,
                                      style: TextStyle(
                                        color: theme
                                            .colorScheme
                                            .onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    expense.title,
                                    style: AppTextStyles.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.xs,
                                    ),
                                    child: Text(
                                      '${isMe ? 'You' : expense.paidBy.name} paid • ${DateFormat.MMMd().format(expense.date)}',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      currencyFormat.format(
                                        expense.totalAmount,
                                      ),
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }, childCount: state.expenses.length),
                      ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddExpenseSheet extends StatefulWidget {
  final String squadId;

  const _AddExpenseSheet({required this.squadId});

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _titleController = TextEditingController();
  final Map<String, TextEditingController> _splitControllers = {};

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        final firebaseUser = auth.FirebaseAuth.instance.currentUser;
        final currentUser = User(
          id: firebaseUser?.uid ?? 'anon',
          name: firebaseUser?.displayName ?? 'Me',
          avatarUrl: (firebaseUser?.displayName ?? 'M').substring(0, 1),
        );

        // Filter other users
        final otherUsers = state.users
            .where((u) => u.id != currentUser.id)
            .toList();

        // Ensure controllers exist for all users
        for (var user in otherUsers) {
          if (!_splitControllers.containsKey(user.id)) {
            _splitControllers[user.id] = TextEditingController();
          }
        }

        double totalAmt = _splitControllers.values.fold(0.0, (sum, ctrl) {
          return sum + (double.tryParse(ctrl.text) ?? 0.0);
        });

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Add Expense', style: AppTextStyles.h2),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Expense Title',
                    hintText: 'e.g. Pizza, Rent, Uber',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Who owes you?', style: AppTextStyles.h3),
                const SizedBox(height: AppSpacing.sm),
                if (state.isLoading && otherUsers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (otherUsers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'No other squad members found.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  )
                else
                  ...otherUsers.map((user) {
                    final controller = _splitControllers[user.id]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Text(
                              user.avatarUrl,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              user.name,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                prefixText: 'ETB ',
                                hintText: '0.0',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const Divider(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount', style: AppTextStyles.h3),
                    Text(
                      'ETB ${totalAmt.toStringAsFixed(2)}',
                      style: AppTextStyles.h3.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: totalAmt > 0 && _titleController.text.isNotEmpty
                      ? () {
                          final Map<String, double> finalSplits = {};
                          _splitControllers.forEach((userId, ctrl) {
                            final amt = double.tryParse(ctrl.text) ?? 0.0;
                            if (amt > 0) {
                              finalSplits[userId] = amt;
                            }
                          });

                          context.read<LedgerBloc>().add(
                            LedgerAddExpense(
                              title: _titleController.text,
                              squadId: widget.squadId,
                              splits: finalSplits,
                              paidBy: currentUser,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      : null,
                  child: const Text('Save Expense'),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}
