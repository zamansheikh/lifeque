import '../../domain/entities/expense_session.dart';
import '../../domain/entities/expense_item.dart';
import 'expense_item_model.dart';

class ExpenseSessionModel extends ExpenseSession {
  const ExpenseSessionModel({
    required super.id,
    required super.title,
    required super.date,
    required super.items,
    super.notes,
    required super.createdAt,
  });

  factory ExpenseSessionModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSessionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      items: (json['items'] as List<dynamic>)
          .map(
            (itemJson) =>
                ExpenseItemModel.fromJson(itemJson as Map<String, dynamic>),
          )
          .toList(),
      notes: json['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.millisecondsSinceEpoch,
      'items': items
          .map((item) => ExpenseItemModel.fromEntity(item).toJson())
          .toList(),
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ExpenseSessionModel.fromEntity(ExpenseSession session) {
    return ExpenseSessionModel(
      id: session.id,
      title: session.title,
      date: session.date,
      items: session.items,
      notes: session.notes,
      createdAt: session.createdAt,
    );
  }

  ExpenseSession toEntity() {
    return ExpenseSession(
      id: id,
      title: title,
      date: date,
      items: items,
      notes: notes,
      createdAt: createdAt,
    );
  }

  @override
  ExpenseSessionModel copyWith({
    String? id,
    String? title,
    DateTime? date,
    List<ExpenseItem>? items,
    String? notes,
    DateTime? createdAt,
    bool clearNotes = false,
  }) {
    return ExpenseSessionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      items: items ?? this.items,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
