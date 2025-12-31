import '../models/expense.dart';
import './mock_users.dart';

final List<Expense> mockExpenses = [
  Expense(
    id: '1',
    title: 'Pizza',
    squadId: 'mock-squad-1',
    totalAmount: 450.0,
    paidBy: mockUsers[0], // Yonatan
    date: DateTime.now().subtract(const Duration(days: 1)),
    splits: {'2': 150.0, '3': 150.0, '4': 150.0},
  ),
  Expense(
    id: '2',
    title: 'Ride to Campus',
    squadId: 'mock-squad-1',
    totalAmount: 120.0,
    paidBy: mockUsers[1], // Mikias
    date: DateTime.now().subtract(const Duration(days: 2)),
    splits: {'1': 60.0, '5': 60.0},
  ),
  Expense(
    id: '3',
    title: 'Cookies',
    squadId: 'mock-squad-1',
    totalAmount: 800.0,
    paidBy: mockUsers[2], // Amha
    date: DateTime.now().subtract(const Duration(days: 3)),
    splits: {'1': 400.0, '2': 400.0},
  ),
];
