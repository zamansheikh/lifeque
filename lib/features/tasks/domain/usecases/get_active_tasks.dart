import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/task.dart' as task_entity;
import '../repositories/task_repository.dart';

class GetActiveTasks implements UseCase<List<task_entity.Task>, NoParams> {
  final TaskRepository repository;

  GetActiveTasks(this.repository);

  @override
  Future<Either<Failure, List<task_entity.Task>>> call(NoParams params) async {
    return await repository.getActiveTasks();
  }
}
