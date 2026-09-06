import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/detail_kit.dart';
import '../../../domain/entities/task.dart';
import '../../bloc/task_bloc.dart';

/// A task's detail view: how long is left, how far along, and the dates.
class TraditionalTaskDetail extends StatefulWidget {
  final Task task;

  const TraditionalTaskDetail({super.key, required this.task});

  @override
  State<TraditionalTaskDetail> createState() => _TraditionalTaskDetailState();
}

class _TraditionalTaskDetailState extends State<TraditionalTaskDetail> {
  Timer? _ticker;

  Task get _task => widget.task;

  @override
  void initState() {
    super.initState();
    // The countdown is the reason to be on this screen, so it ticks while it
    // is open — and only while it is open.
    if (!_task.isCompleted) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => mounted ? setState(() {}) : null,
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent();
    final remaining = _task.endDate.difference(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailHero(
          icon: Icons.assignment_rounded,
          accent: accent,
          status: _status(),
          title: _task.title,
          subtitle: 'Due ${_full(_task.endDate)}',
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
        if (!_task.isCompleted) ...[
          DetailSection(
            title: 'TIME LEFT',
            icon: Icons.hourglass_bottom_rounded,
            accent: accent,
            children: [
              DetailCountdown(
                remaining: remaining,
                color: accent,
                caption: 'Until the deadline',
                passedLabel: 'The deadline has passed',
              ),
              const SizedBox(height: 16),
              DetailProgress(
                value: _task.progressPercentage,
                color: accent,
                label: 'Time elapsed',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DetailStat(
                      value: '${_task.daysLeft}',
                      label: 'days left',
                      icon: Icons.schedule_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DetailStat(
                      value: '${_totalDays()}',
                      label: 'days total',
                      icon: Icons.calendar_month_rounded,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        DetailSection(
          title: 'TIMELINE',
          icon: Icons.timeline_rounded,
          accent: const Color(0xFFEA580C),
          children: [
            DetailTimelineTile(
              icon: Icons.play_circle_outline_rounded,
              color: const Color(0xFF10B981),
              label: 'Started',
              value: _full(_task.startDate),
              hasNext: true,
            ),
            DetailTimelineTile(
              icon: Icons.flag_rounded,
              color: _task.isOverdue ? Colors.red.shade500 : accent,
              label: _task.isOverdue ? 'Was due' : 'Due',
              value: _full(_task.endDate),
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
              icon: _task.isNotificationEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              label: 'Reminder',
              value: _reminderLabel(),
            ),
            if (_task.isPinnedToNotification)
              const DetailRow(
                icon: Icons.push_pin_rounded,
                label: 'Pinned',
                value: 'Kept in the shade',
              ),
            DetailRow(
              icon: Icons.add_circle_outline_rounded,
              label: 'Created',
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

  int _totalDays() {
    final days = _task.endDate.difference(_task.startDate).inDays;
    return days < 1 ? 1 : days;
  }

  /// The reminder in the same words the form used to set it, rather than a
  /// bare "Enabled" that says nothing about when.
  String _reminderLabel() {
    if (!_task.isNotificationEnabled) return 'Off';

    return switch (_task.notificationType) {
      NotificationType.beforeEnd =>
        _task.beforeEndOption == null
            ? 'Before it is due'
            : '${_task.beforeEndOption!.displayName} before',
      NotificationType.daily =>
        _task.dailyNotificationTime == null
            ? 'Every day'
            : '${_task.dailyNotificationTime!.format(context)} daily',
      NotificationType.specificTime =>
        _task.notificationTime == null
            ? 'At a set time'
            : _full(_task.notificationTime!),
    };
  }

  String _full(DateTime value) =>
      DateFormat('EEE, d MMM y · h:mm a').format(value);

  Color _accent() {
    if (_task.isCompleted) return const Color(0xFF10B981);
    if (_task.isOverdue) return Colors.red.shade500;
    if (_task.isActive) return const Color(0xFF2563EB);
    return const Color(0xFFF59E0B);
  }

  String _status() {
    if (_task.isCompleted) return 'Completed';
    if (_task.isOverdue) return 'Overdue';
    if (_task.isActive) return 'In progress';
    return 'Not started yet';
  }
}
