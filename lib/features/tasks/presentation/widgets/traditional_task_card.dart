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
}
