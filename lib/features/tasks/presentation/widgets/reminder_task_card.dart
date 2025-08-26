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
    return buildContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(),

          // Description
          if (widget.task.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.task.description,
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
}
