import 'dart:async'; // Add this for StreamSubscription
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:uuid/uuid.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/user.dart';
import 'ledger_event.dart';
import 'ledger_state.dart';

class LedgerBloc extends Bloc<LedgerEvent, LedgerState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _expensesSubscription;
  StreamSubscription? _usersSubscription;

  LedgerBloc() : super(const LedgerState()) {
    on<LedgerLoadExpenses>(_onLoadExpenses);
    on<LedgerUpdateExpenses>(_onUpdateExpenses);
    on<LedgerUpdateUsers>(_onUpdateUsers);
    on<LedgerAddExpense>(_onAddExpense);
    on<LedgerSettleUp>(_onSettleUp);
  }

  Future<void> _onLoadExpenses(
    LedgerLoadExpenses event,
    Emitter<LedgerState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _expensesSubscription?.cancel();
    await _usersSubscription?.cancel();

    // 1. Subscribe to Expenses
    _expensesSubscription = _firestore
        .collection('expenses')
        .where('squadId', isEqualTo: event.squadId)
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
          final expenses = snapshot.docs
              .map((doc) => Expense.fromFirestore(doc))
              .toList();
          add(LedgerUpdateExpenses(expenses));
        });

    // 2. Subscribe to Users
    _usersSubscription = _firestore
        .collection('users')
        .where('squadId', isEqualTo: event.squadId)
        .snapshots()
        .listen((snapshot) {
          final users = snapshot.docs
              .map((doc) => User.fromFirestore(doc.data(), doc.id))
              .toList();
          add(LedgerUpdateUsers(users));
        });
  }

  void _onUpdateExpenses(
    LedgerUpdateExpenses event,
    Emitter<LedgerState> emit,
  ) {
    final netBalances = _calculateNetBalances(event.expenses);
    emit(
      state.copyWith(
        expenses: event.expenses,
        netBalances: netBalances,
        isLoading: false,
      ),
    );
  }

  void _onUpdateUsers(LedgerUpdateUsers event, Emitter<LedgerState> emit) {
    emit(state.copyWith(users: event.users));
  }

  Map<String, double> _calculateNetBalances(List<Expense> expenses) {
    final netBalances = <String, double>{};
    for (var expense in expenses) {
      expense.splits.forEach((userId, amount) {
        if (userId != expense.paidBy.id) {
          netBalances[userId] =
              (netBalances[userId] ?? 0.0) + (amount as num).toDouble();
        }
      });
    }
    return netBalances;
  }

  Future<void> _onAddExpense(
    LedgerAddExpense event,
    Emitter<LedgerState> emit,
  ) async {
    final totalAmount = event.splits.values.fold(0.0, (sum, amt) => sum + amt);

    final newExpense = Expense(
      id: const Uuid().v4(),
      title: event.title,
      squadId: event.squadId,
      totalAmount: totalAmount,
      paidBy: event.paidBy,
      date: DateTime.now(),
      splits: event.splits,
    );

    try {
      await _firestore
          .collection('expenses')
          .doc(newExpense.id)
          .set(newExpense.toFirestore());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSettleUp(
    LedgerSettleUp event,
    Emitter<LedgerState> emit,
  ) async {
    final currentBalance = state.netBalances[event.user.id] ?? 0;
    if (currentBalance == 0) return;

    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    final currentUser = User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Me',
      avatarUrl: (firebaseUser.displayName ?? 'M').substring(0, 1),
    );

    final settleExpense = Expense(
      id: const Uuid().v4(),
      title: 'Settled up with ${event.user.name}',
      squadId: event.squadId,
      totalAmount: currentBalance.abs(),
      paidBy: currentBalance > 0 ? event.user : currentUser,
      date: DateTime.now(),
      splits: {},
    );

    try {
      await _firestore
          .collection('expenses')
          .doc(settleExpense.id)
          .set(settleExpense.toFirestore());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _expensesSubscription?.cancel();
    _usersSubscription?.cancel();
    return super.close();
  }
}
