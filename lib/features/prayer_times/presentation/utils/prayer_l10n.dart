import 'package:flutter/widgets.dart';

import '../../../../l10n/app_localizations.dart';

/// Display names for prayers and makruh windows.
///
/// The English names double as map keys and as the ids passed back through
/// callbacks (`onTogglePrayed('Fajr')`), and they are what the alarm service
/// and the stored completions use — so they stay English in the data and get
/// translated only on the way to the screen.
String prayerLabel(BuildContext context, String key) {
  final l = L.of(context);
  return switch (key) {
    'Fajr' => l.prayerFajr,
    'Dhuhr' => l.prayerDhuhr,
    'Asr' => l.prayerAsr,
    'Maghrib' => l.prayerMaghrib,
    'Isha' => l.prayerIsha,
    'Tahajjud' => l.prayerTahajjud,
    'Sunrise' => l.prayerSunrise,
    _ => key,
  };
}

/// Plain-language name for one of the three restricted windows.
String restrictedWindowLabel(BuildContext context, String key) {
  final l = L.of(context);
  return switch (key) {
    'Sunrise Period' => l.prohibitedSunrise,
    'Zawal (Midday)' => l.prohibitedZawal,
    'Sunset Period' => l.prohibitedSunset,
    _ => key,
  };
}

/// The short chip label for a restricted window: Morning / Noon / Evening.
String restrictedChipLabel(BuildContext context, String key) {
  final l = L.of(context);
  return switch (key) {
    'Sunrise Period' => l.prohibitedMorning,
    'Zawal (Midday)' => l.prohibitedNoon,
    'Sunset Period' => l.prohibitedEvening,
    _ => key,
  };
}
