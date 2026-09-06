import 'package:flutter/widgets.dart';

/// Hijri month names.
///
/// These are the full transliterated names rather than the "Rabiʿ I / Rabiʿ II"
/// shorthand — months 3/4 and 5/6 are distinct months with their own names
/// (al-Awwal / al-Thani), not numbered variants of one.
///
/// The order matches the `hijri` package's own 1-based month numbering, so
/// `month(HijriCalendar.hMonth)` always names the month the package computed.
class HijriNames {
  HijriNames._();

  static const _full = <String>[
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  /// Arabic script, for places that show the name in Arabic.
  static const _arabic = <String>[
    'مُحَرَّم',
    'صَفَر',
    'رَبِيع ٱلْأَوَّل',
    'رَبِيع ٱلْآخِر',
    'جُمَادَىٰ ٱلْأُولَىٰ',
    'جُمَادَىٰ ٱلْآخِرَة',
    'رَجَب',
    'شَعْبَان',
    'رَمَضَان',
    'شَوَّال',
    'ذُو ٱلْقَعْدَة',
    'ذُو ٱلْحِجَّة',
  ];

  /// Bangla forms, as they are written in Bangladesh — not a transliteration
  /// of the English transliteration. "Rabi' al-Thani" is রবিউস সানি here, for
  /// instance, which is the form people actually read.
  static const _bangla = <String>[
    'মুহাররম',
    'সফর',
    'রবিউল আউয়াল',
    'রবিউস সানি',
    'জমাদিউল আউয়াল',
    'জমাদিউস সানি',
    'রজব',
    'শাবান',
    'রমজান',
    'শাওয়াল',
    'জিলকদ',
    'জিলহজ',
  ];

  /// Short forms for dense table rows, where the full names don't fit.
  static const _short = <String>[
    'Muh',
    'Saf',
    'Rab I',
    'Rab II',
    'Jum I',
    'Jum II',
    'Raj',
    'Sha',
    'Ram',
    'Shw',
    'Qid',
    'Hij',
  ];

  /// Short Bangla forms. "রবি ১" would collide with রবিবার (Sunday) in a row
  /// that already carries a weekday, so these keep the distinguishing word.
  static const _shortBangla = <String>[
    'মুহা',
    'সফর',
    'রবি. আ',
    'রবি. সা',
    'জমা. আ',
    'জমা. সা',
    'রজব',
    'শাবান',
    'রমজান',
    'শাওয়াল',
    'জিলকদ',
    'জিলহজ',
  ];

  /// 1-based month number → full name.
  static String month(int m) => _full[(m - 1).clamp(0, 11)];

  /// The month name in the app's current language.
  static String monthFor(BuildContext context, int m) {
    final index = (m - 1).clamp(0, 11);
    return Localizations.localeOf(context).languageCode == 'bn'
        ? _bangla[index]
        : _full[index];
  }

  /// 1-based month number → Arabic name.
  static String arabicMonth(int m) => _arabic[(m - 1).clamp(0, 11)];

  /// 1-based month number → abbreviated name, for dense table rows.
  static String shortMonth(int m) => _short[(m - 1).clamp(0, 11)];

  /// The abbreviated name in the app's current language.
  static String shortMonthFor(BuildContext context, int m) {
    final index = (m - 1).clamp(0, 11);
    return Localizations.localeOf(context).languageCode == 'bn'
        ? _shortBangla[index]
        : _short[index];
  }
}
