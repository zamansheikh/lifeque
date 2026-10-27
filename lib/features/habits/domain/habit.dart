import 'package:equatable/equatable.dart';

/// "2026-10-27": how a checked day is stored.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Something to do regularly — on every day, or on chosen weekdays.
class Habit extends Equatable {
  static const everyDay = 0x7f;

  final String id;
  final String name;

  /// Index into the icon and colour choices.
  final int icon;
  final int color;

  /// Weekdays it applies to: bit 0 is Monday … bit 6 is Sunday.
  final int days;

  /// Daily reminder, as minutes after midnight; null for none.
  final int? reminderMinutes;
  final bool archived;
  final int sortOrder;
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.name,
    this.icon = 0,
    this.color = 0,
    this.days = everyDay,
    this.reminderMinutes,
    this.archived = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  bool onWeekday(int weekday) => days & (1 << (weekday - 1)) != 0;
  bool isScheduled(DateTime day) => onWeekday(day.weekday);

  Habit copyWith({
    String? name,
    int? icon,
    int? color,
    int? days,
    int? reminderMinutes,
    bool clearReminder = false,
    bool? archived,
    int? sortOrder,
  }) => Habit(
    id: id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    color: color ?? this.color,
    days: days ?? this.days,
    reminderMinutes: clearReminder
        ? null
        : (reminderMinutes ?? this.reminderMinutes),
    archived: archived ?? this.archived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    'days': days,
    'reminderMinutes': reminderMinutes,
    'archived': archived ? 1 : 0,
    'sortOrder': sortOrder,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Habit.fromMap(Map<String, Object?> m) => Habit(
    id: m['id']! as String,
    name: m['name']! as String,
    icon: m['icon'] as int? ?? 0,
    color: m['color'] as int? ?? 0,
    days: m['days'] as int? ?? everyDay,
    reminderMinutes: m['reminderMinutes'] as int?,
    archived: m['archived'] == 1,
    sortOrder: m['sortOrder'] as int? ?? 0,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt']! as int),
  );

  @override
  List<Object?> get props => [
    id,
    name,
    icon,
    color,
    days,
    reminderMinutes,
    archived,
    sortOrder,
    createdAt,
  ];
}

/// Streaks and rates for one habit's checked days.
///
/// Only the days a habit applies to count: a Friday-only habit done every
/// Friday has an unbroken streak, whatever happened on Saturday. Today
/// never breaks a streak — it isn't over yet.
class HabitStats {
  final Habit habit;
  final Set<String> checks;
  const HabitStats(this.habit, this.checks);

  bool doneOn(DateTime day) => checks.contains(dayKey(day));

  int currentStreak(DateTime now) {
    var day = _dateOnly(now);
    var streak = 0;
    if (habit.isScheduled(day) && doneOn(day)) streak++;
    day = day.subtract(const Duration(days: 1));
    final start = _dateOnly(habit.createdAt);
    for (var i = 0; i < 3660 && !day.isBefore(start); i++) {
      if (habit.isScheduled(day)) {
        if (!doneOn(day)) break;
        streak++;
      }
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return streak;
  }

  int bestStreak(DateTime now) {
    if (checks.isEmpty) return 0;
    final sorted = checks.toList()..sort();
    var day = DateTime.parse(sorted.first);
    final end = _dateOnly(now);
    var best = 0, run = 0;
    while (!day.isAfter(end)) {
      if (habit.isScheduled(day)) {
        if (doneOn(day)) {
          run++;
          if (run > best) best = run;
        } else if (day != end) {
          run = 0;
        }
      }
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return best;
  }

  /// Share of the scheduled days in the last [days] days (today included)
  /// that were done, counted from when the habit was made.
  double rate(DateTime now, {int days = 30}) {
    var scheduled = 0, done = 0;
    final start = _dateOnly(habit.createdAt);
    for (var i = 0; i < days; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      if (day.isBefore(start)) break;
      if (!habit.isScheduled(day)) continue;
      scheduled++;
      if (doneOn(day)) done++;
    }
    return scheduled == 0 ? 0 : done / scheduled;
  }
}
