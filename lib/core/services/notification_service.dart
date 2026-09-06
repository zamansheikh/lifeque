import 'dart:async';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../features/tasks/domain/entities/task.dart';
import '../../features/tasks/presentation/bloc/task_bloc.dart';
import '../../features/todos/domain/entities/todo.dart';
import '../../features/todos/domain/repositories/todo_repository.dart';
import '../../features/todos/presentation/bloc/todo_bloc.dart';
import '../../features/medicines/presentation/bloc/medicine_cubit.dart';
import '../../features/medicines/domain/usecases/manage_doses.dart';
import '../../core/usecases/usecase.dart';
import '../../features/medicines/domain/repositories/medicine_repository.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import 'navigation_service.dart';
import '../../injection_container.dart' as di;
import '../../features/medicines/data/services/care_person_service.dart';
import '../../features/medicines/domain/entities/medicine.dart';
import '../../features/medicines/domain/entities/medicine_dose.dart';
import '../../features/medicines/presentation/utils/medicine_l10n.dart';
import '../../l10n/app_localizations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer? _progressUpdateTimer;
  List<Task> _activeTasks = [];

  // Notification tracking constants
  static const String _medicineNotificationIdsKey = 'medicine_notification_ids';
  // Persistent map of "med_<medicineId>_<timeString>" -> int notification id.
  // We assign ids from a monotonic counter so different medicines (or the
  // same medicine at different times) never collide, and so the medicine id
  // space never overlaps the hashCode-based task/birthday id space.
  static const String _medicineNotificationIdMapKey =
      'medicine_notification_id_map';
  static const String _medicineNotificationIdCounterKey =
      'medicine_notification_id_counter';
  // Start medicines well above the range any reasonable .hashCode result
  // would land in for task ids (which are signed-32-bit String hashCodes).
  static const int _medicineIdCounterStart = 1500000000;

  // To-do reminders get their own band for the same reason: ids come from a
  // monotonic counter kept in a persistent map, so a to-do can never land on
  // the same notification id as a task, a birthday, or a medicine dose.
  static const String _todoNotificationIdMapKey = 'todo_notification_id_map';
  static const String _todoNotificationIdCounterKey =
      'todo_notification_id_counter';
  static const int _todoIdCounterStart = 1700000000;

  // ── Channels ────────────────────────────────────────────────────────────
  //
  // Android freezes a channel's sound the moment it is created: changing it
  // later is ignored until the app is reinstalled. So changing the sound means
  // new channel ids, and retiring the old ones so the app's notification
  // settings don't list each channel twice.
  static const String channelTasks = 'task_reminders_v3';
  static const String channelMedicines = 'medicine_reminders_v3';
  static const String channelTodos = 'todo_reminders_v3';
  static const String channelPersistent = 'persistent_tasks';

  /// Confirmations after a notification action ("Completed", "Snoozed").
  ///
  /// These need a channel of their own because on Android 8+ the *channel*
  /// owns the sound: `playSound: false` in the notification details is
  /// ignored. Posting confirmations on the task channel is what made "task
  /// done" chime. A three-second acknowledgement should be silent.
  static const String channelFeedback = 'action_feedback';

  static const List<String> _retiredChannels = [
    'task_reminders',
    'medicine_reminders',
    'todo_reminders',
    'task_reminders_v2',
    'medicine_reminders_v2',
    'todo_reminders_v2',
  ];

  /// Payload prefix that marks a notification as belonging to a to-do.
  /// Everything without a known prefix is still treated as a task id, so this
  /// has to be checked before that fallback.
  static const String todoPayloadPrefix = 'todo_';

  // Track if app was launched by notification action
  static bool _appLaunchedByNotification = false;
  static bool get isAppLaunchedByNotification => _appLaunchedByNotification;
  static void setAppLaunchedByNotification(bool value) {
    _appLaunchedByNotification = value;
    debugPrint('🔔 App launched by notification: $value');
  }

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          notificationCategories: [
            DarwinNotificationCategory(
              'task_category',
              actions: [
                DarwinNotificationAction.plain('mark_done', 'Mark done'),
                DarwinNotificationAction.plain('snooze_15', 'Snooze 15 min'),
                DarwinNotificationAction.plain('view_details', 'View details'),
              ],
            ),
            DarwinNotificationCategory(
              'reminder_category',
              actions: [
                DarwinNotificationAction.plain('mark_done', 'Done'),
                DarwinNotificationAction.plain('snooze_5', 'Snooze 5 min'),
                DarwinNotificationAction.plain('snooze_60', 'Snooze 1 hour'),
              ],
            ),
            DarwinNotificationCategory(
              'medicine_category',
              actions: [
                DarwinNotificationAction.plain('take_medicine', 'Taken'),
                DarwinNotificationAction.plain('skip_medicine', 'Skip dose'),
                DarwinNotificationAction.plain('snooze_medicine', 'In 15 min'),
              ],
            ),
            DarwinNotificationCategory(
              'birthday_category',
              actions: [
                DarwinNotificationAction.plain('call_contact', 'Call'),
                DarwinNotificationAction.plain('send_message', 'Send wishes'),
                DarwinNotificationAction.plain('mark_done', 'Wished them'),
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
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Check if app was launched by a notification action
    await _checkLaunchedFromNotification();

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Check if app was launched by tapping a notification
  Future<void> _checkLaunchedFromNotification() async {
    try {
      final NotificationAppLaunchDetails? launchDetails =
          await _flutterLocalNotificationsPlugin
              .getNotificationAppLaunchDetails();

      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        debugPrint('🔔 App launched from notification!');
        setAppLaunchedByNotification(true);

        // Handle the launch notification response if available
        if (launchDetails.notificationResponse != null) {
          debugPrint('🔔 Delayed processing of launch notification response');
          // Delay the action processing to ensure all services are ready
          Future.delayed(const Duration(milliseconds: 500), () {
            debugPrint('🔔 Processing delayed launch notification response');
            _onNotificationTapped(launchDetails.notificationResponse!);
          });
        }
      }
    } catch (e) {
      debugPrint('🔔 Error checking notification launch details: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    final platform = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (platform == null) return;

    // Alerting channels use the phone's own notification sound. An earlier
    // version shipped a cut of the app's *alarm* tone here, which made every
    // reminder sound like an alarm going off. Ongoing and confirmation
    // channels stay silent.
    const channels = [
      AndroidNotificationChannel(
        channelTasks,
        'Task Reminders',
        description: 'Tasks, reminders and birthdays',
        importance: Importance.max,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        channelMedicines,
        'Medicine Reminders',
        description: 'Doses to take',
        importance: Importance.max,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        channelTodos,
        'To-Do Reminders',
        description: 'Reminders for the to-dos on your list',
        importance: Importance.max,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
        showBadge: true,
      ),
      AndroidNotificationChannel(
        channelFeedback,
        'Action Confirmations',
        description: 'Brief confirmations after a notification action',
        importance: Importance.low,
        enableLights: false,
        enableVibration: false,
        playSound: false,
        showBadge: false,
      ),
      AndroidNotificationChannel(
        channelPersistent,
        'Persistent Tasks',
        description:
            'Ongoing task progress notifications — these stay visible '
            'until the task is complete',
        importance: Importance.low,
        enableLights: false,
        enableVibration: false,
        playSound: false,
        showBadge: true,
      ),
    ];

    for (final channel in channels) {
      await platform.createNotificationChannel(channel);
    }

    // Retire the soundless originals so the app's notification settings
    // don't show two of everything after the upgrade.
    for (final id in _retiredChannels) {
      try {
        await platform.deleteNotificationChannel(channelId: id);
      } catch (e) {
        debugPrint('🔔 Could not delete old channel $id: $e');
      }
    }

    debugPrint('🔔 📺 Notification channels created');
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    final String? actionId = notificationResponse.actionId;

    debugPrint(
      '🔔 Notification tapped - Payload: $payload, ActionId: $actionId',
    );

    // Mark that app was launched by notification action
    setAppLaunchedByNotification(true);

    // Handle notification actions
    if (actionId != null && payload != null) {
      _handleNotificationAction(actionId, payload);
    } else {
      // Handle regular notification tap - navigate to task detail
      // You can implement navigation logic here
      debugPrint('🔔 Regular notification tap - navigating to task detail');
    }
  }

  /// Ensure all services are ready before processing notification actions
  Future<void> _ensureServicesReady() async {
    int retryCount = 0;
    const maxRetries = 10;
    const retryDelay = Duration(milliseconds: 100);

    while (retryCount < maxRetries) {
      try {
        // Try to access the TaskBloc to ensure DI is ready
        di.sl<TaskBloc>();
        debugPrint('🔔 ✅ Services ready, TaskBloc accessible');
        return;
      } catch (e) {
        retryCount++;
        debugPrint(
          '🔔 ⏳ Services not ready (attempt $retryCount/$maxRetries): $e',
        );

        if (retryCount >= maxRetries) {
          debugPrint(
            '🔔 ❌ Services still not ready after $maxRetries attempts',
          );
          throw Exception('Services not ready after maximum retries');
        }

        await Future.delayed(retryDelay);
      }
    }
  }

  /// Recently handled (action, payload) pairs, so the same tap isn't acted on
  /// twice.
  final Map<String, DateTime> _handledActions = {};
  static const Duration _actionDedupeWindow = Duration(seconds: 5);

  /// True if this exact action has just been handled.
  ///
  /// On a cold start the plugin delivers the response through
  /// `onDidReceiveNotificationResponse` *and* `_checkLaunchedFromNotification`
  /// replays it half a second later, so every action ran twice: two
  /// confirmation notifications, and two snoozed reminders where the user
  /// asked for one. A genuine second tap can't happen — the actions carry
  /// `cancelNotification: true`, so the notification is gone after the first.
  bool _alreadyHandled(String actionId, String payload) {
    final key = '$actionId|$payload';
    final now = DateTime.now();
    _handledActions.removeWhere(
      (_, at) => now.difference(at) > _actionDedupeWindow,
    );
    if (_handledActions.containsKey(key)) return true;
    _handledActions[key] = now;
    return false;
  }

  Future<void> _handleNotificationAction(
    String actionId,
    String payload,
  ) async {
    debugPrint('🔔 Handling action: $actionId for payload: $payload');

    if (_alreadyHandled(actionId, payload)) {
      debugPrint('🔔 Ignoring duplicate delivery of $actionId for $payload');
      return;
    }

    // Add retry mechanism for cold app starts
    await _ensureServicesReady();

    // A question about one particular dose, answered by its id.
    if (payload.startsWith(dosePayloadPrefix)) {
      await _handleDoseAnswer(
        actionId,
        payload.substring(dosePayloadPrefix.length),
      );
      return;
    }

    // Check if this is a medicine notification
    if (payload.startsWith('medicine_')) {
      await _handleMedicineNotificationAction(
        actionId,
        payload.substring(9),
      ); // Remove 'medicine_' prefix
      return;
    }

    // To-do reminders. Checked before the task fallback below, which treats
    // any unprefixed payload as a task id.
    if (payload.startsWith(todoPayloadPrefix)) {
      await _handleTodoNotificationAction(
        actionId,
        payload.substring(todoPayloadPrefix.length),
      );
      return;
    }

    final taskId = payload; // For tasks, payload is the task ID

    // Nudge the UI to refresh, but don't depend on it: forceReloadTasks only
    // *dispatches* LoadTasks, it doesn't wait for the read to finish.
    await forceReloadTasks();

    try {
      // Ask storage, not the caches.
      //
      // Opening the app cold, straight from a notification, leaves
      // `_activeTasks` empty and TaskBloc on TaskInitial — the load hasn't
      // finished yet. The old code read that as "the task is gone", cancelled
      // the notification and told the user it had been deleted, while the
      // database had the answer the whole time. With the app already running
      // the caches happened to be warm, which is exactly why this only ever
      // showed up on a cold start.
      final task = await _findTask(taskId);

      if (task == null) {
        debugPrint('🔔 ❌ Task $taskId really is gone');
        await cancelNotificationById(taskId);
        await _showActionFeedbackNotification(
          'Task not found',
          'It looks like this one was deleted',
          const Color(0xFF9E9E9E),
        );
        return;
      }

      // Safe by this point: _ensureServicesReady above only returns once this
      // resolves. UpdateTaskEvent writes through the repository and reloads,
      // so it works even with the bloc still on TaskInitial.
      final taskBloc = di.sl<TaskBloc>();

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
            'Completed',
            '"${task.title}" is done',
            const Color(0xFF4CAF50), // Green
          );
          break;

        case 'snooze_5':
          // Snooze for 5 minutes
          debugPrint('🔔 Snoozing for 5 minutes');
          await _snoozeNotification(task, 5);
          await _showActionFeedbackNotification(
            'Snoozed',
            'Task snoozed for 5 minutes',
            const Color(0xFFFF9800), // Orange
          );
          break;

        case 'snooze_15':
          // Snooze for 15 minutes
          debugPrint('🔔 Snoozing for 15 minutes');
          await _snoozeNotification(task, 15);
          await _showActionFeedbackNotification(
            'Snoozed',
            'Task snoozed for 15 minutes',
            const Color(0xFFFF9800), // Orange
          );
          break;

        case 'snooze_60':
          // Snooze for 1 hour
          debugPrint('🔔 Snoozing for 1 hour');
          await _snoozeNotification(task, 60);
          await _showActionFeedbackNotification(
            'Snoozed',
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
              'Opening',
              'Opening task details...',
              const Color(0xFF2196F3), // Blue
            );
          } catch (e) {
            debugPrint('🔔 Error navigating to task details: $e');
            await _showActionFeedbackNotification(
              'Could not open',
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
                'Opening phone',
                'Dialler is ready',
                const Color(0xFF4CAF50), // Green
              );
            } else {
              throw Exception('Cannot open phone app');
            }
          } catch (e) {
            debugPrint('🔔 Error opening phone app: $e');
            await _showActionFeedbackNotification(
              'Could not open phone',
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
                'Opening messages',
                'Message drafted',
                const Color(0xFF4CAF50), // Green
              );
            } else {
              throw Exception('Cannot open messaging app');
            }
          } catch (e) {
            debugPrint('🔔 Error opening messaging app: $e');
            await _showActionFeedbackNotification(
              'Could not open messages',
              'Could not open messaging app',
              const Color(0xFFF44336), // Red
            );
          }
          break;

        default:
          debugPrint('🔔 Unknown action: $actionId');
          await _showActionFeedbackNotification(
            'Unknown action',
            'Unknown action: $actionId',
            const Color(0xFFF44336), // Red
          );
      }
    } catch (e) {
      debugPrint('🔔 Error handling notification action: $e');
      await _showActionFeedbackNotification(
        'Something went wrong',
        'Failed to perform action: $e',
        const Color(0xFFF44336), // Red
      );
    }
  }

  /// The task behind a notification, read from storage first.
  ///
  /// The in-memory lists are only a fallback for the case where the
  /// repository itself can't be reached — they are empty on a cold start and
  /// must never be the thing that decides a task no longer exists.
  Future<Task?> _findTask(String taskId) async {
    try {
      final result = await di.sl<TaskRepository>().getTaskById(taskId);
      final stored = result.fold((failure) {
        debugPrint('🔔 Repository had no task $taskId: $failure');
        return null;
      }, (task) => task);
      if (stored != null) return stored;
    } catch (e) {
      debugPrint('🔔 Repository lookup failed for $taskId: $e');
    }

    for (final cached in _activeTasks) {
      if (cached.id == taskId) return cached;
    }

    try {
      final state = di.sl<TaskBloc>().state;
      if (state is TaskLoaded) {
        return state.tasks.where((t) => t.id == taskId).firstOrNull;
      }
    } catch (e) {
      debugPrint('🔔 Bloc lookup failed for $taskId: $e');
    }
    return null;
  }

  /// Takes the task itself rather than an id: the caller has already resolved
  /// it from storage, and re-reading `_activeTasks` here used to throw
  /// "Task not found for snoozing" on a cold start for the same reason the
  /// lookup above did.
  Future<void> _snoozeNotification(Task task, int minutes) async {
    final taskId = task.id;
    debugPrint('🔔 Snoozing notification for $taskId by $minutes minutes');

    // Cancel current notification
    await _flutterLocalNotificationsPlugin.cancel(id: taskId.hashCode);

    // Reschedule for later with original task details
    final snoozeTime = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(minutes: minutes));

    // "Snoozed" is the header label now, so the body can be the description
    // rather than restating what the header already says. A null description
    // used to print the literal word "null" here.
    final String title = task.title;
    final description = task.description?.trim();
    final String body = description != null && description.isNotEmpty
        ? description
        : 'Snoozed for $minutes minutes.';

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id: taskId.hashCode,
      title: title,
      body: body,
      scheduledDate: snoozeTime,
      notificationDetails: _getNotificationDetails(
        task.taskType,
        taskId,
        body: body,
        kind: 'Snoozed',
        when: snoozeTime,
      ),
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
      id: DateTime.now().millisecondsSinceEpoch % 100000, // Unique ID
      title: title,
      body: message,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelFeedback,
          'Action Confirmations',
          channelDescription: 'Brief confirmations after a notification action',
          importance: Importance.low,
          priority: Priority.low,
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

  // ── How a notification looks ────────────────────────────────────────────
  //
  // Android already shows the app name and icon in the header, so the title is
  // the thing itself — "Pay the electricity bill", not "📋 Task Reminder: Pay
  // the electricity bill". What kind of thing it is goes in `subText`, the
  // slot Android provides for exactly that, and the accent colour says it
  // again at a glance. Emoji in titles and button labels added nothing those
  // two didn't already carry, and made every notification read like a chat
  // message.
  //
  // Group keys bundle several of a kind under one header instead of stacking
  // up as unrelated rows.
  static const String _groupTasks = 'lifeque.tasks';
  static const String _groupReminders = 'lifeque.reminders';
  static const String _groupBirthdays = 'lifeque.birthdays';
  static const String _groupMedicines = 'lifeque.medicines';
  static const String _groupTodos = 'lifeque.todos';

  static const Color _taskColor = Color(0xFF2563EB);
  static const Color _reminderColor = Color(0xFFD97706);
  static const Color _birthdayColor = Color(0xFFDB2777);
  static const Color _medicineColor = Color(0xFF059669);
  static const Color _todoColor = Color(0xFF7C3AED);

  /// The shared shape of an alerting notification.
  ///
  /// [kind] is the one-word label in the header ("Task", "Reminder"); [body]
  /// is repeated as big text so a long description isn't truncated when the
  /// notification is expanded; [when] makes the timestamp the moment the
  /// notification is *about* rather than the moment it was posted.
  AndroidNotificationDetails _androidAlert({
    required String channelId,
    required String channelName,
    required String kind,
    required Color color,
    required String body,
    required String group,
    List<AndroidNotificationAction> actions = const [],
    DateTime? when,
  }) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: '$kind notifications',
      importance: Importance.max,
      priority: Priority.max,
      autoCancel: true,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      color: color,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
      subText: kind,
      groupKey: group,
      when: when?.millisecondsSinceEpoch,
      showWhen: when != null,
      styleInformation: BigTextStyleInformation(body),
      actions: actions,
    );
  }

  /// Every action opens the app.
  ///
  /// Handling one silently would need a background isolate callback, and this
  /// app doesn't register one — an action marked `showsUserInterface: false`
  /// is simply dropped whenever the app isn't already in the foreground, which
  /// looks exactly like a broken button.
  static AndroidNotificationAction _action(String id, String label) =>
      AndroidNotificationAction(
        id,
        label,
        showsUserInterface: true,
        cancelNotification: true,
      );

  NotificationDetails _getNotificationDetails(
    TaskType taskType,
    String taskId, {
    String body = '',
    String? kind,
    DateTime? when,
  }) {
    switch (taskType) {
      case TaskType.task:
        return NotificationDetails(
          android: _androidAlert(
            channelId: channelTasks,
            channelName: 'Task Reminders',
            kind: kind ?? 'Task',
            color: _taskColor,
            body: body,
            group: _groupTasks,
            when: when,
            // Two actions, not three: tapping the notification already opens
            // the details, so a button for it was a button for nothing.
            actions: [
              _action('mark_done', 'Mark done'),
              _action('snooze_15', 'Snooze 15 min'),
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
          android: _androidAlert(
            channelId: channelTasks,
            channelName: 'Task Reminders',
            kind: kind ?? 'Reminder',
            color: _reminderColor,
            body: body,
            group: _groupReminders,
            when: when,
            actions: [
              _action('mark_done', 'Done'),
              _action('snooze_5', 'Snooze 5 min'),
              _action('snooze_60', 'Snooze 1 hour'),
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
          android: _androidAlert(
            channelId: channelTasks,
            channelName: 'Task Reminders',
            kind: kind ?? 'Birthday',
            color: _birthdayColor,
            body: body,
            group: _groupBirthdays,
            when: when,
            // Ordered by what you'd actually reach for first.
            actions: [
              _action('send_message', 'Send wishes'),
              _action('call_contact', 'Call'),
              _action('mark_done', 'Wished them'),
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
    if (task.taskType == TaskType.birthday &&
        task.birthdayNotificationSchedule.isNotEmpty) {
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
        // The title is the task, full stop. What sort of alert it is — a
        // daily nudge, a deadline warning — belongs in the header label
        // beside the app name, not glued to the front of the title where it
        // pushes the actual words off the end of the line.
        final String notificationTitle = task.title;
        final String notificationBody;
        final String notificationKind;

        if (task.taskType == TaskType.reminder) {
          notificationBody = _getReminderNotificationBody(task);
          notificationKind = 'Reminder';
        } else {
          notificationBody = _getTaskNotificationBody(task);
          notificationKind = switch (task.notificationType) {
            NotificationType.daily => 'Daily task',
            NotificationType.beforeEnd => 'Task due soon',
            NotificationType.specificTime => 'Task',
          };
        }

        DateTimeComponents? dateTimeComponents;
        // For daily notifications, repeat daily at the same time
        if (task.notificationType == NotificationType.daily) {
          dateTimeComponents = DateTimeComponents.time;
        }

        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: task.id.hashCode,
          title: notificationTitle,
          body: notificationBody,
          scheduledDate: scheduledDate,
          notificationDetails: _getNotificationDetails(
            task.taskType,
            task.id,
            body: notificationBody,
            kind: notificationKind,
            when: scheduledNotificationTime,
          ),
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
      } else {
        debugPrint('🔔 Scheduled time is not in the future, not scheduling');
      }
    } else {
      debugPrint('🔔 scheduledNotificationTime is null');
    }

    // If task is pinned to notification, create a persistent notification
    // Only show before notification if pinNotificationTiming is beforeNotification
    if (task.isPinnedToNotification && task.isActive && !task.isCompleted) {
      if (task.pinNotificationTiming ==
          PinNotificationTiming.beforeNotification) {
        await _showPersistentNotification(task);
      }
    }
  }

  Future<void> _scheduleBirthdayNotifications(Task task) async {
    debugPrint(
      '🎂 Scheduling multiple birthday notifications for: ${task.title}',
    );

    final notificationTimes = task.getBirthdayNotificationTimes();
    debugPrint('🎂 Found ${notificationTimes.length} notification times');

    for (int i = 0; i < notificationTimes.length; i++) {
      final notificationTime = notificationTimes[i];
      final option =
          task.birthdayNotificationSchedule[i %
              task.birthdayNotificationSchedule.length];

      final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      if (scheduledDate.isAfter(now)) {
        String title;
        String body;

        // Title is the person; the body says when and why you're hearing
        // about it now. "Tomorrow" and "In two hours" are the useful part.
        title = task.title;
        final String kind;
        switch (option) {
          case BirthdayNotificationOption.oneDayBefore:
            body = 'Birthday tomorrow — time to sort a gift if you need one.';
            kind = 'Birthday tomorrow';
            break;
          case BirthdayNotificationOption.twoHoursBefore:
            body = 'Birthday in two hours.';
            kind = 'Birthday today';
            break;
          case BirthdayNotificationOption.tenMinutesBefore:
            body = 'Birthday in ten minutes.';
            kind = 'Birthday today';
            break;
          case BirthdayNotificationOption.exactTime:
            body = 'It\'s their birthday today. Send them something.';
            kind = 'Birthday today';
            break;
        }

        // Use unique notification ID for each birthday notification
        final notificationId = task.id.hashCode + (i * 1000);

        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: _getNotificationDetails(
            task.taskType,
            task.id,
            body: body,
            kind: kind,
            when: notificationTime,
          ),
          payload: task.id,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        debugPrint(
          '🎂 Scheduled ${option.displayName} notification for: $scheduledDate',
        );
      } else {
        debugPrint('🎂 Skipping past notification time: $scheduledDate');
      }
    }

    // If task is pinned to notification, create a persistent notification
    if (task.isPinnedToNotification && task.isActive && !task.isCompleted) {
      await _showPersistentNotification(task);
    }
  }

  Future<void> _showPersistentNotification(
    Task task, {
    Duration? duration,
  }) async {
    String title;
    String content;
    Color notificationColor;
    String summaryText;
    String detailedContent;

    // An ongoing notification sits in the shade all day, so it has to be
    // readable at a glance and quiet the rest of the time. One line of status,
    // a couple of lines when expanded, and no emoji competing with the app
    // icon that is already right beside it.
    final fmt = DateFormat('d MMM, HH:mm');

    switch (task.taskType) {
      case TaskType.task:
        title = task.title;
        content =
            '${task.timeLeftFormatted} left · '
            '${(task.progressPercentage * 100).toStringAsFixed(0)}% done';
        notificationColor = _taskColor;
        summaryText = 'Task';
        detailedContent =
            'Due ${fmt.format(task.endDate)}\n'
            '${task.timeLeftFormatted} left · '
            '${(task.progressPercentage * 100).toStringAsFixed(0)}% done';
        break;

      case TaskType.reminder:
        final now = DateTime.now();
        final timeUntil = task.endDate.difference(now);
        final isPast = now.isAfter(task.endDate);

        title = task.title;
        if (isPast) {
          content = 'This one has passed';
          detailedContent = 'Was set for ${fmt.format(task.endDate)}';
        } else {
          final days = timeUntil.inDays;
          final hours = timeUntil.inHours % 24;
          final minutes = timeUntil.inMinutes % 60;

          if (days > 0) {
            content = 'In ${days}d ${hours}h';
          } else if (hours > 0) {
            content = 'In ${hours}h ${minutes}m';
          } else {
            content = 'In ${minutes}m';
          }
          detailedContent = '${fmt.format(task.endDate)}\n$content';
        }
        notificationColor = _reminderColor;
        summaryText = 'Reminder';
        break;

      case TaskType.birthday:
        final now = DateTime.now();
        final birthdayThisYear = DateTime(
          now.year,
          task.endDate.month,
          task.endDate.day,
        );
        final today = DateTime(now.year, now.month, now.day);
        final nextBirthday = today.isAfter(birthdayThisYear)
            ? DateTime(now.year + 1, task.endDate.month, task.endDate.day)
            : birthdayThisYear;
        final daysUntil = nextBirthday.difference(today).inDays;
        final turning = nextBirthday.year - task.endDate.year;
        final age = task.endDate.year < now.year && turning > 0
            ? ' · turning $turning'
            : '';

        title = task.title;
        if (daysUntil == 0) {
          content = 'Birthday today$age';
        } else if (daysUntil == 1) {
          content = 'Birthday tomorrow$age';
        } else {
          content = 'Birthday in $daysUntil days$age';
        }
        detailedContent =
            '${DateFormat('d MMMM').format(nextBirthday)}\n$content';
        notificationColor = _birthdayColor;
        summaryText = 'Birthday';
        break;
    }

    await _flutterLocalNotificationsPlugin.show(
      id: task.id.hashCode + 10000, // Different ID for persistent notification
      title: title,
      body: content,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelPersistent,
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
          timeoutAfter: duration?.inMilliseconds,
          color: notificationColor,
          icon: '@mipmap/ic_launcher',
          // Use a custom style to make it more prominent
          subText: summaryText,
          groupKey: switch (task.taskType) {
            TaskType.task => _groupTasks,
            TaskType.reminder => _groupReminders,
            TaskType.birthday => _groupBirthdays,
          },
          styleInformation: BigTextStyleInformation(
            detailedContent,
            htmlFormatBigText: false,
            contentTitle: title,
            htmlFormatContentTitle: false,
          ),
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

  /// Actions on an ongoing notification, which is a control surface rather
  /// than an alert. "Details" is dropped: the notification body already is
  /// the detail, and tapping it opens the page.
  List<AndroidNotificationAction> _getPersistentNotificationActions(
    TaskType taskType,
  ) {
    return switch (taskType) {
      TaskType.task => [_action('mark_done', 'Complete')],
      TaskType.reminder => [
        _action('mark_done', 'Done'),
        _action('snooze_15', 'Snooze 15 min'),
      ],
      TaskType.birthday => [
        _action('send_message', 'Send wishes'),
        _action('mark_done', 'Wished them'),
      ],
    };
  }

  Future<void> updatePersistentNotification(Task task) async {
    if (task.isPinnedToNotification && task.isActive && !task.isCompleted) {
      await _showPersistentNotification(task);
    } else {
      await cancelPersistentNotification(task);
    }
  }

  Future<void> cancelTaskNotification(Task task) async {
    await _cancelEveryNotificationFor(task.id);
    await cancelPersistentNotification(task);
  }

  /// Clears every notification id a task could own.
  ///
  /// Birthdays occupy one id per scheduled reminder (`hash + i * 1000`), and
  /// both cancel paths used to sweep only as far as the *current* schedule:
  /// turning a reminder off left the id it had already claimed still armed, so
  /// the reminder you just unchecked went off anyway. Deleting a birthday was
  /// worse — that path didn't clear the extra ids at all, so a person you had
  /// removed still wished you happy birthday. Sweeping the whole possible
  /// range is four cheap calls and can't leave anything behind.
  Future<void> _cancelEveryNotificationFor(String taskId) async {
    final base = taskId.hashCode;
    await _flutterLocalNotificationsPlugin.cancel(id: base);
    for (var i = 0; i < BirthdayNotificationOption.values.length; i++) {
      await _flutterLocalNotificationsPlugin.cancel(id: base + (i * 1000));
    }
  }

  Future<void> cancelPersistentNotification(Task task) async {
    await _flutterLocalNotificationsPlugin.cancel(id: task.id.hashCode + 10000);
  }

  /// Cancel notification by ID only (useful when task object is not available)
  Future<void> cancelNotificationById(String taskId) async {
    debugPrint('🔔 Cancelling notification for task ID: $taskId');
    await _cancelEveryNotificationFor(taskId);
    // The pinned notification lives well clear of the birthday block.
    await _flutterLocalNotificationsPlugin.cancel(id: taskId.hashCode + 10000);
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
          bool shouldShow = false;
          final scheduledTime = task.getScheduledNotificationTime();

          // Use timezone aware current time for comparison if scheduledTime is timezone aware
          // But getScheduledNotificationTime returns DateTime (which might be TZDateTime)
          // Let's use standard DateTime.now() for comparison as getScheduledNotificationTime returns DateTime
          final now = DateTime.now();

          if (task.pinNotificationTiming ==
              PinNotificationTiming.beforeNotification) {
            // Show only if before scheduled time
            if (scheduledTime != null && now.isBefore(scheduledTime)) {
              shouldShow = true;
            } else if (scheduledTime == null) {
              // If no scheduled time, show always (fallback)
              shouldShow = true;
            }
          } else if (task.pinNotificationTiming ==
              PinNotificationTiming.afterNotification) {
            // Show only if after scheduled time (and within 12 hours)
            if (scheduledTime != null &&
                now.isAfter(scheduledTime) &&
                now.difference(scheduledTime).inHours < 12) {
              shouldShow = true;
            }
          }

          if (shouldShow) {
            // Ensure notification exists, recreate if dismissed
            await _ensureNotificationExists(task);
            // Create a fresh task instance with current time for accurate progress
            final freshTask = task.copyWith();
            await _showPersistentNotification(freshTask);
          } else {
            // Ensure it's cancelled if it shouldn't be shown
            // This handles the "vanish" requirement for beforeNotification
            await cancelPersistentNotification(task);
          }
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

  Future<void> updateActiveTasks(List<Task> tasks) async {
    debugPrint('🔔 📝 updateActiveTasks called with ${tasks.length} tasks');
    _activeTasks = tasks;

    // 1. Garbage collect: Cancel notifications for tasks that are no longer active
    // This ensures robust sync whenever the task list changes
    try {
      final activeTaskIds = tasks.map((t) => t.id).toSet();

      // Check active (showing) notifications
      final activeNotifications = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.getActiveNotifications();

      if (activeNotifications != null) {
        for (final notification in activeNotifications) {
          final payload = notification.payload;
          // Only check task notifications (exclude medicines which start with medicine_)
          if (payload != null && !payload.startsWith('medicine_')) {
            if (!activeTaskIds.contains(payload)) {
              debugPrint(
                '🔔 🗑️ Auto-sync: Cancelling orphan task notification: $payload',
              );
              if (notification.id != null) {
                await _flutterLocalNotificationsPlugin.cancel(
                  id: notification.id!,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('🔔 ⚠️ Error during auto-sync garbage collection: $e');
    }

    // 2. Update existing persistent notifications
    await _refreshPersistentNotifications();
  }

  // Refresh all persistent notifications based on current active tasks
  Future<void> _refreshPersistentNotifications() async {
    for (final task in _activeTasks) {
      // Check if we should show persistent notification
      if (task.isPinnedToNotification && task.isActive && !task.isCompleted) {
        bool shouldShow = false;
        final scheduledTime = task.getScheduledNotificationTime();
        final now = DateTime.now();

        if (task.pinNotificationTiming ==
            PinNotificationTiming.beforeNotification) {
          // Show only if before scheduled time
          if (scheduledTime != null && now.isBefore(scheduledTime)) {
            shouldShow = true;
          } else if (scheduledTime == null) {
            shouldShow = true;
          }
        } else if (task.pinNotificationTiming ==
            PinNotificationTiming.afterNotification) {
          // Show only if after scheduled time (and within 12 hours)
          if (scheduledTime != null &&
              now.isAfter(scheduledTime) &&
              now.difference(scheduledTime).inHours < 12) {
            shouldShow = true;
          }
        }

        if (shouldShow) {
          await _showPersistentNotification(task);
        } else {
          await cancelPersistentNotification(task);
        }
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
      id: 999999,
      title: 'Test notification',
      body: 'This is an immediate test notification to verify the system works',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelTasks,
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
      id: task.id.hashCode + 50000, // Unique test ID
      title: 'Test: ${task.title}',
      body: 'Test notification for real task - try the action buttons!',
      notificationDetails: _getNotificationDetails(task.taskType, task.id),
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
      id: 999998,
      title: 'Scheduled test',
      body:
          'This test notification was scheduled 10 seconds ago - if you see this, scheduled notifications work!',
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelTasks,
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
        id: 123456, // Simple test ID
        title: 'Simple test',
        body: 'This is a simple test notification scheduled for 10 seconds',
        scheduledDate: scheduledTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelTasks,
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

  // Notification ID tracking methods
  Future<void> _saveMedicineNotificationIds(
    String medicineId,
    List<int> notificationIds,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allIds = await _getAllMedicineNotificationIds();
      allIds[medicineId] = notificationIds;
      await prefs.setString(_medicineNotificationIdsKey, jsonEncode(allIds));
      debugPrint(
        '🩺 Saved ${notificationIds.length} notification IDs for medicine $medicineId',
      );
    } catch (e) {
      debugPrint('🩺 Error saving notification IDs: $e');
    }
  }

  Future<List<int>> _getMedicineNotificationIds(String medicineId) async {
    try {
      final allIds = await _getAllMedicineNotificationIds();
      return allIds[medicineId] ?? [];
    } catch (e) {
      debugPrint('🩺 Error getting notification IDs: $e');
      return [];
    }
  }

  Future<Map<String, List<int>>> _getAllMedicineNotificationIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idsJson = prefs.getString(_medicineNotificationIdsKey);
      if (idsJson == null) return {};

      final Map<String, dynamic> decoded = jsonDecode(idsJson);
      final Map<String, List<int>> result = {};
      for (final entry in decoded.entries) {
        result[entry.key] = List<int>.from(entry.value);
      }
      return result;
    } catch (e) {
      debugPrint('🩺 Error reading notification IDs: $e');
      return {};
    }
  }

  Future<void> _removeMedicineNotificationIds(String medicineId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allIds = await _getAllMedicineNotificationIds();
      allIds.remove(medicineId);
      await prefs.setString(_medicineNotificationIdsKey, jsonEncode(allIds));
      debugPrint(
        '🩺 Removed notification ID tracking for medicine $medicineId',
      );
    } catch (e) {
      debugPrint('🩺 Error removing notification IDs: $e');
    }
  }

  // Medicine notification methods

  /// Cancel notifications for any medicine whose course has ended (endDate
  /// in the past). Without this, the daily-repeat scheduler at
  /// [_scheduleTimeBasedMedicineNotification] would keep firing forever for
  /// finished prescriptions.
  Future<void> cancelExpiredMedicineNotifications(
    MedicineRepository medicineRepository,
  ) async {
    debugPrint('🩺 Sweeping expired medicines...');
    try {
      final result = await medicineRepository.getAllMedicines();
      await result.fold(
        (failure) async =>
            debugPrint('🩺 ❌ Failed to fetch medicines for sweep: $failure'),
        (medicines) async {
          final now = DateTime.now();
          int cancelled = 0;
          for (final medicine in medicines) {
            final end =
                medicine.endDate ??
                medicine.startDate.add(Duration(days: medicine.durationInDays));
            if (now.isAfter(end)) {
              await cancelMedicineNotifications(medicine.id);
              cancelled++;
            }
          }
          debugPrint(
            '🩺 Sweep cancelled $cancelled expired medicine schedules',
          );
        },
      );
    } catch (e) {
      debugPrint('🩺 ❌ Error sweeping expired medicines: $e');
    }
  }

  /// Synchronizes notifications with the current database state.
  /// This handles:
  /// 1. Cancelling "orphan" notifications (e.g. if data was cleared but notifications remain).
  /// 2. Rescheduling notifications for all active medicines and tasks to ensure consistency.
  Future<void> syncNotifications(
    MedicineRepository medicineRepository,
    TaskRepository taskRepository,
  ) async {
    debugPrint('🔔 🔄 Starting notification synchronization...');

    try {
      // 0. Kill notifications for medicines whose course ended.
      await cancelExpiredMedicineNotifications(medicineRepository);

      // 1. Get all pending notifications from the system
      final pendingNotifications = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      debugPrint(
        '🔔 📋 Found ${pendingNotifications.length} pending notifications in system',
      );

      // 2. Get all active medicines and tasks
      final medicineResult = await medicineRepository.getActiveMedicines();
      final taskResult = await taskRepository.getActiveTasks();

      await medicineResult.fold(
        (failure) async =>
            debugPrint('🔔 ❌ Failed to fetch active medicines: $failure'),
        (activeMedicines) async {
          await taskResult.fold(
            (failure) async =>
                debugPrint('🔔 ❌ Failed to fetch active tasks: $failure'),
            (activeTasks) async {
              debugPrint(
                '🔔 💊 Found ${activeMedicines.length} active medicines',
              );
              debugPrint('🔔 📝 Found ${activeTasks.length} active tasks');

              final activeMedicineIds = activeMedicines
                  .map((m) => m.id)
                  .toSet();
              final activeTaskIds = activeTasks.map((t) => t.id).toSet();

              // 3. Identify and cancel orphan notifications
              int cancelledCount = 0;

              // Check pending (scheduled) notifications
              for (final notification in pendingNotifications) {
                final payload = notification.payload;
                if (payload != null) {
                  if (payload.startsWith('medicine_')) {
                    final medicineId = payload.substring(9);
                    if (!activeMedicineIds.contains(medicineId)) {
                      debugPrint(
                        '🔔 🗑️ Cancelling orphan medicine notification (pending): $medicineId',
                      );
                      await _flutterLocalNotificationsPlugin.cancel(
                        id: notification.id,
                      );
                      cancelledCount++;
                    }
                  } else if (!payload.startsWith(todoPayloadPrefix)) {
                    // Assume task ID. To-dos are skipped here and reconciled
                    // by syncTodoNotifications, which knows their repository.
                    if (!activeTaskIds.contains(payload)) {
                      debugPrint(
                        '🔔 🗑️ Cancelling orphan task notification (pending): $payload',
                      );
                      await _flutterLocalNotificationsPlugin.cancel(
                        id: notification.id,
                      );
                      cancelledCount++;
                    }
                  }
                }
              }

              // Check active (currently showing) notifications - crucial for pinned notifications
              final activeNotifications = await _flutterLocalNotificationsPlugin
                  .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin
                  >()
                  ?.getActiveNotifications();

              debugPrint(
                '🔔 📋 Found ${activeNotifications?.length ?? 0} active (showing) notifications',
              );

              if (activeNotifications != null) {
                for (final notification in activeNotifications) {
                  final payload = notification.payload;
                  if (payload != null) {
                    if (payload.startsWith('medicine_')) {
                      final medicineId = payload.substring(9);
                      if (!activeMedicineIds.contains(medicineId)) {
                        if (notification.id != null) {
                          debugPrint(
                            '🔔 🗑️ Cancelling orphan medicine notification (active): $medicineId',
                          );
                          await _flutterLocalNotificationsPlugin.cancel(
                            id: notification.id!,
                          );
                          cancelledCount++;
                        }
                      }
                    } else if (!payload.startsWith(todoPayloadPrefix)) {
                      // Assume task ID — see the note above.
                      if (!activeTaskIds.contains(payload)) {
                        if (notification.id != null) {
                          debugPrint(
                            '🔔 🗑️ Cancelling orphan task notification (active): $payload',
                          );
                          await _flutterLocalNotificationsPlugin.cancel(
                            id: notification.id!,
                          );
                          cancelledCount++;
                        }
                      }
                    }
                  }
                }
              }

              debugPrint(
                '🔔 🗑️ Cancelled $cancelledCount orphan notifications',
              );

              // 4. Reschedule notifications for all active medicines
              int rescheduledMedicines = 0;
              for (final medicine in activeMedicines) {
                await scheduleMedicineNotifications(medicine);
                rescheduledMedicines++;
              }

              // 5. Reschedule notifications for all active tasks
              int rescheduledTasks = 0;
              for (final task in activeTasks) {
                await scheduleTaskNotification(task);
                rescheduledTasks++;
              }

              debugPrint(
                '🔔 🔄 Rescheduled: $rescheduledMedicines medicines, $rescheduledTasks tasks',
              );
            },
          );
        },
      );

      debugPrint('🔔 ✅ Notification synchronization completed');
    } catch (e) {
      debugPrint('🔔 ❌ Error during notification synchronization: $e');
    }
  }

  // ── To-do reminders ─────────────────────────────────────────────────────

  /// Stable notification id for a to-do, drawn from a persistent map so the
  /// same to-do always gets the same id (and can therefore be cancelled and
  /// rescheduled) without ever colliding with tasks or medicines.
  Future<int> _generateTodoNotificationId(String todoId) async {
    final key = 'todo_$todoId';
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString(_todoNotificationIdMapKey);
      final Map<String, dynamic> map = mapJson == null
          ? <String, dynamic>{}
          : jsonDecode(mapJson) as Map<String, dynamic>;

      final existing = map[key];
      if (existing is int) return existing;

      final nextId =
          prefs.getInt(_todoNotificationIdCounterKey) ?? _todoIdCounterStart;
      map[key] = nextId;
      await prefs.setString(_todoNotificationIdMapKey, jsonEncode(map));
      await prefs.setInt(_todoNotificationIdCounterKey, nextId + 1);
      return nextId;
    } catch (e) {
      debugPrint('✅ To-do ID-map error, falling back to hashCode for $key: $e');
      return key.hashCode.abs() % 2147483647;
    }
  }

  /// Schedules (or clears) the reminder for a single to-do.
  ///
  /// Always cancels first, so this is safe to call after any edit: turning the
  /// reminder off, completing the to-do, or moving its time all end up doing
  /// the right thing without the caller having to work out which case it is.
  Future<void> scheduleTodoNotification(Todo todo) async {
    await cancelTodoNotification(todo.id);

    if (!todo.hasReminder || todo.reminderTime == null || todo.isCompleted) {
      debugPrint('✅ No reminder to schedule for to-do: ${todo.title}');
      return;
    }

    final scheduledDate = tz.TZDateTime.from(todo.reminderTime!, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!scheduledDate.isAfter(now)) {
      debugPrint(
        '✅ Reminder for "${todo.title}" is in the past ($scheduledDate), '
        'not scheduling',
      );
      return;
    }

    final id = await _generateTodoNotificationId(todo.id);
    final body = _getTodoNotificationBody(todo);

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: todo.title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: _androidAlert(
            channelId: channelTodos,
            channelName: 'To-Do Reminders',
            kind: 'To-do',
            color: _todoColor,
            body: body,
            group: _groupTodos,
            when: todo.reminderTime,
            actions: [
              _action('todo_done', 'Mark done'),
              _action('todo_snooze', 'Snooze 1 hour'),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: '$todoPayloadPrefix${todo.id}',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint(
        '✅ 🔔 To-do reminder scheduled: ${todo.title} at $scheduledDate',
      );
    } catch (e) {
      debugPrint('✅ ❌ Failed to schedule to-do reminder: $e');
    }
  }

  Future<void> cancelTodoNotification(String todoId) async {
    final id = await _generateTodoNotificationId(todoId);
    await _flutterLocalNotificationsPlugin.cancel(id: id);
    debugPrint('✅ 🗑️ Cancelled to-do reminder for $todoId (id $id)');
  }

  String _getTodoNotificationBody(Todo todo) {
    final parts = <String>[];

    final description = todo.description?.trim();
    if (description != null && description.isNotEmpty) parts.add(description);

    final due = todo.dueDate;
    if (due != null) {
      if (todo.isDueToday) {
        parts.add('Due today');
      } else if (todo.isDueTomorrow) {
        parts.add('Due tomorrow');
      } else if (todo.isOverdue) {
        parts.add('Overdue since ${DateFormat('d MMM').format(due)}');
      } else {
        parts.add('Due ${DateFormat('d MMM').format(due)}');
      }
    }

    // Category is worth a word; "Medium priority" on every single to-do is
    // noise, so only an urgent one says so.
    if (todo.priority == TodoPriority.urgent ||
        todo.priority == TodoPriority.high) {
      parts.add('${todo.priority.displayName} priority');
    }
    parts.add(todo.category.displayName);
    return parts.join(' · ');
  }

  /// Handles the "Mark as done" / "Snooze" buttons on a to-do reminder.
  Future<void> _handleTodoNotificationAction(
    String actionId,
    String todoId,
  ) async {
    debugPrint('✅ Handling to-do action "$actionId" for $todoId');

    late final TodoRepository repository;
    try {
      repository = di.sl<TodoRepository>();
    } catch (e) {
      debugPrint('✅ ❌ Todo repository unavailable: $e');
      return;
    }

    final lookup = await repository.getTodoById(todoId);
    final todo = lookup.fold((failure) => null, (value) => value);
    if (todo == null) {
      debugPrint(
        '✅ ⚠️ To-do $todoId no longer exists, cancelling its reminder',
      );
      await cancelTodoNotification(todoId);
      return;
    }

    switch (actionId) {
      case 'todo_done':
        final result = await repository.completeTodo(todoId);
        await result.fold(
          (failure) async =>
              debugPrint('✅ ❌ Could not complete to-do $todoId: $failure'),
          (_) async {
            await cancelTodoNotification(todoId);
            await _showActionFeedbackNotification(
              'Done',
              '"${todo.title}" is off your list',
              const Color(0xFF10B981),
            );
          },
        );
        break;

      case 'todo_snooze':
        final snoozed = todo.copyWith(
          reminderTime: DateTime.now().add(const Duration(hours: 1)),
          hasReminder: true,
        );
        final result = await repository.updateTodo(snoozed);
        await result.fold(
          (failure) async =>
              debugPrint('✅ ❌ Could not snooze to-do $todoId: $failure'),
          (_) async {
            await scheduleTodoNotification(snoozed);
            await _showActionFeedbackNotification(
              'Snoozed',
              '"${todo.title}" will remind you again in an hour',
              const Color(0xFF3B82F6),
            );
          },
        );
        break;

      default:
        debugPrint('✅ Unknown to-do action: $actionId');
        return;
    }

    // Refresh the list if the app happens to be running.
    try {
      di.sl<TodoBloc>().add(LoadTodos());
    } catch (e) {
      debugPrint('✅ To-do list not loaded, skipping refresh: $e');
    }
  }

  /// Re-syncs every to-do reminder with what is actually stored.
  ///
  /// Reminders that belong to deleted or completed to-dos are dropped, and the
  /// rest are rescheduled — the reboot/upgrade path, where Android has thrown
  /// away all pending alarms.
  Future<void> syncTodoNotifications(TodoRepository repository) async {
    debugPrint('✅ 🔄 Syncing to-do reminders...');
    try {
      final result = await repository.getAllTodos();
      await result.fold(
        (failure) async => debugPrint('✅ ❌ Could not read to-dos: $failure'),
        (todos) async {
          final live = {for (final t in todos) '$todoPayloadPrefix${t.id}'};

          final pending = await _flutterLocalNotificationsPlugin
              .pendingNotificationRequests();
          final queued = pending
              .where((n) => n.payload?.startsWith(todoPayloadPrefix) ?? false)
              .toList();
          debugPrint(
            '✅ 📋 ${queued.length} to-do reminder(s) queued with the system: '
            '${queued.map((n) => '${n.id}:${n.title}').join(', ')}',
          );
          for (final notification in pending) {
            final payload = notification.payload;
            if (payload == null) continue;
            if (!payload.startsWith(todoPayloadPrefix)) continue;
            if (!live.contains(payload)) {
              debugPrint('✅ 🗑️ Cancelling orphan to-do reminder: $payload');
              await _flutterLocalNotificationsPlugin.cancel(
                id: notification.id,
              );
            }
          }

          var rescheduled = 0;
          for (final todo in todos) {
            if (!todo.hasReminder || todo.isCompleted) continue;
            await scheduleTodoNotification(todo);
            rescheduled++;
          }
          debugPrint('✅ 🔄 Rescheduled $rescheduled to-do reminders');
        },
      );
    } catch (e) {
      debugPrint('✅ ❌ Error syncing to-do reminders: $e');
    }
  }

  Future<void> scheduleMedicineNotifications(Medicine medicine) async {
    debugPrint('🩺 Scheduling notifications for medicine: ${medicine.name}');

    // Cancel existing notifications for this medicine
    await cancelMedicineNotifications(medicine.id);

    if (medicine.status != MedicineStatus.active) {
      debugPrint('🩺 Medicine is not active, skipping notifications');
      return;
    }

    // Don't schedule for a medicine whose course has already ended. Without
    // this guard the daily-repeat scheduler below would keep firing forever
    // even though the prescription is over.
    final medicineEndDate =
        medicine.endDate ??
        medicine.startDate.add(Duration(days: medicine.durationInDays));
    if (DateTime.now().isAfter(medicineEndDate)) {
      debugPrint(
        '🩺 Medicine ${medicine.name} ended on $medicineEndDate — skipping notifications',
      );
      return;
    }

    // Schedule notifications for each notification time and track their IDs
    final List<int> scheduledIds = [];
    for (final timeString in medicine.notificationTimes) {
      final notificationId = await _scheduleTimeBasedMedicineNotification(
        medicine,
        timeString,
      );
      if (notificationId != null) {
        scheduledIds.add(notificationId);
      }
    }

    // Save the notification IDs for this medicine
    await _saveMedicineNotificationIds(medicine.id, scheduledIds);

    debugPrint(
      '🩺 Scheduled ${scheduledIds.length} notifications for ${medicine.name} (IDs: $scheduledIds)',
    );
  }

  Future<int?> _scheduleTimeBasedMedicineNotification(
    Medicine medicine,
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
        return null;
      }

      final notificationId = await _generateMedicineNotificationId(
        medicine.id,
        timeString,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: notificationId,
        title: _medicineNotificationTitle(medicine),
        body: _getMedicineNotificationBody(medicine),
        scheduledDate: tz.TZDateTime.from(notificationDate, tz.local),
        notificationDetails: _getMedicineNotificationDetails(
          medicine,
          notificationDate,
        ),
        payload: 'medicine_${medicine.id}',
        matchDateTimeComponents:
            DateTimeComponents.time, // Repeat daily at same time
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint(
        '🩺 Scheduled notification for ${medicine.name} at $timeString (ID: $notificationId)',
      );
      return notificationId;
    } catch (e) {
      debugPrint('🩺 Error scheduling notification for time $timeString: $e');
      return null;
    }
  }

  NotificationDetails _getMedicineNotificationDetails(
    Medicine medicine, [
    DateTime? when,
  ]) {
    return NotificationDetails(
      android: _androidAlert(
        channelId: channelMedicines,
        channelName: 'Medicine Reminders',
        kind: 'Medicine',
        color: _medicineColor,
        body: _getMedicineNotificationBody(medicine),
        group: _groupMedicines,
        when: when,
        actions: [
          _action('take_medicine', _l.medNotifTaken),
          _action('skip_medicine', _l.medNotifSkip),
          _action('snooze_medicine', _l.medNotifSnooze),
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

  // ── Follow-up nudges for doses that went unanswered ──────────────────────

  /// Follow-ups live in their own id range so they never collide with the
  /// daily medicine reminders.
  static const int _doseFollowUpIdBase = 810000000;

  /// How long after the scheduled time to ask again.
  static const Duration doseFollowUpDelay = Duration(minutes: 20);

  int _doseFollowUpId(String doseId) =>
      _doseFollowUpIdBase + (doseId.hashCode.abs() % 10000000);

  /// Schedules a second nudge for each of today's doses that is still pending.
  ///
  /// One-shot, and only for the doses in hand — a year-long course would
  /// otherwise want thousands of pending alarms, well past what Android will
  /// hold. It is refreshed whenever the dashboard loads, which is also when a
  /// dose is ticked off, so a resolved dose loses its follow-up straight away.
  Future<void> scheduleDoseFollowUps(
    List<Medicine> medicines,
    List<MedicineDose> doses,
  ) async {
    final byId = {for (final m in medicines) m.id: m};
    final now = DateTime.now();

    for (final dose in doses) {
      final id = _doseFollowUpId(dose.id);
      // Always clear first: this runs on every load, and a dose that has since
      // been taken must lose the nudge it was given earlier.
      await _flutterLocalNotificationsPlugin.cancel(id: id);

      if (dose.status != DoseStatus.pending) continue;
      final medicine = byId[dose.medicineId];
      if (medicine == null) continue;

      final when = dose.scheduledTime.add(doseFollowUpDelay);
      // Past its follow-up already: the dashboard asks about those directly,
      // and a notification for a moment gone by would only confuse.
      if (!when.isAfter(now)) continue;

      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id: id,
          title: _l.medNotifStillPending,
          body:
              '${_medicineNotificationTitle(medicine)} · '
              '${_getMedicineNotificationBody(medicine)}',
          scheduledDate: tz.TZDateTime.from(when, tz.local),
          // Asks about this dose rather than repeating the reminder: by now
          // the answer is either "already took it" or "missed it", and both
          // can be given without opening the app.
          notificationDetails: _doseQuestionDetails(medicine, when),
          payload: '$dosePayloadPrefix${dose.id}',
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('🩺 Could not schedule follow-up for ${dose.id}: $e');
      }
    }
  }

  /// Payload marker for a notification that asks about one dose by id.
  static const String dosePayloadPrefix = 'dose_';

  static const String actionDoseTaken = 'dose_taken';
  static const String actionDoseMissed = 'dose_missed';

  NotificationDetails _doseQuestionDetails(Medicine medicine, DateTime when) {
    return NotificationDetails(
      android: _androidAlert(
        channelId: channelMedicines,
        channelName: 'Medicine Reminders',
        kind: 'Medicine',
        color: _medicineColor,
        body: _getMedicineNotificationBody(medicine),
        group: _groupMedicines,
        when: when,
        actions: [
          _action(actionDoseTaken, _l.medCatchUpTaken),
          _action(actionDoseMissed, _l.medCatchUpMissed),
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

  /// Answers a dose question straight from the notification.
  Future<void> _handleDoseAnswer(String actionId, String doseId) async {
    await _ensureServicesReady();
    try {
      final cubit = di.sl<MedicineCubit>();
      if (actionId == actionDoseTaken) {
        await cubit.markDoseAsTaken(doseId, '');
        await _showActionFeedbackNotification(
          _l.medNotifAskTitle,
          _l.medNotifFeedbackTaken,
          const Color(0xFF4CAF50),
        );
      } else {
        await cubit.markDoseAsMissed(doseId, '');
        await _showActionFeedbackNotification(
          _l.medNotifAskTitle,
          _l.medNotifFeedbackMissed,
          const Color(0xFFEF4444),
        );
      }
    } catch (e) {
      debugPrint('🩺 Could not answer dose $doseId: $e');
    }
  }

  /// Cancels the follow-ups for a whole set of doses — used when the medicine
  /// they belong to is deleted, so nothing nudges about a course that no
  /// longer exists.
  Future<void> cancelDoseFollowUps(Iterable<String> doseIds) async {
    for (final doseId in doseIds) {
      await cancelDoseFollowUp(doseId);
    }
  }

  /// Drops the follow-up for a dose the moment it is answered, so ticking a
  /// dose in the app silences the nudge without waiting for a reload.
  Future<void> cancelDoseFollowUp(String doseId) =>
      _flutterLocalNotificationsPlugin.cancel(id: _doseFollowUpId(doseId));

  Future<void> cancelMedicineNotifications(String medicineId) async {
    debugPrint('🩺 Cancelling notifications for medicine: $medicineId');

    final Set<int> idsToCancel = {};

    // 1. Tracked IDs from SharedPreferences (the fast path).
    final trackedIds = await _getMedicineNotificationIds(medicineId);
    idsToCancel.addAll(trackedIds);

    // 2. Sweep the OS scheduler by payload. This catches notifications that
    //    were scheduled before the tracking system existed, or that drifted
    //    out of sync (data cleared / backup restored / mid-update crash).
    //    Without this sweep, deleting a medicine would leave the OS still
    //    firing reminders for it forever.
    try {
      final pending = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      final expectedPayload = 'medicine_$medicineId';
      for (final n in pending) {
        if (n.payload == expectedPayload) {
          idsToCancel.add(n.id);
        }
      }
    } catch (e) {
      debugPrint('🩺 Error scanning pending notifications: $e');
    }

    if (idsToCancel.isEmpty) {
      debugPrint('🩺 Nothing to cancel for medicine $medicineId');
      await _removeMedicineNotificationIds(medicineId);
      return;
    }

    for (final notificationId in idsToCancel) {
      try {
        await _flutterLocalNotificationsPlugin.cancel(id: notificationId);
        debugPrint(
          '🩺 Cancelled notification $notificationId for medicine $medicineId',
        );
      } catch (e) {
        debugPrint('🩺 Error cancelling notification $notificationId: $e');
      }
    }

    // Remove tracking for this medicine
    await _removeMedicineNotificationIds(medicineId);

    debugPrint(
      '🩺 Cancelled ${idsToCancel.length} notifications for medicine $medicineId '
      '(${trackedIds.length} tracked, ${idsToCancel.length - trackedIds.length} swept from OS)',
    );
  }

  /// Clean up orphaned medicine notifications for users who already had the bug
  /// This should be called once on app startup to clean up any existing orphaned notifications
  Future<void> cleanupOrphanedMedicineNotifications(
    List<String> activeMedicineIds,
  ) async {
    debugPrint('🩺 Cleaning up orphaned medicine notifications...');

    try {
      // Get all pending notifications
      final pendingNotifications = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();

      // Get all tracked medicine notification IDs
      final allTrackedIds = await _getAllMedicineNotificationIds();

      int cancelledCount = 0;
      final Set<String> activeMedicineIdSet = activeMedicineIds.toSet();

      // Remove tracking for medicines that no longer exist
      final List<String> medicineIdsToRemove = [];
      for (final medicineId in allTrackedIds.keys) {
        if (!activeMedicineIdSet.contains(medicineId)) {
          medicineIdsToRemove.add(medicineId);
          // Cancel all notifications for this deleted medicine
          for (final notificationId in allTrackedIds[medicineId]!) {
            try {
              await _flutterLocalNotificationsPlugin.cancel(id: notificationId);
              cancelledCount++;
              debugPrint(
                '🩺 Cancelled orphaned notification $notificationId for deleted medicine $medicineId',
              );
            } catch (e) {
              debugPrint(
                '🩺 Error cancelling orphaned notification $notificationId: $e',
              );
            }
          }
        }
      }

      // Remove tracking for deleted medicines
      for (final medicineId in medicineIdsToRemove) {
        await _removeMedicineNotificationIds(medicineId);
      }

      // Also check for medicine notifications that might not be tracked (old system)
      // Look for notifications with medicine-related payloads
      for (final notification in pendingNotifications) {
        // Check if this looks like a medicine notification but isn't tracked
        final String notificationTitle = notification.title ?? '';

        if ((notificationTitle.contains('Medicine Reminder') ||
                notificationTitle.contains('💊')) &&
            !_isNotificationTracked(notification.id, allTrackedIds)) {
          // This appears to be an untracked medicine notification - cancel it
          try {
            await _flutterLocalNotificationsPlugin.cancel(id: notification.id);
            cancelledCount++;
            debugPrint(
              '🩺 Cancelled untracked medicine notification ${notification.id}: $notificationTitle',
            );
          } catch (e) {
            debugPrint(
              '🩺 Error cancelling untracked notification ${notification.id}: $e',
            );
          }
        }
      }

      debugPrint(
        '🩺 Cleanup completed: cancelled $cancelledCount orphaned notifications',
      );
      debugPrint(
        '🩺 Removed tracking for ${medicineIdsToRemove.length} deleted medicines',
      );
    } catch (e) {
      debugPrint('🩺 Error during orphaned notification cleanup: $e');
    }
  }

  bool _isNotificationTracked(
    int notificationId,
    Map<String, List<int>> allTrackedIds,
  ) {
    for (final ids in allTrackedIds.values) {
      if (ids.contains(notificationId)) {
        return true;
      }
    }
    return false;
  }

  /// Verify notification cleanup by listing pending medicine notifications
  /// This is useful for debugging and testing
  Future<Map<String, dynamic>> getMedicineNotificationStatus() async {
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin
          .pendingNotificationRequests();

      final allTrackedIds = await _getAllMedicineNotificationIds();

      final medicineNotifications = pendingNotifications
          .where(
            (n) =>
                (n.title?.contains('Medicine Reminder') ?? false) ||
                (n.title?.contains('💊') ?? false),
          )
          .toList();

      return {
        'totalPendingNotifications': pendingNotifications.length,
        'medicineNotifications': medicineNotifications.length,
        'trackedMedicines': allTrackedIds.keys.length,
        'totalTrackedNotifications': allTrackedIds.values.fold<int>(
          0,
          (sum, list) => sum + list.length,
        ),
        'medicineNotificationDetails': medicineNotifications
            .map((n) => {'id': n.id, 'title': n.title, 'body': n.body})
            .toList(),
        'trackedMedicineIds': allTrackedIds.keys.toList(),
      };
    } catch (e) {
      debugPrint('🩺 Error getting notification status: $e');
      return {'error': e.toString()};
    }
  }

  /// Returns a unique, stable, collision-free notification id for the given
  /// (medicineId, timeString) pair. Backed by a persistent map; new pairs
  /// get the next value from a monotonic counter. Replaces the previous
  /// hashCode-mod approach, which could collide both inside the medicine
  /// space and against the task/birthday id space.
  Future<int> _generateMedicineNotificationId(
    String medicineId,
    String timeString,
  ) async {
    final key = 'med_${medicineId}_$timeString';
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapJson = prefs.getString(_medicineNotificationIdMapKey);
      final Map<String, dynamic> map = mapJson == null
          ? <String, dynamic>{}
          : jsonDecode(mapJson) as Map<String, dynamic>;

      final existing = map[key];
      if (existing is int) return existing;

      final nextId =
          prefs.getInt(_medicineNotificationIdCounterKey) ??
          _medicineIdCounterStart;
      map[key] = nextId;
      await prefs.setString(_medicineNotificationIdMapKey, jsonEncode(map));
      await prefs.setInt(_medicineNotificationIdCounterKey, nextId + 1);
      return nextId;
    } catch (e) {
      debugPrint('🩺 ID-map error, falling back to hashCode for $key: $e');
      // Last-ditch fallback so a transient prefs error doesn't break scheduling.
      return key.hashCode.abs() % 2147483647;
    }
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
            _l.medNotifTaken,
            _l.medNotifFeedbackTaken,
            const Color(0xFF4CAF50),
          );
          break;

        case 'skip_medicine':
          debugPrint('🩺 User skipped dose from notification');

          // Get the current pending dose for this medicine
          await _markCurrentPendingDoseAsSkipped(medicineId, medicineCubit);

          await _showActionFeedbackNotification(
            _l.medNotifSkip,
            _l.medNotifFeedbackSkipped,
            const Color(0xFFFF9800),
          );
          break;

        case 'snooze_medicine':
          debugPrint('🩺 User snoozed dose from notification');
          await _snoozeMedicineNotification(medicineId, 15);
          await _showActionFeedbackNotification(
            _l.medNotifSnooze,
            _l.medNotifFeedbackSnoozed,
            const Color(0xFF2196F3),
          );
          break;

        default:
          debugPrint('🩺 Unknown medicine notification action: $actionId');
      }
    } catch (e) {
      debugPrint('🩺 Error handling medicine notification action: $e');
      await _showActionFeedbackNotification(
        'Something went wrong',
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
      id:
          DateTime.now().millisecondsSinceEpoch %
          100000, // Unique ID for snoozed notification
      title: 'Medicine dose',
      body: 'Snoozed for $minutes minutes.',
      scheduledDate: snoozeTime,
      notificationDetails: NotificationDetails(
        android: _androidAlert(
          channelId: channelMedicines,
          channelName: 'Medicine Reminders',
          kind: 'Snoozed',
          color: _medicineColor,
          body: 'Snoozed for $minutes minutes.',
          group: _groupMedicines,
          actions: [
            _action('take_medicine', 'Taken'),
            _action('skip_medicine', 'Skip dose'),
          ],
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

  /// Helper method to format duration in a human-readable way
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Generate context-aware notification body for tasks
  String _getTaskNotificationBody(Task task) {
    final parts = <String>[];

    // Deadline first — it is the reason the notification exists.
    final timeLeft = task.endDate.difference(DateTime.now());
    if (timeLeft.isNegative) {
      parts.add('Overdue');
    } else if (timeLeft.inMinutes < 60) {
      parts.add('Due in ${timeLeft.inMinutes} min');
    } else if (timeLeft.inHours < 24) {
      parts.add('Due in ${_formatDuration(timeLeft)}');
    } else {
      parts.add('Due ${DateFormat('d MMM, HH:mm').format(task.endDate)}');
    }

    if (task.progressPercentage > 0) {
      parts.add('${(task.progressPercentage * 100).toInt()}% done');
    }

    String body = parts.join(' · ');

    // Add description
    if (task.description != null && task.description!.isNotEmpty) {
      body += '\n\n${task.description}';
    }

    return body;
  }

  /// Generate context-aware notification body for reminders
  String _getReminderNotificationBody(Task task) {
    // A reminder that has just gone off doesn't need to be told the time it
    // went off in — Android stamps that on the notification itself. The note
    // you left yourself is the useful part; the time is the fallback.
    final description = task.description?.trim();
    if (description != null && description.isNotEmpty) return description;

    return 'Set for ${DateFormat('HH:mm').format(task.endDate)}';
  }

  /// The string bundle for the app's current language.
  ///
  /// Notifications are built far from the widget tree, so there is no context
  /// to read — `Intl.defaultLocale` is set alongside the app language and is
  /// the same source `Clock` and `N` use.
  L get _l => lookupL(Locale((Intl.defaultLocale ?? 'en').split('_').first));

  /// What a medicine reminder should say.
  ///
  /// This used to read `medicine.timing` and `medicine.dosageAmount` off a
  /// `dynamic` inside a try/catch — neither field exists on Medicine, so both
  /// silently failed and every reminder said "Take 500.0" with no unit and no
  /// meal instruction. Typed now, so the next rename breaks the build instead.
  String _getMedicineNotificationBody(Medicine medicine) {
    final parts = <String>[
      doseLabel(medicine.dosage, medicine.dosageUnit),
      // The one thing worth putting on a lock screen: whether it goes with
      // food. Skipped when it says "anytime", which adds nothing.
      if (medicine.mealTiming != MealTiming.anytime)
        _mealTimingText(medicine.mealTiming),
    ];
    return parts.isEmpty ? _l.medNotifTimeFor : parts.join(' · ');
  }

  String _mealTimingText(MealTiming timing) => switch (timing) {
    MealTiming.beforeMeal => _l.medBeforeMeal,
    MealTiming.afterMeal => _l.medAfterMeal,
    MealTiming.withMeal => _l.medWithMeal,
    MealTiming.onEmptyStomach => _l.medEmptyStomach,
    MealTiming.anytime => _l.medAnytime,
  };

  /// Title for a medicine reminder — prefixed with the person when the phone
  /// keeps medicine for more than one, so a shared handset says whose dose it
  /// is before you unlock it.
  String _medicineNotificationTitle(Medicine medicine) {
    final service = _carePeople;
    if (service == null) return medicine.name;
    if (service.getAll().length < 2) return medicine.name;
    final person = service.findById(medicine.personId);
    if (person == null) return medicine.name;
    return _l.medNotifTitleFor(person.name, medicine.name);
  }

  CarePersonService? get _carePeople => di.sl.isRegistered<CarePersonService>()
      ? di.sl<CarePersonService>()
      : null;
}
