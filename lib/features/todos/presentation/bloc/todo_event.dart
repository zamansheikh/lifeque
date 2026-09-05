part of 'todo_bloc.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

class LoadTodos extends TodoEvent {}

class AddTodoEvent extends TodoEvent {
  final Todo todo;

  const AddTodoEvent(this.todo);

  @override
  List<Object> get props => [todo];
}

class UpdateTodoEvent extends TodoEvent {
  final Todo todo;

  const UpdateTodoEvent(this.todo);

  @override
  List<Object> get props => [todo];
}

class DeleteTodoEvent extends TodoEvent {
  final String id;

  const DeleteTodoEvent(this.id);

  @override
  List<Object> get props => [id];
}

class CompleteTodoEvent extends TodoEvent {
  final String id;

  const CompleteTodoEvent(this.id);

  @override
  List<Object> get props => [id];
}

class UncompleteTodoEvent extends TodoEvent {
  final String id;

  const UncompleteTodoEvent(this.id);

  @override
  List<Object> get props => [id];
}

class FilterTodosByCategory extends TodoEvent {
  final TodoCategory category;

  const FilterTodosByCategory(this.category);

  @override
  List<Object> get props => [category];
}

class FilterTodosByPriority extends TodoEvent {
  final TodoPriority priority;

  const FilterTodosByPriority(this.priority);

  @override
  List<Object> get props => [priority];
}

class SearchTodosEvent extends TodoEvent {
  final String query;

  const SearchTodosEvent(this.query);

  @override
  List<Object> get props => [query];
}

class GetCompletedTodosEvent extends TodoEvent {}

class GetPendingTodosEvent extends TodoEvent {}

class GetOverdueTodosEvent extends TodoEvent {}

class GetTodosDueTodayEvent extends TodoEvent {}

class ClearFilters extends TodoEvent {}
