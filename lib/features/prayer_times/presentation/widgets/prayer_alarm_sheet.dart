import 'package:flutter/material.dart';

import '../../../../core/services/prayer_alarm_service.dart';
import '../../../../core/utils/alarm_sound_preview.dart';
import '../../../../core/utils/alarm_sound_utils.dart';
import '../utils/prayer_palette.dart';
import 'prayer_snack.dart';

/// When an alarm fires relative to the start of the waqt. `off` removes it.
enum AlarmOffset {
  fiveBefore(-5, '−5m'),
  onTime(0, 'On time'),
  tenAfter(10, '+10m'),
  off(null, 'Off');

  final int? minutes;
  final String label;

  const AlarmOffset(this.minutes, this.label);
}

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

  late bool _globalEnabled = _service.isEnabled;
  late String _soundPath;
  late int _duration;

  @override
  void initState() {
    super.initState();
    // Seed sound and duration from whichever alarm already exists, so the
    // sheet opens showing the user's real settings rather than defaults.
    final existing = _service.alarms.firstOrNull;
    _soundPath =
        existing?.soundPath ?? AlarmSoundUtils.availableAlarmSounds[0]['path']!;
    _duration = existing?.alarmDurationMinutes ?? 2;
  }

  @override
  void dispose() {
    AlarmSoundPreview.instance.stop();
    super.dispose();
  }

  AlarmOffset _offsetFor(String prayer) {
    final config =
        _service.alarms.where((a) => a.prayerName == prayer).firstOrNull;
    if (config == null || !config.isEnabled) return AlarmOffset.off;
    if (config.type != PrayerAlarmType.afterPrayerStart) return AlarmOffset.off;
    for (final offset in AlarmOffset.values) {
      if (offset.minutes == config.minutesAfterStart) return offset;
    }
    return AlarmOffset.onTime;
  }

  Future<void> _setOffset(String prayer, AlarmOffset offset) async {
    if (offset == AlarmOffset.off) {
      await _service.removeAlarm(prayer);
      if (mounted) setState(() {});
      return;
    }
    final existing =
        _service.alarms.where((a) => a.prayerName == prayer).firstOrNull;
    final config = PrayerAlarmConfig(
      prayerName: prayer,
      type: PrayerAlarmType.afterPrayerStart,
      minutesAfterStart: offset.minutes!,
      isEnabled: true,
      soundPath: _soundPath,
      alarmDurationMinutes: _duration,
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
      // PrayerAlarmConfig has no copyWith — rebuild it, carrying every other
      // field through so nothing is silently reset.
      await _service.updateAlarm(
        PrayerAlarmConfig(
          prayerName: alarm.prayerName,
          type: alarm.type,
          minutesBeforeEnd: alarm.minutesBeforeEnd,
          minutesAfterStart: alarm.minutesAfterStart,
          fixedTime: alarm.fixedTime,
          isEnabled: alarm.isEnabled,
          soundPath: _soundPath,
          alarmDurationMinutes: _duration,
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
          _section('When each alarm rings'),
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
          _section('Adhan sound'),
          const SizedBox(height: 8),
          for (final sound in AlarmSoundUtils.availableAlarmSounds) ...[
            _soundRow(sound),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 12),
          _section('Rings for'),
          const SizedBox(height: 8),
          _durationRow(),
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
              child: const Text(
                'Done',
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
              const Text(
                'Prayer alarms',
                style: TextStyle(
                  color: PrayerPalette.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _globalEnabled
                    ? 'A reminder for each waqt'
                    : 'All alarms are paused',
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

  Widget _prayerRow(String prayer) {
    final active = _offsetFor(prayer);
    return Row(
      children: [
        SizedBox(
          width: 62,
          child: Text(
            prayer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PrayerPalette.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        for (final offset in AlarmOffset.values) ...[
          const SizedBox(width: 8),
          Expanded(child: _chip(prayer, offset, offset == active)),
        ],
      ],
    );
  }

  Widget _chip(String prayer, AlarmOffset offset, bool active) {
    // "Off" reads as a neutral state rather than a positive choice, so it
    // takes the dark ink fill instead of the accent green.
    final bg = !active
        ? Colors.white
        : offset == AlarmOffset.off
            ? PrayerPalette.inkA(0.85)
            : PrayerPalette.accent;

    return InkWell(
      onTap: () => _setOffset(prayer, offset),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? Colors.transparent : PrayerPalette.inkA(0.15),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            offset.label,
            style: TextStyle(
              color: active ? Colors.white : PrayerPalette.inkA(0.7),
              fontSize: 10.5,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
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
                sound['name']!,
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
                'Could not play this sound',
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
                  '${_durations[i]} min',
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
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: value ? PrayerPalette.accent : PrayerPalette.inkA(0.2),
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 20,
            height: 20,
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
