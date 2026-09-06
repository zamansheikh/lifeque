import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

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
  other;

  /// The name to put on screen, in the reader's language.
  String labelFor(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      ExpenseCategory.food => l.expCatFood,
      ExpenseCategory.transport => l.expCatTransport,
      ExpenseCategory.utilities => l.expCatUtilities,
      ExpenseCategory.entertainment => l.expCatEntertainment,
      ExpenseCategory.healthcare => l.expCatHealthcare,
      ExpenseCategory.education => l.expCatEducation,
      ExpenseCategory.shopping => l.expCatShopping,
      ExpenseCategory.groceries => l.expCatGroceries,
      ExpenseCategory.bills => l.expCatBills,
      ExpenseCategory.other => l.expCatOther,
    };
  }

  /// English name, for logs and other places with no context to read.
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
    }
  }

  // Convert from string (for JSON deserialization)
  // 'uncategorized' from old data maps to 'other' for backward compatibility
  static ExpenseCategory fromString(String value) {
    final lower = value.toLowerCase();
    if (lower == 'uncategorized') return ExpenseCategory.other;
    try {
      return ExpenseCategory.values.firstWhere((e) => e.name == lower);
    } catch (e) {
      return ExpenseCategory.other;
    }
  }
}
