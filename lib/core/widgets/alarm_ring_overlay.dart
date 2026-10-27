import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/prayer_times/presentation/utils/prayer_l10n.dart';
import '../../l10n/app_localizations.dart';
import '../services/prayer_alarm_service.dart';
import '../utils/local_clock.dart';

/// Covers the whole app with a ringing screen while any alarm rings.
///
/// It sits in `MaterialApp.builder`, above the router, rather than being
/// pushed as a route: a ring opens the app through the splash screen, whose
/// redirect replaces the route stack and would take a pushed page with it.
/// Up here it shows on the first frame and stays until the ring ends —
/// stopped here, from the notification, or by the auto-stop.
class AlarmRingOverlay extends StatefulWidget {
  final Widget child;

  /// The router's dispatcher. While ringing, Back is claimed so it cannot
  /// quietly navigate the app hidden underneath.
  final BackButtonDispatcher? backButtonDispatcher;

  /// Ringing alarms. Defaults to the plugin's stream; tests pass their own.
  final Stream<AlarmSet>? ringing;

  /// Stops one alarm. Defaults to [Alarm.stop].
  final Future<void> Function(int id)? onStop;

  /// Which ringing alarms take over the screen. Prayer alarms by default:
  /// the study timer's block and break chimes are a nudge, not a wake-up,
  /// and get a notification instead.
  final bool Function(AlarmSettings alarm)? covers;

  const AlarmRingOverlay({
    super.key,
    required this.child,
    this.backButtonDispatcher,
    this.ringing,
    this.onStop,
    this.covers,
  });

  static bool isPrayerAlarm(AlarmSettings alarm) =>
      PrayerAlarmService.prayerForAlarmId(alarm.id) != null;

  @override
  State<AlarmRingOverlay> createState() => _AlarmRingOverlayState();
}

class _AlarmRingOverlayState extends State<AlarmRingOverlay> {
  StreamSubscription<AlarmSet>? _sub;
  List<AlarmSettings> _ringing = const [];
  ChildBackButtonDispatcher? _back;

  @override
  void initState() {
    super.initState();
    _sub = (widget.ringing ?? Alarm.ringing).listen((set) {
      if (!mounted) return;
      final covers = widget.covers ?? AlarmRingOverlay.isPrayerAlarm;
      final list = set.alarms.where(covers).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      setState(() => _ringing = list);
      _claimBack(list.isNotEmpty);
    });
  }

  void _claimBack(bool claim) {
    final root = widget.backButtonDispatcher;
    if (root == null) return;
    // Only once the router is listening — before that, Back never reaches
    // the dispatcher anyway, and Flutter asserts on deferring to it.
    if (claim && _back == null && root.hasCallbacks) {
      _back = root.createChildBackButtonDispatcher()
        ..addCallback(_swallowBack)
        ..takePriority();
    } else if (!claim && _back != null) {
      _back!.removeCallback(_swallowBack);
      root.forget(_back!);
      _back = null;
    }
  }

  Future<bool> _swallowBack() => SynchronousFuture(true);

  @override
  void dispose() {
    _sub?.cancel();
    _claimBack(false);
    super.dispose();
  }

  Future<void> _stop(int id) async {
    HapticFeedback.mediumImpact();
    // Hide at once; the plugin's stream confirms a moment later.
    setState(() => _ringing = _ringing.where((a) => a.id != id).toList());
    _claimBack(_ringing.isNotEmpty);
    await (widget.onStop ?? Alarm.stop)(id);
  }

  @override
  Widget build(BuildContext context) {
    final alarm = _ringing.firstOrNull;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (alarm != null)
          Positioned.fill(
            child: AlarmRingScreen(
              key: ValueKey(alarm.id),
              alarm: alarm,
              onStop: () => _stop(alarm.id),
            ),
          ),
      ],
    );
  }
}

/// The ringing screen: the time, what the alarm is for, and one large Stop.
class AlarmRingScreen extends StatefulWidget {
  final AlarmSettings alarm;
  final VoidCallback onStop;

  const AlarmRingScreen({super.key, required this.alarm, required this.onStop});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  static const _from = Color(0xFF0E4A30);
  static const _to = Color(0xFF123B2C);
  static const _gold = Color(0xFFF5D27A);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  late Timer _tick;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _onStop() {
    if (_stopping) return;
    setState(() => _stopping = true);
    widget.onStop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final prayer = PrayerAlarmService.prayerForAlarmId(widget.alarm.id);
    final config = prayer == null
        ? null
        : PrayerAlarmService().configFor(prayer);

    final header = prayer == null
        ? l.alarmRingGenericHeader
        : l.alarmRingHeader;
    final title = prayer != null
        ? prayerLabelFor(l, prayer)
        : widget.alarm.notificationSettings.title;
    final message = config != null
        ? PrayerAlarmService.ringMessage(l, config)
        : widget.alarm.notificationSettings.body;
    final now = DateTime.now();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _to,
      ),
      child: Material(
        color: _to,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_from, _to],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        size: 16,
                        color: _gold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        header,
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    Clock.hm(now),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Clock.period(now),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _PulsingIcon(animation: _pulse),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: FilledButton.icon(
                      key: const Key('alarm-ring-stop'),
                      onPressed: _stopping ? null : _onStop,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _to,
                        disabledBackgroundColor: Colors.white.withValues(
                          alpha: 0.6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      icon: const Icon(Icons.alarm_off_rounded, size: 26),
                      label: Text(
                        l.alarmRingStop,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (config != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      l.alarmRingAutoStop(config.alarmDurationMinutes),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A mosque in a gold disc with rings rippling out from it.
class _PulsingIcon extends StatelessWidget {
  final Animation<double> animation;

  const _PulsingIcon({required this.animation});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final offset in const [0.0, 0.5])
                _ripple((animation.value + offset) % 1),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF5D27A),
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  size: 48,
                  color: Color(0xFF123B2C),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ripple(double t) {
    final size = 96 + 84 * t;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFF5D27A).withValues(alpha: (1 - t) * 0.6),
          width: 2,
        ),
      ),
    );
  }
}
