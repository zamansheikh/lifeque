import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../features/tasks/presentation/bloc/task_bloc.dart';
import '../features/tasks/presentation/pages/task_list_page.dart';
import '../features/tasks/presentation/pages/add_edit_task_page.dart';
import '../features/tasks/presentation/pages/task_detail_page.dart';
import '../features/medicines/presentation/bloc/medicine_cubit.dart';
import '../features/medicines/presentation/pages/medicines_dashboard_page.dart';
import '../features/medicines/presentation/pages/add_edit_medicine_page.dart';
import '../features/prayer_times/presentation/pages/prayer_times_page.dart';
import '../features/study/presentation/pages/study_timer_page.dart';
import '../features/permissions/presentation/pages/permission_screen.dart';
import 'services/navigation_service.dart';
import '../injection_container.dart' as di;

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: NavigationService.navigatorKey,
    initialLocation: '/permissions',
    routes: [
      GoRoute(
        path: '/permissions',
        name: 'permissions',
        builder: (context, state) => PermissionScreen(
          onPermissionsGranted: () {
            context.go('/');
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
        builder: (context, state) => const PrayerTimesPage(),
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
        BlocProvider(create: (_) => di.sl<MedicineCubit>()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'RemindMe',
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
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: Colors.white,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
            child: child ?? const SizedBox(),
          );
        },
        routerConfig: AppRouter.router,
      ),
    );
  }
}
