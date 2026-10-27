import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/habit_repository.dart';
import '../domain/habit.dart';

abstract class HabitReminders {
  Future<void> schedule(Habit h);
  Future<void> cancel(String id);
}

class HabitsState {
  final List<Habit> habits;
  final Map<String, Set<String>> checks;
  final bool loading;
  const HabitsState({
    this.habits = const [],
    this.checks = const {},
    this.loading = true,
  });

  List<Habit> get active => habits.where((h) => !h.archived).toList();
  HabitStats statsFor(Habit h) => HabitStats(h, checks[h.id] ?? const {});
}

class HabitCubit extends Cubit<HabitsState> {
  final HabitRepository _repo;
  final HabitReminders _reminders;

  HabitCubit(this._repo, this._reminders) : super(const HabitsState());

  Future<void> load() async => emit(
    HabitsState(
      habits: await _repo.all(),
      checks: await _repo.allChecks(),
      loading: false,
    ),
  );

  Future<void> save(Habit h) async {
    await _repo.save(h);
    if (h.archived || h.reminderMinutes == null) {
      await _reminders.cancel(h.id);
    } else {
      await _reminders.schedule(h);
    }
    await load();
  }

  Future<void> delete(String id) async {
    await _reminders.cancel(id);
    await _repo.delete(id);
    await load();
  }

  /// Ticks [day] on or off. Answers the new state.
  Future<bool> toggle(Habit h, DateTime day) async {
    final key = dayKey(day);
    final now = !(state.checks[h.id]?.contains(key) ?? false);
    await _repo.setChecked(h.id, key, now);
    // Update in place rather than reloading: a tap should feel instant.
    final checks = {
      for (final e in state.checks.entries) e.key: {...e.value},
    };
    final set = checks[h.id] ??= {};
    now ? set.add(key) : set.remove(key);
    emit(HabitsState(habits: state.habits, checks: checks, loading: false));
    return now;
  }
}
