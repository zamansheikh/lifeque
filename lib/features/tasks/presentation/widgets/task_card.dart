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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration: widget.task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: widget.task.isCompleted ? Colors.grey : null,
                      ),
                    ),
                  ),
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
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (widget.task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.task.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    decoration: widget.task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${DateFormat.yMd().format(widget.task.startDate)} - ${DateFormat.yMd().format(widget.task.endDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              if (!widget.task.isCompleted) ...[
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: widget.task.progressPercentage,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.task.isOverdue ? Colors.red : Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(widget.task.progressPercentage * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.task.isOverdue ? Colors.red : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Real-time countdown display
                if (widget.task.isActive && !widget.task.isOverdue) ...[
                  Row(
                    children: [
                      Icon(Icons.timer, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        widget.task.timeLeftFormatted,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              Row(
                children: [
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Days left
                  if (!widget.task.isCompleted && !widget.task.isOverdue) ...[
                    Text(
                      '${widget.task.daysLeft} days left',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Notification indicator
                  if (widget.task.isNotificationEnabled) ...[
                    Icon(
                      widget.task.isPinnedToNotification
                          ? Icons.push_pin
                          : Icons.notifications,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Checkbox
                  GestureDetector(
                    onTap: widget.onToggleComplete,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.task.isCompleted
                              ? Colors.green
                              : Colors.grey,
                          width: 2,
                        ),
                        color: widget.task.isCompleted
                            ? Colors.green
                            : Colors.transparent,
                      ),
                      child: widget.task.isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (widget.task.isCompleted) return Colors.green;
    if (widget.task.isOverdue) return Colors.red;
    if (widget.task.isActive) return Colors.orange;
    return Colors.grey;
  }

  String _getStatusText() {
    if (widget.task.isCompleted) return 'Completed';
    if (widget.task.isOverdue) return 'Overdue';
    if (widget.task.isActive) return 'Active';
    return 'Upcoming';
  }
}
