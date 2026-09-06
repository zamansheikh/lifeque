import 'package:flutter/material.dart';

import '../utils/prayer_palette.dart';

/// One prayer's worth of data for [SalatTimesCard].
class SalatRow {
  final String name;

  /// Waqt start, formatted e.g. `11:54 am`.
  final String time;

  /// Waqt end, formatted the same way. Knowing a prayer starts at 11:54 is
  /// only half the question — how long you have left to pray it is the other
  /// half, and the card was only ever answering the first.
  final String? endTime;

  /// Jamaat time, formatted e.g. `1:30 pm`. Null hides the chip's time.
  final String? jamaat;

  final bool isCurrent;
  final bool isPrayed;
  final bool alarmOn;

  const SalatRow({
    required this.name,
    required this.time,
    required this.endTime,
    required this.jamaat,
    required this.isCurrent,
    required this.isPrayed,
    required this.alarmOn,
  });
}

/// White card listing the five fard prayers: completion toggle, name with a
/// NOW badge, editable jamaat chip, waqt time and an alarm toggle.
class SalatTimesCard extends StatelessWidget {
  final List<SalatRow> rows;

  /// e.g. `3/5 prayed today · 🔥 12-day streak`.
  final String summary;

  final bool canMarkPrayed;

  final VoidCallback onSetAlarm;
  final void Function(String prayer) onTogglePrayed;
  final void Function(String prayer) onToggleAlarm;
  final void Function(String prayer) onEditJamaat;

  const SalatTimesCard({
    super.key,
    required this.rows,
    required this.summary,
    required this.canMarkPrayed,
    required this.onSetAlarm,
    required this.onTogglePrayed,
    required this.onToggleAlarm,
    required this.onEditJamaat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: PrayerPalette.heroShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Salat Times',
                style: TextStyle(
                  color: PrayerPalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onSetAlarm,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Set Alarm',
                    style: TextStyle(
                      color: PrayerPalette.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final row in rows) _row(row),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Text(
              summary,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: PrayerPalette.inkA(0.55),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(SalatRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: row.isCurrent ? PrayerPalette.accentA(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border(bottom: BorderSide(color: PrayerPalette.inkA(0.05))),
      ),
      child: Row(
        children: [
          _checkbox(row),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: PrayerPalette.ink,
                          fontSize: 14.5,
                          fontWeight: row.isCurrent
                              ? FontWeight.w800
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (row.isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PrayerPalette.ink,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Text(
                          'NOW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Align(alignment: Alignment.centerLeft, child: _jamaatChip(row)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                row.time,
                style: const TextStyle(
                  color: PrayerPalette.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              if (row.endTime != null) ...[
                const SizedBox(height: 1),
                Text(
                  'till ${row.endTime}',
                  style: TextStyle(
                    color: PrayerPalette.inkA(0.5),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(width: 10),
          _bell(row),
        ],
      ),
    );
  }

  Widget _checkbox(SalatRow row) {
    return InkWell(
      onTap: canMarkPrayed ? () => onTogglePrayed(row.name) : null,
      customBorder: const CircleBorder(),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: row.isPrayed ? PrayerPalette.accent : Colors.transparent,
          border: Border.all(
            color: row.isPrayed
                ? PrayerPalette.accent
                : PrayerPalette.inkA(0.25),
            width: 2,
          ),
        ),
        child: row.isPrayed
            ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _jamaatChip(SalatRow row) {
    return InkWell(
      onTap: () => onEditJamaat(row.name),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: PrayerPalette.accentA(0.10),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mosque, size: 10, color: PrayerPalette.accent),
            const SizedBox(width: 4),
            Text(
              row.jamaat == null ? 'Set jamaat ✎' : 'Jamaat ${row.jamaat} ✎',
              style: const TextStyle(
                color: PrayerPalette.accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bell(SalatRow row) {
    return InkWell(
      onTap: () => onToggleAlarm(row.name),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: row.alarmOn
              ? PrayerPalette.accentA(0.10)
              : PrayerPalette.inkA(0.05),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          row.alarmOn
              ? Icons.notifications_outlined
              : Icons.notifications_off_outlined,
          size: 16,
          color: row.alarmOn ? PrayerPalette.accent : PrayerPalette.inkA(0.35),
        ),
      ),
    );
  }
}
