import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/features/todos/domain/entities/todo.dart';

/// The date predicates the to-do list groups by. Getting one of these wrong
/// silently moves items between the Overdue, Today and Upcoming sections.
void main() {
  Todo todo({DateTime? due, bool completed = false}) => Todo(
    id: 't',
    title: 'Something',
    dueDate: due,
    isCompleted: completed,
    createdAt: DateTime(2024),
  );

  final now = DateTime.now();

  group('isOverdue', () {
    test('true once the due time has passed', () {
      final due = now.subtract(const Duration(hours: 2));
      expect(todo(due: due).isOverdue, isTrue);
    });

    test('false for a due time still ahead', () {
      final due = now.add(const Duration(hours: 2));
      expect(todo(due: due).isOverdue, isFalse);
    });

    test('false with no due date at all', () {
      expect(todo().isOverdue, isFalse);
    });

    test('a completed to-do is never overdue', () {
      final due = now.subtract(const Duration(days: 3));
      expect(todo(due: due, completed: true).isOverdue, isFalse);
    });
  });

  group('isDueToday', () {
    test('true for any time today, including one already passed', () {
      final earlier = DateTime(now.year, now.month, now.day);
      expect(todo(due: earlier).isDueToday, isTrue);
    });

    test('false for tomorrow', () {
      final tomorrow = now.add(const Duration(days: 1));
      expect(todo(due: tomorrow).isDueToday, isFalse);
    });

    test('false with no due date', () {
      expect(todo().isDueToday, isFalse);
    });
  });

  group('isDueTomorrow', () {
    test('true for the same clock time one day on', () {
      final tomorrow = now.add(const Duration(days: 1));
      expect(todo(due: tomorrow).isDueTomorrow, isTrue);
    });

    test('false for today and for two days out', () {
      expect(todo(due: now).isDueTomorrow, isFalse);
      expect(
        todo(due: now.add(const Duration(days: 2))).isDueTomorrow,
        isFalse,
      );
    });
  });

  group('the sections stay mutually exclusive', () {
    test('a to-do is never both overdue and due tomorrow', () {
      for (final offset in [-48, -1, 1, 25, 49]) {
        final item = todo(due: now.add(Duration(hours: offset)));
        expect(
          item.isOverdue && item.isDueTomorrow,
          isFalse,
          reason: 'offset ${offset}h landed in two sections at once',
        );
      }
    });
  });
}
