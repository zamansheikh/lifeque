part of 'expense_bloc.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadSessions extends ExpenseEvent {}

class LoadSessionsByMonth extends ExpenseEvent {
  final int year;
  final int month;

  const LoadSessionsByMonth(this.year, this.month);

  @override
  List<Object> get props => [year, month];
}

class AddSessionEvent extends ExpenseEvent {
  final ExpenseSession session;

  const AddSessionEvent(this.session);

  @override
  List<Object> get props => [session];
}

class UpdateSessionEvent extends ExpenseEvent {
  final ExpenseSession session;

  const UpdateSessionEvent(this.session);

  @override
  List<Object> get props => [session];
}

class DeleteSessionEvent extends ExpenseEvent {
  final String id;

  const DeleteSessionEvent(this.id);

  @override
  List<Object> get props => [id];
}

class AddItemToSessionEvent extends ExpenseEvent {
  final String sessionId;
  final ExpenseItem item;

  const AddItemToSessionEvent(this.sessionId, this.item);

  @override
  List<Object> get props => [sessionId, item];
}

class UpdateItemInSessionEvent extends ExpenseEvent {
  final String sessionId;
  final ExpenseItem item;

  const UpdateItemInSessionEvent(this.sessionId, this.item);

  @override
  List<Object> get props => [sessionId, item];
}

class DeleteItemFromSessionEvent extends ExpenseEvent {
  final String sessionId;
  final String itemId;

  const DeleteItemFromSessionEvent(this.sessionId, this.itemId);

  @override
  List<Object> get props => [sessionId, itemId];
}

class ToggleItemPurchasedEvent extends ExpenseEvent {
  final String sessionId;
  final String itemId;

  const ToggleItemPurchasedEvent(this.sessionId, this.itemId);

  @override
  List<Object> get props => [sessionId, itemId];
}

class LoadBudgets extends ExpenseEvent {}

class LoadBudgetByMonth extends ExpenseEvent {
  final int year;
  final int month;

  const LoadBudgetByMonth(this.year, this.month);

  @override
  List<Object> get props => [year, month];
}

class SetBudgetEvent extends ExpenseEvent {
  final MonthlyBudget budget;

  const SetBudgetEvent(this.budget);

  @override
  List<Object> get props => [budget];
}

class DeleteBudgetEvent extends ExpenseEvent {
  final String id;

  const DeleteBudgetEvent(this.id);

  @override
  List<Object> get props => [id];
}

// Category Budget Events
class LoadCategoryBudgets extends ExpenseEvent {}

class LoadCategoryBudgetsForMonth extends ExpenseEvent {
  final int year;
  final int month;

  const LoadCategoryBudgetsForMonth(this.year, this.month);

  @override
  List<Object> get props => [year, month];
}

class SetCategoryBudgetEvent extends ExpenseEvent {
  final CategoryBudget budget;

  const SetCategoryBudgetEvent(this.budget);

  @override
  List<Object> get props => [budget];
}

class DeleteCategoryBudgetEvent extends ExpenseEvent {
  final String id;

  const DeleteCategoryBudgetEvent(this.id);

  @override
  List<Object> get props => [id];
}

class SearchSessionsEvent extends ExpenseEvent {
  final String query;

  const SearchSessionsEvent(this.query);

  @override
  List<Object> get props => [query];
}

class LoadYearlyExpenseSummary extends ExpenseEvent {
  final int year;

  const LoadYearlyExpenseSummary(this.year);

  @override
  List<Object> get props => [year];
}

class ClearSearch extends ExpenseEvent {}

class ChangeSelectedMonth extends ExpenseEvent {
  final DateTime month;

  const ChangeSelectedMonth(this.month);

  @override
  List<Object> get props => [month];
}
