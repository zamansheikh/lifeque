import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import '../../../../core/error/exceptions.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  NotificationRepositoryImpl(this._flutterLocalNotificationsPlugin);

  @override
  Future<void> initialize() async {
    try {
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
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Request permissions for Android 13+
      if (Platform.isAndroid) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();
      }
    } catch (e) {
      throw NotificationException('Failed to initialize notifications: $e');
    }
  }

  @override
  Future<void> scheduleTaskNotification({
    required String taskId,
    required String title,
    required String description,
    required DateTime scheduledTime,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.max,
            priority: Priority.high,
            ongoing: true,
            autoCancel: false,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        taskId.hashCode,
        title,
        description,
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: taskId,
      );
    } catch (e) {
      throw NotificationException('Failed to schedule notification: $e');
    }
  }

  @override
  Future<void> cancelTaskNotification(String taskId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(taskId.hashCode);
    } catch (e) {
      throw NotificationException('Failed to cancel notification: $e');
    }
  }

  @override
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'instant_notifications',
            'Instant Notifications',
            channelDescription: 'Instant notifications',
            importance: Importance.max,
            priority: Priority.high,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
    } catch (e) {
      throw NotificationException('Failed to show notification: $e');
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        return status == PermissionStatus.granted;
      }
      return true; // iOS handles permissions through initialization
    } catch (e) {
      throw PermissionException('Failed to request permissions: $e');
    }
  }

  @override
  Future<void> setupBackgroundTasks() async {
    // For now, we'll use local notifications for periodic reminders
    // In a production app, you might want to implement a proper background service
    // or use a different approach for persistent notifications
    try {
      // Schedule periodic notifications using Flutter Local Notifications
      // This is a simplified implementation
      await showInstantNotification(
        title: 'LifeQue',
        body: 'Background task setup completed',
      );
    } catch (e) {
      throw NotificationException('Failed to setup background tasks: $e');
    }
  }

  static void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) {
    final String? payload = notificationResponse.payload;
    if (payload != null && payload.isNotEmpty) {
      // Handle notification tap
      // You can navigate to a specific task or perform an action
    }
  }
}
