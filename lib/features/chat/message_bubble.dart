import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../core/models/message.dart';
import '../../core/services/notification_service.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool showAvatar;
  final bool isGrouped;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.isGrouped = false,
    this.onDelete,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isMe = false;

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    _isMe = widget.message.senderId == currentUser?.uid;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: Offset(_isMe ? 0.5 : -0.5, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message.senderId != oldWidget.message.senderId) {
      final currentUser = FirebaseAuth.instance.currentUser;
      setState(() {
        _isMe = widget.message.senderId == currentUser?.uid;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showMessageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy message'),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: widget.message.content),
                  );
                  Navigator.pop(context);
                  NotificationService().showTopNotification(
                    context,
                    title: 'Copied',
                    body: 'Message copied to clipboard',
                    icon: Icons.copy,
                  );
                },
              ),
              if (_isMe && widget.onDelete != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete message',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onDelete?.call();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('MMM d, yyyy');
    final now = DateTime.now();
    final messageDate = widget.message.timestamp;
    final isToday =
        now.year == messageDate.year &&
        now.month == messageDate.month &&
        now.day == messageDate.day;

    final showDate = !isToday;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          crossAxisAlignment: _isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (showDate)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  dateFormat.format(messageDate),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: _isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar for received messages
                  if (!_isMe && widget.showAvatar && !widget.isGrouped)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer,
                          image:
                              widget.message.senderAvatarUrl != null &&
                                  widget.message.senderAvatarUrl!.startsWith(
                                    'http',
                                  )
                              ? DecorationImage(
                                  image: NetworkImage(
                                    widget.message.senderAvatarUrl!,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            widget.message.senderAvatarUrl == null ||
                                !widget.message.senderAvatarUrl!.startsWith(
                                  'http',
                                )
                            ? Center(
                                child: Text(
                                  widget.message.senderName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    )
                  else if (!_isMe && !widget.showAvatar)
                    const SizedBox(width: 40), // Spacer when avatar is hidden
                  // Message bubble
                  Flexible(
                    child: GestureDetector(
                      onLongPress: () => _showMessageMenu(context),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: _isMe
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(_isMe ? 18 : 4),
                            bottomRight: Radius.circular(_isMe ? 4 : 18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sender name for received messages
                            if (!_isMe && !widget.isGrouped) ...[
                              Text(
                                widget.message.senderName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            // Message content
                            Text(
                              widget.message.content,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Avatar for sent messages
                  if (_isMe && widget.showAvatar && !widget.isGrouped)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          widget.message.senderName
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else if (_isMe && !widget.showAvatar)
                    const SizedBox(width: 40), // Spacer when avatar is hidden
                  // Timestamp under message bubble
                  Padding(
                    padding: EdgeInsets.only(
                      left: _isMe ? AppSpacing.xs : 0,
                      right: _isMe ? 0 : AppSpacing.xs,
                    ),
                    child: Text(
                      timeFormat.format(widget.message.timestamp),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
