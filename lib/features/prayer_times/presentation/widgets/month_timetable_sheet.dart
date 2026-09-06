import 'dart:io';
import 'dart:ui' as ui;

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/salah_time_calculator.dart';
import '../utils/bangla_date.dart';
import '../utils/hijri_names.dart';
import '../utils/prayer_palette.dart';
import 'prayer_snack.dart';
import '../../../../core/utils/local_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/prayer_l10n.dart';

/// Preview-and-share for a whole month's timetable, as an A4-proportioned
/// (794×1123) sheet suitable for printing or forwarding to a mosque group.
class MonthTimetableSheet {
  static Future<void> show(
    BuildContext context, {
    required DateTime month,
    required double latitude,
    required double longitude,
    required CalculationMethod method,
    required Madhab madhab,
    required String locationName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Sheet(
        month: month,
        latitude: latitude,
        longitude: longitude,
        method: method,
        madhab: madhab,
        locationName: locationName,
      ),
    );
  }
}

class _Sheet extends StatefulWidget {
  final DateTime month;
  final double latitude;
  final double longitude;
  final CalculationMethod method;
  final Madhab madhab;
  final String locationName;

  const _Sheet({
    required this.month,
    required this.latitude,
    required this.longitude,
    required this.method,
    required this.madhab,
    required this.locationName,
  });

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    // Captured before the first await; the context is gone by the time the
    // share sheet returns.
    final caption = L
        .of(context)
        .calMonthShareCaption(
          DateFormat('MMMM y').format(widget.month),
          widget.locationName,
        );
    final encodeError = L.of(context).calEncodeFailed;
    final shareError = L.of(context).calShareFailed;

    setState(() => _busy = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      // Rendered at 2× so the dense table stays legible when printed.
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw Exception(encodeError);

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/prayer-timetable-'
        '${DateFormat('yyyy-MM').format(widget.month)}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: caption),
      );
    } catch (e) {
      if (!mounted) return;
      PrayerSnack.show(
        context,
        shareError,
        kind: PrayerSnackKind.error,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = ((media.size.width - 48) / 794).clamp(0.05, 1.0);

    return Container(
      padding: EdgeInsets.only(bottom: 16 + media.padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: PrayerPalette.inkA(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            L
                .of(context)
                .calShareMonthTitle(DateFormat('MMMM').format(widget.month)),
            style: const TextStyle(
              color: PrayerPalette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 794 * scale,
            height: 1123 * scale,
            child: FittedBox(
              fit: BoxFit.contain,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: MonthTimetableCard(
                  month: widget.month,
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                  method: widget.method,
                  madhab: widget.madhab,
                  locationName: widget.locationName,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _share,
                style: FilledButton.styleFrom(
                  backgroundColor: PrayerPalette.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(
                  _busy
                      ? L.of(context).calPreparing
                      : L.of(context).calShareTimetable,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The printable A4 sheet: a gradient rule, the month heading, a dark column
/// header and one row per day with Hijri and Bengali dates alongside.
class MonthTimetableCard extends StatelessWidget {
  final DateTime month;
  final double latitude;
  final double longitude;
  final CalculationMethod method;
  final Madhab madhab;
  final String locationName;

  const MonthTimetableCard({
    super.key,
    required this.month,
    required this.latitude,
    required this.longitude,
    required this.method,
    required this.madhab,
    required this.locationName,
  });

  /// English keys; [prayerLabel] renders them.
  static const _columns = [
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  String _fmt(DateTime t) => DateFormat('h:mm').format(t);

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final hijriStart = HijriCalendar.fromDate(month);
    final hijriEnd = HijriCalendar.fromDate(
      DateTime(month.year, month.month + 1, 0),
    );
    final banglaStart = BanglaDate.fromDate(month);
    final banglaEnd = BanglaDate.fromDate(
      DateTime(month.year, month.month + 1, 0),
    );
    // A Gregorian month spans two Bangla months more often than not.
    final banglaSpan = banglaStart.monthName == banglaEnd.monthName
        ? banglaStart.monthName
        : '${banglaStart.monthName}–${banglaEnd.monthName}';
    final madhabLabel = madhab == Madhab.hanafi
        ? L.of(context).madhabHanafi
        : L.of(context).madhabShafi;

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Container(
        width: 794,
        height: 1123,
        color: const Color(0xFFFDFBF4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 12,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    PrayerPalette.ink,
                    PrayerPalette.accent,
                    PrayerPalette.goldRule,
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(46, 26, 46, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Centred above the heading — the conventional place for the
                  // bismillah on a printed sheet, rather than crowding the
                  // top-right corner.
                  Center(
                    child: SizedBox(
                      width: 340,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '\uFDFD',
                          textDirection: ui.TextDirection.rtl,
                          style: PrayerPalette.arabic(
                            fontSize: 96,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM y').format(month),
                        style: const TextStyle(
                          color: PrayerPalette.ink,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Hijri and Bangla get their own line: sharing the
                      // title row left too little width and truncated them.
                      Text(
                        '${HijriNames.monthFor(context, hijriStart.hMonth)} – '
                        '${HijriNames.monthFor(context, hijriEnd.hMonth)} '
                        '${N.plain(hijriEnd.hYear)}  ·  $banglaSpan '
                        '${BanglaDate.digits(banglaEnd.year)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFB8901E),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        L
                            .of(context)
                            .calTimetableHeader(locationName, madhabLabel),
                        style: TextStyle(
                          color: PrayerPalette.inkA(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(46, 20, 46, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: PrayerPalette.ink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        L.of(context).calDate,
                        style: TextStyle(
                          color: PrayerPalette.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: Text(
                        L.of(context).calHijriBangla,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    for (final c in _columns)
                      Expanded(
                        child: Text(
                          prayerLabel(context, c).toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(46, 6, 46, 0),
                child: Column(
                  children: [
                    for (var d = 1; d <= daysInMonth; d++)
                      Expanded(
                        child: _row(
                          context,
                          DateTime(month.year, month.month, d),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(46, 12, 46, 26),
              child: Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: PrayerPalette.inkA(0.12)),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.asset(
                        'assets/icon/icon.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        cacheWidth: 72,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'LifeQue',
                      style: TextStyle(
                        color: PrayerPalette.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      L.of(context).calFridayNote,
                      style: TextStyle(
                        color: PrayerPalette.inkA(0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, DateTime day) {
    final calc = SalahTimeCalculator(
      latitude: latitude,
      longitude: longitude,
      date: day,
      method: method,
      madhab: madhab,
    );
    final times = calc.getPrayerTimesMap();
    final hijri = HijriCalendar.fromDate(day);
    final bangla = BanglaDate.fromDate(day);
    final isFriday = day.weekday == DateTime.friday;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // No "today" highlight: this sheet is printed or forwarded, and the
        // marker would be wrong for anyone reading it on another day.
        color: isFriday
            ? const Color(0xFFF7EFD8)
            : day.day.isEven
            ? PrayerPalette.inkA(0.035)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              '${DateFormat('E d').format(day)}${isFriday ? ' ✦' : ''}',
              style: TextStyle(
                color: isFriday ? PrayerPalette.fridayText : PrayerPalette.ink,
                fontSize: 12.5,
                fontWeight: isFriday ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              '${N.of(hijri.hDay)} ${HijriNames.shortMonthFor(context, hijri.hMonth)} · '
              '${BanglaDate.digits(bangla.day)} ${bangla.monthName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: PrayerPalette.inkA(0.55),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final key in const [
            'Fajr',
            'Sunrise',
            'Dhuhr',
            'Asr',
            'Maghrib',
            'Isha',
          ])
            Expanded(
              child: Text(
                _fmt(times[key]!),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: key == 'Sunrise'
                      ? PrayerPalette.inkA(0.6)
                      : const Color(0xFF1B2A1F),
                  fontSize: 12.5,
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
