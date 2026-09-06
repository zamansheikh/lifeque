import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which version's notes the user has already been shown.
class WhatsNewService {
  WhatsNewService(this._prefs);

  static const String _key = 'whats_new_last_seen_version';

  final SharedPreferences _prefs;

  /// Whether to show the notes for [version].
  ///
  /// True on a fresh install as well as an update — for a first release the
  /// notes double as an introduction to what the app does. It shows once
  /// either way: [markSeen] records the version and the answer turns false.
  bool shouldShow(String version) => _prefs.getString(_key) != version;

  /// True the first time the app runs, before anything has been recorded.
  bool get isFirstRun => _prefs.getString(_key) == null;

  Future<void> markSeen(String version) => _prefs.setString(_key, version);
}
