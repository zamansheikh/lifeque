import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/prayer_palette.dart';

/// Dawn-gradient header: location, a cycling date line, the semicircular waqt
/// gauge and a hill silhouette along the bottom edge.
class PrayerSkyHeader extends StatelessWidget {
  final String locationName;

  /// The date line, already formatted. Cycles between Hijri / Gregorian /
  /// Bangla upstream; this widget only fades it.
  final String dateLine;

  /// Drives the cross-fade between date formats.
  final double dateOpacity;

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
    required this.dateLine,
    required this.dateOpacity,
    required this.gaugeName,
    required this.gaugeLabel,
    required this.gaugeCountdown,
    required this.progress,
    required this.onLocationTap,
    required this.onMenu,
  });

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
                Padding(
                  padding: const EdgeInsets.only(left: 22, top: 3),
                  child: AnimatedOpacity(
                    opacity: dateOpacity,
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      dateLine,
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
                const SizedBox(height: 8),
                Center(child: _gauge()),
              ],
            ),
          ),
          SizedBox(
            height: 30,
            child: CustomPaint(
              painter: _HillsPainter(),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationRow() {
    return Row(
      children: [
        InkWell(
          onTap: onLocationTap,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place, size: 16, color: PrayerPalette.ink),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  locationName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PrayerPalette.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: PrayerPalette.ink,
              ),
            ],
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onMenu,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              '﷽',
              style: TextStyle(color: PrayerPalette.ink, fontSize: 17),
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
            child: CustomPaint(painter: _GaugePainter(progress: progress)),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  gaugeName,
                  style: const TextStyle(
                    color: PrayerPalette.ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  gaugeLabel,
                  style: TextStyle(
                    color: PrayerPalette.inkA(0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  gaugeCountdown,
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
