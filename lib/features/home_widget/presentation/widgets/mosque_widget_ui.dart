import 'package:flutter/material.dart';

/// One jamaat chip: the prayer's Bengali name and the mosque's congregation
/// time. The current waqt's chip inverts to gold.
class JamaatChip {
  /// Bengali label, e.g. `ফজর`.
  final String label;

  /// e.g. `4:39 AM`.
  final String time;

  final bool isCurrent;

  const JamaatChip({
    required this.label,
    required this.time,
    required this.isCurrent,
  });
}

/// Variant 2 of the home-screen widget set: the mosque's jamaat timetable in
/// Bengali, over a sun/fast times strip.
class MosqueWidgetUI extends StatelessWidget {
  /// e.g. `23 Rabiʿ I 1448, Saturday · 5 September`.
  final String dateLine;

  /// Wall-clock time this render happened, e.g. `4:31 PM`.
  final String updatedAt;

  final String sunrise;
  final String sunset;
  final String sahri;
  final String iftar;

  final List<JamaatChip> jamaat;

  /// Exact render size — see [PrayerWidgetUI.size] for why this is explicit.
  final Size size;

  const MosqueWidgetUI({
    super.key,
    required this.size,
    required this.dateLine,
    required this.updatedAt,
    required this.sunrise,
    required this.sunset,
    required this.sahri,
    required this.iftar,
    required this.jamaat,
  });

  static const _gold = Color(0xFFF5D27A);
  static const _navyInk = Color(0xFF12314A);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF16324A),
              Color(0xFF122A3E),
              Color(0xFF0C1E2E),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _header(),
            Row(
              children: [
                Expanded(child: _sunTile(Icons.wb_sunny_outlined, 'Sunrise', sunrise)),
                const SizedBox(width: 5),
                Expanded(child: _sunTile(Icons.wb_twilight_rounded, 'Sunset', sunset)),
                const SizedBox(width: 5),
                Expanded(child: _sunTile(Icons.nightlight_outlined, 'Sahri', sahri)),
                const SizedBox(width: 5),
                Expanded(child: _sunTile(Icons.dinner_dining_outlined, 'Iftar', iftar)),
              ],
            ),
            Row(
              children: [
                for (var i = 0; i < jamaat.length; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Expanded(child: _jamaatChip(jamaat[i])),
                ],
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _gold,
          ),
          child: const Icon(Icons.schedule_rounded, size: 13, color: _navyInk),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mosque Jamaat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                dateLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Updated: $updatedAt',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.refresh_rounded,
          size: 13,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ],
    );
  }

  Widget _sunTile(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: Colors.white.withValues(alpha: 0.75)),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _jamaatChip(JamaatChip chip) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        decoration: BoxDecoration(
          color: chip.isCurrent
              ? _gold
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: chip.isCurrent
                ? _gold
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              chip.label,
              maxLines: 1,
              style: TextStyle(
                color: chip.isCurrent
                    ? _navyInk
                    : Colors.white.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                chip.time,
                style: TextStyle(
                  color: chip.isCurrent ? _navyInk : Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      );
}
