import 'package:equatable/equatable.dart';
import '../../../core/models/user.dart';
import '../../../core/models/expense.dart';

abstract class LedgerEvent extends Equatable {
  const LedgerEvent();

  @override
  List<Object?> get props => [];
}

class LedgerLoadExpenses extends LedgerEvent {
  final String squadId;
  const LedgerLoadExpenses(this.squadId);

  @override
  List<Object?> get props => [squadId];
}

class LedgerAddExpense extends LedgerEvent {
  final String title;
  final String squadId;
  final Map<String, double> splits;
  final User paidBy;

  const LedgerAddExpense({
    required this.title,
    required this.squadId,
    required this.splits,
    required this.paidBy,
  });

  @override
  List<Object?> get props => [title, squadId, splits, paidBy];
}

class LedgerSettleUp extends LedgerEvent {
  final User user;
  final String squadId;

  const LedgerSettleUp({required this.user, required this.squadId});

  @override
  List<Object?> get props => [user, squadId];
}

class LedgerUpdateExpenses extends LedgerEvent {
  final List<Expense> expenses;
  const LedgerUpdateExpenses(this.expenses);
  @override
  List<Object?> get props => [expenses];
}

class LedgerUpdateUsers extends LedgerEvent {
  final List<User> users;
  const LedgerUpdateUsers(this.users);
  @override
  List<Object?> get props => [users];
}
