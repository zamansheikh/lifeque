import 'package:flutter/material.dart';

import '../../../../core/utils/local_clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/todo.dart';
import '../bloc/todo_bloc.dart';
import '../utils/todo_l10n.dart';
import '../../../../l10n/app_localizations.dart';

/// Create or edit a to-do.
///
/// Only the title is required. Due date and reminder are offered as one-tap
/// choices rather than pickers you have to open, because the common answers
/// are "today", "tomorrow" and "when it's due".
class AddEditTodoPage extends StatefulWidget {
  final Todo? todo;

  const AddEditTodoPage({super.key, this.todo});

  bool get isEditing => todo != null;

  @override
  State<AddEditTodoPage> createState() => _AddEditTodoPageState();
}

class _AddEditTodoPageState extends State<AddEditTodoPage> {
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _brand = Color(0xFF2563EB);
  static const _field = Color(0xFFF8FAFC);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TodoCategory _category = TodoCategory.personal;
  TodoPriority _priority = TodoPriority.medium;
  DateTime? _dueDate;
  DateTime? _reminderAt;
  bool _showNote = false;

  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    if (todo != null) {
      _titleController.text = todo.title;
      _descriptionController.text = todo.description ?? '';
      _showNote = _descriptionController.text.isNotEmpty;
      _category = todo.category;
      _priority = todo.priority;
      _dueDate = todo.dueDate;
      _reminderAt = todo.hasReminder ? todo.reminderTime : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────────

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.todo;
    final description = _descriptionController.text.trim();

    final todo = Todo(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: description.isEmpty ? null : description,
      category: _category,
      priority: _priority,
      dueDate: _dueDate,
      // A reminder in the past would never fire, so it is dropped rather than
      // saved as a promise the app can't keep.
      reminderTime: _reminderIsUsable ? _reminderAt : null,
      hasReminder: _reminderIsUsable,
      isCompleted: existing?.isCompleted ?? false,
      createdAt: existing?.createdAt ?? DateTime.now(),
      completedAt: existing?.completedAt,
      // Carried through rather than dropped: editing a to-do used to silently
      // wipe whatever wasn't on this form.
      tags: existing?.tags ?? const [],
    );

    final bloc = context.read<TodoBloc>();
    if (widget.isEditing) {
      bloc.add(UpdateTodoEvent(todo));
    } else {
      bloc.add(AddTodoEvent(todo));
    }
    context.pop();
  }

  bool get _reminderIsUsable =>
      _reminderAt != null && _reminderAt!.isAfter(DateTime.now());

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _field,
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? L.of(context).todoFormEdit
              : L.of(context).todoFormNew,
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
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(L.of(context).commonSave),
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
              title: L.of(context).todoFormWhen,
              children: [_dueRow(), const SizedBox(height: 12), _reminderRow()],
            ),
            const SizedBox(height: 12),
            _card(
              title: L.of(context).todoFormPriority,
              children: [_priorityRow()],
            ),
            const SizedBox(height: 12),
            _card(
              title: L.of(context).todoFormCategory,
              children: [_categoryWrap()],
            ),
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
    return TextFormField(
      controller: _titleController,
      autofocus: !widget.isEditing,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: _ink,
      ),
      decoration: InputDecoration(
        hintText: L.of(context).todoFormTitleLabel,
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return L.of(context).todoFormTitleEmpty;
        }
        return null;
      },
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
          controller: _descriptionController,
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
              L.of(context).taskFormDue,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
            const Spacer(),
            if (_dueDate != null)
              Text(
                _formatDateTime(_dueDate!),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _brand,
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
              L.of(context).todoFormNoDate,
              selected: _dueDate == null,
              onTap: () => setState(() {
                _dueDate = null;
                _reminderAt = null;
              }),
            ),
            _choice(
              L.of(context).commonToday,
              selected: _isSameDay(_dueDate, today),
              onTap: () => _setDue(today),
            ),
            _choice(
              L.of(context).commonTomorrow,
              selected: _isSameDay(_dueDate, tomorrow),
              onTap: () => _setDue(tomorrow),
            ),
            _choice(
              L.of(context).reminderFormPick,
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
    final on = _reminderAt != null;
    final stale = on && !_reminderIsUsable;

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
                  L.of(context).taskFormRemindMe,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: on ? _brand : _ink,
                  ),
                ),
              ),
              Switch.adaptive(
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
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_dueDate != null) ...[
                  _choice(
                    L.of(context).todoFormAtDueTime,
                    selected: _reminderMatches(_dueDate!),
                    onTap: () => setState(() => _reminderAt = _dueDate),
                  ),
                  _choice(
                    L.of(context).todoFormHourBefore,
                    selected: _reminderMatches(
                      _dueDate!.subtract(const Duration(hours: 1)),
                    ),
                    onTap: () => setState(
                      () => _reminderAt = _dueDate!.subtract(
                        const Duration(hours: 1),
                      ),
                    ),
                  ),
                  _choice(
                    L.of(context).todoFormDayBefore,
                    selected: _reminderMatches(
                      _dueDate!.subtract(const Duration(days: 1)),
                    ),
                    onTap: () => setState(
                      () => _reminderAt = _dueDate!.subtract(
                        const Duration(days: 1),
                      ),
                    ),
                  ),
                ],
                _choice(
                  _dueDate == null
                      ? _formatDateTime(_reminderAt!)
                      : L.of(context).reminderFormPick,
                  icon: Icons.schedule_rounded,
                  selected: _dueDate == null,
                  onTap: _pickReminder,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              stale
                  ? L.of(context).todoFormPassed
                  : L
                        .of(context)
                        .todoFormNotificationOn(_formatDateTime(_reminderAt!)),
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

  // ── Priority & category ────────────────────────────────────────────────

  Widget _priorityRow() {
    return Row(
      children: [
        for (final priority in TodoPriority.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _priority = priority),
              child: Container(
                height: 62,
                margin: EdgeInsets.only(
                  right: priority == TodoPriority.values.last ? 0 : 8,
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

  Widget _categoryWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TodoCategory.values.map((category) {
        final selected = _category == category;
        return GestureDetector(
          onTap: () => setState(() => _category = category),
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

  // ── Small pieces ───────────────────────────────────────────────────────

  Widget _choice(
    String label, {
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Material(
      color: selected ? _brand : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        // No `alignment` here: a Container that is given one and no width
        // expands to fill its loose constraints, which made every choice a
        // full-width row inside the Wrap instead of a chip.
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
      _dueDate = date;
      // Keep an existing reminder pinned to the due date rather than leaving
      // it stranded on the old one.
      if (_reminderAt != null) _reminderAt = date;
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

    final due = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 18,
      time?.minute ?? 0,
    );
    _setDue(due);
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final base = _reminderAt ?? _defaultReminder();
    final date = await showDatePicker(
      context: context,
      initialDate: base,
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

  /// Turning the switch on shouldn't make you pick a time — the due date, or
  /// an hour from now, is nearly always what you meant.
  DateTime _defaultReminder() {
    final due = _dueDate;
    if (due != null && due.isAfter(DateTime.now())) return due;
    return DateTime.now().add(const Duration(hours: 1));
  }

  bool _reminderMatches(DateTime candidate) {
    final current = _reminderAt;
    if (current == null) return false;
    return current.difference(candidate).inMinutes.abs() < 1;
  }

  bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = day.difference(today).inDays;

    final label = switch (diff) {
      0 => L.of(context).commonToday,
      1 => L.of(context).commonTomorrow,
      -1 => L.of(context).commonYesterday,
      _ => DateFormat('d MMM').format(dateTime),
    };
    return '$label, ${Clock.h12(dateTime)}';
  }
}
