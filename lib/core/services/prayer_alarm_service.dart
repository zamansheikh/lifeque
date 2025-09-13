import 'dart:async';
import 'dart:developer' as developer;
import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import '../utils/salah_time_calculator.dart';
import '../utils/alarm_sound_utils.dart';

enum PrayerAlarmType { beforePrayerEnd, fixedTime, afterPrayerStart }

class PrayerAlarmConfig {
  final String prayerName;
  final PrayerAlarmType type;
  final int minutesBeforeEnd; // For beforePrayerEnd type
  final int minutesAfterStart; // For afterPrayerStart type
  final DateTime? fixedTime; // For fixedTime type
  final bool isEnabled;
  final String soundPath;

  PrayerAlarmConfig({
    required this.prayerName,
    required this.type,
    this.minutesBeforeEnd = 5,
    this.minutesAfterStart = 5,
    this.fixedTime,
    this.isEnabled = true,
    this.soundPath = 'assets/audio/alarm_sound_1.mp3', // Use custom sound
  });

  Map<String, dynamic> toJson() {
    return {
      'prayerName': prayerName,
      'type': type.index,
      'minutesBeforeEnd': minutesBeforeEnd,
      'minutesAfterStart': minutesAfterStart,
      'fixedTime': fixedTime?.millisecondsSinceEpoch,
      'isEnabled': isEnabled,
      'soundPath': soundPath,
    };
  }

  factory PrayerAlarmConfig.fromJson(Map<String, dynamic> json) {
    return PrayerAlarmConfig(
      prayerName: json['prayerName'],
      type:
          PrayerAlarmType.values[json['type'] is String
              ? int.parse(json['type'])
              : json['type']],
      minutesBeforeEnd: json['minutesBeforeEnd'] is String
          ? int.parse(json['minutesBeforeEnd'])
          : (json['minutesBeforeEnd'] ?? 5),
      minutesAfterStart: json['minutesAfterStart'] is String
          ? int.parse(json['minutesAfterStart'])
          : (json['minutesAfterStart'] ?? 5),
      fixedTime: json['fixedTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['fixedTime'] is String
                  ? int.parse(json['fixedTime'])
                  : json['fixedTime'],
            )
          : null,
      isEnabled: json['isEnabled'] ?? true,
      soundPath: json['soundPath'] ?? 'assets/audio/alarm_sound_1.mp3',
    );
  }
}

class PrayerAlarmService {
  static final PrayerAlarmService _instance = PrayerAlarmService._internal();
  factory PrayerAlarmService() => _instance;
  PrayerAlarmService._internal();

  static const String _prefsKey = 'prayer_alarms';
  static const String _enabledKey = 'prayer_alarms_enabled';

  final StreamController<List<PrayerAlarmConfig>> _alarmsController =
      StreamController<List<PrayerAlarmConfig>>.broadcast();
  final StreamController<bool> _enabledController =
      StreamController<bool>.broadcast();

  List<PrayerAlarmConfig> _alarms = [];
  bool _isEnabled = true;
  Timer? _refreshTimer;

  // Base alarm IDs for prayers (to avoid conflicts with study timer)
  static const Map<String, int> _prayerAlarmIds = {
    'Fajr': 1000,
    'Dhuhr': 1001,
    'Asr': 1002,
    'Maghrib': 1003,
    'Isha': 1004,
  };

  Stream<List<PrayerAlarmConfig>> get alarmsStream => _alarmsController.stream;
  Stream<bool> get enabledStream => _enabledController.stream;
  List<PrayerAlarmConfig> get alarms => List.unmodifiable(_alarms);
  bool get isEnabled => _isEnabled;

  Future<void> initialize() async {
    developer.log('PrayerAlarmService: Initializing');

    // Initialize streams with default values to prevent null issues
    _enabledController.add(_isEnabled);
    _alarmsController.add(_alarms);

    await _loadSettings();
    await _loadAlarms();
    _startRefreshTimer();
    developer.log(
      'PrayerAlarmService: Initialized with ${_alarms.length} alarms',
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_enabledKey) ?? true;
    _enabledController.add(_isEnabled);
  }

  Future<void> _loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsData = prefs.getStringList(_prefsKey) ?? [];

      _alarms = alarmsData.map((alarmString) {
        final data = <String, dynamic>{};
        final parts = alarmString.split('|');
        for (final part in parts) {
          final keyValue = part.split(':');
          if (keyValue.length == 2) {
            final key = keyValue[0];
            final value = keyValue[1];
            if (key == 'type' ||
                key == 'minutesBeforeEnd' ||
                key == 'minutesAfterStart') {
              data[key] = int.parse(value);
            } else if (key == 'fixedTime') {
              data[key] = value != 'null' ? int.parse(value) : null;
            } else if (key == 'isEnabled') {
              data[key] = value == 'true';
            } else {
              data[key] = value;
            }
          }
        }
        return PrayerAlarmConfig.fromJson(data);
      }).toList();

      _alarmsController.add(_alarms);
    } catch (e) {
      developer.log(
        'PrayerAlarmService: Error loading alarms, clearing data: $e',
      );
      // Clear corrupted data and start fresh
      await clearAllAlarms();
    }
  }

  // Method to clear all stored alarm data
  Future<void> clearAllAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _alarms.clear();
    _alarmsController.add(_alarms);
    developer.log('PrayerAlarmService: All alarm data cleared');
  }

  // Diagnostic method to check service health
  Map<String, dynamic> getServiceDiagnostics() {
    return {
      'totalAlarms': _alarms.length,
      'isEnabled': _isEnabled,
      'alarmTypes': _alarms.map((a) => a.type.toString()).toList(),
      'prayerNames': _alarms.map((a) => a.prayerName).toList(),
      'streamControllersClosed': {
        'alarms': _alarmsController.isClosed,
        'enabled': _enabledController.isClosed,
      },
    };
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = _alarms.map((alarm) {
      final data = alarm.toJson();
      return data.entries.map((e) => '${e.key}:${e.value}').join('|');
    }).toList();

    await prefs.setStringList(_prefsKey, alarmsJson);
    _alarmsController.add(_alarms);
  }

  Future<void> addAlarm(PrayerAlarmConfig config) async {
    developer.log('PrayerAlarmService: Adding alarm for ${config.prayerName}');

    // Remove existing alarm for this prayer if any
    _alarms.removeWhere((alarm) => alarm.prayerName == config.prayerName);

    _alarms.add(config);
    await _saveAlarms();

    if (_isEnabled && config.isEnabled) {
      await _scheduleAlarm(config);
    }
  }

  Future<void> removeAlarm(String prayerName) async {
    developer.log('PrayerAlarmService: Removing alarm for $prayerName');

    _alarms.removeWhere((alarm) => alarm.prayerName == prayerName);
    await _saveAlarms();
    await _cancelAlarm(prayerName);
  }

  Future<void> updateAlarm(PrayerAlarmConfig config) async {
    developer.log(
      'PrayerAlarmService: Updating alarm for ${config.prayerName}',
    );

    final index = _alarms.indexWhere(
      (alarm) => alarm.prayerName == config.prayerName,
    );
    if (index != -1) {
      _alarms[index] = config;
      await _saveAlarms();

      // Cancel old alarm and schedule new one
      await _cancelAlarm(config.prayerName);
      if (_isEnabled && config.isEnabled) {
        await _scheduleAlarm(config);
      }
    }
  }

  Future<void> toggleGlobalAlarms(bool enabled) async {
    developer.log('PrayerAlarmService: Toggling global alarms to $enabled');

    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    _enabledController.add(_isEnabled);

    if (enabled) {
      await _scheduleAllAlarms();
    } else {
      await _cancelAllAlarms();
    }
  }

  Future<void> _scheduleAlarm(PrayerAlarmConfig config) async {
    final alarmId = _prayerAlarmIds[config.prayerName];
    if (alarmId == null) return;

    DateTime? alarmTime;

    if (config.type == PrayerAlarmType.fixedTime && config.fixedTime != null) {
      alarmTime = config.fixedTime!;
    } else if (config.type == PrayerAlarmType.beforePrayerEnd) {
      alarmTime = await _calculateBeforePrayerEndTime(
        config.prayerName,
        config.minutesBeforeEnd,
      );
    } else if (config.type == PrayerAlarmType.afterPrayerStart) {
      alarmTime = await _calculateAfterPrayerStartTime(
        config.prayerName,
        config.minutesAfterStart,
      );
    }

    if (alarmTime == null || alarmTime.isBefore(DateTime.now())) {
      developer.log(
        'PrayerAlarmService: Alarm time is in the past for ${config.prayerName}',
      );
      return;
    }

    // Get user's preferred alarm sound
    final alarmSoundPath = await AlarmSoundUtils.getPrayerAlarmSound();

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: alarmTime,
      assetAudioPath: alarmSoundPath, // Use user's preferred sound
      loopAudio: false,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: const Duration(seconds: 2),
      ),
      notificationSettings: NotificationSettings(
        title: '🕌 Prayer Time',
        body: _getAlarmMessage(config),
        stopButton: 'Stop',
        icon: 'notification_icon',
      ),
    );

    try {
      await Alarm.set(alarmSettings: alarmSettings);
      developer.log(
        'PrayerAlarmService: Scheduled alarm for ${config.prayerName} at $alarmTime',
      );
    } catch (e) {
      developer.log('PrayerAlarmService: Error scheduling alarm: $e');
    }
  }

  Future<DateTime?> _calculateBeforePrayerEndTime(
    String prayerName,
    int minutesBefore,
  ) async {
    try {
      // Get next occurrence of this prayer
      final calculator = SalahTimeCalculator(
        latitude: 23.8103, // Default to Dhaka, should get from saved location
        longitude: 90.4125,
        date: DateTime.now(),
        method: CalculationMethod.karachi,
      );

      final prayerTimes = calculator.getPrayerTimesMap();
      final prayerTime = prayerTimes[prayerName];

      if (prayerTime == null) return null;

      // If prayer time has passed today, calculate for tomorrow
      final now = DateTime.now();
      DateTime targetPrayerTime = prayerTime;

      if (prayerTime.isBefore(now)) {
        final tomorrowCalculator = SalahTimeCalculator(
          latitude: 23.8103,
          longitude: 90.4125,
          date: now.add(const Duration(days: 1)),
          method: CalculationMethod.karachi,
        );
        final tomorrowTimes = tomorrowCalculator.getPrayerTimesMap();
        targetPrayerTime = tomorrowTimes[prayerName] ?? prayerTime;
      }

      // Calculate prayer duration (approximate)
      Duration prayerDuration;
      switch (prayerName) {
        case 'Fajr':
          prayerDuration = const Duration(minutes: 15); // Until sunrise
          break;
        case 'Dhuhr':
        case 'Asr':
        case 'Isha':
          prayerDuration = const Duration(minutes: 30);
          break;
        case 'Maghrib':
          prayerDuration = const Duration(minutes: 20);
          break;
        default:
          prayerDuration = const Duration(minutes: 20);
      }

      final prayerEndTime = targetPrayerTime.add(prayerDuration);
      final alarmTime = prayerEndTime.subtract(
        Duration(minutes: minutesBefore),
      );

      return alarmTime;
    } catch (e) {
      developer.log(
        'PrayerAlarmService: Error calculating prayer end time: $e',
      );
      return null;
    }
  }

  Future<DateTime?> _calculateAfterPrayerStartTime(
    String prayerName,
    int minutesAfter,
  ) async {
    try {
      // Get next occurrence of this prayer
      final calculator = SalahTimeCalculator(
        latitude: 23.8103, // Default to Dhaka, should get from saved location
        longitude: 90.4125,
        date: DateTime.now(),
        method: CalculationMethod.karachi,
      );

      final prayerTimes = calculator.getPrayerTimesMap();
      final prayerTime = prayerTimes[prayerName];

      if (prayerTime == null) return null;

      // If prayer time has passed today, calculate for tomorrow
      final now = DateTime.now();
      DateTime targetPrayerTime = prayerTime;

      if (prayerTime.isBefore(now)) {
        final tomorrowCalculator = SalahTimeCalculator(
          latitude: 23.8103,
          longitude: 90.4125,
          date: now.add(const Duration(days: 1)),
          method: CalculationMethod.karachi,
        );
        final tomorrowTimes = tomorrowCalculator.getPrayerTimesMap();
        targetPrayerTime = tomorrowTimes[prayerName] ?? prayerTime;
      }

      // Calculate alarm time as prayer start time + minutes after
      final alarmTime = targetPrayerTime.add(Duration(minutes: minutesAfter));

      return alarmTime;
    } catch (e) {
      developer.log(
        'PrayerAlarmService: Error calculating after prayer start time: $e',
      );
      return null;
    }
  }

  String _getAlarmMessage(PrayerAlarmConfig config) {
    if (config.type == PrayerAlarmType.fixedTime) {
      return '${config.prayerName} prayer time reminder';
    } else if (config.type == PrayerAlarmType.beforePrayerEnd) {
      return '${config.minutesBeforeEnd} minutes left for ${config.prayerName}';
    } else if (config.type == PrayerAlarmType.afterPrayerStart) {
      return '${config.prayerName} prayer started ${config.minutesAfterStart} minutes ago';
    }
    return '${config.prayerName} prayer time reminder';
  }

  Future<void> _cancelAlarm(String prayerName) async {
    final alarmId = _prayerAlarmIds[prayerName];
    if (alarmId != null) {
      await Alarm.stop(alarmId);
      developer.log('PrayerAlarmService: Cancelled alarm for $prayerName');
    }
  }

  Future<void> _scheduleAllAlarms() async {
    for (final alarm in _alarms) {
      if (alarm.isEnabled) {
        await _scheduleAlarm(alarm);
      }
    }
  }

  Future<void> _cancelAllAlarms() async {
    for (final prayerName in _prayerAlarmIds.keys) {
      await _cancelAlarm(prayerName);
    }
  }

  void _startRefreshTimer() {
    // Refresh alarms daily at midnight to handle date changes
    _refreshTimer?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = midnight.difference(now);

    _refreshTimer = Timer(timeUntilMidnight, () {
      _scheduleAllAlarms();
      _startRefreshTimer(); // Schedule next refresh
    });
  }

  void dispose() {
    _refreshTimer?.cancel();
    _alarmsController.close();
    _enabledController.close();
  }
}
