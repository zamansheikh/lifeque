import 'package:sqflite/sqflite.dart';

import '../../../core/utils/database_helper.dart';
import '../domain/subscription.dart';

/// Subscriptions in the app database — and so in every backup, which copies
/// all tables.
class SubscriptionRepository {
  final DatabaseHelper _db;
  SubscriptionRepository(this._db);

  Future<List<Subscription>> all() async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableSubscriptions,
      orderBy: 'nextRenewal ASC',
    );
    return rows.map(Subscription.fromMap).toList();
  }

  Future<Subscription?> byId(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      DatabaseHelper.tableSubscriptions,
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : Subscription.fromMap(rows.first);
  }

  Future<void> save(Subscription s) async {
    final db = await _db.database;
    await db.insert(
      DatabaseHelper.tableSubscriptions,
      s.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete(
      DatabaseHelper.tableSubscriptions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
