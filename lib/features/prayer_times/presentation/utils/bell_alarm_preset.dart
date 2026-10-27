import 'package:flutter/material.dart';

import '../../../../core/services/prayer_alarm_service.dart';

/// One alarm timing for a prayer, as the bell on the salat list remembers it.
///
/// It covers every timing the alarm service can schedule — relative to waqt
/// start, to waqt end, to jamaat, or a fixed clock time — so a long-press on
/// the bell can set again whatever was used last, however it was set.
@immutable
class BellAlarmPreset {
  final PrayerAlarmType type;

  /// Minutes after waqt start or jamaat (negative = before), or minutes
  /// before the waqt ends. Unused for [PrayerAlarmType.fixedTime].
  final int minutes;

  /// The clock time for [PrayerAlarmType.fixedTime].
  final TimeOfDay? time;

  const BellAlarmPreset._(this.type, this.minutes, this.time);

  const BellAlarmPreset.fromStart(int minutes)
    : this._(PrayerAlarmType.afterPrayerStart, minutes, null);

  const BellAlarmPreset.beforeEnd(int minutes)
    : this._(PrayerAlarmType.beforePrayerEnd, minutes, null);

  const BellAlarmPreset.fromJamaat(int minutes)
    : this._(PrayerAlarmType.afterJamaat, minutes, null);

  const BellAlarmPreset.at(TimeOfDay time)
    : this._(PrayerAlarmType.fixedTime, 0, time);

  /// The fixed rows of the bell's chooser. A fixed clock time is added by
  /// the chooser itself, since it needs a picker.
  static const choices = [
    BellAlarmPreset.fromStart(-5),
    BellAlarmPreset.fromStart(0),
    BellAlarmPreset.fromStart(10),
    BellAlarmPreset.fromJamaat(-10),
  ];

  /// The timing an alarm config uses, or null for a disabled or incomplete one.
  static BellAlarmPreset? fromConfig(PrayerAlarmConfig? c) {
    if (c == null || !c.isEnabled) return null;
    return switch (c.type) {
      PrayerAlarmType.afterPrayerStart => BellAlarmPreset.fromStart(
        c.minutesAfterStart,
      ),
      PrayerAlarmType.beforePrayerEnd => BellAlarmPreset.beforeEnd(
        c.minutesBeforeEnd,
      ),
      PrayerAlarmType.afterJamaat => BellAlarmPreset.fromJamaat(
        c.minutesAfterStart,
      ),
      PrayerAlarmType.fixedTime =>
        c.fixedTime == null
            ? null
            : BellAlarmPreset.at(TimeOfDay.fromDateTime(c.fixedTime!)),
    };
  }

  /// An enabled config for [prayer] with this timing. Sound, ring length and
  /// vibration carry over from [existing] so a timing change keeps them.
  PrayerAlarmConfig toConfig(
    String prayer, {
    PrayerAlarmConfig? existing,
    required String defaultSound,
  }) {
    final now = DateTime.now();
    return PrayerAlarmConfig(
      prayerName: prayer,
      type: type,
      minutesAfterStart:
          type == PrayerAlarmType.afterPrayerStart ||
              type == PrayerAlarmType.afterJamaat
          ? minutes
          : (existing?.minutesAfterStart ?? 5),
      minutesBeforeEnd: type == PrayerAlarmType.beforePrayerEnd
          ? minutes
          : (existing?.minutesBeforeEnd ?? 5),
      fixedTime: time == null
          ? null
          : DateTime(now.year, now.month, now.day, time!.hour, time!.minute),
      isEnabled: true,
      soundPath: existing?.soundPath ?? defaultSound,
      alarmDurationMinutes: existing?.alarmDurationMinutes ?? 2,
      vibrate: existing?.vibrate ?? true,
    );
  }

  /// Stored form, e.g. `start:-5`, `end:10`, `jamaat:0`, `fixed:16:30`.
  String encode() => switch (type) {
    PrayerAlarmType.afterPrayerStart => 'start:$minutes',
    PrayerAlarmType.beforePrayerEnd => 'end:$minutes',
    PrayerAlarmType.afterJamaat => 'jamaat:$minutes',
    PrayerAlarmType.fixedTime => 'fixed:${time!.hour}:${time!.minute}',
  };

  /// Reads [encode]'s form, plus the three names the bell stored before it
  /// knew about end-of-waqt and clock-time alarms.
  static BellAlarmPreset? decode(String? raw) {
    if (raw == null) return null;
    switch (raw) {
      case 'fiveBefore':
        return const BellAlarmPreset.fromStart(-5);
      case 'atTime':
        return const BellAlarmPreset.fromStart(0);
      case 'tenAfter':
        return const BellAlarmPreset.fromStart(10);
    }
    final parts = raw.split(':');
    final nums = parts.skip(1).map(int.tryParse).toList();
    if (nums.isEmpty || nums.contains(null)) return null;
    return switch (parts.first) {
      'start' => BellAlarmPreset.fromStart(nums[0]!),
      'end' => BellAlarmPreset.beforeEnd(nums[0]!),
      'jamaat' => BellAlarmPreset.fromJamaat(nums[0]!),
      'fixed' when nums.length == 2 => BellAlarmPreset.at(
        TimeOfDay(hour: nums[0]!, minute: nums[1]!),
      ),
      _ => null,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is BellAlarmPreset &&
      other.type == type &&
      other.minutes == minutes &&
      other.time == time;

  @override
  int get hashCode => Object.hash(type, minutes, time);
}
