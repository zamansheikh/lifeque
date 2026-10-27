import 'package:adhan/adhan.dart';
import '../../core/utils/local_clock.dart';
import 'sun_clock.dart';

/// Prayer times for one place and one day.
///
/// The times come from [SunClock] — the NOAA solar equations, with each
/// time found as the moment the sun reaches its altitude — and are rounded
/// by [SafeMinute] so no time is ever shown on the unsafe side. The method
/// still supplies the Fajr/Isha angles, the Asr shadow and any fixed
/// adjustments. The adhan package remains as the fallback for days the sun
/// never rises or sets.
class SalahTimeCalculator {
  final Coordinates coordinates;
  final DateTime date;
  final CalculationParameters params;
  final CalculationMethod method;

  SalahTimeCalculator({
    required double latitude,
    required double longitude,
    required this.date,
    required this.method,
    Madhab madhab = Madhab.hanafi, // Default to Hanafi for Bangladesh
  }) : coordinates = Coordinates(latitude, longitude),
       params = method.getParameters() {
    // Set the Madhab for Asr calculation
    params.madhab = madhab;
  }

  /// The adhan package's own table — the fallback, and only that.
  PrayerTimes getPrayerTimes() {
    return PrayerTimes(coordinates, DateComponents.from(date), params);
  }

  // Helper method to format times for display
  static String formatTime(DateTime time) {
    return Clock.h12(time);
  }

  late final SunClock _sun = SunClock(
    latitude: coordinates.latitude,
    longitude: coordinates.longitude,
    date: date,
  );

  /// Unrounded instants, local time. Zawal start/end included.
  late final Map<String, DateTime> _raw = _computeRaw();

  Map<String, DateTime> _computeRaw() {
    final sun = _sun;
    final rise = sun.sunriseMinutes, set = sun.sunsetMinutes;
    if (rise == null || set == null) return _adhanRaw();

    final night = 1440 - (set - rise);
    final portion = night / 7;
    final highLatitude = coordinates.latitude.abs() >= 55;

    double fajr;
    double isha;
    if (method == CalculationMethod.moon_sighting_committee) {
      // Its Fajr and Isha follow seasonal tables, not a fixed angle.
      final a = getPrayerTimes();
      fajr = _minutesOf(a.fajr);
      isha = _minutesOf(a.isha);
    } else {
      fajr = sun.minutesAt(-params.fajrAngle, morning: true) ?? rise - portion;
      if (highLatitude && rise - fajr > portion) fajr = rise - portion;
      if (params.ishaInterval > 0) {
        isha = set + params.ishaInterval;
      } else {
        isha =
            sun.minutesAt(-(params.ishaAngle ?? 18), morning: false) ??
            set + portion;
        if (highLatitude && isha - set > portion) isha = set + portion;
      }
    }

    final transit = sun.transitMinutes;
    var dhuhr = sun.zawalEndMinutes ?? transit;
    // Some methods add a fixed cushion after noon; never start earlier
    // than that either.
    final cushion = transit + params.methodAdjustments.dhuhr;
    if (cushion > dhuhr) dhuhr = cushion;
    final asr =
        sun.asrMinutes(params.madhab == Madhab.hanafi ? 2 : 1) ?? set - 1;
    final maghribAngle = params.maghribAngle;
    final maghrib = maghribAngle == null
        ? set
        : sun.minutesAt(-maghribAngle, morning: false) ?? set;

    final m = params.methodAdjustments, u = params.adjustments;
    DateTime at(double minutes, int a, int b) =>
        sun.at(minutes + a + b).toLocal();
    return {
      'Fajr': at(fajr, m.fajr, u.fajr),
      'Sunrise': at(rise, m.sunrise, u.sunrise),
      'Dhuhr': at(dhuhr, 0, u.dhuhr),
      'Asr': at(asr, m.asr, u.asr),
      'Maghrib': at(maghrib, m.maghrib, u.maghrib),
      'Isha': at(isha, m.isha, u.isha),
      'ZawalStart': at(sun.zawalStartMinutes ?? transit, 0, 0),
      'Sunset': at(set, 0, 0),
    };
  }

  double _minutesOf(DateTime t) =>
      t
          .toUtc()
          .difference(DateTime.utc(date.year, date.month, date.day))
          .inMicroseconds /
      60e6;

  Map<String, DateTime> _adhanRaw() {
    final a = getPrayerTimes();
    return {
      'Fajr': a.fajr,
      'Sunrise': a.sunrise,
      'Dhuhr': a.dhuhr,
      'Asr': a.asr,
      'Maghrib': a.maghrib,
      'Isha': a.isha,
      'ZawalStart': a.dhuhr.subtract(const Duration(minutes: 6)),
      'Sunset': a.maghrib,
    };
  }

  /// The day's times as shown: starts rounded up, Fajr and sunrise down.
  late final Map<String, DateTime> _times = {
    'Fajr': SafeMinute.down(_raw['Fajr']!),
    'Sunrise': SafeMinute.down(_raw['Sunrise']!),
    'Dhuhr': SafeMinute.up(_raw['Dhuhr']!),
    'Asr': SafeMinute.up(_raw['Asr']!),
    'Maghrib': SafeMinute.up(_raw['Maghrib']!),
    'Isha': SafeMinute.up(_raw['Isha']!),
  };

  // Get prayer times with proper formatting
  Map<String, DateTime> getPrayerTimesMap() => Map.of(_times);

  static const fardPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  /// The fard waqt running at [now], or null when none is.
  ///
  /// A waqt runs from its start until its end, and the ends are not the next
  /// start: Fajr ends at sunrise, so from sunrise to Dhuhr nothing is running
  /// and this returns null. Callers that only looked at start times kept
  /// reporting Fajr all morning with a countdown stuck at zero.
  ///
  /// Before Fajr the running waqt is last night's Isha, which today's table
  /// does not contain — tonight's Isha is still hours away — so it is
  /// answered directly.
  String? currentFard(DateTime now) {
    final times = getPrayerTimesMap();
    if (now.isBefore(times['Fajr']!)) return 'Isha';
    final ends = getEndTimes(getStartTimes());
    String? current;
    for (final p in fardPrayers) {
      final started = times[p]!.isBefore(now);
      final ended = !ends[p]!.isAfter(now);
      if (started && !ended) current = p;
    }
    return current;
  }

  // Get formatted prayer times for display
  Map<String, String> getFormattedPrayerTimes() {
    final times = getPrayerTimesMap();
    return times.map((key, value) => MapEntry(key, formatTime(value)));
  }

  static const _order = [
    (Prayer.fajr, 'Fajr'),
    (Prayer.sunrise, 'Sunrise'),
    (Prayer.dhuhr, 'Dhuhr'),
    (Prayer.asr, 'Asr'),
    (Prayer.maghrib, 'Maghrib'),
    (Prayer.isha, 'Isha'),
  ];

  /// The time [prayer] starts on this day.
  DateTime? timeForPrayer(Prayer prayer) {
    for (final (p, key) in _order) {
      if (p == prayer) return _times[key];
    }
    return null;
  }

  // Get current prayer
  Prayer? getCurrentPrayer([DateTime? at]) {
    final now = at ?? DateTime.now();
    var current = Prayer.none;
    for (final (p, key) in _order) {
      if (!_times[key]!.isAfter(now)) current = p;
    }
    return current;
  }

  // Get next prayer
  Prayer? getNextPrayer([DateTime? at]) {
    final now = at ?? DateTime.now();
    for (final (p, key) in _order) {
      if (_times[key]!.isAfter(now)) return p;
    }
    return Prayer.none;
  }

  // Get time until next prayer
  Duration? getTimeUntilNextPrayer() {
    final next = timeForPrayer(getNextPrayer() ?? Prayer.none);
    return next?.difference(DateTime.now());
  }

  // --- Methods to get start, end, and restricted times ---

  Map<String, DateTime> getStartTimes() => Map.of(_times);

  /// When each waqt ends. A waqt ends the second before the next one
  /// starts, so its last minute reads one before the next start —
  /// "Fajr 4:44 – 6:00, sunrise 6:01" — the way Bangladeshi timetables
  /// print it. Isha runs until the next Fajr, which is already rounded
  /// down to a minute that has fully passed.
  Map<String, DateTime> getEndTimes(Map<String, DateTime> startTimes) {
    final t = _times;
    DateTime before(DateTime next) => next.subtract(const Duration(seconds: 1));
    return {
      'Fajr': before(t['Sunrise']!),
      'Dhuhr': before(t['Asr']!),
      'Asr': before(t['Maghrib']!),
      'Maghrib': before(t['Isha']!),
      'Isha': _tomorrow._times['Fajr']!,
    };
  }

  late final SalahTimeCalculator _tomorrow = SalahTimeCalculator(
    latitude: coordinates.latitude,
    longitude: coordinates.longitude,
    date: DateTime(date.year, date.month, date.day + 1),
    method: method,
    madhab: params.madhab,
  );

  // Get restricted prayer times (Makruh times) when prayer is discouraged
  // Based on Islamic Foundation Bangladesh guidelines
  Map<String, Map<String, dynamic>> getRestrictedTimes() {
    final t = _times;
    final dhuhr = t['Dhuhr']!;
    // From the moment the sun is visibly at its peak until Dhuhr — and
    // never less than six minutes, the Islamic Foundation's precaution.
    final sixBefore = _raw['Dhuhr']!.subtract(const Duration(minutes: 6));
    final peak = _raw['ZawalStart']!;
    final zawalStart = SafeMinute.down(
      peak.isBefore(sixBefore) ? peak : sixBefore,
    );
    final sunsetStart = SafeMinute.up(
      _raw['Sunset']!.subtract(const Duration(minutes: 15)),
    );

    return {
      // 1. Sunrise Time: From when sun begins to rise until fully risen (~15 minutes)
      'Sunrise Period': {
        'start': t['Sunrise']!,
        'end': SafeMinute.up(
          _raw['Sunrise']!.add(const Duration(minutes: 15)),
        ).subtract(const Duration(seconds: 1)),
        'reason': 'Sunrise prohibited time (~15 minutes)',
        'duration': '~15 minutes',
        'description':
            'From the moment the sun begins to rise until it has fully risen',
      },

      // 2. Midday (Zawal): the sun at its height, until Dhuhr begins
      'Zawal (Midday)': {
        'start': zawalStart,
        'end': dhuhr.subtract(const Duration(seconds: 1)),
        'reason': 'Zawal - Sun at zenith (6 minutes precautionary)',
        'duration': '~6 minutes',
        'description':
            'About 3 minutes before sun reaches zenith, extended to 6 minutes for precaution',
      },

      // 3. Sunset Time: From when sun begins to set until completely disappeared (~15 minutes)
      // Note: Asr can be prayed during this time if not performed earlier
      'Sunset Period': {
        'start': sunsetStart,
        'end': t['Maghrib']!.subtract(const Duration(seconds: 1)),
        'reason': 'Sunset prohibited time (~15 minutes)',
        'duration': '~15 minutes',
        'description':
            'From when sun begins to set until completely disappeared. Note: Asr prayer may be offered if not performed earlier',
        'special_note': 'Asr prayer is allowed during this time if delayed',
      },
    };
  }

  // Check if current time is in a restricted period
  bool isCurrentTimeRestricted() {
    final now = DateTime.now();
    final restrictedTimes = getRestrictedTimes();

    for (final period in restrictedTimes.values) {
      final start = period['start'] as DateTime;
      final end = period['end'] as DateTime;

      if (now.isAfter(start) && now.isBefore(end)) {
        return true;
      }
    }

    return false;
  }

  // Get current restricted period info (if any)
  Map<String, dynamic>? getCurrentRestrictedPeriod() {
    final now = DateTime.now();
    final restrictedTimes = getRestrictedTimes();

    for (final entry in restrictedTimes.entries) {
      final period = entry.value;
      final start = period['start'] as DateTime;
      final end = period['end'] as DateTime;

      if (now.isAfter(start) && now.isBefore(end)) {
        return {
          'name': entry.key,
          'start': start,
          'end': end,
          'reason': period['reason'],
          'remaining': end.difference(now),
        };
      }
    }

    return null;
  }

  // Get Sunnah times
  NightTimes getSunnahTimes() => NightTimes(
    maghrib: _times['Maghrib']!,
    nextFajr: _tomorrow._times['Fajr']!,
  );

  // Get Qibla direction
  double getQiblaDirection() {
    final qibla = Qibla(coordinates);
    return qibla.direction;
  }

  // Get Islamic midnight (midpoint between Maghrib and next Fajr)
  DateTime getIslamicMidnight() => getSunnahTimes().middleOfTheNight;

  // Get detailed explanation about restricted times
  static String getRestrictedTimesExplanation() {
    return '''
Important Information about the Prohibited Times of Salat

According to Islamic Shari'ah, there are three times when performing Salat (prayer) is prohibited. These are determined with reference to the timing of Asr and sunrise/sunset exceptions.

(1) 🌅 Sunrise Time:
From the moment the sun begins to rise until it has fully risen.
⏳ The duration of this prohibited time is approximately 15 minutes.

(2) 🕛 Midday (Zawal) Time:
This time occurs about 3 minutes before the sun reaches its zenith (midday).
⏳ However, for greater precaution, the Islamic Foundation has set this prohibited time to 6 minutes before zenith.

(3) 🌇 Sunset Time:
From the moment the sun begins to set until it has completely disappeared below the horizon.
⏳ The duration of this prohibited time is approximately 15 minutes.

📎 Special Note:
If the Asr prayer of that day has not been performed before sunset, then only the Asr prayer may be offered during this prohibited time, because delaying beyond that would cause the Asr prayer to be completely missed.

This is why the prohibited time of sunset is shown as overlapping with the last time for Asr prayer.

However, intentionally delaying Salat until this prohibited period is never appropriate.

📖 Further Explanation:
Previously, both sunrise and sunset prohibited times were considered to last about 23 minutes.
But after modern astronomical and scientific research, experts have confirmed that these times do not exceed 15 minutes.
Therefore, in our current schedules, the previously estimated 23 minutes has now been corrected to 15 minutes for accuracy.

🧾 Summary:
  • 🌅 Sunrise: ~15 minutes
  • 🕛 Midday (Zawal): ~6 minutes (precautionary)
  • 🌇 Sunset: ~15 minutes
  
📒 Total prohibited time per day: ~36 minutes
''';
  }

  // Get total prohibited time duration per day
  static String getTotalProhibitedDuration() {
    return "~36 minutes"; // 15 + 6 + 15 = 36 minutes
  }
}

/// The night between Maghrib and the next Fajr, and its parts.
class NightTimes {
  final DateTime middleOfTheNight;
  final DateTime lastThirdOfTheNight;

  NightTimes({required DateTime maghrib, required DateTime nextFajr})
    : middleOfTheNight = SafeMinute.up(
        maghrib.add(nextFajr.difference(maghrib) ~/ 2),
      ),
      lastThirdOfTheNight = SafeMinute.up(
        maghrib.add(nextFajr.difference(maghrib) * 2 ~/ 3),
      );
}

// Example of extending the built-in enum to provide user-friendly names
extension CalculationMethodName on CalculationMethod {
  String get displayName {
    switch (this) {
      case CalculationMethod.muslim_world_league:
        return 'Muslim World League';
      case CalculationMethod.egyptian:
        return 'Egyptian General Authority';
      case CalculationMethod.karachi:
        return 'University of Islamic Sciences, Karachi';
      case CalculationMethod.umm_al_qura:
        return 'Umm al-Qura University, Makkah';
      case CalculationMethod.dubai:
        return 'Dubai';
      case CalculationMethod.moon_sighting_committee:
        return 'Moonsighting Committee';
      case CalculationMethod.north_america:
        return 'ISNA (North America)';
      case CalculationMethod.kuwait:
        return 'Kuwait';
      case CalculationMethod.qatar:
        return 'Qatar';
      case CalculationMethod.singapore:
        return 'Singapore';
      case CalculationMethod.turkey:
        return 'Turkey';
      case CalculationMethod.tehran:
        return 'Tehran';
      case CalculationMethod.other:
        return 'Custom';
    }
  }
}

extension PrayerName on Prayer {
  String get displayName {
    switch (this) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.sunrise:
        return 'Sunrise';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      case Prayer.none:
        return 'None';
    }
  }

  String get arabicName {
    switch (this) {
      case Prayer.fajr:
        return 'فجر';
      case Prayer.sunrise:
        return 'شروق';
      case Prayer.dhuhr:
        return 'ظهر';
      case Prayer.asr:
        return 'عصر';
      case Prayer.maghrib:
        return 'مغرب';
      case Prayer.isha:
        return 'عشاء';
      case Prayer.none:
        return '';
    }
  }
}
