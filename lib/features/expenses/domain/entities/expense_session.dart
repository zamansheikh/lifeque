import 'package:equatable/equatable.dart';
import 'expense_item.dart';

class ExpenseSession extends Equatable {
  final String id;
  final String title; // e.g., "market 1"
  final DateTime date;
  final List<ExpenseItem> items;
  final String? notes;
  final DateTime createdAt;

  const ExpenseSession({
    required this.id,
    required this.title,
    required this.date,
    required this.items,
    this.notes,
    required this.createdAt,
  });

  ExpenseSession copyWith({
    String? id,
    String? title,
    DateTime? date,
    List<ExpenseItem>? items,
    String? notes,
    DateTime? createdAt,
    bool clearNotes = false,
  }) {
    return ExpenseSession(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      items: items ?? this.items,
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Calculate total amount of all items
  double get totalAmount {
    return items.fold(0.0, (sum, item) => sum + item.amount);
  }

  // Calculate total amount of purchased items
  double get purchasedAmount {
    return items
        .where((item) => item.isPurchased)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Calculate total amount of missed/unpurchased items
  double get missedAmount {
    return items
        .where((item) => !item.isPurchased)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // Get purchased items count
  int get purchasedCount {
    return items.where((item) => item.isPurchased).length;
  }

  // Get missed items count
  int get missedCount {
    return items.where((item) => !item.isPurchased).length;
  }

  // Check if this session is in the same month/year as given date
  bool isSameMonth(DateTime other) {
    return date.year == other.year && date.month == other.month;
  }

  @override
  List<Object?> get props => [id, title, date, items, notes, createdAt];
}
