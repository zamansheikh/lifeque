import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;

class DatabaseHelper {
  static const String _databaseName = 'remind_me.db';
  static const int _databaseVersion = 6; // Increased for birthday notifications

  // Public getter for database version
  static int get databaseVersion => _databaseVersion;

  static const String tableTask = 'tasks';
  static const String tableMedicine = 'medicines';
  static const String tableMedicineDose = 'medicine_doses';

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
  static const String columnBirthdayNotificationSchedule = 'birthdayNotificationSchedule';
  static const String columnCreatedAt = 'createdAt';
  static const String columnUpdatedAt = 'updatedAt';

  // Medicine table columns
  static const String columnMedicineName = 'name';
  static const String columnMedicineDescription = 'description';
  static const String columnMedicineType = 'type';
  static const String columnMealTiming = 'mealTiming';
  static const String columnDosage = 'dosage';
  static const String columnDosageUnit = 'dosageUnit';
  static const String columnTimesPerDay = 'timesPerDay';
  static const String columnNotificationTimes = 'notificationTimes';
  static const String columnDurationInDays = 'durationInDays';
  static const String columnMedicineStartDate = 'startDate';
  static const String columnMedicineEndDate = 'endDate';
  static const String columnStatus = 'status';
  static const String columnDoctorName = 'doctorName';
  static const String columnNotes = 'notes';

  // Medicine dose table columns
  static const String columnMedicineId = 'medicineId';
  static const String columnScheduledTime = 'scheduledTime';
  static const String columnDoseStatus = 'status';
  static const String columnTakenAt = 'takenAt';

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
      // Create tasks table
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
          $columnBirthdayNotificationSchedule TEXT,
          $columnCreatedAt INTEGER NOT NULL,
          $columnUpdatedAt INTEGER
        )
      ''');

      // Create medicines table
      await db.execute('''
        CREATE TABLE $tableMedicine (
          $columnId TEXT PRIMARY KEY,
          $columnMedicineName TEXT NOT NULL,
          $columnMedicineDescription TEXT,
          $columnMedicineType TEXT NOT NULL,
          $columnMealTiming TEXT NOT NULL,
          $columnDosage REAL NOT NULL,
          $columnDosageUnit TEXT NOT NULL,
          $columnTimesPerDay INTEGER NOT NULL,
          $columnNotificationTimes TEXT NOT NULL,
          $columnDurationInDays INTEGER NOT NULL,
          $columnMedicineStartDate INTEGER NOT NULL,
          $columnMedicineEndDate INTEGER,
          $columnStatus TEXT NOT NULL DEFAULT 'active',
          $columnDoctorName TEXT,
          $columnNotes TEXT,
          $columnCreatedAt INTEGER NOT NULL,
          $columnUpdatedAt INTEGER NOT NULL
        )
      ''');

      // Create medicine doses table
      await db.execute('''
        CREATE TABLE $tableMedicineDose (
          $columnId TEXT PRIMARY KEY,
          $columnMedicineId TEXT NOT NULL,
          $columnScheduledTime INTEGER NOT NULL,
          $columnDoseStatus TEXT NOT NULL DEFAULT 'pending',
          $columnTakenAt INTEGER,
          $columnNotes TEXT,
          $columnCreatedAt INTEGER NOT NULL,
          $columnUpdatedAt INTEGER NOT NULL,
          FOREIGN KEY ($columnMedicineId) REFERENCES $tableMedicine ($columnId) ON DELETE CASCADE
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
    if (oldVersion < 5) {
      // Create medicine tables
      await db.execute('''
        CREATE TABLE $tableMedicine (
          $columnId TEXT PRIMARY KEY,
          $columnMedicineName TEXT NOT NULL,
          $columnMedicineDescription TEXT,
          $columnMedicineType TEXT NOT NULL,
          $columnMealTiming TEXT NOT NULL,
          $columnDosage REAL NOT NULL,
          $columnDosageUnit TEXT NOT NULL,
          $columnTimesPerDay INTEGER NOT NULL,
          $columnNotificationTimes TEXT NOT NULL,
          $columnDurationInDays INTEGER NOT NULL,
          $columnMedicineStartDate INTEGER NOT NULL,
          $columnMedicineEndDate INTEGER,
          $columnStatus TEXT NOT NULL DEFAULT 'active',
          $columnDoctorName TEXT,
          $columnNotes TEXT,
          $columnCreatedAt INTEGER NOT NULL,
          $columnUpdatedAt INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE $tableMedicineDose (
          $columnId TEXT PRIMARY KEY,
          $columnMedicineId TEXT NOT NULL,
          $columnScheduledTime INTEGER NOT NULL,
          $columnDoseStatus TEXT NOT NULL DEFAULT 'pending',
          $columnTakenAt INTEGER,
          $columnNotes TEXT,
          $columnCreatedAt INTEGER NOT NULL,
          $columnUpdatedAt INTEGER NOT NULL,
          FOREIGN KEY ($columnMedicineId) REFERENCES $tableMedicine ($columnId) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 6) {
      // Add birthday notification schedule column
      await db.execute('''
        ALTER TABLE $tableTask ADD COLUMN $columnBirthdayNotificationSchedule TEXT
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
