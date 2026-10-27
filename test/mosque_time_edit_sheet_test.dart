import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/features/prayer_times/presentation/widgets/mosque_time_edit_sheet.dart';
import 'package:lifeque/l10n/app_localizations.dart';

Widget _sheet(String locale, {bool isDefault = true}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: L.localizationsDelegates,
  supportedLocales: L.supportedLocales,
  home: Scaffold(
    body: MosqueTimeEditSheet(
      prayer: 'Asr',
      currentMosqueTime: const TimeOfDay(hour: 15, minute: 46),
      waqtTime: const TimeOfDay(hour: 15, minute: 46),
      isRamadanMode: false,
      isLockedByRamadan: false,
      isDefault: isDefault,
      onSaved: (_) {},
      onRamadanModeChanged: (_) {},
    ),
  ),
);

void main() {
  setUpAll(() async => initializeDateFormatting());
  tearDown(() => Intl.defaultLocale = null);

  testWidgets('renders in Bangla, with nothing left in English', (
    tester,
  ) async {
    Intl.defaultLocale = 'bn';
    await tester.pumpWidget(_sheet('bn'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('আসর জামাতের সময়'), findsOneWidget);
    expect(find.text('দুপুর ৩:৪৬'), findsOneWidget);
    expect(find.text('নির্দিষ্ট সময় বাছুন'), findsOneWidget);
    expect(find.text('রমজান মোড'), findsOneWidget);
    expect(find.text('সংরক্ষণ'), findsOneWidget);

    for (final english in [
      'Save',
      'Ramadan mode',
      'Pick exact time',
      'Same as waqt',
    ]) {
      expect(find.text(english), findsNothing, reason: english);
    }
  });

  testWidgets('steps show the gap from waqt in Bangla', (tester) async {
    Intl.defaultLocale = 'bn';
    await tester.pumpWidget(_sheet('bn', isDefault: false));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(find.text('ওয়াক্তের ৫ মিনিট পরে'), findsOneWidget);
  });

  testWidgets('still reads in English', (tester) async {
    Intl.defaultLocale = 'en';
    await tester.pumpWidget(_sheet('en'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Asr jamaat time'), findsOneWidget);
    expect(find.text('3:46 pm'), findsOneWidget);
  });
}
