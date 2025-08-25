import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';

class AddEditTaskPage extends StatefulWidget {
  final String? taskId;

  const AddEditTaskPage({super.key, this.taskId});

  @override
  State<AddEditTaskPage> createState() => _AddEditTaskPageState();
}

class _AddEditTaskPageState extends State<AddEditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isNotificationEnabled = true;
  DateTime? _notificationTime;
  bool _isPinnedToNotification = false;

  Task? _existingTask;
  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExistingTask();
    }
  }

  void _loadExistingTask() {
    final state = context.read<TaskBloc>().state;
    if (state is TaskLoaded) {
      _existingTask = state.tasks.firstWhere(
        (task) => task.id == widget.taskId,
        orElse: () => throw Exception('Task not found'),
      );

      _titleController.text = _existingTask!.title;
      _descriptionController.text = _existingTask!.description;
      _startDate = _existingTask!.startDate;
      _endDate = _existingTask!.endDate;
      _isNotificationEnabled = _existingTask!.isNotificationEnabled;
      _notificationTime = _existingTask!.notificationTime;
      _isPinnedToNotification = _existingTask!.isPinnedToNotification;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Add Task'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: Text(
              'Save',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskLoaded) {
            // Task was saved successfully, go back
            context.pop();
          } else if (state is TaskError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Start date picker
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Start Date'),
                    subtitle: Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _selectStartDate(context),
                  ),
                ),
                const SizedBox(height: 8),

                // End date picker
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('End Date'),
                    subtitle: Text(
                      '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _selectEndDate(context),
                  ),
                ),
                const SizedBox(height: 16),

                // Notification toggle
                Card(
                  child: SwitchListTile(
                    title: const Text('Enable Notifications'),
                    subtitle: const Text('Get reminded about this task'),
                    value: _isNotificationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isNotificationEnabled = value;
                      });
                    },
                    secondary: const Icon(Icons.notifications),
                  ),
                ),
                const SizedBox(height: 8),

                // Notification time picker (shown only if notifications are enabled)
                if (_isNotificationEnabled) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Notification Time'),
                      subtitle: Text(
                        _notificationTime != null
                            ? '${_notificationTime!.hour.toString().padLeft(2, '0')}:${_notificationTime!.minute.toString().padLeft(2, '0')}'
                            : 'Tap to set notification time',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _selectNotificationTime(context),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Pin to notification toggle
                  Card(
                    child: SwitchListTile(
                      title: const Text('Pin to Notification'),
                      subtitle: const Text(
                        'Keep task visible in notifications',
                      ),
                      value: _isPinnedToNotification,
                      onChanged: (value) {
                        setState(() {
                          _isPinnedToNotification = value;
                        });
                      },
                      secondary: const Icon(Icons.push_pin),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _isEditing ? 'Update Task' : 'Create Task',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        // Ensure end date is after start date
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectNotificationTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime != null
          ? TimeOfDay.fromDateTime(_notificationTime!)
          : TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        // Create a DateTime with today's date and the selected time
        final now = DateTime.now();
        _notificationTime = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();

      final task = Task(
        id: _isEditing ? _existingTask!.id : const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        isCompleted: _isEditing ? _existingTask!.isCompleted : false,
        isNotificationEnabled: _isNotificationEnabled,
        notificationTime: _notificationTime,
        isPinnedToNotification: _isPinnedToNotification,
        createdAt: _isEditing ? _existingTask!.createdAt : now,
        updatedAt: _isEditing ? now : null,
      );

      if (_isEditing) {
        context.read<TaskBloc>().add(UpdateTaskEvent(task));
      } else {
        context.read<TaskBloc>().add(AddTaskEvent(task));
      }
    }
  }
}
