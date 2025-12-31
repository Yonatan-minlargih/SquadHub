import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String squadId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.squadId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromFirestore(String id, Map<String, dynamic> data) {
    return Message(
      id: id,
      squadId: data['squadId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderAvatarUrl: data['senderAvatarUrl'] as String?,
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'squadId': squadId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
