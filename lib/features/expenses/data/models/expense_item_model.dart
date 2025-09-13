import '../../domain/entities/expense_item.dart';

class ExpenseItemModel extends ExpenseItem {
  const ExpenseItemModel({
    required super.id,
    required super.name,
    required super.amount,
    super.isPurchased = false,
    super.purchasedAt,
  });

  factory ExpenseItemModel.fromJson(Map<String, dynamic> json) {
    return ExpenseItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      isPurchased: json['isPurchased'] as bool? ?? false,
      purchasedAt: json['purchasedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['purchasedAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'isPurchased': isPurchased,
      'purchasedAt': purchasedAt?.millisecondsSinceEpoch,
    };
  }

  factory ExpenseItemModel.fromEntity(ExpenseItem item) {
    return ExpenseItemModel(
      id: item.id,
      name: item.name,
      amount: item.amount,
      isPurchased: item.isPurchased,
      purchasedAt: item.purchasedAt,
    );
  }

  ExpenseItem toEntity() {
    return ExpenseItem(
      id: id,
      name: name,
      amount: amount,
      isPurchased: isPurchased,
      purchasedAt: purchasedAt,
    );
  }

  @override
  ExpenseItemModel copyWith({
    String? id,
    String? name,
    double? amount,
    bool? isPurchased,
    DateTime? purchasedAt,
    bool clearPurchasedAt = false,
  }) {
    return ExpenseItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isPurchased: isPurchased ?? this.isPurchased,
      purchasedAt: clearPurchasedAt ? null : (purchasedAt ?? this.purchasedAt),
    );
  }
}
