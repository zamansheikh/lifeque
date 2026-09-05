import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/services/prayer_completion_service.dart';
import '../utils/prayer_palette.dart';

/// Prayer history: streak, this week's bars and a 30-day completion heatmap.
class PrayerStatsPage extends StatefulWidget {
  const PrayerStatsPage({super.key});

  @override
  State<PrayerStatsPage> createState() => _PrayerStatsPageState();
}

class _PrayerStatsPageState extends State<PrayerStatsPage> {
  final _service = PrayerCompletionService.instance;

  int _streak = 0;
  List<int> _week = const [];
  List<int> _month = const [];
  double _rate = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final streak = await _service.getCurrentStreak();
    final week = await _service.recentCounts(7);
    final month = await _service.recentCounts(30);
    final rate = await _service.completionRate(30);
    if (!mounted) return;
    setState(() {
      _streak = streak;
      _week = week;
      _month = month;
      _rate = rate;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrayerPalette.canvas,
      appBar: AppBar(
        backgroundColor: PrayerPalette.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: PrayerPalette.ink,
        title: const Text(
          'Prayer Stats',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: PrayerPalette.accent),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              physics: const BouncingScrollPhysics(),
              children: [
                _tiles(),
                const SizedBox(height: 10),
                _weekCard(),
                const SizedBox(height: 10),
                _heatCard(),
              ],
            ),
    );
  }

  Widget _tiles() {
    final weekTotal = _week.fold<int>(0, (a, b) => a + b);
    return Row(
      children: [
        Expanded(
          child: _tile(
            value: '$_streak',
            label: 'day streak 🔥',
            dark: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tile(
            value: '$weekTotal',
            label: 'of 35 this week',
            dark: false,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _tile(
            value: '${(_rate * 100).round()}%',
            label: '30-day rate',
            dark: false,
          ),
        ),
      ],
    );
  }

  Widget _tile({
    required String value,
    required String label,
    required bool dark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [PrayerPalette.ramadanFrom, PrayerPalette.ramadanTo],
              )
            : null,
        color: dark ? null : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: PrayerPalette.ink.withValues(alpha: dark ? 0.25 : 0.08),
            blurRadius: dark ? 16 : 12,
            offset: Offset(0, dark ? 5 : 3),
          ),
        ],
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: dark ? PrayerPalette.gold : PrayerPalette.ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: dark
                    ? Colors.white.withValues(alpha: 0.75)
                    : PrayerPalette.inkA(0.55),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekCard() {
    final today = DateTime.now();
    return _card(
      title: 'This week',
      child: SizedBox(
        height: 64,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _week.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _bar(
                  count: _week[i],
                  day: DateFormat('E').format(
                    today.subtract(Duration(days: _week.length - 1 - i)),
                  ),
                  isToday: i == _week.length - 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bar({
    required int count,
    required String day,
    required bool isToday,
  }) {
    // 42px of bar for a full five prayers, with a visible stub at zero.
    final height = (count / 5 * 42).clamp(5.0, 42.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: PrayerPalette.inkA(0.6),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: isToday
                ? PrayerPalette.goldRule
                : count >= 5
                    ? PrayerPalette.accent
                    : PrayerPalette.ramadanTo.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          day.substring(0, 2),
          style: TextStyle(
            color: PrayerPalette.inkA(0.5),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _heatCard() {
    return _card(
      title: 'Last 30 days',
      trailing: Text(
        'each dot = 1 day',
        style: TextStyle(
          color: PrayerPalette.inkA(0.5),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.5,
            children: [
              for (final count in _month)
                Container(
                  decoration: BoxDecoration(
                    color: PrayerPalette.heatFor(count),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '0',
                style: TextStyle(
                  color: PrayerPalette.inkA(0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              for (final c in const [
                PrayerPalette.heat0,
                PrayerPalette.heat3,
                PrayerPalette.heat4,
                PrayerPalette.heat5,
              ]) ...[
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
              Text(
                '5',
                style: TextStyle(
                  color: PrayerPalette.inkA(0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PrayerPalette.cardRadius),
        boxShadow: PrayerPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: PrayerPalette.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
