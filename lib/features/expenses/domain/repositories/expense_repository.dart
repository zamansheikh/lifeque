import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/expense_session.dart';
import '../entities/expense_item.dart';
import '../entities/monthly_budget.dart';
import '../entities/category_budget.dart';

abstract class ExpenseRepository {
  // Expense Session operations
  Future<Either<Failure, List<ExpenseSession>>> getAllSessions();
  Future<Either<Failure, ExpenseSession?>> getSessionById(String id);
  Future<Either<Failure, void>> addSession(ExpenseSession session);
  Future<Either<Failure, void>> updateSession(ExpenseSession session);
  Future<Either<Failure, void>> deleteSession(String id);

  // Monthly filtering
  Future<Either<Failure, List<ExpenseSession>>> getSessionsByMonth(
    int year,
    int month,
  );
  Future<Either<Failure, double>> getMonthlyTotal(int year, int month);
  Future<Either<Failure, double>> getMonthlyPurchasedTotal(int year, int month);
  Future<Either<Failure, double>> getMonthlyMissedTotal(int year, int month);

  // Item operations within a session
  Future<Either<Failure, void>> addItemToSession(
    String sessionId,
    ExpenseItem item,
  );
  Future<Either<Failure, void>> updateItemInSession(
    String sessionId,
    ExpenseItem item,
  );
  Future<Either<Failure, void>> deleteItemFromSession(
    String sessionId,
    String itemId,
  );
  Future<Either<Failure, void>> toggleItemPurchased(
    String sessionId,
    String itemId,
  );

  // Budget operations
  Future<Either<Failure, List<MonthlyBudget>>> getAllBudgets();
  Future<Either<Failure, MonthlyBudget?>> getBudgetByMonth(int year, int month);
  Future<Either<Failure, void>> setBudget(MonthlyBudget budget);
  Future<Either<Failure, void>> deleteBudget(String id);

  // Category Budget operations
  Future<Either<Failure, List<CategoryBudget>>> getAllCategoryBudgets();
  Future<Either<Failure, List<CategoryBudget>>> getCategoryBudgetsForMonth(
    int year,
    int month,
  );
  Future<Either<Failure, CategoryBudget?>> getCategoryBudgetById(String id);
  Future<Either<Failure, void>> setCategoryBudget(CategoryBudget budget);
  Future<Either<Failure, void>> deleteCategoryBudget(String id);

  // Analytics
  Future<Either<Failure, Map<String, double>>> getYearlyExpenseSummary(
    int year,
  );
  Future<Either<Failure, List<ExpenseSession>>> searchSessions(String query);
}
