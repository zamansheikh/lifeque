import '../../domain/entities/todo.dart';

class TodoModel extends Todo {
  const TodoModel({
    required super.id,
    required super.title,
    super.description,
    super.isCompleted = false,
    super.priority = TodoPriority.medium,
    super.category = TodoCategory.personal,
    required super.createdAt,
    super.dueDate,
    super.completedAt,
    super.tags = const [],
    super.reminderTime,
    super.hasReminder = false,
  });

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'] ?? false,
      priority:
          TodoPriority.values[json['priority'] ?? TodoPriority.medium.index],
      category:
          TodoCategory.values[json['category'] ?? TodoCategory.personal.index],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      tags: List<String>.from(json['tags'] ?? []),
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'])
          : null,
      hasReminder: json['hasReminder'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'priority': priority.index,
      'category': category.index,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'tags': tags,
      'reminderTime': reminderTime?.toIso8601String(),
      'hasReminder': hasReminder,
    };
  }

  factory TodoModel.fromEntity(Todo todo) {
    return TodoModel(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      isCompleted: todo.isCompleted,
      priority: todo.priority,
      category: todo.category,
      createdAt: todo.createdAt,
      dueDate: todo.dueDate,
      completedAt: todo.completedAt,
      tags: todo.tags,
      reminderTime: todo.reminderTime,
      hasReminder: todo.hasReminder,
    );
  }

  Todo toEntity() {
    return Todo(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted,
      priority: priority,
      category: category,
      createdAt: createdAt,
      dueDate: dueDate,
      completedAt: completedAt,
      tags: tags,
      reminderTime: reminderTime,
      hasReminder: hasReminder,
    );
  }

  @override
  TodoModel copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    TodoPriority? priority,
    TodoCategory? category,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
    List<String>? tags,
    DateTime? reminderTime,
    bool? hasReminder,
  }) {
    return TodoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
      reminderTime: reminderTime ?? this.reminderTime,
      hasReminder: hasReminder ?? this.hasReminder,
    );
  }
}
