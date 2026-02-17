import 'package:flutter/material.dart';

/// Placeholder widget shown when location is not set
class PrayerWidgetPlaceholder extends StatelessWidget {
  const PrayerWidgetPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D4F4F), Color(0xFF0A6B5C), Color(0xFF0E7E6B)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mosque,
                size: 40,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              const Text(
                'Prayer Times',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap to open app & set your location',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Set Location',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
