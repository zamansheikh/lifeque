import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../services/study_sound_service.dart';

/// The study timer's sound settings: a background for focus blocks (heard
/// for a few seconds as soon as it is picked), its volume, and switches for
/// the chimes, the countdown and the clock tick.
class StudySoundSheet extends StatefulWidget {
  final StudySounds sounds;

  /// Called after a change that affects alarms already armed — the
  /// phase-end chimes are baked into them.
  final VoidCallback? onChimesChanged;

  const StudySoundSheet({
    super.key,
    required this.sounds,
    this.onChimesChanged,
  });

  static Future<void> show(
    BuildContext context, {
    StudySounds? sounds,
    VoidCallback? onChimesChanged,
  }) async {
    final s = sounds ?? StudySounds.instance;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) =>
          StudySoundSheet(sounds: s, onChimesChanged: onChimesChanged),
    );
    await s.endPreview();
  }

  @override
  State<StudySoundSheet> createState() => _StudySoundSheetState();
}

class _StudySoundSheetState extends State<StudySoundSheet> {
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _accent = Color(0xFF4F46E5);

  late StudySoundSettings _s = widget.sounds.settings.value;

  void _save(StudySoundSettings next) {
    final chimesChanged = next.chimes != _s.chimes;
    setState(() => _s = next);
    widget.sounds.update(next);
    if (chimesChanged) widget.onChimesChanged?.call();
  }

  IconData _icon(StudyAmbient a) => switch (a) {
    StudyAmbient.off => Icons.volume_off_rounded,
    StudyAmbient.rain => Icons.water_drop_rounded,
    StudyAmbient.white => Icons.graphic_eq_rounded,
    StudyAmbient.brown => Icons.waves_rounded,
  };

  String _label(L l, StudyAmbient a) => switch (a) {
    StudyAmbient.off => l.studySoundOff,
    StudyAmbient.rain => l.studySoundRain,
    StudyAmbient.white => l.studySoundWhite,
    StudyAmbient.brown => l.studySoundBrown,
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l.studySounds,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.studySoundsBackground,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l.studySoundsBackgroundNote,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final a in StudyAmbient.values) ...[
                    if (a != StudyAmbient.values.first)
                      const SizedBox(width: 8),
                    Expanded(child: _ambientTile(l, a)),
                  ],
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _s.ambient == StudyAmbient.off
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.volume_down_rounded,
                              color: _muted,
                              size: 20,
                            ),
                            Expanded(
                              child: Slider(
                                key: const Key('study-sound-volume'),
                                value: _s.ambientVolume,
                                activeColor: _accent,
                                inactiveColor: _accent.withValues(alpha: 0.15),
                                semanticFormatterCallback: (_) =>
                                    l.studySoundVolume,
                                onChanged: (v) {
                                  setState(
                                    () => _s = _s.copyWith(ambientVolume: v),
                                  );
                                  widget.sounds.previewVolume(v);
                                },
                                onChangeEnd: (v) =>
                                    _save(_s.copyWith(ambientVolume: v)),
                              ),
                            ),
                            const Icon(
                              Icons.volume_up_rounded,
                              color: _muted,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 24),
              _switch(
                key: 'study-sound-chimes',
                icon: Icons.notifications_active_outlined,
                title: l.studySoundChimes,
                body: l.studySoundChimesBody,
                value: _s.chimes,
                onChanged: (v) => _save(_s.copyWith(chimes: v)),
              ),
              _switch(
                key: 'study-sound-countdown',
                icon: Icons.hourglass_bottom_rounded,
                title: l.studySoundCountdown,
                body: l.studySoundCountdownBody,
                value: _s.countdown,
                onChanged: (v) => _save(_s.copyWith(countdown: v)),
              ),
              _switch(
                key: 'study-sound-ticking',
                icon: Icons.av_timer_rounded,
                title: l.studySoundTicking,
                body: l.studySoundTickingBody,
                value: _s.ticking,
                onChanged: (v) => _save(_s.copyWith(ticking: v)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(l.commonDone),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ambientTile(L l, StudyAmbient a) {
    final selected = _s.ambient == a;
    return Material(
      color: selected
          ? _accent.withValues(alpha: 0.1)
          : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('study-ambient-${a.name}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          _save(_s.copyWith(ambient: a));
          // Hear it straight away rather than at the next focus block.
          widget.sounds.preview(a, volume: _s.ambientVolume);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _accent : Colors.grey.shade200,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(_icon(a), color: selected ? _accent : _muted, size: 24),
              const SizedBox(height: 6),
              Text(
                _label(l, a),
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _accent : _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switch({
    required String key,
    required IconData icon,
    required String title,
    required String body,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      key: Key(key),
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: _accent,
      secondary: Icon(icon, color: value ? _accent : _muted),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _ink,
        ),
      ),
      subtitle: Text(
        body,
        style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
      ),
    );
  }
}
