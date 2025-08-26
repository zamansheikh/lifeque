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
                if (widget.task.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.task.description,
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
                    // Date range
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
