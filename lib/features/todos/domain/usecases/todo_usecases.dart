import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

class GetAllTodos implements UseCase<List<Todo>, NoParams> {
  final TodoRepository repository;

  GetAllTodos(this.repository);

  @override
  Future<Either<Failure, List<Todo>>> call(NoParams params) async {
    return await repository.getAllTodos();
  }
}

class GetTodoById implements UseCase<Todo, GetTodoByIdParams> {
  final TodoRepository repository;

  GetTodoById(this.repository);

  @override
  Future<Either<Failure, Todo>> call(GetTodoByIdParams params) async {
    return await repository.getTodoById(params.id);
  }
}

class AddTodo implements UseCase<void, AddTodoParams> {
  final TodoRepository repository;

  AddTodo(this.repository);

  @override
  Future<Either<Failure, void>> call(AddTodoParams params) async {
    return await repository.addTodo(params.todo);
  }
}

class UpdateTodo implements UseCase<void, UpdateTodoParams> {
  final TodoRepository repository;

  UpdateTodo(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateTodoParams params) async {
    return await repository.updateTodo(params.todo);
  }
}

class DeleteTodo implements UseCase<void, DeleteTodoParams> {
  final TodoRepository repository;

  DeleteTodo(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteTodoParams params) async {
    return await repository.deleteTodo(params.id);
  }
}

class CompleteTodo implements UseCase<void, CompleteTodoParams> {
  final TodoRepository repository;

  CompleteTodo(this.repository);

  @override
  Future<Either<Failure, void>> call(CompleteTodoParams params) async {
    return await repository.completeTodo(params.id);
  }
}

class UncompleteTodo implements UseCase<void, UncompleteTodoParams> {
  final TodoRepository repository;

  UncompleteTodo(this.repository);

  @override
  Future<Either<Failure, void>> call(UncompleteTodoParams params) async {
    return await repository.uncompleteTodo(params.id);
  }
}

class GetTodosByCategory
    implements UseCase<List<Todo>, GetTodosByCategoryParams> {
  final TodoRepository repository;

  GetTodosByCategory(this.repository);

  @override
  Future<Either<Failure, List<Todo>>> call(
    GetTodosByCategoryParams params,
  ) async {
    return await repository.getTodosByCategory(params.category);
  }
}

class SearchTodos implements UseCase<List<Todo>, SearchTodosParams> {
  final TodoRepository repository;

  SearchTodos(this.repository);

  @override
  Future<Either<Failure, List<Todo>>> call(SearchTodosParams params) async {
    return await repository.searchTodos(params.query);
  }
}

class GetPendingTodos implements UseCase<List<Todo>, NoParams> {
  final TodoRepository repository;

  GetPendingTodos(this.repository);

  @override
  Future<Either<Failure, List<Todo>>> call(NoParams params) async {
    return await repository.getPendingTodos();
  }
}

class GetCompletedTodos implements UseCase<List<Todo>, NoParams> {
  final TodoRepository repository;

  GetCompletedTodos(this.repository);

  @override
  Future<Either<Failure, List<Todo>>> call(NoParams params) async {
    return await repository.getCompletedTodos();
  }
}

class GetOverdueTodos implements UseCase<List<Todo>, NoParams> {
  final TodoRepository repository;

  GetOverdueTodos(this.repository);

  @override
  Future<Either<Failure, List<Todo>>> call(NoParams params) async {
    return await repository.getOverdueTodos();
  }
}

class GetTodosDueToday implements UseCase<List<Todo>, NoParams> {
  final TodoRepository repository;

  GetTodosDueToday(this.repository);

  @override
  Future<Either<Failure, List<Todo>>> call(NoParams params) async {
    return await repository.getTodosDueToday();
  }
}

// Parameter classes
class GetTodoByIdParams extends Equatable {
  final String id;

  const GetTodoByIdParams({required this.id});

  @override
  List<Object> get props => [id];
}

class AddTodoParams extends Equatable {
  final Todo todo;

  const AddTodoParams({required this.todo});

  @override
  List<Object> get props => [todo];
}

class UpdateTodoParams extends Equatable {
  final Todo todo;

  const UpdateTodoParams({required this.todo});

  @override
  List<Object> get props => [todo];
}

class DeleteTodoParams extends Equatable {
  final String id;

  const DeleteTodoParams({required this.id});

  @override
  List<Object> get props => [id];
}

class CompleteTodoParams extends Equatable {
  final String id;

  const CompleteTodoParams({required this.id});

  @override
  List<Object> get props => [id];
}

class UncompleteTodoParams extends Equatable {
  final String id;

  const UncompleteTodoParams({required this.id});

  @override
  List<Object> get props => [id];
}

class GetTodosByCategoryParams extends Equatable {
  final TodoCategory category;

  const GetTodosByCategoryParams({required this.category});

  @override
  List<Object> get props => [category];
}

class SearchTodosParams extends Equatable {
  final String query;

  const SearchTodosParams({required this.query});

  @override
  List<Object> get props => [query];
}
