import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

/// Translucent floating top bar that sits over the [SkyBackground].
///
/// Three regions, evenly weighted:
///   [drawer/back]  [location + dual date]  [actions row]
class PrayerTopBar extends StatelessWidget {
  final String locationName;
  final DateTime date;
  final VoidCallback onMenu;
  final VoidCallback onAlarms;
  final VoidCallback onSettings;
  final VoidCallback onResources;

  const PrayerTopBar({
    super.key,
    required this.locationName,
    required this.date,
    required this.onMenu,
    required this.onAlarms,
    required this.onSettings,
    required this.onResources,
  });

  @override
  Widget build(BuildContext context) {
    final hijri = HijriCalendar.fromDate(date);
    final hijriStr =
        '${hijri.hDay} ${_hijriMonthName(hijri.hMonth)} ${hijri.hYear}';
    final gregStr = DateFormat('EEE, MMM d').format(date);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              _IconBtn(icon: Icons.menu_rounded, onTap: onMenu),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hijriStr,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '  ·  ',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          gregStr,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _IconBtn(icon: Icons.alarm_rounded, onTap: onAlarms),
              _IconBtn(icon: Icons.menu_book_rounded, onTap: onResources),
              _IconBtn(icon: Icons.tune_rounded, onTap: onSettings),
            ],
          ),
        ),
      ),
    );
  }

  static String _hijriMonthName(int m) {
    const names = [
      '', 'Muharram', 'Safar', 'Rabi I', 'Rabi II',
      'Jumada I', 'Jumada II', 'Rajab', 'Shaban',
      'Ramadan', 'Shawwal', 'Dhul Q.', 'Dhul H.',
    ];
    return m >= 1 && m < names.length ? names[m] : '';
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 20),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      splashRadius: 22,
    );
  }
}
