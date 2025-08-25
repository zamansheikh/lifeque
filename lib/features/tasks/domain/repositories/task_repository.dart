import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/task.dart' as task_entity;

abstract class TaskRepository {
  Future<Either<Failure, List<task_entity.Task>>> getAllTasks();
  Future<Either<Failure, task_entity.Task>> getTaskById(String id);
  Future<Either<Failure, void>> addTask(task_entity.Task task);
  Future<Either<Failure, void>> updateTask(task_entity.Task task);
  Future<Either<Failure, void>> deleteTask(String id);
  Future<Either<Failure, List<task_entity.Task>>> getTasksByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<Either<Failure, List<task_entity.Task>>> getActiveTasks();
  Future<Either<Failure, List<task_entity.Task>>> getCompletedTasks();
  Future<Either<Failure, List<task_entity.Task>>> getOverdueTasks();
}
