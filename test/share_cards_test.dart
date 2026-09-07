import 'dart:io';
import 'dart:ui' as ui;

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/core/utils/salah_time_calculator.dart';
import 'package:lifeque/features/prayer_times/presentation/widgets/month_timetable_sheet.dart';
import 'package:lifeque/features/prayer_times/presentation/widgets/prayer_share_sheet.dart';
import 'package:lifeque/l10n/app_localizations.dart';

/// Renders each share card at its export size and writes the PNG out, so
/// the design can be looked at without a device. Also proves the layout
/// has no overflow at that size.
void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    Intl.defaultLocale = 'bn';
  });

  Future<void> export(
    WidgetTester tester,
    Widget card,
    Size size,
    String name,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Scaffold(
          body: RepaintBoundary(key: key, child: card),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    // Written beside the test for eyeballing; harmless if the dir is absent.
    final out = Directory('build/share_previews')..createSync(recursive: true);
    File('${out.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  testWidgets('daily card renders at 1080×1350 without overflow', (
    tester,
  ) async {
    final calc = SalahTimeCalculator(
      latitude: 23.8103,
      longitude: 90.4125,
      date: DateTime(2026, 9, 11), // a Friday, so the badge shows
      method: CalculationMethod.karachi,
      madhab: Madhab.hanafi,
    );
    await tester.runAsync(
      () => export(
        tester,
        PrayerShareCard(
          calculator: calc,
          date: DateTime(2026, 9, 11),
          locationName: 'ঢাকা, বাংলাদেশ',
        ),
        const Size(1080, 1350),
        'daily',
      ),
    );
  });

  testWidgets('month sheet renders at 794×1123 without overflow', (
    tester,
  ) async {
    await tester.runAsync(
      () => export(
        tester,
        MonthTimetableCard(
          month: DateTime(2026, 9),
          latitude: 23.8103,
          longitude: 90.4125,
          method: CalculationMethod.karachi,
          madhab: Madhab.hanafi,
          locationName: 'ঢাকা, বাংলাদেশ',
        ),
        const Size(794, 1123),
        'month',
      ),
    );
  });
}
