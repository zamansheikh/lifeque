import 'package:get_it/get_it.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/utils/database_helper.dart';
import 'core/services/notification_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/in_app_update_service.dart';
import 'features/tasks/data/datasources/task_local_data_source.dart';
import 'features/tasks/data/repositories/task_repository_impl.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'features/tasks/domain/usecases/get_all_tasks.dart';
import 'features/tasks/domain/usecases/get_active_tasks.dart';
import 'features/tasks/domain/usecases/add_task.dart';
import 'features/tasks/domain/usecases/update_task.dart';
import 'features/tasks/domain/usecases/delete_task.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/todos/data/datasources/todo_local_data_source.dart';
import 'features/todos/data/repositories/todo_repository_impl.dart';
import 'features/todos/domain/repositories/todo_repository.dart';
import 'features/todos/domain/usecases/todo_usecases.dart';
import 'features/todos/presentation/bloc/todo_bloc.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/notifications/data/repositories/notification_repository_impl.dart';
import 'features/medicines/data/datasources/medicine_local_data_source.dart';
import 'features/medicines/data/repositories/medicine_repository_impl.dart';
import 'features/medicines/domain/repositories/medicine_repository.dart';
import 'features/medicines/domain/usecases/get_medicines.dart';
import 'features/medicines/domain/usecases/manage_medicine.dart';
import 'features/medicines/domain/usecases/manage_doses.dart';
import 'features/medicines/presentation/bloc/medicine_cubit.dart';
import 'features/expenses/data/datasources/expense_local_data_source.dart';
import 'features/expenses/data/repositories/expense_repository_impl.dart';
import 'features/expenses/domain/repositories/expense_repository.dart';
import 'features/expenses/domain/usecases/expense_usecases.dart';
import 'features/expenses/presentation/bloc/expense_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Tasks
  // Bloc - Changed to singleton to maintain state for notification actions
  sl.registerLazySingleton(
    () => TaskBloc(
      getAllTasks: sl(),
      getActiveTasks: sl(),
      addTask: sl(),
      updateTask: sl(),
      deleteTask: sl(),
      notificationService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllTasks(sl()));
  sl.registerLazySingleton(() => GetActiveTasks(sl()));
  sl.registerLazySingleton(() => AddTask(sl()));
  sl.registerLazySingleton(() => UpdateTask(sl()));
  sl.registerLazySingleton(() => DeleteTask(sl()));

  // Repository
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(databaseHelper: sl()),
  );

  //! Features - Todos
  // Bloc
  sl.registerLazySingleton(
    () => TodoBloc(
      getAllTodos: sl(),
      addTodo: sl(),
      updateTodo: sl(),
      deleteTodo: sl(),
      completeTodo: sl(),
      uncompleteTodo: sl(),
      getTodosByCategory: sl(),
      searchTodos: sl(),
      getCompletedTodos: sl(),
      getPendingTodos: sl(),
      getOverdueTodos: sl(),
      getTodosDueToday: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllTodos(sl()));
  sl.registerLazySingleton(() => AddTodo(sl()));
  sl.registerLazySingleton(() => UpdateTodo(sl()));
  sl.registerLazySingleton(() => DeleteTodo(sl()));
  sl.registerLazySingleton(() => CompleteTodo(sl()));
  sl.registerLazySingleton(() => UncompleteTodo(sl()));
  sl.registerLazySingleton(() => GetTodosByCategory(sl()));
  sl.registerLazySingleton(() => SearchTodos(sl()));
  sl.registerLazySingleton(() => GetCompletedTodos(sl()));
  sl.registerLazySingleton(() => GetPendingTodos(sl()));
  sl.registerLazySingleton(() => GetOverdueTodos(sl()));
  sl.registerLazySingleton(() => GetTodosDueToday(sl()));

  // Repository
  sl.registerLazySingleton<TodoRepository>(
    () => TodoRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<TodoLocalDataSource>(
    () => TodoLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Medicines
  // Cubit
  sl.registerLazySingleton(
    () => MedicineCubit(
      getAllMedicinesUseCase: sl(),
      getActiveMedicinesUseCase: sl(),
      addMedicineUseCase: sl(),
      updateMedicineUseCase: sl(),
      deleteMedicineUseCase: sl(),
      getDosesForMedicineUseCase: sl(),
      getPendingDosesUseCase: sl(),
      markDoseAsTakenUseCase: sl(),
      markDoseAsSkippedUseCase: sl(),
      markDoseAsMissedUseCase: sl(),
      generateDosesForMedicineUseCase: sl(),
      getDosesForDateUseCase: sl(),
      notificationService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllMedicines(sl()));
  sl.registerLazySingleton(() => GetActiveMedicines(sl()));
  sl.registerLazySingleton(() => AddMedicine(sl()));
  sl.registerLazySingleton(() => UpdateMedicine(sl()));
  sl.registerLazySingleton(() => DeleteMedicine(sl()));
  sl.registerLazySingleton(() => GetDosesForMedicine(sl()));
  sl.registerLazySingleton(() => GetPendingDoses(sl()));
  sl.registerLazySingleton(() => MarkDoseAsTaken(sl()));
  sl.registerLazySingleton(() => MarkDoseAsSkipped(sl()));
  sl.registerLazySingleton(() => GenerateDosesForMedicine(sl()));
  sl.registerLazySingleton(() => MarkDoseAsMissed(sl()));
  sl.registerLazySingleton(() => GetDosesForDate(sl()));

  // Repository
  sl.registerLazySingleton<MedicineRepository>(
    () => MedicineRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<MedicineLocalDataSource>(
    () => MedicineLocalDataSourceImpl(databaseHelper: sl()),
  );

  //! Features - Expenses
  // Bloc
  sl.registerLazySingleton(
    () => ExpenseBloc(
      getAllSessions: sl(),
      getSessionById: sl(),
      addSession: sl(),
      updateSession: sl(),
      deleteSession: sl(),
      getSessionsByMonth: sl(),
      getMonthlyTotal: sl(),
      getMonthlyPurchasedTotal: sl(),
      getMonthlyMissedTotal: sl(),
      addItemToSession: sl(),
      updateItemInSession: sl(),
      deleteItemFromSession: sl(),
      toggleItemPurchased: sl(),
      getAllBudgets: sl(),
      getBudgetByMonth: sl(),
      setBudget: sl(),
      deleteBudget: sl(),
      getAllCategoryBudgets: sl(),
      getCategoryBudgetsForMonth: sl(),
      setCategoryBudget: sl(),
      deleteCategoryBudget: sl(),
      getYearlyExpenseSummary: sl(),
      searchSessions: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllSessions(sl()));
  sl.registerLazySingleton(() => GetSessionById(sl()));
  sl.registerLazySingleton(() => AddSession(sl()));
  sl.registerLazySingleton(() => UpdateSession(sl()));
  sl.registerLazySingleton(() => DeleteSession(sl()));
  sl.registerLazySingleton(() => GetSessionsByMonth(sl()));
  sl.registerLazySingleton(() => GetMonthlyTotal(sl()));
  sl.registerLazySingleton(() => GetMonthlyPurchasedTotal(sl()));
  sl.registerLazySingleton(() => GetMonthlyMissedTotal(sl()));
  sl.registerLazySingleton(() => AddItemToSession(sl()));
  sl.registerLazySingleton(() => UpdateItemInSession(sl()));
  sl.registerLazySingleton(() => DeleteItemFromSession(sl()));
  sl.registerLazySingleton(() => ToggleItemPurchased(sl()));
  sl.registerLazySingleton(() => GetAllBudgets(sl()));
  sl.registerLazySingleton(() => GetBudgetByMonth(sl()));
  sl.registerLazySingleton(() => SetBudget(sl()));
  sl.registerLazySingleton(() => DeleteBudget(sl()));
  sl.registerLazySingleton(() => GetAllCategoryBudgets(sl()));
  sl.registerLazySingleton(() => GetCategoryBudgetsForMonth(sl()));
  sl.registerLazySingleton(() => SetCategoryBudget(sl()));
  sl.registerLazySingleton(() => DeleteCategoryBudget(sl()));
  sl.registerLazySingleton(() => GetYearlyExpenseSummary(sl()));
  sl.registerLazySingleton(() => SearchSessions(sl()));

  // Repository
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ExpenseLocalDataSource>(
    () => ExpenseLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Notifications
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl()),
  );

  //! Core
  sl.registerLazySingleton(() => DatabaseHelper());
  sl.registerLazySingleton(() => FlutterLocalNotificationsPlugin());
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => NavigationService());
  sl.registerLazySingleton(() => InAppUpdateService());

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}
