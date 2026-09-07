import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/core/l10n/typed_digits_localizations.dart';
import 'package:lifeque/core/utils/local_numbers.dart';

void main() {
  test('digit conversion both ways', () {
    expect(N.ascii('৭/৯/২০২৬'), '7/9/2026');
    expect(N.bangla('7/9/2026'), '৭/৯/২০২৬');
    expect(N.bangla('৭/৯/2026'), '৭/৯/২০২৬');
  });

  group('Bangla material localization', () {
    late MaterialLocalizations l;
    setUpAll(() async {
      l = await TypedDigitsMaterialLocalizationBn.delegate.load(
        const Locale('bn'),
      );
    });

    test('still shows dates in Bangla digits', () {
      expect(l.formatCompactDate(DateTime(2026, 9, 7)), '৭/৯/২০২৬');
    });

    test('parses a typed date whatever digits it holds', () {
      final expected = DateTime(2026, 9, 7);
      expect(l.parseCompactDate('৭/৯/২০২৬'), expected);
      expect(l.parseCompactDate('7/9/2026'), expected);
      expect(l.parseCompactDate('৭/৯/2026'), expected);
      expect(l.parseCompactDate('nonsense'), isNull);
    });

    test('the time picker edits in Latin digits', () {
      const t = TimeOfDay(hour: 10, minute: 5);
      expect(l.formatHour(t), '10');
      expect(l.formatMinute(t), '05');
      expect(int.tryParse(l.formatHour(t)), 10);
    });

    test('is twelve-hour with AM/PM whatever the phone setting', () {
      expect(l.timeOfDayFormat(), TimeOfDayFormat.h_colon_mm_space_a);
      expect(
        l.timeOfDayFormat(alwaysUse24HourFormat: true),
        TimeOfDayFormat.h_colon_mm_space_a,
      );
      expect(l.formatHour(const TimeOfDay(hour: 23, minute: 59)), '11');
    });

    test('but a displayed time stays Bangla', () {
      const t = TimeOfDay(hour: 10, minute: 5);
      expect(l.formatTimeOfDay(t), contains('১০'));
      expect(l.formatTimeOfDay(t), isNot(contains('10')));
    });
  });

  testWidgets('a date typed with the phone keyboard is accepted', (
    tester,
  ) async {
    DateTime? picked;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        localizationsDelegates: const [
          TypedDigitsMaterialLocalizationBn.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('bn'), Locale('en')],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2026, 9, 7),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2030),
                  initialEntryMode: DatePickerEntryMode.input,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    // The delegate loads asynchronously; nothing renders until it has.
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Prefilled in Bangla; the keyboard types Latin.
    expect(find.text('৭/৯/২০২৬'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '7/9/2024');
    await tester.pumpAndSettle();
    final ok = await TypedDigitsMaterialLocalizationBn.delegate.load(
      const Locale('bn'),
    );
    await tester.tap(find.text(ok.okButtonLabel));
    await tester.pumpAndSettle();

    expect(picked, DateTime(2024, 9, 7));
  });

  testWidgets('the time picker offers AM/PM under Bangla', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        localizationsDelegates: const [
          TypedDigitsMaterialLocalizationBn.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('bn'), Locale('en')],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 23, minute: 59),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final l = await TypedDigitsMaterialLocalizationBn.delegate.load(
      const Locale('bn'),
    );
    expect(find.text(l.anteMeridiemAbbreviation), findsOneWidget);
    expect(find.text(l.postMeridiemAbbreviation), findsOneWidget);
    expect(find.text('11'), findsWidgets); // the hour, not 23
    expect(find.text('23'), findsNothing);
  });
}
