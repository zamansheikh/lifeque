import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';

/// Add or edit a reminder.
///
/// A reminder is one sentence and one moment. The task form wrapped that in a
/// start date, an end date, a notification *type* and a "before the deadline"
/// option, none of which a reminder has — it fires once, at the time you said.
class AddEditReminderPage extends StatefulWidget {
  final String? taskId;

  const AddEditReminderPage({super.key, this.taskId});

  bool get isEditing => taskId != null;

  @override
  State<AddEditReminderPage> createState() => _AddEditReminderPageState();
}

class _AddEditReminderPageState extends State<AddEditReminderPage> {
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _amber = Color(0xFFD97706);
  static const _field = Color(0xFFFFFBEB);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _when;
  bool _showNote = false;
  bool _pinned = false;
  Task? _existing;

  @override
  void initState() {
    super.initState();
    _when = _inAnHour();
    if (widget.isEditing) _load();
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
    _when = task.notificationTime ?? task.endDate;
    _pinned = task.isPinnedToNotification;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────────

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (!_when.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Pick a time in the future'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      return;
    }

    final now = DateTime.now();
    final note = _noteController.text.trim();

    // Reminders store the one moment three times over: startDate, endDate and
    // notificationTime. isActive reads endDate, the scheduler reads endDate,
    // and the detail page reads notificationTime.
    final task = Task(
      id: _existing?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: note.isEmpty ? null : note,
      taskType: TaskType.reminder,
      startDate: _when,
      endDate: _when,
      isCompleted: _existing?.isCompleted ?? false,
      isNotificationEnabled: true,
      notificationType: NotificationType.specificTime,
      notificationTime: _when,
      isPinnedToNotification: _pinned,
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
          widget.isEditing ? 'Edit reminder' : 'New reminder',
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
                backgroundColor: _amber,
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
            _card(title: 'Remind me', children: [_whenRow()]),
            const SizedBox(height: 12),
            _card(children: [_pinRow()]),
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
        hintText: 'Remind me to…',
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.w500,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Say what to remind you about';
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
            color: _amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _showNote = true),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notes_rounded, size: 15, color: _amber),
                    SizedBox(width: 7),
                    Text(
                      'Add a note',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _amber,
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
            hintText: 'Anything worth remembering',
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
          ),
        ),
      ),
    ];
  }

  Widget _whenRow() {
    final hour = _inAnHour();
    final evening = _todayAt(18);
    final morning = _tomorrowAt(9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _amber.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                size: 19,
                color: _amber,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatDateTime(_when),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
              Text(
                _relative(_when),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _when.isAfter(DateTime.now())
                      ? Colors.grey[600]
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _choice('In an hour', hour),
            if (evening.isAfter(DateTime.now()))
              _choice('This evening', evening),
            _choice('Tomorrow 9am', morning),
            _pickChoice(),
          ],
        ),
      ],
    );
  }

  Widget _choice(String label, DateTime value) {
    final selected = _when.difference(value).inMinutes.abs() < 1;
    return _pill(
      label: label,
      selected: selected,
      onTap: () => setState(() => _when = value),
    );
  }

  Widget _pickChoice() {
    final preset = [
      _inAnHour(),
      _todayAt(18),
      _tomorrowAt(9),
    ].any((d) => _when.difference(d).inMinutes.abs() < 1);
    return _pill(
      label: 'Pick…',
      icon: Icons.schedule_rounded,
      selected: !preset,
      onTap: _pickDateTime,
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Material(
      color: selected ? _amber : Colors.white,
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
              color: selected ? _amber : Colors.grey.withValues(alpha: 0.3),
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

  Widget _pinRow() {
    return Row(
      children: [
        Icon(
          _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
          size: 19,
          color: _pinned ? _amber : _muted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keep it in the shade',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _pinned ? _amber : _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'An ongoing notification you can\'t swipe away until it\'s done',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: _pinned,
          activeThumbColor: _amber,
          onChanged: (value) => setState(() => _pinned = value),
        ),
      ],
    );
  }

  // ── Time helpers ───────────────────────────────────────────────────────

  DateTime _inAnHour() {
    final now = DateTime.now();
    // Rounded to the next five minutes: "10:47" is a strange thing to be
    // offered as a one-tap choice.
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

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _when.isAfter(now) ? _when : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
      helpText: 'Remind me on',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: _amber,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
      helpText: 'Remind me at',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: _amber,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted) return;

    setState(() {
      _when = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _when.hour,
        time?.minute ?? _when.minute,
      );
    });
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = day.difference(today).inDays;

    final label = switch (diff) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => DateFormat('EEE d MMM').format(dateTime),
    };
    return '$label, ${DateFormat('HH:mm').format(dateTime)}';
  }

  String _relative(DateTime dateTime) {
    final diff = dateTime.difference(DateTime.now());
    if (diff.isNegative) return 'in the past';
    if (diff.inMinutes < 60) return 'in ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'in ${diff.inHours} h';
    return 'in ${diff.inDays} d';
  }
}
