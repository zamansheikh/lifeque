import 'package:sqflite/sqflite.dart';

import '../../../core/utils/database_helper.dart';
import '../domain/debt.dart';

class DebtRepository {
  final DatabaseHelper _db;
  DebtRepository(this._db);

  Future<List<Debt>> all() async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableDebts,
      orderBy: 'date DESC',
    );
    return rows.map(Debt.fromMap).toList();
  }

  Future<Debt?> byId(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableDebts,
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : Debt.fromMap(rows.first);
  }

  Future<void> save(Debt d) async {
    final db = await _db.database;
    await db.insert(
      DatabaseHelper.tableDebts,
      d.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableDebts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
