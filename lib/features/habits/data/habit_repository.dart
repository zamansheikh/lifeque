import 'package:sqflite/sqflite.dart';

import '../../../core/utils/database_helper.dart';
import '../domain/habit.dart';

class HabitRepository {
  final DatabaseHelper _db;
  HabitRepository(this._db);

  Future<List<Habit>> all() async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableHabits,
      orderBy: 'sortOrder ASC, createdAt ASC',
    );
    return rows.map(Habit.fromMap).toList();
  }

  Future<Map<String, Set<String>>> allChecks() async {
    final db = await _db.database;
    final rows = await db.query(DatabaseHelper.tableHabitChecks);
    final out = <String, Set<String>>{};
    for (final r in rows) {
      (out[r['habitId']! as String] ??= {}).add(r['day']! as String);
    }
    return out;
  }

  Future<void> save(Habit h) async {
    final db = await _db.database;
    await db.insert(
      DatabaseHelper.tableHabits,
      h.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableHabits,
      where: 'id = ?',
      whereArgs: [id],
    );
    await db.delete(
      DatabaseHelper.tableHabitChecks,
      where: 'habitId = ?',
      whereArgs: [id],
    );
  }

  Future<void> setChecked(String habitId, String day, bool checked) async {
    final db = await _db.database;
    if (checked) {
      await db.insert(DatabaseHelper.tableHabitChecks, {
        'habitId': habitId,
        'day': day,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete(
        DatabaseHelper.tableHabitChecks,
        where: 'habitId = ? AND day = ?',
        whereArgs: [habitId, day],
      );
    }
  }
}
