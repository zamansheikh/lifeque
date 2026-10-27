import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/features/habits/data/habit_repository.dart';
import 'package:lifeque/features/habits/domain/habit.dart';
import 'package:lifeque/features/habits/presentation/habit_cubit.dart';
import 'package:lifeque/features/habits/presentation/edit_habit_page.dart';
import 'package:lifeque/features/habits/presentation/habit_detail_page.dart';
import 'package:lifeque/features/habits/presentation/habits_page.dart';
import 'package:lifeque/injection_container.dart' as di;
import 'package:lifeque/l10n/app_localizations.dart';

class MemoryHabits implements HabitRepository {
  final rows = <String, Habit>{};
  final checks = <String, Set<String>>{};
  @override
  Future<List<Habit>> all() async => rows.values.toList();
  @override
  Future<Map<String, Set<String>>> allChecks() async => {
    for (final e in checks.entries) e.key: {...e.value},
  };
  @override
  Future<void> save(Habit h) async => rows[h.id] = h;
  @override
  Future<void> delete(String id) async {
    rows.remove(id);
    checks.remove(id);
  }

  @override
  Future<void> setChecked(String habitId, String day, bool checked) async {
    final set = checks[habitId] ??= {};
    checked ? set.add(day) : set.remove(day);
  }
}

class Recorder implements HabitReminders {
  final scheduled = <String>[];
  final cancelled = <String>[];
  @override
  Future<void> schedule(Habit h) async => scheduled.add(h.id);
  @override
  Future<void> cancel(String id) async => cancelled.add(id);
}

DateTime ago(DateTime now, int days) =>
    DateTime(now.year, now.month, now.day - days);

Habit habit({
  String id = 'h',
  int days = Habit.everyDay,
  required DateTime createdAt,
  int? reminder,
}) => Habit(
  id: id,
  name: 'Read Quran',
  days: days,
  reminderMinutes: reminder,
  createdAt: createdAt,
);

void main() {
  final now = DateTime(2026, 10, 27, 15); // a Tuesday

  group('streaks', () {
    test('an untouched today does not break the streak', () {
      final h = habit(createdAt: ago(now, 30));
      final checks = {for (var i = 1; i <= 3; i++) dayKey(ago(now, i))};
      expect(HabitStats(h, checks).currentStreak(now), 3);
      expect(HabitStats(h, {...checks, dayKey(now)}).currentStreak(now), 4);
    });

    test('a missed day ends it', () {
      final h = habit(createdAt: ago(now, 30));
      final checks = {dayKey(ago(now, 1)), dayKey(ago(now, 3))};
      expect(HabitStats(h, checks).currentStreak(now), 1);
    });

    test('only the chosen weekdays count', () {
      expect(now.weekday, DateTime.tuesday);
      // Fridays only.
      final h = habit(
        days: 1 << (DateTime.friday - 1),
        createdAt: ago(now, 60),
      );
      final fridays = [4, 11, 18].map((d) => dayKey(ago(now, d))).toSet();
      expect(fridays.map(DateTime.parse).every((d) => d.weekday == 5), isTrue);
      expect(HabitStats(h, fridays).currentStreak(now), 3);
      expect(h.isScheduled(now), isFalse);
    });

    test('best streak survives a later gap', () {
      final h = habit(createdAt: ago(now, 30));
      final checks = {
        for (var i = 10; i <= 14; i++) dayKey(ago(now, i)),
        dayKey(ago(now, 1)),
        dayKey(ago(now, 2)),
      };
      final stats = HabitStats(h, checks);
      expect(stats.bestStreak(now), 5);
      expect(stats.currentStreak(now), 2);
    });

    test('the rate counts only days since it was made', () {
      final h = habit(createdAt: ago(now, 3));
      final checks = {dayKey(ago(now, 1)), dayKey(ago(now, 3))};
      expect(HabitStats(h, checks).rate(now), 0.5);
    });

    test('a streak stops at the day the habit was made', () {
      final h = habit(createdAt: ago(now, 2));
      final checks = {for (var i = 0; i <= 9; i++) dayKey(ago(now, i))};
      expect(HabitStats(h, checks).currentStreak(now), 3);
    });
  });

  test('weekday bits: Monday is bit 0', () {
    final h = habit(days: 0x01 | 0x40, createdAt: now);
    expect(h.onWeekday(DateTime.monday), isTrue);
    expect(h.onWeekday(DateTime.sunday), isTrue);
    expect(h.onWeekday(DateTime.tuesday), isFalse);
  });

  test('the map round-trips', () {
    final h = habit(days: 0x15, reminder: 7 * 60 + 30, createdAt: now);
    expect(Habit.fromMap(h.toMap()), h);
  });

  group('the cubit', () {
    test('a reminder is scheduled only when one is set', () async {
      final r = Recorder();
      final c = HabitCubit(MemoryHabits(), r);
      await c.save(habit(id: 'a', reminder: 480, createdAt: now));
      await c.save(habit(id: 'b', createdAt: now));
      await c.save(
        habit(id: 'a', reminder: 480, createdAt: now).copyWith(archived: true),
      );
      expect(r.scheduled, ['a']);
      expect(r.cancelled, ['b', 'a']);
      expect(c.state.active.map((h) => h.id), ['b']);
    });

    test('a tick goes on and off, and delete takes the history', () async {
      final repo = MemoryHabits();
      final r = Recorder();
      final c = HabitCubit(repo, r);
      final h = habit(createdAt: now);
      await c.save(h);
      expect(await c.toggle(h, now), isTrue);
      expect(c.state.statsFor(h).doneOn(now), isTrue);
      expect(repo.checks['h'], {dayKey(now)});
      expect(await c.toggle(h, now), isFalse);
      expect(c.state.statsFor(h).doneOn(now), isFalse);
      await c.toggle(h, now);
      await c.delete('h');
      expect(repo.checks, isEmpty);
      expect(r.cancelled, ['h', 'h']);
    });
  });

  testWidgets('the page in Bangla: tick today and the count follows', (
    tester,
  ) async {
    await initializeDateFormatting();
    Intl.defaultLocale = 'bn';
    addTearDown(() => Intl.defaultLocale = null);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    final today = DateTime.now();
    final repo = MemoryHabits();
    await repo.save(habit(id: 'a', createdAt: ago(today, 5)));
    await repo.save(
      habit(id: 'b', createdAt: ago(today, 5)).copyWith(name: 'হাঁটা'),
    );
    await di.sl.reset();
    di.sl.registerSingleton(HabitCubit(repo, Recorder()));
    addTearDown(di.sl.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: const HabitsPage(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final l = await L.delegate.load(const Locale('bn'));
    expect(find.text(l.habitTodayProgress(0, 2)), findsOneWidget);

    await tester.tap(find.byKey(const Key('habit-check-a')));
    await tester.pumpAndSettle();
    expect(find.text(l.habitTodayProgress(1, 2)), findsOneWidget);
    expect(repo.checks['a'], {dayKey(today)});
  });

  for (final page in ['detail', 'edit']) {
    testWidgets('the $page page fits a small phone in Bangla', (tester) async {
      await initializeDateFormatting();
      Intl.defaultLocale = 'bn';
      addTearDown(() => Intl.defaultLocale = null);
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final today = DateTime.now();
      final repo = MemoryHabits();
      await repo.save(
        habit(
          id: 'a',
          days: 0x55,
          reminder: 21 * 60,
          createdAt: ago(today, 40),
        ),
      );
      for (var i = 0; i < 40; i += 2) {
        await repo.setChecked('a', dayKey(ago(today, i)), true);
      }
      await di.sl.reset();
      final cubit = HabitCubit(repo, Recorder());
      await cubit.load();
      di.sl.registerSingleton(cubit);
      addTearDown(di.sl.reset);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('bn'),
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: page == 'detail'
              ? const HabitDetailPage(id: 'a')
              : const EditHabitPage(id: 'a'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Read Quran'), findsWidgets);
    });
  }
}
