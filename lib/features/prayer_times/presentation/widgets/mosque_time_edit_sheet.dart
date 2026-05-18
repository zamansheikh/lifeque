import 'package:flutter/material.dart';

import '../../data/services/prayer_settings_service.dart';

/// Bottom sheet to edit a single prayer's mosque (jamaat) time and to flip
/// Ramadan mode (which auto-derives Fajr & Maghrib from Waqt). Replaces the
/// old standalone Mosque tab.
class MosqueTimeEditSheet extends StatefulWidget {
  final String prayer;
  final TimeOfDay? currentMosqueTime;
  final TimeOfDay? waqtTime;
  final bool isRamadanMode;
  final bool isLockedByRamadan;
  final void Function(TimeOfDay) onSaved;
  final ValueChanged<bool> onRamadanModeChanged;

  const MosqueTimeEditSheet({
    super.key,
    required this.prayer,
    required this.currentMosqueTime,
    required this.waqtTime,
    required this.isRamadanMode,
    required this.isLockedByRamadan,
    required this.onSaved,
    required this.onRamadanModeChanged,
  });

  static Future<void> show({
    required BuildContext context,
    required String prayer,
    required TimeOfDay? currentMosqueTime,
    required TimeOfDay? waqtTime,
    required bool isLockedByRamadan,
    required void Function(TimeOfDay) onSaved,
    required ValueChanged<bool> onRamadanModeChanged,
  }) async {
    final ramadan = await PrayerSettingsService.instance.getRamadanMode();
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MosqueTimeEditSheet(
        prayer: prayer,
        currentMosqueTime: currentMosqueTime,
        waqtTime: waqtTime,
        isRamadanMode: ramadan,
        isLockedByRamadan: isLockedByRamadan,
        onSaved: onSaved,
        onRamadanModeChanged: onRamadanModeChanged,
      ),
    );
  }

  @override
  State<MosqueTimeEditSheet> createState() => _MosqueTimeEditSheetState();
}

class _MosqueTimeEditSheetState extends State<MosqueTimeEditSheet> {
  late TimeOfDay _time;
  late bool _ramadanMode;

  @override
  void initState() {
    super.initState();
    _time = widget.currentMosqueTime ??
        (widget.waqtTime != null
            ? _addMinutes(widget.waqtTime!, 15)
            : const TimeOfDay(hour: 12, minute: 30));
    _ramadanMode = widget.isRamadanMode;
  }

  TimeOfDay _addMinutes(TimeOfDay t, int mins) {
    final total = t.hour * 60 + t.minute + mins;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }

  int _deltaMinutes() {
    if (widget.waqtTime == null) return 0;
    return (_time.hour * 60 + _time.minute) -
        (widget.waqtTime!.hour * 60 + widget.waqtTime!.minute);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final delta = _deltaMinutes();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.mosque_rounded, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                '${widget.prayer} · Mosque Time',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Jamaat time for your local mosque.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),

          // Ramadan mode tile
          _Tile(
            icon: Icons.nightlight_round,
            iconColor: const Color(0xFFB45309),
            title: 'Ramadan Mode',
            subtitle: 'Auto-sets Fajr & Maghrib to Waqt + 15m',
            trailing: Switch.adaptive(
              value: _ramadanMode,
              onChanged: (v) async {
                setState(() => _ramadanMode = v);
                widget.onRamadanModeChanged(v);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Time picker tile
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.isLockedByRamadan && _ramadanMode ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: widget.isLockedByRamadan && _ramadanMode,
              child: _Tile(
                icon: Icons.access_time_rounded,
                iconColor: cs.primary,
                title: _format(_time),
                subtitle: widget.waqtTime == null
                    ? 'Waqt unknown'
                    : 'Waqt is ${_format(widget.waqtTime!)}'
                        '${delta == 0 ? '' : delta > 0 ? '  ·  +${delta}m later' : '  ·  ${delta}m earlier'}',
                trailing: TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Change'),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (picked != null) {
                      setState(() => _time = picked);
                    }
                  },
                ),
              ),
            ),
          ),

          // Quick-offset row
          if (widget.waqtTime != null &&
              !(widget.isLockedByRamadan && _ramadanMode))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final offset in [0, 5, 10, 15, 20, 30])
                    _OffsetChip(
                      label: offset == 0 ? 'On time' : '+${offset}m',
                      selected: _deltaMinutes() == offset,
                      onTap: () => setState(
                        () => _time = _addMinutes(widget.waqtTime!, offset),
                      ),
                    ),
                ],
              ),
            ),

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: widget.isLockedByRamadan && _ramadanMode
                      ? null
                      : () {
                          widget.onSaved(_time);
                          Navigator.of(context).pop();
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Save Mosque Time'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _format(TimeOfDay t) {
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final hh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final ap = h >= 12 ? 'PM' : 'AM';
    return '$hh:$m $ap';
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _OffsetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OffsetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? cs.primary
          : cs.surfaceContainerHighest.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? cs.onPrimary : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
