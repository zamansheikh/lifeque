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

  ExpenseLoaded copyWith({
    List<ExpenseSession>? sessions,
    List<MonthlyBudget>? budgets,
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
