/// Bengali (Bangla) calendar conversion, following the 2019 Bangladesh
/// Government revision used by the Bangla Academy.
///
/// In that revision the month lengths are fixed rather than astronomical:
/// the year always opens on 14 April (Pohela Boishakh), the first five months
/// have 31 days, the next six have 30, and Falgun takes a 31st day in years
/// whose following February is a Gregorian leap February. That makes the
/// mapping a pure day-count, no ephemeris needed.
class BanglaDate {
  final int day;
  final int month; // 1 = Boishakh
  final int year;

  const BanglaDate({
    required this.day,
    required this.month,
    required this.year,
  });

  static const _monthNames = <String>[
    'বৈশাখ',
    'জ্যৈষ্ঠ',
    'আষাঢ়',
    'শ্রাবণ',
    'ভাদ্র',
    'আশ্বিন',
    'কার্তিক',
    'অগ্রহায়ণ',
    'পৌষ',
    'মাঘ',
    'ফাল্গুন',
    'চৈত্র',
  ];

  /// Indexed by `DateTime.weekday - 1`, so Monday first.
  static const _weekdayNames = <String>[
    'সোমবার',
    'মঙ্গলবার',
    'বুধবার',
    'বৃহস্পতিবার',
    'শুক্রবার',
    'শনিবার',
    'রবিবার',
  ];

  static bool _isGregorianLeap(int y) =>
      (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

  /// Month lengths for the Bengali year that began in April [startYear].
  /// Falgun (index 10) gains a day when the February it contains is a leap
  /// February — that February falls in `startYear + 1`.
  static List<int> _monthLengths(int startYear) => <int>[
        31, 31, 31, 31, 31, // Boishakh … Bhadro
        30, 30, 30, 30, 30, // Ashwin … Magh
        _isGregorianLeap(startYear + 1) ? 31 : 30, // Falgun
        30, // Choitro
      ];

  /// Convert a Gregorian [date] to its Bengali equivalent.
  factory BanglaDate.fromDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);

    // The Bengali year in progress started on 14 April of either this
    // Gregorian year or the previous one.
    var startYear = d.year;
    var start = DateTime(startYear, 4, 14);
    if (d.isBefore(start)) {
      startYear -= 1;
      start = DateTime(startYear, 4, 14);
    }

    final lengths = _monthLengths(startYear);
    var remaining = d.difference(start).inDays; // 0 == Boishakh 1

    var monthIndex = 0;
    while (monthIndex < lengths.length && remaining >= lengths[monthIndex]) {
      remaining -= lengths[monthIndex];
      monthIndex += 1;
    }

    // Guard against a rounding edge at the very end of Choitro.
    if (monthIndex >= lengths.length) {
      monthIndex = lengths.length - 1;
      remaining = lengths[monthIndex] - 1;
    }

    return BanglaDate(
      day: remaining + 1,
      month: monthIndex + 1,
      year: startYear - 593,
    );
  }

  String get monthName => _monthNames[month - 1];

  /// Bengali weekday name for the Gregorian [date] this was built from.
  static String weekdayName(DateTime date) =>
      _weekdayNames[date.weekday - 1];

  /// Render [n] with Bengali digits (০–৯).
  static String digits(Object n) => n.toString().replaceAllMapped(
        RegExp(r'\d'),
        (m) => '০১২৩৪৫৬৭৮৯'[int.parse(m[0]!)],
      );

  /// e.g. `২১ ভাদ্র ১৪৩৩`
  String get formatted => '${digits(day)} $monthName ${digits(year)}';
}
