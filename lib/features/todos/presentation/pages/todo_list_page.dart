import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../domain/entities/todo.dart';
import '../bloc/todo_bloc.dart';
import '../widgets/todo_card.dart';

/// The to-do list.
///
/// Filtering happens here, over the list the bloc already holds, rather than
/// by asking the repository for a different list each time. That makes the
/// status filter, the category filter and the search box *combine* — before,
/// picking a category silently threw away the status filter and vice versa —
/// and it makes every one of them instant.
class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

enum _StatusFilter { open, today, upcoming, done }

extension on _StatusFilter {
  String get label => switch (this) {
    _StatusFilter.open => 'All',
    _StatusFilter.today => 'Today',
    _StatusFilter.upcoming => 'Upcoming',
    _StatusFilter.done => 'Done',
  };
}

class _TodoListPageState extends State<TodoListPage> {
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _brand = Color(0xFF2563EB);
  static const _brandLight = Color(0xFF3B82F6);
  static const _danger = Color(0xFFDC2626);

  final _searchController = TextEditingController();
  String _query = '';
  _StatusFilter _status = _StatusFilter.open;
  TodoCategory? _category;

  @override
  void initState() {
    super.initState();
    context.read<TodoBloc>().add(LoadTodos());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppDrawer(currentRoute: '/todos'),
      appBar: AppBar(
        title: const Text(
          'To Do List',
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
      body: BlocConsumer<TodoBloc, TodoState>(
        // A one-shot success state only drives the snackbar; the bloc settles
        // back onto the list itself, so there is no reload and no flicker.
        listenWhen: (previous, current) =>
            current is TodoError || current is TodoOperationSuccess,
        listener: (context, state) {
          if (state is TodoError) {
            _snack(state.message, _danger);
          } else if (state is TodoOperationSuccess) {
            _snack(state.message, const Color(0xFF059669));
          }
        },
        buildWhen: (previous, current) =>
            current is TodoLoaded ||
            current is TodoLoading ||
            current is TodoInitial,
        builder: (context, state) {
          if (state is! TodoLoaded) {
            return const Center(
              child: CircularProgressIndicator(color: _brand),
            );
          }

          final all = state.todos;
          if (all.isEmpty) return _firstRun();

          final visible = _apply(all);
          final sections = _sections(visible);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              _todayCard(all),
              const SizedBox(height: 14),
              _searchField(),
              const SizedBox(height: 12),
              _statusRow(all),
              const SizedBox(height: 8),
              _categoryRow(all),
              const SizedBox(height: 8),
              if (sections.isEmpty)
                _nothingHere()
              else
                for (final section in sections) ...[
                  _sectionHeader(
                    section.title,
                    section.todos.length,
                    section.color,
                  ),
                  for (final todo in section.todos)
                    TodoCard(
                      todo: todo,
                      showDueDate: section.showsDueDate,
                      onTap: () => context.push('/todos/detail', extra: todo),
                      onEdit: (t) => context.push('/todos/edit', extra: t),
                      onToggleComplete: _toggle,
                      onDelete: _confirmDelete,
                    ),
                  const SizedBox(height: 6),
                ],
            ],
          );
        },
      ),
      // Only ever one way to add on screen: the empty state owns the call to
      // action until there is a list for the button to sit beside.
      floatingActionButton: BlocBuilder<TodoBloc, TodoState>(
        builder: (context, state) {
          if (state is! TodoLoaded || state.todos.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () => context.push('/todos/add'),
            backgroundColor: _brand,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'New to-do',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          );
        },
      ),
    );
  }

  // ── Filtering ──────────────────────────────────────────────────────────

  List<Todo> _apply(List<Todo> todos) {
    final q = _query.trim().toLowerCase();

    return todos.where((todo) {
      switch (_status) {
        case _StatusFilter.open:
          if (todo.isCompleted) return false;
        case _StatusFilter.today:
          if (todo.isCompleted) return false;
          if (!todo.isDueToday && !todo.isOverdue) return false;
        case _StatusFilter.upcoming:
          if (todo.isCompleted) return false;
          if (todo.dueDate == null) return false;
          if (todo.isDueToday || todo.isOverdue) return false;
        case _StatusFilter.done:
          if (!todo.isCompleted) return false;
      }

      if (_category != null && todo.category != _category) return false;

      if (q.isNotEmpty) {
        final haystack = [
          todo.title,
          todo.description ?? '',
          ...todo.tags,
        ].join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  /// Groups by when something is due, most pressing first, so the list reads
  /// as a plan for the day instead of an undifferentiated pile.
  List<_Section> _sections(List<Todo> todos) {
    if (_status == _StatusFilter.done) {
      final done = [...todos]
        ..sort((a, b) {
          final at = a.completedAt ?? a.createdAt;
          final bt = b.completedAt ?? b.createdAt;
          return bt.compareTo(at);
        });
      return done.isEmpty
          ? const []
          : [_Section('Completed', done, Colors.grey.shade500)];
    }

    final overdue = <Todo>[];
    final today = <Todo>[];
    final tomorrow = <Todo>[];
    final thisWeek = <Todo>[];
    final later = <Todo>[];
    final noDate = <Todo>[];

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    for (final todo in todos) {
      final due = todo.dueDate;
      if (due == null) {
        noDate.add(todo);
      } else if (todo.isOverdue) {
        overdue.add(todo);
      } else if (todo.isDueToday) {
        today.add(todo);
      } else if (todo.isDueTomorrow) {
        tomorrow.add(todo);
      } else if (DateTime(
            due.year,
            due.month,
            due.day,
          ).difference(startOfToday).inDays <=
          7) {
        thisWeek.add(todo);
      } else {
        later.add(todo);
      }
    }

    int byUrgency(Todo a, Todo b) {
      final byDate = (a.dueDate ?? a.createdAt).compareTo(
        b.dueDate ?? b.createdAt,
      );
      if (byDate != 0) return byDate;
      return b.priority.index.compareTo(a.priority.index);
    }

    int byPriority(Todo a, Todo b) =>
        b.priority.index.compareTo(a.priority.index);

    for (final bucket in [overdue, today, tomorrow, thisWeek, later]) {
      bucket.sort(byUrgency);
    }
    noDate.sort(byPriority);

    return [
      if (overdue.isNotEmpty) _Section('Overdue', overdue, _danger),
      if (today.isNotEmpty)
        _Section('Today', today, const Color(0xFFD97706), showsDueDate: false),
      if (tomorrow.isNotEmpty)
        _Section('Tomorrow', tomorrow, _brand, showsDueDate: false),
      if (thisWeek.isNotEmpty) _Section('This week', thisWeek, _brand),
      if (later.isNotEmpty) _Section('Later', later, _muted),
      if (noDate.isNotEmpty)
        _Section('No date', noDate, _muted, showsDueDate: false),
    ];
  }

  // ── Pieces ─────────────────────────────────────────────────────────────

  /// One honest number at the top: what today actually looks like.
  Widget _todayCard(List<Todo> all) {
    final dueToday = all.where((t) => t.isDueToday).toList();
    final doneToday = dueToday.where((t) => t.isCompleted).length;
    final overdue = all.where((t) => t.isOverdue).length;
    final open = all.where((t) => !t.isCompleted).length;
    final progress = dueToday.isEmpty ? 0.0 : doneToday / dueToday.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_brandLight, _brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: 0.28),
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
              Expanded(
                child: Text(
                  dueToday.isEmpty
                      ? (open == 0
                            ? 'Nothing left — enjoy it'
                            : '$open open, none due today')
                      : '$doneToday of ${dueToday.length} done today',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (overdue > 0)
                GestureDetector(
                  onTap: () => setState(() {
                    _status = _StatusFilter.today;
                    _category = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$overdue overdue',
                      style: const TextStyle(
                        color: _danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (dueToday.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search your to-dos',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search_rounded, color: _brand, size: 22),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                    FocusScope.of(context).unfocus();
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _statusRow(List<Todo> all) {
    int countFor(_StatusFilter filter) {
      final saved = _status;
      _status = filter;
      final n = _apply(all).length;
      _status = saved;
      return n;
    }

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _StatusFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = _StatusFilter.values[i];
          final selected = _status == filter;
          return _pill(
            label: '${filter.label} · ${countFor(filter)}',
            selected: selected,
            color: _brand,
            onTap: () => setState(() => _status = filter),
          );
        },
      ),
    );
  }

  /// Only the categories actually in use get a chip — an empty "Travel" filter
  /// is nothing but something else to read past.
  Widget _categoryRow(List<Todo> all) {
    final used = <TodoCategory>{for (final todo in all) todo.category}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    if (used.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: used.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return _pill(
              label: 'Any category',
              selected: _category == null,
              color: _muted,
              small: true,
              onTap: () => setState(() => _category = null),
            );
          }
          final category = used[i - 1];
          return _pill(
            label: category.displayName,
            icon: category.icon,
            selected: _category == category,
            color: category.color,
            small: true,
            onTap: () => setState(
              () => _category = _category == category ? null : category,
            ),
          );
        },
      ),
    );
  }

  Widget _pill({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
    IconData? icon,
    bool small = false,
  }) {
    return Material(
      color: selected ? color : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: small ? 11 : 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.grey.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: selected ? Colors.white : color),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: small ? 12 : 13,
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

  Widget _nothingHere() {
    final filtered = _query.isNotEmpty || _category != null;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(
            filtered ? Icons.search_off_rounded : Icons.check_circle_rounded,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            switch (_status) {
              _ when filtered => 'Nothing matched',
              _StatusFilter.done => 'Nothing finished yet',
              _StatusFilter.today => 'Nothing due today',
              _StatusFilter.upcoming => 'Nothing scheduled ahead',
              _StatusFilter.open => 'All clear',
            },
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? 'Try a different word, or clear the category filter.'
                : 'Nothing to do in this view.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _firstRun() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.checklist_rounded,
                size: 40,
                color: _brand,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your list is empty',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add something you need to get done. Give it a due date and a '
              'reminder, and the app will nudge you when it matters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/todos/add'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add your first to-do'),
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────

  void _toggle(Todo todo) {
    final bloc = context.read<TodoBloc>();
    if (todo.isCompleted) {
      bloc.add(UncompleteTodoEvent(todo.id));
    } else {
      bloc.add(CompleteTodoEvent(todo.id));
    }
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  void _confirmDelete(Todo todo) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete this to-do?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '“${todo.title}” and its reminder will be removed. '
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
              context.read<TodoBloc>().add(DeleteTodoEvent(todo.id));
              Navigator.of(dialogContext).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: _danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _Section {
  final String title;
  final List<Todo> todos;
  final Color color;

  /// False where the heading already says when things are due, so the cards
  /// don't repeat "Today" on every row under a "Today" heading.
  final bool showsDueDate;

  const _Section(
    this.title,
    this.todos,
    this.color, {
    this.showsDueDate = true,
  });
}
