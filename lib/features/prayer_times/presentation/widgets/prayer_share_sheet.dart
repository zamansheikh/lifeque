import 'dart:io';
import 'dart:ui' as ui;

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

/// Preview-and-share for the day's prayer times.
///
/// Shows the 1080×1350 share card scaled to fit, then rasterises it at full
/// resolution and hands it to the platform share sheet.
class PrayerShareSheet {
  static Future<void> show(
    BuildContext context, {
    required SalahTimeCalculator calculator,
    required DateTime date,
    required String locationName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(
        calculator: calculator,
        date: date,
        locationName: locationName,
      ),
    );
  }
}

class _ShareSheet extends StatefulWidget {
  final SalahTimeCalculator calculator;
  final DateTime date;
  final String locationName;

  const _ShareSheet({
    required this.calculator,
    required this.date,
    required this.locationName,
  });

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _boundaryKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      // The card is laid out at 1080 logical px and painted at 1:1, so no
      // extra pixelRatio is needed to hit the 1080×1350 target.
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw Exception('Could not encode the card');

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/prayer-times-'
        '${DateFormat('yyyy-MM-dd').format(widget.date)}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              'Prayer times · ${DateFormat('MMMM d, y').format(widget.date)}'
              ' · ${widget.locationName}',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      PrayerSnack.show(
        context,
        'Could not share the card: $e',
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
    // Fit the 1080-wide card into the sheet, leaving room for the controls.
    final scale = ((media.size.width - 48) / 1080).clamp(0.05, 1.0);

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
          const Text(
            'Share today\'s times',
            style: TextStyle(
              color: PrayerPalette.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          // Painted off-screen at full size, displayed scaled down.
          SizedBox(
            width: 1080 * scale,
            height: 1350 * scale,
            child: FittedBox(
              fit: BoxFit.contain,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: PrayerShareCard(
                  calculator: widget.calculator,
                  date: widget.date,
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
                label: Text(_busy ? 'Preparing…' : 'Share image'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 1080×1350 social card: dawn gradient, the five waqts, and a sunrise /
/// sahri / iftar footer strip.
class PrayerShareCard extends StatelessWidget {
  final SalahTimeCalculator calculator;
  final DateTime date;
  final String locationName;

  const PrayerShareCard({
    super.key,
    required this.calculator,
    required this.date,
    required this.locationName,
  });

  static const _fard = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  static const _glyphs = {
    'Fajr': Icons.nightlight_outlined,
    'Dhuhr': Icons.wb_sunny_outlined,
    'Asr': Icons.wb_sunny_outlined,
    'Maghrib': Icons.brightness_4_outlined,
    'Isha': Icons.nightlight_outlined,
  };

  String _fmt(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} '
        '${t.hour < 12 ? 'am' : 'pm'}';
  }

  @override
  Widget build(BuildContext context) {
    final times = calculator.getPrayerTimesMap();
    final hijri = HijriCalendar.fromDate(date);
    final bangla = BanglaDate.fromDate(date);

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Container(
        width: 1080,
        height: 1350,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PrayerPalette.skyTop,
              Color(0xFFEDF6E0),
              Color(0xFFF7FBF5),
              Color(0xFFFDFBF4),
            ],
            stops: [0.0, 0.34, 0.62, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 118,
              right: 154,
              child: Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF2CE6B),
                ),
              ),
            ),
            Positioned(
              top: 330,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 150,
                child: CustomPaint(painter: _CardHillsPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(96, 62, 96, 54),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Amiri draws U+FDFD as one very wide calligraphic
                  // ligature — far wider than the card's 888px content box,
                  // so unconstrained it painted outside the card and came out
                  // clipped in the exported PNG. Give it a fixed slot.
                  SizedBox(
                    // Stops short of the decorative sun at the card's top
                    // right, which sits 154px in from that edge.
                    width: 600,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '\uFDFD',
                        textDirection: ui.TextDirection.rtl,
                        style: PrayerPalette.arabic(fontSize: 150, height: 1.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Prayer Times',
                    style: TextStyle(
                      color: PrayerPalette.ink,
                      fontSize: 66,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${DateFormat('EEEE').format(date)}, ${hijri.hDay} '
                    '${HijriNames.month(hijri.hMonth)} ${hijri.hYear} · '
                    '${DateFormat('MMM d, y').format(date)}',
                    style: TextStyle(
                      color: PrayerPalette.inkA(0.7),
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${BanglaDate.weekdayName(date)}, ${bangla.formatted} '
                    'বঙ্গাব্দ',
                    style: const TextStyle(
                      color: Color(0xFFB8901E),
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.place,
                        size: 22,
                        color: PrayerPalette.accent,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        locationName,
                        style: const TextStyle(
                          color: PrayerPalette.accent,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _divider(),
                  // The hill silhouette sits behind this band, so the first
                  // row needs clearance or it reads as colliding with it.
                  const SizedBox(height: 44),
                  for (var i = 0; i < _fard.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _row(_fard[i], times[_fard[i]]!),
                  ],
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: _footerTile(
                          '☀ SUNRISE',
                          _fmt(times['Sunrise']!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _footerTile(
                          '☾ SAHRI ENDS',
                          _fmt(times['Fajr']!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _footerTile('✦ IFTAR', _fmt(times['Maghrib']!)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          'assets/icon/icon.png',
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          // The source is 2048², far more than the 52pt slot
                          // needs; decode it small rather than re-encoding
                          // the launcher icon itself.
                          cacheWidth: 156,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'LifeQue',
                        style: TextStyle(
                          color: PrayerPalette.ink,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '· your prayer companion',
                        style: TextStyle(
                          color: PrayerPalette.inkA(0.55),
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _divider() => Row(
    children: [
      Expanded(
        child: Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PrayerPalette.goldRule.withValues(alpha: 0),
                PrayerPalette.goldRule.withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Text(
          '✦',
          style: TextStyle(color: PrayerPalette.goldDeep, fontSize: 26),
        ),
      ),
      Expanded(
        child: Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PrayerPalette.goldRule.withValues(alpha: 0.6),
                PrayerPalette.goldRule.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  /// Every prayer renders identically. The card is a timetable people send
  /// to others, so marking "now" would be wrong the moment it's forwarded.
  Widget _row(String name, DateTime time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: PrayerPalette.inkA(0.10), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: PrayerPalette.ink.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Icon(_glyphs[name], size: 34, color: PrayerPalette.goldDeep),
          ),
          const SizedBox(width: 18),
          Text(
            name,
            style: const TextStyle(
              color: PrayerPalette.ink,
              fontSize: 37,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            _fmt(time),
            style: const TextStyle(
              color: PrayerPalette.ink,
              fontSize: 41,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerTile(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: PrayerPalette.goldRule.withValues(alpha: 0.3)),
    ),
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              color: PrayerPalette.goldDeep,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: PrayerPalette.ink,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The two stacked hill bands behind the card's heading.
class _CardHillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 1080.0;
    final sy = size.height / 150.0;

    Path band(List<List<double>> curves, double startY) {
      final p = Path()
        ..moveTo(0, size.height)
        ..lineTo(0, startY * sy);
      for (final c in curves) {
        p.quadraticBezierTo(c[0] * sx, c[1] * sy, c[2] * sx, c[3] * sy);
      }
      return p
        ..lineTo(size.width, size.height)
        ..close();
    }

    canvas.drawPath(
      band([
        [140, 30, 300, 78],
        [430, 116, 600, 58],
        [760, 8, 900, 64],
        [990, 96, 1080, 72],
      ], 96),
      Paint()..color = PrayerPalette.inkA(0.10),
    );
    canvas.drawPath(
      band([
        [230, 72, 470, 108],
        [700, 142, 920, 96],
        [1000, 106, 1080, 116],
      ], 122),
      Paint()..color = PrayerPalette.inkA(0.07),
    );
  }

  @override
  bool shouldRepaint(_CardHillsPainter oldDelegate) => false;
}
