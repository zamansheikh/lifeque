import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo_model.dart';

abstract class TodoLocalDataSource {
  Future<List<TodoModel>> getAllTodos();
  Future<TodoModel?> getTodoById(String id);
  Future<void> saveTodo(TodoModel todo);
  Future<void> deleteTodo(String id);
  Future<void> saveAllTodos(List<TodoModel> todos);
}

class TodoLocalDataSourceImpl implements TodoLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String todosKey = 'CACHED_TODOS';

  TodoLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<TodoModel>> getAllTodos() async {
    final jsonString = sharedPreferences.getString(todosKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((jsonItem) => TodoModel.fromJson(jsonItem)).toList();
    } else {
      return [];
    }
  }

  @override
  Future<TodoModel?> getTodoById(String id) async {
    final todos = await getAllTodos();
    try {
      return todos.firstWhere((todo) => todo.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveTodo(TodoModel todo) async {
    final todos = await getAllTodos();

    // Remove existing todo with same id if exists
    todos.removeWhere((existingTodo) => existingTodo.id == todo.id);

    // Add the new/updated todo
    todos.add(todo);

    await saveAllTodos(todos);
  }

  @override
  Future<void> deleteTodo(String id) async {
    final todos = await getAllTodos();
    todos.removeWhere((todo) => todo.id == id);
    await saveAllTodos(todos);
  }

  @override
  Future<void> saveAllTodos(List<TodoModel> todos) async {
    final jsonString = json.encode(todos.map((todo) => todo.toJson()).toList());
    await sharedPreferences.setString(todosKey, jsonString);
  }
}
