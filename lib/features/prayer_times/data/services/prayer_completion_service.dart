import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which of the five daily prayers the user has marked as prayed on
/// a given calendar date. Backed by SharedPreferences, keyed by ISO date
/// ('yyyy-MM-dd'). Also exposes a rolling streak count.
class PrayerCompletionService {
  static const _prefsKey = 'prayer_completions_v1';
  static const _prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  static final PrayerCompletionService instance = PrayerCompletionService._();
  PrayerCompletionService._();

  static String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<Map<String, dynamic>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  /// Returns the set of prayer names marked complete for [date].
  Future<Set<String>> getCompletions(DateTime date) async {
    final all = await _readAll();
    final list = (all[_dateKey(date)] as List?)?.cast<String>() ?? const [];
    return list.toSet();
  }

  /// Toggle the completion state for [prayer] on [date].
  /// Returns the new state (true = now completed).
  Future<bool> toggle(DateTime date, String prayer) async {
    final all = await _readAll();
    final key = _dateKey(date);
    final list = ((all[key] as List?)?.cast<String>() ?? const []).toSet();
    final nowOn = !list.contains(prayer);
    if (nowOn) {
      list.add(prayer);
    } else {
      list.remove(prayer);
    }
    all[key] = list.toList();
    await _writeAll(all);
    return nowOn;
  }

  /// How many consecutive past days (including yesterday) had ALL five
  /// prayers logged. Today is excluded so the streak doesn't flicker while
  /// the user is still completing today's prayers.
  Future<int> getCurrentStreak() async {
    final all = await _readAll();
    int streak = 0;
    var cursor = DateTime.now().subtract(const Duration(days: 1));
    while (true) {
      final list = (all[_dateKey(cursor)] as List?)?.cast<String>() ?? const [];
      if (list.toSet().containsAll(_prayers)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// How many of the five prayers were logged on [date].
  Future<int> countFor(DateTime date) async =>
      (await getCompletions(date)).length;

  /// Prayed-counts for the [days] days ending today, oldest first.
  ///
  /// Backs both the weekly bar chart and the 30-day heatmap, so it reads the
  /// whole store once rather than hitting SharedPreferences per day.
  Future<List<int>> recentCounts(int days) async {
    final all = await _readAll();
    final today = DateTime.now();
    return [
      for (var i = days - 1; i >= 0; i--)
        ((all[_dateKey(today.subtract(Duration(days: i)))] as List?)
                    ?.cast<String>() ??
                const [])
            .toSet()
            .length,
    ];
  }

  /// Share of the last [days] days' prayers that were logged, 0..1.
  Future<double> completionRate(int days) async {
    final counts = await recentCounts(days);
    if (counts.isEmpty) return 0;
    final total = counts.fold<int>(0, (a, b) => a + b);
    return total / (counts.length * _prayers.length);
  }
}
