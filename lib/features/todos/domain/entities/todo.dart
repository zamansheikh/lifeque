import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TodoPriority { low, medium, high, urgent }

extension TodoPriorityExtension on TodoPriority {
  String get displayName {
    switch (this) {
      case TodoPriority.low:
        return 'Low';
      case TodoPriority.medium:
        return 'Medium';
      case TodoPriority.high:
        return 'High';
      case TodoPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case TodoPriority.low:
        return Colors.green;
      case TodoPriority.medium:
        return Colors.orange;
      case TodoPriority.high:
        return Colors.red;
      case TodoPriority.urgent:
        return Colors.deepPurple;
    }
  }

  IconData get icon {
    switch (this) {
      case TodoPriority.low:
        return Icons.keyboard_arrow_down_rounded;
      case TodoPriority.medium:
        return Icons.remove_rounded;
      case TodoPriority.high:
        return Icons.keyboard_arrow_up_rounded;
      case TodoPriority.urgent:
        return Icons.priority_high_rounded;
    }
  }
}

enum TodoCategory {
  personal,
  work,
  shopping,
  health,
  education,
  finance,
  travel,
  home,
  other,
}

extension TodoCategoryExtension on TodoCategory {
  String get displayName {
    switch (this) {
      case TodoCategory.personal:
        return 'Personal';
      case TodoCategory.work:
        return 'Work';
      case TodoCategory.shopping:
        return 'Shopping';
      case TodoCategory.health:
        return 'Health';
      case TodoCategory.education:
        return 'Education';
      case TodoCategory.finance:
        return 'Finance';
      case TodoCategory.travel:
        return 'Travel';
      case TodoCategory.home:
        return 'Home';
      case TodoCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case TodoCategory.personal:
        return Icons.person_rounded;
      case TodoCategory.work:
        return Icons.work_rounded;
      case TodoCategory.shopping:
        return Icons.shopping_bag_rounded;
      case TodoCategory.health:
        return Icons.health_and_safety_rounded;
      case TodoCategory.education:
        return Icons.school_rounded;
      case TodoCategory.finance:
        return Icons.account_balance_wallet_rounded;
      case TodoCategory.travel:
        return Icons.flight_rounded;
      case TodoCategory.home:
        return Icons.home_rounded;
      case TodoCategory.other:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case TodoCategory.personal:
        return Colors.blue;
      case TodoCategory.work:
        return Colors.indigo;
      case TodoCategory.shopping:
        return Colors.green;
      case TodoCategory.health:
        return Colors.red;
      case TodoCategory.education:
        return Colors.purple;
      case TodoCategory.finance:
        return Colors.amber;
      case TodoCategory.travel:
        return Colors.cyan;
      case TodoCategory.home:
        return Colors.brown;
      case TodoCategory.other:
        return Colors.grey;
    }
  }
}

class Todo extends Equatable {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final TodoPriority priority;
  final TodoCategory category;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final List<String> tags;
  final DateTime? reminderTime;
  final bool hasReminder;

  const Todo({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = TodoPriority.medium,
    this.category = TodoCategory.personal,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    this.tags = const [],
    this.reminderTime,
    this.hasReminder = false,
  });

  Todo copyWith({
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
    return Todo(
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

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final due = dueDate!;
    return now.year == due.year && now.month == due.month && now.day == due.day;
  }

  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final due = dueDate!;
    return tomorrow.year == due.year &&
        tomorrow.month == due.month &&
        tomorrow.day == due.day;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    isCompleted,
    priority,
    category,
    createdAt,
    dueDate,
    completedAt,
    tags,
    reminderTime,
    hasReminder,
  ];
}
