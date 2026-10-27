import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/features/qaza/qaza_store.dart';
import 'package:lifeque/features/ramadan/ramadan_page.dart';
import 'package:lifeque/features/ramadan/ramadan_store.dart';
import 'package:lifeque/features/search/search_index.dart';
import 'package:lifeque/features/search/search_page.dart';
import 'package:lifeque/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

SearchHit hit(
  String title, {
  SearchKind kind = SearchKind.task,
  String? subtitle,
  String hidden = '',
  DateTime? date,
}) => SearchHit(
  kind: kind,
  title: title,
  subtitle: subtitle,
  hidden: hidden,
  route: '/x',
  icon: Icons.circle,
  color: Colors.black,
  date: date,
);

Widget app(Widget home, {String locale = 'en'}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: L.localizationsDelegates,
  supportedLocales: L.supportedLocales,
  home: home,
);

void main() {
  group('search', () {
    test('every word must match, in any field', () {
      final all = [
        hit('Pay electricity bill', hidden: 'DESCO account'),
        hit('Pay rent'),
        hit('Electric kettle', kind: SearchKind.expense),
      ];
      expect(searchHits(all, 'pay desco').map((h) => h.title), [
        'Pay electricity bill',
      ]);
      expect(searchHits(all, 'ELECTRIC').length, 2);
      expect(searchHits(all, '   '), isEmpty);
    });

    test('Bangla and Latin digits find each other', () {
      final all = [
        hit('Netflix', subtitle: '৳৫০০ · 3 Nov', kind: SearchKind.subscription),
        hit('Rice', subtitle: '৳1,200'),
      ];
      expect(searchHits(all, '500').single.title, 'Netflix');
      expect(searchHits(all, '১,২০০').single.title, 'Rice');
    });

    test('sections in order; title starts first, then newer first', () {
      final all = [
        hit('Old milk', date: DateTime(2025), kind: SearchKind.expense),
        hit('Buy milk', date: DateTime(2026)),
        hit('milk powder', date: DateTime(2024)),
        hit('Milk', kind: SearchKind.page),
        hit('Almond milk', date: DateTime(2027)),
      ];
      expect(searchHits(all, 'milk').map((h) => h.title), [
        'Milk',
        'milk powder',
        'Almond milk',
        'Buy milk',
        'Old milk',
      ]);
    });

    testWidgets('the page in Bangla: type, see sections', (tester) async {
      await initializeDateFormatting();
      final l = await L.delegate.load(const Locale('bn'));
      await tester.pumpWidget(
        app(
          SearchPage(
            index: (l) async => [
              ...pageHits(l),
              hit('বাজারের তালিকা'),
              hit('চাল', kind: SearchKind.expense, subtitle: '৳৫০০'),
            ],
          ),
          locale: 'bn',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l.searchStart), findsOneWidget);

      await tester.enterText(find.byKey(const Key('search-field')), 'রমজান');
      await tester.pumpAndSettle();
      expect(find.text(l.searchPages), findsOneWidget);
      expect(find.text(l.ramadanTitle), findsWidgets);

      await tester.enterText(find.byKey(const Key('search-field')), '500');
      await tester.pumpAndSettle();
      expect(find.text('চাল'), findsOneWidget);
      expect(find.text(l.navExpenses), findsOneWidget);

      await tester.enterText(find.byKey(const Key('search-field')), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text(l.searchNothing('zzz')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ramadan', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('a year has 29 or 30 days, all in Ramadan', () {
      for (final y in [1446, 1447, 1448]) {
        final days = ramadanDays(y);
        expect(days.length, inInclusiveRange(29, 30));
        expect(
          days.every((d) => HijriCalendar.fromDate(d).hMonth == 9),
          isTrue,
        );
        expect(HijriCalendar.fromDate(days.first).hDay, 1);
      }
    });

    test('the log opens on the running Ramadan, else the last one', () {
      final ramadan = ramadanDays(1447)[10];
      expect(defaultRamadanYear(ramadan), 1447);
      final shawwal = ramadanDays(1447).last.add(const Duration(days: 5));
      expect(defaultRamadanYear(shawwal), 1447);
      final rajab = ramadanDays(1448).first.subtract(const Duration(days: 60));
      expect(defaultRamadanYear(rajab), 1447);
    });

    test('missed and excused fasts follow into qaza, and back out', () async {
      final qaza = QazaStore.forTesting();
      final store = RamadanStore.forTesting(qaza);
      await store.load();
      expect(qaza.owed[QazaStore.fast], 0);

      await store.setFast(1447, 3, FastStatus.missed);
      await store.setFast(1447, 4, FastStatus.excused);
      expect(qaza.owed[QazaStore.fast], 2);

      // Missed → excused: still owed, not owed twice.
      await store.setFast(1447, 3, FastStatus.excused);
      expect(qaza.owed[QazaStore.fast], 2);

      await store.setFast(1447, 3, FastStatus.fasted);
      await store.setFast(1447, 4, null);
      expect(qaza.owed[QazaStore.fast], 0);

      await store.setTaraweeh(1447, 3, true);
      await store.setTaraweeh(1447, 5, true);

      // Read back from storage.
      final again = RamadanStore.forTesting(qaza);
      await again.load();
      expect(again.fastOn(1447, 3), FastStatus.fasted);
      expect(again.fastOn(1447, 4), isNull);
      expect(again.taraweehCount(1447), 2);
      expect(again.count(1447, FastStatus.fasted), 1);
    });

    testWidgets('the page in Bangla: mark a day from its sheet', (
      tester,
    ) async {
      await initializeDateFormatting();
      Intl.defaultLocale = 'bn';
      addTearDown(() => Intl.defaultLocale = null);
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      final now = ramadanDays(1447)[14].add(const Duration(hours: 13));
      final qaza = QazaStore.forTesting();
      final store = RamadanStore.forTesting(qaza);
      await tester.pumpWidget(
        app(
          RamadanPage(store: store, clock: () => now),
          locale: 'bn',
        ),
      );
      await tester.pumpAndSettle();
      final l = await L.delegate.load(const Locale('bn'));
      expect(tester.takeException(), isNull);
      expect(find.text(l.ramadanToday('১৪৪৭', 15)), findsOneWidget);

      await tester.tap(find.byKey(const Key('ramadan-day-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ramadan-mark-missed')));
      await tester.pumpAndSettle();
      expect(store.fastOn(1447, 3), FastStatus.missed);
      expect(qaza.owed[QazaStore.fast], 1);

      // A day still to come can't be marked.
      await tester.tap(find.byKey(const Key('ramadan-day-20')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ramadan-mark-missed')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
