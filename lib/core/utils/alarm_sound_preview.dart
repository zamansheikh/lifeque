import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays alarm sounds on demand so a sound can be auditioned before it's
/// chosen — otherwise the first time you hear it is when the alarm fires.
///
/// One player for the whole app: starting a preview stops whatever was
/// already playing, so tapping down a list never stacks sounds on top of
/// each other.
class AlarmSoundPreview {
  static final AlarmSoundPreview instance = AlarmSoundPreview._();

  AlarmSoundPreview._() {
    _player.onPlayerComplete.listen((_) => _setPlaying(null));
  }

  final AudioPlayer _player = AudioPlayer();

  /// Asset path currently playing, or null. Widgets listen to this to show
  /// a play/stop state per row.
  final ValueNotifier<String?> playing = ValueNotifier<String?>(null);

  /// Previews are auditions, not alarms — cap them so a long adhan doesn't
  /// keep going after the user has moved on.
  static const _maxPreview = Duration(seconds: 12);
  Timer? _stopTimer;

  void _setPlaying(String? path) {
    _stopTimer?.cancel();
    playing.value = path;
  }

  /// Play [assetPath] (a `assets/audio/…` path), or stop if it's already
  /// the one playing.
  Future<void> toggle(String assetPath) async {
    if (playing.value == assetPath) {
      await stop();
      return;
    }
    await stop();
    try {
      // AssetSource paths are relative to the `assets/` bundle root.
      final relative = assetPath.startsWith('assets/')
          ? assetPath.substring('assets/'.length)
          : assetPath;
      await _player.play(AssetSource(relative));
      _setPlaying(assetPath);
      _stopTimer = Timer(_maxPreview, stop);
    } catch (e) {
      debugPrint('🔊 Could not preview $assetPath: $e');
      _setPlaying(null);
      rethrow;
    }
  }

  Future<void> stop() async {
    _stopTimer?.cancel();
    await _player.stop();
    _setPlaying(null);
  }

  Future<void> dispose() async {
    _stopTimer?.cancel();
    await _player.dispose();
    playing.dispose();
  }
}
