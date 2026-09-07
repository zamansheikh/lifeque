import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which birthdays have been wished this year, and the sender name to
/// prefill next time.
///
/// Kept out of the task row on purpose: "wished" is about this year only and
/// resets on its own, which a column on the task would need a migration and
/// a yearly sweep to model. A preference keyed by task id with the year as
/// the value does the same job with none of that.
class BirthdayWishLog extends ChangeNotifier {
  BirthdayWishLog._();
  static final instance = BirthdayWishLog._();

  static const _prefix = 'birthday_wished_';
  static const _fromKey = 'birthday_wish_from';

  final Map<String, int> _years = {};
  String _from = '';
  bool _loaded = false;

  /// The sender name used last time, so it is typed once.
  String get from => _from;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix)) continue;
      final year = prefs.getInt(key);
      if (year != null) _years[key.substring(_prefix.length)] = year;
    }
    _from = prefs.getString(_fromKey) ?? '';
    _loaded = true;
    notifyListeners();
  }

  bool wishedThisYear(String taskId) => _years[taskId] == DateTime.now().year;

  Future<void> markWished(String taskId) async {
    final year = DateTime.now().year;
    _years[taskId] = year;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$taskId', year);
  }

  Future<void> rememberFrom(String name) async {
    final trimmed = name.trim();
    if (trimmed == _from) return;
    _from = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fromKey, trimmed);
  }
}
