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
  TaskType _taskType = TaskType.task;
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
      _taskType = _existingTask!.taskType;
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
        title: Text(
          _isEditing ? 'Edit Task' : 'Create Task',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'What needs to be done?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.title_rounded),
                    contentPadding: const EdgeInsets.all(16),
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
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add more details about this task...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.description_rounded),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Task Type Selector
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.category_rounded,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Task Type',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Three task type options
                      Column(
                        children: [
                          // First row - Task and Reminder
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _taskType = TaskType.task),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _taskType == TaskType.task
                                          ? Colors.blue.withValues(alpha: 0.1)
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _taskType == TaskType.task
                                            ? Colors.blue
                                            : Colors.grey.shade300,
                                        width: _taskType == TaskType.task
                                            ? 2
                                            : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.assignment_rounded,
                                          color: _taskType == TaskType.task
                                              ? Colors.blue
                                              : Colors.grey.shade600,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Task',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: _taskType == TaskType.task
                                                ? Colors.blue
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Duration-based with start & end',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(
                                    () => _taskType = TaskType.reminder,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _taskType == TaskType.reminder
                                          ? Colors.orange.withValues(alpha: 0.1)
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _taskType == TaskType.reminder
                                            ? Colors.orange
                                            : Colors.grey.shade300,
                                        width: _taskType == TaskType.reminder
                                            ? 2
                                            : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.notifications_active_rounded,
                                          color: _taskType == TaskType.reminder
                                              ? Colors.orange
                                              : Colors.grey.shade600,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Reminder',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _taskType == TaskType.reminder
                                                ? Colors.orange
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Simple notification at specific time',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Second row - Birthday Reminder (full width)
                          InkWell(
                            onTap: () =>
                                setState(() => _taskType = TaskType.birthday),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _taskType == TaskType.birthday
                                    ? Colors.pink.withValues(alpha: 0.1)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _taskType == TaskType.birthday
                                      ? Colors.pink
                                      : Colors.grey.shade300,
                                  width: _taskType == TaskType.birthday ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cake_rounded,
                                    color: _taskType == TaskType.birthday
                                        ? Colors.pink
                                        : Colors.grey.shade600,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Birthday Reminder',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color:
                                                _taskType == TaskType.birthday
                                                ? Colors.pink
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Yearly reminder for birthdays and anniversaries',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_taskType == TaskType.birthday) ...[
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.pink.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.pink,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Date and Time Section - conditional based on task type
                if (_taskType == TaskType.task) ...[
                  // Start date and time picker
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.play_circle_outline_rounded,
                          color: Colors.green,
                        ),
                      ),
                      title: const Text(
                        'Start Date & Time',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year} ${_startDate.hour.toString().padLeft(2, '0')}:${_startDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                      onTap: () => _selectStartDateTime(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // End date and time picker
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.red,
                        ),
                      ),
                      title: const Text(
                        'End Date & Time',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${_endDate.day}/${_endDate.month}/${_endDate.year} ${_endDate.hour.toString().padLeft(2, '0')}:${_endDate.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                      onTap: () => _selectEndDateTime(context),
                    ),
                  ),
                ] else if (_taskType == TaskType.reminder) ...[
                  // Reminder time picker
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: Colors.orange,
                        ),
                      ),
                      title: const Text(
                        'Reminder Time',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        _notificationTime != null
                            ? '${_notificationTime!.day}/${_notificationTime!.month}/${_notificationTime!.year} ${_notificationTime!.hour.toString().padLeft(2, '0')}:${_notificationTime!.minute.toString().padLeft(2, '0')}'
                            : 'Tap to set reminder time',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                      onTap: () => _selectSpecificNotificationTime(context),
                    ),
                  ),
                ] else if (_taskType == TaskType.birthday) ...[
                  // Birthday date picker
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.pink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.cake_rounded,
                          color: Colors.pink,
                        ),
                      ),
                      title: const Text(
                        'Birthday Date',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                      onTap: () => _selectBirthdayDate(context),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Notification settings - conditional based on task type
                if (_taskType == TaskType.task) ...[
                  // Notification toggle for tasks
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SwitchListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: const Text(
                        'Enable Notifications',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        'Get reminded about this task',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      value: _isNotificationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isNotificationEnabled = value;
                        });
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.notifications_rounded,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else if (_taskType == TaskType.reminder) ...[
                  // For reminders, show notification is always enabled
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notification Enabled',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reminders always notify at the set time',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else if (_taskType == TaskType.birthday) ...[
                  // For birthday reminders, show notification is always enabled
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.pink.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.pink.withValues(alpha: 0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.pink.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.cake_rounded,
                            color: Colors.pink,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Annual Reminder',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Birthday reminders notify every year automatically',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.repeat_rounded, color: Colors.pink),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Notification settings (shown only for tasks with notifications enabled)
                if (_taskType == TaskType.task && _isNotificationEnabled) ...[
                  const SizedBox(height: 16),

                  // Notification type selector
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.schedule_rounded,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Notification Type',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<NotificationType>(
                            initialValue: _notificationType,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Colors.blue,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
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
                ],

                const SizedBox(height: 16),

                // Pin to notification toggle - available for all task types
                Container(
                  decoration: BoxDecoration(
                    color: _taskType == TaskType.reminder
                        ? Colors.orange.withValues(alpha: 0.05)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _taskType == TaskType.reminder
                          ? Colors.orange.withValues(alpha: 0.2)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: SwitchListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      _taskType == TaskType.reminder
                          ? 'Pin Reminder'
                          : 'Pin to Notification',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _taskType == TaskType.reminder
                          ? 'Keep reminder visible in notifications for easy access'
                          : 'Keep task visible in notifications',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    value: _isPinnedToNotification,
                    onChanged: (value) {
                      setState(() {
                        _isPinnedToNotification = value;
                      });
                    },
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            (_taskType == TaskType.reminder
                                    ? Colors.orange
                                    : Colors.blue)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.push_pin_rounded,
                        color: _taskType == TaskType.reminder
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                  ),
                ),

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
                      _isEditing
                          ? (_taskType == TaskType.reminder
                                ? 'Update Reminder'
                                : 'Update Task')
                          : (_taskType == TaskType.reminder
                                ? 'Create Reminder'
                                : 'Create Task'),
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
    final DateTime now = DateTime.now();
    final DateTime maxDate = _endDate.isAfter(now)
        ? _endDate
        : now.add(const Duration(days: 365)); // Default to 1 year from now

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          (_notificationTime != null && _notificationTime!.isAfter(now))
          ? _notificationTime!
          : now,
      firstDate: now,
      lastDate: maxDate,
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

  Future<void> _selectBirthdayDate(BuildContext context) async {
    // For birthdays, we only need to pick the date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Birthday Date',
    );

    if (pickedDate != null) {
      setState(() {
        _startDate = pickedDate;
        _endDate = pickedDate; // For birthdays, start and end are the same
        // Set notification time to the birthday at 9 AM by default
        _notificationTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          9,
          0,
        );
      });
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
      // Special validation for reminders
      if (_taskType == TaskType.reminder) {
        if (_notificationTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please set a reminder time')),
          );
          return;
        }
      } else {
        // Validate notification settings for tasks based on type
        if (_isNotificationEnabled) {
          switch (_notificationType) {
            case NotificationType.specificTime:
              if (_notificationTime == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please set a notification time'),
                  ),
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
      }

      final now = DateTime.now();

      // For reminders and birthdays, use notification time as both start and end date
      DateTime startDate, endDate;
      bool isNotificationEnabled;
      NotificationType notificationType;

      if (_taskType == TaskType.reminder) {
        startDate = _notificationTime!;
        endDate = _notificationTime!;
        isNotificationEnabled = true;
        notificationType = NotificationType.specificTime;
      } else if (_taskType == TaskType.birthday) {
        startDate = _startDate;
        endDate = _startDate;
        isNotificationEnabled = true;
        notificationType = NotificationType.specificTime;
      } else {
        startDate = _startDate;
        endDate = _endDate;
        isNotificationEnabled = _isNotificationEnabled;
        notificationType = _notificationType;
      }

      final task = Task(
        id: _isEditing ? _existingTask!.id : const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        taskType: _taskType,
        startDate: startDate,
        endDate: endDate,
        isCompleted: _isEditing ? _existingTask!.isCompleted : false,
        isNotificationEnabled: isNotificationEnabled,
        notificationType: notificationType,
        notificationTime: _notificationTime,
        dailyNotificationTime: _taskType == TaskType.task
            ? _dailyNotificationTime
            : null,
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
