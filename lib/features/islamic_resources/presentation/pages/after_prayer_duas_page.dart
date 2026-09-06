import 'package:flutter/material.dart';

import '../../../prayer_times/presentation/widgets/after_prayer_duas_sheet.dart';
import 'islamic_resources_page.dart';
import '../../../../l10n/app_localizations.dart';

/// The adhkar said after finishing a prayer.
///
/// The same list that used to open as a bottom sheet from the More tab, now a
/// page under Learn alongside the other reference material — which is where
/// someone looks for it, rather than remembering it was tucked into a menu.
class AfterPrayerDuasPage extends StatelessWidget {
  const AfterPrayerDuasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IslamicColors.cream,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  L.of(context).adhkarSubtitle,
                  style: TextStyle(
                    color: IslamicColors.mutedText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                ...AfterPrayerDuasSheet.cards(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      title: Text(
        L.of(context).adhkarTitle,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      backgroundColor: const Color(0xFF00695C),
      foregroundColor: Colors.white,
      pinned: true,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF004D40), Color(0xFF00897B)],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, bottom: 10),
                child: Text(
                  'أذكار بعد الصلاة',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
