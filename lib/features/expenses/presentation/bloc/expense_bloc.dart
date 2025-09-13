import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/expense_session.dart';
import '../../domain/entities/expense_item.dart';
import '../../domain/entities/monthly_budget.dart';
import '../../domain/usecases/expense_usecases.dart';
import '../../../../core/usecases/usecase.dart';

part 'expense_event.dart';
part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final GetAllSessions getAllSessions;
  final GetSessionById getSessionById;
  final AddSession addSession;
  final UpdateSession updateSession;
  final DeleteSession deleteSession;
  final GetSessionsByMonth getSessionsByMonth;
  final GetMonthlyTotal getMonthlyTotal;
  final GetMonthlyPurchasedTotal getMonthlyPurchasedTotal;
  final GetMonthlyMissedTotal getMonthlyMissedTotal;
  final AddItemToSession addItemToSession;
  final UpdateItemInSession updateItemInSession;
  final DeleteItemFromSession deleteItemFromSession;
  final ToggleItemPurchased toggleItemPurchased;
  final GetAllBudgets getAllBudgets;
  final GetBudgetByMonth getBudgetByMonth;
  final SetBudget setBudget;
  final DeleteBudget deleteBudget;
  final GetYearlyExpenseSummary getYearlyExpenseSummary;
  final SearchSessions searchSessions;

  ExpenseBloc({
    required this.getAllSessions,
    required this.getSessionById,
    required this.addSession,
    required this.updateSession,
    required this.deleteSession,
    required this.getSessionsByMonth,
    required this.getMonthlyTotal,
    required this.getMonthlyPurchasedTotal,
    required this.getMonthlyMissedTotal,
    required this.addItemToSession,
    required this.updateItemInSession,
    required this.deleteItemFromSession,
    required this.toggleItemPurchased,
    required this.getAllBudgets,
    required this.getBudgetByMonth,
    required this.setBudget,
    required this.deleteBudget,
    required this.getYearlyExpenseSummary,
    required this.searchSessions,
  }) : super(ExpenseInitial()) {
    on<LoadSessions>(_onLoadSessions);
    on<LoadSessionsByMonth>(_onLoadSessionsByMonth);
    on<AddSessionEvent>(_onAddSession);
    on<UpdateSessionEvent>(_onUpdateSession);
    on<DeleteSessionEvent>(_onDeleteSession);
    on<AddItemToSessionEvent>(_onAddItemToSession);
    on<UpdateItemInSessionEvent>(_onUpdateItemInSession);
    on<DeleteItemFromSessionEvent>(_onDeleteItemFromSession);
    on<ToggleItemPurchasedEvent>(_onToggleItemPurchased);
    on<LoadBudgets>(_onLoadBudgets);
    on<LoadBudgetByMonth>(_onLoadBudgetByMonth);
    on<SetBudgetEvent>(_onSetBudget);
    on<DeleteBudgetEvent>(_onDeleteBudget);
    on<SearchSessionsEvent>(_onSearchSessions);
    on<LoadYearlyExpenseSummary>(_onLoadYearlyExpenseSummary);
    on<ClearSearch>(_onClearSearch);
    on<ChangeSelectedMonth>(_onChangeSelectedMonth);
  }

  Future<void> _onLoadSessions(
    LoadSessions event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseLoading());

    final sessionsResult = await getAllSessions(NoParams());
    final budgetsResult = await getAllBudgets(NoParams());

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    await sessionsResult.fold(
      (failure) async => emit(const ExpenseError('Failed to load sessions')),
      (sessions) async {
        await budgetsResult.fold(
          (failure) async => emit(const ExpenseError('Failed to load budgets')),
          (budgets) async {
            await _loadMonthlyData(emit, sessions, budgets, currentMonth);
          },
        );
      },
    );
  }

  Future<void> _onLoadSessionsByMonth(
    LoadSessionsByMonth event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;
      emit(ExpenseLoading());

      final selectedMonth = DateTime(event.year, event.month);
      await _loadMonthlyData(
        emit,
        currentState.sessions,
        currentState.budgets,
        selectedMonth,
      );
    }
  }

  Future<void> _loadMonthlyData(
    Emitter<ExpenseState> emit,
    List<ExpenseSession> allSessions,
    List<MonthlyBudget> allBudgets,
    DateTime selectedMonth,
  ) async {
    final monthlySessionsResult = await getSessionsByMonth(
      GetSessionsByMonthParams(
        year: selectedMonth.year,
        month: selectedMonth.month,
      ),
    );
    final monthlyTotalResult = await getMonthlyTotal(
      GetMonthlyTotalParams(
        year: selectedMonth.year,
        month: selectedMonth.month,
      ),
    );
    final monthlyPurchasedResult = await getMonthlyPurchasedTotal(
      GetMonthlyTotalParams(
        year: selectedMonth.year,
        month: selectedMonth.month,
      ),
    );
    final monthlyMissedResult = await getMonthlyMissedTotal(
      GetMonthlyTotalParams(
        year: selectedMonth.year,
        month: selectedMonth.month,
      ),
    );
    final budgetResult = await getBudgetByMonth(
      GetBudgetByMonthParams(
        year: selectedMonth.year,
        month: selectedMonth.month,
      ),
    );

    final sessions = monthlySessionsResult.getOrElse(() => []);
    final monthlyTotal = monthlyTotalResult.getOrElse(() => 0.0);
    final monthlyPurchased = monthlyPurchasedResult.getOrElse(() => 0.0);
    final monthlyMissed = monthlyMissedResult.getOrElse(() => 0.0);
    final currentBudget = budgetResult.getOrElse(() => null);

    emit(
      ExpenseLoaded(
        sessions: sessions,
        budgets: allBudgets,
        selectedMonth: selectedMonth,
        currentBudget: currentBudget,
        monthlyTotal: monthlyTotal,
        monthlyPurchased: monthlyPurchased,
        monthlyMissed: monthlyMissed,
      ),
    );
  }

  Future<void> _onAddSession(
    AddSessionEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;

      final result = await addSession(AddSessionParams(session: event.session));

      result.fold(
        (failure) => emit(const ExpenseError('Failed to add session')),
        (_) {
          // Directly reload data instead of showing success state
          add(ChangeSelectedMonth(currentState.selectedMonth));
        },
      );
    }
  }

  Future<void> _onUpdateSession(
    UpdateSessionEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;

      final result = await updateSession(
        UpdateSessionParams(session: event.session),
      );

      result.fold(
        (failure) => emit(const ExpenseError('Failed to update session')),
        (_) {
          add(ChangeSelectedMonth(currentState.selectedMonth));
        },
      );
    }
  }

  Future<void> _onDeleteSession(
    DeleteSessionEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;

      final result = await deleteSession(DeleteSessionParams(id: event.id));

      result.fold(
        (failure) => emit(const ExpenseError('Failed to delete session')),
        (_) {
          emit(const ExpenseOperationSuccess('Session deleted successfully'));
          add(ChangeSelectedMonth(currentState.selectedMonth));
        },
      );
    }
  }

  Future<void> _onAddItemToSession(
    AddItemToSessionEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;

      final result = await addItemToSession(
        AddItemToSessionParams(sessionId: event.sessionId, item: event.item),
      );

      result.fold((failure) => emit(const ExpenseError('Failed to add item')), (
        _,
      ) {
        emit(const ExpenseOperationSuccess('Item added successfully'));
        add(ChangeSelectedMonth(currentState.selectedMonth));
      });
    }
  }

  Future<void> _onUpdateItemInSession(
    UpdateItemInSessionEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;

      final result = await updateItemInSession(
        UpdateItemInSessionParams(sessionId: event.sessionId, item: event.item),
      );

      result.fold(
        (failure) => emit(const ExpenseError('Failed to update item')),
        (_) {
          emit(const ExpenseOperationSuccess('Item updated successfully'));
          add(ChangeSelectedMonth(currentState.selectedMonth));
        },
      );
    }
  }

  Future<void> _onDeleteItemFromSession(
    DeleteItemFromSessionEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;

      final result = await deleteItemFromSession(
        DeleteItemFromSessionParams(
          sessionId: event.sessionId,
          itemId: event.itemId,
        ),
      );

      result.fold(
        (failure) => emit(const ExpenseError('Failed to delete item')),
        (_) {
          emit(const ExpenseOperationSuccess('Item deleted successfully'));
          add(ChangeSelectedMonth(currentState.selectedMonth));
        },
      );
    }
  }

  Future<void> _onToggleItemPurchased(
    ToggleItemPurchasedEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;

      final result = await toggleItemPurchased(
        ToggleItemPurchasedParams(
          sessionId: event.sessionId,
          itemId: event.itemId,
        ),
      );

      result.fold(
        (failure) => emit(const ExpenseError('Failed to toggle item')),
        (_) {
          add(ChangeSelectedMonth(currentState.selectedMonth));
        },
      );
    }
  }

  Future<void> _onLoadBudgets(
    LoadBudgets event,
    Emitter<ExpenseState> emit,
  ) async {
    final result = await getAllBudgets(NoParams());

    result.fold(
      (failure) => emit(const ExpenseError('Failed to load budgets')),
      (budgets) {
        if (state is ExpenseLoaded) {
          final currentState = state as ExpenseLoaded;
          emit(currentState.copyWith(budgets: budgets));
        }
      },
    );
  }

  Future<void> _onLoadBudgetByMonth(
    LoadBudgetByMonth event,
    Emitter<ExpenseState> emit,
  ) async {
    final result = await getBudgetByMonth(
      GetBudgetByMonthParams(year: event.year, month: event.month),
    );

    result.fold(
      (failure) => emit(const ExpenseError('Failed to load budget')),
      (budget) {
        if (state is ExpenseLoaded) {
          final currentState = state as ExpenseLoaded;
          emit(currentState.copyWith(currentBudget: budget));
        }
      },
    );
  }

  Future<void> _onSetBudget(
    SetBudgetEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;

      final result = await setBudget(SetBudgetParams(budget: event.budget));

      result.fold(
        (failure) => emit(const ExpenseError('Failed to set budget')),
        (_) {
          add(ChangeSelectedMonth(currentState.selectedMonth));
        },
      );
    }
  }

  Future<void> _onDeleteBudget(
    DeleteBudgetEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;

      final result = await deleteBudget(DeleteBudgetParams(id: event.id));

      result.fold(
        (failure) => emit(const ExpenseError('Failed to delete budget')),
        (_) {
          emit(const ExpenseOperationSuccess('Budget deleted successfully'));
          add(LoadBudgets());
          add(
            LoadBudgetByMonth(
              currentState.selectedMonth.year,
              currentState.selectedMonth.month,
            ),
          );
        },
      );
    }
  }

  Future<void> _onSearchSessions(
    SearchSessionsEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;

      if (event.query.isEmpty) {
        emit(
          currentState.copyWith(
            searchResults: [],
            searchQuery: null,
            isSearching: false,
            clearSearchQuery: true,
            clearSearchResults: true,
          ),
        );
        return;
      }

      final result = await searchSessions(
        SearchSessionsParams(query: event.query),
      );

      result.fold(
        (failure) => emit(const ExpenseError('Failed to search sessions')),
        (searchResults) {
          emit(
            currentState.copyWith(
              searchResults: searchResults,
              searchQuery: event.query,
              isSearching: true,
            ),
          );
        },
      );
    }
  }

  Future<void> _onLoadYearlyExpenseSummary(
    LoadYearlyExpenseSummary event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;

      final result = await getYearlyExpenseSummary(
        GetYearlyExpenseSummaryParams(year: event.year),
      );

      result.fold(
        (failure) => emit(const ExpenseError('Failed to load yearly summary')),
        (summary) {
          emit(currentState.copyWith(yearlyExpenseSummary: summary));
        },
      );
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<ExpenseState> emit,
  ) async {
    if (state is ExpenseLoaded) {
      final currentState = state as ExpenseLoaded;
      emit(
        currentState.copyWith(
          searchResults: [],
          searchQuery: null,
          isSearching: false,
          clearSearchQuery: true,
          clearSearchResults: true,
        ),
      );
    }
  }

  Future<void> _onChangeSelectedMonth(
    ChangeSelectedMonth event,
    Emitter<ExpenseState> emit,
  ) async {
    add(LoadSessionsByMonth(event.month.year, event.month.month));
  }
}
