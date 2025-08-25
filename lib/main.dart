import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'core/app.dart';
import 'core/services/notification_service.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone
  tz.initializeTimeZones();

  // Initialize dependency injection
  await di.init();

  // Initialize notifications
  final notificationService = di.sl<NotificationService>();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  runApp(const MyApp());
}
