import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLogin extends AuthEvent {
  final String email;
  final String password;

  const AuthLogin({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthAppStarted extends AuthEvent {}

class AuthLogout extends AuthEvent {}

class AuthSignUp extends AuthEvent {
  final String name;
  final String email;
  final String password;

  const AuthSignUp({
    required this.name,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [name, email, password];
}

class AuthCreateSquad extends AuthEvent {
  final String squadName;
  final String squadId;

  const AuthCreateSquad({required this.squadName, required this.squadId});

  @override
  List<Object?> get props => [squadName, squadId];
}

class AuthJoinSquad extends AuthEvent {
  final String squadId;

  const AuthJoinSquad(this.squadId);

  @override
  List<Object?> get props => [squadId];
}

class AuthToggleNotifications extends AuthEvent {
  final bool enabled;
  const AuthToggleNotifications(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class AuthLeaveSquad extends AuthEvent {}
