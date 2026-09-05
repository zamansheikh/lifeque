import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_bloc.dart';

/// Birthdays, on their own screen.
///
/// They live in the task store as [TaskType.birthday] rows, but nothing about
/// them behaves like a task: they repeat forever, they are never "completed",
/// and what you want to know is who is next, not what is overdue. Mixed into
/// the task list they were noise in both directions, so they get their own
/// drawer entry and a layout built around the one question that matters —
/// whose birthday is coming up.
class BirthdayListPage extends StatefulWidget {
  const BirthdayListPage({super.key});

  @override
  State<BirthdayListPage> createState() => _BirthdayListPageState();
}

class _BirthdayListPageState extends State<BirthdayListPage> {
  static const _ink = Color(0xFF1E293B);
  static const _muted = Color(0xFF64748B);
  static const _pink = Color(0xFFDB2777);
  static const _pinkSoft = Color(0xFFF472B6);

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    context.read<TaskBloc>().add(LoadTasks());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FA),
      drawer: const AppDrawer(currentRoute: '/birthdays'),
      appBar: AppBar(
        title: const Text(
          'Birthdays',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: _ink,
          ),
        ),
        backgroundColor: Colors.white,
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
            return const Center(child: CircularProgressIndicator(color: _pink));
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
              ),
            );
          }
          if (state is! TaskLoaded) return const SizedBox.shrink();

          final all =
              state.tasks.where((t) => t.taskType == TaskType.birthday).toList()
                ..sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));

          if (all.isEmpty) {
            return _message(
              icon: Icons.cake_rounded,
              title: 'No birthdays saved',
              body:
                  'Add the people you keep meaning to wish and this page '
                  'will tell you who is next.',
              action: FilledButton.icon(
                onPressed: _addBirthday,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add a birthday'),
                style: FilledButton.styleFrom(backgroundColor: _pink),
              ),
            );
          }

          final q = _query.trim().toLowerCase();
          final visible = q.isEmpty
              ? all
              : all.where((t) => t.title.toLowerCase().contains(q)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              _nextUpCard(all.first),
              const SizedBox(height: 18),
              if (all.length > 4) ...[
                _searchField(),
                const SizedBox(height: 16),
              ],
              Text(
                q.isEmpty ? 'Everyone' : 'Matching “$_query”',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${visible.length} ${visible.length == 1 ? 'birthday' : 'birthdays'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'Nobody by that name',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                )
              else
                ...visible.map(_row),
            ],
          );
        },
      ),
      // The empty state already offers the one action worth taking, so the
      // button only appears once there is a list for it to sit beside.
      floatingActionButton: BlocBuilder<TaskBloc, TaskState>(
        builder: (context, state) {
          final hasAny =
              state is TaskLoaded &&
              state.tasks.any((t) => t.taskType == TaskType.birthday);
          if (!hasAny) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _addBirthday,
            backgroundColor: _pink,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add birthday',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          );
        },
      ),
    );
  }

  // ── Pieces ─────────────────────────────────────────────────────────────

  /// The whole point of the page: who is next, and how long you have.
  Widget _nextUpCard(Task birthday) {
    final days = _daysUntil(birthday);
    final age = _ageTurning(birthday);
    final when = days == 0
        ? 'Today'
        : days == 1
        ? 'Tomorrow'
        : 'In $days days';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_pinkSoft, _pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _pink.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cake_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                days == 0 ? 'Birthday today' : 'Next up',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            birthday.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              when,
              DateFormat('d MMMM').format(birthday.nextOccurrence),
              if (age != null) 'turning $age',
            ].join(' · '),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _heroButton(
                  icon: Icons.notifications_active_rounded,
                  label: birthday.isNotificationEnabled
                      ? 'Reminders on'
                      : 'Reminders off',
                  onTap: () => context.push('/edit-task/${birthday.id}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _heroButton(
                  icon: Icons.open_in_new_rounded,
                  label: 'Details',
                  onTap: () => context.push('/task-detail/${birthday.id}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
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
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by name',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search_rounded, color: _pink, size: 22),
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

  Widget _row(Task birthday) {
    final days = _daysUntil(birthday);
    final age = _ageTurning(birthday);
    final isToday = days == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isToday
            ? Border.all(color: _pink.withValues(alpha: 0.5), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/task-detail/${birthday.id}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _pink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _initial(birthday.title),
                    style: const TextStyle(
                      color: _pink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        birthday.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          DateFormat('d MMMM').format(birthday.nextOccurrence),
                          if (age != null) 'turns $age',
                        ].join(' · '),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isToday ? _pink : _pink.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isToday ? 'Today' : _shortCountdown(days),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isToday ? Colors.white : _pink,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      context.push('/edit-task/${birthday.id}');
                    } else if (value == 'delete') {
                      _confirmDelete(birthday);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      height: 40,
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 16, color: _pink),
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
                            color: Color(0xFFDC2626),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFDC2626),
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
                color: _pink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 40, color: _pink),
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

  // ── Helpers ────────────────────────────────────────────────────────────

  void _addBirthday() => context.push('/add-birthday');

  int _daysUntil(Task birthday) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next = birthday.nextOccurrence;
    return DateTime(next.year, next.month, next.day).difference(today).inDays;
  }

  /// The age they are about to turn, or null when the stored date carries no
  /// usable birth year (someone who only recorded the day and month).
  int? _ageTurning(Task birthday) {
    final born = birthday.endDate;
    final next = birthday.nextOccurrence;
    if (born.year >= DateTime.now().year) return null;
    final age = next.year - born.year;
    return age > 0 ? age : null;
  }

  String _shortCountdown(int days) {
    if (days == 1) return 'Tomorrow';
    if (days < 30) return 'in $days d';
    final months = (days / 30).round();
    return 'in $months mo';
  }

  String _initial(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  void _confirmDelete(Task birthday) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove this birthday?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '“${birthday.title}” and its reminders will be deleted. '
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
              context.read<TaskBloc>().add(DeleteTaskEvent(birthday.id));
              Navigator.of(dialogContext).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
