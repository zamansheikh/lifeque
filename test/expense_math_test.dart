import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/features/expenses/domain/entities/expense_category.dart';
import 'package:lifeque/features/expenses/domain/entities/expense_item.dart';
import 'package:lifeque/features/expenses/domain/entities/expense_session.dart';
import 'package:lifeque/features/expenses/domain/entities/category_budget.dart';

ExpenseItem item(
  String name,
  double amount, {
  bool purchased = false,
  ExpenseCategory category = ExpenseCategory.other,
  String? custom,
}) =>
    ExpenseItem(
      id: name,
      name: name,
      amount: amount,
      isPurchased: purchased,
      category: category,
      customCategoryName: custom,
    );

void main() {
  final now = DateTime(2026, 9, 5);

  group('session totals', () {
    test('total splits exactly into purchased and missed', () {
      final s = ExpenseSession(
        id: 's',
        title: 'market',
        date: now,
        createdAt: now,
        items: [
          item('rice', 120.50, purchased: true),
          item('oil', 340.25, purchased: true),
          item('soap', 55.75),
        ],
      );
      expect(s.totalAmount, closeTo(516.50, 1e-9));
      expect(s.purchasedAmount, closeTo(460.75, 1e-9));
      expect(s.missedAmount, closeTo(55.75, 1e-9));
      expect(s.purchasedAmount + s.missedAmount, closeTo(s.totalAmount, 1e-9));
      expect(s.purchasedCount, 2);
      expect(s.missedCount, 1);
    });

    test('empty session is zero, not NaN', () {
      final s = ExpenseSession(
        id: 's', title: 't', date: now, createdAt: now, items: const [],
      );
      expect(s.totalAmount, 0);
      expect(s.purchasedAmount, 0);
      expect(s.missedAmount, 0);
    });
  });

  group('category keys', () {
    test('custom categories never collide with the built-in "other"', () {
      final builtIn = item('x', 10, category: ExpenseCategory.other);
      final custom = item('y', 10, category: ExpenseCategory.other, custom: 'Gifts');
      expect(builtIn.effectiveCategoryKey, 'other');
      expect(custom.effectiveCategoryKey, 'custom:Gifts');
      expect(builtIn.effectiveCategoryKey == custom.effectiveCategoryKey, isFalse);
    });

    test('item and budget agree on the key for the same custom category', () {
      final it = item('y', 10, category: ExpenseCategory.other, custom: 'Gifts');
      final budget = CategoryBudget(
        id: 'b', year: 2026, month: 9,
        category: ExpenseCategory.other,
        budgetAmount: 500,
        createdAt: now, updatedAt: now,
        customCategoryName: 'Gifts',
      );
      expect(it.effectiveCategoryKey, budget.effectiveCategoryKey);
    });
  });

  group('category budget math', () {
    final b = CategoryBudget(
      id: 'b', year: 2026, month: 9,
      category: ExpenseCategory.food,
      budgetAmount: 1000,
      createdAt: now, updatedAt: now,
    );

    test('progress, remaining and percentage agree', () {
      expect(b.getProgress(250), closeTo(0.25, 1e-9));
      expect(b.getRemaining(250), closeTo(750, 1e-9));
      expect(b.getPercentageSpent(250), 25);
      expect(b.isOverBudget(250), isFalse);
    });

    test('overspend reports past 100% and negative remaining', () {
      expect(b.isOverBudget(1200), isTrue);
      expect(b.getRemaining(1200), closeTo(-200, 1e-9));
      expect(b.getPercentageSpent(1200), 120);
    });

    test('zero budget does not divide by zero', () {
      final zero = b.copyWith(budgetAmount: 0);
      expect(zero.getProgress(100), 0.0);
      expect(zero.getProgress(100).isNaN, isFalse);
      expect(zero.getPercentageSpent(100), 0);
    });
  });

  group('month attribution', () {
    test('session belongs to the month of its date', () {
      final s = ExpenseSession(
        id: 's', title: 't', date: DateTime(2026, 9, 30, 23, 59),
        createdAt: now, items: const [],
      );
      expect(s.isSameMonth(DateTime(2026, 9, 1)), isTrue);
      expect(s.isSameMonth(DateTime(2026, 10, 1)), isFalse);
      expect(s.isSameMonth(DateTime(2025, 9, 15)), isFalse);
    });
  });

  group('aggregate invariants', () {
    test('per-category spending sums back to the month purchased total', () {
      final sessions = [
        ExpenseSession(
          id: 's1', title: 'a', date: now, createdAt: now,
          items: [
            item('rice', 120.50, purchased: true, category: ExpenseCategory.food),
            item('bus', 40.00, purchased: true, category: ExpenseCategory.transport),
            item('soap', 55.75),
          ],
        ),
        ExpenseSession(
          id: 's2', title: 'b', date: now, createdAt: now,
          items: [
            item('gift', 300.00, purchased: true,
                category: ExpenseCategory.other, custom: 'Gifts'),
            item('fish', 210.25, purchased: true, category: ExpenseCategory.food),
          ],
        ),
      ];

      final monthPurchased =
          sessions.fold<double>(0, (sum, s) => sum + s.purchasedAmount);

      final spending = <String, double>{};
      for (final s in sessions) {
        for (final i in s.items) {
          if (!i.isPurchased) continue;
          spending[i.effectiveCategoryKey] =
              (spending[i.effectiveCategoryKey] ?? 0) + i.amount;
        }
      }
      final summed = spending.values.fold<double>(0, (a, b) => a + b);

      expect(summed, closeTo(monthPurchased, 1e-9));
      expect(spending['food'], closeTo(330.75, 1e-9));
      expect(spending['transport'], closeTo(40.00, 1e-9));
      expect(spending['custom:Gifts'], closeTo(300.00, 1e-9));
      // Unpurchased items must never appear in spending.
      expect(spending.containsKey('other'), isFalse);
    });
  });
}
