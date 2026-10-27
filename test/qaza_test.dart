import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/features/prayer_times/data/services/prayer_completion_service.dart';
import 'package:lifeque/features/qaza/qaza_page.dart';
import 'package:lifeque/features/qaza/qaza_store.dart';
import 'package:lifeque/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('the record', () {
    test('owe, make up, undo — and it is all saved', () async {
      final s = QazaStore.forTesting();
      await s.load();
      await s.addOwed('Fajr', 3);
      expect(await s.makeUp('Fajr', at: DateTime(2026, 10, 27, 5)), isTrue);
      expect(s.owed['Fajr'], 2);
      expect(s.made['Fajr'], 1);
      expect(s.madeOn(DateTime(2026, 10, 27)), 1);

      final undone = await s.undo();
      expect(undone?.what, 'Fajr');
      expect(s.owed['Fajr'], 3);
      expect(s.made['Fajr'], 0);

      await s.makeUp('Fajr');
      final again = QazaStore.forTesting();
      await again.load();
      expect(again.owed['Fajr'], 2);
      expect(again.made['Fajr'], 1);
      expect(again.log, hasLength(1));
    });

    test(
      'nothing owed: nothing to make up, and counts never go negative',
      () async {
        final s = QazaStore.forTesting();
        await s.load();
        expect(await s.makeUp('Isha'), isFalse);
        await s.addOwed('Isha', -5);
        expect(s.owed['Isha'], 0);
      },
    );

    test('"two years" adds that many of every prayer and Witr', () async {
      final s = QazaStore.forTesting();
      await s.load();
      await s.addDays(730);
      for (final p in qazaPrayers) {
        expect(s.owed[p], 730, reason: p);
      }
      expect(s.owed[QazaStore.fast], 0);
      expect(s.prayersOwed, 730 * 6);
    });

    test('a damaged record starts empty rather than crashing', () async {
      SharedPreferences.setMockInitialValues({QazaStore.key: 'nonsense'});
      final s = QazaStore.forTesting();
      await s.load();
      expect(s.prayersOwed, 0);
    });
  });

  test('unticked prayers count only from the first tracked day', () async {
    SharedPreferences.setMockInitialValues({
      'prayer_completions_v1': jsonEncode({
        '2026-10-24': ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'],
        '2026-10-25': ['Fajr', 'Dhuhr'],
      }),
    });
    final counts = await PrayerCompletionService.instance.untickedBetween(
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 26),
    );
    // 24th: all done. 25th: three missed. 26th: nothing ticked, five.
    expect(counts, {'Fajr': 1, 'Dhuhr': 1, 'Asr': 2, 'Maghrib': 2, 'Isha': 2});
  });

  testWidgets('the page in Bangla: make one up', (tester) async {
    await initializeDateFormatting();
    Intl.defaultLocale = 'bn';
    addTearDown(() => Intl.defaultLocale = null);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      QazaStore.key: jsonEncode({
        'owed': {'Fajr': 2, 'Witr': 1},
        'made': {},
        'log': [],
      }),
    });
    final store = QazaStore.forTesting();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: QazaPage(store: store),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('৩ ওয়াক্ত নামাজ বাকি'), findsOneWidget);
    expect(find.text('বিতর'), findsOneWidget);

    await tester.tap(find.byKey(const Key('qaza-made-Fajr')));
    await tester.pumpAndSettle();
    expect(store.owed['Fajr'], 1);
    expect(find.text('২ ওয়াক্ত নামাজ বাকি'), findsOneWidget);
  });
}
