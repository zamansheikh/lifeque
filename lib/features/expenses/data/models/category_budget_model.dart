import '../../domain/entities/category_budget.dart';
import '../../domain/entities/expense_category.dart';

class CategoryBudgetModel extends CategoryBudget {
  const CategoryBudgetModel({
    required super.id,
    required super.year,
    required super.month,
    required super.category,
    required super.budgetAmount,
    required super.createdAt,
    required super.updatedAt,
    super.customCategoryName,
  });

  factory CategoryBudgetModel.fromJson(Map<String, dynamic> json) {
    return CategoryBudgetModel(
      id: json['id'] as String,
      year: json['year'] as int,
      month: json['month'] as int,
      category: ExpenseCategory.fromString(json['category'] as String),
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
      customCategoryName: json['customCategoryName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'category': category.name,
      'budgetAmount': budgetAmount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'customCategoryName': customCategoryName,
    };
  }

  factory CategoryBudgetModel.fromEntity(CategoryBudget budget) {
    return CategoryBudgetModel(
      id: budget.id,
      year: budget.year,
      month: budget.month,
      category: budget.category,
      budgetAmount: budget.budgetAmount,
      createdAt: budget.createdAt,
      updatedAt: budget.updatedAt,
      customCategoryName: budget.customCategoryName,
    );
  }

  CategoryBudget toEntity() {
    return CategoryBudget(
      id: id,
      year: year,
      month: month,
      category: category,
      budgetAmount: budgetAmount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      customCategoryName: customCategoryName,
    );
  }

  @override
  CategoryBudgetModel copyWith({
    String? id,
    int? year,
    int? month,
    ExpenseCategory? category,
    double? budgetAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customCategoryName,
    bool clearCustomCategory = false,
  }) {
    return CategoryBudgetModel(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      category: category ?? this.category,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customCategoryName: clearCustomCategory
          ? null
          : (customCategoryName ?? this.customCategoryName),
    );
  }
}
