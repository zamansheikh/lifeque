import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import '../utils/local_numbers.dart';

/// Material's Bangla localization, made safe for typing.
///
/// Bangla shows numbers in Bangla digits, and Material's pickers follow: the
/// date picker's text field opens as "৭/৯/২০২৬", the time picker's hour box
/// as "১০". Phone keyboards, though, type Latin digits — so the moment
/// someone edits, the field holds a mix, and the framework's parsers reject
/// it: `intl` will only read the digits of its own locale, and the time
/// picker parses with plain `int.tryParse`. Every date and time field in
/// the app had this bug, and any new one would too.
///
/// Fixed once, here, for every picker:
///  - typed dates are normalised to Bangla digits before parsing, so any mix
///    of digit sets is accepted;
///  - the time picker's editable hour and minute read in Latin digits, the
///    same ones the keyboard produces, while the times shown elsewhere stay
///    in Bangla.
///
/// Registered ahead of `GlobalMaterialLocalizations.delegate` in the app,
/// so it wins for Bangla and nothing else changes.
class TypedDigitsMaterialLocalizationBn extends MaterialLocalizationBn {
  const TypedDigitsMaterialLocalizationBn({
    required super.fullYearFormat,
    required super.compactDateFormat,
    required super.shortDateFormat,
    required super.mediumDateFormat,
    required super.longDateFormat,
    required super.yearMonthFormat,
    required super.shortMonthDayFormat,
    required super.decimalFormat,
    required super.twoDigitZeroPaddedFormat,
  });

  /// Twelve-hour with AM/PM, whatever the phone's clock setting says.
  ///
  /// Bangla's Material default is a 24-hour dial, which nobody here reads —
  /// times are said as "রাত ১১টা", not "23:00". The dial, the typed hour and
  /// every time this localization formats follow the same rule.
  @override
  TimeOfDayFormat timeOfDayFormat({bool alwaysUse24HourFormat = false}) =>
      TimeOfDayFormat.h_colon_mm_space_a;

  @override
  DateTime? parseCompactDate(String? inputString) => super.parseCompactDate(
    inputString == null ? null : N.bangla(inputString),
  );

  @override
  String formatHour(
    TimeOfDay timeOfDay, {
    bool alwaysUse24HourFormat = false,
  }) => N.ascii(
    super.formatHour(timeOfDay, alwaysUse24HourFormat: alwaysUse24HourFormat),
  );

  @override
  String formatMinute(TimeOfDay timeOfDay) =>
      N.ascii(super.formatMinute(timeOfDay));

  /// Composed from [formatHour] and [formatMinute] upstream, which are Latin
  /// now — so put the digits back for the read-only places this feeds.
  @override
  String formatTimeOfDay(
    TimeOfDay timeOfDay, {
    bool alwaysUse24HourFormat = false,
  }) => N.bangla(
    super.formatTimeOfDay(
      timeOfDay,
      alwaysUse24HourFormat: alwaysUse24HourFormat,
    ),
  );

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _Delegate();
}

class _Delegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _Delegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'bn';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // Let the stock delegate load the date symbols first; then build the
    // same formats it would, for the same locale.
    await GlobalMaterialLocalizations.delegate.load(locale);
    const name = 'bn';
    return TypedDigitsMaterialLocalizationBn(
      fullYearFormat: intl.DateFormat.y(name),
      compactDateFormat: intl.DateFormat.yMd(name),
      shortDateFormat: intl.DateFormat.yMMMd(name),
      mediumDateFormat: intl.DateFormat.MMMEd(name),
      longDateFormat: intl.DateFormat.yMMMMEEEEd(name),
      yearMonthFormat: intl.DateFormat.yMMMM(name),
      shortMonthDayFormat: intl.DateFormat.MMMd(name),
      decimalFormat: intl.NumberFormat.decimalPattern(name),
      twoDigitZeroPaddedFormat: intl.NumberFormat('00', name),
    );
  }

  @override
  bool shouldReload(_Delegate old) => false;
}
