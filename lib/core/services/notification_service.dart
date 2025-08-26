import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../features/tasks/domain/entities/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _progressUpdateTimer;
  List<Task> _activeTasks = [];

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    // Channel for task reminders with maximum priority settings
    const AndroidNotificationChannel taskRemindersChannel =
        AndroidNotificationChannel(
          'task_reminders',
          'Task Reminders',
          description:
              'Important notifications for task reminders and deadlines',
          importance: Importance.max, // Highest importance
          enableLights: true,
          enableVibration: true,
          playSound: true,
          showBadge: true,
          // Use default notification sound
        );

    // Channel for persistent tasks - non-dismissable with special settings
    const AndroidNotificationChannel
    persistentTasksChannel = AndroidNotificationChannel(
      'persistent_tasks',
      'Persistent Tasks',
      description:
          'Ongoing task progress notifications - these stay visible until task completion',
      importance: Importance.low,
      enableLights: false,
      enableVibration: false,
      playSound: false,
      // Make it less likely to be dismissed by system
      showBadge: true,
    );

    final platform = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (platform != null) {
      await platform.createNotificationChannel(taskRemindersChannel);
      await platform.createNotificationChannel(persistentTasksChannel);
      debugPrint('🔔 📺 Notification channels created with max importance');
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    // You can navigate to specific task detail here
  }

  Future<void> scheduleTaskNotification(Task task) async {
    debugPrint('🔔 scheduleTaskNotification called for task: ${task.title}');
    debugPrint('🔔 isNotificationEnabled: ${task.isNotificationEnabled}');
    debugPrint('🔔 notificationType: ${task.notificationType}');

    // Always cancel existing notifications first to ensure clean state
    await cancelTaskNotification(task);

    if (!task.isNotificationEnabled) {
      debugPrint('🔔 Notifications not enabled, returning after cleanup');
      return;
    }

    // Check if we can schedule exact alarms
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      final canScheduleExactAlarms = await androidPlugin
          .canScheduleExactNotifications();
      debugPrint('🔔 Can schedule exact alarms: $canScheduleExactAlarms');

      if (canScheduleExactAlarms != true) {
        debugPrint('🔔 ⚠️ Cannot schedule exact alarms - permission missing');
        // Request permission
        final permissionResult = await androidPlugin
            .requestExactAlarmsPermission();
        debugPrint('🔔 Exact alarm permission request result: $permissionResult');

        // Check again after requesting
        final canScheduleAfterRequest = await androidPlugin
            .canScheduleExactNotifications();
        debugPrint(
          '🔔 Can schedule exact alarms after request: $canScheduleAfterRequest',
        );
      }
    }

    // Use the enhanced notification scheduling logic from Task entity
    final scheduledNotificationTime = task.getScheduledNotificationTime();
    debugPrint('🔔 scheduledNotificationTime: $scheduledNotificationTime');

    if (scheduledNotificationTime != null) {
      final scheduledDate = tz.TZDateTime.from(
        scheduledNotificationTime,
        tz.local,
      );
      final now = tz.TZDateTime.now(tz.local);
      debugPrint('🔔 📅 Local timezone: ${tz.local}');
      debugPrint('🔔 🕐 Current local time: $now');
      debugPrint('🔔 ⏰ Scheduled date/time: $scheduledDate');
      debugPrint(
        '🔔 ✅ Is scheduled time after current: ${scheduledDate.isAfter(now)}',
      );
      debugPrint(
        '🔔 ⏳ Time difference: ${scheduledDate.difference(now).inSeconds} seconds',
      );

      // Only schedule if the notification time is in the future
      if (scheduledDate.isAfter(now)) {
        String notificationTitle = 'Task Reminder: ${task.title}';
        String notificationBody = task.description.isNotEmpty
            ? task.description
            : 'You have a task to complete';

        // Customize notification content based on notification type
        switch (task.notificationType) {
          case NotificationType.daily:
            notificationTitle = 'Daily Reminder: ${task.title}';
            notificationBody = 'Your daily task reminder';
            break;
          case NotificationType.beforeEnd:
            final timeBeforeEnd = task.beforeEndOption?.displayName ?? '';
            notificationTitle = 'Task Due Soon: ${task.title}';
            notificationBody = 'Task ends in $timeBeforeEnd';
            break;
          case NotificationType.specificTime:
            // Use default title and body
            break;
        }

        DateTimeComponents? dateTimeComponents;
        // For daily notifications, repeat daily at the same time
        if (task.notificationType == NotificationType.daily) {
          dateTimeComponents = DateTimeComponents.time;
        }

        await _flutterLocalNotificationsPlugin.zonedSchedule(
          task.id.hashCode,
          notificationTitle,
          notificationBody,
          scheduledDate,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'task_reminders',
              'Task Reminders',
              channelDescription:
                  'Important notifications for task reminders and deadlines',
              importance: Importance.max,
              priority: Priority.max,
              ongoing: false,
              autoCancel: true,
              showProgress: false,
              enableLights: true,
              enableVibration: true,
              playSound: true,
              icon: '@mipmap/ic_launcher',
              visibility: NotificationVisibility.public,
              tag: 'scheduled_reminder',
              // Simplified settings for scheduled notifications
              category: AndroidNotificationCategory.reminder,
              when: scheduledDate.millisecondsSinceEpoch,
              channelAction: AndroidNotificationChannelAction.createIfNotExists,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          matchDateTimeComponents: dateTimeComponents,
          androidScheduleMode: AndroidScheduleMode
              .exactAllowWhileIdle, // Critical for reliability
        );
        debugPrint('🔔 Notification scheduled successfully with enhanced settings!');

        // Debug: List all pending scheduled notifications
        final pendingNotifications = await _flutterLocalNotificationsPlugin
            .pendingNotificationRequests();
        debugPrint(
          '🔔 📋 Total pending notifications: ${pendingNotifications.length}',
        );
        for (var notification in pendingNotifications) {
          debugPrint(
            '🔔 📋 Pending: ID=${notification.id}, Title=${notification.title}',
          );
        }

        // Also schedule a test notification 10 seconds from now to verify system works
        if (task.title.toLowerCase().contains('test')) {
          final testTime = tz.TZDateTime.now(
            tz.local,
          ).add(const Duration(seconds: 10));
          await _flutterLocalNotificationsPlugin.zonedSchedule(
            (task.id.hashCode + 999),
            '🧪 Test Notification',
            'This is a test to verify notifications work',
            testTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'task_reminders',
                'Task Reminders',
                channelDescription: 'Test notification',
                importance: Importance.max,
                priority: Priority.max,
                enableLights: true,
                enableVibration: true,
                playSound: true,
                visibility: NotificationVisibility.public,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          debugPrint('🧪 Test notification scheduled for 10 seconds from now');
        }
      } else {
        debugPrint('🔔 Scheduled time is not in the future, not scheduling');
      }
    } else {
      debugPrint('🔔 scheduledNotificationTime is null');
    }

    // If task is pinned to notification, create a persistent notification
    if (task.isPinnedToNotification && task.isActive && !task.isCompleted) {
      await _showPersistentNotification(task);
    }
  }

  Future<void> _showPersistentNotification(Task task) async {
    await _flutterLocalNotificationsPlugin.show(
      task.id.hashCode + 10000, // Different ID for persistent notification
      '📌 ${task.title}',
      '⏱️ ${task.timeLeftFormatted} • ${(task.progressPercentage * 100).toStringAsFixed(0)}% complete',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'persistent_tasks',
          'Persistent Tasks',
          channelDescription: 'Ongoing task progress notifications',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          enableLights: false,
          enableVibration: false,
          playSound: false,
          showProgress: true,
          maxProgress: 100,
          progress: (task.progressPercentage * 100).round(),
          category: AndroidNotificationCategory.progress,
          visibility: NotificationVisibility.public,
          timeoutAfter: null,
          // Use a custom style to make it more prominent
          styleInformation: BigTextStyleInformation(
            '⏱️ Time left: ${task.timeLeftFormatted}\n📊 Progress: ${(task.progressPercentage * 100).toStringAsFixed(1)}%\n📅 Due: ${task.endDate.day}/${task.endDate.month}/${task.endDate.year}',
            htmlFormatBigText: false,
            contentTitle: '📌 ${task.title}',
            htmlFormatContentTitle: false,
            summaryText: 'Ongoing Task',
            htmlFormatSummaryText: false,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: true,
          presentSound: false,
        ),
      ),
    );
  }

  Future<void> updatePersistentNotification(Task task) async {
    if (task.isPinnedToNotification && task.isActive && !task.isCompleted) {
      await _showPersistentNotification(task);
    } else {
      await cancelPersistentNotification(task);
    }
  }

  Future<void> cancelTaskNotification(Task task) async {
    await _flutterLocalNotificationsPlugin.cancel(task.id.hashCode);
    await cancelPersistentNotification(task);
  }

  Future<void> cancelPersistentNotification(Task task) async {
    await _flutterLocalNotificationsPlugin.cancel(task.id.hashCode + 10000);
  }

  Future<void> startRealTimeUpdates(List<Task> tasks) async {
    _progressUpdateTimer?.cancel();
    _activeTasks = tasks;

    // Update persistent notifications every 1 second for real-time updates
    _progressUpdateTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      // Create fresh task instances with updated progress calculations
      for (final task in _activeTasks) {
        if (task.isPinnedToNotification && task.isActive && !task.isCompleted) {
          // Ensure notification exists, recreate if dismissed
          await _ensureNotificationExists(task);
          // Create a fresh task instance with current time for accurate progress
          final freshTask = task.copyWith();
          await _showPersistentNotification(freshTask);
        }
      }
    });
  }

  Future<void> stopRealTimeUpdates() async {
    _progressUpdateTimer?.cancel();
  }

  void updateActiveTasks(List<Task> tasks) {
    _activeTasks = tasks;
  }

  Future<void> forceUpdateNotifications() async {
    for (final task in _activeTasks) {
      if (task.isPinnedToNotification && task.isActive && !task.isCompleted) {
        await updatePersistentNotification(task);
      }
    }
  }

  // Check if notification exists and recreate if needed
  Future<void> _ensureNotificationExists(Task task) async {
    final activeNotifications = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.getActiveNotifications();

    final notificationId = task.id.hashCode + 10000;
    final notificationExists =
        activeNotifications?.any(
          (notification) => notification.id == notificationId,
        ) ??
        false;

    if (!notificationExists &&
        task.isPinnedToNotification &&
        task.isActive &&
        !task.isCompleted) {
      await _showPersistentNotification(task);
    }
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Request basic notification permission
      final notificationPermissionGranted = await androidPlugin
          .requestNotificationsPermission();
      debugPrint(
        '🔔 Notification permission granted: $notificationPermissionGranted',
      );

      // Request exact alarm permission for scheduled notifications (Android 12+)
      final exactAlarmPermissionGranted = await androidPlugin
          .requestExactAlarmsPermission();
      debugPrint('🔔 Exact alarm permission granted: $exactAlarmPermissionGranted');

      // Check if we can schedule exact notifications
      final canScheduleExact = await androidPlugin
          .canScheduleExactNotifications();
      debugPrint('🔔 Can schedule exact notifications: $canScheduleExact');

      // Check if notifications are enabled
      final areNotificationsEnabled = await androidPlugin
          .areNotificationsEnabled();
      debugPrint('🔔 Are notifications enabled: $areNotificationsEnabled');

      debugPrint('🔔 All notification permissions requested and checked');
    }

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> dispose() {
    _progressUpdateTimer?.cancel();
    return Future.value();
  }

  // Test method to verify notifications work at all
  Future<void> showTestNotification() async {
    debugPrint('🧪 Showing immediate test notification');
    await _flutterLocalNotificationsPlugin.show(
      999999,
      '🧪 Test Notification',
      'This is an immediate test notification to verify the system works',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Test notification',
          importance: Importance.max,
          priority: Priority.max,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          visibility: NotificationVisibility.public,
        ),
      ),
    );
    debugPrint('🧪 Test notification sent');
  }

  // Test method to verify scheduled notifications work
  Future<void> scheduleTestNotification() async {
    debugPrint('🧪 Scheduling test notification for 10 seconds from now');
    final scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 10));

    debugPrint('🧪 📅 Local timezone: ${tz.local}');
    debugPrint('🧪 🕐 Current local time: ${tz.TZDateTime.now(tz.local)}');
    debugPrint('🧪 ⏰ Scheduled time: $scheduledTime');

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      999998,
      '🧪 Scheduled Test Notification',
      'This test notification was scheduled 10 seconds ago - if you see this, scheduled notifications work!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Scheduled test notification',
          importance: Importance.max,
          priority: Priority.max,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.reminder,
          when: null, // Let system determine
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint('🧪 Test scheduled notification set for: $scheduledTime');

    // Check pending notifications
    final pendingNotifications = await _flutterLocalNotificationsPlugin
        .pendingNotificationRequests();
    debugPrint(
      '🧪 📋 Pending notifications after test schedule: ${pendingNotifications.length}',
    );
    for (var notification in pendingNotifications) {
      debugPrint(
        '🧪 📋 Pending: ID=${notification.id}, Title=${notification.title}',
      );
    }
  }

  // Simple test method to verify scheduled notifications work
  Future<void> scheduleSimpleTestNotification() async {
    debugPrint('🧪 Scheduling simple test notification for 10 seconds from now');
    final scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(seconds: 10));

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        123456, // Simple test ID
        '🧪 Simple Test',
        'This is a simple test notification scheduled for 10 seconds',
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Simple test notification',
            importance: Importance.max,
            priority: Priority.max,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('🧪 Simple test notification scheduled successfully');
      debugPrint('🧪 Scheduled for: $scheduledTime');

      // List pending notifications
      final pending = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      debugPrint('🧪 Total pending after simple test: ${pending.length}');
    } catch (e) {
      debugPrint('🧪 ❌ Error scheduling simple test notification: $e');
    }
  }
}
