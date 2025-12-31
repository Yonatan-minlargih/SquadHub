import 'package:equatable/equatable.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/models/user.dart';

abstract class StatusEvent extends Equatable {
  const StatusEvent();

  @override
  List<Object?> get props => [];
}

class StatusLoadUsers extends StatusEvent {
  final String squadId;
  const StatusLoadUsers(this.squadId);

  @override
  List<Object?> get props => [squadId];
}

class StatusUpdateUsers extends StatusEvent {
  final List<User> users;
  const StatusUpdateUsers(this.users);

  @override
  List<Object?> get props => [users];
}

class StatusUpdateUserStatus extends StatusEvent {
  final String userId;
  final UserStatus newStatus;

  const StatusUpdateUserStatus({required this.userId, required this.newStatus});

  @override
  List<Object?> get props => [userId, newStatus];
}
