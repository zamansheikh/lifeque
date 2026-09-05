import 'package:flutter/material.dart';

/// Variant 4: a single-row bar for people who want the next waqt and nothing
/// else taking up their home screen.
class SlimBarWidgetUI extends StatelessWidget {
  /// Prayer the bar is about — the running waqt, or the next one.
  final String prayerName;

  /// e.g. `4:26 PM – 6:13 PM`.
  final String windowRange;

  /// `HH:MM:SS` remaining.
  final String countdown;

  /// e.g. `Waqt ends in` / `Starts in`.
  final String countdownLabel;

  /// Exact render size — see [PrayerWidgetUI.size] for why this is explicit.
  final Size size;

  const SlimBarWidgetUI({
    super.key,
    required this.prayerName,
    required this.windowRange,
    required this.countdown,
    required this.countdownLabel,
    required this.size,
  });

  static const _gold = Color(0xFFF5D27A);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E7A50), Color(0xFF0E4A30)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.mosque, size: 14, color: _gold),
              const SizedBox(width: 8),
              Text(
                prayerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  windowRange,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 8),
              Text(
                countdown,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                countdownLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
