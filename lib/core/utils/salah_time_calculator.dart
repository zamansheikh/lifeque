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
    // End of Isha is the next day's Fajr.
    // We need to calculate it for the next day.
    final tomorrowCalculator = SalahTimeCalculator(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
      date: date.add(const Duration(days: 1)),
      method: method, // Use the stored method
      madhab: params.madhab,
    );
    final tomorrowFajr = tomorrowCalculator.getPrayerTimes().fajr;

    return {
      'Fajr': startTimes['Sunrise']!,
      'Dhuhr': startTimes['Asr']!,
      'Asr': startTimes['Maghrib']!,
      'Maghrib': startTimes['Isha']!,
      'Isha': tomorrowFajr,
    };
  }

  Map<String, Map<String, DateTime>> getRestrictedTimes(
    Map<String, DateTime> startTimes,
  ) {
    return {
      'Sunrise': {
        'start': startTimes['Sunrise']!,
        'end': startTimes['Sunrise']!.add(const Duration(minutes: 15)),
      },
      'Zawal': {
        'start': startTimes['Dhuhr']!.subtract(const Duration(minutes: 5)),
        'end': startTimes['Dhuhr']!,
      },
      'Sunset': {
        'start': startTimes['Maghrib']!.subtract(const Duration(minutes: 15)),
        'end': startTimes['Maghrib']!,
      },
    };
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
