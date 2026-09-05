import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../../../../core/utils/salah_time_calculator.dart';
import '../../data/services/prayer_settings_service.dart';
import '../utils/prayer_palette.dart';

/// Qibla compass: a dial that counter-rotates with the device heading so the
/// Kaaba marker always points at Makkah.
class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  final _settings = PrayerSettingsService.instance;

  double _latitude = 23.8103;
  double _longitude = 90.4125;
  String _locationName = 'Dhaka, Bangladesh';
  double _qiblaBearing = 0;
  double? _heading;
  StreamSubscription<CompassEvent>? _compassSub;
  bool _loading = true;

  /// Kaaba, for the great-circle distance readout.
  static const _makkahLat = 21.4225;
  static const _makkahLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _load();
    _compassSub = FlutterCompass.events?.listen((event) {
      if (mounted) setState(() => _heading = event.heading);
    });
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
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
        _locationName = loc.locationName;
      }
      _qiblaBearing = SalahTimeCalculator(
        latitude: _latitude,
        longitude: _longitude,
        date: DateTime.now(),
        method: method,
        madhab: madhab,
      ).getQiblaDirection();
      _loading = false;
    });
  }

  /// Great-circle distance to the Kaaba in kilometres.
  double get _distanceKm {
    const earthRadius = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(_makkahLat - _latitude);
    final dLng = rad(_makkahLng - _longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(_latitude)) *
            math.cos(rad(_makkahLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Where the Kaaba sits on screen: the bearing, offset by the heading so
  /// the marker stays put as the phone turns.
  double get _markerDegrees => _qiblaBearing - (_heading ?? 0);

  bool get _isAligned {
    final delta = (_markerDegrees % 360).abs();
    return delta < 8 || delta > 352;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: PrayerPalette.accent),
      );
    }

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const Text(
              'Qibla Compass',
              style: TextStyle(
                color: PrayerPalette.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$_locationName · hold your phone flat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PrayerPalette.inkA(0.55),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 26),
            _dial(),
            const SizedBox(height: 24),
            Text(
              '${_qiblaBearing.round()}°',
              style: const TextStyle(
                color: PrayerPalette.ink,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'from North · ${_distanceKm.round()} km to Makkah',
              style: TextStyle(
                color: PrayerPalette.inkA(0.55),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: _isAligned
                    ? PrayerPalette.accentA(0.10)
                    : PrayerPalette.inkA(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _heading == null
                    ? 'No compass on this device — bearing shown above'
                    : _isAligned
                    ? '✓ Aligned — you are facing the Qibla'
                    : '✓ Aligned when the Kaaba points up',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isAligned
                      ? PrayerPalette.accent
                      : PrayerPalette.inkA(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dial() {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: PrayerPalette.inkA(0.08)),
              boxShadow: [
                BoxShadow(
                  color: PrayerPalette.ink.withValues(alpha: 0.14),
                  blurRadius: 36,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: CustomPaint(
              size: const Size.square(222),
              painter: _DashedRingPainter(),
            ),
          ),
          _cardinal('N', Alignment.topCenter, PrayerPalette.accent, 13),
          _cardinal('S', Alignment.bottomCenter, PrayerPalette.inkA(0.4), 12),
          _cardinal('W', Alignment.centerLeft, PrayerPalette.inkA(0.4), 12),
          _cardinal('E', Alignment.centerRight, PrayerPalette.inkA(0.4), 12),
          AnimatedRotation(
            turns: _markerDegrees / 360,
            duration: const Duration(milliseconds: 400),
            child: Transform.translate(
              offset: const Offset(0, -62),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.navigation,
                    size: 30,
                    color: _isAligned
                        ? PrayerPalette.accent
                        : PrayerPalette.accentA(0.75),
                  ),
                  const Text('🕋', style: TextStyle(fontSize: 17)),
                ],
              ),
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: PrayerPalette.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardinal(String label, Alignment at, Color color, double size) =>
      Align(
        alignment: at,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
}

class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = PrayerPalette.inkA(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    // 60 dashes with 60 equal gaps around the circle.
    const dashes = 60;
    const sweep = math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * 2 * sweep,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter oldDelegate) => false;
}
