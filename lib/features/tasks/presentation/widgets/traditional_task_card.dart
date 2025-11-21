import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'base_task_card.dart';

class TraditionalTaskCard extends BaseTaskCard {
  const TraditionalTaskCard({
    super.key,
    required super.task,
    super.onTap,
    super.onToggleComplete,
    super.onEdit,
    super.onDelete,
  });

  @override
  State<TraditionalTaskCard> createState() => _TraditionalTaskCardState();
}

class _TraditionalTaskCardState extends BaseTaskCardState<TraditionalTaskCard> {
  @override
  Widget build(BuildContext context) {
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

          // Countdown Timer
          if (widget.task.isActive &&
              !widget.task.isOverdue &&
              !widget.task.isCompleted) ...[
            _buildCountdownTimer(),
            const SizedBox(height: 12),
          ],

          // Progress bar
          buildProgressBar(),

          const SizedBox(height: 12),

          // Bottom info
          buildBottomInfo(),
        ],
      ),
    );
  }

  @override
  Color getStatusColor() {
    if (widget.task.isCompleted) {
      return Colors.green;
    } else if (widget.task.isActive) {
      return Colors.blue;
    } else if (widget.task.isOverdue) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  @override
  String getStatusText() {
    if (widget.task.isCompleted) {
      return 'Completed';
    } else if (widget.task.isActive) {
      return 'In Progress';
    } else if (widget.task.isOverdue) {
      return 'Overdue';
    } else {
      return 'Pending';
    }
  }

  @override
  Widget buildContent() {
    // This is handled in the main build method
    return const SizedBox.shrink();
  }

  @override
  Widget buildProgressBar() {
    final progress = widget.task.progressPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: getStatusColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(3),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(getStatusColor()),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildBottomInfo() {
    return Row(
      children: [
        // Task type indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_rounded, size: 10, color: Colors.blue),
              SizedBox(width: 3),
              Text(
                'TASK',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Date range
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Text(
                '${DateFormat('MMM d').format(widget.task.startDate)} - ${DateFormat('MMM d').format(widget.task.endDate)}',
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
}
