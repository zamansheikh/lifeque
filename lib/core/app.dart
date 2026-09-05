import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../features/tasks/presentation/bloc/task_bloc.dart';
import '../features/tasks/presentation/pages/task_list_page.dart';
import '../features/tasks/presentation/pages/add_edit_task_page.dart';
import '../features/tasks/presentation/pages/task_detail_page.dart';
import '../features/todos/presentation/bloc/todo_bloc.dart';
import '../features/todos/presentation/pages/todo_list_page.dart';
import '../features/todos/presentation/pages/add_edit_todo_page.dart';
import '../features/todos/presentation/pages/todo_detail_page.dart';
import '../features/todos/domain/entities/todo.dart';
import '../features/medicines/presentation/bloc/medicine_cubit.dart';
import '../features/medicines/presentation/pages/medicines_dashboard_page.dart';
import '../features/medicines/presentation/pages/add_edit_medicine_page.dart';
import '../features/expenses/presentation/bloc/expense_bloc.dart';
import '../features/expenses/presentation/pages/expenses_dashboard_page.dart';
import '../features/expenses/presentation/pages/add_expense_session_page.dart';
import '../features/expenses/presentation/pages/expense_session_detail_page.dart';
import '../features/expenses/presentation/pages/set_budget_page.dart';
import '../features/expenses/domain/entities/monthly_budget.dart';
import '../features/expenses/domain/entities/category_budget.dart';
import '../features/expenses/domain/entities/expense_category.dart';
import '../features/expenses/domain/entities/expense_session.dart';
import '../features/prayer_times/presentation/pages/prayer_shell_page.dart';
import '../features/study/presentation/pages/study_timer_page.dart';
import '../features/permissions/presentation/pages/permission_screen.dart';
import '../features/splash/presentation/pages/splash_screen.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import 'services/navigation_service.dart';
import 'services/navigation_preferences_service.dart';
import 'services/in_app_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../injection_container.dart' as di;

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: NavigationService.navigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/permissions',
        name: 'permissions',
        builder: (context, state) => PermissionScreen(
          onPermissionsGranted: () {
            final svc = NavigationPreferencesService(
              di.sl<SharedPreferences>(),
            );
            context.go(svc.getHomeRoute());
          },
        ),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const TaskListPage(),
      ),
      GoRoute(
        path: '/medicines',
        name: 'medicines',
        builder: (context, state) => const MedicinesDashboardPage(),
      ),
      GoRoute(
        path: '/prayer-times',
        name: 'prayer-times',
        builder: (context, state) => const PrayerShellPage(),
      ),
      GoRoute(
        path: '/study-timer',
        name: 'study-timer',
        builder: (context, state) => const StudyTimerPage(),
      ),
      GoRoute(
        path: '/add-medicine',
        name: 'add-medicine',
        builder: (context, state) => const AddEditMedicinePage(),
      ),
      GoRoute(
        path: '/edit-medicine/:id',
        name: 'edit-medicine',
        builder: (context, state) {
          final medicineId = state.pathParameters['id']!;
          return AddEditMedicinePage(medicineId: medicineId);
        },
      ),
      GoRoute(
        path: '/add-task',
        name: 'add-task',
        builder: (context, state) => const AddEditTaskPage(),
      ),
      GoRoute(
        path: '/edit-task/:id',
        name: 'edit-task',
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return AddEditTaskPage(taskId: taskId);
        },
      ),
      GoRoute(
        path: '/task-detail/:id',
        name: 'task-detail',
        builder: (context, state) {
          final taskId = state.pathParameters['id']!;
          return TaskDetailPage(taskId: taskId);
        },
      ),
      GoRoute(
        path: '/todos',
        name: 'todos',
        builder: (context, state) => const TodoListPage(),
      ),
      GoRoute(
        path: '/todos/add',
        name: 'add-todo',
        builder: (context, state) => const AddEditTodoPage(),
      ),
      GoRoute(
        path: '/todos/edit',
        name: 'edit-todo',
        builder: (context, state) {
          final todo = state.extra as Todo;
          return AddEditTodoPage(todo: todo);
        },
      ),
      GoRoute(
        path: '/todos/detail',
        name: 'todo-detail',
        builder: (context, state) {
          final todo = state.extra as Todo;
          return TodoDetailPage(todo: todo);
        },
      ),
      GoRoute(
        path: '/expenses',
        name: 'expenses',
        builder: (context, state) => const ExpensesDashboardPage(),
      ),
      GoRoute(
        path: '/expenses/add',
        name: 'add-expense-session',
        builder: (context, state) => const AddExpenseSessionPage(),
      ),
      GoRoute(
        path: '/expenses/edit',
        name: 'edit-expense-session',
        builder: (context, state) {
          final session = state.extra as ExpenseSession;
          return AddExpenseSessionPage(session: session);
        },
      ),
      GoRoute(
        path: '/expenses/detail',
        name: 'expense-session-detail',
        builder: (context, state) {
          final session = state.extra as ExpenseSession;
          return ExpenseSessionDetailPage(session: session);
        },
      ),
      GoRoute(
        path: '/expenses/budget',
        name: 'set-budget',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Map<String, Object?>) {
            final selectedMonth = extra['selectedMonth'] as DateTime;
            final existingBudget = extra['existingBudget'] as MonthlyBudget?;
            final existingCategoryBudgets =
                (extra['existingCategoryBudgets'] as List<dynamic>? ?? [])
                    .map((e) => e as CategoryBudget)
                    .toList();
            final categorySpending =
                (extra['categorySpending'] as Map<String, double>?) ?? {};
            return SetBudgetPage(
              selectedMonth: selectedMonth,
              existingBudget: existingBudget,
              existingCategoryBudgets: existingCategoryBudgets,
              categorySpending: categorySpending,
            );
          }
          final selectedMonth = extra as DateTime;
          return SetBudgetPage(selectedMonth: selectedMonth);
        },
      ),
    ],
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configure status bar for light theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<TaskBloc>()..add(LoadTasks())),
        BlocProvider(create: (_) => di.sl<TodoBloc>()),
        BlocProvider(create: (_) => di.sl<MedicineCubit>()),
        BlocProvider(create: (_) => di.sl<ExpenseBloc>()..add(LoadSessions())),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'LifeQue',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          appBarTheme: const AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        ),
        builder: (context, child) {
          return UpdateChecker(
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
              child: child ?? const SizedBox(),
            ),
          );
        },
        routerConfig: AppRouter.router,
      ),
    );
  }
}

/// A wrapper widget that checks for in-app updates once when the app starts.
class UpdateChecker extends StatefulWidget {
  final Widget child;
  const UpdateChecker({super.key, required this.child});

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  @override
  void initState() {
    super.initState();
    _checkUpdates();
  }

  void _checkUpdates() {
    // Check for updates after a short delay once the app is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          InAppUpdateService.checkAndHandleUpdates(context);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
