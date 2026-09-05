import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../domain/entities/task.dart';
import '../../bloc/task_bloc.dart';

class BirthdayTaskDetail extends StatefulWidget {
  final Task task;

  const BirthdayTaskDetail({super.key, required this.task});

  @override
  State<BirthdayTaskDetail> createState() => _BirthdayTaskDetailState();
}

class _BirthdayTaskDetailState extends State<BirthdayTaskDetail> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update every second for real-time countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final birthdayThisYear = DateTime(
      now.year,
      widget.task.endDate.month,
      widget.task.endDate.day,
    );
    final birthdayNextYear = DateTime(
      now.year + 1,
      widget.task.endDate.month,
      widget.task.endDate.day,
    );
    final nextBirthday = now.isAfter(birthdayThisYear)
        ? birthdayNextYear
        : birthdayThisYear;
    final daysUntilBirthday = nextBirthday.difference(now).inDays;
    final currentAge = now.year - widget.task.endDate.year;
    final ageOnNextBirthday =
        currentAge + (now.isAfter(birthdayThisYear) ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header card with birthday info
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.task.isCompleted
                    ? Colors.green.shade50
                    : Colors.pink.shade50,
                widget.task.isCompleted
                    ? Colors.green.shade100
                    : Colors.pink.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.task.isCompleted
                  ? Colors.green.shade200
                  : Colors.pink.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.task.isCompleted
                          ? Colors.green.shade100
                          : Colors.pink.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.task.isCompleted
                          ? Icons.check_circle
                          : Icons.cake_rounded,
                      color: widget.task.isCompleted
                          ? Colors.green
                          : Colors.pink,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Birthday Reminder',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.task.isCompleted
                                ? Colors.green.shade700
                                : Colors.pink.shade700,
                          ),
                        ),
                        Text(
                          widget.task.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration: widget.task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.read<TaskBloc>().add(
                        ToggleTaskCompletion(widget.task.id),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.task.isCompleted
                            ? Colors.green
                            : Colors.white,
                        border: Border.all(
                          color: widget.task.isCompleted
                              ? Colors.green
                              : Colors.pink,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: widget.task.isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 24,
                            )
                          : const Icon(
                              Icons.cake_rounded,
                              color: Colors.pink,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
              if (widget.task.description != null &&
                  widget.task.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  widget.task.description!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Live Countdown Timer
        if (!widget.task.isCompleted && daysUntilBirthday <= 30) ...[
          _buildLiveCountdown(nextBirthday, daysUntilBirthday),
          const SizedBox(height: 20),
        ],

        // Age and countdown info
        if (!widget.task.isCompleted) ...[
          Row(
            children: [
              // Current age card
              Expanded(
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
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$currentAge',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'Current Age',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Next birthday countdown
              Expanded(
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
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: Colors.pink,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$daysUntilBirthday',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                      Text(
                        'Days Until Birthday',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Birthday details
        Container(
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.cake_rounded,
                      color: Colors.pink,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Birthday Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Birth Date',
                DateFormat('MMMM dd, yyyy').format(widget.task.endDate),
                Icons.calendar_today_rounded,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Next Birthday',
                DateFormat('EEEE, MMMM dd, yyyy').format(nextBirthday),
                Icons.event_rounded,
                Colors.pink,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Age on Next Birthday',
                '$ageOnNextBirthday years old',
                Icons.star_rounded,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Zodiac Sign',
                _getZodiacSign(widget.task.endDate),
                Icons.auto_awesome_rounded,
                Colors.purple,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Celebration suggestions (if birthday is soon)
        if (daysUntilBirthday <= 30 && !widget.task.isCompleted) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.pink.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.pink.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.celebration_rounded,
                        color: Colors.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Birthday Coming Soon!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  daysUntilBirthday == 0
                      ? '🎉 Today is the birthday! Don\'t forget to celebrate!'
                      : daysUntilBirthday == 1
                      ? '🎂 Birthday is tomorrow! Time to prepare!'
                      : '🎈 Only $daysUntilBirthday days left! Start planning the celebration!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Settings and metadata
        Container(
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Reminder Type',
                'Annual (every year)',
                Icons.repeat_rounded,
                Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Notifications',
                'Automatic yearly reminders',
                Icons.notifications_active_rounded,
                Colors.green,
              ),
              if (widget.task.isPinnedToNotification) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Pinned',
                  'Visible in notifications',
                  Icons.push_pin_rounded,
                  Colors.orange,
                ),
              ],
              const SizedBox(height: 8),
              _buildDetailRow(
                'Created',
                DateFormat('MMM dd, yyyy').format(widget.task.createdAt),
                Icons.add_circle_outline_rounded,
                Colors.green,
              ),
              if (widget.task.updatedAt != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Updated',
                  DateFormat('MMM dd, yyyy').format(widget.task.updatedAt!),
                  Icons.edit_rounded,
                  Colors.blue,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }

  String _getZodiacSign(DateTime birthDate) {
    final month = birthDate.month;
    final day = birthDate.day;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
      return 'Aries ♈';
    }
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
      return 'Taurus ♉';
    }
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
      return 'Gemini ♊';
    }
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
      return 'Cancer ♋';
    }
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Leo ♌';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
      return 'Virgo ♍';
    }
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
      return 'Libra ♎';
    }
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
      return 'Scorpio ♏';
    }
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
      return 'Sagittarius ♐';
    }
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
      return 'Capricorn ♑';
    }
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      return 'Aquarius ♒';
    }
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) {
      return 'Pisces ♓';
    }

    return 'Unknown';
  }

  Widget _buildLiveCountdown(DateTime nextBirthday, int daysUntil) {
    final now = DateTime.now();
    final difference = nextBirthday.difference(now);
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    // Determine color based on urgency
    Color countdownColor;
    if (daysUntil == 0) {
      countdownColor = Colors.pink.shade600;
    } else if (daysUntil <= 3) {
      countdownColor = Colors.purple.shade600;
    } else if (daysUntil <= 7) {
      countdownColor = Colors.orange.shade600;
    } else {
      countdownColor = Colors.blue.shade600;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            countdownColor.withValues(alpha: 0.15),
            countdownColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: countdownColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                daysUntil == 0 ? Icons.cake_rounded : Icons.celebration_rounded,
                color: countdownColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                daysUntil == 0 ? '🎉 Birthday Today!' : 'Birthday Countdown',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: countdownColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (daysUntil > 0) ...[
                _buildCountdownUnit(
                  daysUntil.toString(),
                  'Days',
                  countdownColor,
                ),
                _buildCountdownUnit(
                  hours.toString().padLeft(2, '0'),
                  'Hours',
                  countdownColor,
                ),
              ] else ...[
                _buildCountdownUnit(
                  hours.toString().padLeft(2, '0'),
                  'Hours',
                  countdownColor,
                ),
                _buildCountdownUnit(
                  minutes.toString().padLeft(2, '0'),
                  'Minutes',
                  countdownColor,
                ),
                _buildCountdownUnit(
                  seconds.toString().padLeft(2, '0'),
                  'Seconds',
                  countdownColor,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownUnit(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
