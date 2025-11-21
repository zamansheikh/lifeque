import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as timezone;
import 'package:alarm/alarm.dart';
import 'core/app.dart';
import 'core/services/notification_service.dart';
// import 'core/services/update_service.dart'; // Commented out - using in-app updates now
import 'core/services/in_app_update_service.dart';
import 'features/medicines/domain/repositories/medicine_repository.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
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

  // Initialize alarm service
  await Alarm.init();
  debugPrint('⏰ Alarm service initialized');

  // Initialize dependency injection
  await di.init();
  debugPrint('💉 Dependency injection initialized');

  // Initialize notifications (without requesting permissions)
  final notificationService = di.sl<NotificationService>();
  debugPrint('🔔 NotificationService instance obtained');

  await notificationService.initialize();
  debugPrint('🔔 NotificationService initialized');

  // Sync notifications with database to handle cleared data or modifications
  try {
    final medicineRepository = di.sl<MedicineRepository>();
    final taskRepository = di.sl<TaskRepository>();
    await notificationService.syncNotifications(
      medicineRepository,
      taskRepository,
    );
  } catch (e) {
    debugPrint('🔔 ❌ Failed to sync notifications on startup: $e');
  }

  // Note: Permissions will be handled by splash screen / permission screen
  debugPrint('🔔 Permission requests moved to dedicated permission flow');

  // Check for app updates in background
  _checkForUpdatesInBackground();

  debugPrint('🎯 Running app...');
  runApp(const MyApp());
}

/// Check for updates in the background without blocking app startup
void _checkForUpdatesInBackground() {
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      debugPrint('🔄 Background update check started...');
      // Using Google Play Store in-app updates instead of GitHub
      final updateInfo = await InAppUpdateService.checkForUpdates();
      if (updateInfo != null) {
        debugPrint('✅ Update available from Google Play Store');
        // Update info is available - will be handled by in-app update dialogs
      } else {
        debugPrint('✅ App is up to date');
      }
    } catch (e) {
      debugPrint('❌ Background update check failed: $e');
    }
  });
}
