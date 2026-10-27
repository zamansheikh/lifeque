import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/features/tasks/data/models/task_model.dart';
import 'package:lifeque/features/tasks/domain/entities/task.dart';

Task item({
  DateTime? due,
  DateTime? reminder,
  RepeatRule repeat = RepeatRule.daily,
}) {
  final at = due ?? reminder ?? DateTime(2026);
  return Task(
    id: 'r',
    title: 'Give Abbu his medicine',
    taskType: TaskType.reminder,
    startDate: at,
    endDate: at,
    isNotificationEnabled: reminder != null,
    notificationTime: reminder,
    hasDueDate: due != null,
    repeat: repeat,
    createdAt: DateTime(2026),
  );
}

void main() {
  test('each rule steps one period', () {
    final d = DateTime(2026, 1, 31, 9, 30);
    expect(RepeatRule.daily.step(d), DateTime(2026, 2, 1, 9, 30));
    expect(RepeatRule.weekly.step(d), DateTime(2026, 2, 7, 9, 30));
    expect(RepeatRule.monthly.step(d), DateTime(2026, 2, 28, 9, 30));
    expect(
      RepeatRule.yearly.step(DateTime(2028, 2, 29)),
      DateTime(2029, 2, 28),
    );
  });

  test('ticking a repeating item moves it on and keeps it open', () {
    final now = DateTime(2026, 10, 27, 8);
    final t = item(due: DateTime(2026, 10, 27, 9)).done(now);
    expect(t.isCompleted, isFalse);
    expect(t.dueDate, DateTime(2026, 10, 28, 9));
    expect(t.completedAt, now);
  });

  test('late by several periods: jumps to the next one still ahead', () {
    final now = DateTime(2026, 10, 27, 12);
    final t = item(due: DateTime(2026, 10, 20, 9)).rolledForward(now);
    expect(t.dueDate, DateTime(2026, 10, 28, 9));
  });

  test('a reminder keeps its distance from the due time', () {
    final now = DateTime(2026, 10, 27, 12);
    final t = item(
      due: DateTime(2026, 10, 27, 18),
      reminder: DateTime(2026, 10, 27, 17),
      repeat: RepeatRule.weekly,
    ).rolledForward(now);
    expect(t.dueDate, DateTime(2026, 11, 3, 18));
    expect(t.reminderAt, DateTime(2026, 11, 3, 17));
    expect(t.getScheduledNotificationTime(), DateTime(2026, 11, 3, 17));
  });

  test('a reminder-only repeat moves its reminder', () {
    final now = DateTime(2026, 10, 27, 12);
    final t = item(
      reminder: DateTime(2026, 10, 1, 8),
      repeat: RepeatRule.monthly,
    ).rolledForward(now);
    expect(t.dueDate, isNull);
    expect(t.reminderAt, DateTime(2026, 11, 1, 8));
  });

  test('not repeating: done means done', () {
    final now = DateTime(2026, 10, 27);
    final t = item(
      due: DateTime(2026, 10, 27, 9),
      repeat: RepeatRule.none,
    ).done(now);
    expect(t.isCompleted, isTrue);
    expect(t.completedAt, now);
  });

  test('ranged tasks and birthdays never repeat this way', () {
    final ranged = Task(
      id: 't',
      title: 'Thesis',
      startDate: DateTime(2026, 10),
      endDate: DateTime(2026, 11),
      repeat: RepeatRule.daily,
      createdAt: DateTime(2026),
    );
    expect(ranged.repeats, isFalse);
    expect(ranged.done(DateTime(2026, 10, 27)).isCompleted, isTrue);
  });

  test('the rule survives storage', () {
    final t = item(due: DateTime(2026, 11, 1), repeat: RepeatRule.monthly);
    expect(
      TaskModel.fromMap(TaskModel.fromEntity(t).toMap()).repeat,
      RepeatRule.monthly,
    );
    expect(
      TaskModel.fromJson(TaskModel.fromEntity(t).toJson()).repeat,
      RepeatRule.monthly,
    );
  });
}
