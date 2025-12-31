import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/message.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../../../core/services/notification_service.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  bool _isVisible = false;
  List<Message> _lastMessages = [];
  StreamSubscription? _messagesSubscription;

  ChatBloc() : super(const ChatInitial()) {
    on<ChatLoadMessages>(_onLoadMessages);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatDeleteMessage>(_onDeleteMessage);
    on<ChatScrollToBottom>(_onScrollToBottom);
    on<_ChatUpdateMessages>(_onUpdateMessages);
    on<_ChatHandleError>(_onHandleError);
    on<ChatToggleVisibility>(_onToggleVisibility);
  }

  void _onToggleVisibility(
    ChatToggleVisibility event,
    Emitter<ChatState> emit,
  ) {
    _isVisible = event.isVisible;
  }

  Future<void> _onLoadMessages(
    ChatLoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatLoading());
      await _messagesSubscription?.cancel();
      _messagesSubscription = _firestore
          .collection('messages')
          .where('squadId', isEqualTo: event.squadId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .listen(
            (snapshot) {
              try {
                final messages = snapshot.docs
                    .map((doc) => Message.fromFirestore(doc.id, doc.data()))
                    .toList()
                    .reversed // Return in chronological order
                    .toList();

                // Notification Logic
                if (!_isVisible && messages.isNotEmpty) {
                  final lastMsg = messages.last;
                  final currentUser = _auth.currentUser;

                  // If it's a new message and NOT from current user
                  if (currentUser != null &&
                      lastMsg.senderId != currentUser.uid &&
                      !_lastMessages.any((m) => m.id == lastMsg.id)) {
                    _notificationService.showLocalNotification(
                      title: 'New message from ${lastMsg.senderName}',
                      body: lastMsg.content,
                    );
                  }
                }

                _lastMessages = messages;
                add(_ChatUpdateMessages(messages));
              } catch (e) {
                add(_ChatHandleError(e.toString()));
              }
            },
            onError: (error) {
              add(_ChatHandleError(error.toString()));
            },
          );
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onUpdateMessages(_ChatUpdateMessages event, Emitter<ChatState> emit) {
    emit(
      ChatLoaded(
        messages: event.messages,
        shouldScrollToBottom: true,
        animateScroll: true,
      ),
    );
  }

  void _onHandleError(_ChatHandleError event, Emitter<ChatState> emit) {
    emit(ChatError(event.message));
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final message = Message(
        id: const Uuid().v4(),
        squadId: event.squadId,
        senderId: user.uid,
        senderName: event.senderName,
        senderAvatarUrl: event.senderAvatarUrl,
        content: event.content,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('messages').add(message.toFirestore());
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onDeleteMessage(
    ChatDeleteMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _firestore.collection('messages').doc(event.messageId).delete();
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onScrollToBottom(
    ChatScrollToBottom event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      emit(
        currentState.copyWith(
          shouldScrollToBottom: true,
          animateScroll: event.animate,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}

class _ChatUpdateMessages extends ChatEvent {
  final List<Message> messages;
  const _ChatUpdateMessages(this.messages);
}

class _ChatHandleError extends ChatEvent {
  final String message;
  const _ChatHandleError(this.message);
}
