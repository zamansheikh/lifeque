import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/task.dart';

/// Moves the old to-do list into the tasks table, once.
///
/// To-dos used to live apart, as one JSON list in settings storage, with a
/// notification system of their own. Since tasks, reminders and to-dos became
/// one list, every to-do becomes a simple item there, keeping its id, so a
/// notification already showing for it still finds it.
class TodoMigration {
  TodoMigration._();

  /// Set once the move has happened. A restored backup made before the merge
  /// lacks it, so its to-dos are moved over too.
  static const doneKey = 'todos_merged_into_tasks_v1';

  /// Where the to-do list was stored.
  static const legacyKey = 'CACHED_TODOS';

  /// The list as it was, kept for one release in case something went wrong.
  static const keptKey = 'todos_before_merge_v1';

  /// Moves the to-dos stored in [prefs] into tasks via [save], skipping ids
  /// already in [existingIds]. Returns how many moved. Safe to call on every
  /// start: after the first run it only reads one flag.
  static Future<int> run({
    required SharedPreferences prefs,
    required Set<String> existingIds,
    required Future<void> Function(Task task) save,
  }) async {
    if (prefs.getBool(doneKey) == true) return 0;

    final raw = prefs.getString(legacyKey);
    var moved = 0;
    if (raw != null && raw.isNotEmpty) {
      final List<dynamic> list;
      try {
        list = jsonDecode(raw) as List<dynamic>;
      } catch (e) {
        // Unreadable: leave it where it is rather than mark it moved.
        debugPrint('🗂 To-do list unreadable, not migrating: $e');
        return 0;
      }
      for (final item in list) {
        final Task task;
        try {
          task = fromLegacy(item as Map<String, dynamic>);
        } catch (e) {
          debugPrint('🗂 Skipping a to-do that could not be read: $e');
          continue;
        }
        if (existingIds.contains(task.id)) continue;
        await save(task);
        moved++;
      }
      await prefs.setString(keptKey, raw);
      await prefs.remove(legacyKey);
    }
    await prefs.setBool(doneKey, true);
    debugPrint('🗂 Moved $moved to-do(s) into the task list');
    return moved;
  }

  /// One stored to-do as a simple item.
  ///
  /// Priority and category indices line up one to one with the old to-do
  /// enums (medium is now called normal). A reminder becomes the item's
  /// reminder; tags had no screen to set them and are not carried.
  @visibleForTesting
  static Task fromLegacy(Map<String, dynamic> json) {
    final created = DateTime.parse(json['createdAt'] as String);
    final due = json['dueDate'] == null
        ? null
        : DateTime.parse(json['dueDate'] as String);
    final reminder = json['hasReminder'] == true && json['reminderTime'] != null
        ? DateTime.parse(json['reminderTime'] as String)
        : null;
    final at = due ?? reminder ?? created;

    int? index(Object? v, int length) =>
        v is int && v >= 0 && v < length ? v : null;
    final priority = index(json['priority'], TaskPriority.values.length);
    final category = index(json['category'], TaskCategory.values.length);

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      taskType: TaskType.reminder,
      startDate: at,
      endDate: at,
      isCompleted: json['isCompleted'] == true,
      isNotificationEnabled: reminder != null,
      notificationType: NotificationType.specificTime,
      notificationTime: reminder,
      createdAt: created,
      priority: priority == null
          ? TaskPriority.normal
          : TaskPriority.values[priority],
      category: category == null ? null : TaskCategory.values[category],
      hasDueDate: due != null,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }
}
