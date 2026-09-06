import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/detail_kit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/todo.dart';
import '../bloc/todo_bloc.dart';
import '../utils/todo_l10n.dart';
import '../../../../core/utils/local_clock.dart';

/// A to-do's detail view.
///
/// The old page was seven stacked white boxes — completion, title,
/// description, category, priority, due date, dates — each with its own
/// heading, so the screen was mostly labels. This is a hero and three
/// sections, built from the same kit as the task, reminder and birthday
/// pages.
class TodoDetailPage extends StatelessWidget {
  final Todo todo;

  const TodoDetailPage({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    // The route hands over a snapshot taken when the row was tapped. Ticking
    // the box goes through the bloc, so read the live copy back out — this
    // page used to pop itself after a toggle purely to avoid showing stale
    // values.
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        final live = state is TodoLoaded
            ? (state.todos.where((t) => t.id == todo.id).firstOrNull ?? todo)
            : todo;
        return _build(context, live);
      },
    );
  }

  Widget _build(BuildContext context, Todo todo) {
    final accent = _accent(todo);
    final l = L.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l.todoDetailTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: l.commonEdit,
            icon: const Icon(Icons.edit_rounded, size: 21),
            onPressed: () => context.push('/todos/edit', extra: todo),
          ),
          PopupMenuButton<String>(
            tooltip: l.commonMore,
            onSelected: (value) {
              if (value == 'delete') _showDeleteConfirmation(context, todo);
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l.commonDelete,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DetailHero(
              icon: todo.category.icon,
              accent: accent,
              status: _status(context, todo),
              title: todo.title,
              subtitle: todo.dueDate == null
                  ? null
                  : '${l.todoRowDue} ${_friendly(context, todo.dueDate!)}',
              description: todo.description,
              isDone: todo.isCompleted,
              action: DetailCheckCircle(
                checked: todo.isCompleted,
                accent: accent,
                onTap: () => context.read<TodoBloc>().add(
                  todo.isCompleted
                      ? UncompleteTodoEvent(todo.id)
                      : CompleteTodoEvent(todo.id),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DetailSection(
              title: l.detailSectionAbout,
              icon: Icons.label_outline_rounded,
              accent: accent,
              children: [
                DetailRow(
                  icon: todo.category.icon,
                  label: l.todoRowCategory,
                  value: todo.category.labelFor(context),
                ),
                DetailRow(
                  icon: todo.priority.icon,
                  label: l.todoRowPriority,
                  value: todo.priority.labelFor(context),
                  valueColor: todo.priority.color,
                ),
                if (todo.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final tag in todo.tags) _tagChip(tag, accent),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            DetailSection(
              title: l.detailSectionWhen,
              icon: Icons.event_rounded,
              accent: const Color(0xFF2563EB),
              children: [
                DetailRow(
                  icon: Icons.flag_rounded,
                  label: l.todoRowDue,
                  value: todo.dueDate == null
                      ? l.todoRowNoDue
                      : _friendly(context, todo.dueDate!),
                  valueColor: todo.isOverdue ? Colors.red.shade500 : null,
                ),
                DetailRow(
                  icon: todo.hasReminder
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  label: l.todoRowReminder,
                  value: !todo.hasReminder || todo.reminderTime == null
                      ? l.commonOff
                      : _friendly(context, todo.reminderTime!),
                ),
                DetailRow(
                  icon: Icons.add_circle_outline_rounded,
                  label: l.todoRowCreated,
                  value: _friendly(context, todo.createdAt),
                ),
                if (todo.completedAt != null)
                  DetailRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: l.todoRowCompleted,
                    value: _friendly(context, todo.completedAt!),
                    valueColor: const Color(0xFF059669),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagChip(String tag, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }

  Color _accent(Todo todo) {
    if (todo.isCompleted) return const Color(0xFF10B981);
    if (todo.isOverdue) return Colors.red.shade500;
    return todo.priority.color;
  }

  String _status(BuildContext context, Todo todo) {
    final l = L.of(context);
    if (todo.isCompleted) return l.todoStatusDone;
    if (todo.isOverdue) return l.todoStatusOverdue;
    if (todo.isDueToday) return l.todoStatusDueToday;
    if (todo.isDueTomorrow) return l.todoStatusDueTomorrow;
    return l.todoStatusPriority(todo.priority.labelFor(context));
  }

  /// "Today at 4:30 pm" where that reads better than a date, otherwise the
  /// date itself.
  String _friendly(BuildContext context, DateTime value) {
    final l = L.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(value.year, value.month, value.day);
    final time = Clock.h12(value);

    final difference = day.difference(today).inDays;
    final label = switch (difference) {
      0 => l.commonToday,
      1 => l.commonTomorrow,
      -1 => l.commonYesterday,
      _ => DateFormat(
        value.year == now.year ? 'EEE, d MMM' : 'd MMM y',
      ).format(value),
    };
    return l.todoAtTime(label, time);
  }

  void _showDeleteConfirmation(BuildContext context, Todo todo) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(L.of(context).todosDeleteTitle),
        content: Text(L.of(context).tasksDeleteBody(todo.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(L.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () {
              context.read<TodoBloc>().add(DeleteTodoEvent(todo.id));
              Navigator.of(dialogContext).pop();
              context.pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(L.of(context).commonDelete),
          ),
        ],
      ),
    );
  }
}
