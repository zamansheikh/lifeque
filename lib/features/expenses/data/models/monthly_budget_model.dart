import '../../domain/entities/monthly_budget.dart';

class MonthlyBudgetModel extends MonthlyBudget {
  const MonthlyBudgetModel({
    required super.id,
    required super.year,
    required super.month,
    required super.targetAmount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MonthlyBudgetModel.fromJson(Map<String, dynamic> json) {
    return MonthlyBudgetModel(
      id: json['id'] as String,
      year: json['year'] as int,
      month: json['month'] as int,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'targetAmount': targetAmount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory MonthlyBudgetModel.fromEntity(MonthlyBudget budget) {
    return MonthlyBudgetModel(
      id: budget.id,
      year: budget.year,
      month: budget.month,
      targetAmount: budget.targetAmount,
      createdAt: budget.createdAt,
      updatedAt: budget.updatedAt,
    );
  }

  MonthlyBudget toEntity() {
    return MonthlyBudget(
      id: id,
      year: year,
      month: month,
      targetAmount: targetAmount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  MonthlyBudgetModel copyWith({
    String? id,
    int? year,
    int? month,
    double? targetAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyBudgetModel(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      targetAmount: targetAmount ?? this.targetAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
