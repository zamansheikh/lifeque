import 'package:sqflite/sqflite.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../../../../core/utils/database_helper.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getAllTasks();
  Future<TaskModel> getTaskById(String id);
  Future<void> insertTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<List<TaskModel>> getTasksByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<TaskModel>> getActiveTasks();
  Future<List<TaskModel>> getCompletedTasks();
  Future<List<TaskModel>> getOverdueTasks();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final DatabaseHelper databaseHelper;

  TaskLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<TaskModel>> getAllTasks() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableTask,
        orderBy: '${DatabaseHelper.columnEndDate} ASC',
      );
      return maps.map((map) => TaskModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get all tasks: $e');
    }
  }

  @override
  Future<TaskModel> getTaskById(String id) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableTask,
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        throw app_exceptions.DatabaseException('Task with id $id not found');
      }

      return TaskModel.fromMap(maps.first);
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get task by id: $e');
    }
  }

  @override
  Future<void> insertTask(TaskModel task) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseHelper.tableTask,
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to insert task: $e');
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      final db = await databaseHelper.database;
      final result = await db.update(
        DatabaseHelper.tableTask,
        task.toMap(),
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [task.id],
      );

      if (result == 0) {
        throw app_exceptions.DatabaseException(
          'Task with id ${task.id} not found for update',
        );
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update task: $e');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      final db = await databaseHelper.database;
      final result = await db.delete(
        DatabaseHelper.tableTask,
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [id],
      );

      if (result == 0) {
        throw app_exceptions.DatabaseException(
          'Task with id $id not found for deletion',
        );
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete task: $e');
    }
  }

  @override
  Future<List<TaskModel>> getTasksByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableTask,
        where:
            '${DatabaseHelper.columnStartDate} >= ? AND ${DatabaseHelper.columnEndDate} <= ?',
        whereArgs: [
          startDate.millisecondsSinceEpoch,
          endDate.millisecondsSinceEpoch,
        ],
        orderBy: '${DatabaseHelper.columnEndDate} ASC',
      );
      return maps.map((map) => TaskModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get tasks by date range: $e',
      );
    }
  }

  @override
  Future<List<TaskModel>> getActiveTasks() async {
    try {
      final db = await databaseHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final maps = await db.query(
        DatabaseHelper.tableTask,
        where:
            '${DatabaseHelper.columnStartDate} <= ? AND ${DatabaseHelper.columnEndDate} > ? AND ${DatabaseHelper.columnIsCompleted} = 0',
        whereArgs: [now, now],
        orderBy: '${DatabaseHelper.columnEndDate} ASC',
      );
      return maps.map((map) => TaskModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get active tasks: $e');
    }
  }

  @override
  Future<List<TaskModel>> getCompletedTasks() async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseHelper.tableTask,
        where: '${DatabaseHelper.columnIsCompleted} = 1',
        orderBy: '${DatabaseHelper.columnEndDate} DESC',
      );
      return maps.map((map) => TaskModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get completed tasks: $e',
      );
    }
  }

  @override
  Future<List<TaskModel>> getOverdueTasks() async {
    try {
      final db = await databaseHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final maps = await db.query(
        DatabaseHelper.tableTask,
        where:
            '${DatabaseHelper.columnEndDate} < ? AND ${DatabaseHelper.columnIsCompleted} = 0',
        whereArgs: [now],
        orderBy: '${DatabaseHelper.columnEndDate} ASC',
      );
      return maps.map((map) => TaskModel.fromMap(map)).toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get overdue tasks: $e');
    }
  }
}
