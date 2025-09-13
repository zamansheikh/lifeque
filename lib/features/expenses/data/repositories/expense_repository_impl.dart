import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/expense_session.dart';
import '../../domain/entities/expense_item.dart';
import '../../domain/entities/monthly_budget.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_data_source.dart';
import '../models/expense_session_model.dart';
import '../models/monthly_budget_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;

  ExpenseRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<ExpenseSession>>> getAllSessions() async {
    try {
      final sessions = await localDataSource.getAllSessions();
      return Right(sessions.map((session) => session.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, ExpenseSession?>> getSessionById(String id) async {
    try {
      final session = await localDataSource.getSessionById(id);
      return Right(session?.toEntity());
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addSession(ExpenseSession session) async {
    try {
      final sessionModel = ExpenseSessionModel.fromEntity(session);
      await localDataSource.saveSession(sessionModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateSession(ExpenseSession session) async {
    try {
      final sessionModel = ExpenseSessionModel.fromEntity(session);
      await localDataSource.saveSession(sessionModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteSession(String id) async {
    try {
      await localDataSource.deleteSession(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<ExpenseSession>>> getSessionsByMonth(
    int year,
    int month,
  ) async {
    try {
      final sessions = await localDataSource.getAllSessions();
      final filteredSessions = sessions
          .where(
            (session) =>
                session.date.year == year && session.date.month == month,
          )
          .map((session) => session.toEntity())
          .toList();

      // Sort by date descending (newest first)
      filteredSessions.sort((a, b) => b.date.compareTo(a.date));

      return Right(filteredSessions);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, double>> getMonthlyTotal(int year, int month) async {
    try {
      final sessionsResult = await getSessionsByMonth(year, month);
      return sessionsResult.fold((failure) => Left(failure), (sessions) {
        final total = sessions.fold(
          0.0,
          (sum, session) => sum + session.totalAmount,
        );
        return Right(total);
      });
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, double>> getMonthlyPurchasedTotal(
    int year,
    int month,
  ) async {
    try {
      final sessionsResult = await getSessionsByMonth(year, month);
      return sessionsResult.fold((failure) => Left(failure), (sessions) {
        final total = sessions.fold(
          0.0,
          (sum, session) => sum + session.purchasedAmount,
        );
        return Right(total);
      });
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, double>> getMonthlyMissedTotal(
    int year,
    int month,
  ) async {
    try {
      final sessionsResult = await getSessionsByMonth(year, month);
      return sessionsResult.fold((failure) => Left(failure), (sessions) {
        final total = sessions.fold(
          0.0,
          (sum, session) => sum + session.missedAmount,
        );
        return Right(total);
      });
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addItemToSession(
    String sessionId,
    ExpenseItem item,
  ) async {
    try {
      final session = await localDataSource.getSessionById(sessionId);
      if (session == null) {
        return Left(CacheFailure());
      }

      final updatedItems = List<ExpenseItem>.from(session.items)..add(item);
      final updatedSession = session.copyWith(items: updatedItems);

      await localDataSource.saveSession(updatedSession);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateItemInSession(
    String sessionId,
    ExpenseItem item,
  ) async {
    try {
      final session = await localDataSource.getSessionById(sessionId);
      if (session == null) {
        return Left(CacheFailure());
      }

      final updatedItems = session.items.map((existingItem) {
        return existingItem.id == item.id ? item : existingItem;
      }).toList();

      final updatedSession = session.copyWith(items: updatedItems);
      await localDataSource.saveSession(updatedSession);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteItemFromSession(
    String sessionId,
    String itemId,
  ) async {
    try {
      final session = await localDataSource.getSessionById(sessionId);
      if (session == null) {
        return Left(CacheFailure());
      }

      final updatedItems = session.items
          .where((item) => item.id != itemId)
          .toList();
      final updatedSession = session.copyWith(items: updatedItems);

      await localDataSource.saveSession(updatedSession);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> toggleItemPurchased(
    String sessionId,
    String itemId,
  ) async {
    try {
      final session = await localDataSource.getSessionById(sessionId);
      if (session == null) {
        return Left(CacheFailure());
      }

      final updatedItems = session.items.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            isPurchased: !item.isPurchased,
            purchasedAt: !item.isPurchased ? DateTime.now() : null,
            clearPurchasedAt: item.isPurchased,
          );
        }
        return item;
      }).toList();

      final updatedSession = session.copyWith(items: updatedItems);
      await localDataSource.saveSession(updatedSession);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<MonthlyBudget>>> getAllBudgets() async {
    try {
      final budgets = await localDataSource.getAllBudgets();
      return Right(budgets.map((budget) => budget.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, MonthlyBudget?>> getBudgetByMonth(
    int year,
    int month,
  ) async {
    try {
      final budgets = await localDataSource.getAllBudgets();
      final budget = budgets
          .where((budget) => budget.year == year && budget.month == month)
          .map((budget) => budget.toEntity())
          .firstOrNull;
      return Right(budget);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> setBudget(MonthlyBudget budget) async {
    try {
      final budgetModel = MonthlyBudgetModel.fromEntity(budget);
      await localDataSource.saveBudget(budgetModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteBudget(String id) async {
    try {
      await localDataSource.deleteBudget(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Map<String, double>>> getYearlyExpenseSummary(
    int year,
  ) async {
    try {
      final sessions = await localDataSource.getAllSessions();
      final yearSessions = sessions.where(
        (session) => session.date.year == year,
      );

      final Map<String, double> summary = {};

      for (int month = 1; month <= 12; month++) {
        final monthSessions = yearSessions.where(
          (session) => session.date.month == month,
        );
        final monthTotal = monthSessions.fold(
          0.0,
          (sum, session) => sum + session.purchasedAmount,
        );

        const monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];

        summary[monthNames[month - 1]] = monthTotal;
      }

      return Right(summary);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, List<ExpenseSession>>> searchSessions(
    String query,
  ) async {
    try {
      final sessions = await localDataSource.getAllSessions();
      final filteredSessions = sessions
          .where(
            (session) =>
                session.title.toLowerCase().contains(query.toLowerCase()) ||
                session.notes?.toLowerCase().contains(query.toLowerCase()) ==
                    true ||
                session.items.any(
                  (item) =>
                      item.name.toLowerCase().contains(query.toLowerCase()),
                ),
          )
          .map((session) => session.toEntity())
          .toList();

      // Sort by date descending (newest first)
      filteredSessions.sort((a, b) => b.date.compareTo(a.date));

      return Right(filteredSessions);
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}
