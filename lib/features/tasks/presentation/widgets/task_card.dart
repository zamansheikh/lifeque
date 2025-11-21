import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/task.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggleComplete,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Start timer for real-time updates only if task is active and not completed
    if (widget.task.isActive && !widget.task.isCompleted) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            // This will trigger a rebuild with updated progress
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _getStatusColor().withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Status indicator dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: widget.task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: widget.task.isCompleted
                              ? Colors.grey.shade500
                              : colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    // Action buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Notification indicator
                        if (widget.task.isNotificationEnabled) ...[
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.task.isPinnedToNotification
                                  ? Icons.push_pin_rounded
                                  : Icons.notifications_rounded,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Checkbox
                        GestureDetector(
                          onTap: widget.onToggleComplete,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.task.isCompleted
                                    ? Colors.green.shade400
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                              color: widget.task.isCompleted
                                  ? Colors.green.shade400
                                  : Colors.transparent,
                            ),
                            child: widget.task.isCompleted
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Menu button
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                widget.onEdit?.call();
                                break;
                              case 'delete':
                                widget.onDelete?.call();
                                break;
                            }
                          },
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    size: 18,
                                    color: Colors.red.shade400,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Description
                if (widget.task.description != null &&
                    widget.task.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.task.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                      decoration: widget.task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 16),

                // Progress section
                if (!widget.task.isCompleted) ...[
                  // Countdown Timer Section
                  if (widget.task.isActive && !widget.task.isOverdue) ...[
                    _buildCountdownTimer(),
                    const SizedBox(height: 12),
                  ],

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Progress bar
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: Colors.grey.shade200,
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: widget.task.progressPercentage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: _getStatusColor(),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _getStatusColor().withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(widget.task.progressPercentage * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Time info
                        Row(
                          children: [
                            if (widget.task.isActive &&
                                !widget.task.isOverdue) ...[
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.task.timeLeftFormatted,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                            ],
                            if (!widget.task.isOverdue) ...[
                              Text(
                                '${widget.task.daysLeft} days left',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Bottom info row
                Row(
                  children: [
                    // Task type indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: widget.task.taskType == TaskType.reminder
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.task.taskType == TaskType.reminder
                                ? Icons.notifications_active_rounded
                                : Icons.assignment_rounded,
                            size: 10,
                            color: widget.task.taskType == TaskType.reminder
                                ? Colors.orange
                                : Colors.blue,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            widget.task.taskType == TaskType.reminder
                                ? 'REMINDER'
                                : 'TASK',
                            style: TextStyle(
                              fontSize: 9,
                              color: widget.task.taskType == TaskType.reminder
                                  ? Colors.orange
                                  : Colors.blue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Date info
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.task.taskType == TaskType.reminder
                                ? Icons.access_time_rounded
                                : Icons.calendar_today_rounded,
                            size: 12,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.task.taskType == TaskType.reminder
                                ? DateFormat(
                                    'MMM d, h:mm a',
                                  ).format(widget.task.startDate)
                                : '${DateFormat('MMM d').format(widget.task.startDate)} - ${DateFormat('MMM d').format(widget.task.endDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Countdown timer helpers
  Map<String, int> _getCountdownValues() {
    final now = DateTime.now();
    final endDate = widget.task.endDate;
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return {'days': 0, 'hours': 0, 'minutes': 0, 'seconds': 0};
    }

    return {
      'days': difference.inDays,
      'hours': difference.inHours % 24,
      'minutes': difference.inMinutes % 60,
      'seconds': difference.inSeconds % 60,
    };
  }

  Color _getCountdownColor() {
    final now = DateTime.now();
    final endDate = widget.task.endDate;
    final difference = endDate.difference(now);

    if (difference.inMinutes < 5) {
      return Colors.red.shade600;
    } else if (difference.inHours < 1) {
      return Colors.orange.shade600;
    } else if (difference.inHours < 24) {
      return Colors.amber.shade600;
    } else if (difference.inDays < 3) {
      return Colors.blue.shade600;
    } else {
      return Colors.green.shade600;
    }
  }

  Widget _buildCountdownTimer() {
    final countdown = _getCountdownValues();
    final countdownColor = _getCountdownColor();
    final now = DateTime.now();
    final difference = widget.task.endDate.difference(now);
    final isUrgent = difference.inMinutes < 5;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
                  color: countdownColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.timer_outlined,
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
              // Show different time units based on time remaining
              if (difference.inDays > 0) ...[
                _buildTimeUnit(
                  countdown['days']!,
                  'Days',
                  countdownColor,
                  isUrgent,
                ),
                _buildTimeUnit(
                  countdown['hours']!,
                  'Hours',
                  countdownColor,
                  isUrgent,
                ),
              ] else if (difference.inHours > 0) ...[
                _buildTimeUnit(
                  countdown['hours']!,
                  'Hours',
                  countdownColor,
                  isUrgent,
                ),
                _buildTimeUnit(
                  countdown['minutes']!,
                  'Mins',
                  countdownColor,
                  isUrgent,
                ),
              ] else if (difference.inMinutes > 0) ...[
                _buildTimeUnit(
                  countdown['minutes']!,
                  'Mins',
                  countdownColor,
                  isUrgent,
                ),
                _buildTimeUnit(
                  countdown['seconds']!,
                  'Secs',
                  countdownColor,
                  isUrgent,
                ),
              ] else ...[
                _buildTimeUnit(
                  countdown['seconds']!,
                  'Seconds',
                  countdownColor,
                  isUrgent,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(int value, String label, Color color, bool isUrgent) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: Duration(milliseconds: isUrgent ? 500 : 0),
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: isUrgent ? scale : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
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
        if (mounted && isUrgent) setState(() {});
      },
    );
  }

  Color _getStatusColor() {
    if (widget.task.isCompleted) return Colors.green.shade400;
    if (widget.task.isOverdue) return Colors.red.shade400;
    if (widget.task.isActive) return Colors.orange.shade400;
    return Colors.grey.shade400;
  }

  String _getStatusText() {
    if (widget.task.isCompleted) return 'Completed';
    if (widget.task.isOverdue) return 'Overdue';
    if (widget.task.isActive) return 'Active';
    return 'Upcoming';
  }
}
