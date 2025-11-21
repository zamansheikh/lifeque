import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';
import 'traditional_task_card.dart';
import 'reminder_task_card.dart';
import 'birthday_reminder_card.dart';
import 'swipeable_task_card.dart';

class TaskCardFactory {
  static Widget createCard({
    required Task task,
    VoidCallback? onTap,
    VoidCallback? onToggleComplete,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    Widget card;

    switch (task.taskType) {
      case TaskType.task:
        card = TraditionalTaskCard(
          task: task,
          onTap: onTap,
          onToggleComplete: onToggleComplete,
          onEdit: onEdit,
          onDelete: onDelete,
        );
        break;
      case TaskType.reminder:
        card = ReminderTaskCard(
          task: task,
          onTap: onTap,
          onToggleComplete: onToggleComplete,
          onEdit: onEdit,
          onDelete: onDelete,
        );
        break;
      case TaskType.birthday:
        // Birthdays don't need swipe actions (they're in a separate card)
        return BirthdayReminderCard(
          task: task,
          onTap: onTap,
          onToggleComplete: onToggleComplete,
          onEdit: onEdit,
          onDelete: onDelete,
        );
    }

    // Wrap tasks and reminders with swipeable functionality
    return SwipeableTaskCard(
      onComplete: onToggleComplete,
      onDelete: onDelete,
      canComplete: !task.isCompleted,
      child: card,
    );
  }
}
