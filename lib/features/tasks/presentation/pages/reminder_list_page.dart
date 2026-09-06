import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';

/// Reminders, on their own screen.
///
/// A reminder is a single nudge at a single time. In the task list it had to
/// borrow a task's vocabulary — progress, deadlines, being "active" — none of
/// which say anything about a thing that either has gone off or hasn't. Here
/// they are grouped by when they fire and nothing else.
class ReminderListPage extends StatefulWidget {
  const ReminderListPage({super.key});

  @override
  State<ReminderListPage> createState() => _ReminderListPageState();
}

class _ReminderListPageState extends State<ReminderListPage> {
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _amber = Color(0xFFD97706);
  static const _amberLight = Color(0xFFF59E0B);
  static const _danger = Color(0xFFDC2626);

  bool _showDone = false;

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(LoadTasks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      drawer: const AppDrawer(currentRoute: '/reminders'),
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: _ink,
          ),
        ),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: _muted),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      body: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          if (state is TaskLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _amber),
            );
          }
          if (state is TaskError) {
            return _message(
              icon: Icons.error_outline_rounded,
              title: 'Something went wrong',
              body: state.message,
              action: FilledButton.icon(
                onPressed: () => context.read<TaskBloc>().add(LoadTasks()),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(backgroundColor: _amber),
              ),
            );
          }
          if (state is! TaskLoaded) return const SizedBox.shrink();

          final all = state.tasks
              .where((t) => t.taskType == TaskType.reminder)
              .toList();

          if (all.isEmpty) {
            return _message(
              icon: Icons.notifications_active_rounded,
              title: 'No reminders set',
              body:
                  'Set one for anything you\'d rather not keep in your '
                  'head — a call to make, a bill to pay, a bin to put out.',
              action: FilledButton.icon(
                onPressed: _add,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Set a reminder'),
                style: FilledButton.styleFrom(backgroundColor: _amber),
              ),
            );
          }

          final sections = _sections(all);
          final doneCount = all.where((t) => t.isCompleted).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              _summary(all),
              const SizedBox(height: 16),
              if (sections.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Center(
                    child: Text(
                      'Nothing pending — everything here is done.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                )
              else
                for (final section in sections) ...[
                  _sectionHeader(
                    section.title,
                    section.items.length,
                    section.color,
                  ),
                  for (final task in section.items) _row(task),
                  const SizedBox(height: 6),
                ],
              if (doneCount > 0) ...[
                const SizedBox(height: 8),
                _doneToggle(doneCount),
                if (_showDone) ...[
                  const SizedBox(height: 10),
                  for (final task in _doneSorted(all)) _row(task),
                ],
              ],
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          final hasAny =
              state is TaskLoaded &&
              state.tasks.any((t) => t.taskType == TaskType.reminder);
          if (!hasAny) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _add,
            backgroundColor: _amber,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'New reminder',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          );
        },
      ),
    );
  }

  // ── Grouping ───────────────────────────────────────────────────────────

  List<_Section> _sections(List<Task> all) {
    final pending = all.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => a.endDate.compareTo(b.endDate));

    final missed = <Task>[];
    final today = <Task>[];
    final tomorrow = <Task>[];
    final later = <Task>[];

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    for (final task in pending) {
      final when = task.endDate;
      final day = DateTime(when.year, when.month, when.day);
      final days = day.difference(startOfToday).inDays;

      if (when.isBefore(now)) {
        missed.add(task);
      } else if (days == 0) {
        today.add(task);
      } else if (days == 1) {
        tomorrow.add(task);
      } else {
        later.add(task);
      }
    }

    return [
      if (missed.isNotEmpty) _Section('Missed', missed, _danger),
      if (today.isNotEmpty) _Section('Today', today, _amber),
      if (tomorrow.isNotEmpty) _Section('Tomorrow', tomorrow, _amber),
      if (later.isNotEmpty) _Section('Later', later, _muted),
    ];
  }

  List<Task> _doneSorted(List<Task> all) =>
      all.where((t) => t.isCompleted).toList()
        ..sort((a, b) => b.endDate.compareTo(a.endDate));

  // ── Pieces ─────────────────────────────────────────────────────────────

  Widget _summary(List<Task> all) {
    final now = DateTime.now();
    final pending = all.where((t) => !t.isCompleted).toList();
    final missed = pending.where((t) => t.endDate.isBefore(now)).length;
    final next = pending.where((t) => t.endDate.isAfter(now)).toList()
      ..sort((a, b) => a.endDate.compareTo(b.endDate));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_amberLight, _amber],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _amber.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 17,
              ),
              const SizedBox(width: 8),
              Text(
                next.isEmpty ? 'Nothing pending' : 'Next reminder',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (missed > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$missed missed',
                    style: const TextStyle(
                      color: _danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            next.isEmpty ? 'You\'re all caught up' : next.first.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          if (next.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${_formatDateTime(next.first.endDate)} · ${_relative(next.first.endDate)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(Task task) {
    final done = task.isCompleted;
    final missed = !done && task.endDate.isBefore(DateTime.now());

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
          onTap: () => context.push('/task-detail/${task.id}'),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: done
                      ? Colors.grey.withValues(alpha: 0.3)
                      : missed
                      ? _danger
                      : _amber,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.read<TaskBloc>().add(
                            ToggleTaskCompletion(task.id),
                          ),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done
                                    ? const Color(0xFF10B981)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: done
                                      ? const Color(0xFF10B981)
                                      : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: done
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
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
                                  height: 1.25,
                                  color: done ? Colors.grey[500] : _ink,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 12,
                                    color: missed ? _danger : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      _formatDateTime(task.endDate),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: missed
                                            ? _danger
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                  if (task.isPinnedToNotification) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.push_pin_rounded,
                                      size: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              context.push('/edit-reminder/${task.id}');
                            } else if (value == 'delete') {
                              _confirmDelete(task);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              height: 40,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: _amber,
                                  ),
                                  SizedBox(width: 10),
                                  Text('Edit', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              height: 40,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    size: 16,
                                    color: _danger,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  Widget _sectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Finished reminders are history, not a list to work through, so they stay
  /// folded away behind a count.
  Widget _doneToggle(int count) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _showDone = !_showDone),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 17,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$count done',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              Icon(
                _showDone
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                color: Colors.grey[500],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String body,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 40, color: _amber),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.45,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 24), action],
          ],
        ),
      ),
    );
  }

  // ── Actions & formatting ───────────────────────────────────────────────

  void _add() => context.push('/add-reminder');

  void _confirmDelete(Task task) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete this reminder?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '“${task.title}” will be removed and won\'t go off. '
          'This can\'t be undone.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () {
              context.read<TaskBloc>().add(DeleteTaskEvent(task.id));
              Navigator.of(dialogContext).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: _danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
    if (diff.isNegative) return 'overdue';
    if (diff.inMinutes < 60) return 'in ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'in ${diff.inHours} h';
    return 'in ${diff.inDays} d';
  }
}

class _Section {
  final String title;
  final List<Task> items;
  final Color color;

  const _Section(this.title, this.items, this.color);
}
