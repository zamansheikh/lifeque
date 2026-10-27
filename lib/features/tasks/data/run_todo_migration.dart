import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';
import '../../../injection_container.dart' as di;
import '../domain/repositories/task_repository.dart';
import 'todo_migration.dart';

/// [TodoMigration] against the real task store, followed by clearing the
/// notifications the old to-do list had queued — the moved items are
/// rescheduled by the task side, which reads them from the store.
Future<int> runTodoMigration() async {
  final repository = di.sl<TaskRepository>();
  final existing = await repository.getAllTasks();
  final ids = existing.fold(
    (_) => <String>{},
    (tasks) => {for (final t in tasks) t.id},
  );
  final moved = await TodoMigration.run(
    prefs: di.sl<SharedPreferences>(),
    existingIds: ids,
    save: (task) async {
      final result = await repository.addTask(task);
      result.fold((f) => throw StateError('$f'), (_) {});
    },
  );
  await di.sl<NotificationService>().cancelLegacyTodoNotifications();
  return moved;
}
