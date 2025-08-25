import 'dart:async';
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
    // Channel for task reminders
    const AndroidNotificationChannel taskRemindersChannel =
        AndroidNotificationChannel(
          'task_reminders',
          'Task Reminders',
          description: 'Notifications for task reminders',
          importance: Importance.high,
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
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    // Handle notification tap
    // You can navigate to specific task detail here
  }

  Future<void> scheduleTaskNotification(Task task) async {
    print('🔔 scheduleTaskNotification called for task: ${task.title}');
    print('🔔 isNotificationEnabled: ${task.isNotificationEnabled}');
    print('🔔 notificationType: ${task.notificationType}');

    if (!task.isNotificationEnabled) {
      print('🔔 Notifications not enabled, returning');
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
      print('🔔 Can schedule exact alarms: $canScheduleExactAlarms');

      if (canScheduleExactAlarms != true) {
        print('🔔 ⚠️ Cannot schedule exact alarms - permission missing');
        // Request permission
        await androidPlugin.requestExactAlarmsPermission();
      }
    }

    // Use the enhanced notification scheduling logic from Task entity
    final scheduledNotificationTime = task.getScheduledNotificationTime();
    print('🔔 scheduledNotificationTime: $scheduledNotificationTime');

    if (scheduledNotificationTime != null) {
      final scheduledDate = tz.TZDateTime.from(
        scheduledNotificationTime,
        tz.local,
      );
      final now = tz.TZDateTime.now(tz.local);
      print('🔔 scheduledDate: $scheduledDate');
      print('🔔 currentTime: $now');
      print('🔔 isAfter check: ${scheduledDate.isAfter(now)}');

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
              channelDescription: 'Notifications for task reminders',
              importance: Importance.max, // Changed from high to max
              priority: Priority.max, // Changed from high to max
              ongoing: false, // Don't make scheduled notifications ongoing
              autoCancel: true, // Allow auto cancel for scheduled notifications
              showProgress:
                  false, // Don't show progress for scheduled notifications
              enableLights: true, // Enable lights for better visibility
              enableVibration: true, // Enable vibration
              playSound: true, // Ensure sound plays
              icon: '@mipmap/ic_launcher', // Ensure icon is set
              largeIcon: const DrawableResourceAndroidBitmap(
                '@mipmap/ic_launcher',
              ),
              // Make it show in lock screen
              visibility: NotificationVisibility.public,
              // Ensure it's not grouped with persistent notifications
              tag: 'scheduled_reminder',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: dateTimeComponents,
        );
        print('🔔 Notification scheduled successfully with enhanced settings!');

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
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          print('🧪 Test notification scheduled for 10 seconds from now');
        }
      } else {
        print('🔔 Scheduled time is not in the future, not scheduling');
      }
    } else {
      print('🔔 scheduledNotificationTime is null');
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
      print(
        '🔔 Notification permission granted: $notificationPermissionGranted',
      );

      // Request exact alarm permission for scheduled notifications (Android 12+)
      final exactAlarmPermissionGranted = await androidPlugin
          .requestExactAlarmsPermission();
      print('🔔 Exact alarm permission granted: $exactAlarmPermissionGranted');

      // Check if we can schedule exact notifications
      final canScheduleExact = await androidPlugin
          .canScheduleExactNotifications();
      print('🔔 Can schedule exact notifications: $canScheduleExact');

      // Check if notifications are enabled
      final areNotificationsEnabled = await androidPlugin
          .areNotificationsEnabled();
      print('🔔 Are notifications enabled: $areNotificationsEnabled');

      print('🔔 All notification permissions requested and checked');
    }

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void dispose() {
    _progressUpdateTimer?.cancel();
  }
}
