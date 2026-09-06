import 'package:flutter/material.dart';

import '../../../../core/widgets/app_drawer.dart';
import '../utils/prayer_palette.dart';
import '../widgets/prayer_bottom_nav.dart';
import 'prayer_calendar_page.dart';
import 'prayer_more_page.dart';
import 'prayer_times_page.dart';
import '../../../islamic_resources/presentation/pages/islamic_resources_page.dart';
import 'tasbih_qibla_page.dart';

/// Container for the whole prayer section: the five bottom-nav tabs plus the
/// app drawer.
///
/// Tabs live in an [IndexedStack] so each keeps its scroll position and, in
/// the tasbih's case, its in-progress count when you switch away and back.
class PrayerShellPage extends StatefulWidget {
  /// Tab to open on. Defaults to the prayer times themselves.
  final PrayerTab initialTab;

  const PrayerShellPage({super.key, this.initialTab = PrayerTab.prayer});

  @override
  State<PrayerShellPage> createState() => _PrayerShellPageState();
}

class _PrayerShellPageState extends State<PrayerShellPage> {
  late PrayerTab _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PrayerPalette.canvas,
      drawer: const AppDrawer(currentRoute: '/prayer-times'),
      drawerScrimColor: Colors.black.withValues(alpha: 0.4),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              // Without expand, IndexedStack loose-sizes each tab and pins it
              // to the top-start — which left the Qibla dial off-centre.
              sizing: StackFit.expand,
              index: PrayerTab.values.indexOf(_tab),
              children: const [
                PrayerTimesPage(),
                PrayerCalendarPage(),
                TasbihQiblaPage(),
                IslamicResourcesPage(embedded: true),
                PrayerMorePage(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: PrayerBottomNav(
              current: _tab,
              onSelect: (tab) => setState(() => _tab = tab),
            ),
          ),
        ],
      ),
    );
  }
}
