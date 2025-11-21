import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'base_task_card.dart';

class ReminderTaskCard extends BaseTaskCard {
  const ReminderTaskCard({
    super.key,
    required super.task,
    super.onTap,
    super.onToggleComplete,
    super.onEdit,
    super.onDelete,
  });

  @override
  State<ReminderTaskCard> createState() => _ReminderTaskCardState();
}

class _ReminderTaskCardState extends BaseTaskCardState<ReminderTaskCard> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final reminderTime = widget.task.startDate;
    final isPast = reminderTime.isBefore(now);

    return buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(),

          // Description
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

          // Countdown Timer (if reminder is upcoming)
          if (!isPast && !widget.task.isCompleted) ...[
            _buildCountdownTimer(),
            const SizedBox(height: 12),
          ],

          // Reminder time info
          buildReminderTimeInfo(),

          const SizedBox(height: 12),

          // Bottom info
          buildBottomInfo(),
        ],
      ),
    );
  }

  Widget buildReminderTimeInfo() {
    final now = DateTime.now();
    final reminderTime =
        widget.task.startDate; // For reminders, startDate = reminderTime
    final isPast = reminderTime.isBefore(now);

    String timeText;
    Color timeColor;
    IconData timeIcon;

    if (widget.task.isCompleted) {
      timeText = 'Completed';
      timeColor = Colors.green;
      timeIcon = Icons.check_circle_rounded;
    } else if (isPast) {
      final difference = now.difference(reminderTime);
      if (difference.inMinutes < 60) {
        timeText = '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        timeText = '${difference.inHours}h ago';
      } else {
        timeText = '${difference.inDays}d ago';
      }
      timeColor = Colors.red;
      timeIcon = Icons.schedule_rounded;
    } else {
      final difference = reminderTime.difference(now);
      if (difference.inMinutes < 60) {
        timeText = 'in ${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        timeText = 'in ${difference.inHours}h';
      } else if (difference.inDays < 7) {
        timeText = 'in ${difference.inDays}d';
      } else {
        timeText = DateFormat('MMM d').format(reminderTime);
      }
      timeColor = Colors.orange;
      timeIcon = Icons.schedule_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: timeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: timeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(timeIcon, color: timeColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(reminderTime),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: timeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('h:mm a').format(reminderTime),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: timeColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: timeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              timeText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: timeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Color getStatusColor() {
    if (widget.task.isCompleted) {
      return Colors.green;
    } else if (widget.task.startDate.isBefore(DateTime.now())) {
      return Colors.red; // Overdue
    } else {
      return Colors.orange; // Upcoming
    }
  }

  @override
  String getStatusText() {
    if (widget.task.isCompleted) {
      return 'Completed';
    } else if (widget.task.startDate.isBefore(DateTime.now())) {
      return 'Missed';
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
    return const SizedBox.shrink(); // Reminders don't need progress bars
  }

  @override
  Widget buildBottomInfo() {
    return Row(
      children: [
        // Reminder type indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: 10,
                color: Colors.orange,
              ),
              SizedBox(width: 3),
              Text(
                'REMINDER',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Completion toggle
        GestureDetector(
          onTap: widget.onToggleComplete,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: widget.task.isCompleted
                  ? Colors.green
                  : Colors.transparent,
              border: Border.all(
                color: widget.task.isCompleted
                    ? Colors.green
                    : Colors.grey.shade400,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: widget.task.isCompleted
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(width: 8),
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

  Widget _buildCountdownTimer() {
    final now = DateTime.now();
    final reminderTime = widget.task.startDate;
    final difference = reminderTime.difference(now);

    final daysUntil = difference.inDays;
    final hoursUntil = difference.inHours % 24;
    final minutesUntil = difference.inMinutes % 60;
    final secondsUntil = difference.inSeconds % 60;

    // Determine color based on urgency
    Color countdownColor;
    if (difference.inHours < 1) {
      countdownColor = Colors.red.shade600;
    } else if (difference.inHours < 6) {
      countdownColor = Colors.orange.shade600;
    } else if (difference.inHours < 24) {
      countdownColor = Colors.amber.shade600;
    } else if (difference.inDays < 3) {
      countdownColor = Colors.blue.shade600;
    } else {
      countdownColor = Colors.indigo.shade600;
    }

    final isUrgent = difference.inHours < 1;

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
                  Icons.alarm_rounded,
                  size: 16,
                  color: countdownColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Time Remaining',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: countdownColor,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (isUrgent)
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: 0.5 + (value * 0.5),
                      child: Icon(
                        Icons.warning_rounded,
                        size: 18,
                        color: Colors.red.shade600,
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
                _buildTimeUnit(daysUntil, 'Days', countdownColor, isUrgent),
                _buildTimeUnit(hoursUntil, 'Hours', countdownColor, isUrgent),
              ] else if (hoursUntil > 0) ...[
                _buildTimeUnit(hoursUntil, 'Hours', countdownColor, isUrgent),
                _buildTimeUnit(minutesUntil, 'Mins', countdownColor, isUrgent),
              ] else ...[
                _buildTimeUnit(minutesUntil, 'Mins', countdownColor, isUrgent),
                _buildTimeUnit(secondsUntil, 'Secs', countdownColor, isUrgent),
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
