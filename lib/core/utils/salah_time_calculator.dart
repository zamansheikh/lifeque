import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

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

  PrayerTimes getPrayerTimes() {
    return PrayerTimes(coordinates, DateComponents.from(date), params);
  }

  // Helper method to format times for display
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  // Get prayer times with proper formatting
  Map<String, DateTime> getPrayerTimesMap() {
    final prayerTimes = getPrayerTimes();
    return {
      'Fajr': prayerTimes.fajr,
      'Sunrise': prayerTimes.sunrise,
      'Dhuhr': prayerTimes.dhuhr,
      'Asr': prayerTimes.asr,
      'Maghrib': prayerTimes.maghrib,
      'Isha': prayerTimes.isha,
    };
  }

  // Get formatted prayer times for display
  Map<String, String> getFormattedPrayerTimes() {
    final times = getPrayerTimesMap();
    return times.map((key, value) => MapEntry(key, formatTime(value)));
  }

  // Get current prayer
  Prayer? getCurrentPrayer() {
    final prayerTimes = getPrayerTimes();
    return prayerTimes.currentPrayer();
  }

  // Get next prayer
  Prayer? getNextPrayer() {
    final prayerTimes = getPrayerTimes();
    return prayerTimes.nextPrayer();
  }

  // Get time until next prayer
  Duration? getTimeUntilNextPrayer() {
    final prayerTimes = getPrayerTimes();
    final nextPrayer = prayerTimes.nextPrayer();

    final nextPrayerTime = prayerTimes.timeForPrayer(nextPrayer);
    if (nextPrayerTime == null) return null;

    return nextPrayerTime.difference(DateTime.now());
  }

  // --- Methods to get start, end, and restricted times ---

  Map<String, DateTime> getStartTimes() {
    final prayerTimes = getPrayerTimes();
    return {
      'Fajr': prayerTimes.fajr,
      'Sunrise': prayerTimes.sunrise,
      'Dhuhr': prayerTimes.dhuhr,
      'Asr': prayerTimes.asr,
      'Maghrib': prayerTimes.maghrib,
      'Isha': prayerTimes.isha,
    };
  }

  Map<String, DateTime> getEndTimes(Map<String, DateTime> startTimes) {
    // Calculate proper prayer end times based on Islamic jurisprudence
    final prayerTimes = getPrayerTimes();

    // Calculate Islamic midnight for Isha end time
    // Islamic midnight = halfway between Maghrib and next day's Fajr
    final tomorrowCalculator = SalahTimeCalculator(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      date: date.add(const Duration(days: 1)),
      method: method, // Use the stored method
      madhab: params.madhab,
    );
    final tomorrowFajr = tomorrowCalculator.getPrayerTimes().fajr;

    // Calculate Islamic midnight (midpoint between Maghrib and next Fajr)
    final maghribTime = prayerTimes.maghrib.millisecondsSinceEpoch;
    final nextFajrTime = tomorrowFajr.millisecondsSinceEpoch;
    final midnightTime =
        maghribTime + ((nextFajrTime - maghribTime) / 2).round();
    final islamicMidnight = DateTime.fromMillisecondsSinceEpoch(midnightTime);

    return {
      'Fajr': prayerTimes.sunrise, // Fajr ends at sunrise
      'Dhuhr': prayerTimes.asr, // Dhuhr ends at Asr time
      'Asr': prayerTimes.maghrib, // Asr ends at Maghrib time
      'Maghrib': prayerTimes.isha, // Maghrib ends at Isha time
      'Isha': islamicMidnight, // Isha ends at Islamic midnight
    };
  }

  // Get restricted prayer times (Makruh times) when prayer is discouraged
  // Based on Islamic Foundation Bangladesh guidelines
  Map<String, Map<String, dynamic>> getRestrictedTimes() {
    final prayerTimes = getPrayerTimes();

    return {
      // 1. Sunrise Time: From when sun begins to rise until fully risen (~15 minutes)
      'Sunrise Period': {
        'start': prayerTimes.sunrise,
        'end': prayerTimes.sunrise.add(
          const Duration(minutes: 15),
        ), // End 15 minutes after sunrise
        'reason': 'Sunrise prohibited time (~15 minutes)',
        'duration': '~15 minutes',
        'description':
            'From the moment the sun begins to rise until it has fully risen',
      },

      // 2. Midday (Zawal) Time: 6 minutes before zenith (precautionary measure)
      'Zawal (Midday)': {
        'start': prayerTimes.dhuhr.subtract(const Duration(minutes: 6)),
        'end': prayerTimes.dhuhr.add(
          const Duration(minutes: 1),
        ), // Small buffer after Dhuhr starts
        'reason': 'Zawal - Sun at zenith (6 minutes precautionary)',
        'duration': '~6 minutes',
        'description':
            'About 3 minutes before sun reaches zenith, extended to 6 minutes for precaution',
      },

      // 3. Sunset Time: From when sun begins to set until completely disappeared (~15 minutes)
      // Note: Asr can be prayed during this time if not performed earlier
      'Sunset Period': {
        'start': prayerTimes.maghrib.subtract(
          const Duration(minutes: 15),
        ), // Start 15 min before Maghrib
        'end': prayerTimes.maghrib,
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
  SunnahTimes getSunnahTimes() {
    final prayerTimes = getPrayerTimes();
    return SunnahTimes(prayerTimes);
  }

  // Get Qibla direction
  double getQiblaDirection() {
    final qibla = Qibla(coordinates);
    return qibla.direction;
  }

  // Get Islamic midnight (midpoint between Maghrib and next Fajr)
  DateTime getIslamicMidnight() {
    final prayerTimes = getPrayerTimes();

    // Calculate next day's Fajr
    final tomorrowCalculator = SalahTimeCalculator(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      date: date.add(const Duration(days: 1)),
      method: method,
      madhab: params.madhab,
    );
    final tomorrowFajr = tomorrowCalculator.getPrayerTimes().fajr;

    // Calculate Islamic midnight (midpoint between Maghrib and next Fajr)
    final maghribTime = prayerTimes.maghrib.millisecondsSinceEpoch;
    final nextFajrTime = tomorrowFajr.millisecondsSinceEpoch;
    final midnightTime =
        maghribTime + ((nextFajrTime - maghribTime) / 2).round();

    return DateTime.fromMillisecondsSinceEpoch(midnightTime);
  }

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
