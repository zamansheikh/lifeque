import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/salah_time_calculator.dart';
import '../../data/services/prayer_settings_service.dart';

class MosqueTimesTab extends StatefulWidget {
  final SalahTimeCalculator? calculator;

  const MosqueTimesTab({super.key, this.calculator});

  @override
  State<MosqueTimesTab> createState() => _MosqueTimesTabState();
}

class _MosqueTimesTabState extends State<MosqueTimesTab> {
  final PrayerSettingsService _settingsService = PrayerSettingsService.instance;
  Map<String, TimeOfDay> _mosqueTimes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMosqueTimes();
  }

  Future<void> _loadMosqueTimes() async {
    final fajrStr = await _settingsService.getMosqueTime('fajr');
    final dhuhrStr = await _settingsService.getMosqueTime('dhuhr');
    final asrStr = await _settingsService.getMosqueTime('asr');
    final ishaStr = await _settingsService.getMosqueTime('isha');

    setState(() {
      _mosqueTimes = {
        'Fajr': _parseTime(fajrStr) ?? const TimeOfDay(hour: 5, minute: 0),
        'Dhuhr': _parseTime(dhuhrStr) ?? const TimeOfDay(hour: 13, minute: 30),
        'Asr': _parseTime(asrStr) ?? const TimeOfDay(hour: 16, minute: 30),
        'Isha': _parseTime(ishaStr) ?? const TimeOfDay(hour: 20, minute: 0),
      };
      _isLoading = false;
    });
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateMosqueTime(String prayer, TimeOfDay time) async {
    final timeStr = '${time.hour}:${time.minute}';
    await _settingsService.saveMosqueTime(prayer, timeStr);
    setState(() {
      _mosqueTimes[prayer] = time;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final prayerTimes = widget.calculator?.getPrayerTimesMap();
    final maghribTime = prayerTimes?['Maghrib'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(context),
        const SizedBox(height: 20),
        _buildTimeCard(
          context,
          'Fajr',
          'ফজর',
          Icons.wb_twilight,
          _mosqueTimes['Fajr'],
          isEditable: true,
        ),
        const SizedBox(height: 12),
        _buildTimeCard(
          context,
          'Dhuhr',
          'যোহর',
          Icons.wb_sunny,
          _mosqueTimes['Dhuhr'],
          isEditable: true,
        ),
        const SizedBox(height: 12),
        _buildTimeCard(
          context,
          'Asr',
          'আছর',
          Icons.wb_cloudy,
          _mosqueTimes['Asr'],
          isEditable: true,
        ),
        const SizedBox(height: 12),
        _buildTimeCard(
          context,
          'Maghrib',
          'মাগরিব',
          Icons.nights_stay,
          maghribTime != null ? TimeOfDay.fromDateTime(maghribTime) : null,
          isEditable: false,
          subtitle: 'সূর্যাস্তের সাথে সাথে',
        ),
        const SizedBox(height: 12),
        _buildTimeCard(
          context,
          'Isha',
          'এশা',
          Icons.bedtime,
          _mosqueTimes['Isha'],
          isEditable: true,
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'মসজিদের জামাতের সময়সূচী পরিবর্তনযোগ্য। আপনার এলাকার মসজিদের সময় অনুযায়ী সেট করে নিন।',
              style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(
    BuildContext context,
    String title,
    String banglaTitle,
    IconData icon,
    TimeOfDay? time, {
    bool isEditable = true,
    String? subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final formattedTime = time != null ? _formatTimeOfDay(time) : '--:--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banglaTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (isEditable)
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: time ?? TimeOfDay.now(),
                );
                if (picked != null) {
                  _updateMosqueTime(title, picked);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }
}
