import 'package:flutter/material.dart';

/// Variant 1 of the home-screen widget set: the current waqt, its window and
/// countdown, the prohibited-time state, and a sun/fast times grid.
///
/// Rendered to a PNG by `HomeWidgetService` and shown by
/// `PrayerTimesWidgetProvider`, so it must paint correctly with no ambient
/// theme — every colour and text style is set explicitly.
class PrayerWidgetUI extends StatelessWidget {
  /// e.g. `23 Rabiʿ I 1448, Saturday`.
  final String hijriLine;

  /// e.g. `5 September · ২১ ভাদ্র ১৪৩৩`.
  final String secondaryDateLine;

  /// Wall-clock time this render happened, e.g. `4:31 PM`.
  final String updatedAt;

  /// Prayer the widget is about — the current waqt, or the next one.
  final String prayerName;

  /// e.g. `4:26 PM – 6:13 PM`.
  final String windowRange;

  /// e.g. `Ends: 6:13 PM · in 01:41:54`.
  final String endsLine;

  /// e.g. `Maghrib 6:13 PM`.
  final String nextChip;

  /// e.g. `⛔ AVOID NOW · 8m left` or `next avoid · Sunset 5:58 pm`.
  final String avoidText;

  /// True while a prohibited window is running — turns the chip red.
  final bool avoidActive;

  final String sunrise;
  final String sunset;
  final String sahri;
  final String iftar;

  /// Exact render size. home_widget lays the widget out inside a Column, which
  /// passes an unbounded height — so the box has to be sized explicitly or the
  /// PNG comes out letterboxed and the host's fitXY then distorts it.
  final Size size;

  const PrayerWidgetUI({
    super.key,
    required this.size,
    required this.hijriLine,
    required this.secondaryDateLine,
    required this.updatedAt,
    required this.prayerName,
    required this.windowRange,
    required this.endsLine,
    required this.nextChip,
    required this.avoidText,
    required this.avoidActive,
    required this.sunrise,
    required this.sunset,
    required this.sahri,
    required this.iftar,
  });

  static const _gold = Color(0xFFF5D27A);
  static const _alertLight = Color(0xFFFCA5A5);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E7A50),
              Color(0xFF146C43),
              Color(0xFF0E4A30),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 52,
              child: Opacity(
                opacity: 0.28,
                child: CustomPaint(painter: _SkylinePainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _left()),
                        const SizedBox(width: 8),
                        _right(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(Icons.mosque, size: 12, color: _gold),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hijriLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                secondaryDateLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  // Rendered outside the app's theme, so the Bengali fallback
                  // has to be named here.
                  fontFamilyFallback: const ['NotoSerifBengali'],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Updated: $updatedAt',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        // The refresh control is a real tappable View in the host layout,
        // anchored top-end. Leave its footprint clear rather than drawing a
        // second one here — two icons appeared, and the live one covered
        // the "Updated" text.
        const SizedBox(width: 30),
      ],
    );
  }

  Widget _left() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          prayerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          windowRange,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, size: 10, color: _gold),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                endsLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: avoidActive
                ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                : const Color(0xFF062316).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: avoidActive
                  ? _alertLight
                  : _alertLight.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.remove_circle_outline,
                size: 9,
                color: _alertLight,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  avoidText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: avoidActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.85),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _right() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF062316).withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _gold.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow_rounded, size: 10, color: _gold),
              const SizedBox(width: 5),
              Text(
                nextChip,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _statLine('Sunrise:', sunrise, Colors.white),
        _statLine('Sunset:', sunset, Colors.white),
        _statLine('Sahri:', sahri, _gold),
        _statLine('Iftar:', iftar, _gold),
      ],
    );
  }

  Widget _statLine(String label, String value, Color valueColor) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
}

/// The mosque-and-minaret skyline along the widget's bottom edge, scaled from
/// the design's 360×52 viewBox.
class _SkylinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 360.0;
    final sy = size.height / 52.0;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    final path = Path()..moveTo(0, 52 * sy);
    void line(double x, double y) {
      final o = p(x, y);
      path.lineTo(o.dx, o.dy);
    }

    void dome(double cx, double cy, double x, double y) {
      final c = p(cx, cy);
      final e = p(x, y);
      path.quadraticBezierTo(c.dx, c.dy, e.dx, e.dy);
    }

    line(0, 34);
    line(26, 34);
    line(26, 22);
    line(34, 22);
    line(34, 34);
    line(60, 34);
    dome(64, 10, 88, 8);
    dome(112, 10, 116, 34);
    line(150, 34);
    line(150, 26);
    line(158, 26);
    line(158, 34);
    line(196, 34);
    dome(202, 16, 224, 14);
    dome(246, 16, 252, 34);
    line(282, 34);
    line(282, 20);
    line(290, 12);
    line(298, 20);
    line(298, 34);
    line(336, 34);
    line(336, 26);
    line(344, 26);
    line(344, 52);
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF062316).withValues(alpha: 0.52),
    );
  }

  @override
  bool shouldRepaint(_SkylinePainter oldDelegate) => false;
}
