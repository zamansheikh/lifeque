import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;

class DatabaseHelper {
  static const String _databaseName = 'remind_me.db';
  static const int _databaseVersion = 4;

  static const String tableTask = 'tasks';

  // Task table columns
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnDescription = 'description';
  static const String columnTaskType = 'taskType';
  static const String columnStartDate = 'startDate';
  static const String columnEndDate = 'endDate';
  static const String columnIsCompleted = 'isCompleted';
  static const String columnIsNotificationEnabled = 'isNotificationEnabled';
  static const String columnNotificationType = 'notificationType';
  static const String columnNotificationTime = 'notificationTime';
  static const String columnDailyNotificationHour = 'dailyNotificationHour';
  static const String columnDailyNotificationMinute = 'dailyNotificationMinute';
  static const String columnBeforeEndOption = 'beforeEndOption';
  static const String columnIsPinnedToNotification = 'isPinnedToNotification';
  static const String columnCreatedAt = 'createdAt';
  static const String columnUpdatedAt = 'updatedAt';

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), _databaseName);
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to initialize database: $e',
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE $tableTask (
          $columnId TEXT PRIMARY KEY,
          $columnTitle TEXT NOT NULL,
          $columnDescription TEXT NOT NULL,
          $columnTaskType INTEGER NOT NULL DEFAULT 0,
          $columnStartDate INTEGER NOT NULL,
          $columnEndDate INTEGER NOT NULL,
          $columnIsCompleted INTEGER NOT NULL DEFAULT 0,
          $columnIsNotificationEnabled INTEGER NOT NULL DEFAULT 1,
          $columnNotificationType INTEGER NOT NULL DEFAULT 0,
          $columnNotificationTime INTEGER,
          $columnDailyNotificationHour INTEGER,
          $columnDailyNotificationMinute INTEGER,
          $columnBeforeEndOption INTEGER,
          $columnIsPinnedToNotification INTEGER NOT NULL DEFAULT 0,
          $columnCreatedAt INTEGER NOT NULL,
          $columnUpdatedAt INTEGER
        )
      ''');
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to create tables: $e');
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add new columns for notification features
      await db.execute('''
        ALTER TABLE $tableTask ADD COLUMN $columnNotificationTime INTEGER
      ''');
      await db.execute('''
        ALTER TABLE $tableTask ADD COLUMN $columnIsPinnedToNotification INTEGER NOT NULL DEFAULT 0
      ''');
    }
    if (oldVersion < 3) {
      // Add new columns for enhanced notification features
      await db.execute('''
        ALTER TABLE $tableTask ADD COLUMN $columnNotificationType INTEGER NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE $tableTask ADD COLUMN $columnDailyNotificationHour INTEGER
      ''');
      await db.execute('''
        ALTER TABLE $tableTask ADD COLUMN $columnDailyNotificationMinute INTEGER
      ''');
      await db.execute('''
        ALTER TABLE $tableTask ADD COLUMN $columnBeforeEndOption INTEGER
      ''');
    }
    if (oldVersion < 4) {
      // Add taskType column for reminder feature
      await db.execute('''
        ALTER TABLE $tableTask ADD COLUMN $columnTaskType INTEGER NOT NULL DEFAULT 0
      ''');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
