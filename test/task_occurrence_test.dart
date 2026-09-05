import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/features/tasks/domain/entities/task.dart';

/// Pins [Task.nextOccurrence] for birthdays.
///
/// The rule is easy to get subtly wrong: `thisYearBirthday` is midnight, so
/// comparing it against `DateTime.now()` rather than against today's *date*
/// pushes a birthday that is happening today a full year into the future. That
/// is what the Birthdays page reported as "in 365 days" before it was fixed.
void main() {
  Task birthdayOn(DateTime born) => Task(
    id: 'b',
    title: 'Someone',
    taskType: TaskType.birthday,
    startDate: born,
    endDate: born,
    createdAt: DateTime(2020),
  );

  group('birthday nextOccurrence', () {
    test('a birthday later today is today, not next year', () {
      final now = DateTime.now();
      final born = DateTime(1996, now.month, now.day);

      final next = birthdayOn(born).nextOccurrence;

      expect(next.year, now.year);
      expect(next.month, now.month);
      expect(next.day, now.day);
    });

    test('a birthday already past this year rolls to next year', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      // Skip the new-year edge, where "yesterday" is already last year and the
      // roll-forward is a no-op rather than a +1.
      if (yesterday.year != now.year) return;

      final born = DateTime(1996, yesterday.month, yesterday.day);
      final next = birthdayOn(born).nextOccurrence;

      expect(next.year, now.year + 1);
      expect(next.month, yesterday.month);
      expect(next.day, yesterday.day);
    });

    test('a birthday still to come this year stays in this year', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      if (tomorrow.year != now.year) return;

      final born = DateTime(1996, tomorrow.month, tomorrow.day);
      final next = birthdayOn(born).nextOccurrence;

      expect(next.year, now.year);
      expect(next.month, tomorrow.month);
      expect(next.day, tomorrow.day);
    });

    test('the day and month always survive the roll-forward', () {
      final born = DateTime(1990, 3, 14);
      final next = birthdayOn(born).nextOccurrence;

      expect(next.month, 3);
      expect(next.day, 14);
      expect(next.isBefore(DateTime.now()), isFalse);
    });
  });
}
