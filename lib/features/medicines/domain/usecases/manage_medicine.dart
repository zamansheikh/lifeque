import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/medicine.dart';
import '../repositories/medicine_repository.dart';

class AddMedicine implements UseCase<void, AddMedicineParams> {
  final MedicineRepository repository;

  AddMedicine(this.repository);

  @override
  Future<Either<Failure, void>> call(AddMedicineParams params) async {
    return await repository.addMedicine(params.medicine);
  }
}

class AddMedicineParams extends Equatable {
  final Medicine medicine;

  const AddMedicineParams({required this.medicine});

  @override
  List<Object> get props => [medicine];
}

class UpdateMedicine implements UseCase<void, UpdateMedicineParams> {
  final MedicineRepository repository;

  UpdateMedicine(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateMedicineParams params) async {
    return await repository.updateMedicine(params.medicine);
  }
}

class UpdateMedicineParams extends Equatable {
  final Medicine medicine;

  const UpdateMedicineParams({required this.medicine});

  @override
  List<Object> get props => [medicine];
}

class DeleteMedicine implements UseCase<void, DeleteMedicineParams> {
  final MedicineRepository repository;

  DeleteMedicine(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteMedicineParams params) async {
    return await repository.deleteMedicine(params.id);
  }
}

class DeleteMedicineParams extends Equatable {
  final String id;

  const DeleteMedicineParams({required this.id});

  @override
  List<Object> get props => [id];
}
