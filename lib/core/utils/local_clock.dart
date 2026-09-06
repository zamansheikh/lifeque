import 'package:intl/intl.dart';

/// A 12-hour clock the reader can actually read.
///
/// `DateFormat('h:mm a')` is not enough on its own: under `bn` the CLDR data
/// still yields the Latin "AM"/"PM", and Bangla puts the part of the day
/// *before* the time ("সন্ধ্যা ৬:১২"), not after it. So the marker is supplied
/// here, in the words people actually use — which is also how prayer times are
/// written on any timetable in Bangladesh.
///
/// Reads `Intl.defaultLocale`, which the app sets alongside the app language,
/// so this works from notification and background code with no `BuildContext`.
class Clock {
  Clock._();

  static bool get _bangla => (Intl.defaultLocale ?? 'en').startsWith('bn');

  /// Hours and minutes alone, in the reader's digits.
  static String hm(DateTime time) => DateFormat('h:mm').format(time);

  /// The part of the day: AM/PM in English, ভোর/সকাল/… in Bangla.
  static String period(DateTime time) {
    if (!_bangla) return DateFormat('a').format(time);
    return switch (time.hour) {
      >= 4 && < 6 => 'ভোর',
      >= 6 && < 12 => 'সকাল',
      >= 12 && < 16 => 'দুপুর',
      >= 16 && < 18 => 'বিকাল',
      >= 18 && < 19 => 'সন্ধ্যা',
      _ => 'রাত',
    };
  }

  /// A full 12-hour time — "6:12 PM", or "সন্ধ্যা ৬:১২".
  static String h12(DateTime time) =>
      _bangla ? '${period(time)} ${hm(time)}' : '${hm(time)} ${period(time)}';

  /// A span of time, with the part of the day named once rather than twice.
  ///
  /// English trails the marker, so it belongs on the end ("5:41 – 5:56 AM");
  /// Bangla leads with it, so it belongs on the start ("ভোর ৫:৪১ – ৫:৫৬").
  static String range(DateTime from, DateTime to, {String separator = '–'}) =>
      _bangla
      ? '${h12(from)} $separator ${hm(to)}'
      : '${hm(from)} $separator ${h12(to)}';

  /// Same, but lower-case in English for the places that want it quiet.
  static String h12Soft(DateTime time) =>
      _bangla ? h12(time) : h12(time).toLowerCase();
}
