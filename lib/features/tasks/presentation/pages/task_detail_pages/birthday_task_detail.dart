import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/detail_kit.dart';
import '../../../domain/entities/task.dart';
import '../../bloc/task_bloc.dart';

/// A birthday's detail view: how old they are, when the next one lands, and
/// which reminders are set for it.
class BirthdayTaskDetail extends StatefulWidget {
  final Task task;

  const BirthdayTaskDetail({super.key, required this.task});

  @override
  State<BirthdayTaskDetail> createState() => _BirthdayTaskDetailState();
}

class _BirthdayTaskDetailState extends State<BirthdayTaskDetail> {
  Timer? _ticker;

  Task get _task => widget.task;

  /// The date of birth. Birthdays store it in `endDate`.
  DateTime get _birth => _task.endDate;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFDB2777);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // nextOccurrence compares by date, so the birthday reads as "today" on the
    // day itself rather than jumping a year ahead at midnight.
    final next = _task.nextOccurrence;
    final daysUntil = next.difference(today).inDays;
    final isToday = daysUntil == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailHero(
          icon: isToday ? Icons.celebration_rounded : Icons.cake_rounded,
          accent: accent,
          status: _status(daysUntil),
          title: _task.title,
          subtitle:
              '${DateFormat('EEEE, d MMMM').format(next)}'
              ' · turning ${next.year - _birth.year}',
          description: _task.description,
          isDone: _task.isCompleted,
          action: DetailCheckCircle(
            checked: _task.isCompleted,
            accent: accent,
            onTap: () =>
                context.read<TaskBloc>().add(ToggleTaskCompletion(_task.id)),
          ),
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: isToday ? 'TODAY' : 'COUNTDOWN',
          icon: Icons.hourglass_bottom_rounded,
          accent: accent,
          children: [
            if (isToday)
              Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'It is today — they turn ${next.year - _birth.year}.',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              )
            else
              DetailCountdown(
                remaining: next.difference(now),
                color: accent,
                caption: 'Until the big day',
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DetailStat(
                    value: '${_ageOn(today)}',
                    label: 'years old now',
                    icon: Icons.person_rounded,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DetailStat(
                    value: isToday ? 'Today' : '$daysUntil',
                    label: isToday ? 'the big day' : 'days to go',
                    icon: Icons.event_rounded,
                    color: accent,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: 'REMINDERS',
          icon: Icons.notifications_active_rounded,
          accent: const Color(0xFF7C3AED),
          children: [
            if (_task.birthdayNotificationSchedule.isEmpty)
              Text(
                'No reminders set for this birthday.',
                style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
              )
            else
              for (final option in _task.birthdayNotificationSchedule)
                DetailRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: option.displayName,
                  value: option.description,
                ),
          ],
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: 'DETAILS',
          icon: Icons.info_outline_rounded,
          accent: Colors.grey.shade500,
          children: [
            DetailRow(
              icon: Icons.cake_rounded,
              label: 'Born',
              value: DateFormat('d MMMM y').format(_birth),
            ),
            DetailRow(
              icon: Icons.event_repeat_rounded,
              label: 'Next birthday',
              value: DateFormat('EEE, d MMM y').format(next),
            ),
            DetailRow(
              icon: Icons.add_circle_outline_rounded,
              label: 'Saved',
              value: DateFormat('d MMM y').format(_task.createdAt),
            ),
            if (_task.updatedAt != null)
              DetailRow(
                icon: Icons.edit_rounded,
                label: 'Last edited',
                value: DateFormat('d MMM y').format(_task.updatedAt!),
              ),
          ],
        ),
      ],
    );
  }

  /// Whole years old on [date] — decremented when this year's birthday is
  /// still ahead, which a plain year subtraction gets wrong for half the year.
  int _ageOn(DateTime date) {
    var age = date.year - _birth.year;
    final hadBirthday =
        date.month > _birth.month ||
        (date.month == _birth.month && date.day >= _birth.day);
    if (!hadBirthday) age--;
    return age < 0 ? 0 : age;
  }

  String _status(int daysUntil) {
    if (daysUntil == 0) return 'Birthday today';
    if (daysUntil == 1) return 'Birthday tomorrow';
    if (daysUntil <= 7) return 'In $daysUntil days';
    return 'In $daysUntil days';
  }
}
