import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'base_task_card.dart';

class BirthdayReminderCard extends BaseTaskCard {
  const BirthdayReminderCard({
    super.key,
    required super.task,
    super.onTap,
    super.onToggleComplete,
    super.onEdit,
    super.onDelete,
  });

  @override
  State<BirthdayReminderCard> createState() => _BirthdayReminderCardState();
}

class _BirthdayReminderCardState
    extends BaseTaskCardState<BirthdayReminderCard> {
  @override
  Widget build(BuildContext context) {
    return buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(),

          // Description with birthday person info
          if (widget.task.description != null &&
              widget.task.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.task.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 16),

          // Countdown Timer (if birthday is within 30 days)
          if (_getDaysUntilBirthday() <= 30 && !widget.task.isCompleted) ...[
            _buildCountdownTimer(),
            const SizedBox(height: 12),
          ],

          // Birthday info
          buildBirthdayInfo(),

          const SizedBox(height: 12),

          // Age calculation and next birthday
          buildAgeInfo(),

          const SizedBox(height: 12),

          // Bottom info
          buildBottomInfo(),
        ],
      ),
    );
  }

  Widget buildBirthdayInfo() {
    final birthdayDate = widget.task.startDate;
    final now = DateTime.now();
    final currentYear = now.year;

    // Calculate this year's birthday
    final thisYearBirthday = DateTime(
      currentYear,
      birthdayDate.month,
      birthdayDate.day,
    );
    final nextYearBirthday = DateTime(
      currentYear + 1,
      birthdayDate.month,
      birthdayDate.day,
    );

    // Determine next birthday
    final nextBirthday = thisYearBirthday.isAfter(now)
        ? thisYearBirthday
        : nextYearBirthday;
    final daysUntilBirthday = nextBirthday.difference(now).inDays;

    String countdownText;
    Color countdownColor;
    IconData countdownIcon;

    if (daysUntilBirthday == 0) {
      countdownText = 'Today! 🎉';
      countdownColor = Colors.pink;
      countdownIcon = Icons.cake_rounded;
    } else if (daysUntilBirthday == 1) {
      countdownText = 'Tomorrow!';
      countdownColor = Colors.purple;
      countdownIcon = Icons.event_rounded;
    } else if (daysUntilBirthday <= 7) {
      countdownText = 'in $daysUntilBirthday days';
      countdownColor = Colors.orange;
      countdownIcon = Icons.event_available_rounded;
    } else if (daysUntilBirthday <= 30) {
      countdownText = 'in $daysUntilBirthday days';
      countdownColor = Colors.blue;
      countdownIcon = Icons.event_note_rounded;
    } else {
      countdownText = 'in $daysUntilBirthday days';
      countdownColor = Colors.indigo;
      countdownIcon = Icons.event_note_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            countdownColor.withValues(alpha: 0.1),
            countdownColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: countdownColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: countdownColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(countdownIcon, color: countdownColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM d').format(nextBirthday),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: countdownColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  countdownText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: countdownColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (daysUntilBirthday <= 7) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: countdownColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                daysUntilBirthday == 0 ? '🎂' : '⭐',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildAgeInfo() {
    final birthdayDate = widget.task.startDate;
    final now = DateTime.now();

    // Calculate current age
    int age = now.year - birthdayDate.year;
    if (now.month < birthdayDate.month ||
        (now.month == birthdayDate.month && now.day < birthdayDate.day)) {
      age--;
    }

    // Calculate next age
    final nextAge = age + 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.numbers_rounded, size: 16, color: Colors.purple.shade600),
          const SizedBox(width: 8),
          Text(
            'Currently $age years old',
            style: TextStyle(
              fontSize: 12,
              color: Colors.purple.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            'Turning $nextAge',
            style: TextStyle(
              fontSize: 12,
              color: Colors.purple.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Color getStatusColor() {
    final birthdayDate = widget.task.startDate;
    final now = DateTime.now();
    final thisYearBirthday = DateTime(
      now.year,
      birthdayDate.month,
      birthdayDate.day,
    );
    final daysUntilBirthday = thisYearBirthday.difference(now).inDays;

    if (daysUntilBirthday == 0) {
      return Colors.pink; // Today
    } else if (daysUntilBirthday <= 7 && daysUntilBirthday > 0) {
      return Colors.purple; // This week
    } else {
      return Colors.indigo; // Future
    }
  }

  @override
  String getStatusText() {
    final birthdayDate = widget.task.startDate;
    final now = DateTime.now();
    final thisYearBirthday = DateTime(
      now.year,
      birthdayDate.month,
      birthdayDate.day,
    );
    final daysUntilBirthday = thisYearBirthday.difference(now).inDays;

    if (daysUntilBirthday == 0) {
      return 'Today!';
    } else if (daysUntilBirthday == 1) {
      return 'Tomorrow';
    } else if (daysUntilBirthday <= 7 && daysUntilBirthday > 0) {
      return 'This Week';
    } else if (daysUntilBirthday < 0) {
      return 'Passed';
    } else {
      return 'Upcoming';
    }
  }

  @override
  Widget buildContent() {
    return const SizedBox.shrink();
  }

  @override
  Widget buildProgressBar() {
    return const SizedBox.shrink(); // Birthday reminders don't need progress bars
  }

  @override
  Widget buildBottomInfo() {
    return Row(
      children: [
        // Birthday type indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.pink.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cake_rounded, size: 10, color: Colors.pink),
              SizedBox(width: 3),
              Text(
                'BIRTHDAY',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.pink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Status chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: getStatusColor().withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            getStatusText(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: getStatusColor(),
            ),
          ),
        ),
      ],
    );
  }

  int _getDaysUntilBirthday() {
    final birthdayDate = widget.task.startDate;
    final now = DateTime.now();
    final currentYear = now.year;

    final thisYearBirthday = DateTime(
      currentYear,
      birthdayDate.month,
      birthdayDate.day,
    );
    final nextYearBirthday = DateTime(
      currentYear + 1,
      birthdayDate.month,
      birthdayDate.day,
    );

    final nextBirthday = thisYearBirthday.isAfter(now)
        ? thisYearBirthday
        : nextYearBirthday;
    return nextBirthday.difference(now).inDays;
  }

  Widget _buildCountdownTimer() {
    final birthdayDate = widget.task.startDate;
    final now = DateTime.now();
    final currentYear = now.year;

    final thisYearBirthday = DateTime(
      currentYear,
      birthdayDate.month,
      birthdayDate.day,
    );
    final nextYearBirthday = DateTime(
      currentYear + 1,
      birthdayDate.month,
      birthdayDate.day,
    );

    final nextBirthday = thisYearBirthday.isAfter(now)
        ? thisYearBirthday
        : nextYearBirthday;
    final difference = nextBirthday.difference(now);
    final daysUntil = difference.inDays;
    final hoursUntil = difference.inHours % 24;
    final minutesUntil = difference.inMinutes % 60;
    final secondsUntil = difference.inSeconds % 60;

    // Determine color based on urgency
    Color countdownColor;
    if (daysUntil == 0) {
      countdownColor = Colors.pink.shade600;
    } else if (daysUntil <= 3) {
      countdownColor = Colors.purple.shade600;
    } else if (daysUntil <= 7) {
      countdownColor = Colors.orange.shade600;
    } else if (daysUntil <= 14) {
      countdownColor = Colors.blue.shade600;
    } else {
      countdownColor = Colors.indigo.shade600;
    }

    final isVeryClose = daysUntil <= 3;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            countdownColor.withValues(alpha: 0.15),
            countdownColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: countdownColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: countdownColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  daysUntil == 0
                      ? Icons.cake_rounded
                      : Icons.celebration_rounded,
                  size: 16,
                  color: countdownColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                daysUntil == 0 ? '🎉 Birthday Today!' : 'Birthday Countdown',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: countdownColor,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (isVeryClose)
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: 0.8 + (value * 0.2),
                      child: Text(
                        daysUntil == 0 ? '🎂' : '🎈',
                        style: const TextStyle(fontSize: 18),
                      ),
                    );
                  },
                  onEnd: () {
                    if (mounted) setState(() {});
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (daysUntil > 0) ...[
                _buildTimeUnit(daysUntil, 'Days', countdownColor, isVeryClose),
                _buildTimeUnit(
                  hoursUntil,
                  'Hours',
                  countdownColor,
                  isVeryClose,
                ),
              ] else ...[
                _buildTimeUnit(
                  hoursUntil,
                  'Hours',
                  countdownColor,
                  isVeryClose,
                ),
                _buildTimeUnit(
                  minutesUntil,
                  'Mins',
                  countdownColor,
                  isVeryClose,
                ),
                _buildTimeUnit(
                  secondsUntil,
                  'Secs',
                  countdownColor,
                  isVeryClose,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(int value, String label, Color color, bool animate) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: Duration(milliseconds: animate ? 500 : 0),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: animate ? scale : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  value.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted && animate) setState(() {});
      },
    );
  }
}
