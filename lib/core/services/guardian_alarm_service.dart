import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class GuardianAlarmService {
  static const int alarmId = 1001;

  static Future<void> initialize() async {
    if (!kIsWeb) {
      await AndroidAlarmManager.initialize();
    }
  }

  static Future<void> scheduleEmergencyAlarm(DateTime triggerTime) async {
    if (kIsWeb) return;

    debugPrint('Scheduling emergency alarm for $triggerTime');
    await AndroidAlarmManager.oneShotAt(
      triggerTime,
      alarmId,
      triggerEmergencyCallback,
      exact: true,
      wakeup: true,
    );
  }

  static Future<void> cancelAlarm() async {
    if (kIsWeb) return;
    debugPrint('Cancelling emergency alarm');
    await AndroidAlarmManager.cancel(alarmId);
  }

  /// This must be a top-level or static function for the alarm manager
  @pragma('vm:entry-point')
  static Future<void> triggerEmergencyCallback() async {
    debugPrint('ALARM FIRED: Triggering emergency alert!');

    // Create a high-priority notification using our Builder pattern
    final notification = NotificationBuilder()
        .setTitle('🚨 EMERGENCY: Safety Timer Expired!')
        .setBody(
          'A safety timer has ended. You have been notified as a guardian.',
        )
        .setChannel('emergency_channel', 'Emergency Alerts')
        .build();

    await NotificationService().notify(911, notification);
  }
}
