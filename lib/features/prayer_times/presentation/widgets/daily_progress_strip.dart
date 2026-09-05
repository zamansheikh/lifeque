import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/islamic_colors.dart';

/// Five tiny dots showing which of today's fard prayers have been logged
/// as prayed, plus an `X / 5` count and a soft motivational line.
class DailyProgressStrip extends StatelessWidget {
  static const _order = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  final Set<String> prayed;
  final int streak;

  const DailyProgressStrip({
    super.key,
    required this.prayed,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final done = _order.where(prayed.contains).length;
    final tagline = _tagline(done);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            border: Border.all(
              color: IslamicColors.emeraldLight.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [IslamicColors.emerald, IslamicColors.emeraldLight],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: IslamicColors.emeraldLight.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$done',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Today · $done of 5',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (streak > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 11)),
                              const SizedBox(width: 2),
                              Text(
                                '$streak',
                                style: const TextStyle(
                                  color: IslamicColors.goldLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        for (final p in _order) ...[
                          _Dot(filled: prayed.contains(p)),
                          if (p != _order.last) const SizedBox(width: 5),
                        ],
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            tagline,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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

  static String _tagline(int done) {
    switch (done) {
      case 0:
        return 'Start the day with intention';
      case 1:
        return 'Good start — keep going';
      case 2:
        return 'You\'re on track';
      case 3:
        return 'More than halfway through';
      case 4:
        return 'One left — finish strong';
      case 5:
        return 'MashaAllah · all five prayed';
      default:
        return '';
    }
  }
}

class _Dot extends StatelessWidget {
  final bool filled;
  const _Dot({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: filled
            ? IslamicColors.emeraldLight
            : Colors.white.withValues(alpha: 0.25),
        shape: BoxShape.circle,
        boxShadow: filled
            ? [
                BoxShadow(
                  color: IslamicColors.emeraldLight.withValues(alpha: 0.6),
                  blurRadius: 5,
                ),
              ]
            : null,
      ),
    );
  }
}
