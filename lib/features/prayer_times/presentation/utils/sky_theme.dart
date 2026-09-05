import 'package:flutter/material.dart';

import 'islamic_colors.dart';

/// Visual palette for the "Dynamic Sky" prayer-times design.
///
/// Each prayer (and the night gap) has its own gradient drawn from Islamic
/// colour traditions — emerald greens, antique golds, deep midnight blues,
/// teals — rather than generic sky colours. The hero gradient on the prayer
/// page morphs between these as the day progresses.
class SkyTheme {
  final List<Color> gradient;
  final Color accent;
  final Color onAccent;
  final IconData icon;
  final String label;

  const SkyTheme({
    required this.gradient,
    required this.accent,
    required this.onAccent,
    required this.icon,
    required this.label,
  });

  /// Pre-dawn — deep midnight with a hint of teal.
  static const SkyTheme preDawn = SkyTheme(
    gradient: [
      IslamicColors.midnightDeep,
      IslamicColors.midnight,
      IslamicColors.tealDeep,
    ],
    accent: IslamicColors.goldLight,
    onAccent: IslamicColors.midnight,
    icon: Icons.nights_stay_rounded,
    label: 'Late Night',
  );

  /// Fajr — midnight-teal lifting into a soft gold dawn.
  static const SkyTheme fajr = SkyTheme(
    gradient: [
      Color(0xFF1A2547),
      IslamicColors.tealDeep,
      IslamicColors.goldDeep,
    ],
    accent: IslamicColors.goldLight,
    onAccent: Color(0xFF1A2547),
    icon: Icons.brightness_4_rounded,
    label: 'Fajr',
  );

  /// Sunrise — warm cream and antique gold.
  static const SkyTheme sunrise = SkyTheme(
    gradient: [
      IslamicColors.goldDeep,
      IslamicColors.gold,
      IslamicColors.goldLight,
    ],
    accent: IslamicColors.emerald,
    onAccent: Colors.white,
    icon: Icons.wb_sunny_rounded,
    label: 'Morning',
  );

  /// Dhuhr — emerald-tinted blue, midday sky over an oasis.
  static const SkyTheme dhuhr = SkyTheme(
    gradient: [IslamicColors.teal, IslamicColors.tealLight, Color(0xFF7FBDB3)],
    accent: IslamicColors.gold,
    onAccent: Colors.white,
    icon: Icons.wb_sunny_rounded,
    label: 'Dhuhr',
  );

  /// Asr — warm afternoon gold over emerald.
  static const SkyTheme asr = SkyTheme(
    gradient: [
      IslamicColors.emeraldMid,
      IslamicColors.goldDeep,
      IslamicColors.goldLight,
    ],
    accent: IslamicColors.cream,
    onAccent: IslamicColors.emerald,
    icon: Icons.wb_twilight_rounded,
    label: 'Asr',
  );

  /// Maghrib — burgundy sunset bleeding into emerald twilight.
  static const SkyTheme maghrib = SkyTheme(
    gradient: [
      IslamicColors.burgundy,
      IslamicColors.sunset,
      IslamicColors.emeraldMid,
    ],
    accent: IslamicColors.goldGlow,
    onAccent: Colors.white,
    icon: Icons.brightness_3_rounded,
    label: 'Maghrib',
  );

  /// Isha — deep emerald-midnight, the dome of a night mosque.
  static const SkyTheme isha = SkyTheme(
    gradient: [
      IslamicColors.midnight,
      IslamicColors.tealDeep,
      IslamicColors.emerald,
    ],
    accent: IslamicColors.goldLight,
    onAccent: IslamicColors.midnight,
    icon: Icons.brightness_2_rounded,
    label: 'Isha',
  );

  /// Pick the appropriate sky for [now] using the prayer-time map provided.
  /// Falls back to whichever window contains [now] given the prayer times.
  static SkyTheme forNow({
    required DateTime now,
    required Map<String, DateTime> times,
  }) {
    DateTime? at(String key) => times[key];

    final fajrT = at('Fajr');
    final sunriseT = at('Sunrise');
    final dhuhrT = at('Dhuhr');
    final asrT = at('Asr');
    final maghribT = at('Maghrib');
    final ishaT = at('Isha');

    if (fajrT != null && now.isBefore(fajrT)) return preDawn;
    if (sunriseT != null && now.isBefore(sunriseT)) return fajr;
    if (dhuhrT != null && now.isBefore(dhuhrT)) return sunrise;
    if (asrT != null && now.isBefore(asrT)) return dhuhr;
    if (maghribT != null && now.isBefore(maghribT)) return asr;
    if (ishaT != null && now.isBefore(ishaT)) return maghrib;
    return isha;
  }

  /// Sky theme for a specific named prayer card.
  static SkyTheme forPrayer(String prayer) {
    switch (prayer) {
      case 'Fajr':
        return fajr;
      case 'Sunrise':
        return sunrise;
      case 'Dhuhr':
        return dhuhr;
      case 'Asr':
        return asr;
      case 'Maghrib':
        return maghrib;
      case 'Isha':
        return isha;
      default:
        return dhuhr;
    }
  }
}
