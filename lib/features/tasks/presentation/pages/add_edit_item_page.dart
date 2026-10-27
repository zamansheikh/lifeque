import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/local_clock.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../utils/task_priority_ui.dart';

/// Add or edit anything on the task list — what used to be three separate
/// things (a task, a reminder, a to-do), each with its own form and page.
///
/// Only the title is required. A due date, a reminder, a priority and a
/// category are each one tap away and all optional, so the same form serves
/// "milk" and "pay rent by Friday, remind me Thursday". Work that runs over
/// several days, with a start, an end and a progress bar, opens the full task
/// form instead — the link at the bottom carries over what was typed.
class AddEditItemPage extends StatefulWidget {
  final String? taskId;

  /// Opens with the reminder switched on — the old "new reminder" entry
  /// points still land here.
  final bool startWithReminder;

  const AddEditItemPage({
    super.key,
    this.taskId,
    this.startWithReminder = false,
  });

  bool get isEditing => taskId != null;

  @override
  State<AddEditItemPage> createState() => _AddEditItemPageState();
}

class _AddEditItemPageState extends State<AddEditItemPage> {
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _brand = Color(0xFF2563EB);
  static const _field = Color(0xFFF8FAFC);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  TaskCategory? _category;
  TaskPriority _priority = TaskPriority.normal;
  DateTime? _dueDate;
  DateTime? _reminderAt;
  bool _pinned = false;
  RepeatRule _repeat = RepeatRule.none;
  bool _showNote = false;
  Task? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _load();
    } else if (widget.startWithReminder) {
      _reminderAt = _inAnHour();
    }
  }

  void _load() {
    final state = context.read<TaskBloc>().state;
    if (state is! TaskLoaded) return;
    final match = state.tasks.where((t) => t.id == widget.taskId);
    if (match.isEmpty) return;

    final task = match.first;
    _existing = task;
    _titleController.text = task.title;
    _noteController.text = task.description ?? '';
    _showNote = _noteController.text.isNotEmpty;
    _category = task.category;
    _priority = task.priority;
    _dueDate = task.dueDate;
    _reminderAt = task.reminderAt;
    _pinned = task.isPinnedToNotification;
    _repeat = task.repeat;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────────

  bool get _reminderIsUsable =>
      _reminderAt != null && _reminderAt!.isAfter(DateTime.now());

  bool get _hasWhen => _dueDate != null || _reminderAt != null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final existing = _existing;
    final note = _noteController.text.trim();
    // A reminder in the past would never ring, so it is dropped rather than
    // saved as a promise the app can't keep. An existing past reminder is
    // kept as it was, so merely opening and saving doesn't erase it.
    final reminder = _reminderIsUsable
        ? _reminderAt
        : (existing?.reminderAt != null && _reminderAt == existing!.reminderAt
              ? _reminderAt
              : null);
    final at = _dueDate ?? reminder ?? existing?.endDate ?? now;

    final task = Task(
      id: existing?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: note.isEmpty ? null : note,
      taskType: TaskType.reminder,
      startDate: at,
      endDate: at,
      isCompleted: existing?.isCompleted ?? false,
      isNotificationEnabled: reminder != null,
      notificationType: NotificationType.specificTime,
      notificationTime: reminder,
      isPinnedToNotification: _pinned && (_dueDate != null || reminder != null),
      priority: _priority,
      category: _category,
      hasDueDate: _dueDate != null,
      completedAt: existing?.completedAt,
      // Only something with a date can come back on one.
      repeat: _dueDate != null || reminder != null ? _repeat : RepeatRule.none,
      createdAt: existing?.createdAt ?? now,
      updatedAt: existing == null ? null : now,
    );

    final bloc = context.read<TaskBloc>();
    if (existing != null) {
      bloc.add(UpdateTaskEvent(task));
    } else {
      bloc.add(AddTaskEvent(task));
    }
    context.pop();
  }

  /// To the full task form, with what has been typed so far.
  void _toRangedTask() {
    context.pushReplacement(
      '/add-task/range',
      extra: (_titleController.text.trim(), _noteController.text.trim()),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      backgroundColor: _field,
      appBar: AppBar(
        title: Text(
          widget.isEditing ? l.taskFormEditTitle : l.taskFormNewTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: _ink,
          ),
        ),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _muted),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            child: FilledButton.icon(
              key: const Key('item-save'),
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(l.commonSave),
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            _card(children: [_titleField(), ..._noteRow()]),
            const SizedBox(height: 12),
            _card(
              title: l.todoFormWhen,
              children: [
                _dueRow(),
                const SizedBox(height: 12),
                _reminderRow(),
                const SizedBox(height: 12),
                _repeatRow(),
                if (_hasWhen) ...[const SizedBox(height: 12), _pinRow()],
              ],
            ),
            const SizedBox(height: 12),
            _card(title: l.todoFormPriority, children: [_priorityRow()]),
            const SizedBox(height: 12),
            _card(title: l.todoFormCategory, children: [_categoryWrap()]),
            if (!widget.isEditing) ...[
              const SizedBox(height: 12),
              _rangeLink(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card({String? title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _muted,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _titleField() {
    final l = L.of(context);
    return TextFormField(
      key: const Key('item-title'),
      controller: _titleController,
      autofocus: !widget.isEditing,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: _ink,
      ),
      decoration: InputDecoration(
        hintText: l.taskFormTitleHint,
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? l.taskFormTitleEmpty : null,
    );
  }

  List<Widget> _noteRow() {
    if (!_showNote) {
      return [
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: _chipButton(
            icon: Icons.notes_rounded,
            label: L.of(context).reminderFormNote,
            onTap: () => setState(() => _showNote = true),
          ),
        ),
      ];
    }
    return [
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: _field,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextFormField(
          controller: _noteController,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 14, color: _ink),
          decoration: InputDecoration(
            hintText: L.of(context).todoFormNoteHint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
          ),
        ),
      ),
    ];
  }

  // ── When ───────────────────────────────────────────────────────────────

  Widget _dueRow() {
    final l = L.of(context);
    final now = DateTime.now();
    // Evening by default, but never a time that has already gone: tapping
    // "Today" at 10pm shouldn't hand you something that is instantly overdue.
    final evening = DateTime(now.year, now.month, now.day, 18);
    final today = evening.isAfter(now)
        ? evening
        : DateTime(now.year, now.month, now.day, 23, 59);
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 18);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_rounded, size: 17, color: _muted),
            const SizedBox(width: 8),
            Text(
              l.taskFormDue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
            const Spacer(),
            if (_dueDate != null)
              Flexible(
                child: Text(
                  _formatDateTime(_dueDate!),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _brand,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _choice(
              l.todoFormNoDate,
              key: 'due-none',
              selected: _dueDate == null,
              onTap: () => setState(() => _dueDate = null),
            ),
            _choice(
              l.commonToday,
              key: 'due-today',
              selected: _isSameDay(_dueDate, today),
              onTap: () => _setDue(today),
            ),
            _choice(
              l.commonTomorrow,
              key: 'due-tomorrow',
              selected: _isSameDay(_dueDate, tomorrow),
              onTap: () => _setDue(tomorrow),
            ),
            _choice(
              l.reminderFormPick,
              icon: Icons.calendar_month_rounded,
              selected:
                  _dueDate != null &&
                  !_isSameDay(_dueDate, today) &&
                  !_isSameDay(_dueDate, tomorrow),
              onTap: _pickDueDate,
            ),
          ],
        ),
      ],
    );
  }

  Widget _reminderRow() {
    final l = L.of(context);
    final on = _reminderAt != null;
    final stale = on && !_reminderIsUsable;
    final due = _dueDate;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: on ? _brand.withValues(alpha: 0.06) : _field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: on
              ? _brand.withValues(alpha: 0.35)
              : Colors.grey.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                on
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                size: 18,
                color: on ? _brand : _muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.taskFormRemindMe,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: on ? _brand : _ink,
                  ),
                ),
              ),
              Switch.adaptive(
                key: const Key('item-reminder-switch'),
                value: on,
                activeThumbColor: _brand,
                onChanged: (value) => setState(() {
                  _reminderAt = value ? _defaultReminder() : null;
                }),
              ),
            ],
          ),
          if (on) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (due != null) ...[
                  _remindChoice(l.todoFormAtDueTime, due),
                  _remindChoice(
                    l.todoFormHourBefore,
                    due.subtract(const Duration(hours: 1)),
                  ),
                  _remindChoice(
                    l.todoFormDayBefore,
                    due.subtract(const Duration(days: 1)),
                  ),
                ] else ...[
                  // No due date: the reminder is the point, so offer the
                  // one-tap times the reminder form had.
                  _remindChoice(l.reminderFormInAnHour, _inAnHour()),
                  if (_todayAt(18).isAfter(DateTime.now()))
                    _remindChoice(l.reminderFormThisEvening, _todayAt(18)),
                  _remindChoice(l.reminderFormTomorrow9, _tomorrowAt(9)),
                ],
                _choice(
                  l.reminderFormPick,
                  icon: Icons.schedule_rounded,
                  selected: !_reminderIsPreset(),
                  onTap: _pickReminder,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              stale
                  ? l.todoFormPassed
                  : l.todoFormNotificationOn(_formatDateTime(_reminderAt!)),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: stale ? const Color(0xFFDC2626) : _muted,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _remindChoice(String label, DateTime value) => _choice(
    label,
    selected: _reminderMatches(value),
    onTap: () => setState(() => _reminderAt = value),
  );

  bool _reminderIsPreset() {
    final due = _dueDate;
    final presets = due != null
        ? [
            due,
            due.subtract(const Duration(hours: 1)),
            due.subtract(const Duration(days: 1)),
          ]
        : [_inAnHour(), _todayAt(18), _tomorrowAt(9)];
    return presets.any(_reminderMatches);
  }

  Widget _repeatRow() {
    final l = L.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.repeat_rounded, size: 17, color: _muted),
            const SizedBox(width: 8),
            Text(
              l.repeatTitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in RepeatRule.values)
              _choice(
                r.labelFor(context),
                key: 'repeat-${r.name}',
                selected: _repeat == r,
                onTap: () => setState(() {
                  _repeat = r;
                  // Repeating needs a date to repeat from: today, unless
                  // one is already set.
                  if (r != RepeatRule.none && !_hasWhen) {
                    final now = DateTime.now();
                    final evening = DateTime(now.year, now.month, now.day, 18);
                    _dueDate = evening.isAfter(now)
                        ? evening
                        : DateTime(now.year, now.month, now.day, 23, 59);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _pinRow() {
    final l = L.of(context);
    return Row(
      children: [
        Icon(
          _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
          size: 19,
          color: _pinned ? _brand : _muted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.reminderFormKeepShade,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _pinned ? _brand : _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l.reminderFormKeepShadeBody,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: _pinned,
          activeThumbColor: _brand,
          onChanged: (value) => setState(() => _pinned = value),
        ),
      ],
    );
  }

  // ── Priority & category ────────────────────────────────────────────────

  Widget _priorityRow() {
    return Row(
      children: [
        for (final priority in TaskPriority.values) ...[
          Expanded(
            child: GestureDetector(
              key: Key('priority-${priority.name}'),
              onTap: () => setState(() => _priority = priority),
              child: Container(
                height: 62,
                margin: EdgeInsets.only(
                  right: priority == TaskPriority.values.last ? 0 : 8,
                ),
                decoration: BoxDecoration(
                  color: _priority == priority
                      ? priority.color.withValues(alpha: 0.14)
                      : _field,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _priority == priority
                        ? priority.color
                        : Colors.grey.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      priority.icon,
                      size: 18,
                      color: _priority == priority
                          ? priority.color
                          : Colors.grey[500],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      priority.labelFor(context),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _priority == priority
                            ? priority.color
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Optional: tapping the chosen category again clears it.
  Widget _categoryWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TaskCategory.values.map((category) {
        final selected = _category == category;
        return GestureDetector(
          key: Key('category-${category.name}'),
          onTap: () => setState(() => _category = selected ? null : category),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? category.color : _field,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? category.color
                    : Colors.grey.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category.icon,
                  size: 15,
                  color: selected ? Colors.white : category.color,
                ),
                const SizedBox(width: 6),
                Text(
                  category.labelFor(context),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _rangeLink() {
    final l = L.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('item-to-range'),
        borderRadius: BorderRadius.circular(16),
        onTap: _toRangedTask,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  size: 20,
                  color: _brand,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.itemFormRangeTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.itemFormRangeBody,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  // ── Small pieces ───────────────────────────────────────────────────────

  Widget _choice(
    String label, {
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    String? key,
  }) {
    return Material(
      key: key == null ? null : Key(key),
      color: selected ? _brand : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _brand : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: selected ? Colors.white : _muted),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _brand.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: _brand),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Date helpers ───────────────────────────────────────────────────────

  void _setDue(DateTime date) {
    setState(() {
      // Keep a reminder that was pinned to the old due date on the new one.
      if (_reminderAt != null &&
          _dueDate != null &&
          _reminderMatches(_dueDate!)) {
        _reminderAt = date;
      }
      _dueDate = date;
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: L.of(context).todoFormDueDate,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime(0, 1, 1, 18)),
      helpText: L.of(context).todoFormDueTime,
    );
    if (!mounted) return;

    _setDue(
      DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 18,
        time?.minute ?? 0,
      ),
    );
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final base = _reminderAt ?? _defaultReminder();
    final date = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now) ? now : base,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      helpText: L.of(context).reminderFormOnDate,
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: L.of(context).reminderFormAtTime,
    );
    if (!mounted) return;

    setState(() {
      _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? base.hour,
        time?.minute ?? base.minute,
      );
    });
  }

  /// Turning the switch on shouldn't make you pick a time — the due time, or
  /// an hour from now, is nearly always what you meant.
  DateTime _defaultReminder() {
    final due = _dueDate;
    if (due != null && due.isAfter(DateTime.now())) return due;
    return _inAnHour();
  }

  DateTime _inAnHour() {
    final now = DateTime.now();
    // Rounded to five minutes: "10:47" is a strange one-tap choice.
    final rounded = now.add(Duration(minutes: 60 - now.minute % 5));
    return DateTime(
      rounded.year,
      rounded.month,
      rounded.day,
      rounded.hour,
      rounded.minute - rounded.minute % 5,
    );
  }

  DateTime _todayAt(int hour) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour);
  }

  DateTime _tomorrowAt(int hour) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, hour);
  }

  bool _reminderMatches(DateTime candidate) {
    final current = _reminderAt;
    if (current == null) return false;
    return current.difference(candidate).inMinutes.abs() < 1;
  }

  bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateTime(DateTime dateTime) {
    final l = L.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final label = switch (day.difference(today).inDays) {
      0 => l.commonToday,
      1 => l.commonTomorrow,
      -1 => l.commonYesterday,
      _ => DateFormat('d MMM').format(dateTime),
    };
    return '$label, ${Clock.h12(dateTime)}';
  }
}
