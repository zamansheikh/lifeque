import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/medicine.dart';
import '../repositories/medicine_repository.dart';

class GetAllMedicines implements UseCase<List<Medicine>, NoParams> {
  final MedicineRepository repository;

  GetAllMedicines(this.repository);

  @override
  Future<Either<Failure, List<Medicine>>> call(NoParams params) async {
    return await repository.getAllMedicines();
  }
}

class GetActiveMedicines implements UseCase<List<Medicine>, NoParams> {
  final MedicineRepository repository;

  GetActiveMedicines(this.repository);

  @override
  Future<Either<Failure, List<Medicine>>> call(NoParams params) async {
    return await repository.getActiveMedicines();
  }
}
