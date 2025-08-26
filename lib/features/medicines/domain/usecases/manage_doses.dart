import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/medicine.dart';
import '../entities/medicine_dose.dart';
import '../repositories/medicine_repository.dart';

class GetDosesForMedicine
    implements UseCase<List<MedicineDose>, GetDosesForMedicineParams> {
  final MedicineRepository repository;

  GetDosesForMedicine(this.repository);

  @override
  Future<Either<Failure, List<MedicineDose>>> call(
    GetDosesForMedicineParams params,
  ) async {
    return await repository.getDosesForMedicine(params.medicineId);
  }
}

class GetDosesForMedicineParams extends Equatable {
  final String medicineId;

  const GetDosesForMedicineParams({required this.medicineId});

  @override
  List<Object> get props => [medicineId];
}

class GetPendingDoses implements UseCase<List<MedicineDose>, NoParams> {
  final MedicineRepository repository;

  GetPendingDoses(this.repository);

  @override
  Future<Either<Failure, List<MedicineDose>>> call(NoParams params) async {
    return await repository.getPendingDoses();
  }
}

class MarkDoseAsTaken implements UseCase<void, MarkDoseParams> {
  final MedicineRepository repository;

  MarkDoseAsTaken(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkDoseParams params) async {
    return await repository.markDoseAsTaken(params.doseId);
  }
}

class MarkDoseAsSkipped implements UseCase<void, MarkDoseParams> {
  final MedicineRepository repository;

  MarkDoseAsSkipped(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkDoseParams params) async {
    return await repository.markDoseAsSkipped(params.doseId);
  }
}

class MarkDoseParams extends Equatable {
  final String doseId;

  const MarkDoseParams({required this.doseId});

  @override
  List<Object> get props => [doseId];
}

class GenerateDosesForMedicine implements UseCase<void, GenerateDosesParams> {
  final MedicineRepository repository;

  GenerateDosesForMedicine(this.repository);

  @override
  Future<Either<Failure, void>> call(GenerateDosesParams params) async {
    return await repository.generateDosesForMedicine(params.medicine);
  }
}

class GenerateDosesParams extends Equatable {
  final Medicine medicine;

  const GenerateDosesParams({required this.medicine});

  @override
  List<Object> get props => [medicine];
}
