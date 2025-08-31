import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrayerTimeCard extends StatelessWidget {
  final String name;
  final DateTime time;
  final bool isActive;

  const PrayerTimeCard({
    super.key,
    required this.name,
    required this.time,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primary.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 2,
              )
            : null,
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
          // Prayer icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getPrayerIcon(),
              color: isActive ? Colors.white : colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Prayer name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isActive ? colorScheme.primary : Colors.black87,
                  ),
                ),
                Text(
                  _getArabicName(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontFamily:
                        'Arabic', // You might want to add an Arabic font
                  ),
                ),
              ],
            ),
          ),

          // Prayer time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('h:mm a').format(time),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isActive ? colorScheme.primary : Colors.black87,
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getPrayerIcon() {
    switch (name.toLowerCase()) {
      case 'fajr':
        return Icons.wb_twilight;
      case 'dhuhr':
        return Icons.wb_sunny;
      case 'asr':
        return Icons.wb_sunny_outlined;
      case 'maghrib':
        return Icons.wb_twilight;
      case 'isha':
        return Icons.nights_stay;
      default:
        return Icons.access_time;
    }
  }

  String _getArabicName() {
    switch (name.toLowerCase()) {
      case 'fajr':
        return 'فجر';
      case 'dhuhr':
        return 'ظهر';
      case 'asr':
        return 'عصر';
      case 'maghrib':
        return 'مغرب';
      case 'isha':
        return 'عشاء';
      default:
        return '';
    }
  }
}
