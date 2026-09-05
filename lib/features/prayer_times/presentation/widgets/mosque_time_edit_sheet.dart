import 'package:flutter/material.dart';

import '../../data/services/prayer_settings_service.dart';
import '../utils/prayer_palette.dart';

/// Sets one prayer's mosque (jamaat) time — nudge it in 5-minute steps or
/// pick an exact wall-clock time — and carries the Ramadan-mode switch that
/// auto-derives Fajr and Maghrib from the waqt.
class MosqueTimeEditSheet extends StatefulWidget {
  final String prayer;
  final TimeOfDay? currentMosqueTime;
  final TimeOfDay? waqtTime;
  final bool isRamadanMode;

  /// True for Fajr and Maghrib, whose jamaat Ramadan mode computes itself.
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
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
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
  late bool _ramadan;

  /// True while Ramadan mode is computing this prayer's jamaat for us.
  bool get _locked => _ramadan && widget.isLockedByRamadan;

  @override
  void initState() {
    super.initState();
    _ramadan = widget.isRamadanMode;
    _time = widget.currentMosqueTime ??
        widget.waqtTime ??
        const TimeOfDay(hour: 5, minute: 0);
    if (_locked) _time = _ramadanDerived;
  }

  /// Ramadan mode sets Fajr and Maghrib jamaat to waqt + 15 minutes.
  TimeOfDay get _ramadanDerived {
    final waqt = widget.waqtTime;
    if (waqt == null) return _time;
    final total = waqt.hour * 60 + waqt.minute + 15;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }

  void _step(int minutes) {
    if (_locked) return;
    final total = _time.hour * 60 + _time.minute + minutes;
    final wrapped = (total + 1440) % 1440;
    setState(() {
      _time = TimeOfDay(hour: wrapped ~/ 60, minute: wrapped % 60);
    });
  }

  String _fmt(TimeOfDay t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} '
        '${t.hour < 12 ? 'am' : 'pm'}';
  }

  /// How far the jamaat sits from the waqt.
  String get _delta {
    final waqt = widget.waqtTime;
    if (waqt == null) return 'Nudge by 5 min, or pick an exact time';
    final diff =
        (_time.hour * 60 + _time.minute) - (waqt.hour * 60 + waqt.minute);
    if (diff == 0) return 'Same as waqt';
    return diff > 0
        ? '$diff min after waqt'
        : '${diff.abs()} min before waqt';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
            Text(
              '${widget.prayer} jamaat time',
              style: const TextStyle(
                color: PrayerPalette.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Your mosque's congregation time",
              style: TextStyle(
                color: PrayerPalette.inkA(0.55),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _stepper(),
            const SizedBox(height: 10),
            _pickExactButton(),
            const SizedBox(height: 6),
            Text(
              _locked
                  ? 'Set automatically by Ramadan mode'
                  : _delta,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PrayerPalette.inkA(0.55),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _ramadanRow(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: PrayerPalette.accent,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  widget.onSaved(_time);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Nudging by 5 minutes is fine for small corrections, but a mosque's
  /// jamaat is an arbitrary wall-clock time — this sets it directly.
  Widget _pickExactButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _locked ? null : _pickExactTime,
        style: OutlinedButton.styleFrom(
          foregroundColor: PrayerPalette.accent,
          side: BorderSide(
            color: _locked
                ? PrayerPalette.inkA(0.12)
                : PrayerPalette.accentA(0.4),
          ),
          padding: const EdgeInsets.symmetric(vertical: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.schedule_rounded, size: 17),
        label: const Text(
          'Pick exact time',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _pickExactTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: '${widget.prayer} jamaat time',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: PrayerPalette.accent,
                onPrimary: Colors.white,
                surface: Colors.white,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  Widget _stepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepButton(Icons.remove_rounded, () => _step(-5)),
        const SizedBox(width: 18),
        SizedBox(
          width: 150,
          child: Text(
            _fmt(_time),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _locked ? PrayerPalette.inkA(0.45) : PrayerPalette.ink,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: 18),
        _stepButton(Icons.add_rounded, () => _step(5)),
      ],
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: _locked ? null : onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _locked
              ? PrayerPalette.inkA(0.04)
              : PrayerPalette.accentA(0.10),
          border: Border.all(
            color: _locked
                ? PrayerPalette.inkA(0.12)
                : PrayerPalette.accentA(0.3),
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: _locked ? PrayerPalette.inkA(0.3) : PrayerPalette.accent,
        ),
      ),
    );
  }

  Widget _ramadanRow() {
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
              color: PrayerPalette.gold.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.nightlight_round,
              size: 16,
              color: Color(0xFFB8901E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ramadan mode',
                  style: TextStyle(
                    color: PrayerPalette.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Auto-sets Fajr & Maghrib to waqt + 15m',
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
          InkWell(
            onTap: () {
              final next = !_ramadan;
              setState(() {
                _ramadan = next;
                if (next && widget.isLockedByRamadan) {
                  _time = _ramadanDerived;
                }
              });
              widget.onRamadanModeChanged(next);
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 23,
              decoration: BoxDecoration(
                color: _ramadan
                    ? PrayerPalette.accent
                    : PrayerPalette.inkA(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    _ramadan ? Alignment.centerRight : Alignment.centerLeft,
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
          ),
        ],
      ),
    );
  }
}
