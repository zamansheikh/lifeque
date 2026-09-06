import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/todo.dart';
import '../utils/todo_l10n.dart';

/// A single to-do row.
///
/// The list groups by when things are due, so the card only spells out a due
/// date when the surrounding section doesn't already say it ([showDueDate]).
/// Priority is a colour stripe rather than a badge — it is a property of the
/// row, not another chip competing with the title for attention.
class TodoCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback? onTap;
  final ValueChanged<Todo>? onToggleComplete;
  final ValueChanged<Todo>? onEdit;
  final ValueChanged<Todo>? onDelete;
  final bool showDueDate;

  const TodoCard({
    super.key,
    required this.todo,
    this.onTap,
    this.onToggleComplete,
    this.onEdit,
    this.onDelete,
    this.showDueDate = true,
  });

  static const _ink = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final done = todo.isCompleted;
    final overdue = todo.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Priority, as a stripe you read without having to read.
                Container(
                  width: 4,
                  color: done
                      ? Colors.grey.withValues(alpha: 0.3)
                      : todo.priority.color,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
                    child: Row(
                      children: [
                        _checkbox(context, done),
                        const SizedBox(width: 12),
                        Expanded(child: _body(context, done, overdue)),
                        if (onEdit != null || onDelete != null) _menu(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkbox(BuildContext context, bool done) {
    return GestureDetector(
      onTap: () => onToggleComplete?.call(todo),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Padding rather than a bigger box: keeps the tap target comfortable
        // without pushing the title off-centre.
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? const Color(0xFF10B981) : Colors.transparent,
            border: Border.all(
              color: done ? const Color(0xFF10B981) : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  Widget _body(BuildContext context, bool done, bool overdue) {
    final description = todo.description?.trim();
    final showDue = showDueDate && todo.dueDate != null;
    final showReminder = todo.hasReminder && todo.reminderTime != null && !done;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          todo.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.25,
            color: done ? Colors.grey[500] : _ink,
            decoration: done ? TextDecoration.lineThrough : null,
          ),
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: done ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
        if (showDue || showReminder || !done) ...[
          const SizedBox(height: 7),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip(
                icon: todo.category.icon,
                label: todo.category.labelFor(context),
                color: todo.category.color,
              ),
              if (showDue)
                _chip(
                  icon: Icons.event_rounded,
                  label: _formatDueDate(todo.dueDate!),
                  color: overdue
                      ? const Color(0xFFDC2626)
                      : todo.isDueToday
                      ? const Color(0xFFD97706)
                      : Colors.grey.shade600,
                ),
              if (showReminder)
                _chip(
                  icon: Icons.notifications_active_rounded,
                  label: DateFormat('d MMM, HH:mm').format(todo.reminderTime!),
                  color: const Color(0xFF2563EB),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400], size: 20),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit') onEdit?.call(todo);
        if (value == 'delete') onDelete?.call(todo);
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          const PopupMenuItem<String>(
            value: 'edit',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 16, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Text('Edit', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem<String>(
            value: 'delete',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.delete_rounded, size: 16, color: Color(0xFFDC2626)),
                SizedBox(width: 10),
                Text(
                  'Delete',
                  style: TextStyle(fontSize: 13, color: Color(0xFFDC2626)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final days = due.difference(today).inDays;

    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days == -1) return 'Yesterday';
    if (days < 0) return '${days.abs()} days late';
    if (days < 7) return DateFormat('EEEE').format(dueDate);
    return DateFormat('d MMM').format(dueDate);
  }
}
