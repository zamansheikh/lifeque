import 'package:flutter/material.dart';

import '../utils/prayer_palette.dart';

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

/// Compact grid for setting all five prayer alarms at once — a row per
/// prayer, four chips per row. Deeper options (sound, duration) stay on the
/// full alarm page.
class PrayerAlarmSheet {
  static Future<void> show(
    BuildContext context, {
    required List<String> prayers,

    /// Current offset per prayer; missing or null means `off`.
    required Map<String, AlarmOffset> current,
    required Future<void> Function(String prayer, AlarmOffset offset) onSet,

    /// Opens the full alarm page, where sound and duration live.
    required VoidCallback onOpenFullSettings,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => _Sheet(
        prayers: prayers,
        initial: current,
        onSet: onSet,
        onOpenFullSettings: onOpenFullSettings,
      ),
    );
  }
}

class _Sheet extends StatefulWidget {
  final List<String> prayers;
  final Map<String, AlarmOffset> initial;
  final Future<void> Function(String prayer, AlarmOffset offset) onSet;
  final VoidCallback onOpenFullSettings;

  const _Sheet({
    required this.prayers,
    required this.initial,
    required this.onSet,
    required this.onOpenFullSettings,
  });

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  late final Map<String, AlarmOffset> _state = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: PrayerPalette.inkA(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Prayer alarms',
              style: TextStyle(
                color: PrayerPalette.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap a chip to set when each alarm rings',
              style: TextStyle(
                color: PrayerPalette.inkA(0.55),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < widget.prayers.length; i++) ...[
              if (i > 0) const SizedBox(height: 9),
              _row(widget.prayers[i]),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.pop(context);
                widget.onOpenFullSettings();
              },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Text(
                  'Adhan sound & duration →',
                  style: TextStyle(
                    color: PrayerPalette.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: PrayerPalette.accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String prayer) {
    final active = _state[prayer] ?? AlarmOffset.off;
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
      onTap: () async {
        setState(() => _state[prayer] = offset);
        await widget.onSet(prayer, offset);
      },
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
}
