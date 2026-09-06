import 'package:flutter/material.dart';

import '../utils/prayer_palette.dart';
import '../../../../core/utils/local_numbers.dart';
import '../../../../l10n/app_localizations.dart';

/// One adhkar entry in [AfterPrayerDuasSheet].
///
/// The Arabic and the repetition count are content and stay as written; the
/// section tag and the meaning are looked up so they follow the app language.
class _Dua {
  final String Function(L) tag;
  final String count;
  final String arabic;
  final String Function(L) meaning;

  const _Dua(this.tag, this.count, this.arabic, this.meaning);
}

/// The adhkar recited straight after the fard prayer.
class AfterPrayerDuasSheet {
  static const _duas = <_Dua>[
    _Dua(_afterSalam, '3×', 'أَسْتَغْفِرُ الله', _astaghfirullah),
    _Dua(
      _afterSalam,
      '1×',
      'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، '
          'تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      _allahummaAntas,
    ),
    _Dua(
      _tasbih,
      '33 · 33 · 34',
      'سُبْحَانَ الله · الْحَمْدُ لِلَّه · اللَّهُ أَكْبَر',
      _tasbihCounts,
    ),
    _Dua(
      _protection,
      '1×',
      'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ '
          'لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ '
          'يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ '
          'وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
      _ayatulKursi,
    ),
  ];

  static String _afterSalam(L l) => l.adhkarSectionAfterSalam;
  static String _tasbih(L l) => l.adhkarSectionTasbih;
  static String _protection(L l) => l.adhkarSectionProtection;
  static String _astaghfirullah(L l) => l.adhkarAstaghfirullah;
  static String _allahummaAntas(L l) => l.adhkarAllahummaAntas;
  static String _tasbihCounts(L l) => l.adhkarTasbihCounts;
  static String _ayatulKursi(L l) => l.adhkarAyatulKursi;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: PrayerPalette.inkA(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'After-prayer adhkar',
                style: TextStyle(
                  color: PrayerPalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (final dua in _duas) ...[
              const SizedBox(height: 10),
              _card(context, dua),
            ],
          ],
        ),
      ),
    );
  }

  /// The dua cards on their own, so the Learn section can lay them out as a
  /// page without duplicating the list.
  static List<Widget> cards(BuildContext context) => [
    for (final dua in _duas) ...[
      _card(context, dua),
      const SizedBox(height: 10),
    ],
  ];

  static Widget _card(BuildContext context, _Dua dua) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
    decoration: BoxDecoration(
      color: PrayerPalette.canvas,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: PrayerPalette.inkA(0.08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              dua.tag(L.of(context)),
              style: const TextStyle(
                color: PrayerPalette.accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              N.digits(dua.count),
              style: TextStyle(
                color: PrayerPalette.inkA(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          dua.arabic,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: PrayerPalette.arabic(fontSize: 22, height: 1.9),
        ),
        const SizedBox(height: 5),
        Text(
          dua.meaning(L.of(context)),
          style: TextStyle(
            color: PrayerPalette.inkA(0.6),
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
