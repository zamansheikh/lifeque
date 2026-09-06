import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/detail_kit.dart';
import '../../../../../l10n/app_localizations.dart';
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
    final l = L.of(context);
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
          subtitle: '${l.detailDue} ${_full(_task.endDate)}',
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
            title: l.detailSectionTimeLeft,
            icon: Icons.hourglass_bottom_rounded,
            accent: accent,
            children: [
              DetailCountdown(
                remaining: remaining,
                color: accent,
                caption: l.detailUntilDeadline,
                passedLabel: l.detailDeadlinePassed,
              ),
              const SizedBox(height: 16),
              DetailProgress(
                value: _task.progressPercentage,
                color: accent,
                label: l.detailTimeElapsed,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DetailStat(
                      value: '${_task.daysLeft}',
                      label: l.detailDaysLeft,
                      icon: Icons.schedule_rounded,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DetailStat(
                      value: '${_totalDays()}',
                      label: l.detailDaysTotal,
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
          title: l.detailSectionTimeline,
          icon: Icons.timeline_rounded,
          accent: const Color(0xFFEA580C),
          children: [
            DetailTimelineTile(
              icon: Icons.play_circle_outline_rounded,
              color: const Color(0xFF10B981),
              label: l.detailStarted,
              value: _full(_task.startDate),
              hasNext: true,
            ),
            DetailTimelineTile(
              icon: Icons.flag_rounded,
              color: _task.isOverdue ? Colors.red.shade500 : accent,
              label: _task.isOverdue ? l.detailWasDue : l.detailDue,
              value: _full(_task.endDate),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: l.detailSectionDetails,
          icon: Icons.info_outline_rounded,
          accent: Colors.grey.shade500,
          children: [
            DetailRow(
              icon: _task.isNotificationEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              label: l.detailReminderRow,
              value: _reminderLabel(),
            ),
            if (_task.isPinnedToNotification)
              DetailRow(
                icon: Icons.push_pin_rounded,
                label: l.detailPinned,
                value: l.detailPinnedValue,
              ),
            DetailRow(
              icon: Icons.add_circle_outline_rounded,
              label: l.detailCreated,
              value: DateFormat('d MMM y').format(_task.createdAt),
            ),
            if (_task.updatedAt != null)
              DetailRow(
                icon: Icons.edit_rounded,
                label: l.detailLastEdited,
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
    final l = L.of(context);
    if (!_task.isNotificationEnabled) return l.commonOff;

    return switch (_task.notificationType) {
      NotificationType.beforeEnd =>
        _task.beforeEndOption == null
            ? l.detailReminderBeforeDue
            : l.detailReminderBefore(_beforeEndLabel(_task.beforeEndOption!)),
      NotificationType.daily =>
        _task.dailyNotificationTime == null
            ? l.taskFormModeDaily
            : l.detailReminderDaily(
                _task.dailyNotificationTime!.format(context),
              ),
      NotificationType.specificTime =>
        _task.notificationTime == null
            ? l.detailReminderAtTime
            : _full(_task.notificationTime!),
    };
  }

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

  String _full(DateTime value) =>
      DateFormat('EEE, d MMM y · h:mm a').format(value);

  Color _accent() {
    if (_task.isCompleted) return const Color(0xFF10B981);
    if (_task.isOverdue) return Colors.red.shade500;
    if (_task.isActive) return const Color(0xFF2563EB);
    return const Color(0xFFF59E0B);
  }

  String _status() {
    final l = L.of(context);
    if (_task.isCompleted) return l.detailStatusCompleted;
    if (_task.isOverdue) return l.detailStatusOverdue;
    if (_task.isActive) return l.detailStatusInProgress;
    return l.detailStatusNotStarted;
  }
}
