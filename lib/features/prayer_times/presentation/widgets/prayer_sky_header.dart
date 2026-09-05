import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/prayer_palette.dart';

/// Dawn-gradient header: location, a cycling date line, the semicircular waqt
/// gauge and a hill silhouette along the bottom edge.
class PrayerSkyHeader extends StatefulWidget {
  final String locationName;

  /// The date in each calendar — Hijri, Gregorian, Bangla. Shown as a
  /// swipeable carousel that also advances on its own.
  final List<String> dateLines;

  /// Prayer the gauge is describing, e.g. `Dhuhr`.
  final String gaugeName;

  /// e.g. `Waqt ends in` or `Starts in`.
  final String gaugeLabel;

  /// Countdown as `HH:MM:SS`.
  final String gaugeCountdown;

  /// How much of the window has elapsed, 0..1.
  final double progress;

  final VoidCallback onLocationTap;
  final VoidCallback onMenu;

  const PrayerSkyHeader({
    super.key,
    required this.locationName,
    required this.dateLines,
    required this.gaugeName,
    required this.gaugeLabel,
    required this.gaugeCountdown,
    required this.progress,
    required this.onLocationTap,
    required this.onMenu,
  });

  @override
  State<PrayerSkyHeader> createState() => _PrayerSkyHeaderState();
}

class _PrayerSkyHeaderState extends State<PrayerSkyHeader> {
  late final PageController _dates = PageController();
  Timer? _advance;
  int _page = 0;

  /// Left inset that lines the date strip up with the location text: the
  /// menu button plus the gap beside it.
  static const _contentInset = 42.0;

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _advance?.cancel();
    _dates.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    _advance?.cancel();
    _advance = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_dates.hasClients) return;
      _dates.animateToPage(
        (_page + 1) % widget.dateLines.length,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            PrayerPalette.skyTop,
            PrayerPalette.skyMid,
            PrayerPalette.skyBottom,
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            // The gradient runs edge-to-edge behind the status bar; inset the
            // content so it clears the clock and notification icons.
            padding: EdgeInsets.fromLTRB(
              20,
              12 + MediaQuery.of(context).padding.top,
              20,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _locationRow(),
                const SizedBox(height: 3),
                _dateCarousel(),
                const SizedBox(height: 8),
                Center(child: _gauge()),
              ],
            ),
          ),
          SizedBox(
            height: 30,
            child: CustomPaint(painter: _HillsPainter(), size: Size.infinite),
          ),
        ],
      ),
    );
  }

  /// Swipeable Hijri / Gregorian / Bangla strip. Auto-advances, and a manual
  /// swipe restarts the timer so it doesn't slide out from under a read.
  Widget _dateCarousel() {
    return Padding(
      padding: const EdgeInsets.only(left: _contentInset),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 18,
              child: PageView.builder(
                controller: _dates,
                itemCount: widget.dateLines.length,
                onPageChanged: (i) {
                  setState(() => _page = i);
                  _startAutoAdvance();
                },
                itemBuilder: (context, i) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.dateLines[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: PrayerPalette.inkA(0.65),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          for (var i = 0; i < widget.dateLines.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(left: 3),
              width: i == _page ? 12 : 5,
              height: 5,
              decoration: BoxDecoration(
                color: PrayerPalette.inkA(i == _page ? 0.55 : 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _locationRow() {
    return Row(
      children: [
        // Explicit drawer affordance — the bismillah is decorative, not a
        // control, so it can't be the only way into the menu.
        InkWell(
          onTap: widget.onMenu,
          customBorder: const CircleBorder(),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.55),
            ),
            child: const Icon(
              Icons.menu_rounded,
              size: 19,
              color: PrayerPalette.ink,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: widget.onLocationTap,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place, size: 16, color: PrayerPalette.ink),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    widget.locationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PrayerPalette.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: PrayerPalette.ink,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // U+FDFD, the single bismillah ligature. Amiri draws it as a wide
        // calligraphic form — far wider than the system fallback — so it gets
        // a fixed slot and scales into it rather than pushing the row over.
        SizedBox(
          width: 142,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              '\uFDFD',
              textDirection: TextDirection.rtl,
              style: PrayerPalette.arabic(
                fontSize: 52,
                color: PrayerPalette.inkA(0.8),
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gauge() {
    return SizedBox(
      width: 230,
      height: 126,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GaugePainter(progress: widget.progress),
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.gaugeName,
                  style: const TextStyle(
                    color: PrayerPalette.ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.gaugeLabel,
                  style: TextStyle(
                    color: PrayerPalette.inkA(0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.gaugeCountdown,
                  style: const TextStyle(
                    color: PrayerPalette.ink,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Semicircular track + progress arc. Mirrors the design's
/// `M25,116 A90,90 0 0 1 205,116` at stroke-width 10.
class _GaugePainter extends CustomPainter {
  final double progress;

  const _GaugePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 90.0;
    final center = Offset(size.width / 2, 116);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = PrayerPalette.inkA(0.15)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = PrayerPalette.ink
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Left horizon (180°) sweeping over the top to the right horizon.
    canvas.drawArc(rect, math.pi, math.pi, false, track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * progress.clamp(0.0, 1.0),
        false,
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress;
}

/// Rolling hill silhouette across the bottom of the header, scaled from the
/// design's 380×30 viewBox.
class _HillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 380.0;
    final sy = size.height / 30.0;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 20 * sy);
    void curve(double cx, double cy, double x, double y) {
      final c = p(cx, cy);
      final e = p(x, y);
      path.quadraticBezierTo(c.dx, c.dy, e.dx, e.dy);
    }

    curve(45, 5, 95, 18);
    curve(140, 29, 200, 14);
    curve(260, 2, 320, 16);
    curve(350, 23, 380, 18);
    path
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = PrayerPalette.inkA(0.14));
  }

  @override
  bool shouldRepaint(_HillsPainter oldDelegate) => false;
}
