import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/salah_time_calculator.dart';
import '../../data/services/prayer_settings_service.dart';
import '../utils/bangla_date.dart';
import '../utils/hijri_names.dart';
import '../utils/prayer_palette.dart';
import '../widgets/prayer_share_sheet.dart';

/// Month timetable: a week strip, today's five prayers, and a scrollable list
/// of every day in the visible month.
class PrayerCalendarPage extends StatefulWidget {
  const PrayerCalendarPage({super.key});

  @override
  State<PrayerCalendarPage> createState() => _PrayerCalendarPageState();
}

class _PrayerCalendarPageState extends State<PrayerCalendarPage> {
  final _settings = PrayerSettingsService.instance;

  /// First of the month currently shown.
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  double _latitude = 23.8103;
  double _longitude = 90.4125;
  String _locationName = 'Dhaka';
  CalculationMethod _method = CalculationMethod.karachi;
  Madhab _madhab = Madhab.hanafi;
  bool _loading = true;

  static const _fard = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loc = await _settings.getSavedLocation();
    final method = await _settings.getCalculationMethod();
    final madhab = await _settings.getMadhab();
    if (!mounted) return;
    setState(() {
      if (loc != null) {
        _latitude = loc.latitude;
        _longitude = loc.longitude;
        _locationName = loc.locationName.split(',').first.trim();
      }
      _method = method;
      _madhab = madhab;
      _loading = false;
    });
  }

  SalahTimeCalculator _calcFor(DateTime d) => SalahTimeCalculator(
        latitude: _latitude,
        longitude: _longitude,
        date: d,
        method: _method,
        madhab: _madhab,
      );

  String _fmt(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')}';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _shiftMonth(int delta) => setState(
        () => _month = DateTime(_month.year, _month.month + delta),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: PrayerPalette.accent),
      );
    }
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      physics: const BouncingScrollPhysics(),
      children: [
        _header(now),
        Transform.translate(
          offset: const Offset(0, -12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _todayCard(now),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
          child: Row(
            children: [
              const Text(
                'Full month',
                style: TextStyle(
                  color: PrayerPalette.ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '✦ = Jumu\'ah',
                style: TextStyle(
                  color: PrayerPalette.inkA(0.5),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _columnHeader(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(children: _monthRows(now)),
        ),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _header(DateTime now) {
    final hijriStart = HijriCalendar.fromDate(_month);
    final hijriEnd = HijriCalendar.fromDate(
      DateTime(_month.year, _month.month + 1, 0),
    );
    final banglaStart = BanglaDate.fromDate(_month);
    final banglaEnd = BanglaDate.fromDate(
      DateTime(_month.year, _month.month + 1, 0),
    );
    final hijriSpan = hijriStart.hMonth == hijriEnd.hMonth
        ? '${HijriNames.month(hijriStart.hMonth)} ${hijriStart.hYear}'
        : '${HijriNames.month(hijriStart.hMonth)} – '
            '${HijriNames.month(hijriEnd.hMonth)} ${hijriEnd.hYear}';
    final banglaSpan = banglaStart.monthName == banglaEnd.monthName
        ? banglaStart.monthName
        : '${banglaStart.monthName}–${banglaEnd.monthName}';

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16 + MediaQuery.of(context).padding.top,
        20,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            PrayerPalette.skyTop,
            PrayerPalette.skyMid,
            PrayerPalette.skyBottom,
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _circleButton(Icons.chevron_left_rounded, () => _shiftMonth(-1)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMMM y').format(_month),
                      style: const TextStyle(
                        color: PrayerPalette.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$hijriSpan · $banglaSpan '
                      '${BanglaDate.digits(banglaEnd.year)} · $_locationName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: PrayerPalette.inkA(0.6),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _circleButton(Icons.chevron_right_rounded, () => _shiftMonth(1)),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: _weekStrip(now)),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: PrayerPalette.ink.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: PrayerPalette.ink),
        ),
      );

  /// Seven days centred on today (or on the 1st when browsing another month).
  List<Widget> _weekStrip(DateTime now) {
    final anchor = _month.year == now.year && _month.month == now.month
        ? DateTime(now.year, now.month, now.day)
        : _month;
    final days = [for (var i = -3; i <= 3; i++) anchor.add(Duration(days: i))];

    return [
      for (var i = 0; i < days.length; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(child: _weekChip(days[i], now)),
      ],
    ];
  }

  Widget _weekChip(DateTime day, DateTime now) {
    final isToday = _sameDay(day, now);
    final isFriday = day.weekday == DateTime.friday && !isToday;
    final hijri = HijriCalendar.fromDate(day);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? PrayerPalette.ink : Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: isToday
              ? PrayerPalette.ink
              : isFriday
                  ? PrayerPalette.goldRule.withValues(alpha: 0.45)
                  : PrayerPalette.inkA(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: PrayerPalette.ink.withValues(alpha: isToday ? 0.3 : 0.06),
            blurRadius: isToday ? 14 : 6,
            offset: Offset(0, isToday ? 5 : 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            DateFormat('E').format(day).toUpperCase(),
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isToday
                  ? Colors.white.withValues(alpha: 0.75)
                  : PrayerPalette.inkA(0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isToday ? PrayerPalette.gold : PrayerPalette.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${hijri.hDay}',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: isToday
                  ? Colors.white.withValues(alpha: 0.6)
                  : PrayerPalette.inkA(0.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Today's five ────────────────────────────────────────────────────────

  Widget _todayCard(DateTime now) {
    final calc = _calcFor(now);
    final times = calc.getPrayerTimesMap();
    final bangla = BanglaDate.fromDate(now);
    final current = _currentPrayer(times, now);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PrayerPalette.ramadanFrom, PrayerPalette.ramadanTo],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: PrayerPalette.ink.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'TODAY · ${DateFormat('E d').format(now).toUpperCase()}',
                style: const TextStyle(
                  color: PrayerPalette.gold,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '· ${bangla.formatted}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => PrayerShareSheet.show(
                  context,
                  calculator: calc,
                  date: now,
                  locationName: _locationName,
                ),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.ios_share_rounded,
                        size: 13,
                        color: PrayerPalette.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Share',
                        style: TextStyle(
                          color: PrayerPalette.gold.withValues(alpha: 0.95),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              children: [
                for (var i = 0; i < _fard.length; i++)
                  Expanded(
                    child: Container(
                      decoration: i == _fard.length - 1
                          ? null
                          : BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color:
                                      Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                      child: Column(
                        children: [
                          Text(
                            _fard[i].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _fmt(times[_fard[i]]!),
                            style: TextStyle(
                              color: _fard[i] == current
                                  ? PrayerPalette.gold
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _currentPrayer(Map<String, DateTime> times, DateTime now) {
    String? current;
    for (final p in _fard) {
      final t = times[p];
      if (t != null && t.isBefore(now)) {
        current = p;
      } else {
        break;
      }
    }
    return current;
  }

  // ── Month list ──────────────────────────────────────────────────────────

  Widget _columnHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: PrayerPalette.ink.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 88),
          for (final p in _fard)
            Expanded(
              child: Text(
                p.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: PrayerPalette.inkA(0.55),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _monthRows(DateTime now) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    return [
      for (var d = 1; d <= daysInMonth; d++) ...[
        if (d > 1) const SizedBox(height: 6),
        _dayRow(DateTime(_month.year, _month.month, d), now),
      ],
    ];
  }

  Widget _dayRow(DateTime day, DateTime now) {
    final isToday = _sameDay(day, now);
    final isFriday = day.weekday == DateTime.friday;
    final times = _calcFor(day).getPrayerTimesMap();
    final hijri = HijriCalendar.fromDate(day);
    final bangla = BanglaDate.fromDate(day);

    final labelColor = isToday
        ? PrayerPalette.gold
        : isFriday
            ? PrayerPalette.fridayText
            : PrayerPalette.ink;
    final timeColor =
        isToday ? Colors.white : PrayerPalette.inkA(0.8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isToday
            ? PrayerPalette.ink
            : isFriday
                ? PrayerPalette.fridayBg
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday
              ? PrayerPalette.ink
              : isFriday
                  ? PrayerPalette.goldRule.withValues(alpha: 0.4)
                  : PrayerPalette.inkA(0.08),
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: PrayerPalette.ink.withValues(alpha: 0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isToday ? 'Today' : DateFormat('E d').format(day)}'
                  '${isFriday ? ' ✦' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${hijri.hDay} ${HijriNames.shortMonth(hijri.hMonth)} · '
                  '${BanglaDate.digits(bangla.day)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isToday
                        ? Colors.white.withValues(alpha: 0.7)
                        : PrayerPalette.inkA(0.5),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          for (final p in _fard)
            Expanded(
              child: Text(
                _fmt(times[p]!),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: timeColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
