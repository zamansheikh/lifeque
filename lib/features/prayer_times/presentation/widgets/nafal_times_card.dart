import 'package:flutter/material.dart';

import '../utils/prayer_palette.dart';

/// One optional-prayer window in [NafalTimesCard].
class NafalRow {
  /// Small green mark. Material icons rather than the design's `☀ ◑ ☁ ☾`
  /// characters, which Android renders as inconsistent colour emoji.
  final IconData glyph;
  final String name;

  /// e.g. `5:57 – 11:39 am`.
  final String range;

  const NafalRow({
    required this.glyph,
    required this.name,
    required this.range,
  });
}

/// Nafal (optional) prayer windows — Ishraq/Duha, Zawal, Awabin, Tahajjud.
class NafalTimesCard extends StatelessWidget {
  final List<NafalRow> rows;

  /// e.g. `Last ⅓ of night begins: 1:01 am`.
  final String footnote;

  final VoidCallback onSeeReference;

  const NafalTimesCard({
    super.key,
    required this.rows,
    required this.footnote,
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
                  'Nafal Prayer Time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: PrayerPalette.ink,
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
          for (final row in rows) _row(row),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: PrayerPalette.accent,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  footnote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: PrayerPalette.inkA(0.6),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(NafalRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: PrayerPalette.inkA(0.06))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Icon(row.glyph, size: 15, color: PrayerPalette.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              row.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PrayerPalette.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            row.range,
            style: TextStyle(
              color: PrayerPalette.inkA(0.8),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
