import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import '../../../../core/services/prayer_alarm_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Alarms'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<bool>(
            stream: _alarmService.enabledStream,
            builder: (context, snapshot) {
              final isEnabled = snapshot.data ?? true;
              return Switch(
                value: isEnabled,
                onChanged: (value) {
                  _alarmService.toggleGlobalAlarms(value);
                },
                activeColor: Colors.white,
              );
            },
          ),
          const SizedBox(width: 16),
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
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.notifications, color: Colors.teal),
                              const SizedBox(width: 8),
                              Text(
                                'Prayer Alarms',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            globalEnabled
                                ? 'Prayer alarms are enabled. Configure individual prayer reminders below.'
                                : 'Prayer alarms are disabled. Use the switch above to enable.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: globalEnabled
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  }).toList(),
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
    final isConfigured = existingAlarm != null;
    final isEnabled = isConfigured && existingAlarm.isEnabled;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          _getPrayerIcon(prayer),
          color: isEnabled && globalEnabled ? Colors.teal : Colors.grey,
        ),
        title: Text(prayer),
        subtitle: Text(
          _getAlarmStatusText(existingAlarm, globalEnabled),
          style: TextStyle(
            color: isEnabled && globalEnabled ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: isEnabled && globalEnabled,
          onChanged: globalEnabled
              ? (value) {
                  if (value) {
                    _showAlarmConfigDialog(prayer, existingAlarm);
                  } else {
                    _alarmService.removeAlarm(prayer);
                  }
                }
              : null,
        ),
        children: [
          if (isConfigured) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        existingAlarm.type == PrayerAlarmType.beforePrayerEnd
                            ? '${existingAlarm.minutesBeforeEnd} minutes before prayer ends'
                            : 'Fixed time: ${_formatTime(existingAlarm.fixedTime!)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: globalEnabled
                            ? () {
                                _showAlarmConfigDialog(prayer, existingAlarm);
                              }
                            : null,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                      TextButton.icon(
                        onPressed: globalEnabled
                            ? () {
                                _alarmService.removeAlarm(prayer);
                              }
                            : null,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Remove'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: globalEnabled
                      ? () {
                          _showAlarmConfigDialog(prayer, null);
                        }
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Alarm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
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
    } else {
      return 'Fixed: ${_formatTime(alarm.fixedTime!)}';
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
  late TimeOfDay _fixedTime;

  @override
  void initState() {
    super.initState();

    if (widget.existingAlarm != null) {
      _selectedType = widget.existingAlarm!.type;
      _minutesBeforeEnd = widget.existingAlarm!.minutesBeforeEnd;
      _fixedTime = widget.existingAlarm!.fixedTime != null
          ? TimeOfDay.fromDateTime(widget.existingAlarm!.fixedTime!)
          : const TimeOfDay(hour: 9, minute: 0);
    } else {
      _selectedType = PrayerAlarmType.beforePrayerEnd;
      _minutesBeforeEnd = 5;
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
                value: _minutesBeforeEnd,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: [5, 10, 15, 20].map((minutes) {
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
    );

    widget.onSave(config);
    Navigator.of(context).pop();
  }
}
