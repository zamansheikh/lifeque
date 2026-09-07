import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/core/utils/salah_time_calculator.dart';
import 'package:adhan/adhan.dart';

void main() {
  // Dhaka, 7 Sep 2026: Fajr 4:25, sunrise 5:42, Dhuhr 11:57, Asr 4:25,
  // Maghrib 6:11, Isha 7:27 (local, +06).
  final calc = SalahTimeCalculator(
    latitude: 23.8103,
    longitude: 90.4125,
    date: DateTime(2026, 9, 7),
    method: CalculationMethod.karachi,
    madhab: Madhab.hanafi,
  );
  final t = calc.getPrayerTimesMap();

  test('the morning gap after sunrise has no running waqt', () {
    final afterSunrise = t['Sunrise']!.add(const Duration(minutes: 1));
    expect(calc.currentFard(afterSunrise), isNull);
    expect(calc.currentFard(DateTime(2026, 9, 7, 9, 28)), isNull);
  });

  test('inside each waqt it is that prayer', () {
    expect(
      calc.currentFard(t['Fajr']!.add(const Duration(minutes: 1))),
      'Fajr',
    );
    expect(
      calc.currentFard(t['Dhuhr']!.add(const Duration(minutes: 1))),
      'Dhuhr',
    );
    expect(calc.currentFard(t['Asr']!.add(const Duration(minutes: 1))), 'Asr');
    expect(
      calc.currentFard(t['Maghrib']!.add(const Duration(minutes: 1))),
      'Maghrib',
    );
    expect(
      calc.currentFard(t['Isha']!.add(const Duration(minutes: 1))),
      'Isha',
    );
  });

  test('before Fajr it is last night\'s Isha', () {
    expect(calc.currentFard(DateTime(2026, 9, 7, 1, 8)), 'Isha');
  });
}
