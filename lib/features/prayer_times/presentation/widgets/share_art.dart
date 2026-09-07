import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Artwork shared by the two share cards: a mosque skyline, a starfield and
/// a crescent. All painted, so they scale to any card size without assets.

/// A mosque silhouette — central dome on a drum, two minarets, two smaller
/// side domes and a low run of rooftops — filled in one colour so it reads as
/// a horizon against whatever is behind it.
///
/// Drawn in a 1080×170 design space and scaled to [size].
class MosqueSkylinePainter extends CustomPainter {
  final Color color;

  const MosqueSkylinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 1080;
    final sy = size.height / 170;
    final paint = Paint()..color = color;
    Offset o(double x, double y) => Offset(x * sx, y * sy);
    Rect r(double l, double t, double w, double h) =>
        Rect.fromLTWH(l * sx, t * sy, w * sx, h * sy);

    // Ground and low rooftops — a stepped city line under everything.
    final ground = Path()..moveTo(0, size.height);
    const steps = [
      [0, 150],
      [90, 150],
      [90, 136],
      [160, 136],
      [160, 146],
      [230, 146],
      [230, 128],
      [290, 128],
      [290, 142],
      [790, 142],
      [790, 130],
      [850, 130],
      [850, 144],
      [920, 144],
      [920, 134],
      [1000, 134],
      [1000, 148],
      [1080, 148],
    ];
    for (final s in steps) {
      ground.lineTo(s[0] * sx, s[1] * sy);
    }
    ground
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(ground, paint);

    // Main hall.
    canvas.drawRect(r(330, 112, 420, 60), paint);

    // Central dome on a drum, with a finial.
    canvas.drawRect(r(462, 96, 156, 40), paint);
    canvas.drawOval(r(448, 30, 184, 140), paint);
    canvas.drawRect(r(537, 6, 6, 40), paint);
    canvas.drawCircle(o(540, 6), 6 * sx, paint);

    // Side domes.
    for (final cx in [400.0, 680.0]) {
      canvas.drawRect(r(cx - 34, 108, 68, 30), paint);
      canvas.drawOval(r(cx - 40, 78, 80, 64), paint);
      canvas.drawRect(r(cx - 2, 62, 4, 22), paint);
    }

    // Minarets: shaft, two balconies, a pointed cap and a finial.
    for (final cx in [300.0, 780.0]) {
      canvas.drawRect(r(cx - 11, 40, 22, 132), paint);
      canvas.drawRect(r(cx - 17, 70, 34, 6), paint);
      canvas.drawRect(r(cx - 16, 100, 32, 5), paint);
      final cap = Path()
        ..moveTo((cx - 14) * sx, 42 * sy)
        ..lineTo(cx * sx, 12 * sy)
        ..lineTo((cx + 14) * sx, 42 * sy)
        ..close();
      canvas.drawPath(cap, paint);
      canvas.drawRect(r(cx - 1.5, 0, 3, 14), paint);
    }

    // Arched entrance cut out of the hall — a lighter notch made by painting
    // nothing there is not possible in one colour, so a slightly translucent
    // arch is drawn instead to suggest depth.
    final arch = Paint()..color = Colors.white.withValues(alpha: 0.08);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        r(516, 128, 48, 44),
        topLeft: Radius.circular(24 * sx),
        topRight: Radius.circular(24 * sx),
      ),
      arch,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        r(376, 138, 24, 34),
        topLeft: Radius.circular(12 * sx),
        topRight: Radius.circular(12 * sx),
      ),
      arch,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        r(680, 138, 24, 34),
        topLeft: Radius.circular(12 * sx),
        topRight: Radius.circular(12 * sx),
      ),
      arch,
    );
  }

  @override
  bool shouldRepaint(MosqueSkylinePainter old) => old.color != color;
}

/// A scatter of stars, brighter toward the top, fading out by [fadeBy]
/// (a fraction of the height) so they do not sit on the horizon glow.
///
/// Positions come from a fixed seed: the same card must paint the same way
/// every time it is previewed and exported.
class StarfieldPainter extends CustomPainter {
  final double fadeBy;
  final Color color;

  const StarfieldPainter({this.fadeBy = 0.7, this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(7);
    for (var i = 0; i < 90; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * fadeBy;
      final fade = 1 - (y / (size.height * fadeBy));
      final radius = 0.8 + rng.nextDouble() * 1.9;
      final alpha = (0.25 + rng.nextDouble() * 0.6) * fade;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = color.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }
    // A few four-point sparkles.
    for (var i = 0; i < 6; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * fadeBy * 0.6;
      final len = 5 + rng.nextDouble() * 6;
      final p = Paint()
        ..color = color.withValues(alpha: 0.55)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x - len, y), Offset(x + len, y), p);
      canvas.drawLine(Offset(x, y - len), Offset(x, y + len), p);
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter old) =>
      old.fadeBy != fadeBy || old.color != color;
}

/// A crescent: a disc with a second disc subtracted from its upper right.
class CrescentPainter extends CustomPainter {
  final Color color;

  const CrescentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = Offset(size.width / 2, size.height / 2);
    final full = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    final bite = Path()
      ..addOval(
        Rect.fromCircle(
          center: c.translate(r * 0.42, -r * 0.22),
          radius: r * 0.86,
        ),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, bite),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(CrescentPainter old) => old.color != color;
}
