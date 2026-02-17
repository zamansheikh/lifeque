import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrayerWidgetUI extends StatelessWidget {
  final String hijriDate;
  final String gregorianDate;
  final String currentPrayerName;
  final String timeRange;
  final PrayerTimes prayerTimes;
  final Prayer nextPrayer;
  final String locationName;

  const PrayerWidgetUI({
    super.key,
    required this.hijriDate,
    required this.gregorianDate,
    required this.currentPrayerName,
    required this.timeRange,
    required this.prayerTimes,
    required this.nextPrayer,
    required this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D4F4F), Color(0xFF0A6B5C), Color(0xFF0E7E6B)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Mosque silhouette at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: -2,
              child: CustomPaint(
                size: const Size(380, 50),
                painter: _MosqueSilhouettePainter(),
              ),
            ),

            // Moon icon (top-right area)
            Positioned(
              right: 50,
              top: 48,
              child: Icon(
                Icons.nightlight_round,
                size: 38,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: Hijri date + Updated time ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Hijri + Gregorian dates
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.mosque,
                                    color: Color(0xFF90EE90),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    hijriDate,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Padding(
                              padding: const EdgeInsets.only(left: 28),
                              child: Text(
                                gregorianDate,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right: Updated time
                      Text(
                        'Updated: ${DateFormat('hh:mm a').format(DateTime.now())}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Bottom row: Prayer name + times list ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Left side: Current prayer + time range
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentPrayerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeRange,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right side: Sunrise / Sunset / Sahri / Iftar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInfoRow('Sunrise', prayerTimes.sunrise),
                          const SizedBox(height: 3),
                          _buildInfoRow('Sunset', prayerTimes.maghrib),
                          const SizedBox(height: 3),
                          _buildInfoRow('Sahri', prayerTimes.fajr),
                          const SizedBox(height: 3),
                          _buildInfoRow('Iftar', prayerTimes.maghrib),
                        ],
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

  Widget _buildInfoRow(String label, DateTime? time) {
    if (time == null) return const SizedBox();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          DateFormat('hh:mm').format(time),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Paints a simple mosque silhouette at the bottom of the widget
class _MosqueSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF063D3D)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Ground line
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.6);

    // Left small dome
    path.lineTo(size.width * 0.05, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.08,
      size.height * 0.2,
      size.width * 0.11,
      size.height * 0.6,
    );

    // Left minaret
    path.lineTo(size.width * 0.14, size.height * 0.6);
    path.lineTo(size.width * 0.145, size.height * 0.15);
    path.lineTo(size.width * 0.155, size.height * 0.05);
    path.lineTo(size.width * 0.165, size.height * 0.15);
    path.lineTo(size.width * 0.17, size.height * 0.6);

    // Center large dome
    path.lineTo(size.width * 0.22, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.30,
      size.height * -0.3,
      size.width * 0.38,
      size.height * 0.6,
    );

    // Right minaret
    path.lineTo(size.width * 0.41, size.height * 0.6);
    path.lineTo(size.width * 0.415, size.height * 0.15);
    path.lineTo(size.width * 0.425, size.height * 0.05);
    path.lineTo(size.width * 0.435, size.height * 0.15);
    path.lineTo(size.width * 0.44, size.height * 0.6);

    // Right small dome
    path.lineTo(size.width * 0.47, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.50,
      size.height * 0.2,
      size.width * 0.53,
      size.height * 0.6,
    );

    // Flat ground to end
    path.lineTo(size.width, size.height * 0.6);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
