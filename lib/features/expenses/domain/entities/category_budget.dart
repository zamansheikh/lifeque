import 'package:equatable/equatable.dart';
import 'expense_category.dart';

class CategoryBudget extends Equatable {
  final String id;
  final int year;
  final int month;
  final ExpenseCategory category;
  final double budgetAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryBudget({
    required this.id,
    required this.year,
    required this.month,
    required this.category,
    required this.budgetAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  CategoryBudget copyWith({
    String? id,
    int? year,
    int? month,
    ExpenseCategory? category,
    double? budgetAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryBudget(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      category: category ?? this.category,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate progress (0.0 to 1.0+)
  double getProgress(double spent) {
    if (budgetAmount <= 0) return 0.0;
    return spent / budgetAmount;
  }

  // Check if over budget
  bool isOverBudget(double spent) {
    return spent > budgetAmount;
  }

  // Get remaining budget
  double getRemaining(double spent) {
    return budgetAmount - spent;
  }

  // Get percentage spent
  int getPercentageSpent(double spent) {
    return (getProgress(spent) * 100).round();
  }

  // Check if this budget is for the same month/year as given date
  bool isSameMonth(DateTime date) {
    return year == date.year && month == date.month;
  }

  // Get a descriptive display name
  String get displayName {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${category.displayName} - ${months[month - 1]} $year';
  }

  @override
  List<Object?> get props => [
    id,
    year,
    month,
    category,
    budgetAmount,
    createdAt,
    updatedAt,
  ];
}
