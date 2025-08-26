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
  NotificationType _notificationType = NotificationType.specificTime;
  DateTime? _notificationTime;
  TimeOfDay? _dailyNotificationTime;
  BeforeEndOption? _beforeEndOption;
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
      _notificationType = _existingTask!.notificationType;
      _notificationTime = _existingTask!.notificationTime;
      _dailyNotificationTime = _existingTask!.dailyNotificationTime;
      _beforeEndOption = _existingTask!.beforeEndOption;
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

                // Start date and time picker
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Start Date & Time'),
                    subtitle: Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year} ${_startDate.hour.toString().padLeft(2, '0')}:${_startDate.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _selectStartDateTime(context),
                  ),
                ),
                const SizedBox(height: 8),

                // End date and time picker
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('End Date & Time'),
                    subtitle: Text(
                      '${_endDate.day}/${_endDate.month}/${_endDate.year} ${_endDate.hour.toString().padLeft(2, '0')}:${_endDate.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _selectEndDateTime(context),
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

                // Notification settings (shown only if notifications are enabled)
                if (_isNotificationEnabled) ...[
                  // Notification type selector
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.schedule),
                              const SizedBox(width: 8),
                              Text(
                                'Notification Type',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<NotificationType>(
                            initialValue: _notificationType,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: NotificationType.specificTime,
                                child: Text('At a specific time'),
                              ),
                              DropdownMenuItem(
                                value: NotificationType.daily,
                                child: Text('Daily reminder'),
                              ),
                              DropdownMenuItem(
                                value: NotificationType.beforeEnd,
                                child: Text('Before end time'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _notificationType = value!;
                                // Reset other notification settings when type changes
                                _notificationTime = null;
                                _dailyNotificationTime = null;
                                _beforeEndOption = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Specific time notification picker
                  if (_notificationType == NotificationType.specificTime) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Notification Time'),
                        subtitle: Text(
                          _notificationTime != null
                              ? '${_notificationTime!.day}/${_notificationTime!.month}/${_notificationTime!.year} ${_notificationTime!.hour.toString().padLeft(2, '0')}:${_notificationTime!.minute.toString().padLeft(2, '0')}'
                              : 'Tap to set notification time',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _selectSpecificNotificationTime(context),
                      ),
                    ),
                  ],

                  // Daily notification time picker
                  if (_notificationType == NotificationType.daily) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.repeat),
                        title: const Text('Daily Notification Time'),
                        subtitle: Text(
                          _dailyNotificationTime != null
                              ? '${_dailyNotificationTime!.hour.toString().padLeft(2, '0')}:${_dailyNotificationTime!.minute.toString().padLeft(2, '0')} every day'
                              : 'Tap to set daily reminder time',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _selectDailyNotificationTime(context),
                      ),
                    ),
                  ],

                  // Before end option selector
                  if (_notificationType == NotificationType.beforeEnd) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.timer),
                                const SizedBox(width: 8),
                                Text(
                                  'Notify Before End',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<BeforeEndOption>(
                              initialValue: _beforeEndOption,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              hint: const Text('Select how long before'),
                              items: BeforeEndOption.values.map((option) {
                                return DropdownMenuItem(
                                  value: option,
                                  child: Text(option.displayName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _beforeEndOption = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

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

  Future<void> _selectStartDateTime(BuildContext context) async {
    // First pick the date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      // Then pick the time
      if (context.mounted) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_startDate),
        );

        if (pickedTime != null) {
          setState(() {
            _startDate = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            // Ensure end date is after start date
            if (_endDate.isBefore(_startDate)) {
              _endDate = _startDate.add(const Duration(hours: 1));
            }
          });
        }
      }
    }
  }

  Future<void> _selectEndDateTime(BuildContext context) async {
    // First pick the date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      // Then pick the time
      if (context.mounted) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_endDate),
        );

        if (pickedTime != null) {
          setState(() {
            _endDate = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
          });
        }
      }
    }
  }

  Future<void> _selectSpecificNotificationTime(BuildContext context) async {
    // First pick the date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _notificationTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: _endDate,
    );

    if (pickedDate != null) {
      // Then pick the time
      if (context.mounted) {
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: _notificationTime != null
              ? TimeOfDay.fromDateTime(_notificationTime!)
              : TimeOfDay.now(),
        );

        if (pickedTime != null) {
          setState(() {
            _notificationTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
          });
        }
      }
    }
  }

  Future<void> _selectDailyNotificationTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dailyNotificationTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _dailyNotificationTime = picked;
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      // Validate notification settings based on type
      if (_isNotificationEnabled) {
        switch (_notificationType) {
          case NotificationType.specificTime:
            if (_notificationTime == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please set a notification time')),
              );
              return;
            }
            break;
          case NotificationType.daily:
            if (_dailyNotificationTime == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please set a daily notification time'),
                ),
              );
              return;
            }
            break;
          case NotificationType.beforeEnd:
            if (_beforeEndOption == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select when to notify before end'),
                ),
              );
              return;
            }
            break;
        }
      }

      final now = DateTime.now();

      final task = Task(
        id: _isEditing ? _existingTask!.id : const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        isCompleted: _isEditing ? _existingTask!.isCompleted : false,
        isNotificationEnabled: _isNotificationEnabled,
        notificationType: _notificationType,
        notificationTime: _notificationTime,
        dailyNotificationTime: _dailyNotificationTime,
        beforeEndOption: _beforeEndOption,
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
