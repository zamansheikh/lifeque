import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/salah_time_calculator.dart';
import '../utils/islamic_colors.dart';

/// Glass card listing recommended (non-fard) prayer times: Tahajjud window,
/// Islamic midnight, Ishraq (after sunrise) and tomorrow's Suhoor cutoff.
///
/// Surfaces information the underlying `SalahTimeCalculator` was already
/// computing but the page wasn't showing.
class SunnahTimesCard extends StatelessWidget {
  final SalahTimeCalculator calculator;

  const SunnahTimesCard({super.key, required this.calculator});

  @override
  Widget build(BuildContext context) {
    final times = calculator.getPrayerTimesMap();
    final sunnah = calculator.getSunnahTimes();
    final midnight = calculator.getIslamicMidnight();
    final sunrise = times['Sunrise']!;
    final ishraqStart = sunrise.add(const Duration(minutes: 15));
    final ishraqEnd = sunrise.add(const Duration(minutes: 45));

    final rows = <_SunnahRow>[
      _SunnahRow(
        icon: Icons.wb_sunny_outlined,
        accent: IslamicColors.goldLight,
        title: 'Ishraq / Duha',
        subtitle: '15–45 min after sunrise',
        timeText:
            '${DateFormat('h:mm a').format(ishraqStart).toLowerCase()}'
            ' → ${DateFormat('h:mm a').format(ishraqEnd).toLowerCase()}',
      ),
      _SunnahRow(
        icon: Icons.brightness_2_outlined,
        accent: IslamicColors.tealLight,
        title: 'Islamic Midnight',
        subtitle: 'midpoint Maghrib → Fajr',
        timeText: DateFormat('h:mm a').format(midnight).toLowerCase(),
      ),
      _SunnahRow(
        icon: Icons.bedtime_rounded,
        accent: IslamicColors.mint,
        title: 'Tahajjud (Last ⅓)',
        subtitle: 'most virtuous part of the night',
        timeText:
            '${DateFormat('h:mm a').format(sunnah.lastThirdOfTheNight).toLowerCase()}'
            ' → ${DateFormat('h:mm a').format(times['Fajr']!.add(const Duration(days: 1))).toLowerCase()}',
      ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: IslamicColors.goldLight.withValues(alpha: 0.25),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: IslamicColors.goldLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SUNNAH TIMES',
                    style: TextStyle(
                      color: IslamicColors.goldLight,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i < rows.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SunnahRow extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String timeText;

  const _SunnahRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: accent, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        Text(
          timeText,
          textAlign: TextAlign.end,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
