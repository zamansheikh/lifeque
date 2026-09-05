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
  final String? endTimeStr;
  final String? nextPrayerName;
  final String? nextPrayerTimeStr;
  final String? activeProhibited; // e.g. "Sunrise 6:15-6:30" or null

  const PrayerWidgetUI({
    super.key,
    required this.hijriDate,
    required this.gregorianDate,
    required this.currentPrayerName,
    required this.timeRange,
    required this.prayerTimes,
    required this.nextPrayer,
    required this.locationName,
    this.endTimeStr,
    this.nextPrayerName,
    this.nextPrayerTimeStr,
    this.activeProhibited,
  });

  @override
  Widget build(BuildContext context) {
    final tf = DateFormat('h:mm a');

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
                size: const Size(380, 45),
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
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
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
                                    size: 13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    hijriDate,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Padding(
                              padding: const EdgeInsets.only(left: 26),
                              child: Text(
                                gregorianDate,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right: Updated time
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Text(
                          'Updated: ${tf.format(DateTime.now())}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 8,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ── Middle: Current prayer + end time | Next prayer ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Left: Current prayer name + time range + end time
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentPrayerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              timeRange,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (endTimeStr != null) ...[
                              const SizedBox(height: 1),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    size: 10,
                                    color: Colors.orange.shade300,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Ends: $endTimeStr',
                                    style: TextStyle(
                                      color: Colors.orange.shade300,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Right: Info column
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Next prayer
                            if (nextPrayerName != null &&
                                nextPrayerTimeStr != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.skip_next_rounded,
                                      size: 12,
                                      color: const Color(0xFF90EE90),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$nextPrayerName $nextPrayerTimeStr',
                                      style: const TextStyle(
                                        color: Color(0xFF90EE90),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            // Sunrise / Sunset
                            _buildInfoRow('Sunrise', prayerTimes.sunrise),
                            const SizedBox(height: 2),
                            _buildInfoRow('Sunset', prayerTimes.maghrib),
                            const SizedBox(height: 2),
                            _buildInfoRow('Sahri', prayerTimes.fajr),
                            const SizedBox(height: 2),
                            _buildInfoRow('Iftar', prayerTimes.maghrib),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Bottom: Prohibited time indicator ──
                  if (activeProhibited != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.block,
                            size: 10,
                            color: Colors.red.shade200,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '🚫 $activeProhibited',
                            style: TextStyle(
                              color: Colors.red.shade200,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

  Widget _buildInfoRow(String label, DateTime? time) {
    if (time == null) return const SizedBox();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          DateFormat('h:mm a').format(time),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
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
