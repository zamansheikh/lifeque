import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/todo.dart';

abstract class TodoRepository {
  /// Get all todos
  Future<Either<Failure, List<Todo>>> getAllTodos();

  /// Get todo by id
  Future<Either<Failure, Todo>> getTodoById(String id);

  /// Add a new todo
  Future<Either<Failure, void>> addTodo(Todo todo);

  /// Update an existing todo
  Future<Either<Failure, void>> updateTodo(Todo todo);

  /// Delete a todo
  Future<Either<Failure, void>> deleteTodo(String id);

  /// Mark todo as completed
  Future<Either<Failure, void>> completeTodo(String id);

  /// Mark todo as uncompleted
  Future<Either<Failure, void>> uncompleteTodo(String id);

  /// Get todos by category
  Future<Either<Failure, List<Todo>>> getTodosByCategory(TodoCategory category);

  /// Get todos by priority
  Future<Either<Failure, List<Todo>>> getTodosByPriority(TodoPriority priority);

  /// Get completed todos
  Future<Either<Failure, List<Todo>>> getCompletedTodos();

  /// Get pending todos
  Future<Either<Failure, List<Todo>>> getPendingTodos();

  /// Get overdue todos
  Future<Either<Failure, List<Todo>>> getOverdueTodos();

  /// Search todos by title or description
  Future<Either<Failure, List<Todo>>> searchTodos(String query);

  /// Get todos due today
  Future<Either<Failure, List<Todo>>> getTodosDueToday();

  /// Get todos due this week
  Future<Either<Failure, List<Todo>>> getTodosDueThisWeek();
}
