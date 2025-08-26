import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../widgets/progress_indicator_widget.dart';

class TaskDetailPage extends StatelessWidget {
  final String taskId;

  const TaskDetailPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
        ),
        title: const Text(
          'Task Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 20,
                color: Colors.blue,
              ),
            ),
            onPressed: () {
              context.push('/edit-task/$taskId');
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoaded) {
            final task = state.tasks.firstWhere(
              (t) => t.id == taskId,
              orElse: () => throw Exception('Task not found'),
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and completion status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted ? Colors.grey : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          context.read<TaskBloc>().add(
                            ToggleTaskCompletion(task.id),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: task.isCompleted
                                  ? Colors.green
                                  : Colors.grey,
                              width: 2,
                            ),
                            color: task.isCompleted
                                ? Colors.green
                                : Colors.transparent,
                          ),
                          child: task.isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 20,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getStatusText(task),
                      style: TextStyle(
                        color: _getStatusColor(task),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  _buildSection(
                    title: 'Description',
                    child: Text(
                      task.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date information
                  _buildSection(
                    title: 'Timeline',
                    child: Column(
                      children: [
                        _buildDateRow(
                          icon: Icons.play_arrow,
                          label: 'Start Date',
                          date: task.startDate,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        _buildDateRow(
                          icon: Icons.flag,
                          label: 'End Date',
                          date: task.endDate,
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progress information
                  if (!task.isCompleted) ...[
                    _buildSection(
                      title: 'Progress',
                      child: Column(
                        children: [
                          ProgressIndicatorWidget(
                            progress: task.progressPercentage,
                            label: 'Task Progress',
                            color: task.isOverdue ? Colors.red : Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoCard(
                                'Days Left',
                                '${task.daysLeft}',
                                Icons.calendar_today,
                                task.isOverdue ? Colors.red : Colors.blue,
                              ),
                              _buildInfoCard(
                                'Total Days',
                                '${task.endDate.difference(task.startDate).inDays}',
                                Icons.schedule,
                                Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Notification settings
                  _buildSection(
                    title: 'Settings',
                    child: ListTile(
                      leading: Icon(
                        task.isNotificationEnabled
                            ? Icons.notifications
                            : Icons.notifications_off,
                        color: task.isNotificationEnabled
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      title: const Text('Notifications'),
                      subtitle: Text(
                        task.isNotificationEnabled ? 'Enabled' : 'Disabled',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Metadata
                  _buildSection(
                    title: 'Details',
                    child: Column(
                      children: [
                        _buildMetadataRow(
                          'Created',
                          DateFormat.yMd().add_jm().format(task.createdAt),
                        ),
                        if (task.updatedAt != null) ...[
                          const SizedBox(height: 8),
                          _buildMetadataRow(
                            'Last Updated',
                            DateFormat.yMd().add_jm().format(task.updatedAt!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else if (state is TaskError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDateRow({
    required IconData icon,
    required String label,
    required DateTime date,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(DateFormat.yMd().format(date), style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildInfoCard(
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
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Color _getStatusColor(Task task) {
    if (task.isCompleted) return Colors.green;
    if (task.isOverdue) return Colors.red;
    if (task.isActive) return Colors.orange;
    return Colors.grey;
  }

  String _getStatusText(Task task) {
    if (task.isCompleted) return 'Completed';
    if (task.isOverdue) return 'Overdue';
    if (task.isActive) return 'Active';
    return 'Upcoming';
  }
}
