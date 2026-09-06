import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../utils/prayer_palette.dart';
import '../../../../core/utils/local_numbers.dart';

/// Today's salat progress, the current streak and the last seven days — the
/// line that used to be a single grey sentence at the foot of the salat card,
/// where it read as a caption rather than something you could open.
///
/// The whole card is the tap target; it opens the stats page.
class PrayerProgressCard extends StatelessWidget {
  /// Fard prayers logged for the day being shown.
  final int prayed;

  /// Always 5 today, but kept explicit so the ring never hard-codes it.
  final int total;

  /// Consecutive days with all five logged. Only meaningful for today.
  final int streak;

  /// Seven daily counts, oldest first, last entry = today. Empty hides the
  /// strip (the page hasn't loaded it yet).
  final List<int> week;

  /// False when browsing another date — the streak line and "today" wording
  /// would both be wrong.
  final bool isToday;

  final VoidCallback onTap;

  const PrayerProgressCard({
    super.key,
    required this.prayed,
    required this.total,
    required this.streak,
    required this.week,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(PrayerPalette.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PrayerPalette.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(PrayerPalette.cardRadius),
            boxShadow: PrayerPalette.cardShadow,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _ring(context),
                  const SizedBox(width: 14),
                  Expanded(child: _headline(context)),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: PrayerPalette.inkA(0.35),
                  ),
                ],
              ),
              if (week.length == 7) ...[
                const SizedBox(height: 14),
                _weekStrip(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _ring(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: _RingPainter(total == 0 ? 0 : prayed / total),
        child: Center(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: N.of(prayed),
                  style: const TextStyle(
                    color: PrayerPalette.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: '/${N.of(total)}',
                  style: TextStyle(
                    color: PrayerPalette.inkA(0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headline(BuildContext context) {
    final l = L.of(context);
    final complete = prayed >= total;
    final title = isToday
        ? (complete ? l.progressAllFive : l.progressLoggedToday)
        : l.progressLogged;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: PrayerPalette.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            if (isToday) _streakChip(context),
            if (isToday) const SizedBox(width: 8),
            Flexible(
              child: Text(
                l.progressViewStats,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PrayerPalette.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _streakChip(BuildContext context) {
    final live = streak > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: live ? const Color(0xFFFBF1DD) : PrayerPalette.inkA(0.05),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 12,
            color: live ? const Color(0xFFD9822B) : PrayerPalette.inkA(0.3),
          ),
          const SizedBox(width: 3),
          Text(
            live
                ? L.of(context).progressStreak(streak)
                : L.of(context).progressNoStreak,
            style: TextStyle(
              color: live ? const Color(0xFF8A5418) : PrayerPalette.inkA(0.45),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Seven columns: a filled bar per day, heaviest when all five were logged.
  Widget _weekStrip(BuildContext context) {
    final today = DateTime.now();
    final l = L.of(context);
    final letters = [
      l.dowMon,
      l.dowTue,
      l.dowWed,
      l.dowThu,
      l.dowFri,
      l.dowSat,
      l.dowSun,
    ];

    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _weekDay(
              count: week[i],
              letter:
                  letters[today.subtract(Duration(days: 6 - i)).weekday - 1],
              isToday: i == 6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _weekDay({
    required int count,
    required String letter,
    required bool isToday,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 26,
          decoration: BoxDecoration(
            color: PrayerPalette.heat0,
            borderRadius: BorderRadius.circular(7),
            border: isToday
                ? Border.all(color: PrayerPalette.accentA(0.45), width: 1.5)
                : null,
          ),
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: count == 0 ? 0 : (count / 5).clamp(0.22, 1.0),
            child: Container(
              decoration: BoxDecoration(
                // Not PrayerPalette.heatFor — its lightest step is the same
                // colour as this bar's own track, so a 1- or 2-prayer day
                // would paint itself invisible.
                color: _fillFor(count),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          letter,
          style: TextStyle(
            color: isToday ? PrayerPalette.accent : PrayerPalette.inkA(0.4),
            fontSize: 10,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Bar colour deepens with the day's count so a glance reads density, not
/// just presence.
Color _fillFor(int count) => switch (count) {
  >= 5 => PrayerPalette.accent,
  4 => PrayerPalette.accentA(0.75),
  3 => PrayerPalette.accentA(0.6),
  _ => PrayerPalette.accentA(0.45),
};

/// Thin progress ring: a full faint track with the completed share drawn over
/// it, starting at 12 o'clock.
class _RingPainter extends CustomPainter {
  final double progress;

  const _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = PrayerPalette.heat0;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = PrayerPalette.accent;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
