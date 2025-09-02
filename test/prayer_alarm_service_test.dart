import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/core/services/prayer_alarm_service.dart';

void main() {
  group('PrayerAlarmService Tests', () {
    test('should create prayer alarm config correctly', () {
      final config = PrayerAlarmConfig(
        prayerName: 'Fajr',
        type: PrayerAlarmType.beforePrayerEnd,
        minutesBeforeEnd: 10,
        isEnabled: true,
      );

      expect(config.prayerName, equals('Fajr'));
      expect(config.type, equals(PrayerAlarmType.beforePrayerEnd));
      expect(config.minutesBeforeEnd, equals(10));
      expect(config.isEnabled, isTrue);
    });

    test('should convert prayer alarm config to/from JSON', () {
      final originalConfig = PrayerAlarmConfig(
        prayerName: 'Dhuhr',
        type: PrayerAlarmType.fixedTime,
        fixedTime: DateTime(2024, 1, 1, 12, 30),
        isEnabled: false,
      );

      final json = originalConfig.toJson();
      final restoredConfig = PrayerAlarmConfig.fromJson(json);

      expect(restoredConfig.prayerName, equals(originalConfig.prayerName));
      expect(restoredConfig.type, equals(originalConfig.type));
      expect(restoredConfig.fixedTime, equals(originalConfig.fixedTime));
      expect(restoredConfig.isEnabled, equals(originalConfig.isEnabled));
    });

    test('should handle prayer alarm types correctly', () {
      expect(PrayerAlarmType.values.length, equals(2));
      expect(PrayerAlarmType.beforePrayerEnd.index, equals(0));
      expect(PrayerAlarmType.fixedTime.index, equals(1));
    });

    test('should create service instance correctly', () {
      final service = PrayerAlarmService();
      expect(service.isEnabled, isTrue); // Default enabled state
      expect(service.alarms, isEmpty); // Initially no alarms
    });
  });
}
