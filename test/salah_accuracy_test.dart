import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/core/utils/hijri_date.dart';
import 'package:lifeque/core/utils/salah_time_calculator.dart';
import 'package:lifeque/core/utils/sun_clock.dart';
import 'package:lifeque/features/prayer_times/presentation/utils/bangla_date.dart';

/// Dhaka as the reference app places it.
const _lat = 23.778714, _lon = 90.397965;

/// "HH:mm" on Bangladesh time, whatever zone the test machine is in.
String bd(DateTime t) {
  final u = t.toUtc().add(const Duration(hours: 6));
  return '${u.hour.toString().padLeft(2, '0')}:'
      '${u.minute.toString().padLeft(2, '0')}';
}

SalahTimeCalculator dhaka(int y, int m, int d) => SalahTimeCalculator(
  latitude: _lat,
  longitude: _lon,
  date: DateTime(y, m, d),
  method: CalculationMethod.karachi,
  madhab: Madhab.hanafi,
);

void main() {
  group('prayer times match the Islamic Foundation-style reference', () {
    // Every value below is what Muslims Day (calendar view, Karachi 18°,
    // Hanafi) shows for Dhaka on 28 October 2026.
    test('Dhaka, 28 October 2026', () {
      final t = dhaka(2026, 10, 28).getPrayerTimesMap();
      expect(bd(t['Fajr']!), '04:45');
      expect(bd(t['Sunrise']!), '06:01');
      expect(bd(t['Dhuhr']!), '11:46');
      expect(bd(t['Asr']!), '15:46');
      expect(bd(t['Maghrib']!), '17:23');
      expect(bd(t['Isha']!), '18:39');
    });

    test('Dhuhr waits for zawal to pass: never at the bare solar noon', () {
      // adhan put Dhuhr at 11:43 — inside the forbidden window.
      final c = dhaka(2026, 10, 27);
      expect(bd(c.getPrayerTimesMap()['Dhuhr']!), '11:46');
      final zawal = c.getRestrictedTimes()['Zawal (Midday)']!;
      expect(bd(zawal['start'] as DateTime), '11:38');
      expect(bd(zawal['end'] as DateTime), '11:45');
    });

    test('each waqt ends the minute before the next begins', () {
      // Muslims Day home screen, 27 Oct: Fajr 4:44–6:00, Dhuhr 11:46–3:46,
      // Asr 3:47–5:22, Maghrib 5:23–6:39, Isha 6:40–4:45.
      final c = dhaka(2026, 10, 27);
      final e = c.getEndTimes(c.getStartTimes());
      expect(bd(e['Fajr']!), '06:00');
      expect(bd(e['Dhuhr']!), '15:46');
      expect(bd(e['Asr']!), '17:22');
      expect(bd(e['Maghrib']!), '18:39');
      expect(bd(e['Isha']!), '04:45');
    });

    test('forbidden windows at sunrise and sunset', () {
      final r = dhaka(2026, 10, 28).getRestrictedTimes();
      expect(bd(r['Sunrise Period']!['start'] as DateTime), '06:01');
      expect(bd(r['Sunrise Period']!['end'] as DateTime), '06:16');
      expect(bd(r['Sunset Period']!['start'] as DateTime), '17:08');
      expect(bd(r['Sunset Period']!['end'] as DateTime), '17:22');
    });

    test('a year in Dhaka: order holds and every time is sane', () {
      for (
        var d = DateTime(2026, 1, 1);
        d.year == 2026;
        d = DateTime(d.year, d.month, d.day + 1)
      ) {
        final t = dhaka(d.year, d.month, d.day).getPrayerTimesMap();
        final order = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
        for (var i = 1; i < order.length; i++) {
          expect(
            t[order[i]]!.isAfter(t[order[i - 1]]!),
            isTrue,
            reason: '$d ${order[i]}',
          );
        }
        // Within two minutes of adhan everywhere: same astronomy, safer
        // rounding, Dhuhr after zawal.
        final a = dhaka(d.year, d.month, d.day).getPrayerTimes();
        for (final (k, v) in [
          ('Fajr', a.fajr),
          ('Sunrise', a.sunrise),
          ('Asr', a.asr),
          ('Maghrib', a.maghrib),
          ('Isha', a.isha),
        ]) {
          expect(
            t[k]!.difference(v).inMinutes.abs(),
            lessThanOrEqualTo(2),
            reason: '$d $k',
          );
        }
        expect(
          t['Dhuhr']!.isAfter(a.dhuhr.subtract(const Duration(minutes: 1))),
          isTrue,
          reason: '$d Dhuhr',
        );
      }
    });

    test('far north falls back to a seventh of the night', () {
      final c = SalahTimeCalculator(
        latitude: 59.91,
        longitude: 10.75, // Oslo, midsummer: the sun never reaches -18°
        date: DateTime(2026, 6, 21),
        method: CalculationMethod.karachi,
      );
      final t = c.getPrayerTimesMap();
      expect(t['Fajr']!.isBefore(t['Sunrise']!), isTrue);
      expect(t['Isha']!.isAfter(t['Maghrib']!), isTrue);
    });
  });

  group('safe rounding', () {
    test('starts round up, Fajr rounds strictly down', () {
      expect(
        SafeMinute.up(DateTime(2026, 1, 1, 11, 45, 1)),
        DateTime(2026, 1, 1, 11, 46),
      );
      expect(
        SafeMinute.up(DateTime(2026, 1, 1, 11, 45)),
        DateTime(2026, 1, 1, 11, 45),
      );
      expect(
        SafeMinute.down(DateTime(2026, 1, 1, 4, 45, 59)),
        DateTime(2026, 1, 1, 4, 45),
      );
      expect(
        SafeMinute.down(DateTime(2026, 1, 1, 4, 45)),
        DateTime(2026, 1, 1, 4, 44),
      );
    });
  });

  group('Bangla calendar (Bangladesh, 2019 revision)', () {
    test('the first six months have 31 days', () {
      expect(
        BanglaDate.fromDate(DateTime(2026, 4, 14)).formatted,
        '১ বৈশাখ ১৪৩৩',
      );
      final kartik = BanglaDate.fromDate(DateTime(2026, 10, 27));
      expect((kartik.day, kartik.month, kartik.year), (11, 7, 1433));
      final ashwin = BanglaDate.fromDate(DateTime(2026, 10, 16));
      expect((ashwin.day, ashwin.month), (31, 6));
    });

    test('Falgun has 29 days, 30 in a leap year', () {
      // Falgun starts on 14 February either way, so 1 Choitro is always
      // 15 March; in a leap year Falgun's extra day is 14 March.
      final normal = BanglaDate.fromDate(DateTime(2027, 3, 15));
      expect((normal.day, normal.month), (1, 12));
      final leap = BanglaDate.fromDate(DateTime(2028, 3, 15));
      expect((leap.day, leap.month), (1, 12));
      final leapLast = BanglaDate.fromDate(DateTime(2028, 3, 14));
      expect((leapLast.day, leapLast.month), (30, 11));
    });

    test('Pohela Boishakh and Bijoy Dibos fall where they should', () {
      expect(BanglaDate.fromDate(DateTime(2027, 4, 14)).day, 1);
      final bijoy = BanglaDate.fromDate(DateTime(2026, 12, 16));
      expect((bijoy.day, bijoy.month), (1, 9)); // ১ পৌষ
    });
  });

  group('Hijri date follows local moon sighting', () {
    tearDown(() => HijriDate.offset = 0);

    test('Bangladesh defaults to a day behind Umm al-Qura', () {
      expect(HijriDate.defaultFor(_lat, _lon), -1);
      expect(HijriDate.defaultFor(21.42, 39.83), 0); // Makkah
      expect(HijriDate.defaultFor(null, null), 0);
    });

    test('27 October 2026 is 15 Jumada al-Ula in Dhaka', () {
      HijriDate.offset = -1;
      final h = HijriDate.of(DateTime(2026, 10, 27));
      expect((h.hDay, h.hMonth, h.hYear), (15, 5, 1448));
      HijriDate.offset = 0;
      expect(HijriDate.of(DateTime(2026, 10, 27)).hDay, 16);
    });

    test('back to the Gregorian day, offset included', () {
      for (final o in [-2, -1, 0, 1, 2]) {
        HijriDate.offset = o;
        final g = HijriDate.toGregorian(1448, 9, 1);
        final h = HijriDate.of(g);
        expect((h.hDay, h.hMonth, h.hYear), (1, 9, 1448), reason: 'offset $o');
      }
    });
  });
}
