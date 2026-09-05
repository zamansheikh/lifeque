import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:lifeque/features/home_widget/services/home_widget_service.dart';
import 'package:lifeque/core/services/prayer_alarm_service.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as timezone;

/// Define task names
const String updateWidgetTask = "com.programmernexus.lifeque.updateWidget";

/// The callback dispatcher needs to be a top-level function or static method.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();

    debugPrint("🔄 Background Service: Executing task: $task");

    if (task == updateWidgetTask) {
      try {
        // Initialize Timezone. Try the device's actual zone (Android reports
        // IANA names via DateTime.timeZoneName) and fall back to Asia/Dhaka.
        tz.initializeTimeZones();
        try {
          final name = DateTime.now().timeZoneName;
          final location = timezone.timeZoneDatabase.locations[name];
          timezone.setLocalLocation(
            location ?? timezone.getLocation('Asia/Dhaka'),
          );
        } catch (_) {
          timezone.setLocalLocation(timezone.getLocation('Asia/Dhaka'));
        }

        // Update the widget (no-ops on platforms without widget support)
        await initHomeWidget();
        final service = HomeWidgetService();
        await service.updateWidget();

        // Re-queue prayer alarms. The native Alarm package holds one
        // fire-time per id, so if the app has been killed for days nothing
        // will have re-queued tomorrow's alarms. Topping up here every ~15min
        // keeps them firing without needing the app to be open.
        try {
          await Alarm.init();
          await PrayerAlarmService().rescheduleFromBackground();
          debugPrint("✅ Background Service: Prayer alarms re-queued");
        } catch (e) {
          debugPrint("⚠️ Background Service: Prayer alarm reschedule failed: $e");
        }

        debugPrint(
          "✅ Background Service: Widget update completed successfully",
        );
        return Future.value(true);
      } catch (e, stack) {
        debugPrint("❌ Background Service: Task failed: $e");
        debugPrint("Stack: $stack");
        return Future.value(false);
      }
    }

    return Future.value(true);
  });
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  /// Initialize the background service
  Future<void> initialize() async {
    try {
      await Workmanager().initialize(callbackDispatcher);
      debugPrint("✅ WorkManager initialized");

      // Register the periodic task
      registerPeriodicTask();
    } catch (e) {
      debugPrint("❌ Failed to initialize WorkManager: $e");
    }
  }

  /// Register the periodic task to update widgets every 15 minutes
  void registerPeriodicTask() {
    try {
      Workmanager().registerPeriodicTask(
        "widget-update-15m", // Unique name for the task
        updateWidgetTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        existingWorkPolicy:
            ExistingPeriodicWorkPolicy.keep, // Keep if already scheduled
        initialDelay: const Duration(
          seconds: 10,
        ), // Start soon after app launch
      );
      debugPrint("✅ Periodic task registered: 15 minutes interval");
    } catch (e) {
      debugPrint("❌ Failed to register periodic task: $e");
    }
  }
}
