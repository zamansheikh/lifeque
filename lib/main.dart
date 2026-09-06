import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as timezone;
import 'package:alarm/alarm.dart';
import 'core/app.dart';
import 'core/services/language_preference_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/prayer_alarm_service.dart';
import 'features/medicines/domain/repositories/medicine_repository.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'features/todos/domain/repositories/todo_repository.dart';
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
    _initLocalTimezone();
  } catch (e) {
    debugPrint('⚠️ Timezone init warning in background: $e');
  }

  // Handle refresh action
  // Check both host and scheme to be sure, or just proceed if it's our URI
  if (uri?.host == 'refreshwidget' ||
      uri.toString().contains('refreshwidget')) {
    debugPrint('🕌 Widget refresh triggered by tap - URI: $uri');
    try {
      // Fresh isolate — the plugin's App Group id has to be set again here.
      await initHomeWidget();
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

  // Initialize timezone DB and resolve the device's actual zone. We avoid
  // adding a flutter_timezone dependency by first trying DateTime.timeZoneName
  // (works on Android — returns IANA names) and falling back to Asia/Dhaka if
  // the platform reports an abbreviation (iOS) or anything else not in the DB.
  // NOTE: this only affects display/debug. TZDateTime.from(dt, tz.local)
  // preserves the UTC instant regardless of which zone is set, so notification
  // firing times are correct even with the fallback.
  tz.initializeTimeZones();
  _initLocalTimezone();
  debugPrint(
    '🕐 Current local time: ${timezone.TZDateTime.now(timezone.local)}',
  );

  // Initialize alarm service
  await Alarm.init();
  debugPrint('⏰ Alarm service initialized');

  // Initialize prayer alarm service so the midnight refresh timer, the
  // alarm-ring listener (for daily auto-reschedule) and the startup re-queue
  // run regardless of whether the user opens the Prayer Alarms page.
  try {
    await PrayerAlarmService().initialize();
    debugPrint('🕌 PrayerAlarmService initialized');
  } catch (e) {
    debugPrint('🕌 ❌ PrayerAlarmService init failed: $e');
  }

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
    // To-do reminders are reconciled separately: syncNotifications only knows
    // about medicines and tasks, and treats anything else as an orphan.
    await notificationService.syncTodoNotifications(di.sl<TodoRepository>());
  } catch (e) {
    debugPrint('🔔 ❌ Failed to sync notifications on startup: $e');
  }

  // Note: Permissions will be handled by splash screen / permission screen
  debugPrint('🔔 Permission requests moved to dedicated permission flow');

  // Register home widget background callback for tap-to-refresh. Guarded
  // because iOS has no widget extension / App Group yet — calling into the
  // plugin there throws PlatformException(-7, AppGroupId not set), and since
  // this call is not awaited it would surface as an unhandled exception.
  if (isHomeWidgetSupported) {
    try {
      await initHomeWidget();
      await HomeWidget.registerInteractivityCallback(
        homeWidgetBackgroundCallback,
      );
    } catch (e) {
      debugPrint('🕌 ❌ Home widget callback registration failed: $e');
    }
  }

  // Initialize background service for periodic widget updates
  await BackgroundService().initialize();

  // Update home screen widget with latest prayer times
  _updateHomeWidget();

  debugPrint('🎯 Running app...');
  // Before the first frame, so the app opens in the chosen language rather
  // than flashing English.
  await LanguagePreferenceService.instance.load();
  // DateFormat needs each locale's month and weekday names loaded before it
  // can render them; without this a Bangla date throws at build time.
  await initializeDateFormatting();

  runApp(const MyApp());
}

/// Set tz.local to the device's zone if we can map it, otherwise Asia/Dhaka.
void _initLocalTimezone() {
  const fallback = 'Asia/Dhaka';
  try {
    final name =
        DateTime.now().timeZoneName; // e.g. "America/New_York" on Android
    // Only IANA-style names will resolve; abbreviations like "EST"/"PST" won't.
    final location = timezone.timeZoneDatabase.locations[name];
    if (location != null) {
      timezone.setLocalLocation(location);
      debugPrint('🌍 Timezone set to device zone: $name');
      return;
    }
    debugPrint(
      '🌍 Device reported "$name" — not an IANA id, falling back to $fallback',
    );
  } catch (e) {
    debugPrint('🌍 Timezone detection failed ($e) — using $fallback');
  }
  timezone.setLocalLocation(timezone.getLocation(fallback));
}

/// Update home screen widget with latest prayer times in background
void _updateHomeWidget() {
  Future.delayed(const Duration(seconds: 5), () async {
    try {
      if (!isHomeWidgetSupported) return;
      debugPrint('🕌 Updating home screen widget...');
      await HomeWidgetService().updateWidget();
    } catch (e) {
      debugPrint('❌ Home widget update failed: $e');
    }
  });
}
