import 'package:flutter/widgets.dart';

/// A figure in sujud, drawn rather than picked from a font.
///
/// Material ships no prostration glyph — the nearest, `self_improvement`, is a
/// seated meditation pose, which is the wrong posture to put on a salah guide.
class SujudIcon extends StatelessWidget {
  const SujudIcon({super.key, required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _SujudPainter(color)),
    );
  }
}

class _SujudPainter extends CustomPainter {
  const _SujudPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Authored on a 24×24 grid, then scaled to whatever it is drawn at.
    final s = size.width / 24;
    Offset at(double x, double y) => Offset(x * s, y * s);

    // The back rising from the shoulders to the raised hips, then the thigh
    // folding back down to the ground.
    canvas.drawPath(
      Path()
        ..moveTo(9.4 * s, 18.2 * s)
        ..quadraticBezierTo(13.2 * s, 17.4 * s, 14.8 * s, 13.0 * s)
        ..quadraticBezierTo(15.9 * s, 10.2 * s, 18.3 * s, 11.8 * s)
        ..quadraticBezierTo(20.5 * s, 13.5 * s, 18.7 * s, 19.0 * s),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 3.0 * s,
    );

    // Forearms flat on the ground, reaching past the head.
    canvas.drawLine(
      at(3.4, 20.6),
      at(10.4, 20.6),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.2 * s,
    );

    // The head, down on the ground.
    canvas.drawCircle(at(6.3, 17.3), 2.9 * s, Paint()..color = color);

    // The ground itself, held back so it reads as a floor line.
    canvas.drawLine(
      at(2.4, 22.6),
      at(21.6, 22.6),
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.8 * s,
    );
  }

  @override
  bool shouldRepaint(_SujudPainter old) => old.color != color;
}
