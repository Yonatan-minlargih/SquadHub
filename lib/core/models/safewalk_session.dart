import 'package:cloud_firestore/cloud_firestore.dart';

enum SafewalkStatus { active, completed, emergency }

class SafewalkSession {
  final String id;
  final String userId;
  final String guardianId;
  final String squadId;
  final SafewalkStatus status;
  final DateTime startTime;
  final DateTime expiryTime;
  final int durationMinutes;

  SafewalkSession({
    required this.id,
    required this.userId,
    required this.guardianId,
    required this.squadId,
    required this.status,
    required this.startTime,
    required this.expiryTime,
    required this.durationMinutes,
  });

  factory SafewalkSession.fromFirestore(Map<String, dynamic> data, String id) {
    return SafewalkSession(
      id: id,
      userId: data['userId'] ?? '',
      guardianId: data['guardianId'] ?? '',
      squadId: data['squadId'] ?? '',
      status: SafewalkStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SafewalkStatus.active,
      ),
      startTime: (data['startTime'] as Timestamp).toDate(),
      expiryTime: (data['expiryTime'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'guardianId': guardianId,
      'squadId': squadId,
      'status': status.name,
      'startTime': Timestamp.fromDate(startTime),
      'expiryTime': Timestamp.fromDate(expiryTime),
      'durationMinutes': durationMinutes,
    };
  }
}
