import 'package:equatable/equatable.dart';
import 'expense_category.dart';

class ExpenseItem extends Equatable {
  final String id;
  final String name;
  final double amount;
  final bool isPurchased;
  final DateTime? purchasedAt;
  final ExpenseCategory category;

  const ExpenseItem({
    required this.id,
    required this.name,
    required this.amount,
    this.isPurchased = false,
    this.purchasedAt,
    this.category = ExpenseCategory.uncategorized,
  });

  ExpenseItem copyWith({
    String? id,
    String? name,
    double? amount,
    bool? isPurchased,
    DateTime? purchasedAt,
    ExpenseCategory? category,
    bool clearPurchasedAt = false,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isPurchased: isPurchased ?? this.isPurchased,
      purchasedAt: clearPurchasedAt ? null : (purchasedAt ?? this.purchasedAt),
      category: category ?? this.category,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    amount,
    isPurchased,
    purchasedAt,
    category,
  ];
}
