import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import '../../features/tasks/domain/entities/task.dart';
import '../../features/tasks/presentation/bloc/task_bloc.dart';
import '../../features/medicines/presentation/bloc/medicine_cubit.dart';
import '../../features/medicines/domain/usecases/manage_doses.dart';
import '../../core/usecases/usecase.dart';
import 'navigation_service.dart';
import '../../injection_container.dart' as di;

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

    final DarwinInitializationSettings
    initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'task_category',
          actions: [
            DarwinNotificationAction.plain('mark_done', '✅ Mark Done'),
            DarwinNotificationAction.plain('snooze_15', '⏰ Snooze 15m'),
            DarwinNotificationAction.plain('view_details', '👁️ View Details'),
          ],
        ),
        DarwinNotificationCategory(
          'reminder_category',
          actions: [
            DarwinNotificationAction.plain('mark_done', '✅ Done'),
            DarwinNotificationAction.plain('snooze_5', '⏰ 5min'),
            DarwinNotificationAction.plain('snooze_60', '⏰ 1hr'),
          ],
        ),
        DarwinNotificationCategory(
          'medicine_category',
          actions: [
            DarwinNotificationAction.plain('take_medicine', '✅ Take Now'),
            DarwinNotificationAction.plain('skip_medicine', '⏭️ Skip'),
            DarwinNotificationAction.plain('snooze_medicine', '⏰ Snooze 15min'),
          ],
        ),
        DarwinNotificationCategory(
          'birthday_category',
          actions: [
            DarwinNotificationAction.plain('call_contact', '📞 Call'),
            DarwinNotificationAction.plain('send_message', '💬 Message'),
            DarwinNotificationAction.plain('mark_done', '✅ Wished'),
          ],
        ),
      ],
    );

    final InitializationSettings initializationSettings =
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

    // Channel for medicine reminders
    const AndroidNotificationChannel medicineRemindersChannel =
        AndroidNotificationChannel(
          'medicine_reminders',
          'Medicine Reminders',
          description: 'Important notifications for medicine dose reminders',
          importance: Importance.max, // Highest importance
          enableLights: true,
          enableVibration: true,
          playSound: true,
          showBadge: true,
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
      await platform.createNotificationChannel(medicineRemindersChannel);
      await platform.createNotificationChannel(persistentTasksChannel);
      debugPrint('🔔 📺 Notification channels created with max importance');
    }
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    final String? actionId = notificationResponse.actionId;

    debugPrint(
      '🔔 Notification tapped - Payload: $payload, ActionId: $actionId',
    );

    // Handle notification actions
    if (actionId != null && payload != null) {
      _handleNotificationAction(actionId, payload);
    } else {
      // Handle regular notification tap - navigate to task detail
      // You can implement navigation logic here
      debugPrint('🔔 Regular notification tap - navigating to task detail');
    }
  }

  Future<void> _handleNotificationAction(
    String actionId,
    String payload,
  ) async {
    debugPrint('🔔 Handling action: $actionId for payload: $payload');

    // Check if this is a medicine notification
    if (payload.startsWith('medicine_')) {
      await _handleMedicineNotificationAction(
        actionId,
        payload.substring(9),
      ); // Remove 'medicine_' prefix
      return;
    }

    // Handle task notifications (existing code)
    final taskId = payload; // For tasks, payload is the task ID
    debugPrint('🔔 Current active tasks count: ${_activeTasks.length}');
    debugPrint('🔔 Active task IDs: ${_activeTasks.map((t) => t.id).toList()}');

    // Force reload tasks to ensure we have the latest data
    await forceReloadTasks();

    try {
      final taskBloc = di.sl<TaskBloc>();

      // Get the current task from the active tasks list
      Task? task;
      try {
        task = _activeTasks.firstWhere((task) => task.id == taskId);
        debugPrint('🔔 Found task: ${task.title} (${task.taskType})');
      } catch (e) {
        debugPrint(
          '🔔 ⚠️ Task $taskId not found in active tasks, trying to get from bloc state',
        );

        // Try to get task from bloc state as fallback
        final currentState = taskBloc.state;
        if (currentState is TaskLoaded) {
          try {
            task = currentState.tasks.firstWhere((t) => t.id == taskId);
            debugPrint('🔔 Found task in bloc state: ${task.title}');
          } catch (e2) {
            debugPrint('🔔 ❌ Task $taskId not found anywhere');
            await _showActionFeedbackNotification(
              '❌ Task Not Found',
              'Task could not be found',
              const Color(0xFFF44336), // Red
            );
            return;
          }
        } else {
          debugPrint('🔔 ❌ TaskBloc not in loaded state: $currentState');
          await _showActionFeedbackNotification(
            '❌ Task Error',
            'Tasks not loaded',
            const Color(0xFFF44336), // Red
          );
          return;
        }
      }

      debugPrint('🔔 Processing action $actionId for task ${task.title}');

      switch (actionId) {
        case 'mark_done':
          // Mark task as completed
          debugPrint('🔔 Marking task $taskId as completed');

          // Cancel the notification immediately
          await cancelTaskNotification(task);
          await cancelPersistentNotification(task);

          // Remove the task from active tasks list
          _activeTasks.removeWhere((t) => t.id == taskId);
          debugPrint('🔔 Removed task from active list');

          // Create an updated task with completed status
          final updatedTask = task.copyWith(
            isCompleted: true,
            updatedAt: DateTime.now(),
          );

          // Update the task directly via bloc
          taskBloc.add(UpdateTaskEvent(updatedTask));
          debugPrint('🔔 Sent UpdateTaskEvent with completed status to bloc');

          // Force reload tasks to refresh UI
          await Future.delayed(const Duration(milliseconds: 500));
          taskBloc.add(LoadTasks());
          debugPrint('🔔 Triggered task reload for UI refresh');

          // Show a completion feedback notification
          await _showActionFeedbackNotification(
            '✅ Task Completed',
            'Task "${task.title}" has been marked as done!',
            const Color(0xFF4CAF50), // Green
          );
          break;

        case 'snooze_5':
          // Snooze for 5 minutes
          debugPrint('🔔 Snoozing for 5 minutes');
          await _snoozeNotification(taskId, 5);
          await _showActionFeedbackNotification(
            '⏰ Snoozed',
            'Task snoozed for 5 minutes',
            const Color(0xFFFF9800), // Orange
          );
          break;

        case 'snooze_15':
          // Snooze for 15 minutes
          debugPrint('🔔 Snoozing for 15 minutes');
          await _snoozeNotification(taskId, 15);
          await _showActionFeedbackNotification(
            '⏰ Snoozed',
            'Task snoozed for 15 minutes',
            const Color(0xFFFF9800), // Orange
          );
          break;

        case 'snooze_60':
          // Snooze for 1 hour
          debugPrint('🔔 Snoozing for 1 hour');
          await _snoozeNotification(taskId, 60);
          await _showActionFeedbackNotification(
            '⏰ Snoozed',
            'Task snoozed for 1 hour',
            const Color(0xFFFF9800), // Orange
          );
          break;

        case 'view_details':
          // Open task details - Navigate to task detail page
          debugPrint('🔔 Opening task details for $taskId');

          try {
            final navigationService = di.sl<NavigationService>();
            navigationService.navigateToTaskDetail(taskId);

            await _showActionFeedbackNotification(
              '👁️ Details',
              'Opening task details...',
              const Color(0xFF2196F3), // Blue
            );
          } catch (e) {
            debugPrint('🔔 Error navigating to task details: $e');
            await _showActionFeedbackNotification(
              '❌ Navigation Error',
              'Could not open task details',
              const Color(0xFFF44336), // Red
            );
          }
          break;

        case 'call_contact':
          // For birthday reminders - call the person
          debugPrint('🔔 Opening phone app to call birthday person');
          try {
            // Extract phone number from task description or use a generic dialer
            // For now, just open the phone dialer
            final phoneUri = Uri.parse('tel:');
            if (await canLaunchUrl(phoneUri)) {
              await launchUrl(phoneUri);
              await _showActionFeedbackNotification(
                '📞 Phone App Opened',
                'Phone app opened successfully',
                const Color(0xFF4CAF50), // Green
              );
            } else {
              throw Exception('Cannot open phone app');
            }
          } catch (e) {
            debugPrint('🔔 Error opening phone app: $e');
            await _showActionFeedbackNotification(
              '❌ Phone Error',
              'Could not open phone app',
              const Color(0xFFF44336), // Red
            );
          }
          break;

        case 'send_message':
          // For birthday reminders - send message
          debugPrint('🔔 Opening messaging app for birthday wishes');
          try {
            // Open SMS app with pre-filled birthday message
            final smsUri = Uri.parse('sms:?body=Happy Birthday! 🎉🎂');
            if (await canLaunchUrl(smsUri)) {
              await launchUrl(smsUri);
              await _showActionFeedbackNotification(
                '💬 Messaging App Opened',
                'Messaging app opened with birthday wishes',
                const Color(0xFF4CAF50), // Green
              );
            } else {
              throw Exception('Cannot open messaging app');
            }
          } catch (e) {
            debugPrint('🔔 Error opening messaging app: $e');
            await _showActionFeedbackNotification(
              '❌ Messaging Error',
              'Could not open messaging app',
              const Color(0xFFF44336), // Red
            );
          }
          break;

        default:
          debugPrint('🔔 Unknown action: $actionId');
          await _showActionFeedbackNotification(
            '❌ Unknown Action',
            'Unknown action: $actionId',
            const Color(0xFFF44336), // Red
          );
      }
    } catch (e) {
      debugPrint('🔔 Error handling notification action: $e');
      await _showActionFeedbackNotification(
        '❌ Error',
        'Failed to perform action: $e',
        const Color(0xFFF44336), // Red
      );
    }
  }

  Future<void> _snoozeNotification(String taskId, int minutes) async {
    debugPrint('🔔 Snoozing notification for $taskId by $minutes minutes');

    // Find the task to get its details
    final task = _activeTasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Task not found for snoozing'),
    );

    // Cancel current notification
    await _flutterLocalNotificationsPlugin.cancel(taskId.hashCode);

    // Reschedule for later with original task details
    final snoozeTime = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(minutes: minutes));

    String title;
    String body;

    switch (task.taskType) {
      case TaskType.task:
        title = '📋 Task Reminder: ${task.title}';
        body = 'Snoozed for $minutes minutes - ${task.description}';
        break;
      case TaskType.reminder:
        title = '⏰ Reminder: ${task.title}';
        body = 'Snoozed for $minutes minutes - ${task.description}';
        break;
      case TaskType.birthday:
        title = '🎂 Birthday Reminder: ${task.title}';
        body = 'Snoozed for $minutes minutes - Don\'t forget to wish them!';
        break;
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      taskId.hashCode,
      title,
      body,
      snoozeTime,
      _getNotificationDetails(task.taskType, taskId),
      payload: taskId, // Add task ID as payload
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint('🔔 Task "${task.title}" snoozed until: $snoozeTime');
  }

  Future<void> _showActionFeedbackNotification(
    String title,
    String message,
    Color color,
  ) async {
    debugPrint('🔔 Showing action feedback: $title - $message');

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
      title,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Action feedback notifications',
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: true,
          ongoing: false,
          enableLights: true,
          enableVibration: false,
          playSound: false,
          color: color,
          icon: '@mipmap/ic_launcher',
          visibility: NotificationVisibility.public,
          timeoutAfter: 3000, // Auto-dismiss after 3 seconds
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );
  }

  NotificationDetails _getNotificationDetails(
    TaskType taskType,
    String taskId,
  ) {
    switch (taskType) {
      case TaskType.task:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Task reminder notifications with actions',
            importance: Importance.max,
            priority: Priority.max,
            ongoing: false,
            autoCancel: true,
            enableLights: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF2196F3), // Blue for tasks
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.reminder,
            actions: [
              const AndroidNotificationAction(
                'mark_done',
                '✅ Mark Done',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'snooze_15',
                '⏰ Snooze 15m',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'view_details',
                '👁️ View Details',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: 'task_category',
          ),
        );

      case TaskType.reminder:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Reminder notifications with quick actions',
            importance: Importance.max,
            priority: Priority.max,
            ongoing: false,
            autoCancel: true,
            enableLights: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFFFF9800), // Orange for reminders
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.reminder,
            actions: [
              const AndroidNotificationAction(
                'mark_done',
                '✅ Done',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'snooze_5',
                '⏰ 5min',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'snooze_60',
                '⏰ 1hr',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: 'reminder_category',
          ),
        );

      case TaskType.birthday:
        return NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Birthday reminder notifications',
            importance: Importance.max,
            priority: Priority.max,
            ongoing: false,
            autoCancel: true,
            enableLights: true,
            enableVibration: true,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFFE91E63), // Pink for birthdays
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.reminder,
            styleInformation: const BigTextStyleInformation(
              '🎉 Don\'t forget to wish them a happy birthday!',
              htmlFormatBigText: false,
              contentTitle: '🎂 Birthday Today!',
              htmlFormatContentTitle: false,
            ),
            actions: [
              const AndroidNotificationAction(
                'call_contact',
                '📞 Call',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'send_message',
                '💬 Message',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'mark_done',
                '✅ Wished',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: 'birthday_category',
          ),
        );
    }
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

    // Special handling for birthday tasks with multiple notification schedule
    if (task.taskType == TaskType.birthday && task.birthdayNotificationSchedule.isNotEmpty) {
      await _scheduleBirthdayNotifications(task);
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
        debugPrint(
          '🔔 Exact alarm permission request result: $permissionResult',
        );

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
          _getNotificationDetails(task.taskType, task.id),
          payload: task.id, // Add task ID as payload
          matchDateTimeComponents: dateTimeComponents,
          androidScheduleMode: AndroidScheduleMode
              .exactAllowWhileIdle, // Critical for reliability
        );
        debugPrint(
          '🔔 Notification scheduled successfully with enhanced settings!',
        );

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

  Future<void> _scheduleBirthdayNotifications(Task task) async {
    debugPrint('🎂 Scheduling multiple birthday notifications for: ${task.title}');
    
    final notificationTimes = task.getBirthdayNotificationTimes();
    debugPrint('🎂 Found ${notificationTimes.length} notification times');
    
    for (int i = 0; i < notificationTimes.length; i++) {
      final notificationTime = notificationTimes[i];
      final option = task.birthdayNotificationSchedule[i % task.birthdayNotificationSchedule.length];
      
      final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);
      final now = tz.TZDateTime.now(tz.local);
      
      if (scheduledDate.isAfter(now)) {
        String title;
        String body;
        
        switch (option) {
          case BirthdayNotificationOption.oneDayBefore:
            title = '🎁 Gift Prep Reminder: ${task.title}';
            body = 'Tomorrow is ${task.title}\'s birthday! Time to prepare gifts 🎁';
            break;
          case BirthdayNotificationOption.twoHoursBefore:
            title = '🎂 Birthday Soon: ${task.title}';
            body = '${task.title}\'s birthday is in 2 hours! Final preparations 🎈';
            break;
          case BirthdayNotificationOption.tenMinutesBefore:
            title = '🎉 Almost Time: ${task.title}';
            body = '${task.title}\'s birthday is in 10 minutes! Get ready to celebrate! 🎊';
            break;
          case BirthdayNotificationOption.exactTime:
            title = '🎂 Happy Birthday ${task.title}! 🎉';
            body = 'It\'s ${task.title}\'s birthday today! Don\'t forget to wish them well! 🎈🎊';
            break;
        }
        
        // Use unique notification ID for each birthday notification
        final notificationId = task.id.hashCode + (i * 1000);
        
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          title,
          body,
          scheduledDate,
          _getNotificationDetails(task.taskType, task.id),
          payload: task.id,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        
        debugPrint('🎂 Scheduled ${option.displayName} notification for: $scheduledDate');
      } else {
        debugPrint('🎂 Skipping past notification time: $scheduledDate');
      }
    }
    
    // If task is pinned to notification, create a persistent notification
    if (task.isPinnedToNotification && task.isActive && !task.isCompleted) {
      await _showPersistentNotification(task);
    }
  }

  Future<void> _showPersistentNotification(Task task) async {
    String title;
    String content;
    Color notificationColor;
    String summaryText;
    String detailedContent;

    // Customize content based on task type
    switch (task.taskType) {
      case TaskType.task:
        title = '📌 ${task.title}';
        content =
            '⏱️ ${task.timeLeftFormatted} • ${(task.progressPercentage * 100).toStringAsFixed(0)}% complete';
        notificationColor = const Color(0xFF2196F3); // Blue
        summaryText = 'Ongoing Task';
        detailedContent =
            '⏱️ Time left: ${task.timeLeftFormatted}\n📊 Progress: ${(task.progressPercentage * 100).toStringAsFixed(1)}%\n📅 Due: ${task.endDate.day}/${task.endDate.month}/${task.endDate.year}';
        break;

      case TaskType.reminder:
        final now = DateTime.now();
        final timeUntil = task.endDate.difference(now);
        final isPast = now.isAfter(task.endDate);

        title = '🔔 ${task.title}';
        if (isPast) {
          content = '⏰ Reminder time has passed!';
          detailedContent =
              '⚠️ This reminder was scheduled for:\n📅 ${task.endDate.day}/${task.endDate.month}/${task.endDate.year} at ${task.endDate.hour}:${task.endDate.minute.toString().padLeft(2, '0')}';
        } else {
          final days = timeUntil.inDays;
          final hours = timeUntil.inHours % 24;
          final minutes = timeUntil.inMinutes % 60;

          if (days > 0) {
            content = '⏰ In ${days}d ${hours}h ${minutes}m';
          } else if (hours > 0) {
            content = '⏰ In ${hours}h ${minutes}m';
          } else {
            content = '⏰ In ${minutes}m';
          }
          detailedContent =
              '🕐 Reminder set for:\n📅 ${task.endDate.day}/${task.endDate.month}/${task.endDate.year} at ${task.endDate.hour}:${task.endDate.minute.toString().padLeft(2, '0')}\n⏰ Time remaining: $content';
        }
        notificationColor = const Color(0xFFFF9800); // Orange
        summaryText = 'Active Reminder';
        break;

      case TaskType.birthday:
        final now = DateTime.now();
        final birthdayThisYear = DateTime(
          now.year,
          task.endDate.month,
          task.endDate.day,
        );
        final birthdayNextYear = DateTime(
          now.year + 1,
          task.endDate.month,
          task.endDate.day,
        );
        final nextBirthday = now.isAfter(birthdayThisYear)
            ? birthdayNextYear
            : birthdayThisYear;
        final daysUntil = nextBirthday.difference(now).inDays;
        final currentAge = now.year - task.endDate.year;

        title = '🎂 ${task.title}';
        if (daysUntil == 0) {
          content = '🎉 Birthday is TODAY! 🎉';
          detailedContent =
              '🎂 Today is ${task.title}\'s birthday!\n🎈 They are turning ${currentAge + 1} years old\n🎉 Don\'t forget to celebrate!';
        } else if (daysUntil == 1) {
          content = '🎈 Birthday is TOMORROW!';
          detailedContent =
              '🎂 ${task.title}\'s birthday is tomorrow!\n🎈 They will turn ${currentAge + (now.isAfter(birthdayThisYear) ? 1 : 0)} years old\n⏰ Time to prepare!';
        } else {
          content = '🎈 $daysUntil days until birthday';
          detailedContent =
              '🎂 ${task.title}\'s birthday:\n📅 ${nextBirthday.day}/${nextBirthday.month}/${nextBirthday.year}\n🎈 Will turn ${currentAge + (now.isAfter(birthdayThisYear) ? 1 : 0)} years old\n⏰ $daysUntil days remaining';
        }
        notificationColor = const Color(0xFFE91E63); // Pink
        summaryText = 'Birthday Reminder';
        break;
    }

    await _flutterLocalNotificationsPlugin.show(
      task.id.hashCode + 10000, // Different ID for persistent notification
      title,
      content,
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
          showProgress:
              task.taskType == TaskType.task, // Only show progress for tasks
          maxProgress: task.taskType == TaskType.task ? 100 : 0,
          progress: task.taskType == TaskType.task
              ? (task.progressPercentage * 100).round()
              : 0,
          category: AndroidNotificationCategory.progress,
          visibility: NotificationVisibility.public,
          timeoutAfter: null,
          color: notificationColor,
          icon: '@mipmap/ic_launcher',
          // Use a custom style to make it more prominent
          styleInformation: BigTextStyleInformation(
            detailedContent,
            htmlFormatBigText: false,
            contentTitle: title,
            htmlFormatContentTitle: false,
            summaryText: summaryText,
            htmlFormatSummaryText: false,
          ),
          // Add action buttons for persistent notifications
          actions: _getPersistentNotificationActions(task.taskType),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: true,
          presentSound: false,
        ),
      ),
      payload: task.id, // Add task ID as payload
    );
  }

  List<AndroidNotificationAction> _getPersistentNotificationActions(
    TaskType taskType,
  ) {
    switch (taskType) {
      case TaskType.task:
        return [
          const AndroidNotificationAction(
            'mark_done',
            '✅ Complete',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'view_details',
            '👁️ Details',
            showsUserInterface: true,
          ),
        ];

      case TaskType.reminder:
        return [
          const AndroidNotificationAction(
            'mark_done',
            '✅ Done',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'snooze_15',
            '⏰ Snooze',
            showsUserInterface: true,
          ),
        ];

      case TaskType.birthday:
        return [
          const AndroidNotificationAction(
            'call_contact',
            '📞 Call',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'mark_done',
            '✅ Wished',
            showsUserInterface: true,
          ),
        ];
    }
  }

  Future<void> updatePersistentNotification(Task task) async {
    if (task.isPinnedToNotification && task.isActive && !task.isCompleted) {
      await _showPersistentNotification(task);
    } else {
      await cancelPersistentNotification(task);
    }
  }

  Future<void> cancelTaskNotification(Task task) async {
    // Cancel the main notification
    await _flutterLocalNotificationsPlugin.cancel(task.id.hashCode);
    
    // For birthday tasks, cancel all multiple notifications
    if (task.taskType == TaskType.birthday && task.birthdayNotificationSchedule.isNotEmpty) {
      for (int i = 0; i < task.birthdayNotificationSchedule.length; i++) {
        final notificationId = task.id.hashCode + (i * 1000);
        await _flutterLocalNotificationsPlugin.cancel(notificationId);
        debugPrint('🎂 Cancelled birthday notification ID: $notificationId');
      }
    }
    
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

  // Force reload tasks from the bloc for debugging
  Future<void> forceReloadTasks() async {
    debugPrint('🔔 🔄 Force reloading tasks from bloc');
    try {
      final taskBloc = di.sl<TaskBloc>();
      final currentState = taskBloc.state;
      debugPrint('🔔 Current bloc state: $currentState');

      if (currentState is TaskLoaded) {
        debugPrint('🔔 Found ${currentState.tasks.length} tasks in bloc state');
        updateActiveTasks(currentState.tasks);
      } else {
        debugPrint('🔔 Bloc not in loaded state, triggering LoadTasks');
        taskBloc.add(LoadTasks());
      }
    } catch (e) {
      debugPrint('🔔 Error force reloading tasks: $e');
    }
  }

  void updateActiveTasks(List<Task> tasks) {
    debugPrint('🔔 📝 updateActiveTasks called with ${tasks.length} tasks');
    for (final task in tasks) {
      debugPrint(
        '🔔 📝 Task: ${task.id} - ${task.title} (${task.taskType}) - Active: ${task.isActive}, Completed: ${task.isCompleted}, Pinned: ${task.isPinnedToNotification}',
      );
    }
    _activeTasks = tasks;
    // Also update any existing persistent notifications to reflect current state
    _refreshPersistentNotifications();
  }

  // Refresh all persistent notifications based on current active tasks
  Future<void> _refreshPersistentNotifications() async {
    for (final task in _activeTasks) {
      if (task.isPinnedToNotification && task.isActive && !task.isCompleted) {
        await _showPersistentNotification(task);
      }
    }
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
      debugPrint(
        '🔔 Exact alarm permission granted: $exactAlarmPermissionGranted',
      );

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

  // Get first active task for testing
  Task? getFirstActiveTask() {
    final activeTasks = _activeTasks
        .where((task) => task.isActive && !task.isCompleted)
        .toList();
    if (activeTasks.isNotEmpty) {
      debugPrint(
        '🧪 Found ${activeTasks.length} active tasks, returning first: ${activeTasks.first.title}',
      );
      return activeTasks.first;
    }
    debugPrint('🧪 No active tasks found');
    return null;
  }

  // Test method to show notification with action buttons for a real task
  Future<void> showTestNotificationForTask(Task task) async {
    debugPrint('🧪 Showing test notification for real task: ${task.title}');
    await _flutterLocalNotificationsPlugin.show(
      task.id.hashCode + 50000, // Unique test ID
      '🧪 Test: ${task.title}',
      'Test notification for real task - try the action buttons!',
      _getNotificationDetails(task.taskType, task.id),
      payload: task.id,
    );
    debugPrint('🧪 Test notification for real task sent');
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
    debugPrint(
      '🧪 Scheduling simple test notification for 10 seconds from now',
    );
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

  // Medicine notification methods
  Future<void> scheduleMedicineNotifications(dynamic medicine) async {
    debugPrint('🩺 Scheduling notifications for medicine: ${medicine.name}');

    // Cancel existing notifications for this medicine
    await cancelMedicineNotifications(medicine.id);

    if (medicine.status.toString() != 'MedicineStatus.active') {
      debugPrint('🩺 Medicine is not active, skipping notifications');
      return;
    }

    // Schedule notifications for each notification time
    for (final timeString in medicine.notificationTimes) {
      await _scheduleTimeBasedMedicineNotification(medicine, timeString);
    }

    debugPrint(
      '🩺 Scheduled ${medicine.notificationTimes.length} notification times for ${medicine.name}',
    );
  }

  Future<void> _scheduleTimeBasedMedicineNotification(
    dynamic medicine,
    String timeString,
  ) async {
    try {
      // Parse time string (format: "HH:mm")
      final timeParts = timeString.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Calculate the first notification date
      final now = DateTime.now();
      var notificationDate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the time has already passed today, start from tomorrow
      if (notificationDate.isBefore(now)) {
        notificationDate = notificationDate.add(const Duration(days: 1));
      }

      // Ensure notification is within medicine duration
      final endDate =
          medicine.endDate ??
          medicine.startDate.add(Duration(days: medicine.durationInDays));
      if (notificationDate.isAfter(endDate)) {
        debugPrint(
          '🩺 Notification time $timeString is after medicine end date, skipping',
        );
        return;
      }

      final notificationId = _generateMedicineNotificationId(
        medicine.id,
        timeString,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        '💊 Medicine Reminder',
        'Time to take ${medicine.name} (${medicine.dosage} ${medicine.dosageUnit})',
        tz.TZDateTime.from(notificationDate, tz.local),
        _getMedicineNotificationDetails(medicine),
        payload: 'medicine_${medicine.id}',
        matchDateTimeComponents:
            DateTimeComponents.time, // Repeat daily at same time
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint(
        '🩺 Scheduled notification for ${medicine.name} at $timeString (ID: $notificationId)',
      );
    } catch (e) {
      debugPrint('🩺 Error scheduling notification for time $timeString: $e');
    }
  }

  NotificationDetails _getMedicineNotificationDetails(dynamic medicine) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'medicine_reminders',
        'Medicine Reminders',
        channelDescription: 'Notifications for medicine dose reminders',
        importance: Importance.max,
        priority: Priority.max,
        ongoing: false,
        autoCancel: true,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF4CAF50), // Green for medicines
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        styleInformation: BigTextStyleInformation(
          'Don\'t forget to take your ${medicine.name}. Dosage: ${medicine.dosage} ${medicine.dosageUnit}',
          htmlFormatBigText: false,
          contentTitle: '💊 Medicine Reminder',
          htmlFormatContentTitle: false,
        ),
        actions: [
          const AndroidNotificationAction(
            'take_medicine',
            '✅ Take Now',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'skip_medicine',
            '⏭️ Skip',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'snooze_medicine',
            '⏰ Snooze 15min',
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'medicine_category',
      ),
    );
  }

  Future<void> cancelMedicineNotifications(String medicineId) async {
    debugPrint('🩺 Cancelling notifications for medicine: $medicineId');

    // Get all pending notifications
    final pendingNotifications = await _flutterLocalNotificationsPlugin
        .pendingNotificationRequests();

    // Cancel notifications that belong to this medicine
    for (final notification in pendingNotifications) {
      if (_isMedicineNotification(notification.id, medicineId)) {
        await _flutterLocalNotificationsPlugin.cancel(notification.id);
        debugPrint(
          '🩺 Cancelled notification ${notification.id} for medicine $medicineId',
        );
      }
    }
  }

  int _generateMedicineNotificationId(String medicineId, String timeString) {
    // Generate unique ID combining medicine ID and time
    final combined = 'med_${medicineId}_$timeString';
    return combined.hashCode.abs() % 2147483647; // Ensure positive int32
  }

  bool _isMedicineNotification(int notificationId, String medicineId) {
    // Check if notification ID was generated for this medicine
    final medicineHash = medicineId.hashCode.abs();
    final notificationHash = notificationId.toString();
    return notificationHash.contains(medicineHash.toString().substring(0, 3));
  }

  Future<void> _handleMedicineNotificationAction(
    String actionId,
    String medicineId,
  ) async {
    debugPrint(
      '🩺 Handling medicine notification action: $actionId for medicine: $medicineId',
    );

    try {
      // Get the medicine cubit to handle dose updates
      final medicineCubit = di.sl<MedicineCubit>();

      switch (actionId) {
        case 'take_medicine':
          debugPrint('🩺 User marked dose as taken from notification');

          // Get the current pending dose for this medicine
          await _markCurrentPendingDoseAsTaken(medicineId, medicineCubit);

          await _showActionFeedbackNotification(
            '✅ Dose Taken',
            'Medicine dose marked as taken!',
            const Color(0xFF4CAF50),
          );
          break;

        case 'skip_medicine':
          debugPrint('🩺 User skipped dose from notification');

          // Get the current pending dose for this medicine
          await _markCurrentPendingDoseAsSkipped(medicineId, medicineCubit);

          await _showActionFeedbackNotification(
            '⏭️ Dose Skipped',
            'Medicine dose skipped',
            const Color(0xFFFF9800),
          );
          break;

        case 'snooze_medicine':
          debugPrint('🩺 User snoozed dose from notification');
          await _snoozeMedicineNotification(medicineId, 15);
          await _showActionFeedbackNotification(
            '⏰ Dose Snoozed',
            'Reminder snoozed for 15 minutes',
            const Color(0xFF2196F3),
          );
          break;

        default:
          debugPrint('🩺 Unknown medicine notification action: $actionId');
      }
    } catch (e) {
      debugPrint('🩺 Error handling medicine notification action: $e');
      await _showActionFeedbackNotification(
        '❌ Error',
        'Failed to perform action',
        const Color(0xFFF44336),
      );
    }
  }

  Future<void> _markCurrentPendingDoseAsTaken(
    String medicineId,
    dynamic medicineCubit,
  ) async {
    try {
      debugPrint('🩺 Finding current pending dose for medicine: $medicineId');

      // Get today's doses for this medicine
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get all pending doses for this medicine today
      final pendingDosesResult = await di.sl<GetPendingDoses>()(NoParams());

      await pendingDosesResult.fold(
        (failure) {
          debugPrint('🩺 ❌ Failed to get pending doses: $failure');
        },
        (pendingDoses) async {
          debugPrint('🩺 Found ${pendingDoses.length} total pending doses');

          // Filter for this medicine and today
          final medicinePendingDoses = pendingDoses
              .where(
                (dose) =>
                    dose.medicineId == medicineId &&
                    dose.scheduledTime.isAfter(
                      todayStart.subtract(const Duration(hours: 2)),
                    ) &&
                    dose.scheduledTime.isBefore(
                      todayEnd.add(const Duration(hours: 2)),
                    ),
              )
              .toList();

          debugPrint(
            '🩺 Found ${medicinePendingDoses.length} pending doses for medicine $medicineId today',
          );

          if (medicinePendingDoses.isNotEmpty) {
            // Sort by scheduled time and get the earliest one (most likely current dose)
            medicinePendingDoses.sort(
              (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
            );
            final currentDose = medicinePendingDoses.first;

            debugPrint(
              '🩺 Marking dose ${currentDose.id} as taken (scheduled: ${currentDose.scheduledTime})',
            );

            // Mark the dose as taken using the medicine cubit
            await medicineCubit.markDoseAsTaken(currentDose.id, medicineId);

            debugPrint('🩺 ✅ Successfully marked dose as taken');
          } else {
            debugPrint(
              '🩺 ⚠️ No pending doses found for medicine $medicineId today',
            );
          }
        },
      );
    } catch (e) {
      debugPrint('🩺 ❌ Error marking current dose as taken: $e');
      rethrow;
    }
  }

  Future<void> _markCurrentPendingDoseAsSkipped(
    String medicineId,
    dynamic medicineCubit,
  ) async {
    try {
      debugPrint(
        '🩺 Finding current pending dose to skip for medicine: $medicineId',
      );

      // Get today's doses for this medicine
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get all pending doses for this medicine today
      final pendingDosesResult = await di.sl<GetPendingDoses>()(NoParams());

      await pendingDosesResult.fold(
        (failure) {
          debugPrint('🩺 ❌ Failed to get pending doses: $failure');
        },
        (pendingDoses) async {
          debugPrint('🩺 Found ${pendingDoses.length} total pending doses');

          // Filter for this medicine and today
          final medicinePendingDoses = pendingDoses
              .where(
                (dose) =>
                    dose.medicineId == medicineId &&
                    dose.scheduledTime.isAfter(
                      todayStart.subtract(const Duration(hours: 2)),
                    ) &&
                    dose.scheduledTime.isBefore(
                      todayEnd.add(const Duration(hours: 2)),
                    ),
              )
              .toList();

          debugPrint(
            '🩺 Found ${medicinePendingDoses.length} pending doses for medicine $medicineId today',
          );

          if (medicinePendingDoses.isNotEmpty) {
            // Sort by scheduled time and get the earliest one (most likely current dose)
            medicinePendingDoses.sort(
              (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
            );
            final currentDose = medicinePendingDoses.first;

            debugPrint(
              '🩺 Marking dose ${currentDose.id} as skipped (scheduled: ${currentDose.scheduledTime})',
            );

            // Mark the dose as skipped using the medicine cubit
            await medicineCubit.markDoseAsSkipped(currentDose.id, medicineId);

            debugPrint('🩺 ✅ Successfully marked dose as skipped');
          } else {
            debugPrint(
              '🩺 ⚠️ No pending doses found for medicine $medicineId today',
            );
          }
        },
      );
    } catch (e) {
      debugPrint('🩺 ❌ Error marking current dose as skipped: $e');
      rethrow;
    }
  }

  Future<void> _snoozeMedicineNotification(
    String medicineId,
    int minutes,
  ) async {
    debugPrint('🩺 Snoozing medicine notification for $minutes minutes');

    // Schedule new notification for later
    final snoozeTime = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(minutes: minutes));

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      DateTime.now().millisecondsSinceEpoch %
          100000, // Unique ID for snoozed notification
      '💊 Medicine Reminder (Snoozed)',
      'Don\'t forget to take your medicine - this reminder was snoozed',
      snoozeTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminders',
          'Medicine Reminders',
          channelDescription: 'Snoozed medicine reminders',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
      payload: 'medicine_$medicineId',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    debugPrint('🩺 Medicine notification snoozed for $minutes minutes');
  }

  // Schedule medicine notifications for all active medicines
  Future<void> scheduleAllMedicineNotifications() async {
    try {
      debugPrint('📋 Scheduling notifications for all active medicines...');

      // Note: This method will be enhanced to work with medicine repository
      // For now, it's a placeholder that will be called after medicines are loaded
      debugPrint('📋 Medicine notifications scheduling completed');
    } catch (e) {
      debugPrint('❌ Error scheduling all medicine notifications: $e');
    }
  }
}
