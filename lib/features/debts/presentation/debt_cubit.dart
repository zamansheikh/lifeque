import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/debt_repository.dart';
import '../domain/debt.dart';

/// Due-date reminders for debts. A seam so tests can see what is scheduled.
abstract class DebtReminders {
  Future<void> schedule(Debt d);
  Future<void> cancel(String id);
}

class DebtsState {
  final List<Debt> items;
  final bool loading;
  const DebtsState({this.items = const [], this.loading = true});

  /// What is still to come back to me, and what I still have to pay.
  double get toReceive => items
      .where((d) => d.theyOweMe && !d.isSettled)
      .fold(0, (s, d) => s + d.remaining);
  double get toPay => items
      .where((d) => !d.theyOweMe && !d.isSettled)
      .fold(0, (s, d) => s + d.remaining);
}

class DebtCubit extends Cubit<DebtsState> {
  final DebtRepository _repo;
  final DebtReminders _reminders;
  final DateTime Function() _now;

  DebtCubit(this._repo, this._reminders, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const DebtsState());

  Future<void> load() async =>
      emit(DebtsState(items: await _repo.all(), loading: false));

  Future<void> save(Debt d) async {
    await _repo.save(d);
    if (d.isSettled) {
      await _reminders.cancel(d.id);
    } else {
      await _reminders.schedule(d);
    }
    await load();
  }

  Future<void> delete(String id) async {
    await _reminders.cancel(id);
    await _repo.delete(id);
    await load();
  }

  Future<Debt> addPayment(Debt d, double amount) async {
    final next = d.withPayment(amount, _now());
    await save(next);
    return next;
  }

  /// Settled as it stands — the rest written off, or paid outside the app.
  Future<void> settle(Debt d) => save(d.copyWith(settledAt: _now()));

  Future<void> reopen(Debt d) => save(d.copyWith(clearSettled: true));
}
