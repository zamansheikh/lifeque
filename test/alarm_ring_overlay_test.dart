import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/core/services/prayer_alarm_service.dart';
import 'package:lifeque/core/widgets/alarm_ring_overlay.dart';
import 'package:lifeque/l10n/app_localizations.dart';

AlarmSettings _alarm(int id, {String title = 't', String body = 'b'}) =>
    AlarmSettings(
      id: id,
      dateTime: DateTime.now(),
      assetAudioPath: null,
      volumeSettings: const VolumeSettings.fixed(),
      notificationSettings: NotificationSettings(title: title, body: body),
    );

void main() {
  late StreamController<AlarmSet> ringing;
  late List<int> stopped;
  late RootBackButtonDispatcher back;

  setUpAll(() async => initializeDateFormatting());
  setUp(() {
    ringing = StreamController<AlarmSet>.broadcast();
    stopped = [];
    // Stands in for the router, which registers itself on the real one.
    back = RootBackButtonDispatcher()..addCallback(() => Future.value(false));
  });
  tearDown(() {
    ringing.close();
    Intl.defaultLocale = null;
  });

  Widget app(String locale) => MaterialApp(
    locale: Locale(locale),
    localizationsDelegates: L.localizationsDelegates,
    supportedLocales: L.supportedLocales,
    builder: (context, child) => AlarmRingOverlay(
      ringing: ringing.stream,
      backButtonDispatcher: back,
      onStop: (id) async {
        stopped.add(id);
        ringing.add(AlarmSet.empty());
      },
      child: child!,
    ),
    home: const Scaffold(body: Text('home page')),
  );

  // The ring screen animates forever, so pump frames rather than settle.
  Future<void> show(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('nothing covers the app while no alarm rings', (tester) async {
    await tester.pumpWidget(app('en'));
    await show(tester);
    expect(find.text('home page'), findsOneWidget);
    expect(find.byKey(const Key('alarm-ring-stop')), findsNothing);
  });

  testWidgets('a prayer alarm fills the screen, in Bangla', (tester) async {
    Intl.defaultLocale = 'bn';
    await tester.pumpWidget(app('bn'));
    ringing.add(AlarmSet([_alarm(1002)])); // Asr
    await show(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('নামাজের অ্যালার্ম'), findsOneWidget);
    expect(find.text('আসর'), findsOneWidget);
    expect(find.text('বন্ধ করুন'), findsOneWidget);
    // The page underneath is covered, not just overlapped.
    final stop = tester.getRect(find.byKey(const Key('alarm-ring-stop')));
    expect(stop.height, greaterThanOrEqualTo(64));
  });

  testWidgets('Stop stops that alarm and uncovers the app', (tester) async {
    Intl.defaultLocale = 'en';
    await tester.pumpWidget(app('en'));
    ringing.add(AlarmSet([_alarm(1000)])); // Fajr
    await show(tester);
    expect(find.text('Fajr'), findsOneWidget);

    await tester.tap(find.byKey(const Key('alarm-ring-stop')));
    await show(tester);

    expect(stopped, [1000]);
    expect(find.byKey(const Key('alarm-ring-stop')), findsNothing);
  });

  testWidgets('a ring stopped from the notification closes the screen', (
    tester,
  ) async {
    Intl.defaultLocale = 'en';
    await tester.pumpWidget(app('en'));
    ringing.add(AlarmSet([_alarm(1003)]));
    await show(tester);
    expect(find.byKey(const Key('alarm-ring-stop')), findsOneWidget);

    ringing.add(AlarmSet.empty());
    await show(tester);
    expect(find.byKey(const Key('alarm-ring-stop')), findsNothing);
    expect(stopped, isEmpty);
  });

  testWidgets('Back is swallowed only while ringing', (tester) async {
    Intl.defaultLocale = 'en';
    await tester.pumpWidget(app('en'));
    ringing.add(AlarmSet([_alarm(1004)]));
    await show(tester);
    expect(await back.invokeCallback(Future.value(false)), isTrue);

    ringing.add(AlarmSet.empty());
    await show(tester);
    expect(await back.invokeCallback(Future.value(false)), isFalse);
  });

  testWidgets('study timer chimes do not take over the screen', (tester) async {
    Intl.defaultLocale = 'en';
    await tester.pumpWidget(app('en'));
    ringing.add(AlarmSet([_alarm(2003, title: 'Break over', body: 'Focus')]));
    await show(tester);
    expect(find.byKey(const Key('alarm-ring-stop')), findsNothing);
    expect(find.text('home page'), findsOneWidget);
    expect(PrayerAlarmService.prayerForAlarmId(2003), isNull);
  });

  testWidgets('a custom rule can cover other alarms with their own text', (
    tester,
  ) async {
    Intl.defaultLocale = 'en';
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        builder: (context, child) => AlarmRingOverlay(
          ringing: ringing.stream,
          covers: (_) => true,
          onStop: (id) async => stopped.add(id),
          child: child!,
        ),
        home: const Scaffold(body: Text('home page')),
      ),
    );
    ringing.add(AlarmSet([_alarm(42, title: 'Break over', body: 'Focus')]));
    await show(tester);
    expect(find.text('Alarm'), findsOneWidget);
    expect(find.text('Break over'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
  });
}
