import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Painted backdrops for the birthday wish cards. Everything is drawn, so
/// the cards need no image assets and stay crisp at export size.
///
/// Each painter keeps the middle of the card clear: that is where the name
/// and the message go, and decoration behind text is noise.

/// Scattered confetti — tilted strips and dots — thickest at the edges.
class ConfettiPainter extends CustomPainter {
  static const _colors = [
    Color(0xFFF472B6),
    Color(0xFFFBBF24),
    Color(0xFF34D399),
    Color(0xFF60A5FA),
    Color(0xFFA78BFA),
    Color(0xFFFB7185),
  ];

  const ConfettiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(11);
    final clear = Rect.fromLTRB(
      size.width * 0.16,
      size.height * 0.26,
      size.width * 0.84,
      size.height * 0.80,
    );
    var placed = 0;
    while (placed < 110) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      if (clear.contains(Offset(x, y))) continue;
      placed++;
      final color = _colors[rng.nextInt(_colors.length)];
      final paint = Paint()
        ..color = color.withValues(alpha: 0.75 + rng.nextDouble() * 0.25);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rng.nextDouble() * math.pi);
      if (rng.nextInt(4) == 0) {
        canvas.drawCircle(Offset.zero, 5 + rng.nextDouble() * 6, paint);
      } else {
        final w = 16 + rng.nextDouble() * 18;
        final h = 7 + rng.nextDouble() * 7;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: h),
            const Radius.circular(3),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter old) => false;
}

/// Pastel balloons rising along both sides, strings trailing below.
class BalloonsPainter extends CustomPainter {
  static const _colors = [
    Color(0xFFF9A8D4),
    Color(0xFFFCD34D),
    Color(0xFF93C5FD),
    Color(0xFF86EFAC),
    Color(0xFFC4B5FD),
    Color(0xFFFDA4AF),
  ];

  const BalloonsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // (x, y, scale) in fractions of the card; sides only, centre stays clear.
    const spots = [
      [0.08, 0.80, 1.0],
      [0.20, 0.92, 0.8],
      [0.05, 0.36, 0.7],
      [0.92, 0.78, 1.05],
      [0.80, 0.94, 0.75],
      [0.95, 0.30, 0.65],
      [0.14, 0.12, 0.55],
      [0.86, 0.10, 0.6],
    ];
    for (var i = 0; i < spots.length; i++) {
      final s = spots[i];
      _balloon(
        canvas,
        Offset(s[0] * size.width, s[1] * size.height),
        70 * s[2],
        _colors[i % _colors.length],
      );
    }
  }

  void _balloon(Canvas canvas, Offset c, double r, Color color) {
    final body = Rect.fromCenter(center: c, width: r * 2, height: r * 2.4);
    canvas.drawOval(body, Paint()..color = color);
    // Highlight.
    canvas.drawOval(
      Rect.fromCenter(
        center: c.translate(-r * 0.35, -r * 0.55),
        width: r * 0.5,
        height: r * 0.8,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
    // Knot.
    final knotY = c.dy + r * 1.2;
    final knot = Path()
      ..moveTo(c.dx, knotY - 4)
      ..lineTo(c.dx - r * 0.14, knotY + r * 0.16)
      ..lineTo(c.dx + r * 0.14, knotY + r * 0.16)
      ..close();
    canvas.drawPath(knot, Paint()..color = color);
    // String.
    final string = Path()
      ..moveTo(c.dx, knotY + r * 0.16)
      ..quadraticBezierTo(
        c.dx + r * 0.5,
        knotY + r * 0.9,
        c.dx - r * 0.2,
        knotY + r * 1.6,
      )
      ..quadraticBezierTo(
        c.dx - r * 0.7,
        knotY + r * 2.2,
        c.dx + r * 0.1,
        knotY + r * 2.8,
      );
    canvas.drawPath(
      string,
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(BalloonsPainter old) => false;
}

/// Five-petal blossoms with leaves, clustered in two opposite corners.
class FloralPainter extends CustomPainter {
  const FloralPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(23);
    const petals = [Color(0xFFF9A8D4), Color(0xFFF472B6), Color(0xFFFDA4AF)];
    const leaf = Color(0xFF86EFAC);

    // Corner clusters: (cx, cy, radius of cluster).
    const clusters = [
      [0.10, 0.10, 0.20],
      [0.90, 0.90, 0.20],
      [0.92, 0.12, 0.10],
      [0.08, 0.90, 0.10],
    ];
    for (final c in clusters) {
      final centre = Offset(c[0] * size.width, c[1] * size.height);
      final spread = c[2] * size.width;
      final count = (spread / 22).round();
      for (var i = 0; i < count; i++) {
        final angle = rng.nextDouble() * math.pi * 2;
        final dist = rng.nextDouble() * spread;
        final p = centre.translate(
          math.cos(angle) * dist,
          math.sin(angle) * dist,
        );
        if (rng.nextInt(3) == 0) {
          _leaf(
            canvas,
            p,
            22 + rng.nextDouble() * 18,
            rng.nextDouble() * math.pi,
            leaf,
          );
        } else {
          _flower(
            canvas,
            p,
            18 + rng.nextDouble() * 22,
            petals[rng.nextInt(petals.length)],
          );
        }
      }
    }
    // A sprinkle of tiny dots for air.
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        2 + rng.nextDouble() * 3,
        Paint()..color = const Color(0xFFF472B6).withValues(alpha: 0.25),
      );
    }
  }

  void _flower(Canvas canvas, Offset c, double r, Color color) {
    final petal = Paint()..color = color.withValues(alpha: 0.9);
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * math.pi * 2 / 5);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -r * 0.6),
          width: r * 0.8,
          height: r * 1.2,
        ),
        petal,
      );
      canvas.restore();
    }
    canvas.drawCircle(c, r * 0.32, Paint()..color = const Color(0xFFFBBF24));
  }

  void _leaf(Canvas canvas, Offset c, double len, double angle, Color color) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: len, height: len * 0.45),
      Paint()..color = color.withValues(alpha: 0.85),
    );
    canvas.drawLine(
      Offset(-len / 2, 0),
      Offset(len / 2, 0),
      Paint()
        ..color = const Color(0xFF16A34A).withValues(alpha: 0.5)
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(FloralPainter old) => false;
}

/// A double gold rule with diamond corner ornaments — the stationery look.
class GoldFramePainter extends CustomPainter {
  final Color color;

  const GoldFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final thick = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final thin = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final outer = Rect.fromLTWH(44, 44, size.width - 88, size.height - 88);
    final inner = outer.deflate(16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, const Radius.circular(6)),
      thick,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(2)),
      thin,
    );

    final fill = Paint()..color = color;
    void diamond(Offset c, double r) {
      final p = Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + r, c.dy)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx - r, c.dy)
        ..close();
      canvas.drawPath(p, fill);
    }

    for (final c in [
      inner.topLeft,
      inner.topRight,
      inner.bottomLeft,
      inner.bottomRight,
    ]) {
      diamond(c, 11);
    }
    // A three-diamond flourish at the top and bottom centre.
    for (final y in [inner.top, inner.bottom]) {
      final cx = size.width / 2;
      diamond(Offset(cx, y), 9);
      diamond(Offset(cx - 26, y), 5);
      diamond(Offset(cx + 26, y), 5);
    }
  }

  @override
  bool shouldRepaint(GoldFramePainter old) => old.color != color;
}
