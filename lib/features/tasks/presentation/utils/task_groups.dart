import '../../domain/entities/task.dart';

/// Where an open item sits in the list.
enum TaskGroup { overdue, today, week, later, someday }

/// Everything on the task list except birthdays, which have their own page.
bool onTaskList(Task t) => t.taskType != TaskType.birthday;

/// Open items, bucketed by when they matter.
///
/// An item's time is its due date, else its reminder (see [Task.planDate]);
/// a ranged task's is its end. Inside a bucket the soonest comes first and,
/// at the same time, the more important one. Undated items are ordered by
/// importance, then newest first.
Map<TaskGroup, List<Task>> groupOpen(Iterable<Task> tasks, DateTime now) {
  final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final endOfWeek = endOfToday.add(const Duration(days: 7));

  final groups = {for (final g in TaskGroup.values) g: <Task>[]};
  for (final t in tasks) {
    if (!onTaskList(t) || t.isCompleted) continue;
    final at = t.planDate;
    final group = at == null
        ? TaskGroup.someday
        : at.isBefore(now)
        ? TaskGroup.overdue
        : !at.isAfter(endOfToday)
        ? TaskGroup.today
        : !at.isAfter(endOfWeek)
        ? TaskGroup.week
        : TaskGroup.later;
    groups[group]!.add(t);
  }

  int byImportance(Task a, Task b) =>
      b.priority.index.compareTo(a.priority.index);
  for (final entry in groups.entries) {
    if (entry.key == TaskGroup.someday) {
      entry.value.sort((a, b) {
        final p = byImportance(a, b);
        return p != 0 ? p : b.createdAt.compareTo(a.createdAt);
      });
    } else {
      entry.value.sort((a, b) {
        final t = a.planDate!.compareTo(b.planDate!);
        return t != 0 ? t : byImportance(a, b);
      });
    }
  }
  return groups;
}

/// Finished items, most recently finished first.
List<Task> doneItems(Iterable<Task> tasks) {
  DateTime when(Task t) => t.completedAt ?? t.updatedAt ?? t.createdAt;
  return tasks.where((t) => onTaskList(t) && t.isCompleted).toList()
    ..sort((a, b) => when(b).compareTo(when(a)));
}
