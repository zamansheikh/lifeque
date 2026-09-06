import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../../../../core/utils/local_clock.dart';

/// How the reminder for a task is expressed, in the user's terms rather than
/// the entity's. [NotificationType] plus [BeforeEndOption] is the storage
/// shape; this is the question actually being asked.
enum _RemindMode { beforeDue, atTime, daily }

/// Create or edit a task.
///
/// The router sends reminders and birthdays to their own forms, so this page
/// only ever deals with a plain task — the type branches it used to carry were
/// unreachable.
///
/// The form is ordered by how much it matters: a title, when it's due, and a
/// reminder that already has a sensible answer. Everything else is behind
/// "More options", because the old page asked all of it up front and then
/// refused to save — notifications defaulted to on with no time chosen, so a
/// title-only task failed with "Please set a notification time".
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
  DateTime _endDate = _endOfToday().add(const Duration(days: 7));

  bool _isNotificationEnabled = true;
  _RemindMode _remindMode = _RemindMode.beforeDue;
  BeforeEndOption _beforeEndOption = BeforeEndOption.oneHour;
  DateTime? _notificationTime;
  TimeOfDay? _dailyNotificationTime;

  bool _isPinnedToNotification = false;
  PinNotificationTiming _pinNotificationTiming =
      PinNotificationTiming.beforeNotification;

  bool _showMore = false;
  Task? _existingTask;

  bool get _isEditing => widget.taskId != null;

  static DateTime _endOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59);
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadExistingTask();
  }

  void _loadExistingTask() {
    final state = context.read<TaskBloc>().state;
    if (state is! TaskLoaded) return;

    final match = state.tasks.where((task) => task.id == widget.taskId);
    if (match.isEmpty) return;

    final task = match.first;
    _existingTask = task;
    _titleController.text = task.title;
    _descriptionController.text = task.description ?? '';
    _startDate = task.startDate;
    _endDate = task.endDate;
    _isNotificationEnabled = task.isNotificationEnabled;
    _notificationTime = task.notificationTime;
    _dailyNotificationTime = task.dailyNotificationTime;
    _beforeEndOption = task.beforeEndOption ?? BeforeEndOption.oneHour;
    _isPinnedToNotification = task.isPinnedToNotification;
    _pinNotificationTiming = task.pinNotificationTiming;
    _remindMode = switch (task.notificationType) {
      NotificationType.beforeEnd => _RemindMode.beforeDue,
      NotificationType.daily => _RemindMode.daily,
      NotificationType.specificTime => _RemindMode.atTime,
    };
    // A description or a pin is a reason to open the drawer on arrival —
    // otherwise an edit would appear to have lost them.
    _showMore =
        _descriptionController.text.isNotEmpty || _isPinnedToNotification;
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
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _isEditing
              ? L.of(context).taskFormEditTitle
              : L.of(context).taskFormNewTitle,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        // No Save button up here: there is one at the bottom, and two buttons
        // doing the same thing is one too many.
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TaskLoaded) {
            context.pop();
          } else if (state is TaskError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _titleField(),
              const SizedBox(height: 18),
              _whenCard(),
              const SizedBox(height: 12),
              _reminderCard(),
              const SizedBox(height: 12),
              _moreOptions(),
              const SizedBox(height: 22),
              _saveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Title ───────────────────────────────────────────────────────────────

  Widget _titleField() {
    return TextFormField(
      controller: _titleController,
      autofocus: !_isEditing,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      decoration: InputDecoration(
        hintText: L.of(context).taskFormTitleHint,
        hintStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade400,
          letterSpacing: -0.3,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: _fieldBorder(Colors.grey.shade300),
        enabledBorder: _fieldBorder(Colors.grey.shade300),
        focusedBorder: _fieldBorder(Theme.of(context).colorScheme.primary, 1.6),
        errorBorder: _fieldBorder(Colors.red.shade300),
        focusedErrorBorder: _fieldBorder(Colors.red.shade400, 1.6),
      ),
      validator: (value) => (value == null || value.trim().isEmpty)
          ? L.of(context).taskFormTitleEmpty
          : null,
    );
  }

  OutlineInputBorder _fieldBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // ── When ────────────────────────────────────────────────────────────────

  /// Deadline first, as one tap where possible.
  ///
  /// Two date-and-time pickers used to be the only way to answer "when", which
  /// is four dialogs deep for "by tonight".
  Widget _whenCard() {
    final l = L.of(context);
    return _card(
      icon: Icons.event_rounded,
      iconColor: const Color(0xFF2563EB),
      title: l.taskFormDue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _presetChip(
                l.taskFormPresetToday,
                _isPreset(_endOfToday()),
                () => _applyPreset(_endOfToday()),
              ),
              _presetChip(
                l.taskFormPresetTomorrow,
                _isPreset(_endOfToday().add(const Duration(days: 1))),
                () => _applyPreset(_endOfToday().add(const Duration(days: 1))),
              ),
              _presetChip(
                l.taskFormPresetWeek,
                _isPreset(_endOfToday().add(const Duration(days: 7))),
                () => _applyPreset(_endOfToday().add(const Duration(days: 7))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _dateRow(
            label: l.taskFormDue,
            value: _humanDateTime(_endDate),
            emphasis: true,
            onTap: _selectEndDateTime,
          ),
          Divider(height: 18, color: Colors.grey.shade200),
          _dateRow(
            label: l.taskFormStarts,
            value: _startsLabel(),
            emphasis: false,
            onTap: _selectStartDateTime,
          ),
          if (!_endDate.isAfter(_startDate)) ...[
            const SizedBox(height: 10),
            _inlineWarning(l.taskFormEndBeforeStart),
          ],
        ],
      ),
    );
  }

  /// True when the current end date matches a preset to the minute, so the
  /// chip can show as chosen.
  bool _isPreset(DateTime candidate) =>
      _endDate.difference(candidate).abs() < const Duration(minutes: 1);

  void _applyPreset(DateTime end) {
    setState(() {
      _endDate = end;
      if (!_endDate.isAfter(_startDate)) {
        _startDate = _endDate.subtract(const Duration(hours: 1));
      }
    });
  }

  String _startsLabel() {
    // Anything within a minute of now is "now" — a timestamp there is noise.
    final delta = _startDate.difference(DateTime.now()).abs();
    if (delta < const Duration(minutes: 1)) return L.of(context).commonNow;
    return _humanDateTime(_startDate);
  }

  String _humanDateTime(DateTime value) {
    final now = DateTime.now();
    final sameDay =
        value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
    final day = sameDay
        ? L.of(context).commonToday
        : DateFormat(
            value.year == now.year ? 'EEE, d MMM' : 'EEE, d MMM y',
          ).format(value);
    return '$day · ${Clock.h12(value)}';
  }

  Widget _dateRow({
    required String label,
    required String value,
    required bool emphasis,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: emphasis ? 15 : 14,
                  fontWeight: emphasis ? FontWeight.w700 : FontWeight.w600,
                  color: emphasis ? Colors.grey.shade900 : Colors.grey.shade700,
                ),
              ),
            ),
            Icon(
              Icons.edit_calendar_rounded,
              size: 17,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // ── Reminder ────────────────────────────────────────────────────────────

  Widget _reminderCard() {
    final l = L.of(context);
    return _card(
      icon: Icons.notifications_rounded,
      iconColor: const Color(0xFF7C3AED),
      title: l.taskFormRemindMe,
      trailing: Switch(
        value: _isNotificationEnabled,
        onChanged: (value) => setState(() => _isNotificationEnabled = value),
      ),
      child: !_isNotificationEnabled
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _presetChip(
                      l.taskFormModeBeforeDue,
                      _remindMode == _RemindMode.beforeDue,
                      () => setState(() => _remindMode = _RemindMode.beforeDue),
                    ),
                    _presetChip(
                      l.taskFormModeAtTime,
                      _remindMode == _RemindMode.atTime,
                      _chooseAtTimeMode,
                    ),
                    _presetChip(
                      l.taskFormModeDaily,
                      _remindMode == _RemindMode.daily,
                      _chooseDailyMode,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                switch (_remindMode) {
                  _RemindMode.beforeDue => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in BeforeEndOption.values)
                        _presetChip(
                          _beforeEndLabel(option),
                          _beforeEndOption == option,
                          () => setState(() => _beforeEndOption = option),
                          small: true,
                        ),
                    ],
                  ),
                  _RemindMode.atTime => _dateRow(
                    label: l.taskFormAt,
                    value: _notificationTime == null
                        ? l.taskFormPickTime
                        : _humanDateTime(_notificationTime!),
                    emphasis: true,
                    onTap: _selectSpecificNotificationTime,
                  ),
                  _RemindMode.daily => _dateRow(
                    label: l.taskFormAt,
                    value: _dailyNotificationTime == null
                        ? l.taskFormPickTime
                        : l.taskFormEveryDayAt(
                            _dailyNotificationTime!.format(context),
                          ),
                    emphasis: true,
                    onTap: _selectDailyNotificationTime,
                  ),
                },
              ],
            ),
    );
  }

  /// Switching to a mode that needs a time asks for it straight away, rather
  /// than letting the form reach Save with a hole in it.
  Future<void> _chooseAtTimeMode() async {
    setState(() => _remindMode = _RemindMode.atTime);
    if (_notificationTime == null) await _selectSpecificNotificationTime();
  }

  Future<void> _chooseDailyMode() async {
    setState(() => _remindMode = _RemindMode.daily);
    if (_dailyNotificationTime == null) await _selectDailyNotificationTime();
  }

  // ── More options ────────────────────────────────────────────────────────

  /// Description, pinning and pin timing. All three are worth having and none
  /// is worth asking for before a task can be created.
  Widget _moreOptions() {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _showMore = !_showMore),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      L.of(context).taskFormMoreOptions,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Icon(
                    _showMore
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          if (_showMore) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: L.of(context).taskFormNotesHint,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.all(14),
                  border: _fieldBorder(Colors.grey.shade200),
                  enabledBorder: _fieldBorder(Colors.grey.shade200),
                  focusedBorder: _fieldBorder(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                L.of(context).taskFormPinTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                L.of(context).taskFormPinSubtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              value: _isPinnedToNotification,
              onChanged: (value) =>
                  setState(() => _isPinnedToNotification = value),
            ),
            if (_isPinnedToNotification)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final timing in PinNotificationTiming.values)
                      _pinTimingRow(timing),
                  ],
                ),
              ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _pinTimingRow(PinNotificationTiming timing) {
    final selected = _pinNotificationTiming == timing;
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => setState(() => _pinNotificationTiming = timing),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 19,
              color: selected ? primary : Colors.grey.shade400,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pinTimingTitle(timing),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: selected ? primary : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _pinTimingBody(timing),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The entity's `displayName` is English-only, so the labels come from the
  /// bundle instead of the enum.
  String _beforeEndLabel(BeforeEndOption option) {
    final l = L.of(context);
    return switch (option) {
      BeforeEndOption.tenMinutes => l.beforeEnd10Minutes,
      BeforeEndOption.thirtyMinutes => l.beforeEnd30Minutes,
      BeforeEndOption.oneHour => l.beforeEnd1Hour,
      BeforeEndOption.twoHours => l.beforeEnd2Hours,
      BeforeEndOption.oneDay => l.beforeEnd1Day,
    };
  }

  String _pinTimingTitle(PinNotificationTiming timing) => switch (timing) {
    PinNotificationTiming.beforeNotification => L.of(context).pinBeforeTitle,
    PinNotificationTiming.afterNotification => L.of(context).pinAfterTitle,
  };

  String _pinTimingBody(PinNotificationTiming timing) => switch (timing) {
    PinNotificationTiming.beforeNotification => L.of(context).pinBeforeBody,
    PinNotificationTiming.afterNotification => L.of(context).pinAfterBody,
  };

  // ── Shared pieces ───────────────────────────────────────────────────────

  Widget _card({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: EdgeInsets.fromLTRB(16, 14, 16, child == null ? 8 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          if (child != null) ...[const SizedBox(height: 14), child],
        ],
      ),
    );
  }

  Widget _presetChip(
    String label,
    bool selected,
    VoidCallback onTap, {
    bool small = false,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: selected ? primary : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: small ? 11 : 13,
            vertical: small ? 7 : 9,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: small ? 12.5 : 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inlineWarning(String message) {
    return Row(
      children: [
        Icon(Icons.error_outline_rounded, size: 15, color: Colors.red.shade400),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _saveTask,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          _isEditing
              ? L.of(context).taskFormSaveChanges
              : L.of(context).taskFormCreate,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Pickers ─────────────────────────────────────────────────────────────

  Future<void> _selectStartDateTime() async {
    final picked = await _pickDateTime(
      initial: _startDate,
      first: DateTime.now().subtract(const Duration(days: 365)),
      last: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      if (!_endDate.isAfter(_startDate)) {
        _endDate = _startDate.add(const Duration(hours: 1));
      }
    });
  }

  Future<void> _selectEndDateTime() async {
    final picked = await _pickDateTime(
      initial: _endDate,
      first: DateTime.now().subtract(const Duration(days: 365)),
      last: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(() => _endDate = picked);
  }

  Future<void> _selectSpecificNotificationTime() async {
    final picked = await _pickDateTime(
      initial: _notificationTime ?? _endDate.subtract(const Duration(hours: 1)),
      first: DateTime.now().subtract(const Duration(days: 1)),
      last: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(() => _notificationTime = picked);
  }

  Future<void> _selectDailyNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dailyNotificationTime ?? TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() => _dailyNotificationTime = picked);
  }

  /// Date then time, with the second dialog seeded from the first so a
  /// dismissed picker leaves the old value alone rather than half-applying.
  Future<DateTime?> _pickDateTime({
    required DateTime initial,
    required DateTime first,
    required DateTime last,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: last,
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  // ── Save ────────────────────────────────────────────────────────────────

  void _saveTask() {
    if (!_formKey.currentState!.validate()) return;

    if (!_endDate.isAfter(_startDate)) {
      _complain(L.of(context).taskFormEndBeforeStart);
      return;
    }

    // Every reminder mode has a default or was filled in when it was picked,
    // so these are backstops rather than the usual path.
    if (_isNotificationEnabled) {
      if (_remindMode == _RemindMode.atTime && _notificationTime == null) {
        _complain(L.of(context).taskFormNeedReminderTime);
        return;
      }
      if (_remindMode == _RemindMode.daily && _dailyNotificationTime == null) {
        _complain(L.of(context).taskFormNeedDailyTime);
        return;
      }
    }

    final now = DateTime.now();
    final notificationType = switch (_remindMode) {
      _RemindMode.beforeDue => NotificationType.beforeEnd,
      _RemindMode.atTime => NotificationType.specificTime,
      _RemindMode.daily => NotificationType.daily,
    };

    final task = Task(
      id: _isEditing ? _existingTask!.id : const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      isCompleted: _isEditing ? _existingTask!.isCompleted : false,
      isNotificationEnabled: _isNotificationEnabled,
      notificationType: notificationType,
      // Only the field this mode actually uses is carried over; the old form
      // left the others populated, so a mode switch could still fire the
      // reminder that had been replaced.
      notificationTime: _remindMode == _RemindMode.atTime
          ? _notificationTime
          : null,
      dailyNotificationTime: _remindMode == _RemindMode.daily
          ? _dailyNotificationTime
          : null,
      beforeEndOption: _remindMode == _RemindMode.beforeDue
          ? _beforeEndOption
          : null,
      isPinnedToNotification: _isPinnedToNotification,
      pinNotificationTiming: _pinNotificationTiming,
      createdAt: _isEditing ? _existingTask!.createdAt : now,
      updatedAt: _isEditing ? now : null,
    );

    if (_isEditing) {
      context.read<TaskBloc>().add(UpdateTaskEvent(task));
    } else {
      context.read<TaskBloc>().add(AddTaskEvent(task));
    }
  }

  void _complain(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
