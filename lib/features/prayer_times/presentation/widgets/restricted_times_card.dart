import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/salah_time_calculator.dart';
import '../utils/islamic_colors.dart';

/// Detailed view of the three Makruh (restricted prayer) periods of the
/// day — typically rendered inside the bottom sheet opened from
/// [RestrictedTimesPill]. Designed in the same Islamic palette as the rest
/// of the prayer experience.
class RestrictedTimesCard extends StatelessWidget {
  final SalahTimeCalculator calculator;

  const RestrictedTimesCard({super.key, required this.calculator});

  @override
  Widget build(BuildContext context) {
    final restricted = calculator.getRestrictedTimes();
    final active = calculator.getCurrentRestrictedPeriod();

    final periods = restricted.entries.toList()
      ..sort(
        (a, b) => (a.value['start'] as DateTime).compareTo(
          b.value['start'] as DateTime,
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, active != null),
        const SizedBox(height: 16),
        if (active != null) ...[
          _activeBanner(active),
          const SizedBox(height: 16),
        ],
        Text(
          "Today's Restricted Windows",
          style: TextStyle(
            color: IslamicColors.emerald,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        for (final entry in periods) ...[
          _PeriodRow(name: entry.key, data: entry.value),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        _explainCard(),
      ],
    );
  }

  Widget _header(BuildContext context, bool isActive) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? const [IslamicColors.warning, IslamicColors.burgundy]
                  : const [IslamicColors.emeraldMid, IslamicColors.emerald],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color:
                    (isActive ? IslamicColors.warning : IslamicColors.emerald)
                        .withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.do_not_disturb_on_outlined,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Restricted Times',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: IslamicColors.emerald,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: IslamicColors.warning,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                isActive
                    ? 'Avoid voluntary prayer right now'
                    : 'Times when Salah is discouraged',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activeBanner(Map<String, dynamic> active) {
    final remaining = active['remaining'] as Duration;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [IslamicColors.warning, IslamicColors.burgundy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: IslamicColors.warning.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  active['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  active['reason'] as String,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _fmt(remaining),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _explainCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IslamicColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: IslamicColors.goldLight.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: IslamicColors.gold,
              ),
              SizedBox(width: 6),
              Text(
                'Why these times?',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: IslamicColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Three short windows each day — sunrise (~15 min), midday "
            "(Zawal, ~6 min) and sunset (~15 min) — are makruh for voluntary "
            "prayer. Only the missed Asr may be offered during the sunset "
            "window if no other choice remains, since delaying further would "
            "lose the Asr entirely.",
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: Color(0xFF3F2A14),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return '${d.inSeconds}s';
  }
}

class _PeriodRow extends StatelessWidget {
  final String name;
  final Map<String, dynamic> data;

  const _PeriodRow({required this.name, required this.data});

  @override
  Widget build(BuildContext context) {
    final start = data['start'] as DateTime;
    final end = data['end'] as DateTime;
    final now = DateTime.now();
    final isActive = now.isAfter(start) && now.isBefore(end);
    final isPast = now.isAfter(end);

    final accent = isActive
        ? IslamicColors.warning
        : isPast
        ? IslamicColors.emeraldLight
        : IslamicColors.goldDeep;
    final bg = isActive
        ? IslamicColors.warning.withValues(alpha: 0.08)
        : IslamicColors.cream;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Icon(_iconFor(name), size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B2A1F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data['duration'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${DateFormat('h:mm a').format(start).toLowerCase()}'
                ' → ${DateFormat('h:mm a').format(end).toLowerCase()}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isActive
                    ? 'ACTIVE'
                    : isPast
                    ? 'PASSED'
                    : 'UPCOMING',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    if (name.contains('Sunrise')) return Icons.wb_twilight_rounded;
    if (name.contains('Zawal')) return Icons.wb_sunny_rounded;
    if (name.contains('Sunset')) return Icons.brightness_3_rounded;
    return Icons.schedule_rounded;
  }
}
