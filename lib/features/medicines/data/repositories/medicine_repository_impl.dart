import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_dose.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../datasources/medicine_local_data_source.dart';
import '../models/medicine_model.dart';
import '../models/medicine_dose_model.dart';

class MedicineRepositoryImpl implements MedicineRepository {
  final MedicineLocalDataSource localDataSource;

  MedicineRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Medicine>>> getAllMedicines() async {
    try {
      final medicineModels = await localDataSource.getAllMedicines();
      final medicines = medicineModels
          .map((model) => model.toEntity())
          .toList();
      return Right(medicines);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to retrieve medicines'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Medicine>>> getActiveMedicines() async {
    try {
      final medicineModels = await localDataSource.getActiveMedicines();
      final medicines = medicineModels
          .map((model) => model.toEntity())
          .toList();
      return Right(medicines);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to retrieve active medicines'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, Medicine>> getMedicineById(String id) async {
    try {
      final medicineModel = await localDataSource.getMedicineById(id);
      return Right(medicineModel.toEntity());
    } on DatabaseException {
      return Left(DatabaseFailure('Medicine not found'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addMedicine(Medicine medicine) async {
    try {
      final medicineModel = MedicineModel.fromEntity(medicine);
      await localDataSource.insertMedicine(medicineModel);
      return const Right(null);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to create medicine'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateMedicine(Medicine medicine) async {
    try {
      final medicineModel = MedicineModel.fromEntity(medicine);
      await localDataSource.updateMedicine(medicineModel);
      return const Right(null);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to update medicine'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMedicine(String id) async {
    try {
      await localDataSource.deleteMedicine(id);
      return const Right(null);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to delete medicine'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MedicineDose>>> getDosesForMedicine(
    String medicineId,
  ) async {
    try {
      final doseModels = await localDataSource.getDosesForMedicine(medicineId);
      final doses = doseModels.map((model) => model.toEntity()).toList();
      return Right(doses);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to retrieve doses for medicine'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MedicineDose>>> getDosesForDate(
    DateTime date,
  ) async {
    try {
      final doseModels = await localDataSource.getDosesForDate(date);
      final doses = doseModels.map((model) => model.toEntity()).toList();
      return Right(doses);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to retrieve doses for date'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MedicineDose>>> getPendingDoses() async {
    try {
      final doseModels = await localDataSource.getPendingDoses();
      final doses = doseModels.map((model) => model.toEntity()).toList();
      return Right(doses);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to retrieve pending doses'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, List<MedicineDose>>> getOverdueDoses() async {
    try {
      final doseModels = await localDataSource.getOverdueDoses();
      final doses = doseModels.map((model) => model.toEntity()).toList();
      return Right(doses);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to retrieve overdue doses'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addDose(MedicineDose dose) async {
    try {
      final doseModel = MedicineDoseModel.fromEntity(dose);
      await localDataSource.insertDose(doseModel);
      return const Right(null);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to create dose'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateDose(MedicineDose dose) async {
    try {
      final doseModel = MedicineDoseModel.fromEntity(dose);
      await localDataSource.updateDose(doseModel);
      return const Right(null);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to update dose'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markDoseAsTaken(String doseId) async {
    try {
      await localDataSource.markDoseAsTaken(doseId);
      return const Right(null);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to mark dose as taken'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markDoseAsSkipped(String doseId) async {
    try {
      await localDataSource.markDoseAsSkipped(doseId);
      return const Right(null);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to mark dose as skipped'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markDoseAsMissed(String doseId) async {
    try {
      await localDataSource.markDoseAsMissed(doseId);
      return const Right(null);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to mark dose as missed'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getMedicineStatistics(
    String medicineId,
  ) async {
    try {
      final doses = await localDataSource.getDosesForMedicine(medicineId);

      final stats = <String, dynamic>{
        'total': doses.length,
        'taken': doses.where((dose) => dose.status == 'taken').length,
        'skipped': doses.where((dose) => dose.status == 'skipped').length,
        'missed': doses.where((dose) => dose.status == 'missed').length,
        'pending': doses.where((dose) => dose.status == 'pending').length,
      };

      return Right(stats);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to get medicine statistics'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getOverallStatistics() async {
    try {
      final allMedicines = await localDataSource.getAllMedicines();
      final allDoses = <dynamic>[];

      for (final medicine in allMedicines) {
        final doses = await localDataSource.getDosesForMedicine(medicine.id);
        allDoses.addAll(doses);
      }

      final stats = <String, dynamic>{
        'totalMedicines': allMedicines.length,
        'activeMedicines': allMedicines
            .where((m) => m.status == 'active')
            .length,
        'totalDoses': allDoses.length,
        'takenDoses': allDoses.where((dose) => dose.status == 'taken').length,
        'skippedDoses': allDoses
            .where((dose) => dose.status == 'skipped')
            .length,
        'missedDoses': allDoses.where((dose) => dose.status == 'missed').length,
        'pendingDoses': allDoses
            .where((dose) => dose.status == 'pending')
            .length,
      };

      return Right(stats);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to get overall statistics'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAdherenceData(
    String medicineId,
    int days,
  ) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));
      final adherenceData = <Map<String, dynamic>>[];

      for (int i = 0; i < days; i++) {
        final date = startDate.add(Duration(days: i));
        final dayDoses = await localDataSource.getDosesForDate(date);
        final medicineDoses = dayDoses
            .where((dose) => dose.medicineId == medicineId)
            .toList();

        final taken = medicineDoses
            .where((dose) => dose.status == 'taken')
            .length;
        final total = medicineDoses.length;
        final adherenceRate = total > 0 ? (taken / total) * 100 : 0.0;

        adherenceData.add({
          'date': date.toIso8601String().split('T')[0],
          'taken': taken,
          'total': total,
          'adherenceRate': adherenceRate,
        });
      }

      return Right(adherenceData);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to get adherence data'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> generateDosesForMedicine(Medicine medicine) async {
    try {
      final doses = <MedicineDose>[];
      final startDate = medicine.startDate;
      final endDate = medicine.endDate ?? medicine.startDate.add(Duration(days: medicine.durationInDays));
      
      // Generate doses for each day from start to end date
      DateTime currentDate = startDate;
      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        // Generate doses for each notification time
        for (final timeString in medicine.notificationTimes) {
          final timeParts = timeString.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          
          final doseTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            hour,
            minute,
          );
          
          final now = DateTime.now();
          final dose = MedicineDose(
            id: '${medicine.id}_${doseTime.millisecondsSinceEpoch}',
            medicineId: medicine.id,
            scheduledTime: doseTime,
            status: DoseStatus.pending,
            createdAt: now,
            updatedAt: now,
          );
          
          doses.add(dose);
        }
        
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      // Insert all generated doses
      for (final dose in doses) {
        final doseModel = MedicineDoseModel.fromEntity(dose);
        await localDataSource.insertDose(doseModel);
      }
      
      return const Right(null);
    } on DatabaseException {
      return Left(DatabaseFailure('Failed to generate doses for medicine'));
    } catch (e) {
      return Left(DatabaseFailure('Unexpected error occurred: $e'));
    }
  }
}
