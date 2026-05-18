import 'dart:async';
import 'dart:developer' as developer;
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/salah_time_calculator.dart';
import '../utils/alarm_sound_utils.dart';
import '../../features/prayer_times/data/services/prayer_settings_service.dart';

enum PrayerAlarmType { beforePrayerEnd, fixedTime, afterPrayerStart }

class PrayerAlarmConfig {
  final String prayerName;
  final PrayerAlarmType type;
  final int minutesBeforeEnd; // For beforePrayerEnd type
  final int minutesAfterStart; // For afterPrayerStart type
  final DateTime? fixedTime; // For fixedTime type
  final bool isEnabled;
  final String soundPath;
  final int alarmDurationMinutes; // Duration in minutes before auto-stop

  PrayerAlarmConfig({
    required this.prayerName,
    required this.type,
    this.minutesBeforeEnd = 5,
    this.minutesAfterStart = 5,
    this.fixedTime,
    this.isEnabled = true,
    this.soundPath = 'assets/audio/alarm_sound_1.mp3', // Use custom sound
    this.alarmDurationMinutes = 2, // Default 2 minutes
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
      'alarmDurationMinutes': alarmDurationMinutes,
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
      alarmDurationMinutes: json['alarmDurationMinutes'] is String
          ? int.parse(json['alarmDurationMinutes'])
          : (json['alarmDurationMinutes'] ?? 2),
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
  StreamSubscription<AlarmSet>? _ringSubscription;
  Set<int> _currentlyRingingIds = {};

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

    // Listen for alarm fires and automatically reschedule for the next day.
    // This ensures alarms repeat daily even if the midnight timer was missed.
    _ringSubscription ??= Alarm.ringing.listen((AlarmSet alarmSet) {
      final currentIds = alarmSet.alarms.map((a) => a.id).toSet();
      for (final alarm in alarmSet.alarms) {
        if (!_currentlyRingingIds.contains(alarm.id)) {
          _onAlarmRang(alarm);
        }
      }
      _currentlyRingingIds = currentIds;
    });

    // Reschedule all alarms on startup so that any alarms missed while the
    // app was closed (e.g. after a device restart) are correctly re-queued.
    if (_isEnabled) {
      await _scheduleAllAlarms();
    }

    developer.log(
      'PrayerAlarmService: Initialized with ${_alarms.length} alarms',
    );
  }

  /// Called whenever an alarm starts ringing. Reschedules the prayer alarm
  /// for tomorrow so it fires again on the next calendar day.
  Future<void> _onAlarmRang(AlarmSettings settings) async {
    developer.log('PrayerAlarmService: Alarm rang id=${settings.id}');

    // Find which prayer this alarm belongs to.
    String? prayerName;
    for (final entry in _prayerAlarmIds.entries) {
      if (entry.value == settings.id) {
        prayerName = entry.key;
        break;
      }
    }
    if (prayerName == null) return;

    // Find the stored config.
    PrayerAlarmConfig? config;
    try {
      config = _alarms.firstWhere((a) => a.prayerName == prayerName);
    } catch (_) {
      return; // No config saved – nothing to reschedule.
    }

    if (!config.isEnabled || !_isEnabled) return;

    // Schedule for tomorrow's prayer time.
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    developer.log(
      'PrayerAlarmService: Rescheduling ${config.prayerName} for tomorrow',
    );
    await _scheduleAlarmForDate(config, tomorrow);
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
                key == 'minutesAfterStart' ||
                key == 'alarmDurationMinutes') {
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

  /// Schedule an alarm for the next upcoming occurrence (today or tomorrow).
  Future<void> _scheduleAlarm(PrayerAlarmConfig config) async {
    await _scheduleAlarmForDate(config, DateTime.now());
  }

  /// Schedule an alarm using [startDate] as the reference date for prayer
  /// time calculation. If the resulting time is in the past, tomorrow is used.
  Future<void> _scheduleAlarmForDate(
    PrayerAlarmConfig config,
    DateTime startDate,
  ) async {
    final alarmId = _prayerAlarmIds[config.prayerName];
    if (alarmId == null) return;

    DateTime? alarmTime;

    if (config.type == PrayerAlarmType.fixedTime && config.fixedTime != null) {
      // Use only the time-of-day from the stored fixedTime and project it
      // onto today (or tomorrow if today's already passed) so the alarm
      // continues to fire daily instead of silently dying once the stored
      // date is in the past.
      final fixed = config.fixedTime!;
      final base = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        fixed.hour,
        fixed.minute,
        fixed.second,
      );
      alarmTime = base.isBefore(DateTime.now())
          ? base.add(const Duration(days: 1))
          : base;
    } else if (config.type == PrayerAlarmType.beforePrayerEnd) {
      alarmTime = await _calculateBeforePrayerEndTime(
        config.prayerName,
        config.minutesBeforeEnd,
        referenceDate: startDate,
      );
    } else if (config.type == PrayerAlarmType.afterPrayerStart) {
      alarmTime = await _calculateAfterPrayerStartTime(
        config.prayerName,
        config.minutesAfterStart,
        referenceDate: startDate,
      );
    }

    if (alarmTime == null || alarmTime.isBefore(DateTime.now())) {
      developer.log(
        'PrayerAlarmService: Alarm time is in the past for ${config.prayerName}',
      );
      return;
    }

    // Use the sound selected for THIS prayer's alarm config. Falls back to
    // the global preference / default if the saved path is empty or invalid.
    String alarmSoundPath = config.soundPath;
    if (alarmSoundPath.isEmpty ||
        !AlarmSoundUtils.isValidAlarmSound(alarmSoundPath)) {
      alarmSoundPath = await AlarmSoundUtils.getPrayerAlarmSound();
    }

    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: alarmTime,
      assetAudioPath: alarmSoundPath, // Per-prayer user-selected sound
      loopAudio: true, // Enable looping to repeat the sound
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0, // Max volume to ensure audibility through main speaker
        fadeDuration: const Duration(seconds: 2),
        volumeEnforced:
            true, // Force volume setting to override system settings
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

      // Auto-stop alarm after configured duration if not manually stopped
      Timer(Duration(minutes: config.alarmDurationMinutes), () async {
        final isRinging = await Alarm.isRinging(alarmId);
        if (isRinging) {
          await Alarm.stop(alarmId);
          developer.log(
            'PrayerAlarmService: Auto-stopped alarm for ${config.prayerName} after ${config.alarmDurationMinutes} minutes',
          );
        }
      });
    } catch (e) {
      developer.log('PrayerAlarmService: Error scheduling alarm: $e');
    }
  }

  /// Build a [SalahTimeCalculator] honouring the user's saved location,
  /// calculation method and madhab. Falls back to Dhaka/Karachi/Hanafi if no
  /// settings have been saved yet.
  Future<SalahTimeCalculator> _buildCalculator(DateTime date) async {
    final settings = PrayerSettingsService.instance;
    final location = await settings.getSavedLocation();
    final method = await settings.getCalculationMethod();
    final madhab = await settings.getMadhab();

    return SalahTimeCalculator(
      latitude: location?.latitude ?? 23.8103,
      longitude: location?.longitude ?? 90.4125,
      date: date,
      method: method,
      madhab: madhab,
    );
  }

  Future<DateTime?> _calculateBeforePrayerEndTime(
    String prayerName,
    int minutesBefore, {
    DateTime? referenceDate,
  }) async {
    try {
      final now = DateTime.now();
      final date = referenceDate ?? now;

      // Get prayer times for the reference date using user's saved settings.
      final calculator = await _buildCalculator(date);

      final prayerTimes = calculator.getPrayerTimesMap();
      final prayerTime = prayerTimes[prayerName];

      if (prayerTime == null) return null;

      // If prayer time has passed, calculate for the next day.
      DateTime targetPrayerTime = prayerTime;

      if (prayerTime.isBefore(now)) {
        final tomorrowCalculator = await _buildCalculator(
          date.add(const Duration(days: 1)),
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
    int minutesAfter, {
    DateTime? referenceDate,
  }) async {
    try {
      final now = DateTime.now();
      final date = referenceDate ?? now;

      // Get prayer times for the reference date using user's saved settings.
      final calculator = await _buildCalculator(date);

      final prayerTimes = calculator.getPrayerTimesMap();
      final prayerTime = prayerTimes[prayerName];

      if (prayerTime == null) return null;

      // Alarm fires at prayer start ± offset minutes.
      // minutesAfter can be negative (before start) or 0 (exact) or positive.
      DateTime alarmTime = prayerTime.add(Duration(minutes: minutesAfter));

      // If the computed alarm time has already passed, shift to the next day.
      if (alarmTime.isBefore(now)) {
        final tomorrowCalculator = await _buildCalculator(
          date.add(const Duration(days: 1)),
        );
        final tomorrowTimes = tomorrowCalculator.getPrayerTimesMap();
        final tomorrowPrayer = tomorrowTimes[prayerName];
        if (tomorrowPrayer != null) {
          alarmTime = tomorrowPrayer.add(Duration(minutes: minutesAfter));
        }
      }

      return alarmTime;
    } catch (e) {
      developer.log(
        'PrayerAlarmService: Error calculating prayer start time: $e',
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
      final mins = config.minutesAfterStart;
      if (mins == 0) {
        return 'Time for ${config.prayerName} prayer';
      } else if (mins < 0) {
        return '${mins.abs()} minutes until ${config.prayerName} prayer';
      } else {
        return '${config.prayerName} prayer started $mins minutes ago';
      }
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

  /// Re-queue all enabled prayer alarms. Safe to call from a background
  /// isolate (e.g. WorkManager). Does NOT touch streams or timers — just
  /// reads persisted alarms and pushes them into the native Alarm package.
  ///
  /// The native Alarm package only holds one fire-time per alarm id, so on
  /// every invocation we recompute today's (or tomorrow's, if today's has
  /// passed) prayer time and re-set it. This is what keeps daily alarms
  /// firing even when the app has been killed for days — WorkManager calls
  /// this every ~15 min and tops up the queue.
  Future<void> rescheduleFromBackground() async {
    developer.log('PrayerAlarmService: rescheduleFromBackground');
    await _loadSettings();
    await _loadAlarms();
    if (!_isEnabled) {
      developer.log('PrayerAlarmService: global alarms disabled — skipping');
      return;
    }
    await _scheduleAllAlarms();
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
    _ringSubscription?.cancel();
    _alarmsController.close();
    _enabledController.close();
  }
}
