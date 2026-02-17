import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Future<void> _showTimePicker(String prayer, TimeOfDay? currentTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      _updateMosqueTime(prayer, picked);
    }
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
        const Text(
          'Mosque Times',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildMosqueTimeCard(
          context,
          name: 'Fajr',
          arabicName: 'فجر',
          icon: Icons.wb_twilight,
          time: _mosqueTimes['Fajr'],
          isEditable: true,
        ),
        const SizedBox(height: 12),
        _buildMosqueTimeCard(
          context,
          name: 'Dhuhr',
          arabicName: 'ظهر',
          icon: Icons.wb_sunny,
          time: _mosqueTimes['Dhuhr'],
          isEditable: true,
        ),
        const SizedBox(height: 12),
        _buildMosqueTimeCard(
          context,
          name: 'Asr',
          arabicName: 'عصر',
          icon: Icons.wb_sunny_outlined,
          time: _mosqueTimes['Asr'],
          isEditable: true,
        ),
        const SizedBox(height: 12),
        _buildMosqueTimeCard(
          context,
          name: 'Maghrib',
          arabicName: 'مغرب',
          icon: Icons.wb_twilight,
          time: maghribTime != null
              ? TimeOfDay.fromDateTime(maghribTime)
              : null,
          isEditable: false,
          subtitle: 'At Sunset',
        ),
        const SizedBox(height: 12),
        _buildMosqueTimeCard(
          context,
          name: 'Isha',
          arabicName: 'عشاء',
          icon: Icons.nights_stay,
          time: _mosqueTimes['Isha'],
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
              'Long press on any editable prayer time to change the mosque jamaat time for your area.',
              style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMosqueTimeCard(
    BuildContext context, {
    required String name,
    required String arabicName,
    required IconData icon,
    required TimeOfDay? time,
    bool isEditable = true,
    String? subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final formattedTime = time != null ? _formatTimeOfDay(time) : '--:--';

    return GestureDetector(
      onLongPress: isEditable
          ? () {
              _showTimePicker(name, time);
              // Haptic feedback
              HapticFeedback.mediumImpact();
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
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
            // Prayer icon — same style as Waqt tab
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),

            // Prayer name + Arabic/subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle ?? arabicName,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Time display
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                if (isEditable)
                  Text(
                    'Long press to edit',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }
}
