import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/local_numbers.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/task_bloc.dart';
import '../utils/task_groups.dart';
import '../widgets/item_card.dart';
import '../widgets/task_card_factory.dart';
import '../../domain/entities/task.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: const AppDrawer(currentRoute: '/'),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          L.of(context).navTasks,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            key: const Key('tasks-search'),
            tooltip: L.of(context).searchTooltip,
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            tooltip: L.of(context).tasksMedicinesTooltip,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            onPressed: () {
              context.push('/medicines');
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            BlocBuilder<TaskBloc, TaskState>(builder: _buildTabs),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildOpenList(), _buildCompletedTaskList()],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            context.push('/add-task');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // ── Tabs ────────────────────────────────────────────────────────────────

  /// A pill segmented control carrying each tab's count.
  ///
  /// The counts are the point: "Active" alone gave no reason to look in the
  /// other two tabs, so a finished list read as an empty app.
  Widget _buildTabs(BuildContext context, TaskState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final tasks = state is TaskLoaded
        ? state.tasks.where(onTaskList).toList()
        : <Task>[];

    final l = L.of(context);
    final labels = [
      (l.tasksTabActive, tasks.where((t) => !t.isCompleted).length),
      (l.tasksTabDone, tasks.where((t) => t.isCompleted).length),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerHeight: 0,
        splashBorderRadius: BorderRadius.circular(10),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        tabs: [
          for (final (label, count) in labels)
            Tab(
              height: 36,
              text: count == 0 ? label : '$label  ${N.of(count)}',
            ),
        ],
      ),
    );
  }

  // ── List plumbing ───────────────────────────────────────────────────────

  Widget _card(Task task) {
    // Simple items get the compact card; work with a start and an end keeps
    // the card with the progress bar.
    if (task.isSimple) {
      return ItemCard(
        key: ValueKey(task.id),
        task: task,
        onTap: () => context.push('/edit-task/${task.id}'),
        onToggle: () {
          context.read<TaskBloc>().add(ToggleTaskCompletion(task.id));
          // A repeating item doesn't leave the list, it moves: say where to.
          if (task.repeats && !task.isCompleted) {
            final next = task.rolledForward(DateTime.now()).planDate!;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    L.of(context).repeatNext(itemWhen(context, next)),
                  ),
                ),
              );
          }
        },
        onDelete: () => _showDeleteConfirmation(context, task.id, task.title),
      );
    }
    return TaskCardFactory.createCard(
      task: task,
      onTap: () => context.push('/task-detail/${task.id}'),
      onToggleComplete: () =>
          context.read<TaskBloc>().add(ToggleTaskCompletion(task.id)),
      onEdit: () => context.push('/edit-task/${task.id}'),
      onDelete: () => _showDeleteConfirmation(context, task.id, task.title),
    );
  }

  /// Pull-to-refresh, which is also the only way to reload now that the app
  /// bar's refresh button is gone.
  Widget _refreshable(Widget child) {
    return RefreshIndicator(
      onRefresh: () async => context.read<TaskBloc>().add(LoadTasks()),
      child: child,
    );
  }

  /// Sections with a heading each, empty ones dropped.
  ///
  /// A flat list sorted by deadline made "due in an hour" and "due in March"
  /// look alike; the headings put a scale on it.
  Widget _groupedList(List<(String, List<Task>)> groups) {
    final children = <Widget>[];
    for (final (label, tasks) in groups) {
      if (tasks.isEmpty) continue;
      children.add(_sectionHeader(label, tasks.length));
      children.addAll(tasks.map(_card));
    }

    return _refreshable(
      ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: children,
      ),
    );
  }

  Widget _sectionHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            N.of(count),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Divider(height: 1, color: Colors.grey.shade200)),
        ],
      ),
    );
  }

  /// Open items, by when they matter.
  Widget _buildOpenList() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoading || state is TaskInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is TaskError) return _buildError(context, state.message);
        if (state is! TaskLoaded) return const SizedBox.shrink();

        final groups = groupOpen(state.tasks, DateTime.now());
        if (groups.values.every((g) => g.isEmpty)) {
          // Three different situations, and conflating them is what made
          // the old onboarding wall wrong: it greeted a returning user who
          // had simply finished everything with instructions for their
          // first task.
          //
          //   nothing at all      → brand new here, offer somewhere to go
          //   nothing on the list → they use the app for other things
          //   all of it finished  → they are on top of it
          if (state.tasks.isEmpty) return _buildFirstRun(context);
          return _buildEmptyActive(
            context,
            hasAnyTask: state.tasks.any(onTaskList),
          );
        }

        final l = L.of(context);
        return _groupedList([
          (l.tasksGroupOverdue, groups[TaskGroup.overdue]!),
          (l.tasksGroupDueToday, groups[TaskGroup.today]!),
          (l.tasksGroupNext7Days, groups[TaskGroup.week]!),
          (l.tasksGroupLater, groups[TaskGroup.later]!),
          (l.tasksGroupSomeday, groups[TaskGroup.someday]!),
        ]);
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<TaskBloc>().add(LoadTasks()),
            child: Text(L.of(context).commonRetry),
          ),
        ],
      ),
    );
  }

  /// What a brand-new install lands on.
  ///
  /// Onboarding hands over to this screen, so if it says nothing the app's
  /// first impression is a blank page. The answer isn't the wall of tip cards
  /// that used to live here — those explained the app at someone instead of
  /// letting them use it, and they came back every time the list emptied.
  /// These are four one-tap ways in, and they disappear for good the moment
  /// anything exists.
  Widget _buildFirstRun(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = L.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/icon/icon.png',
              height: 72,
              width: 72,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l.tasksFirstRunTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.tasksFirstRunBody,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        _startHere(
          icon: Icons.add_task_rounded,
          color: colorScheme.primary,
          title: l.tasksStartTask,
          subtitle: l.tasksStartTaskSub,
          onTap: () => context.push('/add-task'),
        ),
        _startHere(
          icon: Icons.mosque_rounded,
          color: const Color(0xFF0F8A5F),
          title: l.tasksStartPrayer,
          subtitle: l.tasksStartPrayerSub,
          onTap: () => context.push('/prayer-times'),
        ),
        _startHere(
          icon: Icons.cake_rounded,
          color: const Color(0xFFDB2777),
          title: l.tasksStartBirthday,
          subtitle: l.tasksStartBirthdaySub,
          onTap: () => context.push('/add-birthday'),
        ),
        _startHere(
          icon: Icons.notifications_active_rounded,
          color: const Color(0xFFD97706),
          title: l.tasksStartTodo,
          subtitle: l.tasksStartTodoSub,
          onTap: () => context.push('/add-reminder'),
        ),
      ],
    );
  }

  /// One tappable way in. A row that goes somewhere, not a card that talks.
  Widget _startHere({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The Active tab with nothing in it.
  ///
  /// This used to be a scrolling wall of onboarding — a welcome banner, three
  /// tip cards, a "what else can you do?" feature list and a call to action —
  /// shown every single time somebody cleared their list, not just on the
  /// first run. One line about the state you are actually in is more use.
  Widget _buildEmptyActive(BuildContext context, {required bool hasAnyTask}) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = L.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 0, 36, 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: hasAnyTask
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                hasAnyTask
                    ? Icons.check_circle_rounded
                    : Icons.task_alt_rounded,
                size: 40,
                color: hasAnyTask
                    ? const Color(0xFF059669)
                    : colorScheme.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              hasAnyTask ? l.tasksAllDoneTitle : l.tasksEmptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasAnyTask ? l.tasksAllDoneBody : l.tasksEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 18),
            // No button here on purpose: the + is already on screen, and two
            // ways to do the same thing a thumb apart is one too many.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  l.tasksTapPlus,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedTaskList() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoaded) {
          final completedTasks = doneItems(state.tasks);

          if (completedTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 48,
                      color: Colors.green.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    L.of(context).tasksNoCompletedTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    L.of(context).tasksNoCompletedBody,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return _groupedList([
            (L.of(context).tasksGroupCompleted, completedTasks),
          ]);
        }
        if (state is TaskError) return _buildError(context, state.message);
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String taskId,
    String taskTitle,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l = L.of(context);
        return AlertDialog(
          title: Text(l.tasksDeleteTitle),
          content: Text(l.tasksDeleteBody(taskTitle)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l.commonCancel),
            ),
            TextButton(
              onPressed: () {
                context.read<TaskBloc>().add(DeleteTaskEvent(taskId));
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l.commonDelete),
            ),
          ],
        );
      },
    );
  }
}
