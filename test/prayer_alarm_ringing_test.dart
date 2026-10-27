import 'dart:async';
import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lifeque/core/services/prayer_alarm_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what the service asks of the alarm plugin, and rings on demand.
class FakeAlarmBackend implements AlarmBackend {
  final ringingController = StreamController<AlarmSet>.broadcast(sync: true);
  final Set<int> ringingIds = {};
  final List<AlarmSettings> sets = [];
  final List<int> stops = [];

  @override
  Stream<AlarmSet> get ringing => ringingController.stream;

  @override
  Future<bool> set(AlarmSettings settings) async {
    // The real plugin stops anything under the same id first — the bug.
    if (ringingIds.contains(settings.id)) await stop(settings.id);
    sets.add(settings);
    armed[settings.id] = settings;
    return true;
  }

  @override
  Future<bool> stop(int id) async {
    stops.add(id);
    armed.remove(id);
    if (ringingIds.remove(id)) {
      ringingController.add(AlarmSet(_ringingSettings()));
    }
    return true;
  }

  @override
  Future<bool> isRinging(int id) async => ringingIds.contains(id);

  /// Armed alarms, as the plugin's storage holds them.
  final Map<int, AlarmSettings> armed = {};

  @override
  Future<AlarmSettings?> scheduled(int id) async => armed[id];

  final Map<int, AlarmSettings> _known = {};
  Iterable<AlarmSettings> _ringingSettings() =>
      ringingIds.map((id) => _known[id]!);

  /// The plugin starting to ring [settings].
  void ring(AlarmSettings settings) {
    _known[settings.id] = settings;
    ringingIds.add(settings.id);
    ringingController.add(AlarmSet(_ringingSettings()));
  }

  void clearCalls() {
    sets.clear();
    stops.clear();
  }
}

const asrId = 1002;

AlarmSettings ringing(int id, DateTime due) => AlarmSettings(
  id: id,
  dateTime: due,
  assetAudioPath: null,
  volumeSettings: const VolumeSettings.fixed(),
  notificationSettings: const NotificationSettings(title: 't', body: 'b'),
);

Future<void> seedAsrAlarm({int ringMinutes = 2}) async {
  final config = PrayerAlarmConfig(
    prayerName: 'Asr',
    type: PrayerAlarmType.afterPrayerStart,
    minutesAfterStart: 0,
    alarmDurationMinutes: ringMinutes,
  );
  SharedPreferences.setMockInitialValues({
    'prayer_alarms': [jsonEncode(config.toJson())],
    'prayer_alarms_enabled': true,
  });
}

void main() {
  late FakeAlarmBackend backend;
  final service = PrayerAlarmService();

  setUp(() {
    // Notification text is read in the app language; English for asserts.
    Intl.defaultLocale = 'en';
    service.resetForTesting();
    backend = FakeAlarmBackend();
    service.backend = backend;
  });

  tearDown(() => service.resetForTesting());

  test('starting to ring does not reschedule (which would stop it)', () async {
    await seedAsrAlarm();
    await service.initialize();
    backend.clearCalls();

    backend.ring(ringing(asrId, DateTime.now()));
    await pumpEventQueue();

    expect(backend.sets.where((s) => s.id == asrId), isEmpty);
    expect(backend.stops, isNot(contains(asrId)));
    expect(backend.ringingIds, contains(asrId));
  });

  test('app start while ringing leaves the ring alone', () async {
    await seedAsrAlarm();
    // The ring is what opened the app: already ringing before init runs.
    backend.ring(ringing(asrId, DateTime.now()));
    backend.clearCalls();

    await service.initialize();
    await pumpEventQueue();

    expect(backend.stops, isNot(contains(asrId)));
    expect(backend.ringingIds, contains(asrId));
  });

  test('the background top-up leaves a ringing alarm alone', () async {
    await seedAsrAlarm();
    backend.ring(ringing(asrId, DateTime.now()));
    backend.clearCalls();

    await service.rescheduleFromBackground();

    expect(backend.stops, isEmpty);
    expect(backend.sets, isEmpty);
    expect(backend.ringingIds, contains(asrId));
  });

  test('stopping the ring queues the next occurrence', () async {
    await seedAsrAlarm();
    await service.initialize();
    backend.ring(ringing(asrId, DateTime.now()));
    await pumpEventQueue();
    backend.clearCalls();

    await backend.stop(asrId);
    await pumpEventQueue();

    final next = backend.sets.where((s) => s.id == asrId).toList();
    expect(next, hasLength(1));
    expect(next.single.dateTime.isAfter(DateTime.now()), isTrue);
    expect(next.single.allowSameSecondScheduling, isTrue);
    expect(next.single.androidStopAlarmOnTermination, isFalse);
    // No Android volume panel popping up as the ring starts and ends.
    expect(next.single.volumeSettings.showSystemUI, isFalse);
  });

  test('auto-stop counts from the ring, not from scheduling', () {
    fakeAsync((async) {
      seedAsrAlarm(ringMinutes: 3);
      service.initialize();
      async.flushMicrotasks();

      // Due now: it should ring the full three minutes.
      backend.ring(ringing(asrId, DateTime.now()));
      async.flushMicrotasks();

      async.elapse(const Duration(minutes: 2, seconds: 50));
      expect(backend.ringingIds, contains(asrId), reason: 'still ringing');

      async.elapse(const Duration(seconds: 20));
      expect(backend.ringingIds, isNot(contains(asrId)));
      expect(backend.stops, contains(asrId));
    });
  });

  test('a ring that opened the app late still stops on time', () {
    fakeAsync((async) {
      seedAsrAlarm(ringMinutes: 2);
      service.initialize();
      async.flushMicrotasks();

      // Due 90 s ago: only 30 s of its two minutes remain.
      backend.ring(
        ringing(asrId, DateTime.now().subtract(const Duration(seconds: 90))),
      );
      async.flushMicrotasks();

      async.elapse(const Duration(seconds: 35));
      expect(backend.ringingIds, isNot(contains(asrId)));
    });
  });

  test('turning an alarm off stops its ring and its auto-stop', () {
    fakeAsync((async) {
      seedAsrAlarm();
      service.initialize();
      async.flushMicrotasks();
      backend.ring(ringing(asrId, DateTime.now()));
      async.flushMicrotasks();

      service.removeAlarm('Asr');
      async.flushMicrotasks();
      expect(backend.ringingIds, isEmpty);

      backend.clearCalls();
      async.elapse(const Duration(minutes: 5));
      // Nothing left to stop, and no alarm queued for a removed prayer.
      expect(backend.sets, isEmpty);
    });
  });

  test('notification text follows the prayer and timing', () async {
    await seedAsrAlarm();
    await service.initialize();
    final asr = backend.sets.firstWhere((s) => s.id == asrId);
    expect(asr.notificationSettings.title, contains('Asr'));
    expect(asr.notificationSettings.body, 'Asr has begun');
    expect(asr.notificationSettings.stopButton, 'Stop');
    expect(asr.payload, 'Asr');
  });

  test('re-queueing leaves an alarm that is already armed alone', () async {
    await seedAsrAlarm();
    await service.initialize();
    expect(backend.sets.where((s) => s.id == asrId), hasLength(1));
    backend.clearCalls();

    // The 15-minute background top-up, then the midnight refresh.
    await service.rescheduleFromBackground();
    await service.rescheduleFromBackground();

    expect(backend.sets, isEmpty);
    expect(backend.stops, isEmpty);
  });

  test('an alarm due within seconds is never re-armed', () async {
    // Fixed time a few seconds ahead: the plugin would arm this on its
    // uncancellable in-process timer, so a second set makes it fire twice.
    final due = DateTime.now().add(const Duration(seconds: 3));
    final config = PrayerAlarmConfig(
      prayerName: 'Isha',
      type: PrayerAlarmType.fixedTime,
      fixedTime: due,
    );
    SharedPreferences.setMockInitialValues({
      'prayer_alarms': [jsonEncode(config.toJson())],
      'prayer_alarms_enabled': true,
    });
    await service.initialize();
    expect(backend.sets.where((s) => s.id == 1004), hasLength(1));
    backend.clearCalls();

    // Language changed in between, so the text differs — still left alone.
    Intl.defaultLocale = 'bn';
    await service.rescheduleFromBackground();
    expect(backend.sets, isEmpty);
    expect(backend.stops, isEmpty);
  });

  test('a changed alarm well ahead is re-armed', () async {
    await seedAsrAlarm();
    await service.initialize();
    backend.clearCalls();
    // Same time, new sound.
    final asr = service.configFor('Asr')!;
    await service.updateAlarm(asr.copyWith(vibrate: !asr.vibrate));
    expect(backend.sets.where((s) => s.id == asrId), hasLength(1));
  });
}
