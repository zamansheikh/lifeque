import 'dart:convert';
import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifeque/core/utils/hijri_date.dart';
import 'package:lifeque/core/utils/salah_time_calculator.dart';
import 'package:lifeque/features/ifa/ifa_district.dart';
import 'package:lifeque/features/ifa/ifa_ramadan.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Islamic Foundation's own Ramadan 1447 tables, all 64 districts, as
/// converted from its PDFs by tool/ifa/pdf_to_json.py.
final Map<String, dynamic> official1447 =
    jsonDecode(File('ifa/1447.json').readAsStringSync())
        as Map<String, dynamic>;

/// "HH:mm" on Bangladesh time.
String bd(DateTime t) {
  final u = t.toUtc().add(const Duration(hours: 6));
  return '${u.hour.toString().padLeft(2, '0')}:'
      '${u.minute.toString().padLeft(2, '0')}';
}

int minutes(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

DateTime day(String iso) {
  final p = iso.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    IfaRamadan.resetForTesting();
    HijriDate.offset = 0;
  });

  test('all 64 districts are there, each once', () {
    expect(ifaDistricts.length, 64);
    expect(ifaDistricts.map((d) => d.id).toSet().length, 64);
    final tables = official1447['districts'] as Map<String, dynamic>;
    expect(tables.keys.toSet(), ifaDistricts.map((d) => d.id).toSet());
  });

  test("worked out by IFB's rule, 1447 comes out as IFB printed it", () {
    var total = 0, exact = 0, worst = 0;
    final tables = official1447['districts'] as Map<String, dynamic>;
    for (final d in ifaDistricts) {
      for (final row in tables[d.id] as List) {
        final r = [...(row as List).cast<String>()];
        final got = IfaRamadan.computed(d, day(r[0]));
        // IFB's PDF prints Jamalpur's Fajr on 18 March as 5:52 — a typo for
        // 4:52 (the days around it run 4:53, 4:51). Ours says 4:52.
        if (d.id == 'jamalpur' && r[0] == '2026-03-18') {
          expect(bd(got.fajr), '04:52');
          r[2] = '04:52';
        }
        for (final (mine, theirs) in [
          (bd(got.sahri), r[1]),
          (bd(got.fajr), r[2]),
          (bd(got.iftar), r[3]),
        ]) {
          total++;
          if (mine == theirs) exact++;
          final diff = (minutes(mine) - minutes(theirs)).abs();
          if (diff > worst) worst = diff;
        }
      }
    }
    expect(total, 5760);
    expect(exact, greaterThanOrEqualTo(5755)); // 5759 when generated
    expect(worst, lessThanOrEqualTo(1));
  });

  test('a published table is used exactly as printed', () {
    IfaRamadan.addTableForTesting(official1447);
    final tables = official1447['districts'] as Map<String, dynamic>;
    for (final d in ifaDistricts) {
      for (final row in tables[d.id] as List) {
        final r = (row as List).cast<String>();
        final got = IfaRamadan.timesFor(d, day(r[0]));
        expect(got.official, isTrue);
        expect(
          [bd(got.sahri), bd(got.fajr), bd(got.iftar)],
          r.sublist(1),
          reason: '${d.id} ${r[0]}',
        );
      }
    }
  });

  test('a GPS fix finds its district', () {
    String? at(double lat, double lon) => IfaDistrict.at(lat, lon)?.id;
    expect(at(23.7787, 90.3980), 'dhaka');
    expect(at(22.3569, 91.7832), 'chattogram');
    expect(at(24.8949, 91.8687), 'sylhet');
    expect(at(22.8456, 89.5403), 'khulna');
    expect(at(24.3745, 88.6042), 'rajshahi');
    expect(at(26.3411, 88.5542), 'panchagarh');
    expect(at(21.4272, 92.0058), 'coxsbazar');
    expect(at(22.5726, 88.3639), isNull); // Kolkata
    expect(at(21.4225, 39.8262), isNull); // Makkah
  });

  group('the calculator during Ramadan', () {
    SalahTimeCalculator dhaka(DateTime d) => SalahTimeCalculator(
      latitude: 23.7787,
      longitude: 90.3980,
      date: d,
      method: CalculationMethod.karachi,
    );

    test('off: nothing changes', () {
      final t = dhaka(DateTime(2026, 2, 19));
      expect(t.followsIfa, isFalse);
      expect(t.getSahriEnd(), t.getPrayerTimesMap()['Fajr']);
    });

    test('on: sahri, Fajr and iftar are Islamic Foundation\'s', () async {
      await IfaRamadan.setEnabled(true);
      await IfaRamadan.chooseDistrict('dhaka');
      IfaRamadan.addTableForTesting(official1447);
      // 19 February 2026 is in Ramadan 1447.
      expect(HijriDate.of(DateTime(2026, 2, 19)).hMonth, 9);

      final c = dhaka(DateTime(2026, 2, 19));
      expect(c.followsIfa, isTrue);
      final t = c.getPrayerTimesMap();
      expect(bd(c.getSahriEnd()), '05:12');
      expect(bd(t['Fajr']!), '05:15');
      expect(bd(t['Maghrib']!), '17:58');
      final ends = c.getEndTimes(c.getStartTimes());
      expect(bd(ends['Asr']!), '17:57');
      expect(bd(ends['Isha']!), '05:11'); // tomorrow's sahri
      final evening = c.getRestrictedTimes()['Sunset Period']!;
      expect(bd(evening['start'] as DateTime), '17:42');
    });

    test('on, but outside Ramadan: the sun as usual', () async {
      final before = dhaka(DateTime(2026, 10, 27)).getPrayerTimesMap();
      await IfaRamadan.setEnabled(true);
      await IfaRamadan.chooseDistrict('dhaka');
      final c = dhaka(DateTime(2026, 10, 27));
      expect(c.followsIfa, isFalse);
      expect(c.getPrayerTimesMap(), before);
    });

    test('the district follows the location unless one is chosen', () async {
      await IfaRamadan.setEnabled(true);
      await IfaRamadan.ensureLoaded(latitude: 22.3569, longitude: 91.7832);
      expect(IfaRamadan.district?.id, 'chattogram');
      await IfaRamadan.chooseDistrict('sylhet');
      expect(IfaRamadan.district?.id, 'sylhet');
      await IfaRamadan.chooseDistrict(null);
      expect(IfaRamadan.district?.id, 'chattogram');
    });
  });

  test(
    'refresh downloads the coming year\'s table once, and keeps it',
    () async {
      final year = IfaRamadan.targetYear(DateTime.now());
      final doc = {...official1447, 'hijriYear': year};
      var calls = 0;
      final client = MockClient((req) async {
        calls++;
        expect(req.url.toString(), IfaRamadan.tableUrl(year));
        return http.Response.bytes(utf8.encode(jsonEncode(doc)), 200);
      });
      expect(IfaRamadan.hasTable(year), isFalse);
      expect(await IfaRamadan.refresh(force: true, client: client), isTrue);
      expect(IfaRamadan.hasTable(year), isTrue);
      expect(await IfaRamadan.refresh(client: client), isTrue);
      expect(calls, 1);

      // Survives a restart.
      IfaRamadan.resetForTesting();
      await IfaRamadan.ensureLoaded(force: true);
      expect(IfaRamadan.hasTable(year), isTrue);
    },
  );

  test('not published yet: no table, and no second try the same day', () async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response('Not Found', 404);
    });
    expect(await IfaRamadan.refresh(force: true, client: client), isFalse);
    expect(await IfaRamadan.refresh(client: client), isFalse);
    expect(calls, 1);
  });
}
