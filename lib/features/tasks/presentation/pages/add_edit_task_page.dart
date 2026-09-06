import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';

/// Create or edit a task.
///
/// Reminders and birthdays are not offered here — each has its own page and
/// its own form, asking only what that kind of thing actually needs. Leaving
/// a type picker on this screen would have meant three routes to the same
/// three things, with different questions on each.
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
  PinNotificationTiming _pinNotificationTiming =
      PinNotificationTiming.beforeNotification;
  List<BirthdayNotificationOption> _birthdayNotificationSchedule = [
    BirthdayNotificationOption.oneDayBefore,
    BirthdayNotificationOption.exactTime,
  ]; // Default to 1 day before and exact time

  Task? _existingTask;

  /// What the thing being created is called, so the app bar, the title field
  /// and the save button stop saying "Task" while the Birthday type is picked.
  String get _typeNoun => switch (_taskType) {
    TaskType.birthday => 'Birthday',
    TaskType.reminder => 'Reminder',
    TaskType.task => 'Task',
  };
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
      _descriptionController.text = _existingTask!.description ?? '';
      _taskType = _existingTask!.taskType;
      _startDate = _existingTask!.startDate;
      _endDate = _existingTask!.endDate;
      _isNotificationEnabled = _existingTask!.isNotificationEnabled;
      _notificationType = _existingTask!.notificationType;
      _notificationTime = _existingTask!.notificationTime;
      _dailyNotificationTime = _existingTask!.dailyNotificationTime;
      _beforeEndOption = _existingTask!.beforeEndOption;
      _isPinnedToNotification = _existingTask!.isPinnedToNotification;
      _pinNotificationTiming = _existingTask!.pinNotificationTiming;
      _birthdayNotificationSchedule =
          _existingTask!.birthdayNotificationSchedule;
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
          _isEditing ? 'Edit $_typeNoun' : 'New $_typeNoun',
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
                    labelText: _taskType == TaskType.birthday
                        ? 'Whose birthday?'
                        : '$_typeNoun title',
                    hintText: _taskType == TaskType.birthday
                        ? 'Their name'
                        : 'What needs to be done?',
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
                    labelText: 'Description (Optional)',
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
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Date and Time Section - More compact layout
                if (_taskType == TaskType.task) ...[
                  // Combined Start and End date/time in one container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.schedule_rounded,
                                color: Colors.green,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Task Duration',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Start Date/Time
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectStartDateTime(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.play_circle_outline_rounded,
                                            color: Colors.green,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Start',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      Text(
                                        _formatTimeWithAMPM(_startDate),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            // End Date/Time
                            Expanded(
                              child: InkWell(
                                onTap: () => _selectEndDateTime(context),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.flag_rounded,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'End',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      Text(
                                        _formatTimeWithAMPM(_endDate),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else if (_taskType == TaskType.reminder) ...[
                  // Compact reminder time picker
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          color: Colors.orange,
                          size: 18,
                        ),
                      ),
                      title: const Text(
                        'Reminder Time',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _notificationTime != null
                            ? '${_notificationTime!.day}/${_notificationTime!.month}/${_notificationTime!.year} - ${_formatTimeWithAMPM(_notificationTime!)}'
                            : 'Tap to set reminder time',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                      ),
                      onTap: () => _selectSpecificNotificationTime(context),
                    ),
                  ),
                ] else if (_taskType == TaskType.birthday) ...[
                  // Compact birthday date picker
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.pink.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.cake_rounded,
                          color: Colors.pink,
                          size: 18,
                        ),
                      ),
                      title: const Text(
                        'Birthday Date',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                      ),
                      onTap: () => _selectBirthdayDate(context),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Notification settings - More compact
                if (_taskType == TaskType.task) ...[
                  // Notification toggle and settings combined
                  Material(
                    color: Colors.white,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        // Notification toggle
                        SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          title: const Text(
                            'Enable Notifications',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            'Get reminded about this task',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          value: _isNotificationEnabled,
                          onChanged: (value) {
                            setState(() {
                              _isNotificationEnabled = value;
                            });
                          },
                          secondary: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.notifications_rounded,
                              color: Colors.blue,
                              size: 18,
                            ),
                          ),
                        ),
                        // Notification type and settings (when enabled)
                        if (_isNotificationEnabled) ...[
                          Divider(height: 1, color: Colors.grey.shade200),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Notification type dropdown - more compact
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      color: Colors.grey.shade600,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Type:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child:
                                          DropdownButtonFormField<
                                            NotificationType
                                          >(
                                            isDense: true,
                                            initialValue: _notificationType,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: NotificationType
                                                    .specificTime,
                                                child: Text(
                                                  'At a specific time',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value: NotificationType.daily,
                                                child: Text(
                                                  'Daily reminder',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value:
                                                    NotificationType.beforeEnd,
                                                child: Text(
                                                  'Before end time',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
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
                                    ),
                                  ],
                                ),
                                // Specific settings based on type
                                if (_notificationType ==
                                    NotificationType.specificTime) ...[
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: () =>
                                        _selectSpecificNotificationTime(
                                          context,
                                        ),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color: Colors.grey.shade600,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _notificationTime != null
                                                  ? _formatTimeWithAMPM(
                                                      _notificationTime!,
                                                    )
                                                  : 'Tap to set time',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: _notificationTime != null
                                                    ? Colors.black87
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (_notificationType ==
                                    NotificationType.daily) ...[
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: () =>
                                        _selectDailyNotificationTime(context),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.repeat,
                                            color: Colors.grey.shade600,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _dailyNotificationTime != null
                                                  ? _formatTimeOfDayWithAMPM(
                                                      _dailyNotificationTime!,
                                                    )
                                                  : 'Tap to set daily time',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    _dailyNotificationTime !=
                                                        null
                                                    ? Colors.black87
                                                    : Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                                if (_notificationType ==
                                    NotificationType.beforeEnd) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer,
                                        color: Colors.grey.shade600,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Before:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child:
                                            DropdownButtonFormField<
                                              BeforeEndOption
                                            >(
                                              isDense: true,
                                              initialValue: _beforeEndOption,
                                              decoration: InputDecoration(
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                              ),
                                              hint: const Text(
                                                'Select',
                                                style: TextStyle(fontSize: 13),
                                              ),
                                              items: BeforeEndOption.values.map(
                                                (option) {
                                                  return DropdownMenuItem(
                                                    value: option,
                                                    child: Text(
                                                      option.displayName,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ).toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  _beforeEndOption = value;
                                                });
                                              },
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else if (_taskType == TaskType.reminder) ...[
                  // For reminders, show notification is always enabled - more compact
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.orange,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notification Enabled',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Reminders always notify at the set time',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ] else if (_taskType == TaskType.birthday) ...[
                  // Birthday notification schedule options
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.pink.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.pink.withValues(alpha: 0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.pink.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.cake_rounded,
                                color: Colors.pink,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Birthday Notification Schedule',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Choose when to be reminded about this birthday:',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Birthday notification options
                        ...BirthdayNotificationOption.values.map((option) {
                          final isSelected = _birthdayNotificationSchedule
                              .contains(option);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: CheckboxListTile(
                              tileColor: isSelected
                                  ? Colors.pink.withValues(alpha: 0.1)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.pink
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              dense: true,
                              title: Text(
                                option.displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.pink.shade700
                                      : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                option.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected
                                      ? Colors.pink.shade600
                                      : Colors.grey.shade600,
                                ),
                              ),
                              value: isSelected,
                              activeColor: Colors.pink,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    if (!_birthdayNotificationSchedule.contains(
                                      option,
                                    )) {
                                      _birthdayNotificationSchedule.add(option);
                                    }
                                  } else {
                                    _birthdayNotificationSchedule.remove(
                                      option,
                                    );
                                  }
                                });
                              },
                            ),
                          );
                        }),
                        if (_birthdayNotificationSchedule.isEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  color: Colors.orange.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Select at least one notification option',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Pin to notification toggle - more compact and consistent for all types
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SwitchListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      _taskType == TaskType.reminder
                          ? 'Pin Reminder'
                          : 'Pin to Notification',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      _taskType == TaskType.reminder
                          ? 'Keep visible in notifications'
                          : 'Keep task visible in notifications',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    value: _isPinnedToNotification,
                    onChanged: (value) {
                      setState(() {
                        _isPinnedToNotification = value;
                      });
                    },
                    secondary: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            (_taskType == TaskType.reminder
                                    ? Colors.orange
                                    : Colors.blue)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.push_pin_rounded,
                        color: _taskType == TaskType.reminder
                            ? Colors.orange
                            : Colors.blue,
                        size: 18,
                      ),
                    ),
                  ),
                ),

                // Pin timing selection - only shown when pin is enabled
                if (_isPinnedToNotification) ...[
                  const SizedBox(height: 12),
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
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.schedule_rounded,
                                color: Colors.purple,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Pin Timing',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...PinNotificationTiming.values.map((timing) {
                          final isSelected = _pinNotificationTiming == timing;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _pinNotificationTiming = timing;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.purple.withValues(alpha: 0.1)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.purple
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: isSelected
                                          ? Colors.purple
                                          : Colors.grey.shade400,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            timing.displayName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: isSelected
                                                  ? Colors.purple
                                                  : Colors.grey.shade800,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            timing.description,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

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
                      _isEditing ? 'Update $_typeNoun' : 'Create $_typeNoun',
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

  String _formatTimeWithAMPM(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String _formatTimeOfDayWithAMPM(TimeOfDay timeOfDay) {
    final period = timeOfDay.hour >= 12 ? 'PM' : 'AM';
    final displayHour = timeOfDay.hour == 0
        ? 12
        : (timeOfDay.hour > 12 ? timeOfDay.hour - 12 : timeOfDay.hour);

    return '${displayHour.toString().padLeft(2, '0')}:${timeOfDay.minute.toString().padLeft(2, '0')} $period every day';
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
      } else if (_taskType == TaskType.birthday) {
        // Validate birthday notification schedule
        if (_birthdayNotificationSchedule.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please select at least one birthday notification option',
              ),
            ),
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
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
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
        pinNotificationTiming: _pinNotificationTiming,
        birthdayNotificationSchedule: _taskType == TaskType.birthday
            ? _birthdayNotificationSchedule
            : [],
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
