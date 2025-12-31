import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc({AuthService? authService})
    : _authService = authService ?? AuthService(),
      super(const AuthState()) {
    on<AuthSignUp>(_onSignUp);
    on<AuthCreateSquad>(_onCreateSquad);
    on<AuthJoinSquad>(_onJoinSquad);
    on<AuthLogin>(_onLogin);
    on<AuthLogout>(_onLogout);
    on<AuthAppStarted>(_onAppStarted);
    on<AuthToggleNotifications>(_onToggleNotifications);
    on<AuthLeaveSquad>(_onLeaveSquad);

    add(AuthAppStarted());
  }

  Future<void> _onAppStarted(
    AuthAppStarted event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authService.currentUser;
    if (user != null) {
      await _authService.reloadUser();
      final doc = await _authService.getUserDoc(user.uid);

      if (doc.exists) {
        final data = doc.data();
        emit(
          state.copyWith(
            isAuthenticated: true,
            isEmailVerified: true,
            squadId: data?['squadId'] as String?,
            squadName: data?['name'] as String?,
            avatarUrl: data?['avatarUrl'] as String?,
            notificationsEnabled:
                data?['notificationsEnabled'] as bool? ?? true,
            isLoading: false,
          ),
        );
      } else {
        emit(state.copyWith(isLoading: false, isAuthenticated: true));
      }
    } else {
      emit(state.copyWith(isLoading: false, isAuthenticated: false));
    }
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    await _authService.signOut();
    emit(const AuthState(isLoading: false));
  }

  Future<void> _onSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      if (event.password.length < 8) {
        emit(
          state.copyWith(
            isLoading: false,
            error: 'Password must be at least 8 characters long',
          ),
        );
        return;
      }

      final userCredential = await _authService.signUp(
        event.email,
        event.password,
      );

      final user = userCredential.user;
      if (user != null) {
        await _authService.updateDisplayName(event.name);
        await _authService.createUserDoc(
          uid: user.uid,
          name: event.name,
          email: event.email,
        );

        emit(
          state.copyWith(
            isAuthenticated: true,
            isEmailVerified: true,
            isLoading: false,
            error: 'Account created!',
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Authentication failed';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered';
      } else if (e.code == 'weak-password') {
        message = 'The password provided is too weak';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address';
      } else if (e.code == 'network-request-failed') {
        message = 'Please check your internet connection';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many requests. Please wait.';
      }
      emit(state.copyWith(isLoading: false, error: message));
    } catch (e) {
      debugPrint('Signup error: $e');
      emit(
        state.copyWith(
          isLoading: false,
          error: 'An unexpected error occurred. Please try again.',
        ),
      );
    }
  }

  Future<void> _onCreateSquad(
    AuthCreateSquad event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _authService.updateUserSquad(user.uid, event.squadId);
        emit(
          state.copyWith(
            squadId: event.squadId,
            squadName: event.squadName,
            isLoading: false,
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onJoinSquad(
    AuthJoinSquad event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final count = await _authService.getSquadMemberCount(event.squadId);
      if (count >= 12) {
        emit(
          state.copyWith(
            isLoading: false,
            error: 'Squad is full (limit: 12 members)',
          ),
        );
        return;
      }

      final user = _authService.currentUser;
      if (user != null) {
        await _authService.updateUserSquad(user.uid, event.squadId);
      }

      emit(
        state.copyWith(
          isAuthenticated: true,
          squadId: event.squadId,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final userCredential = await _authService.signIn(
        event.email,
        event.password,
      );

      final user = userCredential.user;
      if (user != null) {
        final doc = await _authService.getUserDoc(user.uid);

        if (doc.exists) {
          final data = doc.data();
          emit(
            state.copyWith(
              isAuthenticated: true,
              isEmailVerified: true,
              isLoading: false,
              squadId: data?['squadId'] as String?,
              squadName: data?['name'] as String?,
              avatarUrl: data?['avatarUrl'] as String?,
              notificationsEnabled:
                  data?['notificationsEnabled'] as bool? ?? true,
            ),
          );
        } else {
          emit(
            state.copyWith(
              isAuthenticated: true,
              isEmailVerified: true,
              isLoading: false,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Invalid email or password';
      if (e.code == 'user-disabled') message = 'This account has been disabled';
      emit(state.copyWith(isLoading: false, error: message));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onToggleNotifications(
    AuthToggleNotifications event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(notificationsEnabled: event.enabled));
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _authService.updateNotificationPreference(
          user.uid,
          event.enabled,
        );
      }
    } catch (e) {
      debugPrint('Failed to update notification preference: $e');
    }
  }

  Future<void> _onLeaveSquad(
    AuthLeaveSquad event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _authService.leaveSquad(user.uid);
        // Force state update to remove squadId
        emit(
          state.copyWith(
            isLoading: false,
            squadId: null, // Explicitly set to null
            // We use a new AuthState to ensure checking == null works if copied correctly
          ),
        );
        // Trigger AppStarted to refresh full profile if needed,
        // but explicit nulling is faster for UI response.
        add(AuthAppStarted());
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
