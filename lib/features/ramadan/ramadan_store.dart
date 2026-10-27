import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../qaza/qaza_store.dart';
import '../../core/utils/hijri_date.dart';

/// How one day of Ramadan went.
enum FastStatus {
  fasted,
  missed,

  /// Illness, travel, menstruation: allowed, but still to be made up.
  excused;

  bool get owesQaza => this != fasted;
}

/// The Gregorian date of each day of Ramadan in Hijri [year], by the
/// calculated calendar. 29 or 30 entries.
List<DateTime> ramadanDays(int year) {
  final first = HijriDate.toGregorian(year, 9, 1);
  final start = DateTime(first.year, first.month, first.day);
  final out = <DateTime>[];
  for (var i = 0; i < 30; i++) {
    final d = DateTime(start.year, start.month, start.day + i);
    final h = HijriDate.of(d);
    if (h.hMonth != 9) break;
    out.add(d);
  }
  return out;
}

/// The fasting log and taraweeh nights, per Hijri year.
///
/// A fast marked missed or excused is added to what [QazaStore] counts as
/// owed, and taken off again if the mark changes — so the two never
/// disagree. One small JSON value in settings storage, so it travels with
/// backups.
class RamadanStore extends ChangeNotifier {
  RamadanStore._(this._qaza);
  static final RamadanStore instance = RamadanStore._(QazaStore.instance);

  @visibleForTesting
  RamadanStore.forTesting(this._qaza);

  static const key = 'ramadan_v1';

  final QazaStore _qaza;

  /// year → day (1–30) → status.
  final Map<int, Map<int, FastStatus>> _fasts = {};

  /// year → nights (1–30) taraweeh was prayed.
  final Map<int, Set<int>> _taraweeh = {};
  bool loaded = false;

  FastStatus? fastOn(int year, int day) => _fasts[year]?[day];
  bool taraweehOn(int year, int day) => _taraweeh[year]?.contains(day) ?? false;

  int count(int year, FastStatus s) =>
      _fasts[year]?.values.where((v) => v == s).length ?? 0;
  int taraweehCount(int year) => _taraweeh[year]?.length ?? 0;

  /// Years with anything recorded, newest first.
  List<int> get years =>
      ({..._fasts.keys, ..._taraweeh.keys}.toList()..sort()).reversed.toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _fasts.clear();
    _taraweeh.clear();
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        j.forEach((y, v) {
          final year = int.tryParse(y);
          if (year == null || v is! Map) return;
          final fasts = v['f'];
          if (fasts is Map) {
            final m = _fasts[year] = {};
            fasts.forEach((d, s) {
              final day = int.tryParse('$d');
              if (day != null && s is int && s >= 0 && s < 3) {
                m[day] = FastStatus.values[s];
              }
            });
          }
          final t = v['t'];
          if (t is List) _taraweeh[year] = {...t.whereType<int>()};
        });
      } catch (e) {
        debugPrint('🌙 Ramadan record unreadable, starting empty: $e');
      }
    }
    if (!_qaza.loaded) await _qaza.load();
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final years = {..._fasts.keys, ..._taraweeh.keys};
    await prefs.setString(
      key,
      jsonEncode({
        for (final y in years)
          '$y': {
            'f': {
              for (final e in (_fasts[y] ?? const {}).entries)
                '${e.key}': e.value.index,
            },
            't': (_taraweeh[y] ?? const <int>{}).toList()..sort(),
          },
      }),
    );
    notifyListeners();
  }

  /// Marks [day] of Ramadan [year]; null clears it.
  Future<void> setFast(int year, int day, FastStatus? status) async {
    final m = _fasts[year] ??= {};
    final before = m[day];
    if (before == status) return;
    status == null ? m.remove(day) : m[day] = status;
    final owedBefore = before?.owesQaza ?? false;
    final owedNow = status?.owesQaza ?? false;
    if (owedBefore != owedNow) {
      await _qaza.addOwed(QazaStore.fast, owedNow ? 1 : -1);
    }
    await _save();
  }

  Future<void> setTaraweeh(int year, int day, bool prayed) async {
    final s = _taraweeh[year] ??= {};
    prayed ? s.add(day) : s.remove(day);
    await _save();
  }
}
