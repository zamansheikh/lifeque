import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prayers that can be owed: the five fard and Witr.
const qazaPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha', 'Witr'];

/// One prayer or fast made up, for the history and for undo.
@immutable
class QazaEntry {
  /// A prayer name, or [QazaStore.fast].
  final String what;
  final DateTime at;
  const QazaEntry(this.what, this.at);

  Map<String, Object> toJson() => {'w': what, 't': at.millisecondsSinceEpoch};
  static QazaEntry? fromJson(Object? j) {
    if (j is! Map) return null;
    final w = j['w'], t = j['t'];
    if (w is! String || t is! int) return null;
    return QazaEntry(w, DateTime.fromMillisecondsSinceEpoch(t));
  }
}

/// What is owed — missed prayers and fasts — and what has been made up.
///
/// One small JSON value in settings storage, so it travels with backups.
class QazaStore extends ChangeNotifier {
  QazaStore._();
  static final QazaStore instance = QazaStore._();

  @visibleForTesting
  QazaStore.forTesting();

  static const key = 'qaza_v1';
  static const fast = 'Fast';
  static const _logCap = 500;

  final Map<String, int> owed = {
    for (final p in [...qazaPrayers, fast]) p: 0,
  };
  final Map<String, int> made = {
    for (final p in [...qazaPrayers, fast]) p: 0,
  };
  final List<QazaEntry> log = [];
  bool loaded = false;

  int get prayersOwed => qazaPrayers.fold(0, (s, p) => s + owed[p]!);
  int get prayersMade => qazaPrayers.fold(0, (s, p) => s + made[p]!);

  /// Made up today, of anything.
  int madeOn(DateTime day) => log
      .where(
        (e) =>
            e.at.year == day.year &&
            e.at.month == day.month &&
            e.at.day == day.day,
      )
      .length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    owed.updateAll((_, _) => 0);
    made.updateAll((_, _) => 0);
    log.clear();
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        void read(Map<String, int> into, Object? from) {
          if (from is! Map) return;
          for (final k in into.keys) {
            final v = from[k];
            if (v is int && v >= 0) into[k] = v;
          }
        }

        read(owed, j['owed']);
        read(made, j['made']);
        for (final e in (j['log'] as List? ?? const [])) {
          final entry = QazaEntry.fromJson(e);
          if (entry != null) log.add(entry);
        }
      } catch (e) {
        debugPrint('🕌 Qaza record unreadable, starting empty: $e');
      }
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'owed': owed,
        'made': made,
        'log': [for (final e in log.take(_logCap)) e.toJson()],
      }),
    );
    notifyListeners();
  }

  /// Adds to (or, negative, corrects) what is owed for [what].
  Future<void> addOwed(String what, int n) async {
    owed[what] = (owed[what]! + n).clamp(0, 1000000);
    await _save();
  }

  /// [days] days of every prayer (and Witr) missed — the usual way people
  /// reckon it: "about two years".
  Future<void> addDays(int days, {bool fasts = false}) async {
    for (final p in qazaPrayers) {
      owed[p] = owed[p]! + days;
    }
    if (fasts) owed[fast] = owed[fast]! + days;
    await _save();
  }

  Future<void> addAll(Map<String, int> counts) async {
    counts.forEach((p, n) {
      if (owed.containsKey(p) && n > 0) owed[p] = owed[p]! + n;
    });
    await _save();
  }

  /// One prayer (or fast) made up. Does nothing when nothing is owed.
  Future<bool> makeUp(String what, {DateTime? at}) async {
    if (owed[what]! <= 0) return false;
    owed[what] = owed[what]! - 1;
    made[what] = made[what]! + 1;
    log.insert(0, QazaEntry(what, at ?? DateTime.now()));
    await _save();
    return true;
  }

  /// Takes back the last one made up — a mis-tap.
  Future<QazaEntry?> undo() async {
    if (log.isEmpty) return null;
    final last = log.removeAt(0);
    owed[last.what] = owed[last.what]! + 1;
    made[last.what] = (made[last.what]! - 1).clamp(0, 1000000);
    await _save();
    return last;
  }
}
