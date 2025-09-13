import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/todo_local_data_source.dart';
import '../models/todo_model.dart';

class TodoRepositoryImpl implements TodoRepository {
  final TodoLocalDataSource localDataSource;

  TodoRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Todo>>> getAllTodos() async {
    try {
      final todoModels = await localDataSource.getAllTodos();
      final todos = todoModels.map((model) => model.toEntity()).toList();
      return Right(todos);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Todo>> getTodoById(String id) async {
    try {
      final todoModel = await localDataSource.getTodoById(id);
      if (todoModel != null) {
        return Right(todoModel.toEntity());
      } else {
        return Left(CacheFailure());
      }
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addTodo(Todo todo) async {
    try {
      final todoModel = TodoModel.fromEntity(todo);
      await localDataSource.saveTodo(todoModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateTodo(Todo todo) async {
    try {
      final todoModel = TodoModel.fromEntity(todo);
      await localDataSource.saveTodo(todoModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteTodo(String id) async {
    try {
      await localDataSource.deleteTodo(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> completeTodo(String id) async {
    try {
      final todoModel = await localDataSource.getTodoById(id);
      if (todoModel != null) {
        final updatedTodo = todoModel.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        await localDataSource.saveTodo(updatedTodo);
        return const Right(null);
      } else {
        return Left(CacheFailure());
      }
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> uncompleteTodo(String id) async {
    try {
      final todoModel = await localDataSource.getTodoById(id);
      if (todoModel != null) {
        final updatedTodo = todoModel.copyWith(
          isCompleted: false,
          completedAt: null,
        );
        await localDataSource.saveTodo(updatedTodo);
        return const Right(null);
      } else {
        return Left(CacheFailure());
      }
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getTodosByCategory(
    TodoCategory category,
  ) async {
    try {
      final todoModels = await localDataSource.getAllTodos();
      final filteredTodos = todoModels
          .where((todo) => todo.category == category)
          .map((model) => model.toEntity())
          .toList();
      return Right(filteredTodos);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getTodosByPriority(
    TodoPriority priority,
  ) async {
    try {
      final todoModels = await localDataSource.getAllTodos();
      final filteredTodos = todoModels
          .where((todo) => todo.priority == priority)
          .map((model) => model.toEntity())
          .toList();
      return Right(filteredTodos);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getCompletedTodos() async {
    try {
      final todoModels = await localDataSource.getAllTodos();
      final completedTodos = todoModels
          .where((todo) => todo.isCompleted)
          .map((model) => model.toEntity())
          .toList();
      return Right(completedTodos);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getPendingTodos() async {
    try {
      final todoModels = await localDataSource.getAllTodos();
      final pendingTodos = todoModels
          .where((todo) => !todo.isCompleted)
          .map((model) => model.toEntity())
          .toList();
      return Right(pendingTodos);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getOverdueTodos() async {
    try {
      final todoModels = await localDataSource.getAllTodos();
      final now = DateTime.now();
      final overdueTodos = todoModels
          .where(
            (todo) =>
                !todo.isCompleted &&
                todo.dueDate != null &&
                now.isAfter(todo.dueDate!),
          )
          .map((model) => model.toEntity())
          .toList();
      return Right(overdueTodos);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> searchTodos(String query) async {
    try {
      final todoModels = await localDataSource.getAllTodos();
      final searchResults = todoModels
          .where(
            (todo) =>
                todo.title.toLowerCase().contains(query.toLowerCase()) ||
                (todo.description?.toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false),
          )
          .map((model) => model.toEntity())
          .toList();
      return Right(searchResults);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getTodosDueToday() async {
    try {
      final todoModels = await localDataSource.getAllTodos();
      final now = DateTime.now();
      final todayTodos = todoModels
          .where(
            (todo) =>
                todo.dueDate != null &&
                todo.dueDate!.year == now.year &&
                todo.dueDate!.month == now.month &&
                todo.dueDate!.day == now.day,
          )
          .map((model) => model.toEntity())
          .toList();
      return Right(todayTodos);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<Todo>>> getTodosDueThisWeek() async {
    try {
      final todoModels = await localDataSource.getAllTodos();
      final now = DateTime.now();
      final endOfWeek = now.add(Duration(days: 7 - now.weekday));
      final weekTodos = todoModels
          .where(
            (todo) =>
                todo.dueDate != null &&
                todo.dueDate!.isAfter(now) &&
                todo.dueDate!.isBefore(endOfWeek),
          )
          .map((model) => model.toEntity())
          .toList();
      return Right(weekTodos);
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}
