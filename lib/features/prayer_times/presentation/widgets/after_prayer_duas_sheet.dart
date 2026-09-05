import 'package:flutter/material.dart';

import '../utils/prayer_palette.dart';

/// One adhkar entry in [AfterPrayerDuasSheet].
class _Dua {
  final String tag;
  final String count;
  final String arabic;
  final String english;

  const _Dua(this.tag, this.count, this.arabic, this.english);
}

/// The adhkar recited straight after the fard prayer.
class AfterPrayerDuasSheet {
  static const _duas = <_Dua>[
    _Dua(
      'AFTER SALAM',
      '3×',
      'أَسْتَغْفِرُ الله',
      'Astaghfirullah — I seek the forgiveness of Allah.',
    ),
    _Dua(
      'AFTER SALAM',
      '1×',
      'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، '
          'تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
      'O Allah, You are Peace and from You is peace. Blessed are You, '
          'O Owner of Majesty and Honor.',
    ),
    _Dua(
      'TASBIH',
      '33 · 33 · 34',
      'سُبْحَانَ الله · الْحَمْدُ لِلَّه · اللَّهُ أَكْبَر',
      'SubhanAllah 33× · Alhamdulillah 33× · Allahu Akbar 34×',
    ),
    _Dua(
      'PROTECTION',
      '1×',
      'آيَةُ الْكُرْسِيّ',
      'Recite Ayat al-Kursi (2:255) after each prayer.',
    ),
  ];

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
              _card(dua),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _card(_Dua dua) => Container(
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
                  dua.tag,
                  style: const TextStyle(
                    color: PrayerPalette.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  dua.count,
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
              style: const TextStyle(
                color: PrayerPalette.ink,
                fontSize: 19,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              dua.english,
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
