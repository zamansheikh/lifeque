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
import 'share_art.dart';
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
        '${DateFormat('yyyy-MM', 'en_US').format(widget.month)}.png',
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

/// The printable A4 sheet: a night-sky header over a mosque skyline, the
/// month in three calendars, then one row per day with Fridays picked out
/// in gold. Dense on purpose — it is pinned on mosque noticeboards.
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

  static const _night = Color(0xFF05130E);
  static const _deep = Color(0xFF0E3A29);
  static const _paper = Color(0xFFFBF8EF);
  static const _gold = PrayerPalette.gold;
  static const _fridayBg = Color(0xFFFBF0CF);

  String _fmt(DateTime t) => DateFormat('h:mm').format(t);

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
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
    final hijriSpan = hijriStart.hMonth == hijriEnd.hMonth
        ? HijriNames.monthFor(context, hijriStart.hMonth)
        : '${HijriNames.monthFor(context, hijriStart.hMonth)} – '
              '${HijriNames.monthFor(context, hijriEnd.hMonth)}';
    final madhabLabel = madhab == Madhab.hanafi
        ? l.madhabHanafi
        : l.madhabShafi;

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Container(
        width: 794,
        height: 1123,
        color: _paper,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 232,
              child: _header(
                context,
                hijriSpan,
                hijriEnd,
                banglaSpan,
                banglaEnd,
                madhabLabel,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 16, 40, 0),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: PrayerPalette.inkA(0.10)),
                    boxShadow: [
                      BoxShadow(
                        color: PrayerPalette.ink.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _columnHeader(context),
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 12, 40, 22),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 26,
                      height: 26,
                      fit: BoxFit.cover,
                      cacheWidth: 78,
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
                  const SizedBox(width: 6),
                  Text(
                    '· ${l.shareTagline}',
                    style: TextStyle(
                      color: PrayerPalette.inkA(0.5),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      l.calFridayNote,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      style: TextStyle(
                        color: PrayerPalette.inkA(0.55),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    String hijriSpan,
    HijriCalendar hijriEnd,
    String banglaSpan,
    BanglaDate banglaEnd,
    String madhabLabel,
  ) {
    final l = L.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_night, _deep, Color(0xFF7A6D34), Color(0xFFE9B85C)],
              stops: [0.0, 0.55, 0.88, 1.0],
            ),
          ),
        ),
        const CustomPaint(painter: StarfieldPainter(fadeBy: 0.6)),
        Positioned(
          right: 120,
          bottom: 30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _gold.withValues(alpha: 0.9),
                  _gold.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 84,
          child: CustomPaint(painter: MosqueSkylinePainter(color: _paper)),
        ),
        const Positioned(
          top: 22,
          right: 46,
          child: SizedBox(
            width: 44,
            height: 44,
            child: CustomPaint(painter: CrescentPainter(color: _gold)),
          ),
        ),
        Positioned(
          left: 40,
          top: 22,
          right: 110,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 230,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '﷽',
                    textDirection: ui.TextDirection.rtl,
                    style: PrayerPalette.arabic(
                      fontSize: 60,
                      height: 1.0,
                      color: _gold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.calTimetableTitle,
                style: TextStyle(
                  color: _gold.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('MMMM y').format(month),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$hijriSpan ${N.plain(hijriEnd.hYear)}  ·  '
                '$banglaSpan ${BanglaDate.digits(banglaEnd.year)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.place_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '$locationName  ·  $madhabLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _columnHeader(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    color: PrayerPalette.ink,
    child: Row(
      children: [
        SizedBox(
          width: 104,
          child: Text(
            L.of(context).calDate,
            style: const TextStyle(
              color: _gold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(
          width: 146,
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
              style: TextStyle(
                color: c == 'Sunrise'
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
      ],
    ),
  );

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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // No "today" highlight: this sheet is printed or forwarded, and the
        // marker would be wrong for anyone reading it on another day.
        color: isFriday
            ? _fridayBg
            : day.day.isEven
            ? PrayerPalette.inkA(0.035)
            : Colors.transparent,
        border: isFriday
            ? const Border(
                left: BorderSide(color: PrayerPalette.goldDeep, width: 3),
              )
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(
              '${DateFormat('E d').format(day)}${isFriday ? ' ✦' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isFriday ? PrayerPalette.fridayText : PrayerPalette.ink,
                fontSize: 12.5,
                fontWeight: isFriday ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 146,
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
          for (final key in _columns)
            Expanded(
              child: Text(
                _fmt(times[key]!),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: key == 'Sunrise'
                      ? PrayerPalette.inkA(0.5)
                      : const Color(0xFF1B2A1F),
                  fontSize: 12.5,
                  fontWeight: key == 'Sunrise'
                      ? FontWeight.w500
                      : FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
