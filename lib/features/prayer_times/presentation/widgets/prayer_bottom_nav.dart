import 'package:flutter/material.dart';

import '../utils/prayer_palette.dart';

/// Tabs in the prayer section's bottom bar.
enum PrayerTab { prayer, calendar, qibla, tasbih, more }

/// Floating pill nav for the prayer section: a white rounded bar with five
/// icon+label items, the active one carrying a tinted lozenge behind its icon.
class PrayerBottomNav extends StatelessWidget {
  final PrayerTab current;
  final ValueChanged<PrayerTab> onSelect;

  const PrayerBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  static const _items = <(PrayerTab, IconData, String)>[
    (PrayerTab.prayer, Icons.mosque, 'Prayer'),
    (PrayerTab.calendar, Icons.calendar_month_outlined, 'Calendar'),
    (PrayerTab.qibla, Icons.explore_outlined, 'Qibla'),
    (PrayerTab.tasbih, Icons.blur_circular_outlined, 'Tasbih'),
    (PrayerTab.more, Icons.more_horiz_rounded, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: PrayerPalette.ink.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final (tab, icon, label) in _items)
            Expanded(child: _item(tab, icon, label)),
        ],
      ),
    );
  }

  Widget _item(PrayerTab tab, IconData icon, String label) {
    final active = tab == current;
    final color = active ? PrayerPalette.ink : PrayerPalette.inkA(0.45);
    return InkWell(
      onTap: () => onSelect(tab),
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
            decoration: BoxDecoration(
              color: active ? PrayerPalette.accentA(0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
