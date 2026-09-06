import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/salah_time_calculator.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/islamic_colors.dart';

/// The three makruh windows, in detail.
///
/// Shown in the sheet opened from the prohibited-times card. Beyond listing
/// the windows it now carries the evidence they rest on — the page told people
/// not to pray at these times without ever saying on what authority.
class RestrictedTimesCard extends StatelessWidget {
  final SalahTimeCalculator calculator;

  const RestrictedTimesCard({super.key, required this.calculator});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
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
        const SizedBox(height: 18),
        if (active != null) ...[
          _activeBanner(context, active),
          const SizedBox(height: 16),
        ],
        _sectionLabel(l.restrictedTodayWindows),
        const SizedBox(height: 10),
        for (final entry in periods) ...[
          _PeriodRow(name: entry.key, data: entry.value),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
        _explainCard(context),
        const SizedBox(height: 12),
        _sectionLabel(l.restrictedEvidence),
        const SizedBox(height: 10),
        _hadith(context, l.restrictedHadith1, l.restrictedHadith1Ref),
        const SizedBox(height: 8),
        _hadith(context, l.restrictedHadith2, l.restrictedHadith2Ref),
        const SizedBox(height: 12),
        _scholarNote(context),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: IslamicColors.emerald,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _header(BuildContext context, bool isActive) {
    final l = L.of(context);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? const [IslamicColors.warning, IslamicColors.burgundy]
                  : const [IslamicColors.emeraldMid, IslamicColors.emerald],
            ),
            borderRadius: BorderRadius.circular(13),
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
                  Flexible(
                    child: Text(
                      l.restrictedTimesTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: IslamicColors.emerald,
                      ),
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: IslamicColors.warning,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l.restrictedActive,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                isActive ? l.restrictedActiveSubtitle : l.restrictedSubtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activeBanner(BuildContext context, Map<String, dynamic> active) {
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
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
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
                  _windowName(context, active['name'] as String),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  L.of(context).restrictedActiveSubtitle,
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
              _fmt(context, remaining),
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

  Widget _explainCard(BuildContext context) {
    final l = L.of(context);

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
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: IslamicColors.gold,
              ),
              const SizedBox(width: 6),
              Text(
                l.restrictedWhy,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: IslamicColors.emerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.restrictedWhyBody,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: Color(0xFF3F2A14),
            ),
          ),
        ],
      ),
    );
  }

  /// One narration, with its reference.
  ///
  /// The reference is the point — a claim about what is permitted should say
  /// where it comes from, so it can be checked rather than taken on trust.
  Widget _hadith(BuildContext context, String text, String reference) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: IslamicColors.emerald.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 18,
                color: IslamicColors.emerald.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.55,
                    color: Color(0xFF1B2A1F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: IslamicColors.emerald.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reference,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: IslamicColors.emerald,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scholarNote(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.school_outlined,
          size: 15,
          color: Colors.black.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            L.of(context).restrictedScholarNote,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ),
      ],
    );
  }

  static String _fmt(BuildContext context, Duration d) {
    final l = L.of(context);
    if (d.inHours > 0) {
      return '${l.taskUnitHours(d.inHours)} '
          '${l.taskUnitMinutes(d.inMinutes.remainder(60))}';
    }
    if (d.inMinutes > 0) return l.taskUnitMinutes(d.inMinutes);
    return l.taskUnitSeconds(d.inSeconds);
  }
}

/// The window's name in the current language. The map keys stay English.
String _windowName(BuildContext context, String key) {
  final l = L.of(context);
  return switch (key) {
    'Sunrise Period' => l.restrictedWindowSunrise,
    'Zawal (Midday)' => l.restrictedWindowZawal,
    'Sunset Period' => l.restrictedWindowSunset,
    _ => key,
  };
}

class _PeriodRow extends StatelessWidget {
  final String name;
  final Map<String, dynamic> data;

  const _PeriodRow({required this.name, required this.data});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? IslamicColors.warning.withValues(alpha: 0.08)
            : IslamicColors.cream,
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
            alignment: Alignment.center,
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
                  _windowName(context, name),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B2A1F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // The map's "~15 minutes" is English and unformatted; the
                  // length is derived from the window itself instead.
                  l.restrictedAboutMinutes(end.difference(start).inMinutes),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${DateFormat('h:mm a').format(start)} → '
                '${DateFormat('h:mm a').format(end)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isActive
                    ? l.restrictedActive
                    : isPast
                    ? l.restrictedPassed
                    : l.restrictedUpcoming,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
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
