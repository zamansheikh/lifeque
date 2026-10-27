import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/local_clock.dart';
import '../../../injection_container.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../domain/habit.dart';
import 'habit_cubit.dart';
import 'habit_ui.dart';

/// Add or edit a habit: its name, look, days and reminder.
class EditHabitPage extends StatefulWidget {
  final String? id;

  /// A suggestion picked from the empty list, to start from.
  final HabitIdea? idea;
  const EditHabitPage({super.key, this.id, this.idea});

  @override
  State<EditHabitPage> createState() => _EditHabitPageState();
}

class _EditHabitPageState extends State<EditHabitPage> {
  final _cubit = di.sl<HabitCubit>();
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  int _icon = 0;
  int _color = 0;
  int _days = Habit.everyDay;
  int? _reminder;
  Habit? _existing;
  bool _ideaApplied = false;

  bool get _editing => widget.id != null;

  @override
  void initState() {
    super.initState();
    final h = widget.id == null
        ? null
        : _cubit.state.habits.where((h) => h.id == widget.id).firstOrNull;
    if (h != null) {
      _existing = h;
      _name.text = h.name;
      _icon = h.icon;
      _color = h.color;
      _days = h.days;
      _reminder = h.reminderMinutes;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final idea = widget.idea;
    if (idea != null && !_ideaApplied) {
      _ideaApplied = true;
      _applyIdea(idea);
    }
  }

  void _applyIdea(HabitIdea idea) {
    _name.text = idea.$1(L.of(context));
    _icon = idea.$2;
    _color = idea.$3;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final base = _existing;
    final habit = Habit(
      id: base?.id ?? const Uuid().v4(),
      name: _name.text.trim(),
      icon: _icon,
      color: _color,
      days: _days,
      reminderMinutes: _reminder,
      archived: base?.archived ?? false,
      sortOrder: base?.sortOrder ?? _cubit.state.habits.length,
      createdAt: base?.createdAt ?? DateTime.now(),
    );
    await _cubit.save(habit);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l = L.of(context);
    final h = _existing;
    if (h == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.habitDeleteTitle),
        content: Text(l.habitDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _cubit.delete(h.id);
    // Leave both this page and the habit's detail page behind it.
    if (mounted) context.go('/habits');
  }

  Future<void> _pickReminder() async {
    final m = _reminder ?? 8 * 60;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (t != null) setState(() => _reminder = t.hour * 60 + t.minute);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final color = habitColor(_color);
    final monday = DateTime(2024, 1, 1);
    final reminder = _reminder;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(_editing ? l.habitEdit : l.habitAdd),
        actions: [
          if (_editing)
            IconButton(
              tooltip: l.commonDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFDC2626),
              ),
              onPressed: _delete,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            child: FilledButton.icon(
              key: const Key('habit-save'),
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(l.commonSave),
              style: FilledButton.styleFrom(backgroundColor: color),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              key: const Key('habit-name'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l.habitName,
                prefixIcon: Icon(habitIcon(_icon), color: color),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l.habitNameEmpty : null,
            ),
            if (!_editing) ...[
              const SizedBox(height: 10),
              _label(l.habitSuggestions),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final idea in habitIdeas)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: Icon(
                            habitIcon(idea.$2),
                            size: 16,
                            color: habitColor(idea.$3),
                          ),
                          label: Text(idea.$1(l)),
                          onPressed: () => setState(() => _applyIdea(idea)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _label(l.habitIcon),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < habitIcons.length; i++)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _icon = i),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: i == _icon
                            ? color.withValues(alpha: 0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: i == _icon ? color : Colors.grey.shade200,
                          width: i == _icon ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        habitIcons[i],
                        color: i == _icon ? color : Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _label(l.habitColor),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < habitColors.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _color = i),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: habitColors[i],
                        shape: BoxShape.circle,
                        border: i == _color
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: i == _color
                            ? [
                                BoxShadow(
                                  color: habitColors[i],
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _label(l.habitDays)),
                if (_days != Habit.everyDay)
                  TextButton(
                    onPressed: () => setState(() => _days = Habit.everyDay),
                    child: Text(l.habitEveryDay),
                  ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var d = 0; d < 7; d++)
                  Builder(
                    builder: (_) {
                      final on = _days & (1 << d) != 0;
                      return InkWell(
                        key: Key('habit-day-$d'),
                        customBorder: const CircleBorder(),
                        onTap: () {
                          final next = _days ^ (1 << d);
                          // A habit for no days at all makes no sense.
                          if (next != 0) setState(() => _days = next);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: on ? color : Colors.white,
                            border: Border.all(
                              color: on ? color : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            DateFormat.E()
                                .format(monday.add(Duration(days: d)))
                                .characters
                                .take(2)
                                .toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: on ? Colors.white : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              key: const Key('habit-reminder'),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              secondary: Icon(Icons.notifications_rounded, color: color),
              title: Text(l.habitReminder),
              subtitle: Text(
                reminder == null
                    ? l.habitReminderOff
                    : Clock.h12(
                        DateTime(2024, 1, 1, reminder ~/ 60, reminder % 60),
                      ),
              ),
              value: reminder != null,
              activeThumbColor: color,
              onChanged: (on) {
                if (on) {
                  _pickReminder();
                } else {
                  setState(() => _reminder = null);
                }
              },
            ),
            if (reminder != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _pickReminder,
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(l.reminderFormPick),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
      ),
    ),
  );
}
