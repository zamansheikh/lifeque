import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as timezone;
import 'package:alarm/alarm.dart';
import 'core/app.dart';
import 'core/services/notification_service.dart';
// import 'core/services/update_service.dart'; // Commented out - using in-app updates now
import 'features/medicines/domain/repositories/medicine_repository.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'injection_container.dart' as di;
import 'features/home_widget/services/home_widget_service.dart';
import 'core/services/background_service.dart';

/// Top-level background callback for home_widget tap-to-refresh.
/// This runs in an isolate when the user taps the widget.
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 Widget background callback started with URI: $uri');

  // Initialize timezone (needed for prayer time calculations)
  try {
    tz.initializeTimeZones();
    timezone.setLocalLocation(timezone.getLocation('Asia/Dhaka'));
  } catch (e) {
    debugPrint('⚠️ Timezone init warning in background: $e');
  }

  // Handle refresh action
  // Check both host and scheme to be sure, or just proceed if it's our URI
  if (uri?.host == 'refreshwidget' ||
      uri.toString().contains('refreshwidget')) {
    debugPrint('🕌 Widget refresh triggered by tap - URI: $uri');
    try {
      // Create a fresh instance of the service
      final service = HomeWidgetService();
      debugPrint(
        '🕌 Created HomeWidgetService instance, calling updateWidget()...',
      );
      await service.updateWidget();
      debugPrint('✅ Widget refreshed via background callback successfully');
    } catch (e, stack) {
      debugPrint('❌ Widget background refresh failed: $e');
      debugPrint('Stack: $stack');
    }
  } else {
    debugPrint('❓ Unknown URI in widget callback: $uri');
  }
}

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

  // Register home widget background callback for tap-to-refresh
  HomeWidget.registerInteractivityCallback(homeWidgetBackgroundCallback);

  // Initialize background service for periodic widget updates
  await BackgroundService().initialize();

  // Update home screen widget with latest prayer times
  _updateHomeWidget();

  debugPrint('🎯 Running app...');
  runApp(const MyApp());
}

/// Update home screen widget with latest prayer times in background
void _updateHomeWidget() {
  Future.delayed(const Duration(seconds: 5), () async {
    try {
      debugPrint('🕌 Updating home screen widget...');
      await HomeWidgetService().updateWidget();
    } catch (e) {
      debugPrint('❌ Home widget update failed: $e');
    }
  });
}
