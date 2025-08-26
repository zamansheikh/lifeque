import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as timezone;
import 'core/app.dart';
import 'core/services/notification_service.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 App starting...');

  // Initialize timezone
  tz.initializeTimeZones();

  // Set the local timezone to Bangladesh (Asia/Dhaka)
  timezone.setLocalLocation(timezone.getLocation('Asia/Dhaka'));
  print('🌍 Timezone initialized and set to Asia/Dhaka (Bangladesh)');
  print('🕐 Current local time: ${timezone.TZDateTime.now(timezone.local)}');

  // Initialize dependency injection
  await di.init();
  print('💉 Dependency injection initialized');

  // Initialize notifications
  final notificationService = di.sl<NotificationService>();
  print('🔔 NotificationService instance obtained');

  await notificationService.initialize();
  print('🔔 NotificationService initialized');

  await notificationService.requestPermissions();
  print('🔔 NotificationService permissions requested');

  // Test simple scheduled notification
  await notificationService.scheduleSimpleTestNotification();
  print('🔔 Simple test notification scheduled');

  print('🎯 Running app...');
  runApp(const MyApp());
}
