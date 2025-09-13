import 'package:shared_preferences/shared_preferences.dart';

/// Utility class for managing alarm sound preferences
class AlarmSoundUtils {
  static const String _prayerAlarmSoundKey = 'prayer_alarm_sound';
  static const String _defaultAlarmSoundKey = 'default_alarm_sound';

  /// Available alarm sounds in the assets folder
  static const List<Map<String, String>> availableAlarmSounds = [
    {
      'name': 'Alarm Sound 1',
      'path': 'assets/audio/alarm_sound_1.mp3',
      'description': 'Traditional alarm tone',
    },
    {
      'name': 'Alarm Sound 2',
      'path': 'assets/audio/alarm_sound_2.mp3',
      'description': 'Gentle wake-up tone',
    },
    {
      'name': 'Alarm Sound 3',
      'path': 'assets/audio/alarm_sound_3.mp3',
      'description': 'Melodic alarm tone',
    },
  ];

  /// Get the currently selected prayer alarm sound
  static Future<String> getPrayerAlarmSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prayerAlarmSoundKey) ??
        availableAlarmSounds[0]['path']!;
  }

  /// Set the prayer alarm sound preference
  static Future<void> setPrayerAlarmSound(String soundPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prayerAlarmSoundKey, soundPath);
  }

  /// Get the default alarm sound for other features
  static Future<String> getDefaultAlarmSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultAlarmSoundKey) ??
        availableAlarmSounds[0]['path']!;
  }

  /// Set the default alarm sound preference
  static Future<void> setDefaultAlarmSound(String soundPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultAlarmSoundKey, soundPath);
  }

  /// Get alarm sound name by path
  static String getAlarmSoundName(String path) {
    final sound = availableAlarmSounds.firstWhere(
      (sound) => sound['path'] == path,
      orElse: () => availableAlarmSounds[0],
    );
    return sound['name']!;
  }

  /// Validate if the alarm sound path exists in available sounds
  static bool isValidAlarmSound(String path) {
    return availableAlarmSounds.any((sound) => sound['path'] == path);
  }
}
