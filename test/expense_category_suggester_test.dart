import 'package:flutter_test/flutter_test.dart';
import 'package:lifeque/features/expenses/domain/entities/expense_category.dart';
import 'package:lifeque/features/expenses/domain/services/expense_category_suggester.dart';

ExpenseCategory? top(String name) =>
    ExpenseCategorySuggester.suggest(name).firstOrNull;

void main() {
  group('suggests from English', () {
    test('a grocery run', () {
      expect(top('2kg rice'), ExpenseCategory.groceries);
      expect(top('Onion and garlic'), ExpenseCategory.groceries);
      expect(top('eggs'), ExpenseCategory.groceries);
    });

    test('eating out is not the same as buying food', () {
      expect(top('dinner at restaurant'), ExpenseCategory.food);
      expect(top('Biryani'), ExpenseCategory.food);
    });

    test('the rest of the categories', () {
      expect(top('CNG fare'), ExpenseCategory.transport);
      expect(top('Electricity bill'), ExpenseCategory.utilities);
      expect(top('movie ticket'), ExpenseCategory.entertainment);
      expect(top('medicine from pharmacy'), ExpenseCategory.healthcare);
      expect(top('tuition fees'), ExpenseCategory.education);
      expect(top('new shirt'), ExpenseCategory.shopping);
      expect(top('house rent'), ExpenseCategory.bills);
    });
  });

  group('suggests from Bangla', () {
    test('a grocery run', () {
      expect(top('চাল ৫ কেজি'), ExpenseCategory.groceries);
      expect(top('পেঁয়াজ ও রসুন'), ExpenseCategory.groceries);
      expect(top('ইলিশ মাছ'), ExpenseCategory.groceries);
    });

    test('the rest of the categories', () {
      expect(top('বিরিয়ানি'), ExpenseCategory.food);
      expect(top('রিকশা ভাড়া'), ExpenseCategory.transport);
      expect(top('বিদ্যুৎ বিল'), ExpenseCategory.utilities);
      expect(top('সিনেমার টিকিট'), ExpenseCategory.entertainment);
      expect(top('ওষুধ'), ExpenseCategory.healthcare);
      expect(top('টিউশন ফি'), ExpenseCategory.education);
      expect(top('নতুন শার্ট'), ExpenseCategory.shopping);
      expect(top('বাসা ভাড়া'), ExpenseCategory.bills);
    });

    test('case endings still match the root word', () {
      expect(top('ডিমের দাম'), ExpenseCategory.groceries);
      expect(top('মাছের বাজার'), ExpenseCategory.groceries);
    });
  });

  test('reads a line that mixes both scripts', () {
    expect(top('২ kg চাল'), ExpenseCategory.groceries);
    expect(top('bus ভাড়া'), ExpenseCategory.transport);
  });

  group('does not match on fragments of a longer word', () {
    // Every one of these was a false positive under plain `contains`.
    test('steak is not tea', () {
      expect(
        ExpenseCategorySuggester.suggest('steak'),
        isNot(contains(ExpenseCategory.food)),
      );
    });
    test('toilet paper is not oil', () {
      expect(top('toilet paper'), isNot(ExpenseCategory.groceries));
    });
    test('billboard is not a bill', () {
      expect(ExpenseCategorySuggester.suggest('billboard'), isEmpty);
    });
    test('sandal is not dal', () {
      expect(top('sandal'), ExpenseCategory.shopping);
    });
  });

  test('an unknown item suggests nothing rather than guessing', () {
    expect(ExpenseCategorySuggester.suggest('xyzzy'), isEmpty);
    expect(ExpenseCategorySuggester.suggest(''), isEmpty);
    expect(ExpenseCategorySuggester.suggest('   '), isEmpty);
  });

  group('completes the name being typed', () {
    test('offers matches in the script being typed', () {
      final en = ExpenseCategorySuggester.suggestNames('ric');
      expect(en.map((m) => m.name), contains('Rice'));
      expect(en.first.name, isNot(matches(RegExp(r'[\u0980-\u09FF]'))));

      final bn = ExpenseCategorySuggester.suggestNames('চা');
      expect(bn.map((m) => m.name), contains('চাল'));
    });

    test('carries the category of the completion', () {
      final match = ExpenseCategorySuggester.suggestNames(
        'rick',
      ).firstWhere((m) => m.name == 'Rickshaw');
      expect(match.category, ExpenseCategory.transport);
    });

    test('waits for a second character, and caps the list', () {
      expect(ExpenseCategorySuggester.suggestNames('r'), isEmpty);
      expect(ExpenseCategorySuggester.suggestNames('b').length, 0);
      expect(
        ExpenseCategorySuggester.suggestNames('ba').length,
        lessThanOrEqualTo(6),
      );
    });

    test('does not offer the word already typed in full', () {
      expect(
        ExpenseCategorySuggester.suggestNames('rice').map((m) => m.name),
        isNot(contains('Rice')),
      );
    });
  });

  test('ranks by how many keywords hit, and caps the list', () {
    final many = ExpenseCategorySuggester.suggest('rice dal onion bus ticket');
    expect(many.first, ExpenseCategory.groceries);
    expect(many.length, lessThanOrEqualTo(3));
  });
}
