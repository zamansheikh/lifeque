import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/usecases/todo_usecases.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/services/notification_service.dart';

part 'todo_event.dart';
part 'todo_state.dart';

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final GetAllTodos getAllTodos;
  final AddTodo addTodo;
  final UpdateTodo updateTodo;
  final DeleteTodo deleteTodo;
  final CompleteTodo completeTodo;
  final UncompleteTodo uncompleteTodo;
  final GetTodosByCategory getTodosByCategory;
  final SearchTodos searchTodos;
  final GetCompletedTodos getCompletedTodos;
  final GetPendingTodos getPendingTodos;
  final GetOverdueTodos getOverdueTodos;
  final GetTodosDueToday getTodosDueToday;
  final NotificationService notificationService;
  // Held directly (rather than behind a use case) only so reminder syncing
  // has something to read the full list from.
  final TodoRepository todoRepository;

  TodoBloc({
    required this.getAllTodos,
    required this.addTodo,
    required this.updateTodo,
    required this.deleteTodo,
    required this.completeTodo,
    required this.uncompleteTodo,
    required this.getTodosByCategory,
    required this.searchTodos,
    required this.getCompletedTodos,
    required this.getPendingTodos,
    required this.getOverdueTodos,
    required this.getTodosDueToday,
    required this.notificationService,
    required this.todoRepository,
  }) : super(TodoInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<AddTodoEvent>(_onAddTodo);
    on<UpdateTodoEvent>(_onUpdateTodo);
    on<DeleteTodoEvent>(_onDeleteTodo);
    on<CompleteTodoEvent>(_onCompleteTodo);
    on<UncompleteTodoEvent>(_onUncompleteTodo);
    on<FilterTodosByCategory>(_onFilterByCategory);
    on<SearchTodosEvent>(_onSearchTodos);
    on<GetCompletedTodosEvent>(_onGetCompletedTodos);
    on<GetPendingTodosEvent>(_onGetPendingTodos);
    on<GetOverdueTodosEvent>(_onGetOverdueTodos);
    on<GetTodosDueTodayEvent>(_onGetTodosDueToday);
    on<ClearFilters>(_onClearFilters);
  }

  Future<void> _onLoadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    emit(TodoLoading());

    final result = await getAllTodos(NoParams());

    result.fold(
      (failure) => emit(const TodoError("Couldn't load your to-dos")),
      (todos) {
        emit(TodoLoaded(todos: todos));
        // Android drops pending alarms on reboot and on app upgrade, so every
        // load is a chance to put the reminders back.
        notificationService.syncTodoNotifications(todoRepository);
      },
    );
  }

  /// Emits the updated list, then a one-shot success state for the snackbar,
  /// then the list again.
  ///
  /// Without that third emit the page is left sitting on a non-list state and
  /// has to reload from scratch, which used to flash a spinner — and, briefly,
  /// an error message — after every single edit.
  void _settle(Emitter<TodoState> emit, TodoLoaded loaded, String message) {
    emit(loaded);
    emit(TodoOperationSuccess(message));
    emit(loaded);
  }

  Future<void> _onAddTodo(AddTodoEvent event, Emitter<TodoState> emit) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;

      final result = await addTodo(AddTodoParams(todo: event.todo));

      result.fold((failure) => emit(const TodoError("Couldn't save that")), (
        _,
      ) {
        final updatedTodos = List<Todo>.from(currentState.todos)
          ..add(event.todo);
        notificationService.scheduleTodoNotification(event.todo);
        _settle(
          emit,
          currentState.copyWith(todos: updatedTodos),
          'To-do added',
        );
      });
    }
  }

  Future<void> _onUpdateTodo(
    UpdateTodoEvent event,
    Emitter<TodoState> emit,
  ) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;

      final result = await updateTodo(UpdateTodoParams(todo: event.todo));

      result.fold((failure) => emit(const TodoError("Couldn't save that")), (
        _,
      ) {
        final updatedTodos = currentState.todos.map((todo) {
          return todo.id == event.todo.id ? event.todo : todo;
        }).toList();
        // Reschedules, moves or clears the reminder to match the new values —
        // scheduleTodoNotification cancels first, so all three cases are one
        // call.
        notificationService.scheduleTodoNotification(event.todo);
        _settle(
          emit,
          currentState.copyWith(todos: updatedTodos),
          'To-do updated',
        );
      });
    }
  }

  Future<void> _onDeleteTodo(
    DeleteTodoEvent event,
    Emitter<TodoState> emit,
  ) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;

      final result = await deleteTodo(DeleteTodoParams(id: event.id));

      result.fold((failure) => emit(const TodoError("Couldn't delete that")), (
        _,
      ) {
        final updatedTodos = currentState.todos
            .where((todo) => todo.id != event.id)
            .toList();
        notificationService.cancelTodoNotification(event.id);
        _settle(
          emit,
          currentState.copyWith(todos: updatedTodos),
          'To-do deleted',
        );
      });
    }
  }

  Future<void> _onCompleteTodo(
    CompleteTodoEvent event,
    Emitter<TodoState> emit,
  ) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;

      final result = await completeTodo(CompleteTodoParams(id: event.id));

      result.fold((failure) => emit(const TodoError("Couldn't update that")), (
        _,
      ) {
        final updatedTodos = currentState.todos.map((todo) {
          if (todo.id == event.id) {
            return todo.copyWith(
              isCompleted: true,
              completedAt: DateTime.now(),
            );
          }
          return todo;
        }).toList();
        // A finished to-do has no business buzzing later on.
        notificationService.cancelTodoNotification(event.id);
        _settle(emit, currentState.copyWith(todos: updatedTodos), 'Done');
      });
    }
  }

  Future<void> _onUncompleteTodo(
    UncompleteTodoEvent event,
    Emitter<TodoState> emit,
  ) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;

      final result = await uncompleteTodo(UncompleteTodoParams(id: event.id));

      result.fold((failure) => emit(const TodoError("Couldn't update that")), (
        _,
      ) {
        Todo? reopened;
        final updatedTodos = currentState.todos.map((todo) {
          if (todo.id == event.id) {
            reopened = todo.copyWith(isCompleted: false, completedAt: null);
            return reopened!;
          }
          return todo;
        }).toList();
        // Reopening puts the reminder back, if its time hasn't passed.
        if (reopened != null) {
          notificationService.scheduleTodoNotification(reopened!);
        }
        _settle(
          emit,
          currentState.copyWith(todos: updatedTodos),
          'Moved back to your list',
        );
      });
    }
  }

  Future<void> _onFilterByCategory(
    FilterTodosByCategory event,
    Emitter<TodoState> emit,
  ) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;

      final result = await getTodosByCategory(
        GetTodosByCategoryParams(category: event.category),
      );

      result.fold(
        (failure) => emit(const TodoError('Failed to filter todos')),
        (filteredTodos) => emit(
          currentState.copyWith(
            filteredTodos: filteredTodos,
            selectedCategory: event.category,
            isFiltered: true,
          ),
        ),
      );
    }
  }

  Future<void> _onSearchTodos(
    SearchTodosEvent event,
    Emitter<TodoState> emit,
  ) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;

      if (event.query.isEmpty) {
        emit(
          currentState.copyWith(
            filteredTodos: [],
            searchQuery: null,
            isFiltered: false,
            clearSearchQuery: true,
          ),
        );
        return;
      }

      final result = await searchTodos(SearchTodosParams(query: event.query));

      result.fold(
        (failure) => emit(const TodoError('Failed to search todos')),
        (searchResults) => emit(
          currentState.copyWith(
            filteredTodos: searchResults,
            searchQuery: event.query,
            isFiltered: true,
          ),
        ),
      );
    }
  }

  Future<void> _onGetCompletedTodos(
    GetCompletedTodosEvent event,
    Emitter<TodoState> emit,
  ) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;

      final result = await getCompletedTodos(NoParams());

      result.fold(
        (failure) => emit(const TodoError('Failed to get completed todos')),
        (completedTodos) => emit(
          currentState.copyWith(
            filteredTodos: completedTodos,
            isFiltered: true,
          ),
        ),
      );
    }
  }

  Future<void> _onGetPendingTodos(
    GetPendingTodosEvent event,
    Emitter<TodoState> emit,
  ) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;

      final result = await getPendingTodos(NoParams());

      result.fold(
        (failure) => emit(const TodoError('Failed to get pending todos')),
        (pendingTodos) => emit(
          currentState.copyWith(filteredTodos: pendingTodos, isFiltered: true),
        ),
      );
    }
  }

  Future<void> _onGetOverdueTodos(
    GetOverdueTodosEvent event,
    Emitter<TodoState> emit,
  ) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;

      final result = await getOverdueTodos(NoParams());

      result.fold(
        (failure) => emit(const TodoError('Failed to get overdue todos')),
        (overdueTodos) => emit(
          currentState.copyWith(filteredTodos: overdueTodos, isFiltered: true),
        ),
      );
    }
  }

  Future<void> _onGetTodosDueToday(
    GetTodosDueTodayEvent event,
    Emitter<TodoState> emit,
  ) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;

      final result = await getTodosDueToday(NoParams());

      result.fold(
        (failure) => emit(const TodoError('Failed to get todos due today')),
        (todayTodos) => emit(
          currentState.copyWith(filteredTodos: todayTodos, isFiltered: true),
        ),
      );
    }
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<TodoState> emit,
  ) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;
      emit(
        currentState.copyWith(
          filteredTodos: [],
          isFiltered: false,
          clearSearchQuery: true,
          clearCategory: true,
          clearPriority: true,
        ),
      );
    }
  }
}
