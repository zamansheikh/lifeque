import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MosqueWidgetUI extends StatelessWidget {
  final String hijriDate;
  final String gregorianDate;
  final String locationName;
  final Map<String, String>
  mosqueTimes; // {Fajr: "5:00 AM", Dhuhr: "1:30 PM", ...}
  final String? currentPrayer;

  const MosqueWidgetUI({
    super.key,
    required this.hijriDate,
    required this.gregorianDate,
    required this.locationName,
    required this.mosqueTimes,
    this.currentPrayer,
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
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
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

            // Decorative crescent
            Positioned(
              right: 14,
              top: 10,
              child: Icon(
                Icons.mosque,
                size: 28,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: Title + Updated time ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Mosque Jamaat label
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.access_time_filled,
                              color: Color(0xFFFFD54F),
                              size: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Mosque Jamaat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      // Right: Updated time
                      Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: Text(
                          'Updated: ${DateFormat('hh:mm a').format(DateTime.now())}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 9,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ── Hijri + Gregorian date ──
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      '$hijriDate  •  $gregorianDate',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ── Prayer times row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPrayerColumn(
                        'Fajr',
                        'ফজর',
                        mosqueTimes['Fajr'] ?? '--',
                      ),
                      _buildDivider(),
                      _buildPrayerColumn(
                        'Dhuhr',
                        'যোহর',
                        mosqueTimes['Dhuhr'] ?? '--',
                      ),
                      _buildDivider(),
                      _buildPrayerColumn(
                        'Asr',
                        'আছর',
                        mosqueTimes['Asr'] ?? '--',
                      ),
                      _buildDivider(),
                      _buildPrayerColumn(
                        'Maghrib',
                        'মাগরিব',
                        mosqueTimes['Maghrib'] ?? '--',
                      ),
                      _buildDivider(),
                      _buildPrayerColumn(
                        'Isha',
                        'এশা',
                        mosqueTimes['Isha'] ?? '--',
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerColumn(String name, String bangla, String time) {
    final isCurrent = currentPrayer?.toLowerCase() == name.toLowerCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          bangla,
          style: TextStyle(
            color: isCurrent
                ? const Color(0xFFFFD54F)
                : Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: isCurrent
              ? BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                )
              : null,
          child: Text(
            time,
            style: TextStyle(
              color: isCurrent ? const Color(0xFFFFD54F) : Colors.white,
              fontSize: 13,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

/// Paints a simple mosque silhouette at the bottom of the widget
class _MosqueSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D1442)
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
