import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatLoadMessages extends ChatEvent {
  final String squadId;

  const ChatLoadMessages(this.squadId);

  @override
  List<Object?> get props => [squadId];
}

class ChatSendMessage extends ChatEvent {
  final String content;
  final String squadId;
  final String senderName;
  final String? senderAvatarUrl;

  const ChatSendMessage({
    required this.content,
    required this.squadId,
    required this.senderName,
    this.senderAvatarUrl,
  });

  @override
  List<Object?> get props => [content, squadId, senderName, senderAvatarUrl];
}

class ChatDeleteMessage extends ChatEvent {
  final String messageId;

  const ChatDeleteMessage(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class ChatScrollToBottom extends ChatEvent {
  final bool animate;

  const ChatScrollToBottom({this.animate = true});

  @override
  List<Object?> get props => [animate];
}

class ChatToggleVisibility extends ChatEvent {
  final bool isVisible;

  const ChatToggleVisibility({required this.isVisible});

  @override
  List<Object?> get props => [isVisible];
}
