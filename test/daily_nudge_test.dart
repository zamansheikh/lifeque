import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/features/nudges/daily_nudge.dart';
import 'package:lifeque/features/tasks/domain/entities/task.dart';
import 'package:lifeque/l10n/app_localizations.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Task birthday(String id, DateTime born) => Task(
  id: id,
  title: 'Person $id',
  taskType: TaskType.birthday,
  startDate: born,
  endDate: born,
  createdAt: born,
);

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));
    await initializeDateFormatting();
    Intl.defaultLocale = 'bn';
  });

  // A Monday that is neither the start of a month nor a "share day".
  final monday = DateTime(2026, 9, 7, 10);
  bool never(String _) => false;

  test('a birthday today beats everything', () {
    final n = pickNudge(
      now: monday,
      birthdays: [birthday('a', DateTime(2000, 9, 7))],
      hasLocation: false,
      wished: (_) => false,
      seenToday: never,
    );
    expect(n?.kind, NudgeKind.birthdayToday);
    expect(n?.key, 'bday_today_a');
  });

  test('a birthday already wished is not nagged about', () {
    final n = pickNudge(
      now: monday,
      birthdays: [birthday('a', DateTime(2000, 9, 7))],
      hasLocation: true,
      wished: (_) => true,
      seenToday: never,
    );
    expect(n?.kind, isNot(NudgeKind.birthdayToday));
  });

  test('tomorrow\'s birthday comes next', () {
    final n = pickNudge(
      now: monday,
      birthdays: [birthday('b', DateTime(2000, 9, 8))],
      hasLocation: true,
      wished: (_) => false,
      seenToday: never,
    );
    expect(n?.kind, NudgeKind.birthdayTomorrow);
  });

  test('no location asks for one, and offers nothing that needs it', () {
    final friday = DateTime(2026, 9, 11, 10);
    final n = pickNudge(
      now: friday,
      birthdays: const [],
      hasLocation: false,
      wished: (_) => false,
      seenToday: (k) => k == 'location',
    );
    expect(n, isNull);
  });

  test('Friday is a Jumu\'ah share', () {
    final friday = DateTime(2026, 9, 11, 10);
    final n = pickNudge(
      now: friday,
      birthdays: const [],
      hasLocation: true,
      wished: (_) => false,
      seenToday: never,
    );
    expect(n?.kind, NudgeKind.jumuahShare);
  });

  test('the first days of a month suggest the timetable, once', () {
    // A Thursday: the first of October 2026 (the 2nd is a Friday, which
    // would win as Jumu'ah).
    final first = DateTime(2026, 10, 1, 10);
    expect(
      pickNudge(
        now: first,
        birthdays: const [],
        hasLocation: true,
        wished: (_) => false,
        seenToday: never,
      )?.kind,
      NudgeKind.monthTimetable,
    );
    expect(
      pickNudge(
        now: first,
        birthdays: const [],
        hasLocation: true,
        wished: (_) => false,
        seenToday: (k) => k.startsWith('month_'),
      )?.kind,
      isNot(NudgeKind.monthTimetable),
    );
  });

  test('a quiet day says nothing', () {
    final n = pickNudge(
      now: monday,
      birthdays: const [],
      hasLocation: true,
      wished: (_) => false,
      seenToday: never,
    );
    expect(n, isNull);
  });

  testWidgets('the sheet renders in Bangla without overflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(
          body: NudgeSheet(
            nudge: Nudge(
              NudgeKind.birthdayToday,
              birthday: birthday('a', DateTime(2000, 9, 7)),
              key: 'bday_today_a',
            ),
            location: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('জন্মদিন'), findsWidgets);
    expect(find.text('এখন নয়'), findsOneWidget);
  });
}
