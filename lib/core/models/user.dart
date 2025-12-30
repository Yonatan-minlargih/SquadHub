import '../widgets/status_chip.dart';

class User {
  final String id;
  final String name;
  final String avatarUrl;
  final UserStatus status;

  User({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.status = UserStatus.free,
  });

  factory User.fromFirestore(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      name: data['name'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      status: UserStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => UserStatus.free,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'name': name, 'avatarUrl': avatarUrl, 'status': status.name};
  }
}
