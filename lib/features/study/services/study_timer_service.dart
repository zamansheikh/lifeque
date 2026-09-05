import 'dart:async';
import 'dart:convert';

import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/alarm_sound_utils.dart';

enum StudyPhase {
  focus, // A focus block
  shortBreak, // The breather between blocks
  longBreak, // The longer rest after a set of blocks
  stopped,
}

extension StudyPhaseLabel on StudyPhase {
  String get label => switch (this) {
    StudyPhase.focus => 'Focus',
    StudyPhase.shortBreak => 'Short break',
    StudyPhase.longBreak => 'Long break',
    StudyPhase.stopped => 'Not running',
  };
}

class StudySession {
  final DateTime startTime;
  final int focusDuration; // minutes
  final int shortBreakDuration; // minutes
  final int longBreakDuration; // minutes
  final int cyclesBeforeLongBreak;

  const StudySession({
    required this.startTime,
    this.focusDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.cyclesBeforeLongBreak = 4,
  });

  Map<String, dynamic> toJson() => {
    'start': startTime.millisecondsSinceEpoch,
    'focus': focusDuration,
    'short': shortBreakDuration,
    'long': longBreakDuration,
    'cycles': cyclesBeforeLongBreak,
  };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    startTime: DateTime.fromMillisecondsSinceEpoch(json['start'] as int),
    focusDuration: json['focus'] as int,
    shortBreakDuration: json['short'] as int,
    longBreakDuration: json['long'] as int,
    cyclesBeforeLongBreak: json['cycles'] as int,
  );
}

/// One stretch of the session, pinned to the clock.
class StudySlot {
  final StudyPhase phase;
  final DateTime start;
  final DateTime end;

  /// Focus blocks finished before this slot began.
  final int cyclesDone;

  const StudySlot({
    required this.phase,
    required this.start,
    required this.end,
    required this.cyclesDone,
  });

  Duration get duration => end.difference(start);

  Map<String, dynamic> toJson() => {
    'p': phase.index,
    's': start.millisecondsSinceEpoch,
    'e': end.millisecondsSinceEpoch,
    'c': cyclesDone,
  };

  factory StudySlot.fromJson(Map<String, dynamic> json) => StudySlot(
    phase: StudyPhase.values[json['p'] as int],
    start: DateTime.fromMillisecondsSinceEpoch(json['s'] as int),
    end: DateTime.fromMillisecondsSinceEpoch(json['e'] as int),
    cyclesDone: json['c'] as int,
  );
}

/// A pomodoro timer that keeps running when the app doesn't.
///
/// The old version counted down a variable once a second, which meant the
/// session only advanced while the page was on screen: background the app
/// during a focus block and the phase never ended, no break alarm followed the
/// first one, and reopening the app restored whatever the counter happened to
/// say when Android suspended it.
///
/// This one plans the whole session as a list of clock-pinned [StudySlot]s and
/// arms an alarm for every boundary up front. The ticker is display only —
/// where you are in the session is always derived from the current time, so
/// closing the app, locking the phone, or killing it outright changes nothing.
class StudyTimerService {
  static StudyTimerService? _instance;
  static StudyTimerService get instance => _instance ??= StudyTimerService._();
  StudyTimerService._();

  static const String _storageKey = 'study_session_v2';

  /// Alarm ids are reserved as a contiguous block so the chain can be
  /// cancelled wholesale without tracking which ones are live.
  static const int _alarmIdBase = 1000;

  /// About three hours of pomodoro planned ahead. Every slot costs one
  /// AlarmManager round-trip to arm and another to cancel, so this is a
  /// balance between surviving a long session with the app closed and not
  /// making the pause button wait on forty platform calls.
  static const int _maxScheduledSlots = 12;

  /// The id block this service has ever used. Earlier builds planned twenty
  /// slots, so a sweep has to reach past the current dozen to clear alarms an
  /// old version left behind.
  static const int _reservedAlarmSlots = 20;

  StudySession? _session;
  List<StudySlot> _slots = const [];
  bool _paused = false;
  Duration _pausedRemaining = Duration.zero;

  Timer? _ticker;

  /// Ids currently sitting in AlarmManager. Cancelling used to blind-fire a
  /// stop at every id in the reserved block whether or not anything was
  /// scheduled there, which is most of why pause and resume felt sluggish.
  final Set<int> _liveAlarmIds = <int>{};

  /// Alarm work runs off the button's critical path but strictly in order —
  /// a pause immediately followed by a resume must not end up cancelling the
  /// alarms the resume just armed.
  Future<void> _alarmQueue = Future<void>.value();

  /// Alarms armed by a previous run of the process are live but unrecorded,
  /// so the first load re-arms from scratch rather than trusting them.
  bool _rearmedThisLaunch = false;

  /// Guards the tick-time rebuild below: the ticker fires every second, and a
  /// rebuild takes longer than that, so without this it would pile up calls.
  bool _extending = false;

  final _phaseController = StreamController<StudyPhase>.broadcast();
  final _timeController = StreamController<int>.broadcast();
  final _cycleController = StreamController<int>.broadcast();
  final _runningController = StreamController<bool>.broadcast();

  Stream<StudyPhase> get phaseStream => _phaseController.stream;
  Stream<int> get timeLeftStream => _timeController.stream;
  Stream<int> get cycleStream => _cycleController.stream;
  Stream<bool> get runningStream => _runningController.stream;

  StudySession? get session => _session;

  // ── Derived state ───────────────────────────────────────────────────────
  // Nothing below is stored; it is all read off the clock, which is what makes
  // the timer survive the app being closed.

  StudySlot? get _currentSlot {
    if (_session == null) return null;
    if (_paused) return _slots.isEmpty ? null : _slots.first;
    final now = DateTime.now();
    for (final slot in _slots) {
      if (now.isBefore(slot.end)) return slot;
    }
    return null;
  }

  StudyPhase get currentPhase {
    if (_session == null) return StudyPhase.stopped;
    return _currentSlot?.phase ?? StudyPhase.stopped;
  }

  StudyPhase get nextPhase {
    final slot = _currentSlot;
    if (slot == null) return StudyPhase.stopped;
    final index = _slots.indexOf(slot);
    if (index < 0 || index + 1 >= _slots.length) return StudyPhase.stopped;
    return _slots[index + 1].phase;
  }

  int get timeLeft {
    final slot = _currentSlot;
    if (slot == null) return 0;
    if (_paused) return _pausedRemaining.inSeconds;
    final left = slot.end.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  /// Length of the phase you are in, for drawing progress.
  ///
  /// Read from the slot rather than from the settings, so a phase that was
  /// resumed part-way through still draws a truthful ring.
  int get phaseDuration {
    final slot = _currentSlot;
    if (slot == null) return (_session?.focusDuration ?? 25) * 60;
    if (_paused) return slot.duration.inSeconds;
    return slot.duration.inSeconds;
  }

  int get completedCycles {
    if (_session == null) return 0;
    final slot = _currentSlot;
    if (slot != null) return slot.cyclesDone;
    return _slots.isEmpty ? 0 : _slots.last.cyclesDone;
  }

  bool get hasActiveSession => _session != null;
  bool get isPaused => _session != null && _paused;
  bool get isRunning => _session != null && !_paused;

  /// Hands alarm work to the background queue and returns at once.
  ///
  /// The UI has already been told what happened by the time this is called;
  /// making the user watch a spinner while AlarmManager is written to would
  /// be a poor trade for a button that should feel instant.
  void _queueAlarmWork(Future<void> Function() work) {
    _alarmQueue = _alarmQueue
        .then((_) => work())
        .catchError((Object e) => debugPrint('📚 Alarm work failed: $e'));
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────

  Future<void> startStudySession({
    int focusDuration = 25,
    int shortBreakDuration = 5,
    int longBreakDuration = 15,
    int cyclesBeforeLongBreak = 4,
  }) async {
    _session = StudySession(
      startTime: DateTime.now(),
      focusDuration: focusDuration,
      shortBreakDuration: shortBreakDuration,
      longBreakDuration: longBreakDuration,
      cyclesBeforeLongBreak: cyclesBeforeLongBreak,
    );
    _paused = false;
    _pausedRemaining = Duration.zero;
    _slots = _buildSlots(
      from: DateTime.now(),
      startPhase: StudyPhase.focus,
      cyclesDone: 0,
    );

    _startTicker();
    _emitAll();
    unawaited(_save());
    _queueAlarmWork(_armAlarms);
  }

  Future<void> pauseSession() async {
    if (!isRunning) return;
    final slot = _currentSlot;
    if (slot == null) {
      await stopSession();
      return;
    }

    _pausedRemaining = slot.end.difference(DateTime.now());
    if (_pausedRemaining.isNegative) _pausedRemaining = Duration.zero;

    // The slot list is rewritten to start at the paused phase so resuming can
    // simply replay it from the new "now".
    _slots = [
      StudySlot(
        phase: slot.phase,
        start: slot.start,
        end: slot.end,
        cyclesDone: slot.cyclesDone,
      ),
    ];
    _paused = true;
    _ticker?.cancel();
    _ticker = null;

    _emitAll();
    unawaited(_save());
    _queueAlarmWork(_cancelAlarms);
    debugPrint('📚 Session paused with ${_pausedRemaining.inSeconds}s left');
  }

  Future<void> resumeSession() async {
    if (!isPaused || _session == null) return;
    final slot = _slots.isEmpty ? null : _slots.first;
    if (slot == null) {
      await stopSession();
      return;
    }

    _paused = false;
    _slots = _buildSlots(
      from: DateTime.now(),
      startPhase: slot.phase,
      cyclesDone: slot.cyclesDone,
      firstPhaseLength: _pausedRemaining.inSeconds > 0
          ? _pausedRemaining
          : null,
    );
    _pausedRemaining = Duration.zero;

    _startTicker();
    _emitAll();
    unawaited(_save());
    _queueAlarmWork(_armAlarms);
    debugPrint('📚 Session resumed');
  }

  /// Jump straight to the next phase — the "I'm done early" button.
  Future<void> skipPhase() async {
    if (_session == null) return;
    final slot = _currentSlot;
    if (slot == null) {
      await stopSession();
      return;
    }

    final next = nextPhase;
    final cyclesDone =
        slot.cyclesDone + (slot.phase == StudyPhase.focus ? 1 : 0);

    _paused = false;
    _pausedRemaining = Duration.zero;
    _slots = _buildSlots(
      from: DateTime.now(),
      startPhase: next == StudyPhase.stopped ? StudyPhase.focus : next,
      cyclesDone: cyclesDone,
    );

    _startTicker();
    _emitAll();
    unawaited(_save());
    _queueAlarmWork(_armAlarms);
  }

  Future<void> stopSession() async {
    _ticker?.cancel();
    _ticker = null;
    _session = null;
    _slots = const [];
    _paused = false;
    _pausedRemaining = Duration.zero;

    _emitAll();
    _queueAlarmWork(_cancelAlarms);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Picks the session back up wherever the clock says it is.
  ///
  /// Called every time the page appears, so a session started three hours ago
  /// and left running in the background comes back on the right phase with the
  /// right countdown — and with its remaining alarms topped back up.
  Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      _emitAll();
      return;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _session = StudySession.fromJson(json['session'] as Map<String, dynamic>);
      _slots = (json['slots'] as List<dynamic>)
          .map((e) => StudySlot.fromJson(e as Map<String, dynamic>))
          .toList();
      _paused = json['paused'] as bool? ?? false;
      _pausedRemaining = Duration(seconds: json['remaining'] as int? ?? 0);
    } catch (e) {
      debugPrint('📚 Could not read the saved session, clearing it: $e');
      await prefs.remove(_storageKey);
      _session = null;
      _slots = const [];
      _emitAll();
      return;
    }

    if (_paused) {
      _emitAll();
      return;
    }

    // The plan may have run out while the app was away; rebuild the tail from
    // wherever the clock has landed.
    final now = DateTime.now();
    if (_slots.isEmpty || !now.isBefore(_slots.last.end)) {
      final last = _slots.isEmpty ? null : _slots.last;
      _slots = _buildSlots(
        from: now,
        startPhase: last?.phase == StudyPhase.focus
            ? StudyPhase.shortBreak
            : StudyPhase.focus,
        cyclesDone: last?.cyclesDone ?? 0,
      );
      unawaited(_save());
      _queueAlarmWork(_armAlarms);
    } else if (_slots.indexOf(_currentSlot ?? _slots.first) >
        _slots.length - 4) {
      // Getting close to the end of the plan: extend it and re-arm.
      _slots = _buildSlots(
        from: _currentSlot?.start ?? now,
        startPhase: _currentSlot?.phase ?? StudyPhase.focus,
        cyclesDone: _currentSlot?.cyclesDone ?? 0,
        firstPhaseLength: _currentSlot?.duration,
      );
      unawaited(_save());
      _queueAlarmWork(_armAlarms);
    } else if (!_rearmedThisLaunch) {
      // Plan is still good, but this process didn't arm it. Sweep the whole
      // reserved block — which clears the extra ids an older, twenty-slot
      // build would have left — then put the current plan back.
      _queueAlarmWork(() => _cancelAlarms(all: true));
      _queueAlarmWork(_armAlarms);
    }
    _rearmedThisLaunch = true;

    _startTicker();
    _emitAll();
  }

  // ── Planning ────────────────────────────────────────────────────────────

  /// Lays out the next [_maxScheduledSlots] phases end to end from [from].
  ///
  /// [firstPhaseLength] shortens the opening slot, which is how a resumed or
  /// reloaded phase keeps only the time it had left.
  List<StudySlot> _buildSlots({
    required DateTime from,
    required StudyPhase startPhase,
    required int cyclesDone,
    Duration? firstPhaseLength,
  }) {
    final session = _session!;
    final slots = <StudySlot>[];

    var cursor = from;
    var phase = startPhase;
    var cycles = cyclesDone;

    for (var i = 0; i < _maxScheduledSlots; i++) {
      final length = i == 0 && firstPhaseLength != null
          ? firstPhaseLength
          : _lengthOf(phase, session);
      final end = cursor.add(length);
      slots.add(
        StudySlot(phase: phase, start: cursor, end: end, cyclesDone: cycles),
      );

      cursor = end;
      if (phase == StudyPhase.focus) {
        cycles++;
        phase = cycles % session.cyclesBeforeLongBreak == 0
            ? StudyPhase.longBreak
            : StudyPhase.shortBreak;
      } else {
        phase = StudyPhase.focus;
      }
    }
    return slots;
  }

  Duration _lengthOf(StudyPhase phase, StudySession session) => switch (phase) {
    StudyPhase.focus => Duration(minutes: session.focusDuration),
    StudyPhase.shortBreak => Duration(minutes: session.shortBreakDuration),
    StudyPhase.longBreak => Duration(minutes: session.longBreakDuration),
    StudyPhase.stopped => Duration.zero,
  };

  // ── Alarms ──────────────────────────────────────────────────────────────

  /// Arms one alarm per phase boundary, for the whole plan.
  ///
  /// The point of scheduling ahead rather than one at a time: if the app is
  /// killed after the first alarm, every later break and focus block still
  /// announces itself.
  Future<void> _armAlarms() async {
    await _cancelAlarms();
    final now = DateTime.now();

    // The app's own alarm tone. This used to point at
    // 'packages/alarm/assets/alarm.mp3', which isn't bundled — every phase
    // alarm fired with a FileNotFoundException instead of a sound.
    final sound = await AlarmSoundUtils.getDefaultAlarmSound();

    for (var i = 0; i < _slots.length; i++) {
      final slot = _slots[i];
      if (!slot.end.isAfter(now)) continue;

      final next = i + 1 < _slots.length ? _slots[i + 1].phase : null;
      try {
        await Alarm.set(
          alarmSettings: AlarmSettings(
            id: _alarmIdBase + i,
            dateTime: slot.end,
            assetAudioPath: sound,
            loopAudio: false,
            vibrate: true,
            warningNotificationOnKill: false,
            androidFullScreenIntent: false,
            volumeSettings: VolumeSettings.fade(
              volume: 0.7,
              fadeDuration: const Duration(seconds: 2),
            ),
            notificationSettings: NotificationSettings(
              title: _boundaryTitle(slot.phase),
              body: _boundaryBody(slot.phase, next),
              stopButton: 'Got it',
              icon: 'notification_icon',
            ),
          ),
        );
        _liveAlarmIds.add(_alarmIdBase + i);
      } catch (e) {
        debugPrint('📚 Could not arm alarm ${_alarmIdBase + i}: $e');
      }
    }
    debugPrint('📚 Armed ${_liveAlarmIds.length} phase alarms');
  }

  /// Stops only what is actually scheduled.
  ///
  /// [all] sweeps the whole reserved block regardless — used once on load,
  /// where alarms armed by a previous run of the process are live but this
  /// instance has no record of them.
  Future<void> _cancelAlarms({bool all = false}) async {
    final ids = all
        ? [for (var i = 0; i < _reservedAlarmSlots; i++) _alarmIdBase + i]
        : _liveAlarmIds.toList();
    _liveAlarmIds.clear();

    for (final id in ids) {
      try {
        await Alarm.stop(id);
      } catch (_) {
        // Nothing scheduled under that id — nothing to do.
      }
    }
  }

  String _boundaryTitle(StudyPhase finishing) => switch (finishing) {
    StudyPhase.focus => 'Focus block done',
    StudyPhase.shortBreak => 'Break over',
    StudyPhase.longBreak => 'Long break over',
    StudyPhase.stopped => 'Study timer',
  };

  String _boundaryBody(StudyPhase finishing, StudyPhase? next) {
    final session = _session;
    if (session == null) return '';
    return switch (next) {
      StudyPhase.shortBreak =>
        'Take ${session.shortBreakDuration} minutes. Stand up, look away from the screen.',
      StudyPhase.longBreak =>
        'You\'ve earned a longer one — ${session.longBreakDuration} minutes.',
      StudyPhase.focus => 'Next up: ${session.focusDuration} minutes of focus.',
      _ => 'Session finished.',
    };
  }

  // ── Ticker ──────────────────────────────────────────────────────────────

  /// Display only. It never decides what phase you're in; it just notices when
  /// the clock has moved you into the next one.
  void _startTicker() {
    _ticker?.cancel();
    if (_session == null || _paused) return;

    var lastPhase = currentPhase;
    var lastCycles = completedCycles;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_session == null) {
        _ticker?.cancel();
        _ticker = null;
        return;
      }

      final phase = currentPhase;
      if (phase == StudyPhase.stopped) {
        // Ran off the end of the plan — extend it in place.
        if (!_extending) {
          _extending = true;
          loadSavedSession().whenComplete(() => _extending = false);
        }
        return;
      }

      _timeController.add(timeLeft);
      if (phase != lastPhase) {
        lastPhase = phase;
        _phaseController.add(phase);
      }
      final cycles = completedCycles;
      if (cycles != lastCycles) {
        lastCycles = cycles;
        _cycleController.add(cycles);
      }
    });
  }

  void _emitAll() {
    _phaseController.add(currentPhase);
    _timeController.add(timeLeft);
    _cycleController.add(completedCycles);
    _runningController.add(isRunning);
  }

  // ── Storage ─────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final session = _session;
    if (session == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'session': session.toJson(),
        'slots': _slots.map((s) => s.toJson()).toList(),
        'paused': _paused,
        'remaining': _pausedRemaining.inSeconds,
      }),
    );
  }

  void dispose() {
    _ticker?.cancel();
    _phaseController.close();
    _timeController.close();
    _cycleController.close();
    _runningController.close();
  }
}
