import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/core/services/navigation_preferences_service.dart';
import 'package:lifeque/core/services/notification_service.dart';
import 'package:lifeque/features/tasks/data/models/task_model.dart';
import 'package:lifeque/features/tasks/data/todo_migration.dart';
import 'package:lifeque/features/tasks/domain/entities/task.dart';
import 'package:lifeque/features/tasks/presentation/utils/task_groups.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A to-do as the old list stored it.
Map<String, dynamic> legacyTodo({
  String id = 'todo-1',
  int priority = 1,
  int category = 0,
  DateTime? due,
  DateTime? reminder,
  bool completed = false,
}) => {
  'id': id,
  'title': 'Pay rent',
  'description': 'Landlord',
  'isCompleted': completed,
  'priority': priority,
  'category': category,
  'createdAt': DateTime(2026, 10, 1, 9).toIso8601String(),
  'dueDate': due?.toIso8601String(),
  'completedAt': completed ? DateTime(2026, 10, 2).toIso8601String() : null,
  'tags': ['old-tag'],
  'reminderTime': reminder?.toIso8601String(),
  'hasReminder': reminder != null,
};

Task simple({
  required String id,
  DateTime? due,
  DateTime? reminder,
  TaskPriority priority = TaskPriority.normal,
  bool done = false,
  DateTime? created,
}) {
  final at = due ?? reminder ?? DateTime(2026);
  return Task(
    id: id,
    title: id,
    taskType: TaskType.reminder,
    startDate: at,
    endDate: at,
    isCompleted: done,
    isNotificationEnabled: reminder != null,
    notificationTime: reminder,
    hasDueDate: due != null,
    priority: priority,
    createdAt: created ?? DateTime(2026),
  );
}

void main() {
  group('moving the old to-do list over', () {
    test('every field lands where the task list expects it', () {
      final due = DateTime(2026, 10, 31, 18);
      final reminder = DateTime(2026, 10, 31, 17);
      final t = TodoMigration.fromLegacy(
        legacyTodo(priority: 3, category: 4, due: due, reminder: reminder),
      );
      expect(t.id, 'todo-1', reason: 'ids kept, for notifications on screen');
      expect(t.isSimple, isTrue);
      expect(t.title, 'Pay rent');
      expect(t.description, 'Landlord');
      expect(t.priority, TaskPriority.urgent);
      expect(t.category, TaskCategory.education);
      expect(t.dueDate, due);
      expect(t.reminderAt, reminder);
      expect(t.getScheduledNotificationTime(), reminder);
      expect(t.planDate, due);
    });

    test('an undated to-do stays undated; medium becomes normal', () {
      final t = TodoMigration.fromLegacy(legacyTodo());
      expect(t.dueDate, isNull);
      expect(t.reminderAt, isNull);
      expect(t.planDate, isNull);
      expect(t.priority, TaskPriority.normal);
      expect(t.isNotificationEnabled, isFalse);
      expect(t.getScheduledNotificationTime(), isNull);
    });

    test('a reminder with no due date is placed by its reminder', () {
      final reminder = DateTime(2026, 11, 2, 9);
      final t = TodoMigration.fromLegacy(legacyTodo(reminder: reminder));
      expect(t.dueDate, isNull);
      expect(t.planDate, reminder);
    });

    test('completion carries over', () {
      final t = TodoMigration.fromLegacy(legacyTodo(completed: true));
      expect(t.isCompleted, isTrue);
      expect(t.completedAt, DateTime(2026, 10, 2));
    });

    test('runs once, skips ids already there, keeps a copy', () async {
      final raw = jsonEncode([
        legacyTodo(id: 'a'),
        legacyTodo(id: 'b'),
        legacyTodo(id: 'c'),
      ]);
      SharedPreferences.setMockInitialValues({TodoMigration.legacyKey: raw});
      final prefs = await SharedPreferences.getInstance();
      final saved = <String>[];

      final moved = await TodoMigration.run(
        prefs: prefs,
        existingIds: {'b'},
        save: (t) async => saved.add(t.id),
      );
      expect(moved, 2);
      expect(saved, ['a', 'c']);
      expect(prefs.getString(TodoMigration.legacyKey), isNull);
      expect(prefs.getString(TodoMigration.keptKey), raw);
      expect(prefs.getBool(TodoMigration.doneKey), isTrue);

      // Second start: nothing happens.
      final again = await TodoMigration.run(
        prefs: prefs,
        existingIds: {},
        save: (t) async => saved.add(t.id),
      );
      expect(again, 0);
      expect(saved, ['a', 'c']);
    });

    test('an unreadable list is left alone, not marked done', () async {
      SharedPreferences.setMockInitialValues({
        TodoMigration.legacyKey: 'not json',
      });
      final prefs = await SharedPreferences.getInstance();
      final moved = await TodoMigration.run(
        prefs: prefs,
        existingIds: {},
        save: (_) async => fail('nothing should be saved'),
      );
      expect(moved, 0);
      expect(prefs.getString(TodoMigration.legacyKey), 'not json');
      expect(prefs.getBool(TodoMigration.doneKey), isNull);
    });

    test('a fresh install with no to-dos just marks it done', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final moved = await TodoMigration.run(
        prefs: prefs,
        existingIds: {},
        save: (_) async => fail('nothing to save'),
      );
      expect(moved, 0);
      expect(prefs.getBool(TodoMigration.doneKey), isTrue);
    });
  });

  group('the one list', () {
    final now = DateTime(2026, 10, 27, 14);

    test('items land in the right section', () {
      final groups = groupOpen([
        simple(id: 'late', due: DateTime(2026, 10, 27, 9)),
        simple(id: 'tonight', due: DateTime(2026, 10, 27, 20)),
        simple(id: 'ring-today', reminder: DateTime(2026, 10, 27, 16)),
        simple(id: 'friday', due: DateTime(2026, 10, 31, 18)),
        simple(id: 'december', due: DateTime(2026, 12, 1)),
        simple(id: 'someday'),
        simple(id: 'finished', due: DateTime(2026, 10, 27, 9), done: true),
        Task(
          id: 'birthday',
          title: 'Ammu',
          taskType: TaskType.birthday,
          startDate: DateTime(1970, 10, 27),
          endDate: DateTime(1970, 10, 27),
          createdAt: DateTime(2026),
        ),
        Task(
          id: 'ranged',
          title: 'Thesis',
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 30),
          createdAt: DateTime(2026),
        ),
      ], now);

      List<String> ids(TaskGroup g) => groups[g]!.map((t) => t.id).toList();
      expect(ids(TaskGroup.overdue), ['late']);
      expect(ids(TaskGroup.today), ['ring-today', 'tonight']);
      expect(ids(TaskGroup.week), ['ranged', 'friday']);
      expect(ids(TaskGroup.later), ['december']);
      expect(ids(TaskGroup.someday), ['someday']);
      final all = groups.values.expand((g) => g).map((t) => t.id);
      expect(all, isNot(contains('finished')));
      expect(all, isNot(contains('birthday')), reason: 'birthdays have a page');
    });

    test('same time: the more important one first', () {
      final at = DateTime(2026, 10, 27, 18);
      final groups = groupOpen([
        simple(id: 'normal', due: at),
        simple(id: 'urgent', due: at, priority: TaskPriority.urgent),
      ], now);
      expect(groups[TaskGroup.today]!.map((t) => t.id), ['urgent', 'normal']);
    });

    test('undated: important first, then newest', () {
      final groups = groupOpen([
        simple(id: 'old', created: DateTime(2026, 1, 1)),
        simple(id: 'new', created: DateTime(2026, 10, 1)),
        simple(
          id: 'high',
          created: DateTime(2025),
          priority: TaskPriority.high,
        ),
      ], now);
      expect(groups[TaskGroup.someday]!.map((t) => t.id), [
        'high',
        'new',
        'old',
      ]);
    });

    test('done: most recently finished first', () {
      final a = simple(
        id: 'a',
        done: true,
      ).copyWith(completedAt: DateTime(2026, 10, 1));
      final b = simple(
        id: 'b',
        done: true,
      ).copyWith(completedAt: DateTime(2026, 10, 20));
      expect(doneItems([a, b]).map((t) => t.id), ['b', 'a']);
    });
  });

  group('storage', () {
    test('new fields survive the database row', () {
      final original = simple(
        id: 'x',
        due: DateTime(2026, 11, 1, 18),
        reminder: DateTime(2026, 11, 1, 17),
        priority: TaskPriority.high,
      ).copyWith(category: TaskCategory.work, completedAt: DateTime(2026, 11));
      final back = TaskModel.fromMap(TaskModel.fromEntity(original).toMap());
      expect(back.priority, TaskPriority.high);
      expect(back.category, TaskCategory.work);
      expect(back.hasDueDate, isTrue);
      expect(back.completedAt, DateTime(2026, 11));
      expect(back.reminderAt, DateTime(2026, 11, 1, 17));
    });

    test('a row from before the merge reads exactly as it did', () {
      final at = DateTime(2026, 10, 30, 10);
      final row = {
        'id': 'old',
        'title': 'Old reminder',
        'taskType': TaskType.reminder.index,
        'startDate': at.millisecondsSinceEpoch,
        'endDate': at.millisecondsSinceEpoch,
        'isCompleted': 0,
        'isNotificationEnabled': 1,
        'notificationType': 0,
        'notificationTime': at.millisecondsSinceEpoch,
        'isPinnedToNotification': 0,
        'pinNotificationTiming': 0,
        'createdAt': at.millisecondsSinceEpoch,
      };
      final t = TaskModel.fromMap(row);
      expect(t.priority, TaskPriority.normal);
      expect(t.category, isNull);
      expect(t.hasDueDate, isTrue);
      expect(t.planDate, at);
      expect(t.getScheduledNotificationTime(), at);
    });

    test('a JSON copy keeps the new fields', () {
      final original = simple(
        id: 'j',
        priority: TaskPriority.low,
      ).copyWith(category: TaskCategory.home);
      final back = TaskModel.fromJson(TaskModel.fromEntity(original).toJson());
      expect(back.priority, TaskPriority.low);
      expect(back.category, TaskCategory.home);
      expect(back.hasDueDate, isFalse);
    });
  });

  group('menu order', () {
    test('a saved order starting with Reminders now starts with Tasks', () {
      SharedPreferences.setMockInitialValues({});
      return SharedPreferences.getInstance().then((prefs) async {
        await prefs.setStringList('nav_item_order', [
          '/reminders',
          '/prayer-times',
          '/todos',
          '/',
          '/birthdays',
        ]);
        final svc = NavigationPreferencesService(prefs);
        final routes = svc.getOrderedItems().map((i) => i.route).toList();
        expect(routes.first, '/');
        expect(routes.where((r) => r == '/'), hasLength(1));
        expect(routes, isNot(contains('/reminders')));
        expect(routes, isNot(contains('/todos')));
        expect(svc.getHomeRoute(), '/');
      });
    });
  });

  group('startup notification sync', () {
    setUpAll(() {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    });

    test('keeps reminders that have not started, not only running tasks', () {
      final tonight = simple(
        id: 'tonight',
        reminder: DateTime.now().add(const Duration(hours: 5)),
      );
      // The old sync kept only rows its "active" query matched — start in
      // the past, end in the future — and cancelled everything else as an
      // orphan on every app start. A reminder's start is its ring time.
      expect(tonight.startDate.isAfter(DateTime.now()), isTrue);
      expect(NotificationService.needsTaskNotification(tonight), isTrue);
    });

    test('skips finished items and ones with nothing to notify', () {
      final done = simple(id: 'd', reminder: DateTime(2030), done: true);
      final silent = simple(id: 's', due: DateTime(2030));
      expect(NotificationService.needsTaskNotification(done), isFalse);
      expect(NotificationService.needsTaskNotification(silent), isFalse);
    });
  });
}
