import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as timezone;
import 'core/app.dart';
import 'core/services/notification_service.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀 App starting...');

  // Initialize timezone
  tz.initializeTimeZones();

  // Set the local timezone to Bangladesh (Asia/Dhaka)
  timezone.setLocalLocation(timezone.getLocation('Asia/Dhaka'));
  debugPrint('🌍 Timezone initialized and set to Asia/Dhaka (Bangladesh)');
  debugPrint(
    '🕐 Current local time: ${timezone.TZDateTime.now(timezone.local)}',
  );

  // Initialize dependency injection
  await di.init();
  debugPrint('💉 Dependency injection initialized');

  // Initialize notifications
  final notificationService = di.sl<NotificationService>();
  debugPrint('🔔 NotificationService instance obtained');

  await notificationService.initialize();
  debugPrint('🔔 NotificationService initialized');

  await notificationService.requestPermissions();
  debugPrint('🔔 NotificationService permissions requested');

  debugPrint('🎯 Running app...');
  runApp(const MyApp());
}
