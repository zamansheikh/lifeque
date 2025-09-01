import 'dart:async';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StudyPhase {
  focus, // 25-30 minute focus session
  shortBreak, // 5 minute break
  longBreak, // 15-30 minute break
  stopped,
}

class StudySession {
  final DateTime startTime;
  final int focusDuration; // in minutes
  final int shortBreakDuration; // in minutes
  final int longBreakDuration; // in minutes
  final int cyclesBeforeLongBreak;

  StudySession({
    required this.startTime,
    this.focusDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.cyclesBeforeLongBreak = 4,
  });
}

class StudyTimerService {
  static StudyTimerService? _instance;
  static StudyTimerService get instance => _instance ??= StudyTimerService._();
  StudyTimerService._();

  // Current session state
  StudySession? _currentSession;
  StudyPhase _currentPhase = StudyPhase.stopped;
  int _completedCycles = 0;
  Timer? _timer;
  DateTime? _phaseStartTime;
  int _currentPhaseTimeLeft = 0; // in seconds
  bool _isPaused = false; // Track if timer is paused

  // Stream controllers for UI updates
  final StreamController<StudyPhase> _phaseController =
      StreamController.broadcast();
  final StreamController<int> _timeController = StreamController.broadcast();
  final StreamController<int> _cycleController = StreamController.broadcast();
  final StreamController<bool> _runningController =
      StreamController.broadcast();

  // Getters for streams
  Stream<StudyPhase> get phaseStream => _phaseController.stream;
  Stream<int> get timeLeftStream => _timeController.stream;
  Stream<int> get cycleStream => _cycleController.stream;
  Stream<bool> get runningStream => _runningController.stream;

  // Getters for current state
  StudyPhase get currentPhase => _currentPhase;
  int get timeLeft => _currentPhaseTimeLeft;
  int get completedCycles => _completedCycles;
  bool get isRunning => _timer != null && !_isPaused;
  bool get isPaused =>
      _isPaused &&
      _currentSession != null &&
      _currentPhase != StudyPhase.stopped;
  bool get hasActiveSession =>
      _currentSession != null && _currentPhase != StudyPhase.stopped;

  void _updateRunningState() {
    _runningController.add(isRunning);
  }

  // Alarm IDs
  static const int _studyAlarmId = 1000;

  Future<void> startStudySession({
    int focusDuration = 25,
    int shortBreakDuration = 5,
    int longBreakDuration = 15,
    int cyclesBeforeLongBreak = 4,
  }) async {
    _currentSession = StudySession(
      startTime: DateTime.now(),
      focusDuration: focusDuration,
      shortBreakDuration: shortBreakDuration,
      longBreakDuration: longBreakDuration,
      cyclesBeforeLongBreak: cyclesBeforeLongBreak,
    );

    _completedCycles = 0;
    await _startFocusPhase();
    await _saveSessionState();
  }

  Future<void> _startFocusPhase() async {
    _currentPhase = StudyPhase.focus;
    _phaseStartTime = DateTime.now();
    _currentPhaseTimeLeft = _currentSession!.focusDuration * 60;
    _isPaused = false;

    await _setAlarm(
      duration: Duration(minutes: _currentSession!.focusDuration),
      title: '🎯 Focus Session Complete!',
      body: 'Great work! Time for a break.',
    );

    _startTimer();
    _phaseController.add(_currentPhase);
    _cycleController.add(_completedCycles);
    _updateRunningState();
  }

  Future<void> _startShortBreak() async {
    _currentPhase = StudyPhase.shortBreak;
    _phaseStartTime = DateTime.now();
    _currentPhaseTimeLeft = _currentSession!.shortBreakDuration * 60;
    _isPaused = false;

    await _setAlarm(
      duration: Duration(minutes: _currentSession!.shortBreakDuration),
      title: '☕ Break Time Over!',
      body: 'Ready to get back to work?',
    );

    _startTimer();
    _phaseController.add(_currentPhase);
    _updateRunningState();
  }

  Future<void> _startLongBreak() async {
    _currentPhase = StudyPhase.longBreak;
    _phaseStartTime = DateTime.now();
    _currentPhaseTimeLeft = _currentSession!.longBreakDuration * 60;
    _isPaused = false;

    await _setAlarm(
      duration: Duration(minutes: _currentSession!.longBreakDuration),
      title: '🌟 Long Break Complete!',
      body: 'Refreshed and ready for the next session?',
    );

    _startTimer();
    _phaseController.add(_currentPhase);
    _updateRunningState();
  }

  // Track if alarm is currently set
  bool _alarmIsSet = false;

  Future<void> _setAlarm({
    required Duration duration,
    required String title,
    required String body,
  }) async {
    // Cancel any existing alarm
    if (_alarmIsSet) {
      await Alarm.stop(_studyAlarmId);
      _alarmIsSet = false;
    }

    // Only set if duration is positive
    if (duration.inSeconds <= 0) return;

    final alarmTime = DateTime.now().add(duration);

    final alarmSettings = AlarmSettings(
      id: _studyAlarmId,
      dateTime: alarmTime,
      assetAudioPath:
          'packages/alarm/assets/alarm.mp3', // Use default alarm package sound
      loopAudio: false,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: Duration(seconds: 2),
      ),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'Stop',
        icon: 'notification_icon',
      ),
    );

    try {
      await Alarm.set(alarmSettings: alarmSettings);
      _alarmIsSet = true;
      debugPrint('📅 Alarm set for ${alarmTime.toString()}');
    } catch (e) {
      debugPrint('Failed to set study alarm: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentPhaseTimeLeft > 0) {
        _currentPhaseTimeLeft--;
        _timeController.add(_currentPhaseTimeLeft);
      } else {
        // Phase completed
        _onPhaseComplete();
      }
    });
  }

  Future<void> _onPhaseComplete() async {
    _timer?.cancel();

    switch (_currentPhase) {
      case StudyPhase.focus:
        _completedCycles++;
        _cycleController.add(_completedCycles);

        // Check if it's time for a long break
        if (_completedCycles % _currentSession!.cyclesBeforeLongBreak == 0) {
          await _startLongBreak();
        } else {
          await _startShortBreak();
        }
        break;

      case StudyPhase.shortBreak:
      case StudyPhase.longBreak:
        await _startFocusPhase();
        break;

      case StudyPhase.stopped:
        break;
    }

    await _saveSessionState();
  }

  Future<void> stopSession() async {
    _timer?.cancel();
    _timer = null;
    _isPaused = false;

    if (_alarmIsSet) {
      await Alarm.stop(_studyAlarmId);
      _alarmIsSet = false;
    }

    _currentSession = null;
    _currentPhase = StudyPhase.stopped;
    _completedCycles = 0;
    _currentPhaseTimeLeft = 0;

    _phaseController.add(_currentPhase);
    _timeController.add(_currentPhaseTimeLeft);
    _cycleController.add(_completedCycles);
    _updateRunningState();

    await _clearSessionState();
  }

  Future<void> pauseSession() async {
    if (!isRunning) return;

    _timer?.cancel();
    _timer = null;
    _isPaused = true;

    if (_alarmIsSet) {
      await Alarm.stop(_studyAlarmId);
      _alarmIsSet = false;
    }
    await _saveSessionState();
    debugPrint('⏸️ Session paused');
    _updateRunningState();
  }

  Future<void> resumeSession() async {
    if (!isPaused) return;

    _isPaused = false;

    if (_currentSession != null && _currentPhase != StudyPhase.stopped) {
      // Recalculate remaining time
      final elapsed = DateTime.now().difference(_phaseStartTime!);
      final phaseDuration = _getPhaseDuration(_currentPhase);
      _currentPhaseTimeLeft = (phaseDuration.inSeconds - elapsed.inSeconds)
          .clamp(0, phaseDuration.inSeconds);

      if (_currentPhaseTimeLeft > 0) {
        await _setAlarm(
          duration: Duration(seconds: _currentPhaseTimeLeft),
          title: _getPhaseCompleteTitle(_currentPhase),
          body: _getPhaseCompleteBody(_currentPhase),
        );
        _startTimer();
        debugPrint('▶️ Session resumed');
        _updateRunningState();
      } else {
        await _onPhaseComplete();
      }
    }
  }

  Duration _getPhaseDuration(StudyPhase phase) {
    switch (phase) {
      case StudyPhase.focus:
        return Duration(minutes: _currentSession!.focusDuration);
      case StudyPhase.shortBreak:
        return Duration(minutes: _currentSession!.shortBreakDuration);
      case StudyPhase.longBreak:
        return Duration(minutes: _currentSession!.longBreakDuration);
      case StudyPhase.stopped:
        return Duration.zero;
    }
  }

  String _getPhaseCompleteTitle(StudyPhase phase) {
    switch (phase) {
      case StudyPhase.focus:
        return '🎯 Focus Session Complete!';
      case StudyPhase.shortBreak:
        return '☕ Break Time Over!';
      case StudyPhase.longBreak:
        return '🌟 Long Break Complete!';
      case StudyPhase.stopped:
        return '';
    }
  }

  String _getPhaseCompleteBody(StudyPhase phase) {
    switch (phase) {
      case StudyPhase.focus:
        return 'Great work! Time for a break.';
      case StudyPhase.shortBreak:
        return 'Ready to get back to work?';
      case StudyPhase.longBreak:
        return 'Refreshed and ready for the next session?';
      case StudyPhase.stopped:
        return '';
    }
  }

  // Persistence methods
  Future<void> _saveSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentSession != null) {
      await prefs.setString('study_session', _encodeSession());
    }
  }

  Future<void> _clearSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('study_session');
  }

  Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = prefs.getString('study_session');
    if (sessionData != null) {
      _decodeSession(sessionData);
      if (_currentSession != null) {
        await resumeSession();
      }
    }
  }

  String _encodeSession() {
    // Simple encoding for session state
    return '${_currentSession!.startTime.millisecondsSinceEpoch}|'
        '${_currentSession!.focusDuration}|'
        '${_currentSession!.shortBreakDuration}|'
        '${_currentSession!.longBreakDuration}|'
        '${_currentSession!.cyclesBeforeLongBreak}|'
        '${_currentPhase.index}|'
        '${_completedCycles}|'
        '${_phaseStartTime?.millisecondsSinceEpoch ?? 0}';
  }

  void _decodeSession(String data) {
    final parts = data.split('|');
    if (parts.length >= 8) {
      _currentSession = StudySession(
        startTime: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0])),
        focusDuration: int.parse(parts[1]),
        shortBreakDuration: int.parse(parts[2]),
        longBreakDuration: int.parse(parts[3]),
        cyclesBeforeLongBreak: int.parse(parts[4]),
      );
      _currentPhase = StudyPhase.values[int.parse(parts[5])];
      _completedCycles = int.parse(parts[6]);
      final phaseStartMs = int.parse(parts[7]);
      _phaseStartTime = phaseStartMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(phaseStartMs)
          : null;
    }
  }

  void dispose() {
    _timer?.cancel();
    _phaseController.close();
    _timeController.close();
    _cycleController.close();
  }
}
