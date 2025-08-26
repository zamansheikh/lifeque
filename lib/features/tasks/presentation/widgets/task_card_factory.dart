import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import 'traditional_task_card.dart';
import 'reminder_task_card.dart';
import 'birthday_reminder_card.dart';

class TaskCardFactory {
  static Widget createCard({
    required Task task,
    VoidCallback? onTap,
    VoidCallback? onToggleComplete,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    switch (task.taskType) {
      case TaskType.task:
        return TraditionalTaskCard(
          task: task,
          onTap: onTap,
          onToggleComplete: onToggleComplete,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      case TaskType.reminder:
        return ReminderTaskCard(
          task: task,
          onTap: onTap,
          onToggleComplete: onToggleComplete,
          onEdit: onEdit,
          onDelete: onDelete,
        );
      case TaskType.birthday:
        return BirthdayReminderCard(
          task: task,
          onTap: onTap,
          onToggleComplete: onToggleComplete,
          onEdit: onEdit,
          onDelete: onDelete,
        );
    }
  }
}
