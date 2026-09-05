import 'package:flutter/material.dart';

/// A prayer marker on the day track.
class TimelineTick {
  /// Position along the track, 0..1.
  final double position;

  /// Three-letter label, e.g. `FAJ`.
  final String label;

  /// True once the waqt has started — fills the dot gold.
  final bool passed;

  /// True for the waqt the widget is currently about — lights the label.
  final bool isCurrent;

  const TimelineTick({
    required this.position,
    required this.label,
    required this.passed,
    required this.isCurrent,
  });
}

/// A prohibited window on the day track.
class TimelineBlock {
  /// Start and end along the track, 0..1.
  final double start;
  final double end;

  const TimelineBlock({required this.start, required this.end});
}

/// Variant 3: the whole day as one track — prayer markers, the prohibited
/// windows in red, and a "now" needle.
class DayTimelineWidgetUI extends StatelessWidget {
  final List<TimelineTick> ticks;
  final List<TimelineBlock> blocks;

  /// Where "now" sits along the track, 0..1.
  final double now;

  /// e.g. `⛔ AVOID NOW · 8m left` or `next avoid · Sunset 5:58 pm`.
  final String avoidText;
  final bool avoidActive;

  /// Exact render size — see [PrayerWidgetUI.size] for why this is explicit.
  final Size size;

  const DayTimelineWidgetUI({
    super.key,
    required this.ticks,
    required this.blocks,
    required this.now,
    required this.avoidText,
    required this.avoidActive,
    required this.size,
  });

  static const _gold = Color(0xFFF5D27A);
  static const _alert = Color(0xFFEF4444);
  static const _alertLight = Color(0xFFFCA5A5);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF123B2C),
                Color(0xFF0E4A30),
                Color(0xFF062316),
              ],
              stops: [0.0, 0.6, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _header(),
              _track(),
              _labels(),
              _legend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Icon(Icons.remove_circle_outline, size: 12, color: _alertLight),
        const SizedBox(width: 6),
        const Text(
          'Prayer day map',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            avoidText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: avoidActive
                  ? _alertLight
                  : Colors.white.withValues(alpha: 0.55),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _track() {
    return SizedBox(
      height: 18,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Dawn → night colour wash for the whole day.
              Positioned(
                left: 0,
                right: 0,
                top: 2,
                height: 14,
                child: Opacity(
                  opacity: 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0A2E20),
                          Color(0xFFF2CE6B),
                          Color(0xFF7FBDB3),
                          Color(0xFFD4AF37),
                          Color(0xFF6E1B1B),
                          Color(0xFF0A1428),
                        ],
                        stops: [0.0, 0.11, 0.40, 0.78, 0.89, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // Everything after "now" is dimmed, so elapsed reads at a glance.
              Positioned(
                left: w * now.clamp(0.0, 1.0),
                right: 0,
                top: 2,
                height: 14,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF062316).withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              for (final block in blocks)
                Positioned(
                  left: w * block.start.clamp(0.0, 1.0),
                  width: (w * (block.end - block.start)).clamp(3.0, w),
                  top: 0,
                  height: 18,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _alert,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _alertLight),
                      boxShadow: [
                        BoxShadow(
                          color: _alert.withValues(alpha: 0.8),
                          blurRadius: 7,
                        ),
                      ],
                    ),
                  ),
                ),
              for (final tick in ticks)
                Positioned(
                  left: w * tick.position.clamp(0.0, 1.0) - 4.5,
                  top: 4.5,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tick.passed
                          ? _gold
                          : Colors.white.withValues(alpha: 0.35),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: w * now.clamp(0.0, 1.0) - 1.25,
                top: 0,
                height: 18,
                child: Container(
                  width: 2.5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.9),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _labels() {
    return SizedBox(
      height: 11,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final tick in ticks)
                Positioned(
                  // Centre each label on its tick; 16 is half a label's width.
                  left: (w * tick.position.clamp(0.0, 1.0) - 16)
                      .clamp(0.0, w - 32),
                  width: 32,
                  child: Text(
                    tick.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tick.isCurrent
                          ? _gold
                          : Colors.white.withValues(alpha: 0.6),
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _legend() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _alert,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: _alertLight),
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Prohibited (sunrise · zawal · sunset)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 8,
          height: 2.5,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Now',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
