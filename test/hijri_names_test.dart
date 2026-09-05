import 'package:flutter_test/flutter_test.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:lifeque/features/prayer_times/presentation/utils/hijri_names.dart';

/// The month names are hand-written, so pin them to the `hijri` package's own
/// numbering — an off-by-one here would silently mislabel every date shown.
void main() {
  test('our month names line up with the package for every month', () {
    // The package spells them slightly differently (Al- vs al-, Sha'aban);
    // compare on a normalised form so only a real mismatch fails.
    String norm(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z]"), '')
        .replaceAll('shaaban', 'shaban');

    for (var m = 1; m <= 12; m++) {
      final date = HijriCalendar()
        ..hYear = 1448
        ..hMonth = m
        ..hDay = 1;
      expect(
        norm(HijriNames.month(m)),
        norm(date.getLongMonthName()),
        reason: 'month $m disagrees with the hijri package',
      );
    }
  });

  test('a known date resolves to the right month name', () {
    final h = HijriCalendar.fromDate(DateTime(2026, 9, 5));
    expect(h.hMonth, 3);
    expect(HijriNames.month(h.hMonth), "Rabi' al-Awwal");
    expect(HijriNames.shortMonth(h.hMonth), 'Rab I');
    expect(HijriNames.arabicMonth(h.hMonth), 'رَبِيع ٱلْأَوَّل');
  });

  test('every accessor covers all twelve months without throwing', () {
    for (var m = 1; m <= 12; m++) {
      expect(HijriNames.month(m), isNotEmpty);
      expect(HijriNames.shortMonth(m), isNotEmpty);
      expect(HijriNames.arabicMonth(m), isNotEmpty);
    }
  });
}
