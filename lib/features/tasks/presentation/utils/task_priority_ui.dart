import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/task.dart';

/// Look and label of a priority, for anything a person reads.
extension TaskPriorityUi on TaskPriority {
  Color get color => switch (this) {
    TaskPriority.low => Colors.green,
    TaskPriority.normal => Colors.orange,
    TaskPriority.high => Colors.red,
    TaskPriority.urgent => Colors.deepPurple,
  };

  IconData get icon => switch (this) {
    TaskPriority.low => Icons.keyboard_arrow_down_rounded,
    TaskPriority.normal => Icons.remove_rounded,
    TaskPriority.high => Icons.keyboard_arrow_up_rounded,
    TaskPriority.urgent => Icons.priority_high_rounded,
  };

  String labelFor(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      TaskPriority.low => l.priorityLow,
      TaskPriority.normal => l.priorityMedium,
      TaskPriority.high => l.priorityHigh,
      TaskPriority.urgent => l.priorityUrgent,
    };
  }

  /// High and urgent are worth a flag on the card; the rest are not.
  bool get stands => this == TaskPriority.high || this == TaskPriority.urgent;
}

extension RepeatRuleUi on RepeatRule {
  String labelFor(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      RepeatRule.none => l.repeatNever,
      RepeatRule.daily => l.repeatDaily,
      RepeatRule.weekly => l.repeatWeekly,
      RepeatRule.monthly => l.repeatMonthly,
      RepeatRule.yearly => l.repeatYearly,
    };
  }
}

extension TaskCategoryUi on TaskCategory {
  IconData get icon => switch (this) {
    TaskCategory.personal => Icons.person_rounded,
    TaskCategory.work => Icons.work_rounded,
    TaskCategory.shopping => Icons.shopping_bag_rounded,
    TaskCategory.health => Icons.health_and_safety_rounded,
    TaskCategory.education => Icons.school_rounded,
    TaskCategory.finance => Icons.account_balance_wallet_rounded,
    TaskCategory.travel => Icons.flight_rounded,
    TaskCategory.home => Icons.home_rounded,
    TaskCategory.other => Icons.category_rounded,
  };

  Color get color => switch (this) {
    TaskCategory.personal => Colors.blue,
    TaskCategory.work => Colors.indigo,
    TaskCategory.shopping => Colors.green,
    TaskCategory.health => Colors.red,
    TaskCategory.education => Colors.purple,
    TaskCategory.finance => Colors.amber,
    TaskCategory.travel => Colors.cyan,
    TaskCategory.home => Colors.brown,
    TaskCategory.other => Colors.grey,
  };

  String labelFor(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      TaskCategory.personal => l.categoryPersonal,
      TaskCategory.work => l.categoryWork,
      TaskCategory.shopping => l.categoryShopping,
      TaskCategory.health => l.categoryHealth,
      TaskCategory.education => l.categoryEducation,
      TaskCategory.finance => l.categoryFinance,
      TaskCategory.travel => l.categoryTravel,
      TaskCategory.home => l.categoryHome,
      TaskCategory.other => l.categoryOther,
    };
  }
}
