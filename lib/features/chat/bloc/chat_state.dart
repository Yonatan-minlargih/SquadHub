import 'package:equatable/equatable.dart';
import '../../../core/models/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<Message> messages;
  final bool shouldScrollToBottom;
  final bool animateScroll;

  const ChatLoaded({
    required this.messages,
    this.shouldScrollToBottom = false,
    this.animateScroll = true,
  });

  ChatLoaded copyWith({
    List<Message>? messages,
    bool? shouldScrollToBottom,
    bool? animateScroll,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      shouldScrollToBottom: shouldScrollToBottom ?? this.shouldScrollToBottom,
      animateScroll: animateScroll ?? this.animateScroll,
    );
  }

  @override
  List<Object?> get props => [messages, shouldScrollToBottom, animateScroll];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}


