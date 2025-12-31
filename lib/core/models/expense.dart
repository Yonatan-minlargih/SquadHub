import 'user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String title;
  final String squadId;
  final double totalAmount;
  final User paidBy;
  final DateTime date;

  /// Map of user IDs to the amount they owe for this expense
  final Map<String, dynamic> splits;

  Expense({
    required this.id,
    required this.title,
    required this.squadId,
    required this.totalAmount,
    required this.paidBy,
    required this.date,
    required this.splits,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      title: data['title'] ?? '',
      squadId: data['squadId'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      paidBy: User.fromFirestore(
        data['paidBy'] as Map<String, dynamic>,
        data['paidById'] ?? '',
      ),
      date: (data['date'] as Timestamp).toDate(),
      splits: Map<String, dynamic>.from(data['splits'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'squadId': squadId,
      'totalAmount': totalAmount,
      'paidBy': paidBy.toFirestore(),
      'paidById': paidBy.id,
      'date': Timestamp.fromDate(date),
      'splits': splits,
    };
  }

  /// Factory to create an expense where everyone (including payer) splits equally
  factory Expense.equalSplit({
    required String id,
    required String title,
    required String squadId,
    required double totalAmount,
    required User paidBy,
    required List<User> members,
  }) {
    final splitAmount = totalAmount / members.length;
    final splits = {for (var u in members) u.id: splitAmount};
    return Expense(
      id: id,
      title: title,
      squadId: squadId,
      totalAmount: totalAmount,
      paidBy: paidBy,
      date: DateTime.now(),
      splits: splits,
    );
  }
}
