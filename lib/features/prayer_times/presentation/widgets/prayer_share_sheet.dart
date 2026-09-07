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
import 'share_art.dart';
import '../../../../core/utils/local_numbers.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/prayer_l10n.dart';
import '../../../../core/utils/local_clock.dart';

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
    // Read the caption before the first await — the share sheet and the file
    // write are async gaps, and the context may be gone on the far side.
    final caption =
        '${L.of(context).shareCaption(DateFormat('MMMM d, y').format(widget.date))}'
        ' · ${widget.locationName}';
    final encodeError = L.of(context).shareEncodeFailed;

    setState(() => _busy = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      // The card is laid out at 1080 logical px and painted at 1:1, so no
      // extra pixelRatio is needed to hit the 1080×1350 target.
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw Exception(encodeError);

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/prayer-times-'
        // Latin digits in the file name whatever the UI language — share
        // targets and file pickers do not all cope with Bangla ones.
        '${DateFormat('yyyy-MM-dd', 'en_US').format(widget.date)}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: caption),
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
          Text(
            L.of(context).shareTodayTimes,
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
                label: Text(
                  _busy ? L.of(context).calPreparing : L.of(context).shareImage,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 1080×1350 social card.
///
/// A night sky that warms into dawn over a mosque skyline, the five waqts as
/// gold-on-green rows beneath it, and the ayah on fixed prayer times at the
/// foot — so the picture says something worth passing on, not only when.
/// 4:5, the tallest ratio Instagram and Facebook show uncropped in a feed.
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
    'Fajr': Icons.nightlight_round,
    'Dhuhr': Icons.wb_sunny_rounded,
    'Asr': Icons.wb_twilight_rounded,
    'Maghrib': Icons.brightness_4_rounded,
    'Isha': Icons.bedtime_rounded,
  };

  static const _night = Color(0xFF05130E);
  static const _deep = Color(0xFF0E3A29);
  static const _panel = Color(0xFF0A2519);
  static const _gold = PrayerPalette.gold;
  static const _ayah =
      'إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا';

  String _fmt(DateTime t) => Clock.h12(t);

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final times = calculator.getPrayerTimesMap();

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Container(
        width: 1080,
        height: 1350,
        color: _panel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 500, child: _sky(context)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(72, 30, 72, 34),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _fard.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _row(context, _fard[i], times[_fard[i]]!),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _pill(
                            Icons.wb_sunny_outlined,
                            l.shareSunrise,
                            _fmt(times['Sunrise']!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _pill(
                            Icons.nightlight_outlined,
                            l.shareSahriEnds,
                            _fmt(times['Fajr']!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _pill(
                            Icons.restaurant_rounded,
                            l.shareIftar,
                            _fmt(times['Maghrib']!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ayahBlock(l),
                    const Spacer(),
                    _footer(l),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── The sky ─────────────────────────────────────────────────────────────

  Widget _sky(BuildContext context) {
    final l = L.of(context);
    final hijri = HijriCalendar.fromDate(date);
    final bangla = BanglaDate.fromDate(date);
    final isFriday = date.weekday == DateTime.friday;

    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_night, _deep, Color(0xFF6E6A32), Color(0xFFE9B85C)],
              stops: [0.0, 0.5, 0.84, 1.0],
            ),
          ),
        ),
        const CustomPaint(painter: StarfieldPainter(fadeBy: 0.62)),
        // The rising sun, half behind the skyline.
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gold.withValues(alpha: 0.95),
                    _gold.withValues(alpha: 0.35),
                    _gold.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Sized so the heading block, location pill included, ends above the
        // central dome's finial rather than sitting on it.
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 150,
          child: CustomPaint(painter: MosqueSkylinePainter(color: _panel)),
        ),
        const Positioned(
          top: 62,
          left: 84,
          child: SizedBox(
            width: 82,
            height: 82,
            child: CustomPaint(painter: CrescentPainter(color: _gold)),
          ),
        ),
        if (isFriday)
          Positioned(
            top: 70,
            right: 72,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                l.shareFridayBadge,
                style: const TextStyle(
                  color: _night,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        Positioned(
          top: 44,
          left: 72,
          right: 72,
          child: Column(
            children: [
              // Amiri draws U+FDFD as one very wide ligature; give it a slot
              // narrower than the gap between the moon and the badge.
              SizedBox(
                width: 460,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '﷽',
                    textDirection: ui.TextDirection.rtl,
                    style: PrayerPalette.arabic(
                      fontSize: 110,
                      height: 1.0,
                      color: _gold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.shareCardTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 76,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${BanglaDate.weekdayName(date)}, '
                '${N.of(hijri.hDay)} '
                '${HijriNames.monthFor(context, hijri.hMonth)} '
                '${N.plain(hijri.hYear)} · '
                '${DateFormat('d MMMM y').format(date)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${bangla.formatted} বঙ্গাব্দ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place_rounded, size: 22, color: _gold),
                    const SizedBox(width: 8),
                    Text(
                      locationName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── The timetable ───────────────────────────────────────────────────────

  /// Every prayer renders identically. The card is a timetable people send
  /// to others, so marking "now" would be wrong the moment it's forwarded.
  Widget _row(BuildContext context, String name, DateTime time) {
    return Container(
      height: 84,
      padding: const EdgeInsets.only(left: 22, right: 30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withValues(alpha: 0.16),
              border: Border.all(color: _gold.withValues(alpha: 0.55)),
            ),
            child: Icon(_glyphs[name], size: 28, color: _gold),
          ),
          const SizedBox(width: 22),
          Text(
            prayerLabel(context, name),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(
            _fmt(time),
            style: const TextStyle(
              color: _gold,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, String value) => Container(
    height: 72,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _gold.withValues(alpha: 0.28)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: _gold),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: _gold,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _ayahBlock(L l) => Column(
    children: [
      // One line, scaled to fit: the ayah must never wrap mid-phrase.
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          _ayah,
          textDirection: ui.TextDirection.rtl,
          style: PrayerPalette.arabic(fontSize: 34, height: 1.5, color: _gold),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        l.shareAyahTranslation,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 21,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '— ${l.shareAyahRef}',
        style: TextStyle(
          color: _gold.withValues(alpha: 0.8),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _footer(L l) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/icon/icon.png',
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          // The source is 2048², far more than the slot needs.
          cacheWidth: 132,
        ),
      ),
      const SizedBox(width: 12),
      const Text(
        'LifeQue',
        style: TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(width: 10),
      Text(
        '· ${l.shareTagline}',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
