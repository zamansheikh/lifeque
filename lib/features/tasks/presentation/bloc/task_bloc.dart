import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart' as task_entity;
import '../../domain/usecases/get_all_tasks.dart';
import '../../domain/usecases/get_active_tasks.dart';
import '../../domain/usecases/add_task.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/services/notification_service.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetAllTasks getAllTasks;
  final GetActiveTasks getActiveTasks;
  final AddTask addTask;
  final UpdateTask updateTask;
  final DeleteTask deleteTask;
  final NotificationService notificationService;

  TaskBloc({
    required this.getAllTasks,
    required this.getActiveTasks,
    required this.addTask,
    required this.updateTask,
    required this.deleteTask,
    required this.notificationService,
  }) : super(TaskInitial()) {
    on<LoadTasks>(_onLoadTasks);
    on<LoadActiveTasks>(_onLoadActiveTasks);
    on<AddTaskEvent>(_onAddTask);
    on<UpdateTaskEvent>(_onUpdateTask);
    on<DeleteTaskEvent>(_onDeleteTask);
    on<ToggleTaskCompletion>(_onToggleTaskCompletion);
  }

  Future<void> _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    final result = await getAllTasks(const NoParams());
    result.fold((failure) => emit(TaskError(failure.toString())), (tasks) {
      emit(TaskLoaded(tasks));
      // Update active tasks and start real-time notification updates
      notificationService.updateActiveTasks(tasks);
      notificationService.startRealTimeUpdates(tasks);
      // Force immediate update of notifications
      notificationService.forceUpdateNotifications();
    });
  }

  Future<void> _onLoadActiveTasks(
    LoadActiveTasks event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    final result = await getActiveTasks(const NoParams());
    result.fold(
      (failure) => emit(TaskError(failure.toString())),
      (tasks) => emit(TaskLoaded(tasks)),
    );
  }

  Future<void> _onAddTask(AddTaskEvent event, Emitter<TaskState> emit) async {
    emit(TaskLoading());
    final result = await addTask(AddTaskParams(task: event.task));
    result.fold((failure) => emit(TaskError(failure.toString())), (_) async {
      // Schedule notification for the new task
      await notificationService.scheduleTaskNotification(event.task);
      add(LoadTasks()); // Reload tasks after adding
    });
  }

  Future<void> _onUpdateTask(
    UpdateTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());
    final result = await updateTask(UpdateTaskParams(task: event.task));
    result.fold((failure) => emit(TaskError(failure.toString())), (_) async {
      // Update notification for the task
      if (event.task.isCompleted) {
        await notificationService.cancelTaskNotification(event.task);
      } else {
        await notificationService.scheduleTaskNotification(event.task);
      }
      add(LoadTasks()); // Reload tasks after updating
    });
  }

  Future<void> _onDeleteTask(
    DeleteTaskEvent event,
    Emitter<TaskState> emit,
  ) async {
    emit(TaskLoading());

    // Get the task before deleting to cancel its notification
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      final task = currentState.tasks.firstWhere(
        (task) => task.id == event.taskId,
        orElse: () => throw Exception('Task not found'),
      );
      await notificationService.cancelTaskNotification(task);
    }

    final result = await deleteTask(DeleteTaskParams(id: event.taskId));
    result.fold((failure) => emit(TaskError(failure.toString())), (_) {
      add(LoadTasks()); // Reload tasks after deleting
    });
  }

  Future<void> _onToggleTaskCompletion(
    ToggleTaskCompletion event,
    Emitter<TaskState> emit,
  ) async {
    if (state is TaskLoaded) {
      final currentState = state as TaskLoaded;
      final tasks = currentState.tasks;
      final taskIndex = tasks.indexWhere((task) => task.id == event.taskId);

      if (taskIndex != -1) {
        final task = tasks[taskIndex];
        final updatedTask = task.copyWith(
          isCompleted: !task.isCompleted,
          updatedAt: DateTime.now(),
        );
        add(UpdateTaskEvent(updatedTask));
      }
    }
  }
}
