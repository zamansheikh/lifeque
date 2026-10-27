import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/local_numbers.dart';
import '../../../injection_container.dart' as di;
import '../../../l10n/app_localizations.dart';
import '../domain/habit.dart';
import 'habit_cubit.dart';
import 'habit_ui.dart';

/// One habit up close: its streaks, its rate, and sixteen weeks of ticks.
class HabitDetailPage extends StatelessWidget {
  final String id;
  const HabitDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return BlocBuilder<HabitCubit, HabitsState>(
      bloc: di.sl<HabitCubit>(),
      builder: (context, state) {
        final habit = state.habits.where((h) => h.id == id).firstOrNull;
        if (habit == null) {
          return Scaffold(appBar: AppBar());
        }
        final stats = state.statsFor(habit);
        final color = habitColor(habit.color);
        final now = DateTime.now();
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            title: Text(habit.name, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                key: const Key('habit-edit'),
                tooltip: l.habitEdit,
                icon: const Icon(Icons.edit_rounded),
                onPressed: () => context.push('/habits/edit/${habit.id}'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.9,
                children: [
                  _Stat(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFEA580C),
                    label: l.habitCurrent,
                    value: l.habitDaysUnit(stats.currentStreak(now)),
                  ),
                  _Stat(
                    icon: Icons.emoji_events_rounded,
                    color: const Color(0xFFF59E0B),
                    label: l.habitBest,
                    value: l.habitDaysUnit(stats.bestStreak(now)),
                  ),
                  _Stat(
                    icon: Icons.insights_rounded,
                    color: color,
                    label: l.habitRate,
                    value: '${N.of((stats.rate(now) * 100).round())}%',
                  ),
                  _Stat(
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF059669),
                    label: l.habitTotal,
                    value: N.of(stats.checks.length),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l.habitHistory,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: _Heatmap(habit: habit, stats: stats, now: now),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _Stat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          child: Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

/// Sixteen weeks, one column per week, Monday on top. Tapping a day that
/// has passed (or today) ticks it on or off.
class _Heatmap extends StatelessWidget {
  static const _weeks = 16;
  final Habit habit;
  final HabitStats stats;
  final DateTime now;
  const _Heatmap({required this.habit, required this.stats, required this.now});

  @override
  Widget build(BuildContext context) {
    final color = habitColor(habit.color);
    final today = DateTime(now.year, now.month, now.day);
    // The Monday that starts the first column.
    final start = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1) - 7 * (_weeks - 1),
    );
    final created = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );
    final monday = DateTime(2024, 1, 1);

    return LayoutBuilder(
      builder: (context, box) {
        const labelWidth = 22.0;
        final cell = ((box.maxWidth - labelWidth) / _weeks).clamp(8.0, 22.0);
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    for (var d = 0; d < 7; d++)
                      SizedBox(
                        width: labelWidth,
                        height: cell,
                        child: d.isEven
                            ? Text(
                                DateFormat.E()
                                    .format(monday.add(Duration(days: d)))
                                    .characters
                                    .first,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
                for (var w = 0; w < _weeks; w++)
                  Column(
                    children: [
                      for (var d = 0; d < 7; d++)
                        _cell(
                          context,
                          DateTime(
                            start.year,
                            start.month,
                            start.day + w * 7 + d,
                          ),
                          today,
                          created,
                          cell,
                          color,
                        ),
                    ],
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _cell(
    BuildContext context,
    DateTime day,
    DateTime today,
    DateTime created,
    double size,
    Color color,
  ) {
    final future = day.isAfter(today);
    final scheduled = habit.isScheduled(day);
    final done = stats.doneOn(day);
    final Color fill;
    if (future) {
      fill = Colors.transparent;
    } else if (done) {
      fill = color;
    } else if (!scheduled || day.isBefore(created)) {
      fill = const Color(0xFFF1F5F9);
    } else {
      fill = color.withValues(alpha: 0.14);
    }
    return GestureDetector(
      onTap: future || !scheduled
          ? null
          : () => di.sl<HabitCubit>().toggle(habit, day),
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(1.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(size / 4),
            border: day == today ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
      ),
    );
  }
}
