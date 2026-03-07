import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_session_model.dart';
import '../models/monthly_budget_model.dart';
import '../models/category_budget_model.dart';

abstract class ExpenseLocalDataSource {
  Future<List<ExpenseSessionModel>> getAllSessions();
  Future<ExpenseSessionModel?> getSessionById(String id);
  Future<void> saveSession(ExpenseSessionModel session);
  Future<void> deleteSession(String id);
  Future<void> saveAllSessions(List<ExpenseSessionModel> sessions);

  Future<List<MonthlyBudgetModel>> getAllBudgets();
  Future<MonthlyBudgetModel?> getBudgetById(String id);
  Future<void> saveBudget(MonthlyBudgetModel budget);
  Future<void> deleteBudget(String id);
  Future<void> saveAllBudgets(List<MonthlyBudgetModel> budgets);

  // Category budget methods
  Future<List<CategoryBudgetModel>> getAllCategoryBudgets();
  Future<List<CategoryBudgetModel>> getCategoryBudgetsForMonth(
    int year,
    int month,
  );
  Future<CategoryBudgetModel?> getCategoryBudgetById(String id);
  Future<void> saveCategoryBudget(CategoryBudgetModel budget);
  Future<void> deleteCategoryBudget(String id);
  Future<void> saveAllCategoryBudgets(List<CategoryBudgetModel> budgets);
}

class ExpenseLocalDataSourceImpl implements ExpenseLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String sessionsKey = 'CACHED_EXPENSE_SESSIONS';
  static const String budgetsKey = 'CACHED_MONTHLY_BUDGETS';

  // Simple async lock to prevent race conditions during concurrent category budget updates
  Future<void>? _categoryBudgetLock;

  Future<void> _runWithCategoryBudgetLock(
    Future<void> Function() action,
  ) async {
    final previousLock = _categoryBudgetLock ?? Future.value();
    final completer = Completer<void>();
    _categoryBudgetLock = completer.future;

    try {
      await previousLock;
      await action();
    } catch (_) {
      // Ignore errors for the lock propagation
    } finally {
      completer.complete();
    }
  }

  ExpenseLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<ExpenseSessionModel>> getAllSessions() async {
    final jsonString = sharedPreferences.getString(sessionsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map(
            (jsonItem) =>
                ExpenseSessionModel.fromJson(jsonItem as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<ExpenseSessionModel?> getSessionById(String id) async {
    final sessions = await getAllSessions();
    try {
      return sessions.firstWhere((session) => session.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveSession(ExpenseSessionModel session) async {
    final sessions = await getAllSessions();
    final index = sessions.indexWhere((s) => s.id == session.id);

    if (index != -1) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }

    await saveAllSessions(sessions);
  }

  @override
  Future<void> deleteSession(String id) async {
    final sessions = await getAllSessions();
    sessions.removeWhere((session) => session.id == id);
    await saveAllSessions(sessions);
  }

  @override
  Future<void> saveAllSessions(List<ExpenseSessionModel> sessions) async {
    final jsonString = json.encode(
      sessions.map((session) => session.toJson()).toList(),
    );
    await sharedPreferences.setString(sessionsKey, jsonString);
  }

  @override
  Future<List<MonthlyBudgetModel>> getAllBudgets() async {
    final jsonString = sharedPreferences.getString(budgetsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map(
            (jsonItem) =>
                MonthlyBudgetModel.fromJson(jsonItem as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<MonthlyBudgetModel?> getBudgetById(String id) async {
    final budgets = await getAllBudgets();
    try {
      return budgets.firstWhere((budget) => budget.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveBudget(MonthlyBudgetModel budget) async {
    final budgets = await getAllBudgets();
    // First try by ID
    int index = budgets.indexWhere((b) => b.id == budget.id);
    if (index == -1) {
      // If ID not found, try to find by (year, month) to avoid duplicates
      index = budgets.indexWhere(
        (b) => b.year == budget.year && b.month == budget.month,
      );
      if (index != -1) {
        // Preserve original id and createdAt when updating existing month entry
        final existing = budgets[index];
        budgets[index] = MonthlyBudgetModel(
          id: existing.id,
          year: budget.year,
          month: budget.month,
          targetAmount: budget.targetAmount,
          createdAt: existing.createdAt,
          updatedAt: budget.updatedAt,
        );
      } else {
        budgets.add(budget);
      }
    } else {
      budgets[index] = budget;
    }

    await saveAllBudgets(budgets);
  }

  @override
  Future<void> deleteBudget(String id) async {
    final budgets = await getAllBudgets();
    budgets.removeWhere((budget) => budget.id == id);
    await saveAllBudgets(budgets);
  }

  @override
  Future<void> saveAllBudgets(List<MonthlyBudgetModel> budgets) async {
    // Deduplicate by (year, month), keep most recently updated
    final Map<String, MonthlyBudgetModel> latestByMonth = {};
    for (final b in budgets) {
      final key = '${b.year}-${b.month}';
      final existing = latestByMonth[key];
      if (existing == null || b.updatedAt.isAfter(existing.updatedAt)) {
        latestByMonth[key] = b;
      }
    }
    final deduped = latestByMonth.values.toList()
      ..sort((a, b) {
        // stable sort by year/month ascending to keep storage tidy
        final byYear = a.year.compareTo(b.year);
        if (byYear != 0) return byYear;
        return a.month.compareTo(b.month);
      });
    final jsonString = json.encode(
      deduped.map((budget) => budget.toJson()).toList(),
    );
    await sharedPreferences.setString(budgetsKey, jsonString);
  }

  // Category Budget Methods
  static const String categoryBudgetsKey = 'CACHED_CATEGORY_BUDGETS';

  @override
  Future<List<CategoryBudgetModel>> getAllCategoryBudgets() async {
    final jsonString = sharedPreferences.getString(categoryBudgetsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map(
            (jsonItem) =>
                CategoryBudgetModel.fromJson(jsonItem as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<List<CategoryBudgetModel>> getCategoryBudgetsForMonth(
    int year,
    int month,
  ) async {
    final allBudgets = await getAllCategoryBudgets();
    return allBudgets
        .where((budget) => budget.year == year && budget.month == month)
        .toList();
  }

  @override
  Future<CategoryBudgetModel?> getCategoryBudgetById(String id) async {
    final budgets = await getAllCategoryBudgets();
    try {
      return budgets.firstWhere((budget) => budget.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveCategoryBudget(CategoryBudgetModel budget) async {
    await _runWithCategoryBudgetLock(() async {
      final budgets = await getAllCategoryBudgets();
      // First try by ID
      int index = budgets.indexWhere((b) => b.id == budget.id);
      if (index == -1) {
        // If ID not found, try to find by (year, month, category, customCategoryName) to avoid duplicates
        index = budgets.indexWhere(
          (b) =>
              b.year == budget.year &&
              b.month == budget.month &&
              b.category == budget.category &&
              b.customCategoryName == budget.customCategoryName,
        );
        if (index != -1) {
          // Preserve original id and createdAt when updating existing entry
          final existing = budgets[index];
          budgets[index] = CategoryBudgetModel(
            id: existing.id,
            year: budget.year,
            month: budget.month,
            category: budget.category,
            budgetAmount: budget.budgetAmount,
            createdAt: existing.createdAt,
            updatedAt: budget.updatedAt,
            customCategoryName: budget.customCategoryName,
          );
        } else {
          budgets.add(budget);
        }
      } else {
        budgets[index] = budget;
      }

      await saveAllCategoryBudgets(budgets);
    });
  }

  @override
  Future<void> deleteCategoryBudget(String id) async {
    await _runWithCategoryBudgetLock(() async {
      final budgets = await getAllCategoryBudgets();
      budgets.removeWhere((budget) => budget.id == id);
      await saveAllCategoryBudgets(budgets);
    });
  }

  @override
  Future<void> saveAllCategoryBudgets(List<CategoryBudgetModel> budgets) async {
    // Deduplicate by (year, month, category, customCategoryName), keep most recently updated
    final Map<String, CategoryBudgetModel> latestByKey = {};
    for (final b in budgets) {
      final key =
          '${b.year}-${b.month}-${b.category.name}-${b.customCategoryName ?? ''}';
      final existing = latestByKey[key];
      if (existing == null || b.updatedAt.isAfter(existing.updatedAt)) {
        latestByKey[key] = b;
      }
    }
    final deduped = latestByKey.values.toList()
      ..sort((a, b) {
        // Sort by year/month/category
        final byYear = a.year.compareTo(b.year);
        if (byYear != 0) return byYear;
        final byMonth = a.month.compareTo(b.month);
        if (byMonth != 0) return byMonth;
        return a.category.name.compareTo(b.category.name);
      });
    final jsonString = json.encode(
      deduped.map((budget) => budget.toJson()).toList(),
    );
    await sharedPreferences.setString(categoryBudgetsKey, jsonString);
  }
}
