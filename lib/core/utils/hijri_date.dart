import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Hijri date as it is kept where the user lives.
///
/// The `hijri` package follows the Umm al-Qura calendar, which is set by
/// calculation for Saudi Arabia. A month elsewhere starts when the new
/// moon is sighted there — in Bangladesh usually a day later — so the date
/// people actually use is often one behind. [offset] shifts every Hijri
/// date in the app by whole days; the user can set it to match their
/// moon-sighting committee.
class HijriDate {
  HijriDate._();

  static const prefsKey = 'hijri_day_offset';
  static const minOffset = -2, maxOffset = 2;

  /// Days added to the Umm al-Qura date. Read once from settings.
  static int offset = 0;
  static bool _loaded = false;

  /// Bangladesh's committee is usually a day behind Umm al-Qura.
  static int defaultFor(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return 0;
    final inBangladesh =
        latitude >= 20.5 &&
        latitude <= 26.7 &&
        longitude >= 88.0 &&
        longitude <= 92.7;
    return inBangladesh ? -1 : 0;
  }

  /// Reads the saved offset; when none is saved, the default for the
  /// place prayer times are worked out for. Safe to call repeatedly, and
  /// from background isolates that start with nothing loaded.
  static Future<void> ensureLoaded({
    double? latitude,
    double? longitude,
    bool force = false,
  }) async {
    if (_loaded && !force) return;
    final prefs = await SharedPreferences.getInstance();
    offset = prefs.getInt(prefsKey) ?? defaultFor(latitude, longitude);
    _loaded = true;
  }

  static Future<void> save(int value) async {
    offset = value.clamp(minOffset, maxOffset);
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefsKey, offset);
  }

  /// The Hijri date of the Gregorian day [date].
  static HijriCalendar of(DateTime date) => HijriCalendar.fromDate(
    DateTime(date.year, date.month, date.day + offset),
  );

  /// The Gregorian day on which Hijri [day]/[month]/[year] falls.
  static DateTime toGregorian(int year, int month, int day) {
    final g = HijriCalendar().hijriToGregorian(year, month, day);
    return DateTime(g.year, g.month, g.day - offset);
  }
}
