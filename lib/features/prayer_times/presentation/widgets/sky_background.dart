import 'package:flutter/material.dart';

import '../utils/sky_theme.dart';

/// Full-bleed gradient that morphs through the day. Lives behind every
/// element on the prayer page so the whole screen "feels" like the sky.
class SkyBackground extends StatelessWidget {
  final SkyTheme theme;
  final Widget child;

  const SkyBackground({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.gradient.first,
            theme.gradient.last,
            const Color(0xFF0A0E27),
          ],
          stops: const [0.0, 0.45, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Subtle starfield in the lower (night) half — gives the page a
          // little depth without competing with the content.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _StarsPainter(
                  brightness:
                      theme == SkyTheme.isha || theme == SkyTheme.preDawn
                      ? 0.7
                      : 0.15,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _StarsPainter extends CustomPainter {
  final double brightness;
  _StarsPainter({required this.brightness});

  @override
  void paint(Canvas canvas, Size size) {
    if (brightness <= 0.01) return;
    final paint = Paint()..color = Colors.white.withValues(alpha: brightness);
    // Deterministic pseudo-random positions so they don't dance on rebuild.
    const seed = 7919;
    for (int i = 0; i < 60; i++) {
      final x = ((i * seed) % 1000) / 1000 * size.width;
      final y = (((i + 31) * seed) % 1000) / 1000 * size.height * 0.7;
      final r = 0.7 + ((i * 13) % 7) / 10;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarsPainter old) =>
      old.brightness != brightness;
}
