import 'dart:math' as math;

/// Where the sun is, for one place on one calendar day.
///
/// Implements the NOAA Solar Calculator equations (Meeus, "Astronomical
/// Algorithms"): solar declination and the equation of time from the
/// Julian century, apparent altitude with NOAA's refraction model, and
/// sunrise/sunset at the standard 0.833° below the horizon.
///
/// Every prayer time is then "the moment the sun reaches this altitude",
/// found by bisection on the real altitude curve rather than by the
/// hour-angle shortcut — the declination and equation of time are
/// recomputed at each instant, not frozen at noon. Times come back as
/// instants (UTC); callers show them in local time.
class SunClock {
  final double latitude;
  final double longitude;

  /// The calendar day, as it is on the wall at [latitude]/[longitude].
  final int year, month, day;

  SunClock({
    required this.latitude,
    required this.longitude,
    required DateTime date,
  }) : year = date.year,
       month = date.month,
       day = date.day;

  static const _d2r = math.pi / 180;
  static const _r2d = 180 / math.pi;

  /// Midnight UTC at the start of the calendar day. Events are measured
  /// in minutes from here: solar noon is 720 − 4·longitude minutes, which
  /// stays inside this UTC day for every longitude.
  late final DateTime _base = DateTime.utc(year, month, day);
  late final double _jd0 = _julianDay(year, month, day);

  static double _julianDay(int y, int m, int d) {
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        d +
        b -
        1524.5;
  }

  /// Declination (degrees) and equation of time (minutes) at [minutes]
  /// after the day's UTC midnight.
  ({double decl, double eot}) _sun(double minutes) {
    final t = (_jd0 + minutes / 1440 - 2451545.0) / 36525.0;
    final l0 = (280.46646 + t * (36000.76983 + 0.0003032 * t)) % 360;
    final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
    final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
    final mr = m * _d2r;
    final center =
        math.sin(mr) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
        math.sin(2 * mr) * (0.019993 - 0.000101 * t) +
        math.sin(3 * mr) * 0.000289;
    final omega = (125.04 - 1934.136 * t) * _d2r;
    final lambda = l0 + center - 0.00569 - 0.00478 * math.sin(omega);
    final meanObliquity =
        23 +
        (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60;
    final obliquity = meanObliquity + 0.00256 * math.cos(omega);
    final decl =
        math.asin(math.sin(obliquity * _d2r) * math.sin(lambda * _d2r)) * _r2d;
    final y = math.pow(math.tan(obliquity * _d2r / 2), 2).toDouble();
    final l0r = l0 * _d2r;
    final eot =
        4 *
        _r2d *
        (y * math.sin(2 * l0r) -
            2 * e * math.sin(mr) +
            4 * e * y * math.sin(mr) * math.cos(2 * l0r) -
            0.5 * y * y * math.sin(4 * l0r) -
            1.25 * e * e * math.sin(2 * mr));
    return (decl: decl, eot: eot);
  }

  /// The sun's declination around noon, for the Asr shadow rule.
  double get noonDeclination => _sun(transitMinutes).decl;

  /// Geometric altitude (no refraction) at [minutes].
  double _geometricAltitude(double minutes) {
    final s = _sun(minutes);
    final trueSolar = minutes + s.eot + 4 * longitude;
    final hourAngle = trueSolar / 4 - 180;
    final la = latitude * _d2r, de = s.decl * _d2r;
    final cosZenith =
        math.sin(la) * math.sin(de) +
        math.cos(la) * math.cos(de) * math.cos(hourAngle * _d2r);
    return 90 - math.acos(cosZenith.clamp(-1.0, 1.0)) * _r2d;
  }

  /// NOAA's atmospheric refraction, in degrees, for a geometric altitude.
  static double _refraction(double alt) {
    if (alt > 85) return 0;
    final t = math.tan(alt * _d2r);
    final double arcsec;
    if (alt > 5) {
      arcsec = 58.1 / t - 0.07 / math.pow(t, 3) + 0.000086 / math.pow(t, 5);
    } else if (alt > -0.575) {
      arcsec =
          1735 + alt * (-518.2 + alt * (103.4 + alt * (-12.79 + alt * 0.711)));
    } else {
      arcsec = -20.772 / t;
    }
    return arcsec / 3600;
  }

  /// Altitude as seen, refraction included.
  double apparentAltitude(double minutes) {
    final g = _geometricAltitude(minutes);
    return g + _refraction(g);
  }

  /// Solar noon, minutes after the UTC midnight. Refined twice: the
  /// equation of time is taken at noon itself, not at midnight.
  late final double transitMinutes = () {
    var m = 720 - 4 * longitude;
    for (var i = 0; i < 3; i++) {
      m = 720 - 4 * longitude - _sun(m).eot;
    }
    return m;
  }();

  /// The minute (from UTC midnight) the sun reaches [altitude], before
  /// noon when [morning], after it otherwise. Null when it never does that
  /// day — the sun stays above or below it.
  double? minutesAt(
    double altitude, {
    required bool morning,
    bool apparent = true,
  }) {
    double alt(double m) =>
        apparent ? apparentAltitude(m) : _geometricAltitude(m);
    final noon = transitMinutes;
    // Altitude rises from midnight to noon and falls after it, so each
    // half is monotonic and bisection finds the one crossing.
    var lo = morning ? noon - 720 : noon;
    var hi = morning ? noon : noon + 720;
    final atLo = alt(lo), atHi = alt(hi);
    final rising = morning;
    final minAlt = rising ? atLo : atHi;
    final maxAlt = rising ? atHi : atLo;
    if (altitude < minAlt || altitude > maxAlt) return null;
    for (var i = 0; i < 60; i++) {
      final mid = (lo + hi) / 2;
      final above = alt(mid) >= altitude;
      // Rising: above means the crossing is earlier. Falling: later.
      if (above == rising) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return (lo + hi) / 2;
  }

  DateTime at(double minutes) =>
      _base.add(Duration(microseconds: (minutes * 60e6).round()));

  /// Sunrise and sunset: the upper limb on the horizon, 0.833° below the
  /// geometric horizon (refraction plus the sun's radius).
  double? get sunriseMinutes =>
      minutesAt(-0.833, morning: true, apparent: false);
  double? get sunsetMinutes =>
      minutesAt(-0.833, morning: false, apparent: false);

  /// Zawal is over once the sun has dropped measurably past its highest
  /// point — 0.01° below the noon altitude. Before that the sun is still
  /// at the zenith for the eye, and salat is not yet permitted.
  static const zawalMargin = 0.01;

  double get noonAltitude => apparentAltitude(transitMinutes);

  double? get zawalStartMinutes =>
      minutesAt(noonAltitude - zawalMargin, morning: true);
  double? get zawalEndMinutes =>
      minutesAt(noonAltitude - zawalMargin, morning: false);

  /// Asr: an object's shadow equals [shadowFactor] times its length plus
  /// its noon shadow (1 for the majority, 2 for Hanafi).
  double? asrMinutes(int shadowFactor) {
    final noonShadow = (latitude - noonDeclination).abs() * _d2r;
    final altitude =
        math.atan(1 / (shadowFactor + math.tan(noonShadow))) * _r2d;
    return minutesAt(altitude, morning: false);
  }
}

/// Wall-clock rounding that never errs on the unsafe side.
///
/// A start time shown a minute early sends people to pray before the waqt;
/// a Fajr shown a minute late lets them eat after sahri has ended. So
/// starts round up, while Fajr — which is also when sahri ends — and
/// sunrise, which ends Fajr, round down.
class SafeMinute {
  SafeMinute._();

  /// The next whole minute, unless already on one.
  static DateTime up(DateTime t) {
    final s = DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
    return s.second == 0
        ? s
        : DateTime(s.year, s.month, s.day, s.hour, s.minute + 1);
  }

  /// The last whole minute strictly before [t]: 4:45:20 → 4:45, and
  /// 4:45:00 exactly → 4:44, so the minute shown has fully passed.
  static DateTime down(DateTime t) {
    final s = DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
    return s.second == 0
        ? DateTime(s.year, s.month, s.day, s.hour, s.minute - 1)
        : DateTime(s.year, s.month, s.day, s.hour, s.minute);
  }
}
