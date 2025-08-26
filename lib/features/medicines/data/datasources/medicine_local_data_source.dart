import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/utils/database_helper.dart';
import '../../../../core/error/exceptions.dart' as app_exceptions;
import '../models/medicine_model.dart';
import '../models/medicine_dose_model.dart';

abstract class MedicineLocalDataSource {
  Future<List<MedicineModel>> getAllMedicines();
  Future<List<MedicineModel>> getActiveMedicines();
  Future<MedicineModel> getMedicineById(String id);
  Future<void> insertMedicine(MedicineModel medicine);
  Future<void> updateMedicine(MedicineModel medicine);
  Future<void> deleteMedicine(String id);

  Future<List<MedicineDoseModel>> getDosesForMedicine(String medicineId);
  Future<List<MedicineDoseModel>> getDosesForDate(DateTime date);
  Future<List<MedicineDoseModel>> getPendingDoses();
  Future<List<MedicineDoseModel>> getOverdueDoses();
  Future<void> insertDose(MedicineDoseModel dose);
  Future<void> updateDose(MedicineDoseModel dose);
  Future<void> markDoseAsTaken(String doseId);
  Future<void> markDoseAsSkipped(String doseId);
  Future<void> markDoseAsMissed(String doseId);
}

class MedicineLocalDataSourceImpl implements MedicineLocalDataSource {
  final DatabaseHelper databaseHelper;

  MedicineLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<MedicineModel>> getAllMedicines() async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableMedicine,
        orderBy: '${DatabaseHelper.columnCreatedAt} DESC',
      );
      return maps
          .map((map) => MedicineModel.fromJson(_convertFromDb(map)))
          .toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get all medicines: $e');
    }
  }

  @override
  Future<List<MedicineModel>> getActiveMedicines() async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableMedicine,
        where: '${DatabaseHelper.columnStatus} = ?',
        whereArgs: ['active'],
        orderBy: '${DatabaseHelper.columnCreatedAt} DESC',
      );
      return maps
          .map((map) => MedicineModel.fromJson(_convertFromDb(map)))
          .toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get active medicines: $e',
      );
    }
  }

  @override
  Future<MedicineModel> getMedicineById(String id) async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableMedicine,
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return MedicineModel.fromJson(_convertFromDb(maps.first));
      } else {
        throw app_exceptions.DatabaseException('Medicine not found');
      }
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get medicine: $e');
    }
  }

  @override
  Future<void> insertMedicine(MedicineModel medicine) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseHelper.tableMedicine,
        _convertToDb(medicine.toJson()),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to insert medicine: $e');
    }
  }

  @override
  Future<void> updateMedicine(MedicineModel medicine) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseHelper.tableMedicine,
        _convertToDb(medicine.toJson()),
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [medicine.id],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update medicine: $e');
    }
  }

  @override
  Future<void> deleteMedicine(String id) async {
    try {
      final db = await databaseHelper.database;
      // First delete all associated doses
      await db.delete(
        DatabaseHelper.tableMedicineDose,
        where: '${DatabaseHelper.columnMedicineId} = ?',
        whereArgs: [id],
      );
      // Then delete the medicine
      await db.delete(
        DatabaseHelper.tableMedicine,
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to delete medicine: $e');
    }
  }

  @override
  Future<List<MedicineDoseModel>> getDosesForMedicine(String medicineId) async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableMedicineDose,
        where: '${DatabaseHelper.columnMedicineId} = ?',
        whereArgs: [medicineId],
        orderBy: '${DatabaseHelper.columnScheduledTime} ASC',
      );
      return maps
          .map((map) => MedicineDoseModel.fromJson(_convertDoseFromDb(map)))
          .toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get doses for medicine: $e',
      );
    }
  }

  @override
  Future<List<MedicineDoseModel>> getDosesForDate(DateTime date) async {
    try {
      final db = await databaseHelper.database;
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableMedicineDose,
        where:
            '${DatabaseHelper.columnScheduledTime} >= ? AND ${DatabaseHelper.columnScheduledTime} < ?',
        whereArgs: [
          startOfDay.millisecondsSinceEpoch,
          endOfDay.millisecondsSinceEpoch,
        ],
        orderBy: '${DatabaseHelper.columnScheduledTime} ASC',
      );
      return maps
          .map((map) => MedicineDoseModel.fromJson(_convertDoseFromDb(map)))
          .toList();
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to get doses for date: $e',
      );
    }
  }

  @override
  Future<List<MedicineDoseModel>> getPendingDoses() async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableMedicineDose,
        where: '${DatabaseHelper.columnDoseStatus} = ?',
        whereArgs: ['pending'],
        orderBy: '${DatabaseHelper.columnScheduledTime} ASC',
      );
      return maps
          .map((map) => MedicineDoseModel.fromJson(_convertDoseFromDb(map)))
          .toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get pending doses: $e');
    }
  }

  @override
  Future<List<MedicineDoseModel>> getOverdueDoses() async {
    try {
      final db = await databaseHelper.database;
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableMedicineDose,
        where:
            '${DatabaseHelper.columnDoseStatus} = ? AND ${DatabaseHelper.columnScheduledTime} < ?',
        whereArgs: ['pending', oneHourAgo.millisecondsSinceEpoch],
        orderBy: '${DatabaseHelper.columnScheduledTime} ASC',
      );
      return maps
          .map((map) => MedicineDoseModel.fromJson(_convertDoseFromDb(map)))
          .toList();
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to get overdue doses: $e');
    }
  }

  @override
  Future<void> insertDose(MedicineDoseModel dose) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseHelper.tableMedicineDose,
        _convertDoseToDb(dose.toJson()),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to insert dose: $e');
    }
  }

  @override
  Future<void> updateDose(MedicineDoseModel dose) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseHelper.tableMedicineDose,
        _convertDoseToDb(dose.toJson()),
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [dose.id],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException('Failed to update dose: $e');
    }
  }

  @override
  Future<void> markDoseAsTaken(String doseId) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseHelper.tableMedicineDose,
        {
          DatabaseHelper.columnDoseStatus: 'taken',
          DatabaseHelper.columnTakenAt: DateTime.now().millisecondsSinceEpoch,
          DatabaseHelper.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [doseId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to mark dose as taken: $e',
      );
    }
  }

  @override
  Future<void> markDoseAsSkipped(String doseId) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseHelper.tableMedicineDose,
        {
          DatabaseHelper.columnDoseStatus: 'skipped',
          DatabaseHelper.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [doseId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to mark dose as skipped: $e',
      );
    }
  }

  @override
  Future<void> markDoseAsMissed(String doseId) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseHelper.tableMedicineDose,
        {
          DatabaseHelper.columnDoseStatus: 'missed',
          DatabaseHelper.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [doseId],
      );
    } catch (e) {
      throw app_exceptions.DatabaseException(
        'Failed to mark dose as missed: $e',
      );
    }
  }

  // Helper methods to convert between JSON and database format
  Map<String, dynamic> _convertToDb(Map<String, dynamic> json) {
    return {
      DatabaseHelper.columnId: json['id'],
      DatabaseHelper.columnMedicineName: json['name'],
      DatabaseHelper.columnMedicineDescription: json['description'],
      DatabaseHelper.columnMedicineType: json['type'],
      DatabaseHelper.columnMealTiming: json['mealTiming'],
      DatabaseHelper.columnDosage: json['dosage'],
      DatabaseHelper.columnDosageUnit: json['dosageUnit'],
      DatabaseHelper.columnTimesPerDay: json['timesPerDay'],
      DatabaseHelper.columnNotificationTimes: jsonEncode(
        json['notificationTimes'],
      ),
      DatabaseHelper.columnDurationInDays: json['durationInDays'],
      DatabaseHelper.columnMedicineStartDate: DateTime.parse(
        json['startDate'],
      ).millisecondsSinceEpoch,
      DatabaseHelper.columnMedicineEndDate: json['endDate'] != null
          ? DateTime.parse(json['endDate']).millisecondsSinceEpoch
          : null,
      DatabaseHelper.columnStatus: json['status'],
      DatabaseHelper.columnDoctorName: json['doctorName'],
      DatabaseHelper.columnNotes: json['notes'],
      DatabaseHelper.columnCreatedAt: DateTime.parse(
        json['createdAt'],
      ).millisecondsSinceEpoch,
      DatabaseHelper.columnUpdatedAt: DateTime.parse(
        json['updatedAt'],
      ).millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> _convertFromDb(Map<String, dynamic> dbMap) {
    return {
      'id': dbMap[DatabaseHelper.columnId],
      'name': dbMap[DatabaseHelper.columnMedicineName],
      'description': dbMap[DatabaseHelper.columnMedicineDescription],
      'type': dbMap[DatabaseHelper.columnMedicineType],
      'mealTiming': dbMap[DatabaseHelper.columnMealTiming],
      'dosage': dbMap[DatabaseHelper.columnDosage],
      'dosageUnit': dbMap[DatabaseHelper.columnDosageUnit],
      'timesPerDay': dbMap[DatabaseHelper.columnTimesPerDay],
      'notificationTimes': jsonDecode(
        dbMap[DatabaseHelper.columnNotificationTimes],
      ),
      'durationInDays': dbMap[DatabaseHelper.columnDurationInDays],
      'startDate': DateTime.fromMillisecondsSinceEpoch(
        dbMap[DatabaseHelper.columnMedicineStartDate],
      ).toIso8601String(),
      'endDate': dbMap[DatabaseHelper.columnMedicineEndDate] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              dbMap[DatabaseHelper.columnMedicineEndDate],
            ).toIso8601String()
          : null,
      'status': dbMap[DatabaseHelper.columnStatus],
      'doctorName': dbMap[DatabaseHelper.columnDoctorName],
      'notes': dbMap[DatabaseHelper.columnNotes],
      'createdAt': DateTime.fromMillisecondsSinceEpoch(
        dbMap[DatabaseHelper.columnCreatedAt],
      ).toIso8601String(),
      'updatedAt': DateTime.fromMillisecondsSinceEpoch(
        dbMap[DatabaseHelper.columnUpdatedAt],
      ).toIso8601String(),
    };
  }

  Map<String, dynamic> _convertDoseToDb(Map<String, dynamic> json) {
    return {
      DatabaseHelper.columnId: json['id'],
      DatabaseHelper.columnMedicineId: json['medicineId'],
      DatabaseHelper.columnScheduledTime: DateTime.parse(
        json['scheduledTime'],
      ).millisecondsSinceEpoch,
      DatabaseHelper.columnDoseStatus: json['status'],
      DatabaseHelper.columnTakenAt: json['takenAt'] != null
          ? DateTime.parse(json['takenAt']).millisecondsSinceEpoch
          : null,
      DatabaseHelper.columnNotes: json['notes'],
      DatabaseHelper.columnCreatedAt: DateTime.parse(
        json['createdAt'],
      ).millisecondsSinceEpoch,
      DatabaseHelper.columnUpdatedAt: DateTime.parse(
        json['updatedAt'],
      ).millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> _convertDoseFromDb(Map<String, dynamic> dbMap) {
    return {
      'id': dbMap[DatabaseHelper.columnId],
      'medicineId': dbMap[DatabaseHelper.columnMedicineId],
      'scheduledTime': DateTime.fromMillisecondsSinceEpoch(
        dbMap[DatabaseHelper.columnScheduledTime],
      ).toIso8601String(),
      'status': dbMap[DatabaseHelper.columnDoseStatus],
      'takenAt': dbMap[DatabaseHelper.columnTakenAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              dbMap[DatabaseHelper.columnTakenAt],
            ).toIso8601String()
          : null,
      'notes': dbMap[DatabaseHelper.columnNotes],
      'createdAt': DateTime.fromMillisecondsSinceEpoch(
        dbMap[DatabaseHelper.columnCreatedAt],
      ).toIso8601String(),
      'updatedAt': DateTime.fromMillisecondsSinceEpoch(
        dbMap[DatabaseHelper.columnUpdatedAt],
      ).toIso8601String(),
    };
  }
}
