import 'package:equatable/equatable.dart';

class MonthlyBudget extends Equatable {
  final String id;
  final int year;
  final int month;
  final double targetAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MonthlyBudget({
    required this.id,
    required this.year,
    required this.month,
    required this.targetAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  MonthlyBudget copyWith({
    String? id,
    int? year,
    int? month,
    double? targetAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyBudget(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      targetAmount: targetAmount ?? this.targetAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get the month name
  String get monthName {
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
    return months[month - 1];
  }

  // Get a descriptive display name
  String get displayName {
    return '$monthName $year';
  }

  // Check if this budget is for the same month/year as given date
  bool isSameMonth(DateTime date) {
    return year == date.year && month == date.month;
  }

  @override
  List<Object?> get props => [
    id,
    year,
    month,
    targetAmount,
    createdAt,
    updatedAt,
  ];
}
