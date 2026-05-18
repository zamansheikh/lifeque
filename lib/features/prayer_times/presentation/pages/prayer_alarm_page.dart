import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import '../../../../core/services/prayer_alarm_service.dart';
import '../../../../core/utils/alarm_sound_utils.dart';
import '../../../../core/utils/salah_time_calculator.dart';
import '../utils/islamic_colors.dart';

class PrayerAlarmPage extends StatefulWidget {
  const PrayerAlarmPage({super.key});

  @override
  State<PrayerAlarmPage> createState() => _PrayerAlarmPageState();
}

class _PrayerAlarmPageState extends State<PrayerAlarmPage> {
  final PrayerAlarmService _alarmService = PrayerAlarmService();
  final List<String> _prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  @override
  void initState() {
    super.initState();
    _alarmService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    // Override the local colour scheme so EVERY downstream `colorScheme.primary`
    // (used heavily by this page's existing helpers) reads emerald instead of
    // the app's default Material primary. Lets us re-skin the whole page
    // without rewriting hundreds of lines.
    final base = Theme.of(context);
    final themed = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: IslamicColors.emerald,
        onPrimary: Colors.white,
        secondary: IslamicColors.goldDeep,
        onSecondary: Colors.white,
        error: IslamicColors.warning,
      ),
    );

    return Theme(
      data: themed,
      child: Builder(builder: _build),
    );
  }

  Widget _build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: IslamicColors.cream,
      appBar: AppBar(
        title: const Text(
          'Prayer Alarms',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: IslamicColors.emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [IslamicColors.emerald, IslamicColors.emeraldMid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          StreamBuilder<bool>(
            stream: _alarmService.enabledStream,
            builder: (context, snapshot) {
              final isEnabled = snapshot.data ?? true;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: IslamicColors.goldLight.withValues(alpha: 0.4),
                  ),
                ),
                child: Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    _alarmService.toggleGlobalAlarms(value);
                  },
                  activeThumbColor: IslamicColors.goldLight,
                  activeTrackColor:
                      IslamicColors.goldDeep.withValues(alpha: 0.5),
                  inactiveThumbColor: Colors.white70,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PrayerAlarmConfig>>(
        stream: _alarmService.alarmsStream,
        builder: (context, snapshot) {
          final alarms = snapshot.data ?? [];

          return StreamBuilder<bool>(
            stream: _alarmService.enabledStream,
            builder: (context, globalSnapshot) {
              final globalEnabled = globalSnapshot.data ?? true;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Modern info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.notifications_rounded,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Prayer Alarms',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    globalEnabled
                                        ? 'Configure reminders for each prayer'
                                        : 'Enable alarms using the switch above',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: globalEnabled
                                    ? colorScheme.primary.withValues(alpha: 0.1)
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.1,
                                      ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                globalEnabled ? 'ACTIVE' : 'DISABLED',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: globalEnabled
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._prayers.map((prayer) {
                    final existingAlarm =
                        alarms.where((a) => a.prayerName == prayer).isNotEmpty
                        ? alarms.where((a) => a.prayerName == prayer).first
                        : null;
                    return _buildPrayerAlarmCard(
                      prayer,
                      existingAlarm,
                      globalEnabled,
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPrayerAlarmCard(
    String prayer,
    PrayerAlarmConfig? existingAlarm,
    bool globalEnabled,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConfigured = existingAlarm != null;
    final isEnabled = isConfigured && existingAlarm.isEnabled;
    final isActive = isEnabled && globalEnabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getPrayerIcon(prayer),
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
          ),
          title: Text(
            prayer,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _getAlarmStatusText(existingAlarm, globalEnabled),
              style: TextStyle(
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: Container(
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Switch(
              value: isActive,
              onChanged: globalEnabled
                  ? (value) {
                      if (value) {
                        _showAlarmConfigDialog(prayer, existingAlarm);
                      } else {
                        _alarmService.removeAlarm(prayer);
                      }
                    }
                  : null,
              activeThumbColor: colorScheme.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          children: [
            if (isConfigured) ...[
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getAlarmDetailsText(existingAlarm),
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Edit button
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton.icon(
                            onPressed: globalEnabled
                                ? () {
                                    _showAlarmConfigDialog(
                                      prayer,
                                      existingAlarm,
                                    );
                                  }
                                : null,
                            icon: Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            label: Text(
                              'Edit',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Remove button
                        Container(
                          decoration: BoxDecoration(
                            color: colorScheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextButton.icon(
                            onPressed: globalEnabled
                                ? () {
                                    _alarmService.removeAlarm(prayer);
                                  }
                                : null,
                            icon: Icon(
                              Icons.delete_rounded,
                              size: 16,
                              color: colorScheme.error,
                            ),
                            label: Text(
                              'Remove',
                              style: TextStyle(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: globalEnabled
                          ? () {
                              _showAlarmConfigDialog(prayer, null);
                            }
                          : null,
                      icon: Icon(
                        Icons.add_rounded,
                        color: colorScheme.onPrimary,
                      ),
                      label: Text(
                        'Configure Alarm',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getPrayerIcon(String prayer) {
    switch (prayer) {
      case 'Fajr':
        return Icons.wb_sunny_outlined;
      case 'Dhuhr':
        return Icons.wb_sunny;
      case 'Asr':
        return Icons.wb_twilight;
      case 'Maghrib':
        return Icons.brightness_3;
      case 'Isha':
        return Icons.brightness_2;
      default:
        return Icons.schedule;
    }
  }

  String _getAlarmStatusText(PrayerAlarmConfig? alarm, bool globalEnabled) {
    if (!globalEnabled) return 'Disabled globally';
    if (alarm == null) return 'No alarm set';
    if (!alarm.isEnabled) return 'Disabled';

    if (alarm.type == PrayerAlarmType.fixedTime) {
      return _formatTimeWithAMPM(alarm.fixedTime!);
    }
    final actualTime = _calculateActualAlarmTime(alarm.prayerName, alarm);
    if (actualTime != null) {
      return _formatTimeWithAMPM(actualTime);
    }
    // Fallback label
    if (alarm.type == PrayerAlarmType.beforePrayerEnd) {
      return '${alarm.minutesBeforeEnd} min before end';
    }
    final mins = alarm.minutesAfterStart;
    if (mins == 0) return 'Exact prayer time';
    if (mins < 0) return '${mins.abs()} min before start';
    return '$mins min after start';
  }

  String _getAlarmDetailsText(PrayerAlarmConfig alarm) {
    if (alarm.type == PrayerAlarmType.fixedTime && alarm.fixedTime != null) {
      return 'Fixed time: ${_formatTimeWithAMPM(alarm.fixedTime!)}';
    }
    final actualTime = _calculateActualAlarmTime(alarm.prayerName, alarm);
    final timeStr = actualTime != null
        ? ' (${_formatTimeWithAMPM(actualTime)})'
        : '';
    if (alarm.type == PrayerAlarmType.beforePrayerEnd) {
      return '${alarm.minutesBeforeEnd} minutes before prayer ends$timeStr';
    }
    final mins = alarm.minutesAfterStart;
    if (mins == 0) return 'Exact prayer time$timeStr';
    if (mins < 0) return '${mins.abs()} minutes before prayer starts$timeStr';
    return '$mins minutes after prayer starts$timeStr';
  }

  String _formatTimeWithAMPM(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  DateTime? _calculateActualAlarmTime(
    String prayerName,
    PrayerAlarmConfig alarm,
  ) {
    try {
      // For this demo, we'll use default coordinates (Dhaka, Bangladesh)
      // In a real app, you'd get this from user settings
      final calculator = SalahTimeCalculator(
        latitude: 23.8103, // Dhaka latitude
        longitude: 90.4125, // Dhaka longitude
        date: DateTime.now(),
        method: CalculationMethod.karachi, // Common method for Bangladesh
      );

      final prayerTimes = calculator.getPrayerTimesMap();

      if (alarm.type == PrayerAlarmType.beforePrayerEnd) {
        // Get the next prayer time to calculate "end" time
        DateTime? prayerEndTime;
        switch (prayerName) {
          case 'Fajr':
            prayerEndTime = prayerTimes['Sunrise'];
            break;
          case 'Dhuhr':
            prayerEndTime = prayerTimes['Asr'];
            break;
          case 'Asr':
            prayerEndTime = prayerTimes['Maghrib'];
            break;
          case 'Maghrib':
            prayerEndTime = prayerTimes['Isha'];
            break;
          case 'Isha':
            // Isha ends at midnight (or next Fajr)
            final nextDay = DateTime.now().add(const Duration(days: 1));
            final nextCalc = SalahTimeCalculator(
              latitude: 23.8103,
              longitude: 90.4125,
              date: nextDay,
              method: CalculationMethod.karachi,
            );
            prayerEndTime = nextCalc.getPrayerTimesMap()['Fajr'];
            break;
        }

        if (prayerEndTime != null) {
          return prayerEndTime.subtract(
            Duration(minutes: alarm.minutesBeforeEnd),
          );
        }
      } else if (alarm.type == PrayerAlarmType.afterPrayerStart) {
        final prayerStartTime = prayerTimes[prayerName];
        if (prayerStartTime != null) {
          return prayerStartTime.add(
            Duration(minutes: alarm.minutesAfterStart),
          );
        }
      }
    } catch (e) {
      // If calculation fails, return null to fall back to basic description
      return null;
    }
    return null;
  }

  void _showAlarmConfigDialog(String prayer, PrayerAlarmConfig? existingAlarm) {
    showDialog(
      context: context,
      builder: (context) => _AlarmConfigDialog(
        prayer: prayer,
        existingAlarm: existingAlarm,
        onSave: (config) {
          if (existingAlarm != null) {
            _alarmService.updateAlarm(config);
          } else {
            _alarmService.addAlarm(config);
          }
        },
      ),
    );
  }
}

class _AlarmConfigDialog extends StatefulWidget {
  final String prayer;
  final PrayerAlarmConfig? existingAlarm;
  final Function(PrayerAlarmConfig) onSave;

  const _AlarmConfigDialog({
    required this.prayer,
    this.existingAlarm,
    required this.onSave,
  });

  @override
  State<_AlarmConfigDialog> createState() => _AlarmConfigDialogState();
}

class _AlarmConfigDialogState extends State<_AlarmConfigDialog> {
  /// true = relative slider (-60..+60 from prayer start), false = fixed time
  late bool _isRelative;

  /// -60 = 60 min before prayer start, 0 = exact prayer time, +60 = 60 min after
  late int _relativeMinutes;
  late TimeOfDay _fixedTime;
  late String _selectedSoundPath;
  late int _alarmDurationMinutes;

  @override
  void initState() {
    super.initState();

    if (widget.existingAlarm != null) {
      final alarm = widget.existingAlarm!;
      _selectedSoundPath = alarm.soundPath;
      _alarmDurationMinutes = alarm.alarmDurationMinutes;
      _fixedTime = alarm.fixedTime != null
          ? TimeOfDay.fromDateTime(alarm.fixedTime!)
          : const TimeOfDay(hour: 9, minute: 0);
      if (alarm.type == PrayerAlarmType.fixedTime) {
        _isRelative = false;
        _relativeMinutes = 0;
      } else if (alarm.type == PrayerAlarmType.beforePrayerEnd) {
        // Legacy: convert "X min before end" to approximately negative from start
        _isRelative = true;
        _relativeMinutes = -alarm.minutesBeforeEnd;
      } else {
        // afterPrayerStart — minutesAfterStart may already be negative (stored by new UI)
        _isRelative = true;
        _relativeMinutes = alarm.minutesAfterStart.clamp(-60, 60);
      }
    } else {
      _isRelative = true;
      _relativeMinutes = 0; // Default: exact prayer time
      _selectedSoundPath = AlarmSoundUtils.availableAlarmSounds[0]['path']!;
      _alarmDurationMinutes = 2;
      _fixedTime = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _getProjectedTime() {
    try {
      final calculator = SalahTimeCalculator(
        latitude: 23.8103,
        longitude: 90.4125,
        date: DateTime.now(),
        method: CalculationMethod.karachi,
      );
      final prayerTimes = calculator.getPrayerTimesMap();
      final prayerStartTime = prayerTimes[widget.prayer];
      if (prayerStartTime != null) {
        final targetTime = prayerStartTime.add(
          Duration(minutes: _relativeMinutes),
        );
        return DateFormat('h:mm a').format(targetTime);
      }
    } catch (e) {
      return '--:--';
    }
    return '--:--';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.alarm,
                      color: colorScheme.onPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.prayer} Alarm',
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Configure reminder settings',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alarm Type Section
                    Text(
                      'Alarm Type',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Radio tiles — 2 options
                    _buildRelativeRadioTile(context),
                    const SizedBox(height: 8),
                    _buildFixedRadioTile(context),

                    const SizedBox(height: 24),

                    // Dynamic configuration based on type
                    if (_isRelative) ...[
                      _buildConfigSection(
                        context,
                        'নামাজের সময়',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 8),
                            // Big label showing the selected offset
                            Text(
                              _relativeMinutes == 0
                                  ? 'ঠিক নামাজের সময়'
                                  : _relativeMinutes < 0
                                  ? '${_relativeMinutes.abs()} মিনিট আগে'
                                  : '$_relativeMinutes মিনিট পরে',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'আনুমানিক সময়: ${_getProjectedTime()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Bidirectional slider
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: colorScheme.primary,
                                inactiveTrackColor:
                                    colorScheme.surfaceContainerHighest,
                                thumbColor: colorScheme.primary,
                                overlayColor: colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                valueIndicatorColor: colorScheme.primary,
                                valueIndicatorTextStyle: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Slider(
                                value: _relativeMinutes.toDouble(),
                                min: -60,
                                max: 60,
                                divisions: 24,
                                label: _relativeMinutes == 0
                                    ? 'ঠিক সময়'
                                    : _relativeMinutes < 0
                                    ? '${_relativeMinutes.abs()} min আগে'
                                    : '$_relativeMinutes min পরে',
                                onChanged: (value) {
                                  setState(() {
                                    _relativeMinutes = value.toInt();
                                  });
                                },
                              ),
                            ),
                            // Axis labels
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '← আগে',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        '-60 min',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Icon(
                                        Icons.radio_button_checked,
                                        size: 12,
                                        color: colorScheme.primary,
                                      ),
                                      Text(
                                        'ঠিক সময়',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'পরে →',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        '+60 min',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      _buildConfigSection(
                        context,
                        'নির্দিষ্ট সময়',
                        InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _fixedTime,
                            );
                            if (time != null) {
                              setState(() {
                                _fixedTime = time;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _formatTime(_fixedTime),
                                  style: textTheme.bodyLarge,
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Alarm Sound Section
                    _buildConfigSection(
                      context,
                      'Alarm Sound',
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSoundPath,
                        decoration: _getInputDecoration(
                          context,
                          'Select sound',
                        ),
                        items: AlarmSoundUtils.availableAlarmSounds.map((
                          sound,
                        ) {
                          return DropdownMenuItem(
                            value: sound['path']!,
                            child: Text(
                              sound['name']!,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSoundPath = value!;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Alarm Duration Section
                    _buildConfigSection(
                      context,
                      'Alarm Duration',
                      DropdownButtonFormField<int>(
                        initialValue: _alarmDurationMinutes,
                        decoration: _getInputDecoration(
                          context,
                          'Select duration',
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 minute')),
                          DropdownMenuItem(value: 2, child: Text('2 minutes')),
                          DropdownMenuItem(value: 3, child: Text('3 minutes')),
                          DropdownMenuItem(value: 5, child: Text('5 minutes')),
                          DropdownMenuItem(
                            value: 10,
                            child: Text('10 minutes'),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text('15 minutes'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _alarmDurationMinutes = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saveAlarm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check,
                            size: 20,
                            color: colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Save',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelativeRadioTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _isRelative;

    return InkWell(
      onTap: () => setState(() => _isRelative = true),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.tune,
                size: 20,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'নামাজের সময় অনুযায়ী',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'আগে, পরে বা ঠিক নামাজের সময়ে',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedRadioTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = !_isRelative;

    return InkWell(
      onTap: () => setState(() => _isRelative = false),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.access_time,
                size: 20,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'নির্দিষ্ট সময়',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'একটি নির্দিষ্ট সময়ে এলার্ম দিন',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? colorScheme.primary : colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigSection(BuildContext context, String title, Widget child) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  InputDecoration _getInputDecoration(BuildContext context, String hint) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '${displayHour.toString()}:${minute.toString().padLeft(2, '0')} $period';
  }

  void _saveAlarm() {
    final config = PrayerAlarmConfig(
      prayerName: widget.prayer,
      type: _isRelative
          ? PrayerAlarmType.afterPrayerStart
          : PrayerAlarmType.fixedTime,
      minutesBeforeEnd: 0,
      minutesAfterStart: _isRelative ? _relativeMinutes : 0,
      fixedTime: !_isRelative
          ? DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
              _fixedTime.hour,
              _fixedTime.minute,
            )
          : null,
      isEnabled: true,
      soundPath: _selectedSoundPath,
      alarmDurationMinutes: _alarmDurationMinutes,
    );

    widget.onSave(config);
    Navigator.of(context).pop();
  }
}
