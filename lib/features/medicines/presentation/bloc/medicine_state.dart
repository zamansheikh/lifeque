import 'package:equatable/equatable.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/entities/medicine_dose.dart';

abstract class MedicineState extends Equatable {
  const MedicineState();

  @override
  List<Object?> get props => [];
}

class MedicineInitial extends MedicineState {}

class MedicineLoading extends MedicineState {}

class MedicineLoaded extends MedicineState {
  final List<Medicine> medicines;

  const MedicineLoaded({required this.medicines});

  @override
  List<Object> get props => [medicines];
}

class MedicineError extends MedicineState {
  final String message;

  const MedicineError({required this.message});

  @override
  List<Object> get props => [message];
}

class MedicineOperationSuccess extends MedicineState {
  final String message;

  const MedicineOperationSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

// Dose-specific states
class DoseLoading extends MedicineState {}

class DoseLoaded extends MedicineState {
  final List<MedicineDose> doses;

  const DoseLoaded({required this.doses});

  @override
  List<Object> get props => [doses];
}

class DoseError extends MedicineState {
  final String message;

  const DoseError({required this.message});

  @override
  List<Object> get props => [message];
}

class DoseOperationSuccess extends MedicineState {
  final String message;

  const DoseOperationSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

// Combined state for dashboard/summary views
class MedicineDashboardLoaded extends MedicineState {
  final List<Medicine> medicines; // all/active depending on context
  final List<MedicineDose> todayDoses; // all doses scheduled for today
  final DateTime date;

  const MedicineDashboardLoaded({
    required this.medicines,
    required this.todayDoses,
    required this.date,
  });

  List<MedicineDose> dosesForMedicine(String id) =>
      todayDoses.where((d) => d.medicineId == id).toList();

  @override
  List<Object?> get props => [medicines, todayDoses, date];
}

class DailyProgressLoaded extends MedicineState {
  final String medicineId;
  final DateTime date;
  final List<MedicineDose> doses;

  const DailyProgressLoaded({
    required this.medicineId,
    required this.date,
    required this.doses,
  });

  int get taken => doses.where((d) => d.status == DoseStatus.taken).length;
  int get skipped => doses.where((d) => d.status == DoseStatus.skipped).length;
  int get missed => doses.where((d) => d.status == DoseStatus.missed).length;
  int get pending => doses.where((d) => d.status == DoseStatus.pending).length;
  int get total => doses.length;
  double get percent => total == 0 ? 0 : taken / total;

  @override
  List<Object?> get props => [medicineId, date, doses];
}

// Detailed view state for a single medicine with full dose history
class MedicineDetailLoaded extends MedicineState {
  final Medicine medicine;
  final List<MedicineDose> doses; // full course doses

  const MedicineDetailLoaded({required this.medicine, required this.doses});

  int get taken => doses.where((d) => d.status == DoseStatus.taken).length;
  int get skipped => doses.where((d) => d.status == DoseStatus.skipped).length;
  int get missed => doses.where((d) => d.status == DoseStatus.missed).length;
  int get pending => doses.where((d) => d.status == DoseStatus.pending).length;
  int get total => doses.length;
  double get adherencePercent => total == 0 ? 0 : taken / total;
  int get daysElapsed {
    final today = DateTime.now();
    final diff = today.difference(medicine.startDate).inDays + 1;
    return diff.clamp(0, medicine.durationInDays);
  }

  int get daysTotal => medicine.durationInDays;

  Map<DateTime, List<MedicineDose>> get dosesByDate {
    final map = <DateTime, List<MedicineDose>>{};
    for (final d in doses) {
      final dt = DateTime(
        d.scheduledTime.year,
        d.scheduledTime.month,
        d.scheduledTime.day,
      );
      map.putIfAbsent(dt, () => []).add(d);
    }
    final sortedKeys = map.keys.toList()..sort((a, b) => a.compareTo(b));
    return {for (final k in sortedKeys) k: map[k]!};
  }

  @override
  List<Object?> get props => [medicine, doses];
}

// Statistics states
class StatisticsLoading extends MedicineState {}

class StatisticsLoaded extends MedicineState {
  final Map<String, dynamic> statistics;

  const StatisticsLoaded({required this.statistics});

  @override
  List<Object> get props => [statistics];
}

class StatisticsError extends MedicineState {
  final String message;

  const StatisticsError({required this.message});

  @override
  List<Object> get props => [message];
}

// Adherence data states
class AdherenceDataLoading extends MedicineState {}

class AdherenceDataLoaded extends MedicineState {
  final List<Map<String, dynamic>> adherenceData;

  const AdherenceDataLoaded({required this.adherenceData});

  @override
  List<Object> get props => [adherenceData];
}

class AdherenceDataError extends MedicineState {
  final String message;

  const AdherenceDataError({required this.message});

  @override
  List<Object> get props => [message];
}
