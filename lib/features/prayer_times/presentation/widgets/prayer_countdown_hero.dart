import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/sky_theme.dart';

/// The visual centerpiece: a giant live countdown above a curved day-arc.
///
/// The arc spans from the day's first prayer (Fajr) to the next day's Fajr,
/// with the five prayers as dots positioned by their actual times and a
/// glowing "now" marker that slides along the arc.
///
/// Tapping a prayer dot fires [onPrayerTapped] so the focus card below can
/// re-target it.
class PrayerCountdownHero extends StatelessWidget {
  /// Ordered Fajr → Isha (sunrise NOT included).
  final List<String> prayerNames;
  final Map<String, DateTime> times;
  final DateTime arcStart;
  final DateTime arcEnd;
  final DateTime now;
  final String focusedPrayer;
  final DateTime focusedPrayerTime;
  final String? prevPrayerName;
  final String? currentPrayer;
  final bool isToday;
  final ValueChanged<String> onPrayerTapped;

  /// Restricted (makruh) periods to overlay as red bands on the arc. Each
  /// map needs `start` and `end` DateTimes. Pass an empty list to hide them.
  final List<Map<String, DateTime>> restrictedPeriods;

  const PrayerCountdownHero({
    super.key,
    required this.prayerNames,
    required this.times,
    required this.arcStart,
    required this.arcEnd,
    required this.now,
    required this.focusedPrayer,
    required this.focusedPrayerTime,
    required this.prevPrayerName,
    required this.currentPrayer,
    required this.isToday,
    required this.onPrayerTapped,
    this.restrictedPeriods = const [],
  });

  @override
  Widget build(BuildContext context) {
    final remaining = focusedPrayerTime.difference(now);
    // "Passed mode": user tapped a prayer whose time on this date is in the
    // past. We show how long ago instead of counting down to tomorrow.
    final isPast = isToday && focusedPrayerTime.isBefore(now);
    final showLive = isToday && !isPast && !remaining.isNegative;
    final countdown = isPast
        ? _fmtPassed(now.difference(focusedPrayerTime))
        : showLive
        ? _fmt(remaining)
        : DateFormat('h:mm a').format(focusedPrayerTime);
    final sky = SkyTheme.forPrayer(focusedPrayer);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Soft "next up" pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sky.icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                isToday
                    ? (isPast
                          ? 'PASSED · $focusedPrayer'
                          : remaining.isNegative
                          ? 'NOW · $focusedPrayer'
                          : 'NEXT · $focusedPrayer')
                    : 'AT · $focusedPrayer',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Giant countdown
        Text(
          countdown,
          style: TextStyle(
            color: Colors.white,
            fontSize: 56,
            fontWeight: FontWeight.w200,
            height: 1.0,
            letterSpacing: -2,
            fontFeatures: const [FontFeature.tabularFigures()],
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isPast
              ? 'was at ${DateFormat('h:mm a').format(focusedPrayerTime)}'
              : showLive
              ? 'until ${DateFormat('h:mm a').format(focusedPrayerTime)}'
              : DateFormat('EEE, MMM d').format(focusedPrayerTime),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 28),

        // Unified visualization — one Stack so the leader-line painter can
        // actually reach BOTH the dots up top AND the labels at the bottom.
        _ArcWithLabels(
          prayerNames: prayerNames,
          times: times,
          arcStart: arcStart,
          arcEnd: arcEnd,
          now: now,
          focusedPrayer: focusedPrayer,
          currentPrayer: currentPrayer,
          isToday: isToday,
          onPrayerTapped: onPrayerTapped,
          restrictedPeriods: restrictedPeriods,
        ),
      ],
    );
  }

  static String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // Human-friendly relative time for the "passed" state. Big visual hit
  // ("3h 24m") rather than a seconds-precise tick, since precision doesn't
  // matter once a prayer is over.
  static String _fmtPassed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m ago';
    if (m > 0) return '${m}m ago';
    return 'just now';
  }
}

// Layout constants used by both painters and the label row. Kept here so
// the math stays in sync — if you bump one, the others move with it.
const double _kSideInset = 24.0;
const double _kArcHeight = 60.0;
const double _kGap = 8.0;
const double _kLabelHeight = 50.0;
const double _kTotalHeight = _kArcHeight + _kGap + _kLabelHeight;

// Bezier control points for the day-arc (in arc-band local coords).
// Start/end y == 38, control y == 4 → curve peaks near the top of the band.
const double _kArcY = 38.0;
const double _kArcPeakY = 4.0;

/// Solve y on the arc's quadratic bezier at a given x. Because both
/// endpoints share the same y and the control point sits at the horizontal
/// midpoint, x(t) is linear in t — so we can just plug in t = fraction.
double _arcYAt(double frac) {
  final t = frac.clamp(0.0, 1.0);
  final omt = 1 - t;
  return omt * omt * _kArcY + 2 * omt * t * _kArcPeakY + t * t * _kArcY;
}

/// One self-contained widget that owns the arc, the dots, the leader
/// lines, and the labels. Sharing one coordinate system is what lets the
/// leader lines actually CONNECT from each dot to its label cell.
class _ArcWithLabels extends StatelessWidget {
  final List<String> prayerNames;
  final Map<String, DateTime> times;
  final DateTime arcStart;
  final DateTime arcEnd;
  final DateTime now;
  final String focusedPrayer;
  final String? currentPrayer;
  final bool isToday;
  final ValueChanged<String> onPrayerTapped;
  final List<Map<String, DateTime>> restrictedPeriods;

  const _ArcWithLabels({
    required this.prayerNames,
    required this.times,
    required this.arcStart,
    required this.arcEnd,
    required this.now,
    required this.focusedPrayer,
    required this.currentPrayer,
    required this.isToday,
    required this.onPrayerTapped,
    required this.restrictedPeriods,
  });

  double _frac(DateTime t) {
    final total = arcEnd.difference(arcStart).inSeconds;
    if (total <= 0) return 0;
    final part = t.difference(arcStart).inSeconds.clamp(0, total);
    return part / total;
  }

  @override
  Widget build(BuildContext context) {
    final visible = prayerNames.where((p) => times[p] != null).toList();

    return SizedBox(
      height: _kTotalHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final usable = w - _kSideInset * 2;
          double dotX(DateTime t) => _kSideInset + _frac(t) * usable;
          final cellWidth = w / visible.length;
          double labelX(int i) => cellWidth * i + cellWidth / 2;
          final nowFrac = isToday ? _frac(now) : -1.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1) The curved arc + progress fill (top band only).
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: _kArcHeight,
                child: CustomPaint(
                  painter: _ArcPainter(
                    progress: nowFrac.clamp(0.0, 1.0),
                    showProgress: isToday && nowFrac >= 0 && nowFrac <= 1,
                    restrictedRanges: [
                      for (final p in restrictedPeriods)
                        if (p['start'] != null && p['end'] != null)
                          [_frac(p['start']!), _frac(p['end']!)],
                    ],
                  ),
                ),
              ),

              // 2) Leader lines — painter spans the FULL height so it can
              //    actually draw from each dot down to its label cell.
              //    Each dot's y now follows the arc curve so the line and
              //    the dot meet exactly.
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ConnectorsPainter(
                      dotPositions: [
                        for (final n in visible)
                          Offset(dotX(times[n]!), _arcYAt(_frac(times[n]!))),
                      ],
                      labelPositions: [
                        for (int i = 0; i < visible.length; i++)
                          Offset(labelX(i), _kArcHeight + _kGap + 2),
                      ],
                      focusedIndex: visible.indexOf(focusedPrayer),
                    ),
                  ),
                ),
              ),

              // 3) Dots — each placed on the actual arc curve so they
              //    visually sit on the line instead of floating below it.
              //    The currently-running waqt's dot gets a warm pulsing
              //    glow so the live prayer is unmistakable.
              for (final n in visible)
                _PositionedDot(
                  centerX: dotX(times[n]!),
                  centerY: _arcYAt(_frac(times[n]!)),
                  isFocused: n == focusedPrayer,
                  isCurrent: isToday && n == currentPrayer,
                  isPast: isToday && times[n]!.isBefore(now),
                ),

              // No now-marker pin — the progress-bar fill on the curve
              // already communicates "where we are in the day", and the
              // running-prayer dot below is highlighted for the active waqt.

              // 5) Label row — evenly spaced, never collides, tap targets.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _kLabelHeight,
                child: Row(
                  children: [
                    for (int i = 0; i < visible.length; i++)
                      Expanded(
                        child: _LabelCell(
                          name: visible[i],
                          time: times[visible[i]]!,
                          isFocused: visible[i] == focusedPrayer,
                          isPast: isToday && times[visible[i]]!.isBefore(now),
                          onTap: () => onPrayerTapped(visible[i]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A dot on the arc representing one of the five daily prayers.
///
/// Visual states (highest priority wins when more than one applies):
///   • **isCurrent** — the running waqt, gold pulsing halo
///   • **isFocused** — user-tapped or auto-next, big white bordered dot
///   • **isPast** — finished prayer earlier today, faded
///   • default — upcoming prayer, normal white
class _PositionedDot extends StatefulWidget {
  final double centerX;
  final double centerY;
  final bool isFocused;
  final bool isCurrent;
  final bool isPast;

  const _PositionedDot({
    required this.centerX,
    required this.centerY,
    required this.isFocused,
    required this.isCurrent,
    required this.isPast,
  });

  @override
  State<_PositionedDot> createState() => _PositionedDotState();
}

class _PositionedDotState extends State<_PositionedDot>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.isCurrent) _startPulse();
  }

  @override
  void didUpdateWidget(_PositionedDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && _pulse == null) {
      _startPulse();
    } else if (!widget.isCurrent && _pulse != null) {
      _pulse!.dispose();
      _pulse = null;
    }
  }

  void _startPulse() {
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // isCurrent beats isFocused — the running waqt is the most important
    // piece of information; user-focus is secondary.
    if (widget.isCurrent) return _buildCurrent();
    if (widget.isFocused) return _buildFocused();
    return _buildPlain();
  }

  Widget _buildCurrent() {
    const dotSize = 16.0;
    const gold = Color(0xFFFFD54F);
    return Positioned(
      left: widget.centerX - dotSize / 2,
      top: widget.centerY - dotSize / 2,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _pulse!,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_pulse!.value);
            final glow = 10.0 + 10.0 * t;
            return Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: gold,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: gold.withValues(alpha: 0.7),
                    blurRadius: glow,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.4),
                    blurRadius: glow * 1.4,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFocused() {
    const dotSize = 16.0;
    return Positioned(
      left: widget.centerX - dotSize / 2,
      top: widget.centerY - dotSize / 2,
      child: IgnorePointer(
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlain() {
    const dotSize = 10.0;
    final color = widget.isPast
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.85);
    return Positioned(
      left: widget.centerX - dotSize / 2,
      top: widget.centerY - dotSize / 2,
      child: IgnorePointer(
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _LabelCell extends StatelessWidget {
  final String name;
  final DateTime time;
  final bool isFocused;
  final bool isPast;
  final VoidCallback onTap;

  const _LabelCell({
    required this.name,
    required this.time,
    required this.isFocused,
    required this.isPast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isFocused
        ? Colors.white
        : isPast
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.85);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                name.substring(0, math.min(3, name.length)),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: isFocused ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              // 12-hour clock with a tiny am/pm marker so Fajr 4:48 isn't
              // confused with afternoon 4:48 at a glance.
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    DateFormat('h:mm').format(time),
                    style: TextStyle(
                      color: color.withValues(alpha: 0.95),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    DateFormat('a').format(time).toLowerCase(),
                    style: TextStyle(
                      color: color.withValues(alpha: 0.65),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Connector lines from each dot to its label cell. Because this painter
/// shares the [_ArcWithLabels] coordinate system, the start and end points
/// are *actual* widget positions — they connect cleanly.
class _ConnectorsPainter extends CustomPainter {
  final List<Offset> dotPositions;
  final List<Offset> labelPositions;
  final int focusedIndex;

  _ConnectorsPainter({
    required this.dotPositions,
    required this.labelPositions,
    required this.focusedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final focusedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < dotPositions.length; i++) {
      final from = dotPositions[i];
      final to = labelPositions[i];
      // Vertical midpoint for the S-curve control points.
      final midY = (from.dy + to.dy) / 2;

      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx, midY, to.dx, midY, to.dx, to.dy);
      canvas.drawPath(path, i == focusedIndex ? focusedPaint : basePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorsPainter old) =>
      old.focusedIndex != focusedIndex ||
      old.dotPositions.length != dotPositions.length ||
      !_listEquals(old.dotPositions, dotPositions) ||
      !_listEquals(old.labelPositions, labelPositions);

  static bool _listEquals(List<Offset> a, List<Offset> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _ArcPainter extends CustomPainter {
  final double progress; // 0..1
  final bool showProgress;
  // Each inner list is [startFrac, endFrac] (0..1) describing a makruh
  // window to overlay on the arc in red.
  final List<List<double>> restrictedRanges;

  _ArcPainter({
    required this.progress,
    required this.showProgress,
    this.restrictedRanges = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Curve endpoints + control point must match the constants used by
    // _arcYAt so the on-curve dots line up with what the user sees.
    final start = Offset(_kSideInset, _kArcY);
    final end = Offset(size.width - _kSideInset, _kArcY);
    final mid = Offset(size.width / 2, _kArcPeakY);

    Offset pointAt(double t) {
      final omt = 1 - t;
      final x = omt * omt * start.dx + 2 * omt * t * mid.dx + t * t * end.dx;
      final y = omt * omt * start.dy + 2 * omt * t * mid.dy + t * t * end.dy;
      return Offset(x, y);
    }

    Path arcBetween(double t0, double t1) {
      const subdivisions = 24;
      final path = Path();
      final first = pointAt(t0);
      path.moveTo(first.dx, first.dy);
      for (int i = 1; i <= subdivisions; i++) {
        final tt = t0 + (t1 - t0) * (i / subdivisions);
        final p = pointAt(tt);
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }

    // FUTURE portion — subtle, thin, faded.
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final bgPath = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
    canvas.drawPath(bgPath, bg);

    // PAST portion — render as a glowing progress bar in three passes.
    if (showProgress) {
      final fgPath = arcBetween(0, progress);

      final glow = Paint()
        ..color = const Color(0xFFFFE082).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(fgPath, glow);

      final main = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(fgPath, main);

      final highlight = Paint()
        ..color = Colors.white.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(fgPath, highlight);
    }

    // RESTRICTED bands — drawn on TOP so they're always visible. Bright
    // crimson with a soft glow so the eye picks them up even against the
    // white progress fill.
    if (restrictedRanges.isNotEmpty) {
      final bandGlow = Paint()
        ..color = const Color(0xFFEF4444).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final bandStroke = Paint()
        ..color = const Color(0xFFFCA5A5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      for (final range in restrictedRanges) {
        if (range.length != 2) continue;
        final a = range[0].clamp(0.0, 1.0);
        final b = range[1].clamp(0.0, 1.0);
        if (b <= a) continue;
        final path = arcBetween(a, b);
        canvas.drawPath(path, bandGlow);
        canvas.drawPath(path, bandStroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.progress != progress ||
      old.showProgress != showProgress ||
      old.restrictedRanges.length != restrictedRanges.length;
}
