import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/salah_time_calculator.dart';

class RestrictedTimesCard extends StatelessWidget {
  final SalahTimeCalculator calculator;

  const RestrictedTimesCard({super.key, required this.calculator});

  @override
  Widget build(BuildContext context) {
    final restrictedTimes = calculator.getRestrictedTimes();
    final currentRestricted = calculator.getCurrentRestrictedPeriod();
    final isCurrentlyRestricted = calculator.isCurrentTimeRestricted();

    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isCurrentlyRestricted
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: isCurrentlyRestricted ? Colors.orange : Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Restricted Times',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCurrentlyRestricted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      isCurrentlyRestricted
                          ? 'Prayer is currently discouraged'
                          : 'Times when prayer is discouraged (Makruh)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Current Restricted Period (if active)
          if (isCurrentlyRestricted && currentRestricted != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Currently Restricted: ${currentRestricted['name']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentRestricted['reason'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ends in: ${_formatDuration(currentRestricted['remaining'])}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // All Restricted Times List
          const Text(
            'Today\'s Restricted Periods',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          ...restrictedTimes.entries.map((entry) {
            final period = entry.value;
            final start = period['start'] as DateTime;
            final end = period['end'] as DateTime;
            final reason = period['reason'] as String;
            final now = DateTime.now();
            final isActive = now.isAfter(start) && now.isBefore(end);
            final isPast = now.isAfter(end);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.orange.shade50
                    : isPast
                    ? Colors.grey.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? Colors.orange.shade200
                      : isPast
                      ? Colors.grey.shade200
                      : Colors.red.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isActive
                            ? Icons.pause_circle_filled
                            : isPast
                            ? Icons.check_circle
                            : Icons.schedule,
                        color: isActive
                            ? Colors.orange.shade600
                            : isPast
                            ? Colors.grey.shade600
                            : Colors.red.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.orange.shade700
                                : isPast
                                ? Colors.grey.shade600
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NOW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: 13,
                      color: isActive
                          ? Colors.orange.shade600
                          : isPast
                          ? Colors.grey.shade500
                          : Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'From: ${DateFormat('h:mm a').format(start)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? Colors.orange.shade700
                              : isPast
                              ? Colors.grey.shade600
                              : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'To: ${DateFormat('h:mm a').format(end)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? Colors.orange.shade700
                              : isPast
                              ? Colors.grey.shade600
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 16),

          // Info note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'During these times, voluntary prayers (nafl) are discouraged, but missed obligatory prayers (qada) can still be performed.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
