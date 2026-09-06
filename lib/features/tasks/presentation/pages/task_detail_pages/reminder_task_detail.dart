import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/widgets/detail_kit.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/task.dart';
import '../../bloc/task_bloc.dart';
import '../../../../../core/utils/local_clock.dart';

/// A reminder's detail view. A reminder is a single moment, so the page is
/// mostly one question: how long until it goes off.
class ReminderTaskDetail extends StatefulWidget {
  final Task task;

  const ReminderTaskDetail({super.key, required this.task});

  @override
  State<ReminderTaskDetail> createState() => _ReminderTaskDetailState();
}

class _ReminderTaskDetailState extends State<ReminderTaskDetail> {
  Timer? _ticker;

  Task get _task => widget.task;

  /// A reminder stores its moment in `endDate`; `notificationTime` is the same
  /// instant when it was set through the form.
  DateTime get _at => _task.notificationTime ?? _task.endDate;

  @override
  void initState() {
    super.initState();
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
    final remaining = _at.difference(DateTime.now());
    final accent = _accent(remaining);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DetailHero(
          icon: Icons.notifications_active_rounded,
          accent: accent,
          status: _status(remaining),
          title: _task.title,
          subtitle: DateFormat('EEE, d MMM y · h:mm a').format(_at),
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
            title: l.detailSectionCountdown,
            icon: Icons.hourglass_bottom_rounded,
            accent: accent,
            children: [
              DetailCountdown(
                remaining: remaining,
                color: accent,
                caption: l.detailUntilItFires,
                passedLabel: l.detailAlreadyFired,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        DetailSection(
          title: l.detailSectionDetails,
          icon: Icons.info_outline_rounded,
          accent: Colors.grey.shade500,
          children: [
            DetailRow(
              icon: Icons.event_rounded,
              label: l.detailRowDate,
              value: DateFormat('EEEE, d MMMM y').format(_at),
            ),
            DetailRow(
              icon: Icons.schedule_rounded,
              label: l.detailRowTime,
              value: Clock.h12(_at),
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

  Color _accent(Duration remaining) {
    if (_task.isCompleted) return const Color(0xFF10B981);
    if (remaining.isNegative) return Colors.red.shade500;
    if (remaining.inHours < 1) return const Color(0xFFEA580C);
    return const Color(0xFFF59E0B);
  }

  String _status(Duration remaining) {
    final l = L.of(context);
    if (_task.isCompleted) return l.detailStatusDone;
    if (remaining.isNegative) return l.detailStatusPassed;
    if (remaining.inMinutes < 60) return l.detailStatusAnyMinute;
    return l.detailStatusWaiting;
  }
}
