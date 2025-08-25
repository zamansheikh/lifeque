abstract class NotificationRepository {
  Future<void> initialize();
  Future<void> scheduleTaskNotification({
    required String taskId,
    required String title,
    required String description,
    required DateTime scheduledTime,
  });
  Future<void> cancelTaskNotification(String taskId);
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  });
  Future<bool> requestPermissions();
  Future<void> setupBackgroundTasks();
}
