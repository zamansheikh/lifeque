import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/alarm_sound_preview.dart';
import '../../../home_widget/presentation/widgets/add_widget_sheet.dart';
import '../../../../core/utils/alarm_sound_utils.dart';
import '../../../islamic_resources/presentation/pages/islamic_resources_page.dart'
    hide IslamicColors;
import '../../data/services/prayer_settings_service.dart';
import '../utils/prayer_palette.dart';
import '../widgets/after_prayer_duas_sheet.dart';
import '../widgets/prayer_alarm_sheet.dart';
import '../widgets/prayer_snack.dart';
import 'prayer_stats_page.dart';

/// "More" tab: shortcuts into stats/resources/duas, the adhan voice picker,
/// and the prayer settings block (method, madhab, location, Ramadan mode).
class PrayerMorePage extends StatefulWidget {
  const PrayerMorePage({super.key});

  @override
  State<PrayerMorePage> createState() => _PrayerMorePageState();
}

class _PrayerMorePageState extends State<PrayerMorePage> {
  final _settings = PrayerSettingsService.instance;

  CalculationMethod _method = CalculationMethod.karachi;
  Madhab _madhab = Madhab.hanafi;
  String _locationName = 'Not set';
  bool _fromGps = false;
  bool _ramadan = false;
  String _adhanSound = '';
  bool _loading = true;

  static const _methodLabels = <CalculationMethod, String>{
    CalculationMethod.karachi: 'Karachi',
    CalculationMethod.muslim_world_league: 'Muslim World League',
    CalculationMethod.egyptian: 'Egyptian',
    CalculationMethod.umm_al_qura: 'Umm al-Qura',
    CalculationMethod.dubai: 'Dubai',
    CalculationMethod.qatar: 'Qatar',
    CalculationMethod.kuwait: 'Kuwait',
    CalculationMethod.moon_sighting_committee: 'Moonsighting Committee',
    CalculationMethod.singapore: 'Singapore',
    CalculationMethod.north_america: 'ISNA (North America)',
    CalculationMethod.turkey: 'Turkey',
    CalculationMethod.tehran: 'Tehran',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // Don't leave a preview playing after the user navigates away.
    AlarmSoundPreview.instance.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final method = await _settings.getCalculationMethod();
    final madhab = await _settings.getMadhab();
    final loc = await _settings.getSavedLocation();
    final ramadan = await _settings.getRamadanMode();
    final sound = await AlarmSoundUtils.getPrayerAlarmSound();
    if (!mounted) return;
    setState(() {
      _method = method;
      _madhab = madhab;
      _locationName = loc?.locationName ?? 'Not set';
      _fromGps = loc?.isFromGps ?? false;
      _ramadan = ramadan;
      _adhanSound = sound;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: PrayerPalette.accent),
      );
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        physics: const BouncingScrollPhysics(),
        children: [
          const Text(
            'More',
            style: TextStyle(
              color: PrayerPalette.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _navRow(
            icon: Icons.bar_chart_rounded,
            title: 'Prayer stats',
            subtitle: 'Streak, weekly & 30-day history',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrayerStatsPage()),
            ),
          ),
          const SizedBox(height: 8),
          _navRow(
            icon: Icons.alarm_rounded,
            title: 'Prayer alarms',
            subtitle: 'Per-prayer timing, adhan sound & duration',
            onTap: () => PrayerAlarmSheet.show(
              context,
              prayers: const ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'],
            ),
          ),
          const SizedBox(height: 8),
          _navRow(
            icon: Icons.widgets_rounded,
            title: 'Home-screen widget',
            subtitle: 'Prayer times on your home screen',
            onTap: () => AddWidgetSheet.show(context),
          ),
          const SizedBox(height: 8),
          _navRow(
            icon: Icons.menu_book_rounded,
            title: 'Islamic resources',
            subtitle: 'Quran, hadith, 99 names, duas',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IslamicResourcesPage()),
            ),
          ),
          const SizedBox(height: 8),
          _navRow(
            icon: Icons.auto_stories_rounded,
            title: 'After-prayer duas',
            subtitle: 'Adhkar with Arabic & translation',
            onTap: () => AfterPrayerDuasSheet.show(context),
          ),
          const SizedBox(height: 10),
          _adhanCard(),
          const SizedBox(height: 10),
          _settingsCard(),
        ],
      ),
    );
  }

  // ── Rows ────────────────────────────────────────────────────────────────

  Widget _navRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: PrayerPalette.ink.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: PrayerPalette.accentA(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 17, color: PrayerPalette.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: PrayerPalette.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: PrayerPalette.inkA(0.5),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: PrayerPalette.inkA(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String title, required List<Widget> children}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(PrayerPalette.cardRadius),
          boxShadow: PrayerPalette.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: PrayerPalette.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );

  // ── Adhan voice ─────────────────────────────────────────────────────────

  Widget _adhanCard() {
    final sounds = AlarmSoundUtils.availableAlarmSounds;
    return _card(
      title: 'Adhan voice',
      children: [
        for (var i = 0; i < sounds.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _adhanRow(sounds[i]),
        ],
      ],
    );
  }

  Widget _adhanRow(Map<String, String> sound) {
    final selected = sound['path'] == _adhanSound;
    return InkWell(
      onTap: () async {
        await AlarmSoundUtils.setPrayerAlarmSound(sound['path']!);
        if (!mounted) return;
        setState(() => _adhanSound = sound['path']!);
      },
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? PrayerPalette.accentA(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? PrayerPalette.accentA(0.4)
                : PrayerPalette.inkA(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? PrayerPalette.accent
                      : PrayerPalette.inkA(0.3),
                  width: 2,
                ),
              ),
              child: selected
                  ? Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: PrayerPalette.accent,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sound['name']!,
                    style: const TextStyle(
                      color: PrayerPalette.ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    sound['description'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: PrayerPalette.inkA(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _previewButton(sound['path']!),
          ],
        ),
      ),
    );
  }

  /// Audition a sound without selecting it.
  Widget _previewButton(String path) {
    return ValueListenableBuilder<String?>(
      valueListenable: AlarmSoundPreview.instance.playing,
      builder: (_, current, child) {
        final isPlaying = current == path;
        return InkWell(
          onTap: () async {
            try {
              await AlarmSoundPreview.instance.toggle(path);
            } catch (_) {
              if (!mounted) return;
              PrayerSnack.show(
                context,
                'Could not play this sound',
                kind: PrayerSnackKind.error,
              );
            }
          },
          customBorder: const CircleBorder(),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPlaying
                  ? PrayerPalette.accent
                  : PrayerPalette.accentA(0.12),
            ),
            child: Icon(
              isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 18,
              color: isPlaying ? Colors.white : PrayerPalette.accent,
            ),
          ),
        );
      },
    );
  }

  // ── Settings ────────────────────────────────────────────────────────────

  Widget _settingsCard() {
    return _card(
      title: 'Settings',
      children: [
        _settingRow(
          label: 'Calculation method',
          trailing: InkWell(
            onTap: _pickMethod,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _methodLabels[_method] ?? 'Custom',
                  style: const TextStyle(
                    color: PrayerPalette.accent,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: PrayerPalette.accent,
                ),
              ],
            ),
          ),
        ),
        _settingRow(
          label: 'Madhab (Asr)',
          trailing: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: PrayerPalette.accentA(0.35)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _madhabChip('Hanafi', Madhab.hanafi),
                _madhabChip('Shafi', Madhab.shafi),
              ],
            ),
          ),
        ),
        _settingRow(
          label: 'Location',
          trailing: Flexible(
            child: Text(
              '${_locationName.split(',').first}'
              '${_fromGps ? ' · GPS ✓' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: PrayerPalette.inkA(0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        _settingRow(
          label: 'Ramadan mode',
          showDivider: false,
          trailing: _switch(
            value: _ramadan,
            onChanged: (v) async {
              await _settings.saveRamadanMode(v);
              if (!mounted) return;
              setState(() => _ramadan = v);
            },
          ),
        ),
      ],
    );
  }

  Widget _settingRow({
    required String label,
    required Widget trailing,
    bool showDivider = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: PrayerPalette.inkA(0.07)),
              ),
            )
          : null,
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: PrayerPalette.inkA(0.7),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _madhabChip(String label, Madhab madhab) {
    final active = _madhab == madhab;
    return InkWell(
      onTap: () async {
        await _settings.saveMadhab(madhab);
        if (!mounted) return;
        setState(() => _madhab = madhab);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        color: active ? PrayerPalette.accent : Colors.white,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : PrayerPalette.inkA(0.6),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// The design's pill switch — smaller and squarer than Material's default.
  Widget _switch({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 23,
        decoration: BoxDecoration(
          color: value ? PrayerPalette.accent : PrayerPalette.inkA(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickMethod() async {
    final picked = await showModalBottomSheet<CalculationMethod>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                'Calculation method',
                style: TextStyle(
                  color: PrayerPalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (final entry in _methodLabels.entries)
              ListTile(
                title: Text(
                  entry.value,
                  style: TextStyle(
                    color: PrayerPalette.ink,
                    fontSize: 14,
                    fontWeight: entry.key == _method
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
                trailing: entry.key == _method
                    ? const Icon(Icons.check_rounded,
                        color: PrayerPalette.accent)
                    : null,
                onTap: () => Navigator.pop(ctx, entry.key),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await _settings.saveCalculationMethod(picked);
    if (!mounted) return;
    setState(() => _method = picked);
  }
}
