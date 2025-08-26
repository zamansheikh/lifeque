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
