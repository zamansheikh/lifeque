import 'package:flutter/widgets.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/todo.dart';

/// Translated names for the to-do enums.
///
/// The entity's own `displayName` stays English: it is a plain getter with no
/// `BuildContext`, and it is what the stored data and any debug output use.
/// Anything a person reads goes through these instead.
extension TodoPriorityL10n on TodoPriority {
  String labelFor(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      TodoPriority.low => l.priorityLow,
      TodoPriority.medium => l.priorityMedium,
      TodoPriority.high => l.priorityHigh,
      TodoPriority.urgent => l.priorityUrgent,
    };
  }
}

extension TodoCategoryL10n on TodoCategory {
  String labelFor(BuildContext context) {
    final l = L.of(context);
    return switch (this) {
      TodoCategory.personal => l.categoryPersonal,
      TodoCategory.work => l.categoryWork,
      TodoCategory.shopping => l.categoryShopping,
      TodoCategory.health => l.categoryHealth,
      TodoCategory.education => l.categoryEducation,
      TodoCategory.finance => l.categoryFinance,
      TodoCategory.travel => l.categoryTravel,
      TodoCategory.home => l.categoryHome,
      TodoCategory.other => l.categoryOther,
    };
  }
}
