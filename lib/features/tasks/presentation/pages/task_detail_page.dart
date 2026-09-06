import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import 'task_detail_pages/traditional_task_detail.dart';
import 'task_detail_pages/reminder_task_detail.dart';
import 'task_detail_pages/birthday_task_detail.dart';

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
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            if (state is TaskLoaded) {
              try {
                final task = state.tasks.firstWhere((t) => t.id == taskId);
                return Text(
                  _getAppBarTitle(task.taskType),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                );
              } catch (e) {
                return const Text('Details');
              }
            }
            return const Text('Details');
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_rounded, size: 21),
            onPressed: () => context.push('/edit-task/$taskId'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoaded) {
            try {
              final task = state.tasks.firstWhere((t) => t.id == taskId);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                physics: const BouncingScrollPhysics(),
                child: _buildTaskTypeDetail(task),
              );
            } catch (e) {
              return _buildErrorView('Task not found');
            }
          } else if (state is TaskError) {
            return _buildErrorView('Error: ${state.message}');
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildTaskTypeDetail(Task task) {
    switch (task.taskType) {
      case TaskType.task:
        return TraditionalTaskDetail(task: task);
      case TaskType.reminder:
        return ReminderTaskDetail(task: task);
      case TaskType.birthday:
        return BirthdayTaskDetail(task: task);
    }
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle(TaskType taskType) {
    switch (taskType) {
      case TaskType.task:
        return 'Task';
      case TaskType.reminder:
        return 'Reminder';
      case TaskType.birthday:
        return 'Birthday';
    }
  }
}
