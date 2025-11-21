import 'package:flutter/material.dart';

enum ExpenseCategory {
  food,
  transport,
  utilities,
  entertainment,
  healthcare,
  education,
  shopping,
  groceries,
  bills,
  other,
  uncategorized;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.healthcare:
        return 'Healthcare';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.groceries:
        return 'Groceries';
      case ExpenseCategory.bills:
        return 'Bills';
      case ExpenseCategory.other:
        return 'Other';
      case ExpenseCategory.uncategorized:
        return 'Uncategorized';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.utilities:
        return Icons.lightbulb_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_rounded;
      case ExpenseCategory.healthcare:
        return Icons.local_hospital_rounded;
      case ExpenseCategory.education:
        return Icons.school_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.groceries:
        return Icons.shopping_cart_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.other:
        return Icons.more_horiz_rounded;
      case ExpenseCategory.uncategorized:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFFF6B6B); // Red
      case ExpenseCategory.transport:
        return const Color(0xFF4ECDC4); // Teal
      case ExpenseCategory.utilities:
        return const Color(0xFFFFA07A); // Light Salmon
      case ExpenseCategory.entertainment:
        return const Color(0xFFBA68C8); // Purple
      case ExpenseCategory.healthcare:
        return const Color(0xFF66BB6A); // Green
      case ExpenseCategory.education:
        return const Color(0xFF42A5F5); // Blue
      case ExpenseCategory.shopping:
        return const Color(0xFFFF7043); // Deep Orange
      case ExpenseCategory.groceries:
        return const Color(0xFF26A69A); // Teal Green
      case ExpenseCategory.bills:
        return const Color(0xFF78909C); // Blue Grey
      case ExpenseCategory.other:
        return const Color(0xFF9E9E9E); // Grey
      case ExpenseCategory.uncategorized:
        return const Color(0xFFBDBDBD); // Light Grey
    }
  }

  // Convert from string (for JSON deserialization)
  static ExpenseCategory fromString(String value) {
    try {
      return ExpenseCategory.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
      );
    } catch (e) {
      return ExpenseCategory.uncategorized;
    }
  }
}
