import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/hijri_date.dart';
import '../../core/utils/sun_clock.dart';
import 'ifa_district.dart';

/// Sahri end, Fajr azan and iftar for one day of Ramadan.
class IfaDay {
  final DateTime sahri;
  final DateTime fajr;
  final DateTime iftar;

  /// From Islamic Foundation's published table, rather than worked out by
  /// its rule.
  final bool official;

  const IfaDay({
    required this.sahri,
    required this.fajr,
    required this.iftar,
    required this.official,
  });
}

/// Islamic Foundation Bangladesh's Ramadan calendar, district by district.
///
/// Off unless the user turns it on, and then used only during Ramadan —
/// the rest of the year the times come from the sun as usual. For each
/// Ramadan the published table is used when the app has it (the developer
/// converts IFB's PDFs into `ifa/<year>.json` in the app's repository, and
/// [refresh] downloads it). Until then the times are worked out by IFB's own
/// published rule, at the district edge points fitted to its tables.
class IfaRamadan {
  IfaRamadan._();

  static const prefsEnabled = 'ifa_ramadan_enabled';
  static const prefsDistrict = 'ifa_ramadan_district';
  static const prefsTables = 'ifa_ramadan_tables_v1';
  static const prefsLastCheck = 'ifa_ramadan_last_check';

  /// Where the yearly tables are published.
  static String tableUrl(int hijriYear) =>
      'https://raw.githubusercontent.com/zamansheikh/lifeque/main/ifa/$hijriYear.json';

  static bool enabled = false;

  /// The district picked by hand; null means "where I am".
  static String? chosenDistrictId;

  /// The district the saved location falls in.
  static String? autoDistrictId;

  /// hijri year → district id → date ("2027-02-09") → [sahri, fajr, iftar].
  static final Map<int, Map<String, Map<String, List<String>>>> _tables = {};
  static bool _loaded = false;

  static IfaDistrict? get district =>
      IfaDistrict.byId(chosenDistrictId ?? autoDistrictId);

  static bool hasTable(int hijriYear) => _tables.containsKey(hijriYear);

  static Future<void> ensureLoaded({
    double? latitude,
    double? longitude,
    bool force = false,
  }) async {
    if (latitude != null && longitude != null) {
      autoDistrictId = IfaDistrict.at(latitude, longitude)?.id;
    }
    if (_loaded && !force) return;
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(prefsEnabled) ?? false;
    chosenDistrictId = prefs.getString(prefsDistrict);
    _tables.clear();
    final raw = prefs.getString(prefsTables);
    if (raw != null) {
      try {
        final stored = jsonDecode(raw) as Map<String, dynamic>;
        for (final doc in stored.values) {
          _addTable(doc as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('🌙 Stored IFA tables unreadable: $e');
      }
    }
    _loaded = true;
  }

  static Future<void> setEnabled(bool value) async {
    enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsEnabled, value);
  }

  /// Null goes back to following the saved location.
  static Future<void> chooseDistrict(String? id) async {
    chosenDistrictId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(prefsDistrict);
    } else {
      await prefs.setString(prefsDistrict, id);
    }
  }

  /// Reads one `ifa/<year>.json` document into memory.
  static void _addTable(Map<String, dynamic> doc) {
    final year = doc['hijriYear'] as int;
    final districts = doc['districts'] as Map<String, dynamic>;
    _tables[year] = {
      for (final e in districts.entries)
        e.key: {
          for (final row in e.value as List)
            (row as List)[0] as String: [
              row[1] as String,
              row[2] as String,
              row[3] as String,
            ],
        },
    };
  }

  /// Adds a published table. Validated before it replaces anything.
  @visibleForTesting
  static void addTableForTesting(Map<String, dynamic> doc) => _addTable(doc);

  @visibleForTesting
  static void resetForTesting() {
    enabled = false;
    chosenDistrictId = null;
    autoDistrictId = null;
    _tables.clear();
    _loaded = true;
  }

  /// The Ramadan that is running, or the next one.
  static int targetYear(DateTime now) {
    final h = HijriDate.of(now);
    return h.hMonth <= 9 ? h.hYear : h.hYear + 1;
  }

  /// Fetches the published table for the coming (or running) Ramadan, if
  /// the app does not have it yet. Answers whether it has it afterwards.
  /// Checks at most once a day unless [force]d.
  static Future<bool> refresh({bool force = false, http.Client? client}) async {
    await ensureLoaded();
    final year = targetYear(DateTime.now());
    if (hasTable(year)) return true;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(prefsLastCheck) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - last < const Duration(days: 1).inMilliseconds) {
      return false;
    }
    await prefs.setInt(prefsLastCheck, now);
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse(tableUrl(year)))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return false;
      final doc =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (doc['hijriYear'] != year) return false;
      final districts = doc['districts'] as Map<String, dynamic>;
      if (districts.length < 60) return false;
      _addTable(doc);
      final stored = <String, dynamic>{};
      final raw = prefs.getString(prefsTables);
      if (raw != null) {
        try {
          stored.addAll(jsonDecode(raw) as Map<String, dynamic>);
        } catch (_) {}
      }
      // Keep this year's and last year's; older ones are of no use.
      stored.removeWhere((k, _) => (int.tryParse(k) ?? 0) < year - 1);
      stored['$year'] = doc;
      await prefs.setString(prefsTables, jsonEncode(stored));
      return true;
    } catch (e) {
      debugPrint('🌙 Could not fetch the IFA table for $year: $e');
      return false;
    } finally {
      if (client == null) c.close();
    }
  }

  /// Whether the IFA times replace the computed ones on [date].
  static bool appliesTo(DateTime date) =>
      enabled && district != null && HijriDate.of(date).hMonth == 9;

  /// The day's IFA times, or null when the option does not apply.
  static IfaDay? dayFor(DateTime date) {
    if (!appliesTo(date)) return null;
    return timesFor(district!, date);
  }

  /// [d]'s times on [date]: from the published table when there is one,
  /// otherwise by IFB's rule.
  static IfaDay timesFor(IfaDistrict d, DateTime date) {
    final key =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    for (final table in _tables.values) {
      final row = table[d.id]?[key];
      if (row != null) {
        DateTime at(String hhmm) {
          final p = hhmm.split(':');
          // The table is on Bangladesh time; shown in the phone's own zone.
          return DateTime.utc(
            date.year,
            date.month,
            date.day,
            int.parse(p[0]) - 6,
            int.parse(p[1]),
          ).toLocal();
        }

        return IfaDay(
          sahri: at(row[0]),
          fajr: at(row[1]),
          iftar: at(row[2]),
          official: true,
        );
      }
    }
    return computed(d, date);
  }

  /// IFB's rule: sahri at subh sadiq on the eastern edge with the seconds
  /// dropped; Fajr azan at subh sadiq and iftar at sunset on the western
  /// edge, rounded up to the minute — any part of a second counts.
  static IfaDay computed(IfaDistrict d, DateTime date) {
    SunClock at((double, double) p) =>
        SunClock(latitude: p.$1, longitude: p.$2, date: date);
    DateTime when(SunClock sun, double? minutes) =>
        sun.at(minutes ?? sun.transitMinutes).toLocal();
    DateTime minuteOf(DateTime t) =>
        DateTime(t.year, t.month, t.day, t.hour, t.minute);
    DateTime up(DateTime t) {
      final m = minuteOf(t);
      return t.isAfter(m) ? m.add(const Duration(minutes: 1)) : m;
    }

    final s = at(d.sahri), f = at(d.fajr), i = at(d.iftar);
    return IfaDay(
      sahri: minuteOf(when(s, s.minutesAt(-18, morning: true))),
      fajr: up(when(f, f.minutesAt(-18, morning: true))),
      iftar: up(when(i, i.sunsetMinutes)),
      official: false,
    );
  }
}
