import 'package:flutter/material.dart';

import '../utils/prayer_palette.dart';

/// One makruh window shown as a chip in [ProhibitedTimesCard].
class ProhibitedChip {
  /// `Morning`, `Noon`, `Evening`.
  final String label;

  /// e.g. `5:42 – 5:57 am`.
  final String range;

  /// True while now falls inside the window — inverts the chip.
  final bool isActive;

  const ProhibitedChip({
    required this.label,
    required this.range,
    required this.isActive,
  });
}

/// The three daily windows in which salat is prohibited.
class ProhibitedTimesCard extends StatelessWidget {
  final String subtitle;
  final List<ProhibitedChip> chips;
  final VoidCallback onSeeReference;

  const ProhibitedTimesCard({
    super.key,
    required this.subtitle,
    required this.chips,
    required this.onSeeReference,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PrayerPalette.cardRadius),
        boxShadow: PrayerPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Prohibited Times for Prayer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: PrayerPalette.danger,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: onSeeReference,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'See Reference',
                    style: TextStyle(
                      color: PrayerPalette.accent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: PrayerPalette.inkA(0.6),
              fontSize: 11,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _chip(chips[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(ProhibitedChip chip) {
    final bg = chip.isActive
        ? PrayerPalette.dangerChipActive
        : PrayerPalette.dangerChipBg;
    final border = chip.isActive
        ? PrayerPalette.dangerChipActive
        : PrayerPalette.danger.withValues(alpha: 0.25);
    final labelColor = chip.isActive
        ? Colors.white.withValues(alpha: 0.8)
        : PrayerPalette.dangerChipLabel;
    final rangeColor =
        chip.isActive ? Colors.white : PrayerPalette.dangerChipText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(
            chip.label,
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              chip.range,
              style: TextStyle(
                color: rangeColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
