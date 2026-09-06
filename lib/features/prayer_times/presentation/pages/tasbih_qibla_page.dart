import 'package:flutter/material.dart';

import '../utils/prayer_palette.dart';
import 'qibla_page.dart';
import 'tasbih_page.dart';
import '../../../../l10n/app_localizations.dart';

/// Tasbih and the Qibla compass, on one tab.
///
/// They are both "hold the phone and do a thing" tools, each a single screen
/// deep, and keeping them apart cost a whole slot in a five-tab bar. Sharing
/// one tab freed that slot for the Islamic resources, which had been buried
/// two taps down under More.
///
/// The two live in an [IndexedStack] rather than being swapped out, so the
/// tasbih keeps its in-progress count and the compass keeps its sensor
/// subscription while you look at the other one.
class TasbihQiblaPage extends StatefulWidget {
  const TasbihQiblaPage({super.key});

  @override
  State<TasbihQiblaPage> createState() => _TasbihQiblaPageState();
}

class _TasbihQiblaPageState extends State<TasbihQiblaPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: _switcher(),
          ),
          Expanded(
            child: IndexedStack(
              sizing: StackFit.expand,
              index: _index,
              children: const [TasbihPage(), QiblaPage()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PrayerPalette.inkA(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              index: 0,
              icon: Icons.blur_circular_outlined,
              label: L.of(context).tasbihTitle,
            ),
          ),
          Expanded(
            child: _segment(
              index: 1,
              icon: Icons.explore_outlined,
              label: L.of(context).qiblaTitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final active = _index == index;
    return Material(
      color: active ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      elevation: active ? 1 : 0,
      shadowColor: PrayerPalette.ink.withValues(alpha: 0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => setState(() => _index = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? PrayerPalette.accent : PrayerPalette.inkA(0.45),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: active ? PrayerPalette.ink : PrayerPalette.inkA(0.45),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
