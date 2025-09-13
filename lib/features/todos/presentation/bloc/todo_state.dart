part of 'todo_bloc.dart';

abstract class TodoState extends Equatable {
  const TodoState();

  @override
  List<Object?> get props => [];
}

class TodoInitial extends TodoState {}

class TodoLoading extends TodoState {}

class TodoLoaded extends TodoState {
  final List<Todo> todos;
  final List<Todo> filteredTodos;
  final String? searchQuery;
  final TodoCategory? selectedCategory;
  final TodoPriority? selectedPriority;
  final bool isFiltered;

  const TodoLoaded({
    required this.todos,
    this.filteredTodos = const [],
    this.searchQuery,
    this.selectedCategory,
    this.selectedPriority,
    this.isFiltered = false,
  });

  TodoLoaded copyWith({
    List<Todo>? todos,
    List<Todo>? filteredTodos,
    String? searchQuery,
    TodoCategory? selectedCategory,
    TodoPriority? selectedPriority,
    bool? isFiltered,
    bool clearSearchQuery = false,
    bool clearCategory = false,
    bool clearPriority = false,
  }) {
    return TodoLoaded(
      todos: todos ?? this.todos,
      filteredTodos: filteredTodos ?? this.filteredTodos,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      selectedCategory: clearCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      selectedPriority: clearPriority
          ? null
          : (selectedPriority ?? this.selectedPriority),
      isFiltered: isFiltered ?? this.isFiltered,
    );
  }

  List<Todo> get displayTodos => isFiltered ? filteredTodos : todos;

  @override
  List<Object?> get props => [
    todos,
    filteredTodos,
    searchQuery,
    selectedCategory,
    selectedPriority,
    isFiltered,
  ];
}

class TodoError extends TodoState {
  final String message;

  const TodoError(this.message);

  @override
  List<Object> get props => [message];
}

class TodoOperationSuccess extends TodoState {
  final String message;

  const TodoOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
