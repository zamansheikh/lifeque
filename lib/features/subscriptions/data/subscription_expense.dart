import 'package:uuid/uuid.dart';

import '../../../core/utils/app_strings.dart';
import '../../expenses/domain/entities/expense_category.dart';
import '../../expenses/domain/entities/expense_item.dart';
import '../../expenses/domain/entities/expense_session.dart';
import '../domain/subscription.dart';

/// The expense category a renewal is filed under.
ExpenseCategory expenseCategoryFor(SubscriptionCategory c) => switch (c) {
  SubscriptionCategory.streaming ||
  SubscriptionCategory.music ||
  SubscriptionCategory.gaming => ExpenseCategory.entertainment,
  SubscriptionCategory.education => ExpenseCategory.education,
  SubscriptionCategory.internet => ExpenseCategory.utilities,
  SubscriptionCategory.fitness => ExpenseCategory.healthcare,
  _ => ExpenseCategory.bills,
};

/// A paid renewal as an expense entry: one item, already bought.
ExpenseSession renewalExpense(Subscription s, double amountLocal, DateTime at) {
  const uuid = Uuid();
  return ExpenseSession(
    id: uuid.v4(),
    title: s.name,
    date: at,
    items: [
      ExpenseItem(
        id: uuid.v4(),
        name: s.name,
        amount: amountLocal,
        isPurchased: true,
        purchasedAt: at,
        category: expenseCategoryFor(s.category),
      ),
    ],
    notes: appStrings.subExpenseNote,
    createdAt: at,
  );
}
