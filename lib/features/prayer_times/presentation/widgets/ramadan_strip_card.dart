import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

import '../utils/prayer_palette.dart';

/// Dark green Ramadan strip: sahri cutoff, iftar and a live countdown.
class RamadanStripCard extends StatelessWidget {
  /// e.g. `RAMADAN · DAY 14`, or just `RAMADAN` outside the month.
  final String heading;

  /// Sahri end, formatted without the meridiem, e.g. `4:28`.
  final String sahriTime;
  final String sahriMeridiem;

  final String iftarTime;
  final String iftarMeridiem;

  /// `HH:MM:SS` until iftar.
  final String untilIftar;

  const RamadanStripCard({
    super.key,
    required this.heading,
    required this.sahriTime,
    required this.sahriMeridiem,
    required this.iftarTime,
    required this.iftarMeridiem,
    required this.untilIftar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PrayerPalette.ramadanFrom, PrayerPalette.ramadanTo],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: PrayerPalette.ink.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // U+262A renders as a colour emoji on Android even with a text
              // variation selector, so use a vector icon for the gold mark.
              const Icon(
                Icons.nightlight_round,
                size: 14,
                color: PrayerPalette.gold,
              ),
              const SizedBox(width: 7),
              Text(
                heading,
                style: const TextStyle(
                  color: PrayerPalette.gold,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 10,
                  child: _stat(
                    value: sahriTime,
                    label: '${L.of(context).ramadanSahriEnds} · $sahriMeridiem',
                    valueColor: Colors.white,
                  ),
                ),
                _divider(),
                Expanded(
                  flex: 10,
                  child: _stat(
                    value: iftarTime,
                    label: '${L.of(context).ramadanIftar} · $iftarMeridiem',
                    valueColor: Colors.white,
                  ),
                ),
                _divider(),
                Expanded(
                  flex: 13,
                  child: _stat(
                    value: untilIftar,
                    label: 'Until Iftar',
                    valueColor: PrayerPalette.gold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Colors.white.withValues(alpha: 0.18),
  );

  Widget _stat({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: valueColor,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
