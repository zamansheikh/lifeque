import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../services/study_timer_service.dart';

extension StudyPhaseUI on StudyPhase {
  Color get color => switch (this) {
    StudyPhase.focus => const Color(0xFF4F46E5),
    StudyPhase.shortBreak => const Color(0xFF059669),
    StudyPhase.longBreak => const Color(0xFF0891B2),
    StudyPhase.stopped => const Color(0xFF64748B),
  };

  Color get tint => switch (this) {
    StudyPhase.focus => const Color(0xFFF1F1FE),
    StudyPhase.shortBreak => const Color(0xFFECFDF5),
    StudyPhase.longBreak => const Color(0xFFECFEFF),
    StudyPhase.stopped => const Color(0xFFF8FAFC),
  };

  IconData get icon => switch (this) {
    StudyPhase.focus => Icons.center_focus_strong_rounded,
    StudyPhase.shortBreak => Icons.local_cafe_rounded,
    StudyPhase.longBreak => Icons.self_improvement_rounded,
    StudyPhase.stopped => Icons.timer_outlined,
  };

  String get displayName => switch (this) {
    StudyPhase.focus => 'Focus',
    StudyPhase.shortBreak => 'Short break',
    StudyPhase.longBreak => 'Long break',
    StudyPhase.stopped => 'Ready when you are',
  };
}

class StudyTimerPage extends StatefulWidget {
  const StudyTimerPage({super.key});

  @override
  State<StudyTimerPage> createState() => _StudyTimerPageState();
}

class _StudyTimerPageState extends State<StudyTimerPage>
    with WidgetsBindingObserver {
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);

  final StudyTimerService _service = StudyTimerService.instance;

  int _focusDuration = 25;
  int _shortBreakDuration = 5;
  int _longBreakDuration = 15;
  int _cyclesBeforeLongBreak = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service.loadSavedSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the background is exactly when the displayed phase is
    // most likely to be stale — the clock has moved on without us.
    if (state == AppLifecycleState.resumed) {
      _service.loadSavedSession();
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StudyPhase>(
      stream: _service.phaseStream,
      initialData: _service.currentPhase,
      builder: (context, phaseSnapshot) {
        final phase = phaseSnapshot.data ?? StudyPhase.stopped;
        final running = _service.hasActiveSession;

        return Scaffold(
          backgroundColor: phase.tint,
          drawer: const AppDrawer(currentRoute: '/study-timer'),
          appBar: AppBar(
            title: const Text(
              'Study Timer',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: _ink,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: _muted),
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: _muted),
                tooltip: 'Timer settings',
                onPressed: _showSettings,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                children: [
                  _dial(phase),
                  const SizedBox(height: 20),
                  _cycleDots(phase),
                  const SizedBox(height: 24),
                  _controls(phase),
                  const SizedBox(height: 24),
                  running ? _sessionCard(phase) : _planCard(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── The dial ────────────────────────────────────────────────────────────

  Widget _dial(StudyPhase phase) {
    return StreamBuilder<int>(
      stream: _service.timeLeftStream,
      initialData: _service.timeLeft,
      builder: (context, snapshot) {
        final timeLeft = snapshot.data ?? 0;
        final total = _service.hasActiveSession
            ? _service.phaseDuration
            : _focusDuration * 60;
        final elapsed = (total - timeLeft).clamp(0, total);
        final progress = total > 0 ? elapsed / total : 0.0;

        return SizedBox(
          width: 264,
          height: 264,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The ring is the whole status display: colour says which phase,
              // sweep says how far in, and it stays legible from across a desk.
              SizedBox.expand(
                child: CustomPaint(
                  painter: _DialPainter(
                    progress: progress,
                    color: phase.color,
                    track: phase.color.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(phase.icon, size: 22, color: phase.color),
                  const SizedBox(height: 8),
                  Text(
                    phase.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: phase.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatTime(
                      _service.hasActiveSession
                          ? timeLeft
                          : _focusDuration * 60,
                    ),
                    style: const TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      height: 1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _subtitle(phase),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _subtitle(StudyPhase phase) {
    if (!_service.hasActiveSession) return '$_focusDuration min to start';
    if (_service.isPaused) return 'Paused';
    final next = _service.nextPhase;
    if (next == StudyPhase.stopped) return '';
    return 'Then ${next.displayName.toLowerCase()}';
  }

  // ── Cycle dots ──────────────────────────────────────────────────────────

  /// Where you are in the run up to the long break, at a glance — a count like
  /// "3 cycles" never told you how many were left before the long one.
  Widget _cycleDots(StudyPhase phase) {
    return StreamBuilder<int>(
      stream: _service.cycleStream,
      initialData: _service.completedCycles,
      builder: (context, snapshot) {
        final done = snapshot.data ?? 0;
        final perSet =
            _service.session?.cyclesBeforeLongBreak ?? _cyclesBeforeLongBreak;
        final inSet = perSet == 0 ? 0 : done % perSet;
        final active = _service.hasActiveSession;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < perSet; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: i < inSet ? 22 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: i < inSet
                            ? phase.color
                            : phase.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              active
                  ? '$done ${done == 1 ? 'block' : 'blocks'} done · '
                        '${perSet - inSet} to the long break'
                  : '$perSet blocks, then a long break',
              style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
            ),
          ],
        );
      },
    );
  }

  // ── Controls ────────────────────────────────────────────────────────────

  Widget _controls(StudyPhase phase) {
    return StreamBuilder<bool>(
      stream: _service.runningStream,
      initialData: _service.isRunning,
      builder: (context, snapshot) {
        if (!_service.hasActiveSession) {
          return SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text('Start focusing'),
              style: FilledButton.styleFrom(
                backgroundColor: StudyPhase.focus.color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          );
        }

        final running = _service.isRunning;
        return Row(
          children: [
            Expanded(
              child: _secondaryButton(
                icon: Icons.stop_rounded,
                label: 'Stop',
                color: const Color(0xFFDC2626),
                onTap: _confirmStop,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: running ? _pause : _resume,
                icon: Icon(
                  running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 22,
                ),
                label: Text(running ? 'Pause' : 'Resume'),
                style: FilledButton.styleFrom(
                  backgroundColor: phase.color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _secondaryButton(
                icon: Icons.skip_next_rounded,
                label: 'Skip',
                color: _muted,
                onTap: _skip,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _secondaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cards ───────────────────────────────────────────────────────────────

  Widget _sessionCard(StudyPhase phase) {
    final session = _service.session;
    if (session == null) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: _service.cycleStream,
      initialData: _service.completedCycles,
      builder: (context, snapshot) {
        final done = snapshot.data ?? 0;
        final focusMinutes = done * session.focusDuration;

        return _card(
          child: Column(
            children: [
              Row(
                children: [
                  _stat(
                    'Focused',
                    focusMinutes >= 60
                        ? '${(focusMinutes / 60).toStringAsFixed(1)} h'
                        : '$focusMinutes min',
                    Icons.timelapse_rounded,
                    StudyPhase.focus.color,
                  ),
                  _divider(),
                  _stat(
                    'Blocks',
                    '$done',
                    Icons.done_all_rounded,
                    StudyPhase.shortBreak.color,
                  ),
                  _divider(),
                  _stat(
                    'Started',
                    _formatClock(session.startTime),
                    Icons.schedule_rounded,
                    _muted,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: phase.color.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_rounded,
                      size: 15,
                      color: phase.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alarms are set for every block and break, so you can '
                        'put the phone down.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _planCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Your plan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showSettings,
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Adjust'),
                style: TextButton.styleFrom(
                  foregroundColor: StudyPhase.focus.color,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(
                'Focus',
                '$_focusDuration min',
                StudyPhase.focus.icon,
                StudyPhase.focus.color,
              ),
              _divider(),
              _stat(
                'Break',
                '$_shortBreakDuration min',
                StudyPhase.shortBreak.icon,
                StudyPhase.shortBreak.color,
              ),
              _divider(),
              _stat(
                'Long break',
                '$_longBreakDuration min',
                StudyPhase.longBreak.icon,
                StudyPhase.longBreak.color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 40, color: const Color(0xFFE2E8F0));

  Widget _stat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _start() async {
    await _service.startStudySession(
      focusDuration: _focusDuration,
      shortBreakDuration: _shortBreakDuration,
      longBreakDuration: _longBreakDuration,
      cyclesBeforeLongBreak: _cyclesBeforeLongBreak,
    );
    if (mounted) setState(() {});
  }

  Future<void> _pause() async {
    await _service.pauseSession();
    if (mounted) setState(() {});
  }

  Future<void> _resume() async {
    await _service.resumeSession();
    if (mounted) setState(() {});
  }

  Future<void> _skip() async {
    await _service.skipPhase();
    if (mounted) setState(() {});
  }

  Future<void> _confirmStop() async {
    final stop = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'End this session?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'The countdown stops and every alarm for the rest of the session is '
          'cancelled.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('End session'),
          ),
        ],
      ),
    );

    if (stop == true) {
      await _service.stopSession();
      if (mounted) setState(() {});
    }
  }

  Future<void> _showSettings() async {
    final running = _service.hasActiveSession;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
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
              const Text(
                'Timer settings',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              if (running) ...[
                const SizedBox(height: 8),
                Text(
                  'A session is running — these take effect the next time you '
                  'start one.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey[600],
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _slider(
                'Focus block',
                _focusDuration,
                10,
                60,
                5,
                StudyPhase.focus.color,
                (v) => setSheetState(() => _focusDuration = v),
                (v) => '$v min',
              ),
              _slider(
                'Short break',
                _shortBreakDuration,
                3,
                15,
                1,
                StudyPhase.shortBreak.color,
                (v) => setSheetState(() => _shortBreakDuration = v),
                (v) => '$v min',
              ),
              _slider(
                'Long break',
                _longBreakDuration,
                10,
                45,
                5,
                StudyPhase.longBreak.color,
                (v) => setSheetState(() => _longBreakDuration = v),
                (v) => '$v min',
              ),
              _slider(
                'Blocks before a long break',
                _cyclesBeforeLongBreak,
                2,
                8,
                1,
                _muted,
                (v) => setSheetState(() => _cyclesBeforeLongBreak = v),
                (v) => '$v',
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: StudyPhase.focus.color,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (mounted) setState(() {});
  }

  Widget _slider(
    String label,
    int value,
    int min,
    int max,
    int step,
    Color color,
    ValueChanged<int> onChanged,
    String Function(int) format,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  format(value),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.15),
              overlayColor: color.withValues(alpha: 0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: ((max - min) / step).round(),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Formatting ──────────────────────────────────────────────────────────

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  String _formatClock(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

/// The progress ring: a rounded sweep on a soft track, starting at twelve.
class _DialPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  const _DialPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);

    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (progress <= 0) return;
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
