import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/core/utils/database_helper.dart';
import 'package:lifeque/features/tasks/data/models/task_model.dart';
import 'package:lifeque/features/tasks/domain/entities/task.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The tasks table as version 10 shipped it.
const _v10Tasks = '''
  CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    taskType INTEGER NOT NULL DEFAULT 0,
    startDate INTEGER NOT NULL,
    endDate INTEGER NOT NULL,
    isCompleted INTEGER NOT NULL DEFAULT 0,
    isNotificationEnabled INTEGER NOT NULL DEFAULT 1,
    notificationType INTEGER NOT NULL DEFAULT 0,
    notificationTime INTEGER,
    dailyNotificationHour INTEGER,
    dailyNotificationMinute INTEGER,
    beforeEndOption INTEGER,
    isPinnedToNotification INTEGER NOT NULL DEFAULT 0,
    pinNotificationTiming INTEGER NOT NULL DEFAULT 0,
    birthdayNotificationSchedule TEXT,
    createdAt INTEGER NOT NULL,
    updatedAt INTEGER
  )''';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late String path;
  setUp(() async {
    path = join(await getDatabasesPath(), 'remind_me.db');
    await DatabaseHelper().close();
    await databaseFactory.deleteDatabase(path);
  });
  tearDown(() async {
    await DatabaseHelper().close();
    await databaseFactory.deleteDatabase(path);
  });

  test('upgrading from 10 adds the new columns and keeps every row', () async {
    final at = DateTime(2026, 10, 30, 10);
    final old = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 10,
        onCreate: (db, _) => db.execute(_v10Tasks),
      ),
    );
    await old.insert('tasks', {
      'id': 'r1',
      'title': 'Old reminder',
      'taskType': TaskType.reminder.index,
      'startDate': at.millisecondsSinceEpoch,
      'endDate': at.millisecondsSinceEpoch,
      'notificationTime': at.millisecondsSinceEpoch,
      'createdAt': at.millisecondsSinceEpoch,
    });
    await old.close();

    final db = await DatabaseHelper().database;
    expect(await db.getVersion(), 11);
    final columns = {
      for (final c in await db.rawQuery('PRAGMA table_info(tasks)'))
        c['name'] as String,
    };
    expect(
      columns,
      containsAll(['priority', 'category', 'hasDueDate', 'completedAt']),
    );

    final task = TaskModel.fromMap((await db.query('tasks')).single);
    expect(task.title, 'Old reminder');
    expect(task.priority, TaskPriority.normal);
    expect(task.hasDueDate, isTrue);
    expect(task.planDate, at);
  });

  test('a fresh install creates them too, and they round-trip', () async {
    final db = await DatabaseHelper().database;
    final item = TaskModel.fromEntity(
      Task(
        id: 'n1',
        title: 'Milk',
        taskType: TaskType.reminder,
        startDate: DateTime(2026),
        endDate: DateTime(2026),
        isNotificationEnabled: false,
        hasDueDate: false,
        priority: TaskPriority.high,
        category: TaskCategory.shopping,
        createdAt: DateTime(2026),
      ),
    );
    await db.insert('tasks', item.toMap());
    final back = TaskModel.fromMap((await db.query('tasks')).single);
    expect(back.priority, TaskPriority.high);
    expect(back.category, TaskCategory.shopping);
    expect(back.planDate, isNull);
  });
}
