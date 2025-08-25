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
    if (!task.isNotificationEnabled || task.notificationTime == null) {
      return;
    }

    final notificationTime = task.notificationTime!;
    final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);

    // Only schedule if the notification time is in the future
    if (scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        task.id.hashCode,
        'Task Reminder: ${task.title}',
        task.description.isNotEmpty
            ? task.description
            : 'You have a task to complete',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.high,
            priority: Priority.high,
            ongoing: task.isPinnedToNotification,
            autoCancel: !task.isPinnedToNotification,
            showProgress: true,
            maxProgress: 100,
            progress: (task.progressPercentage * 100).round(),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
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
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

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
