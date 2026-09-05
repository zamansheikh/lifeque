import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MosqueWidgetUI extends StatelessWidget {
  final String hijriDate;
  final String gregorianDate;
  final String locationName;
  final Map<String, String> mosqueTimes;
  final String? currentPrayer;
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? sahri;
  final DateTime? iftar;
  final String? activeProhibited;

  const MosqueWidgetUI({
    super.key,
    required this.hijriDate,
    required this.gregorianDate,
    required this.locationName,
    required this.mosqueTimes,
    this.currentPrayer,
    this.sunrise,
    this.sunset,
    this.sahri,
    this.iftar,
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
                size: const Size(380, 40),
                painter: _MosqueSilhouettePainter(),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: Title + Info badges ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Title + date
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
                                    Icons.access_time_filled,
                                    color: Color(0xFFFFD54F),
                                    size: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Mosque Jamaat',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Padding(
                              padding: const EdgeInsets.only(left: 24),
                              child: Text(
                                '$hijriDate  •  $gregorianDate',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right: Updated + info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
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
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ── Middle: Sunrise / Sunset / Sahri / Iftar row ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (sunrise != null)
                        _buildInfoChip('☀️', 'Sunrise', tf.format(sunrise!)),
                      if (sunset != null) ...[
                        const SizedBox(width: 6),
                        _buildInfoChip('🌅', 'Sunset', tf.format(sunset!)),
                      ],
                      if (sahri != null) ...[
                        const SizedBox(width: 6),
                        _buildInfoChip('🍽', 'Sahri', tf.format(sahri!)),
                      ],
                      if (iftar != null) ...[
                        const SizedBox(width: 6),
                        _buildInfoChip('🌙', 'Iftar', tf.format(iftar!)),
                      ],
                    ],
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

                  const SizedBox(height: 2),

                  // ── Prohibited time banner ──
                  if (activeProhibited != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.block,
                            size: 9,
                            color: Colors.red.shade200,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '🚫 $activeProhibited',
                            style: TextStyle(
                              color: Colors.red.shade200,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (activeProhibited == null) const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String emoji, String label, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 9)),
          const SizedBox(width: 3),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 7,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
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
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
              fontSize: 12,
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
      height: 26,
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

    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.6);

    path.lineTo(size.width * 0.05, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.08,
      size.height * 0.2,
      size.width * 0.11,
      size.height * 0.6,
    );

    path.lineTo(size.width * 0.14, size.height * 0.6);
    path.lineTo(size.width * 0.145, size.height * 0.15);
    path.lineTo(size.width * 0.155, size.height * 0.05);
    path.lineTo(size.width * 0.165, size.height * 0.15);
    path.lineTo(size.width * 0.17, size.height * 0.6);

    path.lineTo(size.width * 0.22, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.30,
      size.height * -0.3,
      size.width * 0.38,
      size.height * 0.6,
    );

    path.lineTo(size.width * 0.41, size.height * 0.6);
    path.lineTo(size.width * 0.415, size.height * 0.15);
    path.lineTo(size.width * 0.425, size.height * 0.05);
    path.lineTo(size.width * 0.435, size.height * 0.15);
    path.lineTo(size.width * 0.44, size.height * 0.6);

    path.lineTo(size.width * 0.47, size.height * 0.6);
    path.quadraticBezierTo(
      size.width * 0.50,
      size.height * 0.2,
      size.width * 0.53,
      size.height * 0.6,
    );

    path.lineTo(size.width, size.height * 0.6);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
