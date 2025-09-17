import 'package:flutter/material.dart';
import '../../../../core/services/prayer_alarm_service.dart';
import '../../../../core/utils/alarm_sound_utils.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Prayer Alarms'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          StreamBuilder<bool>(
            stream: _alarmService.enabledStream,
            builder: (context, snapshot) {
              final isEnabled = snapshot.data ?? true;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    _alarmService.toggleGlobalAlarms(value);
                  },
                  activeColor: colorScheme.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
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
              activeColor: colorScheme.primary,
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

    if (alarm.type == PrayerAlarmType.beforePrayerEnd) {
      return '${alarm.minutesBeforeEnd} min before end';
    } else if (alarm.type == PrayerAlarmType.afterPrayerStart) {
      return '${alarm.minutesAfterStart} min after start';
    } else {
      return 'Fixed: ${_formatTime(alarm.fixedTime!)}';
    }
  }

  String _getAlarmDetailsText(PrayerAlarmConfig alarm) {
    if (alarm.type == PrayerAlarmType.beforePrayerEnd) {
      return '${alarm.minutesBeforeEnd} minutes before prayer ends';
    } else if (alarm.type == PrayerAlarmType.afterPrayerStart) {
      return '${alarm.minutesAfterStart} minutes after prayer starts';
    } else if (alarm.type == PrayerAlarmType.fixedTime &&
        alarm.fixedTime != null) {
      return 'Fixed time: ${_formatTime(alarm.fixedTime!)}';
    } else {
      return 'Invalid alarm configuration';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
  late PrayerAlarmType _selectedType;
  late int _minutesBeforeEnd;
  late int _minutesAfterStart;
  late TimeOfDay _fixedTime;
  late String _selectedSoundPath;
  late int _alarmDurationMinutes;

  @override
  void initState() {
    super.initState();

    if (widget.existingAlarm != null) {
      _selectedType = widget.existingAlarm!.type;
      _minutesBeforeEnd = widget.existingAlarm!.minutesBeforeEnd;
      _minutesAfterStart = widget.existingAlarm!.minutesAfterStart;
      _selectedSoundPath = widget.existingAlarm!.soundPath;
      _alarmDurationMinutes = widget.existingAlarm!.alarmDurationMinutes;
      _fixedTime = widget.existingAlarm!.fixedTime != null
          ? TimeOfDay.fromDateTime(widget.existingAlarm!.fixedTime!)
          : const TimeOfDay(hour: 9, minute: 0);
    } else {
      _selectedType = PrayerAlarmType.beforePrayerEnd;
      _minutesBeforeEnd = 5;
      _minutesAfterStart = 5;
      _selectedSoundPath = AlarmSoundUtils.availableAlarmSounds[0]['path']!;
      _alarmDurationMinutes = 2; // Default 2 minutes
      _fixedTime = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.prayer} Alarm'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alarm Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            RadioListTile<PrayerAlarmType>(
              title: const Text('Before prayer ends'),
              subtitle: const Text('Alert X minutes before prayer time ends'),
              value: PrayerAlarmType.beforePrayerEnd,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            RadioListTile<PrayerAlarmType>(
              title: const Text('After prayer starts'),
              subtitle: const Text('Alert X minutes after prayer time begins'),
              value: PrayerAlarmType.afterPrayerStart,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            RadioListTile<PrayerAlarmType>(
              title: const Text('Fixed time'),
              subtitle: const Text('Alert at a specific time'),
              value: PrayerAlarmType.fixedTime,
              groupValue: _selectedType,
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_selectedType == PrayerAlarmType.beforePrayerEnd) ...[
              Text(
                'Minutes before prayer ends',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                isExpanded: true, // Fix pixel overflow
                initialValue: _minutesBeforeEnd,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [5, 10, 15, 20, 25, 30, 35, 40].map((minutes) {
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text('$minutes minutes'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _minutesBeforeEnd = value!;
                  });
                },
              ),
            ] else if (_selectedType == PrayerAlarmType.afterPrayerStart) ...[
              Text(
                'Minutes after prayer starts',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                isExpanded: true, // Fix pixel overflow
                initialValue: _minutesAfterStart,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [5, 10, 15, 20, 25, 30, 35, 40].map((minutes) {
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text('$minutes minutes'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _minutesAfterStart = value!;
                  });
                },
              ),
            ] else ...[
              Text('Fixed time', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ListTile(
                title: Text(_formatTime(_fixedTime)),
                leading: const Icon(Icons.access_time),
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
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Alarm Sound', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true, // Fix pixel overflow
              initialValue: _selectedSoundPath,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: AlarmSoundUtils.availableAlarmSounds.map((sound) {
                return DropdownMenuItem(
                  value: sound['path']!,
                  child: Text(
                    sound['name']!,
                    overflow: TextOverflow.ellipsis, // Prevent overflow
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSoundPath = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Alarm Duration',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _alarmDurationMinutes,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                hintText: 'Select duration',
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 minute')),
                DropdownMenuItem(value: 2, child: Text('2 minutes')),
                DropdownMenuItem(value: 3, child: Text('3 minutes')),
                DropdownMenuItem(value: 5, child: Text('5 minutes')),
                DropdownMenuItem(value: 10, child: Text('10 minutes')),
                DropdownMenuItem(value: 15, child: Text('15 minutes')),
              ],
              onChanged: (value) {
                setState(() {
                  _alarmDurationMinutes = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAlarm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _saveAlarm() {
    final config = PrayerAlarmConfig(
      prayerName: widget.prayer,
      type: _selectedType,
      minutesBeforeEnd: _minutesBeforeEnd,
      minutesAfterStart: _minutesAfterStart,
      fixedTime: _selectedType == PrayerAlarmType.fixedTime
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
