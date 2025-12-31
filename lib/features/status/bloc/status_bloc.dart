import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user.dart';
import 'status_event.dart';
import 'status_state.dart';

class StatusBloc extends Bloc<StatusEvent, StatusState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _usersSubscription;

  StatusBloc() : super(const StatusState()) {
    on<StatusLoadUsers>(_onLoadUsers);
    on<StatusUpdateUsers>(_onUpdateUsers);
    on<StatusUpdateUserStatus>(_onUpdateUserStatus);
  }

  Future<void> _onLoadUsers(
    StatusLoadUsers event,
    Emitter<StatusState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _usersSubscription?.cancel();

    _usersSubscription = _firestore
        .collection('users')
        .where('squadId', isEqualTo: event.squadId)
        .snapshots()
        .listen((snapshot) {
          final users = snapshot.docs
              .map((doc) => User.fromFirestore(doc.data(), doc.id))
              .toList();
          add(StatusUpdateUsers(users));
        });
  }

  void _onUpdateUsers(StatusUpdateUsers event, Emitter<StatusState> emit) {
    emit(state.copyWith(users: event.users, isLoading: false));
  }

  Future<void> _onUpdateUserStatus(
    StatusUpdateUserStatus event,
    Emitter<StatusState> emit,
  ) async {
    try {
      await _firestore.collection('users').doc(event.userId).update({
        'status': event.newStatus.name,
      });
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _usersSubscription?.cancel();
    return super.close();
  }
}
