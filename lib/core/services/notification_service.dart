import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// A class that mimics the Android Notification.Builder pattern
class NotificationBuilder {
  String? _title;
  String? _body;
  String _channelId = 'squadhub_channel';
  String _channelName = 'SquadHub Notifications';
  Importance _importance = Importance.max;
  Priority _priority = Priority.high;

  NotificationBuilder setTitle(String title) {
    _title = title;
    return this;
  }

  NotificationBuilder setBody(String body) {
    _body = body;
    return this;
  }

  NotificationBuilder setChannel(String id, String name) {
    _channelId = id;
    _channelName = name;
    return this;
  }

  NotificationBuilder setImportance(Importance importance) {
    _importance = importance;
    return this;
  }

  NotificationBuilder setPriority(Priority priority) {
    _priority = priority;
    return this;
  }

  Notification build() {
    return Notification(
      title: _title ?? 'Default Title',
      body: _body ?? '',
      channelId: _channelId,
      channelName: _channelName,
      importance: _importance,
      priority: _priority,
    );
  }
}

class Notification {
  final String title;
  final String body;
  final String channelId;
  final String channelName;
  final Importance importance;
  final Priority priority;

  Notification({
    required this.title,
    required this.body,
    required this.channelId,
    required this.channelName,
    required this.importance,
    required this.priority,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Request permissions (Safe on all platforms)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');

      // 2. Get FCM Token (Web requires VAPID key often, or it hangs)
      try {
        String? token;
        if (kIsWeb) {
          // token = await _fcm.getToken(VAPID_KEY");
        } else {
          token = await _fcm.getToken();
        }

        if (token != null) {
          await _saveTokenToFirestore(token);
        }
      } catch (e) {
        debugPrint('Failed to get FCM token: $e');
      }
    }

    // 3. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    try {
      await _localNotifications.initialize(initializationSettings);
    } catch (e) {
      debugPrint('Local notifications initialization failed: $e');
    }

    // 4. Handle Background messages (Mobile only)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
    }

    // 5. Handle Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        showLocalNotification(
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
        );
      }
    });
  }

  /// The NotificationManager equivalent in this architecture
  Future<void> notify(int id, Notification notification) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final enabled = userDoc.data()?['notificationsEnabled'] as bool? ?? true;
      if (!enabled) return;
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          notification.channelId,
          notification.channelName,
          importance: notification.importance,
          priority: notification.priority,
          showWhen: true,
        );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      id,
      notification.title,
      notification.body,
      platformChannelSpecifics,
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    final notification = NotificationBuilder()
        .setTitle(title)
        .setBody(body)
        .build();
    await notify(DateTime.now().millisecond, notification);
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'notificationsEnabled': true,
      }, SetOptions(merge: true));
    }
  }

  Future<void> updateNotificationPreference(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'notificationsEnabled': enabled},
      );
    }
  }

  /// Shows a notification at the top of the screen using an Overlay
  void showTopNotification(
    BuildContext context, {
    required String title,
    required String body,
    IconData? icon,
    Color? backgroundColor,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              tween: Tween(begin: -100.0, end: 0.0),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          backgroundColor ?? theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon ?? Icons.notifications_active,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                body,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          onPressed: () => overlayEntry.remove(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);

    // Auto-remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

// Global background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}
