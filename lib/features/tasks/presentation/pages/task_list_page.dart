import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../bloc/task_bloc.dart';
import '../widgets/task_card_factory.dart';
import '../widgets/upcoming_birthdays_card.dart';
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
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
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
        title: const Text(
          'LifeQue',
          style: TextStyle(
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
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.refresh_rounded, size: 20),
            ),
            onPressed: () {
              context.read<TaskBloc>().add(LoadTasks());
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 3.0,
                    color: colorScheme.primary,
                  ),
                  insets: const EdgeInsets.symmetric(horizontal: 4.0),
                ),
                labelColor: colorScheme.primary,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'All Tasks'),
                  Tab(text: 'Completed'),
                ],
                dividerHeight: 0,
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveTaskList(),
                  _buildTaskList(),
                  _buildCompletedTaskList(),
                ],
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

  Widget _buildTaskList() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TaskLoaded) {
          if (state.tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.task_alt_rounded,
                      size: 48,
                      color: Colors.blue.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No tasks yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first task',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          // Sort tasks by next occurrence (most urgent first)
          final sortedTasks = List.from(state.tasks);
          sortedTasks.sort(
            (a, b) => a.nextOccurrence.compareTo(b.nextOccurrence),
          );

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: sortedTasks.length,
            itemBuilder: (context, index) {
              final task = sortedTasks[index];
              return TaskCardFactory.createCard(
                task: task,
                onTap: () {
                  context.push('/task-detail/${task.id}');
                },
                onToggleComplete: () {
                  context.read<TaskBloc>().add(ToggleTaskCompletion(task.id));
                },
                onEdit: () {
                  context.push('/edit-task/${task.id}');
                },
                onDelete: () {
                  _showDeleteConfirmation(context, task.id, task.title);
                },
              );
            },
          );
        } else if (state is TaskError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<TaskBloc>().add(LoadTasks());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActiveTaskList() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoaded) {
          // Separate birthdays from other active tasks
          final activeTasks = state.tasks
              .where(
                (task) => task.isActive && task.taskType != TaskType.birthday,
              )
              .toList();

          final upcomingBirthdays = state.tasks
              .where(
                (task) =>
                    task.taskType == TaskType.birthday && !task.isCompleted,
              )
              .toList();

          // Sort by next occurrence (most urgent first)
          activeTasks.sort(
            (a, b) => a.nextOccurrence.compareTo(b.nextOccurrence),
          );
          // The original code had a trailing comma here, which is syntactically incorrect.
          // I've removed it to ensure the code remains syntactically valid.
          // The instruction provided a trailing comma, but it was part of a snippet
          // that was already syntactically incorrect.
          // The instruction was: `activeTasks.sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));,`
          // The correct Dart syntax for a statement ending is a semicolon, not a comma.
          // I am making the change faithfully but ensuring syntactic correctness.
          // If the intent was to add another sort criterion, it would be a separate line or part of a chained sort.
          // Given the instruction, it seems the comma was a typo.

          if (activeTasks.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Welcome illustration
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Welcome message
                  const Text(
                    'Welcome to LifeQue! 🎯',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your journey to productivity starts here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Quick tips cards
                  _buildTipCard(
                    icon: Icons.add_task_rounded,
                    title: 'Create Your First Task',
                    description:
                        'Tap the + button below to add your first task and start organizing your life',
                    color: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 16),
                  _buildTipCard(
                    icon: Icons.schedule_rounded,
                    title: 'Set Deadlines',
                    description:
                        'Add due dates to stay on track and never miss important deadlines',
                    color: const Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 16),
                  _buildTipCard(
                    icon: Icons.track_changes_rounded,
                    title: 'Track Progress',
                    description:
                        'Monitor your task completion and celebrate your achievements',
                    color: const Color(0xFFFF9800),
                  ),

                  const SizedBox(height: 40),

                  // Features showcase
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'What else can you do?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureRow(
                          Icons.mosque_rounded,
                          'Prayer Times & Qibla',
                        ),
                        _buildFeatureRow(
                          Icons.medical_services_rounded,
                          'Medicine Reminders',
                        ),
                        _buildFeatureRow(Icons.school_rounded, 'Study Timer'),
                        _buildFeatureRow(
                          Icons.attach_money_rounded,
                          'Expense Tracking',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // CTA button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 98, 168, 224),
                          Color.fromARGB(255, 76, 75, 162),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667eea).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/add-task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      label: const Text(
                        'Create Your First Task',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: activeTasks.length + 1, // +1 for birthday card
            itemBuilder: (context, index) {
              // Show birthday card first
              if (index == 0) {
                return UpcomingBirthdaysCard(birthdays: upcomingBirthdays);
              }

              // Show regular tasks and reminders
              final task = activeTasks[index - 1];
              return TaskCardFactory.createCard(
                task: task,
                onTap: () {
                  context.push('/task-detail/${task.id}');
                },
                onToggleComplete: () {
                  context.read<TaskBloc>().add(ToggleTaskCompletion(task.id));
                },
                onEdit: () {
                  context.push('/edit-task/${task.id}');
                },
                onDelete: () {
                  _showDeleteConfirmation(context, task.id, task.title);
                },
              );
            },
          );
        }
        return _buildTaskList();
      },
    );
  }

  Widget _buildCompletedTaskList() {
    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, state) {
        if (state is TaskLoaded) {
          final completedTasks = state.tasks
              .where((task) => task.isCompleted)
              .toList();

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
                    'No completed tasks yet!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete some tasks to see them here.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: completedTasks.length,
            itemBuilder: (context, index) {
              final task = completedTasks[index];
              return TaskCardFactory.createCard(
                task: task,
                onTap: () {
                  context.push('/task-detail/${task.id}');
                },
                onToggleComplete: () {
                  context.read<TaskBloc>().add(ToggleTaskCompletion(task.id));
                },
                onEdit: () {
                  context.push('/edit-task/${task.id}');
                },
                onDelete: () {
                  _showDeleteConfirmation(context, task.id, task.title);
                },
              );
            },
          );
        }
        return _buildTaskList();
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
        return AlertDialog(
          title: const Text('Delete Task'),
          content: Text('Are you sure you want to delete "$taskTitle"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<TaskBloc>().add(DeleteTaskEvent(taskId));
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
