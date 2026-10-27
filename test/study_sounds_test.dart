import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/core/services/prayer_alarm_service.dart';
import 'package:lifeque/features/study/presentation/widgets/study_sound_sheet.dart';
import 'package:lifeque/features/study/services/study_sound_service.dart';
import 'package:lifeque/features/study/services/study_timer_service.dart';
import 'package:lifeque/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what would have played.
class FakeStudyAudio implements StudyAudio {
  final List<String> cues = [];
  final Map<String, String> loops = {};
  final Map<String, double> volumes = {};

  @override
  Future<void> cue(String asset, double volume) async => cues.add(asset);

  @override
  Future<void> loop(String channel, String asset, double volume) async {
    loops[channel] = asset;
    volumes[channel] = volume;
  }

  @override
  Future<void> setLoopVolume(String channel, double volume) async =>
      volumes[channel] = volume;

  @override
  Future<void> stopLoop(String channel) async => loops.remove(channel);
}

void main() {
  late FakeStudyAudio audio;
  late StudySounds sounds;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    audio = FakeStudyAudio();
    sounds = StudySounds.forTesting(audio);
  });

  Future<void> configure(StudySoundSettings s) async {
    await sounds.update(s);
    audio.cues.clear();
  }

  group('background and ticking follow the session', () {
    test('play in a running focus block only', () async {
      await configure(
        const StudySoundSettings(ambient: StudyAmbient.rain, ticking: true),
      );

      await sounds.follow(phase: StudyPhase.focus, running: true);
      expect(audio.loops['ambient'], StudyAmbient.rain.asset);
      expect(audio.loops['tick'], isNotNull);

      await sounds.follow(phase: StudyPhase.focus, running: false); // paused
      expect(audio.loops, isEmpty);

      await sounds.follow(phase: StudyPhase.focus, running: true);
      await sounds.follow(phase: StudyPhase.shortBreak, running: true);
      expect(audio.loops, isEmpty, reason: 'quiet during breaks');

      await sounds.follow(phase: StudyPhase.focus, running: true);
      await sounds.follow(phase: StudyPhase.stopped, running: false);
      expect(audio.loops, isEmpty, reason: 'quiet once the session ends');
    });

    test('nothing loops with background off and ticking off', () async {
      await configure(const StudySoundSettings());
      await sounds.follow(phase: StudyPhase.focus, running: true);
      expect(audio.loops, isEmpty);
    });

    test('changing the setting mid-block takes effect at once', () async {
      await configure(const StudySoundSettings());
      await sounds.follow(phase: StudyPhase.focus, running: true);

      await sounds.update(
        const StudySoundSettings(ambient: StudyAmbient.brown),
      );
      expect(audio.loops['ambient'], StudyAmbient.brown.asset);

      await sounds.update(const StudySoundSettings(ambient: StudyAmbient.off));
      expect(audio.loops['ambient'], isNull);
    });

    test('a preview plays, then hands back to the session', () {
      fakeAsync((async) {
        sounds.update(const StudySoundSettings(ambient: StudyAmbient.rain));
        sounds.follow(phase: StudyPhase.shortBreak, running: true);
        async.flushMicrotasks();
        expect(audio.loops['ambient'], isNull);

        sounds.preview(StudyAmbient.white);
        async.flushMicrotasks();
        expect(audio.loops['ambient'], StudyAmbient.white.asset);

        async.elapse(const Duration(seconds: 7));
        expect(audio.loops['ambient'], isNull, reason: 'back to the break');
      });
    });
  });

  group('countdown', () {
    test('ticks once each at 3, 2 and 1', () async {
      await configure(const StudySoundSettings());
      await sounds.follow(phase: StudyPhase.focus, running: true);

      for (final s in [5, 4, 3, 3, 2, 1, 1, 0]) {
        await sounds.onTimeLeft(s);
      }
      expect(audio.cues, List.filled(3, StudyCue.count.asset));
    });

    test('stays quiet when off or paused', () async {
      await configure(const StudySoundSettings(countdown: false));
      await sounds.follow(phase: StudyPhase.focus, running: true);
      await sounds.onTimeLeft(2);
      expect(audio.cues, isEmpty);

      await configure(const StudySoundSettings());
      await sounds.follow(phase: StudyPhase.focus, running: false);
      await sounds.onTimeLeft(2);
      expect(audio.cues, isEmpty);
    });
  });

  group('chimes', () {
    test('tap cues play only with chimes on', () async {
      await configure(const StudySoundSettings());
      await sounds.cue(StudyCue.start);
      expect(audio.cues, [StudyCue.start.asset]);

      await configure(const StudySoundSettings(chimes: false));
      await sounds.cue(StudyCue.pause);
      expect(audio.cues, isEmpty);
    });

    test('focus and break ends get different alarm chimes', () async {
      await configure(const StudySoundSettings());
      final focusEnd = sounds.phaseEndAlarmSound(StudyPhase.focus);
      final breakEnd = sounds.phaseEndAlarmSound(StudyPhase.shortBreak);
      expect(focusEnd, isNot(breakEnd));
      expect(sounds.phaseEndAlarmSound(StudyPhase.longBreak), breakEnd);

      await configure(const StudySoundSettings(chimes: false));
      expect(
        sounds.phaseEndAlarmSound(StudyPhase.focus),
        isNull,
        reason: 'falls back to the regular alarm sound',
      );
    });
  });

  test('settings survive a restart', () async {
    const saved = StudySoundSettings(
      chimes: false,
      countdown: false,
      ticking: true,
      ambient: StudyAmbient.white,
      ambientVolume: 0.3,
    );
    await sounds.update(saved);

    final fresh = StudySounds.forTesting(FakeStudyAudio());
    await fresh.load();
    expect(fresh.settings.value, saved);
  });

  test('every sound the timer refers to is bundled', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/audio/study/'));
    final assets = [
      ...StudyCue.values.map((c) => c.asset),
      ...StudyAmbient.values.map((a) => a.asset).whereType<String>(),
      'audio/study/study_tick_loop.wav',
    ];
    for (final a in assets) {
      expect(File('assets/$a').existsSync(), isTrue, reason: a);
    }
    for (final phase in [StudyPhase.focus, StudyPhase.shortBreak]) {
      final path = sounds.phaseEndAlarmSound(phase)!;
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });

  test('study alarms never share ids with prayer alarms', () {
    for (final prayer in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      final ids = [
        for (var id = 900; id < 3000; id++)
          if (PrayerAlarmService.prayerForAlarmId(id) == prayer) id,
      ];
      expect(ids, hasLength(1));
      expect(StudyTimerService.ownsAlarm(ids.single), isFalse, reason: prayer);
    }
    expect(StudyTimerService.ownsAlarm(StudyTimerService.alarmIdBase), isTrue);
  });

  group('sound sheet', () {
    setUpAll(() async => initializeDateFormatting());
    tearDown(() => Intl.defaultLocale = null);

    Widget app(String locale) => MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: Scaffold(body: StudySoundSheet(sounds: sounds)),
    );

    testWidgets('renders in Bangla and previews a pick', (tester) async {
      Intl.defaultLocale = 'bn';
      await tester.pumpWidget(app('bn'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('শব্দ'), findsOneWidget);
      expect(find.text('বৃষ্টি'), findsOneWidget);
      expect(find.text('৩-২-১ গণনা'), findsOneWidget);

      await tester.tap(find.byKey(const Key('study-ambient-rain')));
      await tester.pump();
      expect(audio.loops['ambient'], StudyAmbient.rain.asset);
      expect(sounds.settings.value.ambient, StudyAmbient.rain);
      // The volume slider appears once a background is chosen.
      expect(find.byKey(const Key('study-sound-volume')), findsOneWidget);

      await sounds.endPreview();
    });

    testWidgets('switches save, and chimes report the change', (tester) async {
      var chimesChanged = 0;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: StudySoundSheet(
              sounds: sounds,
              onChimesChanged: () => chimesChanged++,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('study-sound-ticking')));
      await tester.pump();
      expect(sounds.settings.value.ticking, isTrue);

      await tester.tap(find.byKey(const Key('study-sound-chimes')));
      await tester.pump();
      expect(sounds.settings.value.chimes, isFalse);
      expect(chimesChanged, 1);
    });
  });
}
