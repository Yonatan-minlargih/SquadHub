import '../models/user.dart';
import '../widgets/status_chip.dart';

final List<User> mockUsers = [
  User(id: '1', name: 'Yonatan', avatarUrl: 'Y'),
  User(id: '2', name: 'Mikias', avatarUrl: 'M', status: UserStatus.busy),
  User(id: '3', name: 'Amha', avatarUrl: 'A', status: UserStatus.studying),
  User(id: '4', name: 'Eyob', avatarUrl: 'E', status: UserStatus.away),
  User(id: '5', name: 'Kaleab', avatarUrl: 'K'),
];

final User currentUser = mockUsers[0];
