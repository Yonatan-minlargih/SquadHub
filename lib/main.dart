import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/bloc/app_bloc_provider.dart';
import 'core/services/theme_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/services/guardian_alarm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive
  try {
    await Hive.initFlutter();
    await ThemeService().init();
  } catch (e) {
    debugPrint('Hive initialization failed: $e');
  }

  // 2. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stack) {
    debugPrint('Firebase initialization failed: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Firebase Initialization Failed:\n$e\n\n$stack',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // 3. Initialize Notifications & Alarm Manager
  try {
    await NotificationService().initialize();
    await GuardianAlarmService.initialize();
  } catch (e) {
    debugPrint('Service initialization failed: $e');
  }

  runApp(AppBlocProvider(child: const SquadHubApp()));
}
