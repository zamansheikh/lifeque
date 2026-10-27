import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/core/services/prayer_alarm_service.dart';
import 'package:lifeque/features/prayer_times/presentation/utils/bell_alarm_preset.dart';

void main() {
  group('BellAlarmPreset', () {
    test('round-trips every timing kind', () {
      const presets = [
        BellAlarmPreset.fromStart(-5),
        BellAlarmPreset.fromStart(0),
        BellAlarmPreset.beforeEnd(10),
        BellAlarmPreset.fromJamaat(15),
        BellAlarmPreset.fromJamaat(-10),
        BellAlarmPreset.at(TimeOfDay(hour: 4, minute: 30)),
      ];
      for (final p in presets) {
        expect(BellAlarmPreset.decode(p.encode()), p);
      }
    });

    test('reads the names stored before this format', () {
      expect(
        BellAlarmPreset.decode('fiveBefore'),
        const BellAlarmPreset.fromStart(-5),
      );
      expect(
        BellAlarmPreset.decode('atTime'),
        const BellAlarmPreset.fromStart(0),
      );
      expect(
        BellAlarmPreset.decode('tenAfter'),
        const BellAlarmPreset.fromStart(10),
      );
      expect(BellAlarmPreset.decode('nonsense'), isNull);
      expect(BellAlarmPreset.decode(null), isNull);
    });

    test('config round-trip keeps timing and existing sound', () {
      final existing = PrayerAlarmConfig(
        prayerName: 'Asr',
        type: PrayerAlarmType.afterPrayerStart,
        minutesAfterStart: 0,
        soundPath: 'custom.mp3',
        alarmDurationMinutes: 5,
      );
      const preset = BellAlarmPreset.at(TimeOfDay(hour: 16, minute: 5));
      final config = preset.toConfig(
        'Asr',
        existing: existing,
        defaultSound: 'default.mp3',
      );
      expect(config.type, PrayerAlarmType.fixedTime);
      expect(config.soundPath, 'custom.mp3');
      expect(config.alarmDurationMinutes, 5);
      expect(BellAlarmPreset.fromConfig(config), preset);

      final end = const BellAlarmPreset.beforeEnd(
        10,
      ).toConfig('Asr', defaultSound: 'default.mp3');
      expect(end.minutesBeforeEnd, 10);
      expect(
        BellAlarmPreset.fromConfig(end),
        const BellAlarmPreset.beforeEnd(10),
      );
      expect(
        BellAlarmPreset.fromConfig(end.copyWith(isEnabled: false)),
        isNull,
      );
    });
  });
}
