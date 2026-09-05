import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/services/tasbih_service.dart';
import '../utils/prayer_palette.dart';

/// Digital tasbih: tap the dial to count a bead, 33 to a round, cycling
/// SubhanAllah → Alhamdulillah → Allahu Akbar.
class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key});

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  final _service = TasbihService.instance;
  TasbihState _state = const TasbihState(count: 0, round: 1, dhikrIndex: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded = await _service.load();
    if (!mounted) return;
    setState(() {
      _state = loaded;
      _loading = false;
    });
  }

  void _tap() {
    final next = _state.increment();
    // A round rolling over is worth a firmer buzz than a single bead.
    if (next.round != _state.round) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
    setState(() => _state = next);
    _service.save(next);
  }

  void _reset() {
    final next = _state.reset;
    setState(() => _state = next);
    _service.save(next);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: PrayerPalette.accent),
      );
    }
    final dhikr = Dhikr.at(_state.dhikrIndex);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const Text(
              'Tasbih',
              style: TextStyle(
                color: PrayerPalette.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Round ${_state.round} · after-prayer dhikr',
              style: TextStyle(
                color: PrayerPalette.inkA(0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              dhikr.arabic,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: PrayerPalette.ink,
                fontSize: 30,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dhikr.english,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PrayerPalette.inkA(0.6),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            _dial(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: _reset,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PrayerPalette.inkA(0.15)),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        color: PrayerPalette.ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: PrayerPalette.accentA(0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '33 · 33 · 34',
                    style: TextStyle(
                      color: PrayerPalette.accent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dial() {
    return GestureDetector(
      onTap: _tap,
      child: SizedBox(
        width: 210,
        height: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(210),
              painter: _TasbihRingPainter(progress: _state.progress),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: PrayerPalette.ink.withValues(alpha: 0.14),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_state.count}',
                    style: const TextStyle(
                      color: PrayerPalette.ink,
                      fontSize: 54,
                      fontWeight: FontWeight.w300,
                      height: 1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'of ${TasbihService.perRound} · tap to count',
                    style: TextStyle(
                      color: PrayerPalette.inkA(0.5),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TasbihRingPainter extends CustomPainter {
  final double progress;

  const _TasbihRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 11;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = PrayerPalette.inkA(0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -1.5707963267948966, // 12 o'clock
        6.283185307179586 * progress,
        false,
        Paint()
          ..color = PrayerPalette.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TasbihRingPainter old) => old.progress != progress;
}
