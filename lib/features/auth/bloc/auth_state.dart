import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final bool isAuthenticated;
  final bool isEmailVerified;
  final String? squadId;
  final String? squadName;
  final String? avatarUrl;
  final bool isLoading;
  final String? error;
  final bool notificationsEnabled;

  const AuthState({
    this.isAuthenticated = false,
    this.isEmailVerified = true,
    this.squadId,
    this.squadName,
    this.avatarUrl,
    this.isLoading = true,
    this.error,
    this.notificationsEnabled = true,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isEmailVerified,
    String? squadId,
    String? squadName,
    String? avatarUrl,
    bool? isLoading,
    String? error,
    bool? notificationsEnabled,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      squadId: squadId ?? this.squadId,
      squadName: squadName ?? this.squadName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [
    isAuthenticated,
    isEmailVerified,
    squadId,
    squadName,
    avatarUrl,
    isLoading,
    error,
    notificationsEnabled,
  ];
}
