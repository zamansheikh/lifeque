import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/prayer_times/presentation/utils/prayer_l10n.dart';
import '../../l10n/app_localizations.dart';
import '../utils/app_strings.dart';
import '../utils/salah_time_calculator.dart';
import '../utils/alarm_sound_utils.dart';
import '../../features/prayer_times/data/services/jamaat_defaults.dart';
import '../../features/prayer_times/data/services/prayer_settings_service.dart';

/// What an alarm's offset is measured from.
///
/// [afterJamaat] mirrors [afterPrayerStart] but anchors to the mosque's
/// congregation time instead of the waqt, so "10 min before jamaat" tracks
/// the jamaat as the user adjusts it.
enum PrayerAlarmType {
  beforePrayerEnd,
  fixedTime,
  afterPrayerStart,
  afterJamaat,
}

class PrayerAlarmConfig {
  final String prayerName;
  final PrayerAlarmType type;
  final int minutesBeforeEnd; // For beforePrayerEnd type
  final int minutesAfterStart; // For afterPrayerStart type
  final DateTime? fixedTime; // For fixedTime type
  final bool isEnabled;
  final String soundPath;
  final int alarmDurationMinutes; // Duration in minutes before auto-stop
  final bool vibrate; // Buzz alongside the adhan

  PrayerAlarmConfig({
    required this.prayerName,
    required this.type,
    this.minutesBeforeEnd = 5,
    this.minutesAfterStart = 5,
    this.fixedTime,
    this.isEnabled = true,
    this.soundPath = AlarmSoundUtils.defaultSoundPath,
    this.alarmDurationMinutes = 2, // Default 2 minutes
    this.vibrate = true,
  });

  PrayerAlarmConfig copyWith({
    String? prayerName,
    PrayerAlarmType? type,
    int? minutesBeforeEnd,
    int? minutesAfterStart,
    DateTime? fixedTime,
    bool? isEnabled,
    String? soundPath,
    int? alarmDurationMinutes,
    bool? vibrate,
  }) {
    return PrayerAlarmConfig(
      prayerName: prayerName ?? this.prayerName,
      type: type ?? this.type,
      minutesBeforeEnd: minutesBeforeEnd ?? this.minutesBeforeEnd,
      minutesAfterStart: minutesAfterStart ?? this.minutesAfterStart,
      fixedTime: fixedTime ?? this.fixedTime,
      isEnabled: isEnabled ?? this.isEnabled,
      soundPath: soundPath ?? this.soundPath,
      alarmDurationMinutes: alarmDurationMinutes ?? this.alarmDurationMinutes,
      vibrate: vibrate ?? this.vibrate,
    );
  }

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
      'vibrate': vibrate,
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
      isEnabled: _asBool(json['isEnabled'], true),
      soundPath: json['soundPath'] ?? AlarmSoundUtils.defaultSoundPath,
      alarmDurationMinutes: json['alarmDurationMinutes'] is String
          ? int.parse(json['alarmDurationMinutes'])
          : (json['alarmDurationMinutes'] ?? 2),
      // Alarms saved before vibration was configurable buzzed by default.
      vibrate: _asBool(json['vibrate'], true),
    );
  }

  /// Booleans have been persisted both as real bools and as the strings
  /// "true"/"false" by different versions of the storage format. Handing a
  /// String straight to a bool parameter threw, and the throw was swallowed by
  /// a catch that then wiped every saved alarm.
  static bool _asBool(Object? value, bool fallback) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }
}

/// The calls the service makes into the alarm plugin, behind one seam so
/// tests can see what gets scheduled and stopped without a device.
abstract class AlarmBackend {
  Stream<AlarmSet> get ringing;
  Future<bool> set(AlarmSettings settings);
  Future<bool> stop(int id);
  Future<bool> isRinging(int id);

  /// What is currently armed under [id], if anything.
  Future<AlarmSettings?> scheduled(int id);
}

class PluginAlarmBackend implements AlarmBackend {
  const PluginAlarmBackend();

  @override
  Stream<AlarmSet> get ringing => Alarm.ringing;

  @override
  Future<bool> set(AlarmSettings settings) =>
      Alarm.set(alarmSettings: settings);

  @override
  Future<bool> stop(int id) => Alarm.stop(id);

  @override
  Future<bool> isRinging(int id) => Alarm.isRinging(id);

  @override
  Future<AlarmSettings?> scheduled(int id) => Alarm.getAlarm(id);
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

  /// Stops each ringing alarm after its "rings for" length. Started when the
  /// ring starts — it used to start when the alarm was *scheduled*, so an
  /// alarm queued a minute before its time was cut off a minute into ringing.
  final Map<int, Timer> _autoStopTimers = {};

  AlarmBackend _backend = const PluginAlarmBackend();

  @visibleForTesting
  set backend(AlarmBackend value) => _backend = value;

  /// Back to a fresh singleton, for tests.
  @visibleForTesting
  void resetForTesting() {
    _ringSubscription?.cancel();
    _ringSubscription = null;
    _refreshTimer?.cancel();
    for (final t in _autoStopTimers.values) {
      t.cancel();
    }
    _autoStopTimers.clear();
    _currentlyRingingIds = {};
    _alarms = [];
    _isEnabled = true;
    _backend = const PluginAlarmBackend();
  }

  /// The prayer an alarm id belongs to, or null for other alarms (the study
  /// timer's, say).
  static String? prayerForAlarmId(int id) {
    for (final entry in _prayerAlarmIds.entries) {
      if (entry.value == id) return entry.key;
    }
    return null;
  }

  /// The saved alarm for [prayer], if any.
  PrayerAlarmConfig? configFor(String prayer) {
    for (final a in _alarms) {
      if (a.prayerName == prayer) return a;
    }
    return null;
  }

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

    // Watch rings start and stop. The next day's alarm is queued when a ring
    // *stops*, never while it rings: Alarm.set on a ringing id stops it.
    _ringSubscription ??= _backend.ringing.listen(_onRingingChanged);

    // Reschedule all alarms on startup so that any alarms missed while the
    // app was closed (e.g. after a device restart) are correctly re-queued.
    if (_isEnabled) {
      await _scheduleAllAlarms();
    }

    developer.log(
      'PrayerAlarmService: Initialized with ${_alarms.length} alarms',
    );
  }

  void _onRingingChanged(AlarmSet alarmSet) {
    final now = alarmSet.alarms.map((a) => a.id).toSet();
    final before = _currentlyRingingIds;
    _currentlyRingingIds = now;
    for (final alarm in alarmSet.alarms) {
      if (!before.contains(alarm.id)) _onAlarmRang(alarm);
    }
    for (final id in before.difference(now)) {
      _onAlarmStopped(id);
    }
  }

  /// A prayer alarm started ringing: arm its auto-stop. Nothing is
  /// rescheduled here — doing that used to silence the alarm the instant it
  /// began, because re-setting an id stops whatever is ringing under it.
  void _onAlarmRang(AlarmSettings settings) {
    developer.log('PrayerAlarmService: Alarm rang id=${settings.id}');
    final prayer = prayerForAlarmId(settings.id);
    if (prayer == null) return;
    final config = configFor(prayer);
    final minutes = config?.alarmDurationMinutes ?? 2;

    // Measured from when it was due, not from now: if the app was started
    // by the ring (or opened during it), the ring has already been going.
    final ringsUntil = settings.dateTime.add(Duration(minutes: minutes));
    var left = ringsUntil.difference(DateTime.now());
    if (left.isNegative) left = Duration.zero;

    _autoStopTimers.remove(settings.id)?.cancel();
    _autoStopTimers[settings.id] = Timer(left, () async {
      _autoStopTimers.remove(settings.id);
      if (await _backend.isRinging(settings.id)) {
        await _backend.stop(settings.id);
        developer.log(
          'PrayerAlarmService: Auto-stopped $prayer after $minutes min',
        );
      }
    });
  }

  /// A ring ended — the user stopped it, or it timed out. Now it is safe to
  /// queue the next occurrence.
  Future<void> _onAlarmStopped(int id) async {
    _autoStopTimers.remove(id)?.cancel();
    final prayer = prayerForAlarmId(id);
    if (prayer == null) return;
    final config = configFor(prayer);
    if (config == null || !config.isEnabled || !_isEnabled) return;
    developer.log('PrayerAlarmService: $prayer stopped — queueing next');
    await _scheduleAlarm(config);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_enabledKey) ?? true;
    _enabledController.add(_isEnabled);
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsData = prefs.getStringList(_prefsKey) ?? [];

    final loaded = <PrayerAlarmConfig>[];
    for (final entry in alarmsData) {
      final config = _decodeAlarm(entry);
      if (config != null) {
        loaded.add(config);
      } else {
        developer.log('PrayerAlarmService: Skipping unreadable alarm entry');
      }
    }

    _alarms = loaded;
    _alarmsController.add(_alarms);
  }

  /// Reads one stored alarm, in either the current JSON format or the legacy
  /// `key:value|key:value` one.
  ///
  /// A single bad row is skipped rather than treated as a reason to delete
  /// everything. The old code wrapped the whole load in a try/catch whose
  /// handler called [clearAllAlarms] — so one unparseable field silently wiped
  /// every alarm the user had set, which is why they came back "reset to
  /// normal" after closing the app.
  PrayerAlarmConfig? _decodeAlarm(String stored) {
    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map<String, dynamic>) {
        return PrayerAlarmConfig.fromJson(decoded);
      }
    } catch (_) {
      // Not JSON — fall through to the legacy reader below.
    }

    try {
      final data = <String, dynamic>{};
      for (final part in stored.split('|')) {
        final separator = part.indexOf(':');
        if (separator <= 0) continue;
        // indexOf, not split: a value containing a colon used to make the
        // pair three elements long and get dropped entirely.
        final key = part.substring(0, separator);
        final value = part.substring(separator + 1);
        data[key] = value == 'null' ? null : value;
      }
      if (data['prayerName'] == null || data['type'] == null) return null;
      return PrayerAlarmConfig.fromJson(data);
    } catch (e) {
      developer.log('PrayerAlarmService: Could not read alarm "$stored": $e');
      return null;
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
    // Real JSON. The old "key:value|key:value" format lost any value
    // containing a colon or a pipe, and round-tripped every bool as a string.
    final alarmsJson = _alarms
        .map((alarm) => jsonEncode(alarm.toJson()))
        .toList();

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

    // Never re-set an alarm while it rings: Alarm.set stops the ringing one
    // first. Startup (which the ring itself triggers, by opening the app),
    // the midnight refresh and the background top-up all come through here,
    // and each was silencing alarms a moment after they began. The next
    // occurrence is queued when the ring stops — see _onAlarmStopped.
    if (_currentlyRingingIds.contains(alarmId) ||
        await _backend.isRinging(alarmId)) {
      developer.log(
        'PrayerAlarmService: ${config.prayerName} is ringing — not rescheduling',
      );
      return;
    }

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
    } else if (config.type == PrayerAlarmType.afterJamaat) {
      alarmTime = await _calculateAfterJamaatTime(
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

    final l = appStrings;
    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: alarmTime,
      assetAudioPath: alarmSoundPath, // Per-prayer user-selected sound
      loopAudio: true, // Enable looping to repeat the sound
      vibrate: config.vibrate,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      // Prayer alarms have their own ids, and two can fall in the same
      // second (Asr "before waqt ends" and Maghrib "at waqt"). The default
      // quietly replaced one with the other.
      allowSameSecondScheduling: true,
      // Keep ringing if the app's task goes away mid-ring; the notification's
      // Stop button still works without it.
      androidStopAlarmOnTermination: false,
      payload: config.prayerName,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0, // Max volume to ensure audibility through main speaker
        fadeDuration: const Duration(seconds: 2),
        volumeEnforced:
            true, // Force volume setting to override system settings
        // The plugin raises the volume to ring and restores it after; by
        // default each change pops Android's volume panel over the screen.
        showSystemUI: false,
      ),
      notificationSettings: NotificationSettings(
        title: '🕌 ${prayerLabelFor(l, config.prayerName)}',
        body: ringMessage(l, config),
        stopButton: l.alarmRingStop,
        icon: 'notification_icon',
      ),
    );

    // Already armed for this moment: leave it alone. Re-setting is not
    // harmless. For an alarm due within five seconds the plugin arms an
    // in-process timer that cannot be cancelled, so a re-set just before the
    // alarm makes it fire twice — and the second start silences the first
    // ("An alarm is already ringing. Ignoring new alarm"). Startup, the
    // midnight refresh and the 15-minute background top-up all come through
    // here, so this was a ring cut off in milliseconds, now and then.
    final armed = await _backend.scheduled(alarmId);
    if (armed != null &&
        armed.dateTime.millisecondsSinceEpoch ~/ 1000 ==
            alarmTime.millisecondsSinceEpoch ~/ 1000) {
      final unchanged = armed.copyWith(dateTime: alarmTime) == alarmSettings;
      final dueSoon =
          alarmTime.difference(DateTime.now()) < const Duration(seconds: 30);
      if (unchanged || dueSoon) {
        developer.log(
          'PrayerAlarmService: ${config.prayerName} already armed for '
          '$alarmTime — leaving it',
        );
        return;
      }
    }

    try {
      await _backend.set(alarmSettings);
      developer.log(
        'PrayerAlarmService: Scheduled alarm for ${config.prayerName} at $alarmTime',
      );
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

  /// When a "before waqt ends" alarm should ring: [minutesBefore] the waqt
  /// ends, using the same end times the prayer list
  /// shows (Fajr → sunrise, Dhuhr → Asr, Asr → Maghrib, Maghrib → Isha,
  /// Isha → next Fajr). Returns the first such moment still ahead.
  ///
  /// The day before is checked too: at 1 am, the Isha waqt that is ending is
  /// yesterday's, and its end (this morning's Fajr) is the one to warn about.
  Future<DateTime?> _calculateBeforePrayerEndTime(
    String prayerName,
    int minutesBefore, {
    DateTime? referenceDate,
  }) async {
    try {
      final now = DateTime.now();
      final date = referenceDate ?? now;

      for (var offset = -1; offset <= 1; offset++) {
        final calculator = await _buildCalculator(
          date.add(Duration(days: offset)),
        );
        final end = calculator.getEndTimes(
          calculator.getStartTimes(),
        )[prayerName];
        if (end == null) return null;
        final at = end.subtract(Duration(minutes: minutesBefore));
        if (at.isAfter(now)) return at;
      }
      return null;
    } catch (e) {
      developer.log(
        'PrayerAlarmService: Error calculating prayer end time: $e',
      );
      return null;
    }
  }

  /// The mosque's jamaat for [prayerName] on [date] — the user's saved time
  /// if they've set one, the Ramadan-mode derivation for Fajr/Maghrib, else
  /// the customary default. Same precedence the prayer list and widget use,
  /// so an alarm never disagrees with the time shown next to it.
  Future<DateTime?> _resolveJamaatTime(String prayerName, DateTime date) async {
    final settings = PrayerSettingsService.instance;
    final calculator = await _buildCalculator(date);
    final waqt = calculator.getPrayerTimesMap()[prayerName];
    if (waqt == null) return null;

    if (await settings.getRamadanMode() &&
        (prayerName == 'Fajr' || prayerName == 'Maghrib')) {
      return waqt.add(const Duration(minutes: 15));
    }

    final saved = await settings.getMosqueTime(prayerName.toLowerCase());
    if (saved != null) {
      try {
        final parts = saved.split(':');
        return DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
      } catch (_) {
        // Fall through to the default on a malformed stored value.
      }
    }
    return JamaatDefaults.forPrayer(prayerName, waqt);
  }

  /// Jamaat ± [minutesAfter]. Negative fires before jamaat, 0 on it.
  Future<DateTime?> _calculateAfterJamaatTime(
    String prayerName,
    int minutesAfter, {
    DateTime? referenceDate,
  }) async {
    try {
      final now = DateTime.now();
      final date = referenceDate ?? now;

      final jamaat = await _resolveJamaatTime(prayerName, date);
      if (jamaat == null) return null;

      var alarmTime = jamaat.add(Duration(minutes: minutesAfter));

      // Today's has passed — recompute against tomorrow's jamaat rather than
      // adding 24h, so it tracks the waqt drift the default is derived from.
      if (alarmTime.isBefore(now)) {
        final tomorrow = await _resolveJamaatTime(
          prayerName,
          date.add(const Duration(days: 1)),
        );
        if (tomorrow != null) {
          alarmTime = tomorrow.add(Duration(minutes: minutesAfter));
        }
      }
      return alarmTime;
    } catch (e) {
      developer.log('PrayerAlarmService: Error calculating jamaat time: $e');
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

  /// What the alarm is for, in the app's language: "Asr begins in 10 min",
  /// "Dhuhr jamaat is starting". Shared by the notification and the ring
  /// screen.
  static String ringMessage(L l, PrayerAlarmConfig config) {
    final p = prayerLabelFor(l, config.prayerName);
    final m = config.minutesAfterStart;
    return switch (config.type) {
      PrayerAlarmType.fixedTime => l.alarmRingReminder(p),
      PrayerAlarmType.beforePrayerEnd => l.alarmRingBeforeEnd(
        p,
        config.minutesBeforeEnd,
      ),
      PrayerAlarmType.afterJamaat =>
        m == 0
            ? l.alarmRingAtJamaat(p)
            : m < 0
            ? l.alarmRingBeforeJamaat(p, -m)
            : l.alarmRingAfterJamaat(p, m),
      PrayerAlarmType.afterPrayerStart =>
        m == 0
            ? l.alarmRingAtWaqt(p)
            : m < 0
            ? l.alarmRingBeforeWaqt(p, -m)
            : l.alarmRingAfterWaqt(p, m),
    };
  }

  Future<void> _cancelAlarm(String prayerName) async {
    final alarmId = _prayerAlarmIds[prayerName];
    if (alarmId != null) {
      _autoStopTimers.remove(alarmId)?.cancel();
      await _backend.stop(alarmId);
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
    for (final t in _autoStopTimers.values) {
      t.cancel();
    }
    _ringSubscription?.cancel();
    _alarmsController.close();
    _enabledController.close();
  }
}
