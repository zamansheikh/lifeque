import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/salah_time_calculator.dart';
import '../../injection_container.dart' as di;
import '../../l10n/app_localizations.dart';
import '../prayer_times/data/services/prayer_settings_service.dart';
import '../prayer_times/presentation/widgets/month_timetable_sheet.dart';
import '../prayer_times/presentation/widgets/prayer_share_sheet.dart';
import '../tasks/domain/entities/task.dart';
import '../tasks/domain/repositories/task_repository.dart';
import '../tasks/presentation/widgets/birthday_wish/birthday_wish_log.dart';
import '../tasks/presentation/widgets/birthday_wish/birthday_wish_sheet.dart';

/// The kinds of gentle suggestion the app can make on opening.
enum NudgeKind {
  birthdayToday,
  birthdayTomorrow,
  setLocation,
  jumuahShare,
  monthTimetable,
  shareTimes,
}

/// One suggestion, chosen for today.
class Nudge {
  final NudgeKind kind;

  /// The birthday it is about, for the two birthday kinds.
  final Task? birthday;

  /// What the "shown" record is keyed by, so a nudge about one person's
  /// birthday does not silence another's.
  final String key;

  const Nudge(this.kind, {this.birthday, required this.key});
}

/// Decides which suggestion, if any, today deserves. Pure, so it is tested
/// without preferences or a clock.
///
/// Rules, in priority order:
///  1. A birthday today that has not been wished yet.
///  2. A birthday tomorrow.
///  3. No location saved.
///  4. Friday: share the day's times as a Jumu'ah greeting.
///  5. The first three days of a month: share the month's timetable.
///  6. Roughly one day in four, chosen by the date so it is stable within a
///     day: share today's times.
///
/// [seenToday] says whether a given key was already shown today (or, for the
/// month nudge, this month) — the picker skips those and moves down the list.
Nudge? pickNudge({
  required DateTime now,
  required List<Task> birthdays,
  required bool hasLocation,
  required bool Function(String taskId) wished,
  required bool Function(String key) seenToday,
}) {
  final today = DateTime(now.year, now.month, now.day);
  int daysUntil(Task t) {
    final n = t.nextOccurrence;
    return DateTime(n.year, n.month, n.day).difference(today).inDays;
  }

  for (final b in birthdays.where((b) => b.taskType == TaskType.birthday)) {
    if (daysUntil(b) == 0 && !wished(b.id)) {
      final key = 'bday_today_${b.id}';
      if (!seenToday(key)) {
        return Nudge(NudgeKind.birthdayToday, birthday: b, key: key);
      }
    }
  }
  for (final b in birthdays.where((b) => b.taskType == TaskType.birthday)) {
    if (daysUntil(b) == 1) {
      final key = 'bday_tomorrow_${b.id}';
      if (!seenToday(key)) {
        return Nudge(NudgeKind.birthdayTomorrow, birthday: b, key: key);
      }
    }
  }
  if (!hasLocation) {
    if (!seenToday('location')) {
      return const Nudge(NudgeKind.setLocation, key: 'location');
    }
    // Everything below needs a location.
    return null;
  }
  if (now.weekday == DateTime.friday && !seenToday('jumuah')) {
    return const Nudge(NudgeKind.jumuahShare, key: 'jumuah');
  }
  if (now.day <= 3) {
    final key = 'month_${now.year}_${now.month}';
    if (!seenToday(key)) return Nudge(NudgeKind.monthTimetable, key: key);
  }
  final dayStamp =
      now.year * 1000 + today.difference(DateTime(now.year)).inDays;
  if (dayStamp % 4 == 0 && !seenToday('share_times')) {
    return const Nudge(NudgeKind.shareTimes, key: 'share_times');
  }
  return null;
}

/// Runs the picker against real data and shows the result as a small sheet.
///
/// At most one nudge per day, whatever kind: people open the app for what
/// they came for, and a suggestion every time would train them to swipe it
/// away unread.
class DailyNudge {
  static const _dayKey = 'nudge_last_day';
  static const _seenPrefix = 'nudge_seen_';

  static String _stamp(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<bool> maybeShow(BuildContext context) async {
    final prefs = di.sl<SharedPreferences>();
    final now = DateTime.now();
    final today = _stamp(now);
    if (prefs.getString(_dayKey) == today) return false;

    final tasks = (await di.sl<TaskRepository>().getAllTasks()).fold(
      (_) => <Task>[],
      (list) => list,
    );
    final settings = PrayerSettingsService.instance;
    final location = await settings.getSavedLocation();
    await BirthdayWishLog.instance.load();

    final nudge = pickNudge(
      now: now,
      birthdays: tasks,
      hasLocation: location != null,
      wished: BirthdayWishLog.instance.wishedThisYear,
      seenToday: (key) {
        final seen = prefs.getString('$_seenPrefix$key');
        if (seen == null) return false;
        // Month keys carry the month in the key itself, so any record means
        // "already this month"; everything else is per day.
        return key.startsWith('month_') || seen == today;
      },
    );
    if (nudge == null) return false;

    await prefs.setString(_dayKey, today);
    await prefs.setString('$_seenPrefix${nudge.key}', today);
    if (!context.mounted) return false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => NudgeSheet(nudge: nudge, location: location),
    );
    return true;
  }
}

/// The suggestion itself: an icon, a line, a body, one action and a way out.
class NudgeSheet extends StatelessWidget {
  final Nudge nudge;
  final LocationData? location;

  const NudgeSheet({super.key, required this.nudge, required this.location});

  static const _pink = Color(0xFFDB2777);
  static const _green = Color(0xFF0F8A5F);
  static const _ink = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final name = nudge.birthday?.title.trim() ?? '';
    final (icon, color, title, body, action) = switch (nudge.kind) {
      NudgeKind.birthdayToday => (
        Icons.cake_rounded,
        _pink,
        l.nudgeBirthdayTodayTitle(name),
        l.nudgeBirthdayTodayBody,
        l.wishSendWishes,
      ),
      NudgeKind.birthdayTomorrow => (
        Icons.card_giftcard_rounded,
        _pink,
        l.nudgeBirthdayTomorrowTitle(name),
        l.nudgeBirthdayTomorrowBody,
        l.nudgeBirthdayTomorrowAction,
      ),
      NudgeKind.setLocation => (
        Icons.location_on_rounded,
        _green,
        l.nudgeLocationTitle,
        l.nudgeLocationBody,
        l.nudgeLocationAction,
      ),
      NudgeKind.jumuahShare => (
        Icons.mosque_rounded,
        _green,
        l.nudgeJumuahTitle,
        l.nudgeJumuahBody,
        l.nudgeShareTimesAction,
      ),
      NudgeKind.monthTimetable => (
        Icons.calendar_month_rounded,
        _green,
        l.nudgeMonthTitle,
        l.nudgeMonthBody,
        l.calShareTimetable,
      ),
      NudgeKind.shareTimes => (
        Icons.ios_share_rounded,
        _green,
        l.nudgeShareTimesTitle,
        l.nudgeShareTimesBody,
        l.nudgeShareTimesAction,
      ),
    };

    return Container(
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        18 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _act(context),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade600),
            child: Text(l.nudgeLater),
          ),
        ],
      ),
    );
  }

  Future<void> _act(BuildContext context) async {
    // Close the nudge first: what it opens is a sheet or a page of its own.
    Navigator.of(context).pop();
    final root = GoRouter.of(context);
    // The nudge's own context is going away with the pop; the navigator's is
    // the one that outlives it.
    final host = root.routerDelegate.navigatorKey.currentContext;
    if (host == null) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!host.mounted) return;

    switch (nudge.kind) {
      case NudgeKind.birthdayToday:
        await BirthdayWishSheet.show(host, nudge.birthday!);
      case NudgeKind.birthdayTomorrow:
        root.push('/birthdays');
      case NudgeKind.setLocation:
        root.push('/prayer-times');
      case NudgeKind.jumuahShare:
      case NudgeKind.shareTimes:
        final loc = location;
        if (loc == null) return;
        final settings = PrayerSettingsService.instance;
        final calc = SalahTimeCalculator(
          latitude: loc.latitude,
          longitude: loc.longitude,
          date: DateTime.now(),
          method: await settings.getCalculationMethod(),
          madhab: await settings.getMadhab(),
        );
        if (!host.mounted) return;
        await PrayerShareSheet.show(
          host,
          calculator: calc,
          date: DateTime.now(),
          locationName: loc.locationName.split(',').first.trim(),
        );
      case NudgeKind.monthTimetable:
        final loc = location;
        if (loc == null) return;
        final settings = PrayerSettingsService.instance;
        final method = await settings.getCalculationMethod();
        final madhab = await settings.getMadhab();
        if (!host.mounted) return;
        final now = DateTime.now();
        await MonthTimetableSheet.show(
          host,
          month: DateTime(now.year, now.month),
          latitude: loc.latitude,
          longitude: loc.longitude,
          method: method,
          madhab: madhab,
          locationName: loc.locationName.split(',').first.trim(),
        );
    }
  }
}
