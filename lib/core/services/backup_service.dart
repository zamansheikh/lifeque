import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Why a file could not be restored.
enum BackupProblem {
  /// Not JSON, or JSON that is not a LifeQue backup.
  notABackup,

  /// Made by a newer version of the app, in a format this one cannot read.
  tooNew,

  /// Looked right but writing it failed; nothing was changed.
  writeFailed,
}

class BackupException implements Exception {
  final BackupProblem problem;
  final Object? cause;
  const BackupException(this.problem, [this.cause]);

  @override
  String toString() => 'BackupException($problem, $cause)';
}

/// What a backup file holds, shown before restoring so nobody overwrites
/// their data with the wrong file.
class BackupSummary {
  final DateTime createdAt;
  final String? appVersion;

  /// Rows per table, e.g. `{tasks: 12, medicines: 3}`.
  final Map<String, int> rows;
  final int settings;

  const BackupSummary({
    required this.createdAt,
    required this.appVersion,
    required this.rows,
    required this.settings,
  });

  int rowsIn(String table) => rows[table] ?? 0;
}

/// One file with everything: every setting and every row of the app's
/// database, so moving to a new phone or reinstalling loses nothing.
///
/// Plain JSON, written and read through the system's own share sheet and file
/// picker — no storage permission is needed or asked for.
///
/// Restoring *replaces* what is on the phone. Only things that belong to this
/// device are left alone: scheduled-alarm bookkeeping, notification ids, a
/// study session in progress, and one-off prompt state. Those are rebuilt
/// from the restored data afterwards.
class BackupService {
  static const app = 'lifeque';

  /// Bumped only for changes an older app could not read.
  static const formatVersion = 1;

  /// Settings keys that describe this phone rather than the person.
  static const _deviceOnlyKeys = {
    'study_session_v2', // tied to alarms armed on this phone
    'medicine_notification_ids', // ids of notifications queued here
    'todo_notification_id_map',
    'update_prompt_day',
    'whats_new_last_seen_version',
    'widget_suggestion_dismissed_v1',
    'widget_suggestion_pinned_v1',
    'nudge_last_day',
  };

  static const _deviceOnlyPrefixes = [
    '__alarm_id__', // the alarm plugin's own record of what it has armed
    'nudge_seen_',
  ];

  static bool isDeviceOnly(String key) =>
      _deviceOnlyKeys.contains(key) ||
      _deviceOnlyPrefixes.any((p) => key.startsWith(p));

  final Future<Database> Function() _database;
  final Future<SharedPreferences> Function() _prefs;
  final String? appVersion;
  final DateTime Function() _now;

  BackupService({
    required Future<Database> Function() database,
    required Future<SharedPreferences> Function() prefs,
    this.appVersion,
    DateTime Function()? now,
  }) : _database = database,
       _prefs = prefs,
       _now = now ?? DateTime.now;

  /// `lifeque-backup-2026-10-27.json`.
  String fileName() {
    final d = _now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'lifeque-backup-${d.year}-${two(d.month)}-${two(d.day)}.json';
  }

  // ── Export ──────────────────────────────────────────────────────────────

  Future<String> export() async {
    final prefs = await _prefs();
    final settings = <String, Object>{};
    for (final key in prefs.getKeys().toList()..sort()) {
      if (isDeviceOnly(key)) continue;
      final encoded = _encodePref(prefs.get(key));
      if (encoded != null) settings[key] = encoded;
    }

    final db = await _database();
    final tables = <String, Object>{};
    for (final table in await _userTables(db)) {
      tables[table] = await db.query(table);
    }

    return const JsonEncoder.withIndent(' ').convert({
      'app': app,
      'format': formatVersion,
      'appVersion': appVersion,
      'createdAt': _now().toUtc().toIso8601String(),
      'dbVersion': await db.getVersion(),
      'settings': settings,
      'tables': tables,
    });
  }

  /// Settings values carry their type, so an int stays an int and a string
  /// list stays a list on the way back.
  static Map<String, Object>? _encodePref(Object? value) => switch (value) {
    final String v => {'t': 's', 'v': v},
    final bool v => {'t': 'b', 'v': v},
    final int v => {'t': 'i', 'v': v},
    final double v => {'t': 'd', 'v': v},
    final List<String> v => {'t': 'l', 'v': v},
    final List<Object?> v => {'t': 'l', 'v': v.map((e) => '$e').toList()},
    _ => null,
  };

  static Future<List<String>> _userTables(Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata' "
      'ORDER BY name',
    );
    return [for (final r in rows) r['name']! as String];
  }

  // ── Import ──────────────────────────────────────────────────────────────

  /// Reads [json] far enough to describe it. Throws [BackupException] for a
  /// file that is not a backup this app can restore.
  BackupSummary inspect(String json) {
    final data = _parse(json);
    final tables = data['tables'] as Map<String, dynamic>;
    return BackupSummary(
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      appVersion: data['appVersion'] as String?,
      rows: {
        for (final e in tables.entries)
          e.key: (e.value as List<dynamic>).length,
      },
      settings: (data['settings'] as Map<String, dynamic>).length,
    );
  }

  Map<String, dynamic> _parse(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (e) {
      throw BackupException(BackupProblem.notABackup, e);
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['app'] != app ||
        decoded['format'] is! int ||
        decoded['settings'] is! Map<String, dynamic> ||
        decoded['tables'] is! Map<String, dynamic>) {
      throw const BackupException(BackupProblem.notABackup);
    }
    if ((decoded['format'] as int) > formatVersion) {
      throw const BackupException(BackupProblem.tooNew);
    }
    return decoded;
  }

  /// Replaces this phone's data with [json]'s.
  ///
  /// The database is written in one transaction, so a failure part-way leaves
  /// it as it was. Settings are only touched once the database has been
  /// written.
  Future<void> restore(String json) async {
    final data = _parse(json);
    final tables = data['tables'] as Map<String, dynamic>;
    final settings = data['settings'] as Map<String, dynamic>;

    final db = await _database();
    try {
      final existing = (await _userTables(db)).toSet();
      await db.transaction((txn) async {
        for (final entry in tables.entries) {
          final table = entry.key;
          // A table this version does not have (a newer backup) is skipped
          // rather than invented.
          if (!existing.contains(table)) continue;
          final columns = await _columns(txn, table);
          await txn.delete(table);
          for (final row in entry.value as List<dynamic>) {
            final values = <String, Object?>{
              for (final c in (row as Map<String, dynamic>).entries)
                // Columns an older or newer schema has and this one does not
                // are dropped; missing ones take their defaults.
                if (columns.contains(c.key)) c.key: c.value,
            };
            await txn.insert(table, values);
          }
        }
      });
    } catch (e) {
      throw BackupException(BackupProblem.writeFailed, e);
    }

    // Write the backup's settings first, then drop whatever it does not
    // have — an interruption part-way leaves extra settings, never none.
    final prefs = await _prefs();
    final restored = <String>{};
    for (final entry in settings.entries) {
      if (isDeviceOnly(entry.key)) continue;
      await _writePref(prefs, entry.key, entry.value);
      restored.add(entry.key);
    }
    for (final key in prefs.getKeys().toList()) {
      if (!isDeviceOnly(key) && !restored.contains(key)) {
        await prefs.remove(key);
      }
    }
  }

  static Future<Set<String>> _columns(DatabaseExecutor db, String table) async {
    final info = await db.rawQuery('PRAGMA table_info("$table")');
    return {for (final c in info) c['name']! as String};
  }

  static Future<void> _writePref(
    SharedPreferences prefs,
    String key,
    Object? encoded,
  ) async {
    if (encoded is! Map<String, dynamic>) return;
    final v = encoded['v'];
    switch (encoded['t']) {
      case 's' when v is String:
        await prefs.setString(key, v);
      case 'b' when v is bool:
        await prefs.setBool(key, v);
      case 'i' when v is int:
        await prefs.setInt(key, v);
      case 'd' when v is num:
        await prefs.setDouble(key, v.toDouble());
      case 'l' when v is List:
        await prefs.setStringList(key, [for (final e in v) '$e']);
    }
  }
}
