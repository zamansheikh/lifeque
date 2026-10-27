import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/local_clock.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/task.dart';
import '../utils/task_priority_ui.dart';

/// One simple item on the task list: a tick-circle, the title, and chips for
/// whatever it has — due time, reminder, priority, category. Ranged tasks
/// keep their own card with the progress bar.
class ItemCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const ItemCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  static const _ink = Color(0xFF1E293B);
  static const _danger = Color(0xFFDC2626);
  static const _done = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final done = task.isCompleted;
    final at = task.planDate;
    final overdue = !done && at != null && at.isBefore(DateTime.now());
    final due = task.dueDate;
    final reminder = task.reminderAt;

    final chips = <Widget>[
      if (at != null)
        _chip(
          icon: due != null
              ? Icons.event_rounded
              : Icons.notifications_active_rounded,
          label: itemWhen(context, at),
          color: overdue ? _danger : const Color(0xFF2563EB),
        ),
      // Both a due time and a separate reminder: show the reminder too.
      if (due != null && reminder != null && !_sameMinute(due, reminder))
        _chip(
          icon: Icons.notifications_active_rounded,
          label: itemWhen(context, reminder),
          color: const Color(0xFF7C3AED),
        ),
      if (task.repeats)
        _chip(
          icon: Icons.repeat_rounded,
          label: task.repeat.labelFor(context),
          color: const Color(0xFF0D9488),
        ),
      if (task.priority.stands)
        _chip(
          icon: Icons.flag_rounded,
          label: task.priority.labelFor(context),
          color: task.priority.color,
        ),
      if (task.category != null)
        _chip(
          icon: task.category!.icon,
          label: task.category!.labelFor(context),
          color: task.category!.color,
        ),
      if (task.isPinnedToNotification && !done)
        _chip(
          icon: Icons.push_pin_rounded,
          label: null,
          color: Colors.grey.shade600,
        ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: overdue
            ? Border.all(color: _danger.withValues(alpha: 0.35))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 0, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  key: Key('item-toggle-${task.id}'),
                  onPressed: onToggle,
                  tooltip: done ? l.itemMarkOpen : l.itemMarkDone,
                  icon: Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 24,
                    color: done
                        ? _done
                        : task.priority.stands
                        ? task.priority.color
                        : Colors.grey.shade400,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            color: done ? Colors.grey.shade500 : _ink,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if ((task.description ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            task.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (chips.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(spacing: 6, runSpacing: 6, children: chips),
                        ],
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                  onSelected: (v) => v == 'edit' ? onTap() : onDelete(),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l.commonEdit)),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        l.commonDelete,
                        style: const TextStyle(color: _danger),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String? label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static bool _sameMinute(DateTime a, DateTime b) =>
      a.difference(b).inMinutes.abs() < 1;
}

/// "আজ, সন্ধ্যা ৬:০০" / "Tomorrow, 9:00 AM" / "Fri 31 Oct, 6:00 PM".
String itemWhen(BuildContext context, DateTime at) {
  final l = L.of(context);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final label = switch (day.difference(today).inDays) {
    0 => l.commonToday,
    1 => l.commonTomorrow,
    -1 => l.commonYesterday,
    _ => DateFormat('EEE d MMM').format(at),
  };
  return '$label, ${Clock.h12(at)}';
}
