import 'package:equatable/equatable.dart';
import '../../../core/models/user.dart';

class StatusState extends Equatable {
  final List<User> users;
  final bool isLoading;
  final String? error;

  const StatusState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  StatusState copyWith({List<User>? users, bool? isLoading, String? error}) {
    return StatusState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [users, isLoading, error];
}
