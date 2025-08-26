import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/task.dart';
import '../../bloc/task_bloc.dart';
import '../../widgets/progress_indicator_widget.dart';

class TraditionalTaskDetail extends StatelessWidget {
  final Task task;

  const TraditionalTaskDetail({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header card with title and completion
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                task.isCompleted ? Colors.green.shade50 : Colors.blue.shade50,
                task.isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: task.isCompleted
                  ? Colors.green.shade200
                  : Colors.blue.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted
                                ? Colors.grey.shade600
                                : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.read<TaskBloc>().add(
                        ToggleTaskCompletion(task.id),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.isCompleted ? Colors.green : Colors.white,
                        border: Border.all(
                          color: task.isCompleted
                              ? Colors.green
                              : Colors.grey.shade300,
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
                      child: task.isCompleted
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Progress section (only for active tasks)
        if (!task.isCompleted) ...[
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
                        color: task.isOverdue
                            ? Colors.red.shade100
                            : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.trending_up_rounded,
                        color: task.isOverdue ? Colors.red : Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ProgressIndicatorWidget(
                  progress: task.progressPercentage,
                  label:
                      '${(task.progressPercentage * 100).toStringAsFixed(1)}% Complete',
                  color: task.isOverdue ? Colors.red : Colors.blue,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildProgressCard(
                        'Days Left',
                        '${task.daysLeft}',
                        Icons.schedule_rounded,
                        task.isOverdue ? Colors.red : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildProgressCard(
                        'Total Days',
                        '${task.endDate.difference(task.startDate).inDays}',
                        Icons.calendar_month_rounded,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Timeline section
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
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.timeline_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Timeline',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTimelineItem(
                'Started',
                DateFormat('MMM dd, yyyy • h:mm a').format(task.startDate),
                Icons.play_circle_outline_rounded,
                Colors.green,
                true,
              ),
              const SizedBox(height: 12),
              _buildTimelineItem(
                'Due',
                DateFormat('MMM dd, yyyy • h:mm a').format(task.endDate),
                Icons.flag_rounded,
                task.isOverdue ? Colors.red : Colors.orange,
                false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

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
                    'Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Notifications',
                task.isNotificationEnabled ? 'Enabled' : 'Disabled',
                task.isNotificationEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                task.isNotificationEnabled ? Colors.blue : Colors.grey,
              ),
              if (task.isPinnedToNotification) ...[
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
                DateFormat('MMM dd, yyyy').format(task.createdAt),
                Icons.add_circle_outline_rounded,
                Colors.green,
              ),
              if (task.updatedAt != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Updated',
                  DateFormat('MMM dd, yyyy').format(task.updatedAt!),
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

  Widget _buildProgressCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isStart,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
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
        ),
      ],
    );
  }

  Color _getStatusColor() {
    if (task.isCompleted) return Colors.green;
    if (task.isOverdue) return Colors.red;
    if (task.isActive) return Colors.orange;
    return Colors.grey;
  }

  String _getStatusText() {
    if (task.isCompleted) return 'Completed';
    if (task.isOverdue) return 'Overdue';
    if (task.isActive) return 'Active';
    return 'Upcoming';
  }
}
