import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/medicine.dart';
import '../entities/medicine_dose.dart';

abstract class MedicineRepository {
  // Medicine CRUD operations
  Future<Either<Failure, List<Medicine>>> getAllMedicines();
  Future<Either<Failure, List<Medicine>>> getActiveMedicines();
  Future<Either<Failure, Medicine>> getMedicineById(String id);
  Future<Either<Failure, void>> addMedicine(Medicine medicine);
  Future<Either<Failure, void>> updateMedicine(Medicine medicine);
  Future<Either<Failure, void>> deleteMedicine(String id);

  // Dose operations
  Future<Either<Failure, List<MedicineDose>>> getDosesForMedicine(
    String medicineId,
  );
  Future<Either<Failure, List<MedicineDose>>> getDosesForDate(DateTime date);
  Future<Either<Failure, List<MedicineDose>>> getPendingDoses();
  Future<Either<Failure, List<MedicineDose>>> getOverdueDoses();
  Future<Either<Failure, void>> addDose(MedicineDose dose);
  Future<Either<Failure, void>> updateDose(MedicineDose dose);
  Future<Either<Failure, void>> markDoseAsTaken(String doseId);
  Future<Either<Failure, void>> markDoseAsSkipped(String doseId);
  Future<Either<Failure, void>> markDoseAsMissed(String doseId);

  // Analytics
  Future<Either<Failure, Map<String, dynamic>>> getMedicineStatistics(
    String medicineId,
  );
  Future<Either<Failure, Map<String, dynamic>>> getOverallStatistics();
  Future<Either<Failure, List<Map<String, dynamic>>>> getAdherenceData(
    String medicineId,
    int days,
  );
}
