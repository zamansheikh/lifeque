import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/expense_session.dart';
import '../entities/expense_item.dart';
import '../entities/monthly_budget.dart';
import '../entities/category_budget.dart';
import '../repositories/expense_repository.dart';

// Session Use Cases
class GetAllSessions implements UseCase<List<ExpenseSession>, NoParams> {
  final ExpenseRepository repository;

  GetAllSessions(this.repository);

  @override
  Future<Either<Failure, List<ExpenseSession>>> call(NoParams params) async {
    return await repository.getAllSessions();
  }
}

class GetSessionById implements UseCase<ExpenseSession?, GetSessionByIdParams> {
  final ExpenseRepository repository;

  GetSessionById(this.repository);

  @override
  Future<Either<Failure, ExpenseSession?>> call(
    GetSessionByIdParams params,
  ) async {
    return await repository.getSessionById(params.id);
  }
}

class AddSession implements UseCase<void, AddSessionParams> {
  final ExpenseRepository repository;

  AddSession(this.repository);

  @override
  Future<Either<Failure, void>> call(AddSessionParams params) async {
    return await repository.addSession(params.session);
  }
}

class UpdateSession implements UseCase<void, UpdateSessionParams> {
  final ExpenseRepository repository;

  UpdateSession(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateSessionParams params) async {
    return await repository.updateSession(params.session);
  }
}

class DeleteSession implements UseCase<void, DeleteSessionParams> {
  final ExpenseRepository repository;

  DeleteSession(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteSessionParams params) async {
    return await repository.deleteSession(params.id);
  }
}

// Monthly Use Cases
class GetSessionsByMonth
    implements UseCase<List<ExpenseSession>, GetSessionsByMonthParams> {
  final ExpenseRepository repository;

  GetSessionsByMonth(this.repository);

  @override
  Future<Either<Failure, List<ExpenseSession>>> call(
    GetSessionsByMonthParams params,
  ) async {
    return await repository.getSessionsByMonth(params.year, params.month);
  }
}

class GetMonthlyTotal implements UseCase<double, GetMonthlyTotalParams> {
  final ExpenseRepository repository;

  GetMonthlyTotal(this.repository);

  @override
  Future<Either<Failure, double>> call(GetMonthlyTotalParams params) async {
    return await repository.getMonthlyTotal(params.year, params.month);
  }
}

class GetMonthlyPurchasedTotal
    implements UseCase<double, GetMonthlyTotalParams> {
  final ExpenseRepository repository;

  GetMonthlyPurchasedTotal(this.repository);

  @override
  Future<Either<Failure, double>> call(GetMonthlyTotalParams params) async {
    return await repository.getMonthlyPurchasedTotal(params.year, params.month);
  }
}

class GetMonthlyMissedTotal implements UseCase<double, GetMonthlyTotalParams> {
  final ExpenseRepository repository;

  GetMonthlyMissedTotal(this.repository);

  @override
  Future<Either<Failure, double>> call(GetMonthlyTotalParams params) async {
    return await repository.getMonthlyMissedTotal(params.year, params.month);
  }
}

// Item Use Cases
class AddItemToSession implements UseCase<void, AddItemToSessionParams> {
  final ExpenseRepository repository;

  AddItemToSession(this.repository);

  @override
  Future<Either<Failure, void>> call(AddItemToSessionParams params) async {
    return await repository.addItemToSession(params.sessionId, params.item);
  }
}

class UpdateItemInSession implements UseCase<void, UpdateItemInSessionParams> {
  final ExpenseRepository repository;

  UpdateItemInSession(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateItemInSessionParams params) async {
    return await repository.updateItemInSession(params.sessionId, params.item);
  }
}

class DeleteItemFromSession
    implements UseCase<void, DeleteItemFromSessionParams> {
  final ExpenseRepository repository;

  DeleteItemFromSession(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteItemFromSessionParams params) async {
    return await repository.deleteItemFromSession(
      params.sessionId,
      params.itemId,
    );
  }
}

class ToggleItemPurchased implements UseCase<void, ToggleItemPurchasedParams> {
  final ExpenseRepository repository;

  ToggleItemPurchased(this.repository);

  @override
  Future<Either<Failure, void>> call(ToggleItemPurchasedParams params) async {
    return await repository.toggleItemPurchased(
      params.sessionId,
      params.itemId,
    );
  }
}

// Budget Use Cases
class GetAllBudgets implements UseCase<List<MonthlyBudget>, NoParams> {
  final ExpenseRepository repository;

  GetAllBudgets(this.repository);

  @override
  Future<Either<Failure, List<MonthlyBudget>>> call(NoParams params) async {
    return await repository.getAllBudgets();
  }
}

class GetBudgetByMonth
    implements UseCase<MonthlyBudget?, GetBudgetByMonthParams> {
  final ExpenseRepository repository;

  GetBudgetByMonth(this.repository);

  @override
  Future<Either<Failure, MonthlyBudget?>> call(
    GetBudgetByMonthParams params,
  ) async {
    return await repository.getBudgetByMonth(params.year, params.month);
  }
}

class SetBudget implements UseCase<void, SetBudgetParams> {
  final ExpenseRepository repository;

  SetBudget(this.repository);

  @override
  Future<Either<Failure, void>> call(SetBudgetParams params) async {
    return await repository.setBudget(params.budget);
  }
}

class DeleteBudget implements UseCase<void, DeleteBudgetParams> {
  final ExpenseRepository repository;

  DeleteBudget(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteBudgetParams params) async {
    return await repository.deleteBudget(params.id);
  }
}

// Category Budget Use Cases
class GetAllCategoryBudgets implements UseCase<List<CategoryBudget>, NoParams> {
  final ExpenseRepository repository;

  GetAllCategoryBudgets(this.repository);

  @override
  Future<Either<Failure, List<CategoryBudget>>> call(NoParams params) async {
    return await repository.getAllCategoryBudgets();
  }
}

class GetCategoryBudgetsForMonth
    implements UseCase<List<CategoryBudget>, GetCategoryBudgetsForMonthParams> {
  final ExpenseRepository repository;

  GetCategoryBudgetsForMonth(this.repository);

  @override
  Future<Either<Failure, List<CategoryBudget>>> call(
    GetCategoryBudgetsForMonthParams params,
  ) async {
    return await repository.getCategoryBudgetsForMonth(
      params.year,
      params.month,
    );
  }
}

class SetCategoryBudget implements UseCase<void, SetCategoryBudgetParams> {
  final ExpenseRepository repository;

  SetCategoryBudget(this.repository);

  @override
  Future<Either<Failure, void>> call(SetCategoryBudgetParams params) async {
    return await repository.setCategoryBudget(params.budget);
  }
}

class DeleteCategoryBudget
    implements UseCase<void, DeleteCategoryBudgetParams> {
  final ExpenseRepository repository;

  DeleteCategoryBudget(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteCategoryBudgetParams params) async {
    return await repository.deleteCategoryBudget(params.id);
  }
}

// Analytics Use Cases
class GetYearlyExpenseSummary
    implements UseCase<Map<String, double>, GetYearlyExpenseSummaryParams> {
  final ExpenseRepository repository;

  GetYearlyExpenseSummary(this.repository);

  @override
  Future<Either<Failure, Map<String, double>>> call(
    GetYearlyExpenseSummaryParams params,
  ) async {
    return await repository.getYearlyExpenseSummary(params.year);
  }
}

class SearchSessions
    implements UseCase<List<ExpenseSession>, SearchSessionsParams> {
  final ExpenseRepository repository;

  SearchSessions(this.repository);

  @override
  Future<Either<Failure, List<ExpenseSession>>> call(
    SearchSessionsParams params,
  ) async {
    return await repository.searchSessions(params.query);
  }
}

// Parameter classes
class GetSessionByIdParams {
  final String id;
  GetSessionByIdParams({required this.id});
}

class AddSessionParams {
  final ExpenseSession session;
  AddSessionParams({required this.session});
}

class UpdateSessionParams {
  final ExpenseSession session;
  UpdateSessionParams({required this.session});
}

class DeleteSessionParams {
  final String id;
  DeleteSessionParams({required this.id});
}

class GetSessionsByMonthParams {
  final int year;
  final int month;
  GetSessionsByMonthParams({required this.year, required this.month});
}

class GetMonthlyTotalParams {
  final int year;
  final int month;
  GetMonthlyTotalParams({required this.year, required this.month});
}

class AddItemToSessionParams {
  final String sessionId;
  final ExpenseItem item;
  AddItemToSessionParams({required this.sessionId, required this.item});
}

class UpdateItemInSessionParams {
  final String sessionId;
  final ExpenseItem item;
  UpdateItemInSessionParams({required this.sessionId, required this.item});
}

class DeleteItemFromSessionParams {
  final String sessionId;
  final String itemId;
  DeleteItemFromSessionParams({required this.sessionId, required this.itemId});
}

class ToggleItemPurchasedParams {
  final String sessionId;
  final String itemId;
  ToggleItemPurchasedParams({required this.sessionId, required this.itemId});
}

class GetBudgetByMonthParams {
  final int year;
  final int month;
  GetBudgetByMonthParams({required this.year, required this.month});
}

class SetBudgetParams {
  final MonthlyBudget budget;
  SetBudgetParams({required this.budget});
}

class DeleteBudgetParams {
  final String id;
  DeleteBudgetParams({required this.id});
}

class GetCategoryBudgetsForMonthParams {
  final int year;
  final int month;
  GetCategoryBudgetsForMonthParams({required this.year, required this.month});
}

class SetCategoryBudgetParams {
  final CategoryBudget budget;
  SetCategoryBudgetParams({required this.budget});
}

class DeleteCategoryBudgetParams {
  final String id;
  DeleteCategoryBudgetParams({required this.id});
}

class GetYearlyExpenseSummaryParams {
  final int year;
  GetYearlyExpenseSummaryParams({required this.year});
}

class SearchSessionsParams {
  final String query;
  SearchSessionsParams({required this.query});
}
