import 'package:intl/intl.dart';

/// Digits in the app's current language.
///
/// Bangla uses its own numerals, and `intl` already renders them inside
/// translated messages and dates — so a screen that also prints a bare Dart
/// `'$count'` ends up mixing "৬ দিন" with "2", which reads as a bug. Every
/// user-facing number goes through here instead.
class N {
  N._();

  /// A whole number: `12` → `12` / `১২`.
  static String of(num value) => NumberFormat.decimalPattern().format(value);

  /// A percentage, already scaled 0–100: `62` → `62%` / `৬২%`.
  static String percent(num value) => '${of(value)}%';

  /// A year or other ungrouped figure: `1448` → `1448` / `১৪৪৮`.
  ///
  /// [of] groups thousands, which is right for counts and wrong for years —
  /// the Hijri year rendered as "১,৪৪৮".
  static String plain(num value) =>
      (NumberFormat.decimalPattern()..turnOffGrouping()).format(value);

  /// Localises the digits inside a string that is not itself a number —
  /// `"1.0.0"` → `"১.০.০"`, `"4+2"` → `"৪+২"`.
  ///
  /// For figures that arrive already formatted, where the separators carry
  /// meaning and must survive: version names, dose counts like `33 · 33 · 34`,
  /// rak'ah tables.
  static String digits(String text) =>
      text.replaceAllMapped(RegExp(r'\d'), (m) => plain(int.parse(m[0]!)));

  /// Two-digit clock-style padding that still localises: `7` → `07` / `০৭`.
  static String padded2(int value) => of(value).padLeft(2, of(0));
}
