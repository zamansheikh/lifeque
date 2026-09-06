import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';
import '../../../../l10n/app_localizations.dart';

/// Add or edit a birthday.
///
/// Birthdays are stored as [TaskType.birthday] rows, but filling one in has
/// nothing in common with filling in a task: there is no start and end date,
/// no "pin to notification", no notification type, and the one question that
/// matters — whose birthday, and when — was buried under a type picker asking
/// whether this was a task, a reminder or a birthday at all. This form asks
/// only what a birthday needs.
class AddEditBirthdayPage extends StatefulWidget {
  final String? taskId;

  const AddEditBirthdayPage({super.key, this.taskId});

  bool get isEditing => taskId != null;

  @override
  State<AddEditBirthdayPage> createState() => _AddEditBirthdayPageState();
}

class _AddEditBirthdayPageState extends State<AddEditBirthdayPage> {
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _pink = Color(0xFFDB2777);
  static const _field = Color(0xFFFDF7FA);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _birthDate = DateTime.now();
  bool _showNote = false;
  Task? _existing;

  /// Sensible for someone who just wants to be told: a day's warning to sort
  /// a gift, then a nudge on the morning itself.
  Set<BirthdayNotificationOption> _schedule = {
    BirthdayNotificationOption.oneDayBefore,
    BirthdayNotificationOption.exactTime,
  };

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _load();
  }

  void _load() {
    final state = context.read<TaskBloc>().state;
    if (state is! TaskLoaded) return;
    final match = state.tasks.where((t) => t.id == widget.taskId);
    if (match.isEmpty) return;

    final task = match.first;
    _existing = task;
    _nameController.text = task.title;
    _noteController.text = task.description ?? '';
    _showNote = _noteController.text.isNotEmpty;
    _birthDate = task.startDate;
    if (task.birthdayNotificationSchedule.isNotEmpty) {
      _schedule = task.birthdayNotificationSchedule.toSet();
    } else if (!task.isNotificationEnabled) {
      _schedule = {};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────────

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final note = _noteController.text.trim();

    // Birthdays keep the birth date in both start and end: nextOccurrence
    // reads endDate, the notification schedule reads startDate.
    final task = Task(
      id: _existing?.id ?? const Uuid().v4(),
      title: _nameController.text.trim(),
      description: note.isEmpty ? null : note,
      taskType: TaskType.birthday,
      startDate: _birthDate,
      endDate: _birthDate,
      isCompleted: false,
      // Unchecking every reminder is a deliberate "just keep the date".
      isNotificationEnabled: _schedule.isNotEmpty,
      notificationType: NotificationType.specificTime,
      birthdayNotificationSchedule: BirthdayNotificationOption.values
          .where(_schedule.contains)
          .toList(),
      createdAt: _existing?.createdAt ?? now,
      updatedAt: _existing == null ? null : now,
    );

    final bloc = context.read<TaskBloc>();
    if (_existing != null) {
      bloc.add(UpdateTaskEvent(task));
    } else {
      bloc.add(AddTaskEvent(task));
    }
    context.pop();
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _field,
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? L.of(context).birthdayFormEdit
              : L.of(context).birthdayFormNew,
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
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                backgroundColor: _pink,
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
            _card(children: [_nameField(), ..._noteRow()]),
            const SizedBox(height: 12),
            _card(title: L.of(context).birthdayFormDob, children: [_dateRow()]),
            const SizedBox(height: 12),
            _card(
              title: L.of(context).taskFormRemindMe,
              children: [_scheduleList()],
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

  Widget _nameField() {
    return TextFormField(
      controller: _nameController,
      autofocus: !widget.isEditing,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: _ink,
      ),
      decoration: InputDecoration(
        hintText: L.of(context).birthdayFormNameLabel,
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return L.of(context).birthdayFormNameEmpty;
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
          child: Material(
            color: _pink.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _showNote = true),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notes_rounded, size: 15, color: _pink),
                    SizedBox(width: 7),
                    Text(
                      L.of(context).reminderFormNote,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _pink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            hintText: L.of(context).birthdayFormNoteHint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
          ),
        ),
      ),
    ];
  }

  Widget _dateRow() {
    final age = _ageTurning();
    final yearKnown = _birthDate.year < DateTime.now().year;

    return Material(
      color: _field,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _pickDate,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _pink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.cake_rounded, size: 19, color: _pink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      yearKnown
                          ? DateFormat('d MMMM yyyy').format(_birthDate)
                          : DateFormat('d MMMM').format(_birthDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      age != null
                          ? L.of(context).birthdayFormTurning(age)
                          : L.of(context).birthdayFormSetYear,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scheduleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final option in BirthdayNotificationOption.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _scheduleTile(option),
          ),
        Text(
          _schedule.isEmpty
              ? L.of(context).birthdayFormNoReminders
              : 'You\'ll be reminded ${_schedule.length == 1 ? 'once' : '${_schedule.length} times'} every year.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.35),
        ),
      ],
    );
  }

  Widget _scheduleTile(BirthdayNotificationOption option) {
    final selected = _schedule.contains(option);
    return Material(
      color: selected ? _pink.withValues(alpha: 0.07) : _field,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() {
          if (selected) {
            _schedule.remove(option);
          } else {
            _schedule.add(option);
          }
        }),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? _pink.withValues(alpha: 0.45)
                  : Colors.grey.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label(option),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? _pink : _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? _pink : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: selected ? _pink : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The stored labels are written for the task form ("1 day before (gift
  /// prep)"); on a screen that is only ever about birthdays they can be plain.
  String _label(BirthdayNotificationOption option) => switch (option) {
    BirthdayNotificationOption.oneDayBefore =>
      L.of(context).birthdayFormDayBefore,
    BirthdayNotificationOption.twoHoursBefore =>
      L.of(context).birthdayFormTwoHours,
    BirthdayNotificationOption.tenMinutesBefore =>
      L.of(context).birthdayFormTenMinutes,
    BirthdayNotificationOption.exactTime => L.of(context).birthdayFormMidnight,
  };

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: L.of(context).birthdayFormDob,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: _pink,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  int? _ageTurning() {
    final now = DateTime.now();
    if (_birthDate.year >= now.year) return null;

    final today = DateTime(now.year, now.month, now.day);
    final thisYear = DateTime(now.year, _birthDate.month, _birthDate.day);
    final nextYear = today.isAfter(thisYear) ? now.year + 1 : now.year;
    final age = nextYear - _birthDate.year;
    return age > 0 ? age : null;
  }
}
