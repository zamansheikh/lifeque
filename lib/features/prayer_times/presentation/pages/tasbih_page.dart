import 'dart:math' as math;

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

class _TasbihPageState extends State<TasbihPage>
    with SingleTickerProviderStateMixin {
  final _service = TasbihService.instance;
  TasbihState _state = const TasbihState(count: 0, round: 1, dhikrIndex: 0);
  bool _loading = true;

  /// Quick squash on each bead so the dial feels like a physical button.
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    lowerBound: 0,
    upperBound: 0.04,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
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
    _press.forward().then((_) => _press.reverse());
    setState(() => _state = next);
    _service.save(next);
  }

  Future<void> _reset() async {
    final confirmed = _state.count == 0 && _state.round == 1
        ? true
        : await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  'Reset the counter?',
                  style: TextStyle(
                    color: PrayerPalette.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                content: Text(
                  'This clears round ${_state.round} and starts again '
                  'from SubhanAllah.',
                  style: TextStyle(color: PrayerPalette.inkA(0.7)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Keep counting'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: PrayerPalette.accent,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ) ??
            false;
    if (!confirmed) return;
    final next = _state.reset;
    setState(() => _state = next);
    _service.save(next);
  }

  /// Beads counted since the very first round — the session total.
  int get _total =>
      (_state.round - 1) * TasbihService.perRound + _state.count;

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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _headerRow(),
            const SizedBox(height: 14),
            _dhikrCard(dhikr),
            const SizedBox(height: 20),
            _dial(),
            const SizedBox(height: 18),
            _sequence(),
            const SizedBox(height: 14),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _headerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Tasbih',
          style: TextStyle(
            color: PrayerPalette.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: PrayerPalette.accentA(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Round ${_state.round}',
            style: const TextStyle(
              color: PrayerPalette.accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dhikrCard(Dhikr dhikr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PrayerPalette.cardRadius),
        boxShadow: PrayerPalette.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            dhikr.arabic,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: PrayerPalette.arabic(fontSize: 36, height: 1.7),
          ),
          const SizedBox(height: 6),
          Text(
            dhikr.english,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PrayerPalette.inkA(0.6),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dial() {
    return GestureDetector(
      onTap: _tap,
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, child) => Transform.scale(
          scale: 1 - _press.value,
          child: child,
        ),
        child: SizedBox(
          width: 228,
          height: 228,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(228),
                painter: _TasbihRingPainter(
                  progress: _state.progress,
                  count: _state.count,
                ),
              ),
              Container(
                margin: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Solid white, not a gradient — a gradient's outer stop
                  // blends into the page ground and makes the button read
                  // smaller than its tap target.
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: PrayerPalette.ink.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
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
                        fontSize: 60,
                        fontWeight: FontWeight.w300,
                        height: 1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of ${TasbihService.perRound}',
                      style: TextStyle(
                        color: PrayerPalette.inkA(0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: PrayerPalette.accentA(0.10),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Text(
                        'tap to count',
                        style: TextStyle(
                          color: PrayerPalette.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
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

  /// The 33 · 33 · 34 sequence, with the dhikr currently being counted lit.
  Widget _sequence() {
    const counts = [33, 33, 34];
    final active = _state.dhikrIndex % 3;
    return Row(
      children: [
        for (var i = 0; i < counts.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: i == active ? PrayerPalette.accent : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: i == active
                      ? PrayerPalette.accent
                      : PrayerPalette.inkA(0.12),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    Dhikr.at(i).english.split(' — ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i == active
                          ? Colors.white.withValues(alpha: 0.85)
                          : PrayerPalette.inkA(0.5),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${counts[i]}×',
                    style: TextStyle(
                      color: i == active ? Colors.white : PrayerPalette.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _footer() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PrayerPalette.accentA(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$_total counted',
              style: const TextStyle(
                color: PrayerPalette.accent,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: _reset,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PrayerPalette.inkA(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 15,
                  color: PrayerPalette.inkA(0.7),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Reset',
                  style: TextStyle(
                    color: PrayerPalette.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Progress ring plus 33 bead ticks, so the round reads at a glance.
class _TasbihRingPainter extends CustomPainter {
  final double progress;
  final int count;

  const _TasbihRingPainter({required this.progress, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2; // 12 o'clock

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = PrayerPalette.inkA(0.09)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        start,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = PrayerPalette.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round,
      );
    }

    // One tick per bead, just outside the ring; counted ones fill in.
    const beads = TasbihService.perRound;
    for (var i = 0; i < beads; i++) {
      final angle = start + (2 * math.pi * i / beads);
      final at = Offset(
        center.dx + (radius + 9) * math.cos(angle),
        center.dy + (radius + 9) * math.sin(angle),
      );
      canvas.drawCircle(
        at,
        i < count ? 2.2 : 1.6,
        Paint()
          ..color = i < count
              ? PrayerPalette.accent
              : PrayerPalette.inkA(0.18),
      );
    }
  }

  @override
  bool shouldRepaint(_TasbihRingPainter old) =>
      old.progress != progress || old.count != count;
}
