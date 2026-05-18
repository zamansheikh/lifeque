import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../../../../core/utils/salah_time_calculator.dart';
import '../utils/islamic_colors.dart';

/// Live Qibla compass dressed in the Islamic palette — emerald/gold dial,
/// gold needle, cream face. When the phone is aligned with the Qibla the
/// dial pulses green and the bearing reads in emerald.
class QiblaCard extends StatefulWidget {
  final SalahTimeCalculator calculator;

  const QiblaCard({super.key, required this.calculator});

  @override
  State<QiblaCard> createState() => _QiblaCardState();
}

class _QiblaCardState extends State<QiblaCard>
    with SingleTickerProviderStateMixin {
  double? _compassDirection;
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _hasCompass = false;
  bool _isCompassLoading = true;

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initCompass() async {
    try {
      _compassSubscription = FlutterCompass.events?.listen(
        (CompassEvent event) {
          if (!mounted) return;
          setState(() {
            _compassDirection = event.heading;
            _hasCompass = true;
            _isCompassLoading = false;
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() {
            _hasCompass = false;
            _isCompassLoading = false;
          });
        },
      );
      Timer(const Duration(seconds: 2), () {
        if (_isCompassLoading && mounted) {
          setState(() {
            _hasCompass = false;
            _isCompassLoading = false;
          });
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasCompass = false;
        _isCompassLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final qiblaBearing = widget.calculator.getQiblaDirection();
    final compassDir = _compassDirection ?? 0;
    final relativeQibla = (qiblaBearing - compassDir + 360) % 360;
    final isAligned = _isAligned(relativeQibla);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _header(qiblaBearing, isAligned),
        const SizedBox(height: 20),
        _compass(qiblaBearing, compassDir, isAligned),
        const SizedBox(height: 20),
        _facts(qiblaBearing),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _header(double bearing, bool isAligned) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [IslamicColors.emerald, IslamicColors.emeraldMid],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: IslamicColors.emerald.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.explore_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Qibla',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: IslamicColors.emerald,
                ),
              ),
              Text(
                _hasCompass
                    ? (isAligned
                        ? 'Aligned · point toward the Ka\'bah'
                        : 'Rotate phone to align')
                    : 'Bearing from your location',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: IslamicColors.goldLight.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: IslamicColors.goldDeep.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            '${bearing.toStringAsFixed(1)}°',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: IslamicColors.goldDeep,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  // ── Compass ─────────────────────────────────────────────────────────────

  Widget _compass(double qiblaBearing, double compassDir, bool isAligned) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            IslamicColors.cream,
            IslamicColors.cream.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isAligned
                    ? IslamicColors.emeraldLight
                    : Colors.black)
                .withValues(alpha: isAligned ? 0.4 : 0.15),
            blurRadius: isAligned ? 30 : 18,
            spreadRadius: isAligned ? 4 : 0,
          ),
        ],
        border: Border.all(
          color: isAligned
              ? IslamicColors.emeraldLight
              : IslamicColors.goldDeep,
          width: 3,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dial — rotates with phone heading
          if (_hasCompass)
            Transform.rotate(
              angle: -compassDir * math.pi / 180,
              child: CustomPaint(
                size: const Size(260, 260),
                painter: _DialPainter(),
              ),
            )
          else
            CustomPaint(
              size: const Size(260, 260),
              painter: _DialPainter(),
            ),

          // Qibla needle — emerald with gold tip pointing toward the Ka'bah
          if (_hasCompass)
            Transform.rotate(
              angle: (qiblaBearing - compassDir) * math.pi / 180,
              child: CustomPaint(
                size: const Size(220, 220),
                painter: _NeedlePainter(isAligned: isAligned),
              ),
            )
          else
            Transform.rotate(
              angle: qiblaBearing * math.pi / 180,
              child: CustomPaint(
                size: const Size(220, 220),
                painter: _NeedlePainter(isAligned: false),
              ),
            ),

          // Center — Ka'bah glyph
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  IslamicColors.midnight,
                  IslamicColors.midnightDeep,
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: IslamicColors.goldLight,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: IslamicColors.goldGlow.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🕋',
                style: TextStyle(fontSize: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Facts row ───────────────────────────────────────────────────────────

  Widget _facts(double bearing) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IslamicColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: IslamicColors.emerald.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _factCell(
              icon: Icons.navigation_rounded,
              label: 'BEARING',
              value: '${bearing.toStringAsFixed(0)}° ${_compass8(bearing)}',
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: IslamicColors.emerald.withValues(alpha: 0.15),
          ),
          Expanded(
            child: _factCell(
              icon: _hasCompass
                  ? Icons.sensors_rounded
                  : Icons.sensors_off_rounded,
              label: 'COMPASS',
              value: _isCompassLoading
                  ? 'detecting…'
                  : _hasCompass
                      ? 'live'
                      : 'not available',
              accent: _hasCompass
                  ? IslamicColors.emeraldLight
                  : IslamicColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _factCell({
    required IconData icon,
    required String label,
    required String value,
    Color? accent,
  }) {
    final c = accent ?? IslamicColors.emerald;
    return Column(
      children: [
        Icon(icon, color: c, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: c,
          ),
        ),
      ],
    );
  }

  bool _isAligned(double relativeQibla) {
    // Within ±5° counts as aligned (typical Qibla apps).
    return relativeQibla < 5 || relativeQibla > 355;
  }

  static String _compass8(double bearing) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final i = (((bearing + 22.5) / 45) % 8).floor();
    return dirs[i];
  }
}

/// The dial — cream background with cardinal tick marks and N/E/S/W glyphs.
class _DialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tick = Paint()
      ..color = IslamicColors.emerald.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final majorTick = Paint()
      ..color = IslamicColors.emerald
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (int deg = 0; deg < 360; deg += 15) {
      final isCardinal = deg % 90 == 0;
      final isMajor = deg % 30 == 0;
      final inset = isCardinal ? 18.0 : (isMajor ? 12.0 : 6.0);
      final paint = isCardinal ? majorTick : tick;
      final a = (deg - 90) * math.pi / 180;
      final p1 = center +
          Offset(math.cos(a) * (radius - 8), math.sin(a) * (radius - 8));
      final p2 = center +
          Offset(
            math.cos(a) * (radius - 8 - inset),
            math.sin(a) * (radius - 8 - inset),
          );
      canvas.drawLine(p1, p2, paint);
    }

    // Cardinal letters
    const labels = [('N', 0), ('E', 90), ('S', 180), ('W', 270)];
    for (final entry in labels) {
      final letter = entry.$1;
      final deg = entry.$2;
      final a = (deg - 90) * math.pi / 180;
      final pos = center +
          Offset(
            math.cos(a) * (radius - 42),
            math.sin(a) * (radius - 42),
          );
      final tp = TextPainter(
        text: TextSpan(
          text: letter,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: letter == 'N'
                ? IslamicColors.warning
                : IslamicColors.emerald,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => false;
}

/// The Qibla needle — gold-tipped emerald arrow pointing toward the Ka'bah.
/// Turns fully gold + glowing when the phone is aligned.
class _NeedlePainter extends CustomPainter {
  final bool isAligned;
  _NeedlePainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final topY = 14.0;
    final bottomY = size.height - 36;

    final tipColor = isAligned
        ? IslamicColors.goldGlow
        : IslamicColors.goldLight;
    final bodyColor = isAligned
        ? IslamicColors.emeraldLight
        : IslamicColors.emerald;

    // Soft glow halo behind the tip
    canvas.drawCircle(
      Offset(center.dx, topY + 12),
      isAligned ? 22 : 12,
      Paint()
        ..color = tipColor.withValues(alpha: isAligned ? 0.45 : 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Needle body — triangle from center upward to tip
    final needle = Path()
      ..moveTo(center.dx, topY)
      ..lineTo(center.dx - 12, center.dy)
      ..lineTo(center.dx + 12, center.dy)
      ..close();
    canvas.drawPath(
      needle,
      Paint()
        ..shader = LinearGradient(
          colors: [tipColor, bodyColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, topY, size.width, center.dy - topY)),
    );

    // Tail — thin emerald triangle below center
    final tail = Path()
      ..moveTo(center.dx, bottomY)
      ..lineTo(center.dx - 6, center.dy)
      ..lineTo(center.dx + 6, center.dy)
      ..close();
    canvas.drawPath(
      tail,
      Paint()..color = IslamicColors.emerald.withValues(alpha: 0.7),
    );

    // White outline for the tip triangle
    canvas.drawPath(
      needle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter old) =>
      old.isAligned != isAligned;
}
