import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/subscription_repository.dart';
import '../domain/subscription.dart';

/// What the subscription screens need from notifications. A seam so tests
/// can see what gets scheduled.
abstract class SubscriptionReminders {
  Future<void> schedule(Subscription s);
  Future<void> cancel(String id);
}

/// Records a paid renewal as an expense, in taka.
typedef LogExpense =
    Future<void> Function(Subscription s, double amountLocal, DateTime at);

class SubscriptionsState {
  final List<Subscription> items;
  final bool loading;
  const SubscriptionsState({this.items = const [], this.loading = true});
}

class SubscriptionCubit extends Cubit<SubscriptionsState> {
  final SubscriptionRepository _repo;
  final SubscriptionReminders _reminders;
  final LogExpense _logExpense;
  final DateTime Function() _now;

  SubscriptionCubit(
    this._repo,
    this._reminders,
    this._logExpense, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       super(const SubscriptionsState());

  Future<void> load() async {
    final items = await _repo.all();
    emit(SubscriptionsState(items: items, loading: false));
  }

  Future<void> save(Subscription s) async {
    await _repo.save(s);
    await _reminders.schedule(s);
    await load();
  }

  Future<void> delete(String id) async {
    await _reminders.cancel(id);
    await _repo.delete(id);
    await load();
  }

  /// Cancelled subscriptions stay listed but stop counting and reminding.
  Future<void> setActive(Subscription s, bool active) =>
      save(s.copyWith(isActive: active));

  /// The current renewal is paid: move to the next one, and — when
  /// [amountLocal] is given — record it as an expense.
  Future<Subscription> markPaid(
    Subscription s, {
    double? amountLocal,
    bool logExpense = true,
  }) async {
    final now = _now();
    final paid = s.afterPayment(
      paidAt: now,
      paidLocal: s.isLocalCurrency ? null : amountLocal,
    );
    await save(paid);
    if (logExpense && amountLocal != null && amountLocal > 0) {
      await _logExpense(s, amountLocal, now);
    }
    return paid;
  }
}
