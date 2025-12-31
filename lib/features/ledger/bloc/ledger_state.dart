import 'package:equatable/equatable.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/user.dart';

class LedgerState extends Equatable {
  final List<Expense> expenses;
  final List<User> users;
  final Map<String, double> netBalances;
  final bool isLoading;
  final String? error;

  const LedgerState({
    this.expenses = const [],
    this.users = const [],
    this.netBalances = const {},
    this.isLoading = false,
    this.error,
  });

  LedgerState copyWith({
    List<Expense>? expenses,
    List<User>? users,
    Map<String, double>? netBalances,
    bool? isLoading,
    String? error,
  }) {
    return LedgerState(
      expenses: expenses ?? this.expenses,
      users: users ?? this.users,
      netBalances: netBalances ?? this.netBalances,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [expenses, users, netBalances, isLoading, error];
}
