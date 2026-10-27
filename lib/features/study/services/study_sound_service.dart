import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'study_timer_service.dart' show StudyPhase;

/// Background sound under a focus block.
enum StudyAmbient {
  off(null),
  rain('audio/study/study_bg_rain.wav'),
  white('audio/study/study_bg_white.wav'),
  brown('audio/study/study_bg_brown.wav');

  /// Path relative to `assets/`, as [AssetSource] wants it.
  final String? asset;
  const StudyAmbient(this.asset);
}

/// One-shot cues.
enum StudyCue {
  start('audio/study/study_start.wav'),
  pause('audio/study/study_pause.wav'),
  resume('audio/study/study_resume.wav'),
  skip('audio/study/study_skip.wav'),
  count('audio/study/study_count.wav');

  final String asset;
  const StudyCue(this.asset);
}

@immutable
class StudySoundSettings {
  /// Chimes for start / pause / resume / skip, and the distinct phase-end
  /// chimes the alarms play.
  final bool chimes;

  /// 3-2-1 ticks in the last seconds of every block and break.
  final bool countdown;

  /// A quiet tick-tock during focus.
  final bool ticking;

  final StudyAmbient ambient;

  /// 0–1, for [ambient].
  final double ambientVolume;

  const StudySoundSettings({
    this.chimes = true,
    this.countdown = true,
    this.ticking = false,
    this.ambient = StudyAmbient.off,
    this.ambientVolume = 0.5,
  });

  StudySoundSettings copyWith({
    bool? chimes,
    bool? countdown,
    bool? ticking,
    StudyAmbient? ambient,
    double? ambientVolume,
  }) => StudySoundSettings(
    chimes: chimes ?? this.chimes,
    countdown: countdown ?? this.countdown,
    ticking: ticking ?? this.ticking,
    ambient: ambient ?? this.ambient,
    ambientVolume: ambientVolume ?? this.ambientVolume,
  );

  @override
  bool operator ==(Object other) =>
      other is StudySoundSettings &&
      other.chimes == chimes &&
      other.countdown == countdown &&
      other.ticking == ticking &&
      other.ambient == ambient &&
      other.ambientVolume == ambientVolume;

  @override
  int get hashCode =>
      Object.hash(chimes, countdown, ticking, ambient, ambientVolume);
}

/// The audio calls the sounds make, behind a seam so tests can see what
/// plays without a device.
abstract class StudyAudio {
  Future<void> cue(String asset, double volume);

  /// Starts (or re-points) looping [channel] at [asset].
  Future<void> loop(String channel, String asset, double volume);

  Future<void> setLoopVolume(String channel, double volume);
  Future<void> stopLoop(String channel);
}

class AudioPlayersStudyAudio implements StudyAudio {
  // Mix rather than take focus: someone studying to their own music should
  // hear a chime over it, not have it paused.
  static final _mix = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();
  // Loops keep a wake lock so they carry on with the screen off.
  static final _mixAwake = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
    stayAwake: true,
  ).build();

  final AudioPlayer _cue = AudioPlayer(playerId: 'study_cue');
  final Map<String, AudioPlayer> _loops = {};
  final Map<String, String> _loopAssets = {};
  bool _cueReady = false;

  @override
  Future<void> cue(String asset, double volume) async {
    if (!_cueReady) {
      await _cue.setAudioContext(_mix);
      await _cue.setPlayerMode(PlayerMode.lowLatency);
      _cueReady = true;
    }
    await _cue.stop();
    await _cue.play(AssetSource(asset), volume: volume);
  }

  @override
  Future<void> loop(String channel, String asset, double volume) async {
    var player = _loops[channel];
    if (player == null) {
      player = AudioPlayer(playerId: 'study_$channel');
      await player.setAudioContext(_mixAwake);
      await player.setReleaseMode(ReleaseMode.loop);
      _loops[channel] = player;
    }
    if (_loopAssets[channel] == asset && player.state == PlayerState.playing) {
      await player.setVolume(volume);
      return;
    }
    _loopAssets[channel] = asset;
    await player.stop();
    await player.play(AssetSource(asset), volume: volume);
  }

  @override
  Future<void> setLoopVolume(String channel, double volume) async =>
      _loops[channel]?.setVolume(volume);

  @override
  Future<void> stopLoop(String channel) async {
    _loopAssets.remove(channel);
    await _loops[channel]?.stop();
  }
}

/// Everything the study timer sounds like.
///
/// Cues are one-shots for what you just did. The background and the ticking
/// follow the session: on during a running focus block, off for breaks,
/// pauses and when the session ends. Phase-end chimes are not played here —
/// the boundary alarms play them, so they still sound with the phone locked
/// or the app closed (see [phaseEndAlarmSound]).
class StudySounds {
  static final StudySounds instance = StudySounds._(AudioPlayersStudyAudio());

  StudySounds._(this._audio);

  @visibleForTesting
  StudySounds.forTesting(this._audio);

  final StudyAudio _audio;

  static const _ambientChannel = 'ambient';
  static const _tickChannel = 'tick';
  static const _cueVolume = 0.8;
  static const _tickVolume = 0.35;

  static const _kChimes = 'study_sound_chimes';
  static const _kCountdown = 'study_sound_countdown';
  static const _kTicking = 'study_sound_ticking';
  static const _kAmbient = 'study_sound_ambient';
  static const _kAmbientVolume = 'study_sound_ambient_volume';

  final ValueNotifier<StudySoundSettings> settings = ValueNotifier(
    const StudySoundSettings(),
  );

  StudyPhase _phase = StudyPhase.stopped;
  bool _running = false;
  int? _lastCountdown;
  Timer? _previewStop;
  bool _previewing = false;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    settings.value = StudySoundSettings(
      chimes: p.getBool(_kChimes) ?? true,
      countdown: p.getBool(_kCountdown) ?? true,
      ticking: p.getBool(_kTicking) ?? false,
      ambient: StudyAmbient.values.firstWhere(
        (a) => a.name == p.getString(_kAmbient),
        orElse: () => StudyAmbient.off,
      ),
      ambientVolume: p.getDouble(_kAmbientVolume) ?? 0.5,
    );
  }

  Future<void> update(StudySoundSettings value) async {
    settings.value = value;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kChimes, value.chimes);
    await p.setBool(_kCountdown, value.countdown);
    await p.setBool(_kTicking, value.ticking);
    await p.setString(_kAmbient, value.ambient.name);
    await p.setDouble(_kAmbientVolume, value.ambientVolume);
    if (!_previewing) await _syncLoops();
  }

  /// A tap's chime, when chimes are on.
  Future<void> cue(StudyCue cue) async {
    if (!settings.value.chimes) return;
    await _safely(() => _audio.cue(cue.asset, _cueVolume));
  }

  /// Called once a second with the time left in the current phase. Ticks at
  /// 3, 2 and 1; the alarm takes over at 0.
  Future<void> onTimeLeft(int seconds) async {
    if (!_running || !settings.value.countdown) return;
    if (seconds < 1 || seconds > 3) {
      _lastCountdown = null;
      return;
    }
    if (_lastCountdown == seconds) return;
    _lastCountdown = seconds;
    await _safely(() => _audio.cue(StudyCue.count.asset, _cueVolume));
  }

  /// Where the session is; the background and ticking follow it.
  Future<void> follow({required StudyPhase phase, required bool running}) {
    if (phase == _phase && running == _running) return Future.value();
    _phase = phase;
    _running = running;
    _lastCountdown = null;
    if (_previewing) return Future.value();
    return _syncLoops();
  }

  bool get _inFocus => _running && _phase == StudyPhase.focus;

  Future<void> _syncLoops() async {
    final s = settings.value;
    final ambient = s.ambient.asset;
    await _safely(() async {
      if (_inFocus && ambient != null) {
        await _audio.loop(_ambientChannel, ambient, s.ambientVolume);
      } else {
        await _audio.stopLoop(_ambientChannel);
      }
      if (_inFocus && s.ticking) {
        await _audio.loop(_tickChannel, _tickAsset, _tickVolume);
      } else {
        await _audio.stopLoop(_tickChannel);
      }
    });
  }

  static const _tickAsset = 'audio/study/study_tick_loop.wav';

  /// Lets a background sound be heard from the settings sheet for a few
  /// seconds, then hands back to whatever the session wants.
  Future<void> preview(StudyAmbient ambient, {double? volume}) async {
    _previewStop?.cancel();
    final asset = ambient.asset;
    if (asset == null) {
      await endPreview();
      return;
    }
    _previewing = true;
    await _safely(
      () => _audio.loop(
        _ambientChannel,
        asset,
        volume ?? settings.value.ambientVolume,
      ),
    );
    _previewStop = Timer(const Duration(seconds: 6), endPreview);
  }

  Future<void> previewVolume(double volume) async {
    if (_previewing || _inFocus) {
      await _safely(() => _audio.setLoopVolume(_ambientChannel, volume));
    }
  }

  Future<void> endPreview() async {
    _previewStop?.cancel();
    if (!_previewing) return;
    _previewing = false;
    await _safely(() => _audio.stopLoop(_ambientChannel));
    await _syncLoops();
  }

  /// The chime a boundary alarm should play, or null for the default alarm
  /// sound when chimes are off. Back into focus is bright and rising; into a
  /// break is calm and falling, so you can tell which without looking.
  String? phaseEndAlarmSound(StudyPhase finishing) {
    if (!settings.value.chimes) return null;
    return finishing == StudyPhase.focus
        ? 'assets/audio/study/study_focus_done.wav'
        : 'assets/audio/study/study_break_over.wav';
  }

  /// How long the phase-end chimes last, so the alarm can be let go once
  /// they have played.
  static const phaseEndChimeLength = Duration(milliseconds: 2600);

  Future<void> _safely(Future<void> Function() body) async {
    try {
      await body();
    } catch (e) {
      // A sound that fails to play must never break the timer.
      debugPrint('📚🔊 Study sound failed: $e');
    }
  }
}
