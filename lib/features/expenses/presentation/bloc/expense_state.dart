part of 'expense_bloc.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpenseLoaded extends ExpenseState {
  final List<ExpenseSession> sessions;
  final List<MonthlyBudget> budgets;
  final List<CategoryBudget> categoryBudgets;
  final DateTime selectedMonth;
  final MonthlyBudget? currentBudget;
  final double monthlyTotal;
  final double monthlyPurchased;
  final double monthlyMissed;
  final Map<String, double>? yearlyExpenseSummary;
  final List<ExpenseSession> searchResults;
  final String? searchQuery;
  final bool isSearching;

  const ExpenseLoaded({
    required this.sessions,
    required this.budgets,
    this.categoryBudgets = const [],
    required this.selectedMonth,
    this.currentBudget,
    this.monthlyTotal = 0.0,
    this.monthlyPurchased = 0.0,
    this.monthlyMissed = 0.0,
    this.yearlyExpenseSummary,
    this.searchResults = const [],
    this.searchQuery,
    this.isSearching = false,
  });

  // Calculate spending by category for the selected month.
  // Keys are effectiveCategoryKey strings (e.g. 'food', 'custom:Home Rent').
  Map<String, double> getCategorySpending() {
    final Map<String, double> spending = {};

    // Get sessions for the selected month
    final monthSessions = sessions.where(
      (session) =>
          session.date.year == selectedMonth.year &&
          session.date.month == selectedMonth.month,
    );

    // Sum up purchased items by effectiveCategoryKey
    for (final session in monthSessions) {
      for (final item in session.items) {
        if (item.isPurchased) {
          final key = item.effectiveCategoryKey;
          spending[key] = (spending[key] ?? 0.0) + item.amount;
        }
      }
    }

    return spending;
  }

  ExpenseLoaded copyWith({
    List<ExpenseSession>? sessions,
    List<MonthlyBudget>? budgets,
    List<CategoryBudget>? categoryBudgets,
    DateTime? selectedMonth,
    MonthlyBudget? currentBudget,
    double? monthlyTotal,
    double? monthlyPurchased,
    double? monthlyMissed,
    Map<String, double>? yearlyExpenseSummary,
    List<ExpenseSession>? searchResults,
    String? searchQuery,
    bool? isSearching,
    bool clearCurrentBudget = false,
    bool clearYearlyExpenseSummary = false,
    bool clearSearchQuery = false,
    bool clearSearchResults = false,
  }) {
    return ExpenseLoaded(
      sessions: sessions ?? this.sessions,
      budgets: budgets ?? this.budgets,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      currentBudget: clearCurrentBudget
          ? null
          : (currentBudget ?? this.currentBudget),
      monthlyTotal: monthlyTotal ?? this.monthlyTotal,
      monthlyPurchased: monthlyPurchased ?? this.monthlyPurchased,
      monthlyMissed: monthlyMissed ?? this.monthlyMissed,
      yearlyExpenseSummary: clearYearlyExpenseSummary
          ? null
          : (yearlyExpenseSummary ?? this.yearlyExpenseSummary),
      searchResults: clearSearchResults
          ? const []
          : (searchResults ?? this.searchResults),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      isSearching: isSearching ?? this.isSearching,
    );
  }

  @override
  List<Object?> get props => [
    sessions,
    budgets,
    categoryBudgets,
    selectedMonth,
    currentBudget,
    monthlyTotal,
    monthlyPurchased,
    monthlyMissed,
    yearlyExpenseSummary,
    searchResults,
    searchQuery,
    isSearching,
  ];
}

class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError(this.message);

  @override
  List<Object> get props => [message];
}

class ExpenseOperationSuccess extends ExpenseState {
  final String message;

  const ExpenseOperationSuccess(this.message);

  @override
  List<Object> get props => [message];
}
