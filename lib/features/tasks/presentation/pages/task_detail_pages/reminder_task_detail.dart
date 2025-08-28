import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/task.dart';
import '../../bloc/task_bloc.dart';

class ReminderTaskDetail extends StatelessWidget {
  final Task task;

  const ReminderTaskDetail({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final reminderTime = task.endDate;
    final isPast = now.isAfter(reminderTime);
    final timeUntil = reminderTime.difference(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header card with countdown
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                task.isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
                task.isCompleted
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: task.isCompleted
                  ? Colors.green.shade200
                  : Colors.orange.shade200,
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
                      color: task.isCompleted
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      task.isCompleted
                          ? Icons.check_circle
                          : Icons.access_time_rounded,
                      color: task.isCompleted ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.isCompleted
                              ? 'Reminder Completed'
                              : (isPast
                                    ? 'Reminder Triggered'
                                    : 'Reminder Pending'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: task.isCompleted
                                ? Colors.green.shade700
                                : (isPast
                                      ? Colors.red.shade700
                                      : Colors.orange.shade700),
                          ),
                        ),
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted
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
                              : Colors.orange,
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
                          : Icon(
                              Icons.notifications_rounded,
                              color: Colors.orange,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  task.description,
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

        // Countdown/Time info
        if (!task.isCompleted) ...[
          Container(
            padding: const EdgeInsets.all(24),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPast ? Icons.alarm_off_rounded : Icons.alarm_rounded,
                      color: isPast ? Colors.red : Colors.orange,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isPast ? 'Time Passed' : 'Time Remaining',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isPast ? Colors.red : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!isPast) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTimeUnit(
                        '${timeUntil.inDays}',
                        'Days',
                        Colors.blue,
                      ),
                      _buildTimeUnit(
                        '${timeUntil.inHours % 24}',
                        'Hours',
                        Colors.green,
                      ),
                      _buildTimeUnit(
                        '${timeUntil.inMinutes % 60}',
                        'Minutes',
                        Colors.orange,
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Reminder time has passed',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Reminder details
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
                      Icons.schedule_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Reminder Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Date',
                DateFormat('EEEE, MMMM dd, yyyy').format(reminderTime),
                Icons.calendar_today_rounded,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Time',
                DateFormat('h:mm a').format(reminderTime),
                Icons.access_time_rounded,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Type',
                'One-time reminder',
                Icons.notifications_rounded,
                Colors.purple,
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
                    'Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Notifications',
                'Always enabled for reminders',
                Icons.notifications_active_rounded,
                Colors.blue,
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

  Widget _buildTimeUnit(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
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
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
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
}
