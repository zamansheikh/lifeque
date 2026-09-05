/// Hijri month names, transliterated the way the design writes them
/// (`Rabiʿ I`, `Dhul Qaʿdah`) rather than the `hijri` package's own spellings.
class HijriNames {
  HijriNames._();

  static const _full = <String>[
    'Muharram',
    'Safar',
    'Rabiʿ I',
    'Rabiʿ II',
    'Jumada I',
    'Jumada II',
    'Rajab',
    'Shaʿban',
    'Ramadan',
    'Shawwal',
    'Dhul Qaʿdah',
    'Dhul Hijjah',
  ];

  static const _short = <String>[
    'Muh',
    'Saf',
    'Rb I',
    'Rb II',
    'Jm I',
    'Jm II',
    'Raj',
    'Shb',
    'Ram',
    'Shw',
    'DhQ',
    'DhH',
  ];

  /// 1-based month number → full name.
  static String month(int m) => _full[(m - 1).clamp(0, 11)];

  /// 1-based month number → abbreviated name, for dense table rows.
  static String shortMonth(int m) => _short[(m - 1).clamp(0, 11)];
}
