part 'ifa_districts.g.dart';

/// One of Bangladesh's 64 districts, as Islamic Foundation Bangladesh times
/// its Ramadan calendar.
///
/// IFB gives each district one timetable that is safe from edge to edge:
/// sahri ends at subh sadiq on the district's eastern edge, and the Fajr
/// azan and iftar follow its western edge. [sahri], [fajr] and [iftar] are
/// the points that reproduce IFB's published tables.
class IfaDistrict {
  final String id;
  final String en;
  final String bn;
  final String division;

  /// (latitude, longitude) the event is timed at.
  final (double, double) sahri;
  final (double, double) fajr;
  final (double, double) iftar;

  /// Simplified boundary rings, as flat lat, lon pairs.
  final List<List<double>> outline;

  const IfaDistrict({
    required this.id,
    required this.en,
    required this.bn,
    required this.division,
    required this.sahri,
    required this.fajr,
    required this.iftar,
    required this.outline,
  });

  /// Whether ([lat], [lon]) falls inside the district (even-odd rule).
  bool contains(double lat, double lon) {
    var inside = false;
    for (final ring in outline) {
      final n = ring.length ~/ 2;
      for (var i = 0, j = n - 1; i < n; j = i++) {
        final yi = ring[2 * i], xi = ring[2 * i + 1];
        final yj = ring[2 * j], xj = ring[2 * j + 1];
        if ((yi > lat) != (yj > lat) &&
            lon < (xj - xi) * (lat - yi) / (yj - yi) + xi) {
          inside = !inside;
        }
      }
    }
    return inside;
  }

  /// Squared distance (degrees) from ([lat], [lon]) to the nearest outline
  /// vertex — good enough to pick a district for a point just off the
  /// simplified coast or border.
  double _distance2(double lat, double lon) {
    var best = double.infinity;
    for (final ring in outline) {
      for (var i = 0; i < ring.length; i += 2) {
        final dy = ring[i] - lat, dx = ring[i + 1] - lon;
        final d = dy * dy + dx * dx;
        if (d < best) best = d;
      }
    }
    return best;
  }

  static IfaDistrict? byId(String? id) {
    if (id == null) return null;
    for (final d in ifaDistricts) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// The district a GPS fix is in; the nearest one when the fix lies just
  /// outside every simplified outline (a river mouth, a char), and null
  /// when it is not in Bangladesh at all.
  static IfaDistrict? at(double lat, double lon) {
    for (final d in ifaDistricts) {
      if (d.contains(lat, lon)) return d;
    }
    IfaDistrict? nearest;
    var best = double.infinity;
    for (final d in ifaDistricts) {
      final dist = d._distance2(lat, lon);
      if (dist < best) {
        best = dist;
        nearest = d;
      }
    }
    // About 15 km: beyond that it is another country.
    return best <= 0.15 * 0.15 ? nearest : null;
  }

  static const divisions = <String, String>{
    'dhaka': 'ঢাকা',
    'chattogram': 'চট্টগ্রাম',
    'rajshahi': 'রাজশাহী',
    'khulna': 'খুলনা',
    'barishal': 'বরিশাল',
    'sylhet': 'সিলেট',
    'rangpur': 'রংপুর',
    'mymensingh': 'ময়মনসিংহ',
  };
}
