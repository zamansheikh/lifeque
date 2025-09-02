import 'package:get_it/get_it.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/utils/database_helper.dart';
import 'core/services/notification_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/backup_service.dart';
import 'features/tasks/data/datasources/task_local_data_source.dart';
import 'features/tasks/data/repositories/task_repository_impl.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'features/tasks/domain/usecases/get_all_tasks.dart';
import 'features/tasks/domain/usecases/get_active_tasks.dart';
import 'features/tasks/domain/usecases/add_task.dart';
import 'features/tasks/domain/usecases/update_task.dart';
import 'features/tasks/domain/usecases/delete_task.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/notifications/data/repositories/notification_repository_impl.dart';
import 'features/medicines/data/datasources/medicine_local_data_source.dart';
import 'features/medicines/data/repositories/medicine_repository_impl.dart';
import 'features/medicines/domain/repositories/medicine_repository.dart';
import 'features/medicines/domain/usecases/get_medicines.dart';
import 'features/medicines/domain/usecases/manage_medicine.dart';
import 'features/medicines/domain/usecases/manage_doses.dart';
import 'features/medicines/presentation/bloc/medicine_cubit.dart';

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

  //! Features - Notifications
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl()),
  );

  //! Core
  sl.registerLazySingleton(() => DatabaseHelper());
  sl.registerLazySingleton(() => FlutterLocalNotificationsPlugin());
  sl.registerLazySingleton(() => NotificationService());
  sl.registerLazySingleton(() => NavigationService());
  sl.registerLazySingleton(() => BackupService());
}
