import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/local_numbers.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../injection_container.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../domain/habit.dart';
import 'habit_cubit.dart';
import 'habit_ui.dart';

/// Today's habits: one tap to tick each, its streak, and the last week at a
/// glance.
class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final _cubit = di.sl<HabitCubit>();

  @override
  void initState() {
    super.initState();
    _cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: const AppDrawer(currentRoute: '/habits'),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          title: Text(
            l.navHabits,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: l.commonMenu,
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          key: const Key('habit-add'),
          tooltip: l.habitAdd,
          backgroundColor: const Color(0xFFF59E0B),
          onPressed: () => context.push('/habits/add'),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
        body: BlocBuilder<HabitCubit, HabitsState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            final habits = state.active;
            if (habits.isEmpty) return const _Empty();
            final now = DateTime.now();
            final today = habits.where((h) => h.isScheduled(now)).toList();
            final done = today
                .where((h) => state.statsFor(h).doneOn(now))
                .length;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: [
                _TodayCard(done: done, total: today.length, now: now),
                const SizedBox(height: 12),
                for (final h in habits)
                  _HabitCard(habit: h, stats: state.statsFor(h), now: now),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final int done, total;
  final DateTime now;
  const _TodayCard({
    required this.done,
    required this.total,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final share = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: share,
                  strokeWidth: 7,
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                ),
                Text(
                  '${N.of((share * 100).round())}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.MMMMEEEEd().format(now),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.habitTodayProgress(done, total),
                  key: const Key('habit-today'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final HabitStats stats;
  final DateTime now;
  const _HabitCard({
    required this.habit,
    required this.stats,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final color = habitColor(habit.color);
    final scheduled = habit.isScheduled(now);
    final done = stats.doneOn(now);
    final streak = stats.currentStreak(now);
    final cubit = context.read<HabitCubit>();

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        key: Key('habit-card-${habit.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/habits/view/${habit.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(habitIcon(habit.icon), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 15,
                              color: streak > 0
                                  ? const Color(0xFFEA580C)
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              l.habitStreakDays(streak),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (scheduled)
                    IconButton(
                      key: Key('habit-check-${habit.id}'),
                      iconSize: 34,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        cubit.toggle(habit, now);
                      },
                      icon: Icon(
                        done
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: done ? color : Colors.grey.shade400,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        l.habitNotToday,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _WeekDots(habit: habit, stats: stats, now: now, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

/// The last seven days. Tapping a past day fixes a forgotten tick.
class _WeekDots extends StatelessWidget {
  final Habit habit;
  final HabitStats stats;
  final DateTime now;
  final Color color;
  const _WeekDots({
    required this.habit,
    required this.stats,
    required this.now,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HabitCubit>();
    return Row(
      children: [
        for (var i = 6; i >= 0; i--)
          Expanded(
            child: Builder(
              builder: (_) {
                final day = DateTime(now.year, now.month, now.day - i);
                final on = habit.isScheduled(day);
                final done = stats.doneOn(day);
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: on ? () => cubit.toggle(habit, day) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      children: [
                        Text(
                          DateFormat.E().format(day),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: i == 0 ? color : Colors.grey.shade500,
                            fontWeight: i == 0
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: !on
                                ? Colors.transparent
                                : done
                                ? color
                                : color.withValues(alpha: 0.1),
                            border: on
                                ? null
                                : Border.all(color: Colors.grey.shade200),
                          ),
                          child: done
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 100),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              size: 44,
              color: Color(0xFFEA580C),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l.habitEmptyTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          l.habitEmptyBody,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l.habitSuggestions,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final idea in habitIdeas)
              ActionChip(
                avatar: Icon(
                  habitIcon(idea.$2),
                  size: 16,
                  color: habitColor(idea.$3),
                ),
                label: Text(idea.$1(l)),
                onPressed: () => context.push('/habits/add', extra: idea),
              ),
          ],
        ),
      ],
    );
  }
}
