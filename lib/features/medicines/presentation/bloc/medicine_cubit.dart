import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_dose.dart';
import '../../domain/usecases/get_medicines.dart';
import '../../domain/usecases/manage_medicine.dart';
import '../../domain/usecases/manage_doses.dart';
import 'medicine_state.dart';

class MedicineCubit extends Cubit<MedicineState> {
  final GetAllMedicines getAllMedicinesUseCase;
  final GetActiveMedicines getActiveMedicinesUseCase;
  final AddMedicine addMedicineUseCase;
  final UpdateMedicine updateMedicineUseCase;
  final DeleteMedicine deleteMedicineUseCase;
  final GetDosesForMedicine getDosesForMedicineUseCase;
  final GetPendingDoses getPendingDosesUseCase;
  final MarkDoseAsTaken markDoseAsTakenUseCase;
  final MarkDoseAsSkipped markDoseAsSkippedUseCase;
  final MarkDoseAsMissed markDoseAsMissedUseCase;
  final GenerateDosesForMedicine generateDosesForMedicineUseCase;
  final GetDosesForDate getDosesForDateUseCase;
  final NotificationService notificationService;

  MedicineCubit({
    required this.getAllMedicinesUseCase,
    required this.getActiveMedicinesUseCase,
    required this.addMedicineUseCase,
    required this.updateMedicineUseCase,
    required this.deleteMedicineUseCase,
    required this.getDosesForMedicineUseCase,
    required this.getPendingDosesUseCase,
    required this.markDoseAsTakenUseCase,
    required this.markDoseAsSkippedUseCase,
    required this.markDoseAsMissedUseCase,
    required this.generateDosesForMedicineUseCase,
    required this.getDosesForDateUseCase,
    required this.notificationService,
  }) : super(MedicineInitial());

  // Medicine operations
  Future<void> loadAllMedicines() async {
    emit(MedicineLoading());
    final result = await getAllMedicinesUseCase(NoParams());
    result.fold(
      (failure) => emit(MedicineError(message: _getFailureMessage(failure))),
      (medicines) => emit(MedicineLoaded(medicines: medicines)),
    );
  }

  Future<void> loadActiveMedicines() async {
    emit(MedicineLoading());
    final result = await getActiveMedicinesUseCase(NoParams());
    result.fold(
      (failure) => emit(MedicineError(message: _getFailureMessage(failure))),
      (medicines) async {
        emit(MedicineLoaded(medicines: medicines));
        // Schedule notifications for all active medicines
        for (final medicine in medicines) {
          if (medicine.isActive) {
            await notificationService.scheduleMedicineNotifications(medicine);
          }
        }
      },
    );
  }

  Future<void> addMedicine(Medicine medicine) async {
    emit(MedicineLoading());
    final result = await addMedicineUseCase(
      AddMedicineParams(medicine: medicine),
    );
    result.fold(
      (failure) => emit(MedicineError(message: _getFailureMessage(failure))),
      (_) async {
        // Generate doses for the new medicine
        final generateResult = await generateDosesForMedicineUseCase(
          GenerateDosesParams(medicine: medicine),
        );

        generateResult.fold(
          (failure) => emit(
            MedicineError(
              message:
                  'Medicine added but failed to generate doses: ${_getFailureMessage(failure)}',
            ),
          ),
          (_) async {
            // Schedule notifications for the new medicine
            await notificationService.scheduleMedicineNotifications(medicine);
            emit(
              const MedicineOperationSuccess(
                message: 'Medicine added successfully with doses generated',
              ),
            );
            loadAllMedicines(); // Refresh the list
          },
        );
      },
    );
  }

  Future<void> updateMedicine(Medicine medicine) async {
    emit(MedicineLoading());
    final result = await updateMedicineUseCase(
      UpdateMedicineParams(medicine: medicine),
    );
    result.fold(
      (failure) => emit(MedicineError(message: _getFailureMessage(failure))),
      (_) async {
        // Cancel existing notifications and schedule new ones
        await notificationService.cancelMedicineNotifications(medicine.id);
        if (medicine.isActive) {
          await notificationService.scheduleMedicineNotifications(medicine);
        }
        emit(
          const MedicineOperationSuccess(
            message: 'Medicine updated successfully',
          ),
        );
        loadAllMedicines(); // Refresh the list
      },
    );
  }

  Future<void> deleteMedicine(String id) async {
    emit(MedicineLoading());
    final result = await deleteMedicineUseCase(DeleteMedicineParams(id: id));
    result.fold(
      (failure) => emit(MedicineError(message: _getFailureMessage(failure))),
      (_) async {
        // Cancel notifications for the deleted medicine
        await notificationService.cancelMedicineNotifications(id);
        emit(
          const MedicineOperationSuccess(
            message: 'Medicine deleted successfully',
          ),
        );
        loadAllMedicines(); // Refresh the list
      },
    );
  }

  // Dose operations
  Future<void> getDosesForMedicine(String medicineId) async {
    emit(DoseLoading());
    final result = await getDosesForMedicineUseCase(
      GetDosesForMedicineParams(medicineId: medicineId),
    );
    result.fold(
      (failure) => emit(DoseError(message: _getFailureMessage(failure))),
      (doses) => emit(DoseLoaded(doses: doses)),
    );
  }

  Future<void> getPendingDoses() async {
    emit(DoseLoading());
    final result = await getPendingDosesUseCase(NoParams());
    result.fold(
      (failure) => emit(DoseError(message: _getFailureMessage(failure))),
      (doses) => emit(DoseLoaded(doses: doses)),
    );
  }

  Future<void> markDoseAsTaken(String doseId, String medicineId) async {
    // Avoid showing a full-screen loading state that hides medicine list; perform inline update
    final result = await markDoseAsTakenUseCase(MarkDoseParams(doseId: doseId));
    result.fold(
      (failure) => emit(DoseError(message: _getFailureMessage(failure))),
      (_) async {
        emit(const DoseOperationSuccess(message: 'Dose marked as taken'));
        // Silent refresh of dashboard (don't emit loading) by calling loadDashboard logic inline
        _silentDashboardRefresh();
      },
    );
  }

  Future<void> markDoseAsSkipped(String doseId, String medicineId) async {
    final result = await markDoseAsSkippedUseCase(
      MarkDoseParams(doseId: doseId),
    );
    result.fold(
      (failure) => emit(DoseError(message: _getFailureMessage(failure))),
      (_) async {
        emit(const DoseOperationSuccess(message: 'Dose marked as skipped'));
        _silentDashboardRefresh();
      },
    );
  }

  Future<void> markDoseAsMissed(String doseId, String medicineId) async {
    final result = await markDoseAsMissedUseCase(
      MarkDoseParams(doseId: doseId),
    );
    result.fold(
      (failure) => emit(DoseError(message: _getFailureMessage(failure))),
      (_) async {
        emit(const DoseOperationSuccess(message: 'Dose marked as missed'));
        _silentDashboardRefresh();
      },
    );
  }

  Future<void> loadDashboard({DateTime? date}) async {
    final target = date ?? DateTime.now();
    emit(MedicineLoading());
    final medsResult = await getActiveMedicinesUseCase(NoParams());
    await medsResult.fold(
      (failure) async =>
          emit(MedicineError(message: _getFailureMessage(failure))),
      (medicines) async {
        final dosesResult = await getDosesForDateUseCase(DateParams(target));
        dosesResult.fold(
          (failure) =>
              emit(MedicineError(message: _getFailureMessage(failure))),
          (doses) async {
            final now = DateTime.now();
            final updated = <MedicineDose>[];
            for (final d in doses) {
              if (d.status == DoseStatus.pending &&
                  d.scheduledTime.isBefore(
                    now.subtract(const Duration(minutes: 60)),
                  )) {
                // Mark as missed in storage
                await markDoseAsMissedUseCase(MarkDoseParams(doseId: d.id));
                updated.add(d.copyWith(status: DoseStatus.missed));
              } else {
                updated.add(d);
              }
            }
            emit(
              MedicineDashboardLoaded(
                medicines: medicines,
                todayDoses: updated,
                date: DateTime(target.year, target.month, target.day),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _silentDashboardRefresh() async {
    final target = DateTime.now();
    final medsResult = await getActiveMedicinesUseCase(NoParams());
    medsResult.fold((failure) {}, (medicines) async {
      final dosesResult = await getDosesForDateUseCase(DateParams(target));
      dosesResult.fold((failure) {}, (doses) {
        final now = DateTime.now();
        final updated = doses.map((d) {
          if (d.status == DoseStatus.pending &&
              d.scheduledTime.isBefore(
                now.subtract(const Duration(minutes: 60)),
              )) {
            return d.copyWith(status: DoseStatus.missed);
          }
          return d;
        }).toList();
        emit(
          MedicineDashboardLoaded(
            medicines: medicines,
            todayDoses: updated,
            date: DateTime(target.year, target.month, target.day),
          ),
        );
      });
    });
  }

  Future<void> loadDailyProgress(String medicineId, {DateTime? date}) async {
    final target = date ?? DateTime.now();
    final dosesResult = await getDosesForDateUseCase(DateParams(target));
    dosesResult.fold(
      (failure) => emit(DoseError(message: _getFailureMessage(failure))),
      (doses) {
        final medDoses = doses
            .where((d) => d.medicineId == medicineId)
            .toList();
        emit(
          DailyProgressLoaded(
            medicineId: medicineId,
            date: DateTime(target.year, target.month, target.day),
            doses: medDoses,
          ),
        );
      },
    );
  }

  Future<void> loadMedicineDetail(String medicineId) async {
    // Get medicine and its full dose list
    final medsResult = await getActiveMedicinesUseCase(NoParams());
    await medsResult.fold(
      (failure) {
        emit(MedicineError(message: _getFailureMessage(failure)));
      },
      (medicines) async {
        final med = medicines.firstWhere(
          (m) => m.id == medicineId,
          orElse: () => medicines.isNotEmpty
              ? medicines.first
              : throw Exception('Medicine not found'),
        );
        final dosesResult = await getDosesForMedicineUseCase(
          GetDosesForMedicineParams(medicineId: medicineId),
        );
        dosesResult.fold(
          (failure) => emit(DoseError(message: _getFailureMessage(failure))),
          (doses) => emit(MedicineDetailLoaded(medicine: med, doses: doses)),
        );
      },
    );
  }

  Future<void> generateDosesForMedicine(Medicine medicine) async {
    emit(DoseLoading());
    final generateResult = await generateDosesForMedicineUseCase(
      GenerateDosesParams(medicine: medicine),
    );

    generateResult.fold(
      (failure) => emit(DoseError(message: _getFailureMessage(failure))),
      (_) {
        emit(
          const DoseOperationSuccess(message: 'Doses generated successfully'),
        );
        getDosesForMedicine(medicine.id); // Refresh doses for this medicine
      },
    );
  }

  String _getFailureMessage(Failure failure) {
    if (failure is DatabaseFailure) {
      return failure.message;
    } else if (failure is PermissionFailure) {
      return failure.message;
    } else if (failure is NotificationFailure) {
      return failure.message;
    } else {
      return 'An unexpected error occurred';
    }
  }
}
