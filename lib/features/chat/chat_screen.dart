import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/message.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_state.dart';
import 'bloc/chat_bloc.dart';
import 'bloc/chat_event.dart';
import 'bloc/chat_state.dart';
import '../../core/widgets/empty_state.dart';
import 'chat_input.dart';
import 'message_bubble.dart';
import '../../core/services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolling = false;
  String? _squadId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    _squadId = authState.squadId;
    if (_squadId != null) {
      context.read<ChatBloc>().add(ChatLoadMessages(_squadId!));
    }
    context.read<ChatBloc>().add(const ChatToggleVisibility(isVisible: true));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isAtBottom =
          _scrollController.offset >=
          _scrollController.position.maxScrollExtent - 100;
      if (_isScrolling != !isAtBottom) {
        setState(() {
          _isScrolling = !isAtBottom;
        });
      }
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animate) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  void _handleSendMessage(String content) {
    final authState = context.read<AuthBloc>().state;
    final squadId = authState.squadId ?? _squadId;
    if (squadId == null) return;

    context.read<ChatBloc>().add(
      ChatSendMessage(
        content: content,
        squadId: squadId,
        senderName: authState.squadName ?? 'User',
        senderAvatarUrl: authState.avatarUrl,
      ),
    );
  }

  void _handleDeleteMessage(String messageId) {
    context.read<ChatBloc>().add(ChatDeleteMessage(messageId));
    if (!mounted) return;
    NotificationService().showTopNotification(
      context,
      title: 'Deleted',
      body: 'Message deleted successfully',
      icon: Icons.delete_outline,
    );
  }

  bool _shouldShowAvatar(int index, List<Message> messages) {
    if (index == 0) return true;
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    // Shows avatar if:
    // 1. Different sender
    // 2. More than 5 minutes gap
    // 3. Different day
    final timeDiff = currentMessage.timestamp.difference(
      previousMessage.timestamp,
    );
    final isDifferentSender =
        currentMessage.senderName != previousMessage.senderName;
    final isTimeGap = timeDiff.inMinutes > 5;
    final isDifferentDay =
        currentMessage.timestamp.day != previousMessage.timestamp.day ||
        currentMessage.timestamp.month != previousMessage.timestamp.month ||
        currentMessage.timestamp.year != previousMessage.timestamp.year;

    return isDifferentSender || isTimeGap || isDifferentDay;
  }

  bool _isGroupedMessage(int index, List<Message> messages) {
    if (index == 0) return false;
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];

    // Group messages if same sender and within 5 minutes
    if (currentMessage.senderName != previousMessage.senderName) return false;
    final timeDiff = currentMessage.timestamp.difference(
      previousMessage.timestamp,
    );
    return timeDiff.inMinutes <= 5;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    context.read<ChatBloc>().add(const ChatToggleVisibility(isVisible: false));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState.squadId != _squadId) {
          setState(() {
            _squadId = authState.squadId;
          });
          if (_squadId != null) {
            context.read<ChatBloc>().add(ChatLoadMessages(_squadId!));
          }
        }
      },
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatLoaded && state.shouldScrollToBottom) {
            _scrollToBottom(animate: state.animateScroll);
          } else if (state is ChatError) {
            NotificationService().showTopNotification(
              context,
              title: 'Chat Error',
              body: state.message,
              icon: Icons.error_outline,
              backgroundColor: Colors.red.shade400,
            );
          }
        },
        builder: (context, state) {
          if (state is ChatLoading) {
            return Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('Squad Chat'),
                  ],
                ),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (state is ChatError) {
            return Scaffold(
              appBar: AppBar(
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        size: 20,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('Squad Chat'),
                  ],
                ),
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Error loading messages', style: AppTextStyles.h3),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        state.message,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FilledButton.icon(
                        onPressed: () {
                          if (_squadId != null) {
                            context.read<ChatBloc>().add(
                              ChatLoadMessages(_squadId!),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final messages = state is ChatLoaded ? state.messages : <Message>[];

          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text('Squad Chat', overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${messages.length}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: _squadId == null
                      ? const EmptyState(
                          icon: Icons.people_outline,
                          title: 'No Squad Found',
                          description:
                              'You need to join or create a squad before you can chat!',
                        )
                      : messages.isEmpty
                      ? const EmptyState(
                          icon: Icons.chat_bubble_outline,
                          title: 'No messages yet',
                          description:
                              'Start the conversation by sending a message below!',
                        )
                      : Stack(
                          children: [
                            ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.only(
                                top: AppSpacing.sm,
                                bottom: AppSpacing.lg,
                                left: AppSpacing.sm,
                                right: AppSpacing.sm,
                              ),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final showAvatar = _shouldShowAvatar(
                                  index,
                                  messages,
                                );
                                final isGrouped = _isGroupedMessage(
                                  index,
                                  messages,
                                );

                                return TweenAnimationBuilder<double>(
                                  duration: Duration(
                                    milliseconds: 200 + (index * 30),
                                  ),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: Opacity(
                                        opacity: value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      bottom: isGrouped
                                          ? AppSpacing.xs
                                          : AppSpacing.sm,
                                    ),
                                    child: MessageBubble(
                                      message: message,
                                      showAvatar: showAvatar,
                                      isGrouped: isGrouped,
                                      onDelete:
                                          message.senderId ==
                                              auth
                                                  .FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid
                                          ? () =>
                                                _handleDeleteMessage(message.id)
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),

                            if (_isScrolling && messages.isNotEmpty)
                              Positioned(
                                bottom: 80,
                                right: AppSpacing.md,
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 200),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Opacity(
                                        opacity: value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: FloatingActionButton.small(
                                    onPressed: () => _scrollToBottom(),
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                    foregroundColor:
                                        theme.colorScheme.onPrimaryContainer,
                                    child: const Icon(
                                      Icons.keyboard_arrow_down,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                if (_squadId != null) ChatInput(onSend: _handleSendMessage),
              ],
            ),
          );
        },
      ),
    );
  }
}
