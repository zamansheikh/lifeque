import 'package:flutter/material.dart';

import '../../../../core/services/prayer_alarm_service.dart';
import '../../../../core/utils/alarm_sound_preview.dart';
import '../../../../core/utils/alarm_sound_utils.dart';
import '../utils/prayer_palette.dart';
import 'prayer_snack.dart';
import '../../../../l10n/app_localizations.dart';
import '../utils/prayer_l10n.dart';

/// The single place prayer alarms are configured: a master switch, per-prayer
/// timing, the adhan sound and how long it rings.
///
/// This replaces the old full-screen alarm page — everything it did lives
/// here, one tap from the prayer list, in the section's own theme.
class PrayerAlarmSheet {
  static Future<void> show(
    BuildContext context, {
    required List<String> prayers,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _Sheet(prayers: prayers),
    );
  }
}

class _Sheet extends StatefulWidget {
  final List<String> prayers;

  const _Sheet({required this.prayers});

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  final _service = PrayerAlarmService();

  /// How long the adhan rings before it gives up, in minutes.
  static const _durations = [1, 2, 5, 10];

  /// Range the offset slider covers, in minutes relative to the waqt start.
  static const _minOffset = -30.0;
  static const _maxOffset = 60.0;

  late bool _globalEnabled = _service.isEnabled;
  late String _soundPath;
  late int _duration;
  late bool _vibrate;

  /// Slider positions mid-drag, before they are committed on release.
  final Map<String, int> _pendingOffsets = {};

  @override
  void initState() {
    super.initState();
    // Seed sound and duration from whichever alarm already exists, so the
    // sheet opens showing the user's real settings rather than defaults.
    final existing = _service.alarms.firstOrNull;
    _soundPath =
        existing?.soundPath ?? AlarmSoundUtils.availableAlarmSounds[0]['path']!;
    _duration = existing?.alarmDurationMinutes ?? 2;
    _vibrate = existing?.vibrate ?? true;
  }

  @override
  void dispose() {
    AlarmSoundPreview.instance.stop();
    super.dispose();
  }

  PrayerAlarmConfig? _configFor(String prayer) =>
      _service.alarms.where((a) => a.prayerName == prayer).firstOrNull;

  /// Whether this prayer's alarm is anchored to the jamaat rather than the
  /// waqt. Off alarms default to waqt.
  bool _isJamaatBased(String prayer) =>
      _configFor(prayer)?.type == PrayerAlarmType.afterJamaat;

  /// Minutes relative to the anchor, or null when the alarm is off.
  int? _minutesFor(String prayer) {
    final pending = _pendingOffsets[prayer];
    if (pending != null) return pending;
    final config = _configFor(prayer);
    if (config == null || !config.isEnabled) return null;
    if (config.type != PrayerAlarmType.afterPrayerStart &&
        config.type != PrayerAlarmType.afterJamaat) {
      return null;
    }
    return config.minutesAfterStart;
  }

  /// The bundled sound files are named in English; only the label changes.
  String _soundLabel(BuildContext context, String name) {
    final l = L.of(context);
    return switch (name) {
      'Alarm Sound 1' => l.alarmSound1,
      'Alarm Sound 2' => l.alarmSound2,
      'Alarm Sound 3' => l.alarmSound3,
      _ => name,
    };
  }

  /// e.g. `At waqt`, `5 min before jamaat`, `10 min after waqt`.
  ///
  /// Four separate messages rather than one built from an anchor word: Bangla
  /// puts the anchor first ("ওয়াক্তের ৫ মিনিট আগে"), so a sentence assembled
  /// from English word order would come out backwards.
  String _offsetLabel(BuildContext context, int minutes, bool jamaat) {
    final l = L.of(context);
    if (minutes == 0) return jamaat ? l.alarmAtJamaat : l.alarmAtWaqt;
    if (minutes < 0) {
      return jamaat
          ? l.alarmMinBeforeJamaat(minutes.abs())
          : l.alarmMinBeforeWaqt(minutes.abs());
    }
    return jamaat
        ? l.alarmMinAfterJamaat(minutes)
        : l.alarmMinAfterWaqt(minutes);
  }

  Future<void> _setMinutes(String prayer, int minutes, {bool? jamaat}) async {
    final existing = _configFor(prayer);
    final useJamaat = jamaat ?? _isJamaatBased(prayer);
    final config = PrayerAlarmConfig(
      prayerName: prayer,
      type: useJamaat
          ? PrayerAlarmType.afterJamaat
          : PrayerAlarmType.afterPrayerStart,
      minutesAfterStart: minutes,
      isEnabled: true,
      soundPath: _soundPath,
      alarmDurationMinutes: _duration,
      vibrate: _vibrate,
    );
    if (existing != null) {
      await _service.updateAlarm(config);
    } else {
      await _service.addAlarm(config);
    }
    if (mounted) setState(() {});
  }

  /// Sound and ring-length apply to every prayer alarm, matching the single
  /// "Adhan voice" choice in More — so changing one rewrites them all.
  Future<void> _applyToAllAlarms() async {
    for (final alarm in List.of(_service.alarms)) {
      await _service.updateAlarm(
        alarm.copyWith(
          soundPath: _soundPath,
          alarmDurationMinutes: _duration,
          vibrate: _vibrate,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PrayerPalette.inkA(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _header(),
          const SizedBox(height: 16),
          _section(L.of(context).alarmSheetWhen),
          const SizedBox(height: 8),
          Opacity(
            opacity: _globalEnabled ? 1 : 0.4,
            child: IgnorePointer(
              ignoring: !_globalEnabled,
              child: Column(
                children: [
                  for (var i = 0; i < widget.prayers.length; i++) ...[
                    if (i > 0) const SizedBox(height: 9),
                    _prayerRow(widget.prayers[i]),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _section(L.of(context).alarmSheetSound),
          const SizedBox(height: 8),
          for (final sound in AlarmSoundUtils.availableAlarmSounds) ...[
            _soundRow(sound),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 12),
          _section(L.of(context).alarmSheetRingsFor),
          const SizedBox(height: 8),
          _durationRow(),
          const SizedBox(height: 18),
          _vibrationRow(),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: PrayerPalette.accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                L.of(context).commonDone,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pieces ──────────────────────────────────────────────────────────────

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PrayerPalette.accentA(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.alarm_rounded,
            color: PrayerPalette.accent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L.of(context).alarmSheetTitle,
                style: TextStyle(
                  color: PrayerPalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _globalEnabled
                    ? L.of(context).alarmSheetSubtitle
                    : L.of(context).alarmSheetPaused,
                style: TextStyle(
                  color: PrayerPalette.inkA(0.55),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _switch(
          value: _globalEnabled,
          onChanged: (v) async {
            await _service.toggleGlobalAlarms(v);
            if (!mounted) return;
            setState(() => _globalEnabled = v);
          },
        ),
      ],
    );
  }

  Widget _section(String title) => Text(
    title,
    style: TextStyle(
      color: PrayerPalette.inkA(0.5),
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    ),
  );

  /// A row per prayer: an on/off switch, and — when on — a slider for the
  /// exact offset, so any minute in range is reachable rather than only the
  /// three presets the chips used to offer.
  Widget _prayerRow(String prayer) {
    final minutes = _minutesFor(prayer);
    final isOn = minutes != null;
    final jamaat = _isJamaatBased(prayer);

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, isOn ? 4 : 8),
      decoration: BoxDecoration(
        color: isOn ? PrayerPalette.accentA(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOn ? PrayerPalette.accentA(0.3) : PrayerPalette.inkA(0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 66,
                child: Text(
                  prayerLabel(context, prayer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PrayerPalette.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  isOn
                      ? _offsetLabel(context, minutes, jamaat)
                      : L.of(context).alarmNone,
                  style: TextStyle(
                    color: isOn
                        ? PrayerPalette.accent
                        : PrayerPalette.inkA(0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _switch(
                value: isOn,
                compact: true,
                onChanged: (v) async {
                  if (v) {
                    await _setMinutes(prayer, 0);
                  } else {
                    await _service.removeAlarm(prayer);
                    if (mounted) setState(() {});
                  }
                },
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 6),
            _anchorSelector(prayer, jamaat, minutes),
            _offsetSlider(prayer, minutes, jamaat),
          ],
        ],
      ),
    );
  }

  /// Measure the offset from the waqt or from the mosque's jamaat. Jamaat is
  /// what most people actually plan around, so it's offered per prayer rather
  /// than as one global setting.
  Widget _anchorSelector(String prayer, bool jamaat, int minutes) {
    Widget chip(String label, bool selected, VoidCallback onTap) => Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? PrayerPalette.accent : Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? Colors.transparent : PrayerPalette.inkA(0.15),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : PrayerPalette.inkA(0.7),
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(
            L.of(context).alarmMeasuredFrom,
            style: TextStyle(
              color: PrayerPalette.inkA(0.45),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          chip(
            L.of(context).alarmAnchorWaqt,
            !jamaat,
            () => _setMinutes(prayer, minutes, jamaat: false),
          ),
          const SizedBox(width: 6),
          chip(
            L.of(context).alarmAnchorJamaat,
            jamaat,
            () => _setMinutes(prayer, minutes, jamaat: true),
          ),
        ],
      ),
    );
  }

  Widget _offsetSlider(String prayer, int minutes, bool jamaat) {
    return Row(
      children: [
        Text(
          '${_minOffset.round()}',
          style: TextStyle(
            color: PrayerPalette.inkA(0.35),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: PrayerPalette.accent,
              inactiveTrackColor: PrayerPalette.inkA(0.12),
              thumbColor: PrayerPalette.accent,
              overlayColor: PrayerPalette.accentA(0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              valueIndicatorColor: PrayerPalette.ink,
              showValueIndicator: ShowValueIndicator.onDrag,
            ),
            child: Slider(
              value: minutes.toDouble().clamp(_minOffset, _maxOffset),
              min: _minOffset,
              max: _maxOffset,
              // One division per minute, so every value is reachable.
              divisions: (_maxOffset - _minOffset).round(),
              label: _offsetLabel(context, minutes, jamaat),
              // Track the finger live, but only write on release — each
              // write reschedules the OS alarm.
              onChanged: (v) =>
                  setState(() => _pendingOffsets[prayer] = v.round()),
              onChangeEnd: (v) async {
                _pendingOffsets.remove(prayer);
                await _setMinutes(prayer, v.round());
              },
            ),
          ),
        ),
        Text(
          '+${_maxOffset.round()}',
          style: TextStyle(
            color: PrayerPalette.inkA(0.35),
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _soundRow(Map<String, String> sound) {
    final path = sound['path']!;
    final selected = path == _soundPath;
    return InkWell(
      onTap: () async {
        setState(() => _soundPath = path);
        await AlarmSoundUtils.setPrayerAlarmSound(path);
        await _applyToAllAlarms();
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
              child: Text(
                _soundLabel(context, sound['name']!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PrayerPalette.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _previewButton(path),
          ],
        ),
      ),
    );
  }

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
                L.of(context).alarmSoundFailed,
                kind: PrayerSnackKind.error,
              );
            }
          },
          customBorder: const CircleBorder(),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPlaying
                  ? PrayerPalette.accent
                  : PrayerPalette.accentA(0.12),
            ),
            child: Icon(
              isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 17,
              color: isPlaying ? Colors.white : PrayerPalette.accent,
            ),
          ),
        );
      },
    );
  }

  /// Vibration rides along with the adhan; some users keep the phone silent
  /// and rely on the buzz alone, so it is separately switchable.
  Widget _vibrationRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PrayerPalette.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PrayerPalette.inkA(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PrayerPalette.accentA(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.vibration_rounded,
              size: 17,
              color: PrayerPalette.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L.of(context).alarmVibrate,
                  style: TextStyle(
                    color: PrayerPalette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  L.of(context).alarmVibrateBody,
                  style: TextStyle(
                    color: PrayerPalette.inkA(0.5),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _switch(
            value: _vibrate,
            onChanged: (v) async {
              setState(() => _vibrate = v);
              await _applyToAllAlarms();
            },
          ),
        ],
      ),
    );
  }

  Widget _durationRow() {
    return Row(
      children: [
        for (var i = 0; i < _durations.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () async {
                setState(() => _duration = _durations[i]);
                await _applyToAllAlarms();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _duration == _durations[i]
                      ? PrayerPalette.accent
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _duration == _durations[i]
                        ? Colors.transparent
                        : PrayerPalette.inkA(0.15),
                  ),
                ),
                child: Text(
                  L.of(context).alarmMinutes(_durations[i]),
                  style: TextStyle(
                    color: _duration == _durations[i]
                        ? Colors.white
                        : PrayerPalette.inkA(0.7),
                    fontSize: 11.5,
                    fontWeight: _duration == _durations[i]
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _switch({
    required bool value,
    required ValueChanged<bool> onChanged,
    bool compact = false,
  }) {
    final w = compact ? 38.0 : 44.0;
    final h = compact ? 22.0 : 26.0;
    final knob = compact ? 16.0 : 20.0;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: value ? PrayerPalette.accent : PrayerPalette.inkA(0.2),
          borderRadius: BorderRadius.circular(h / 2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: knob,
            height: knob,
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
}
