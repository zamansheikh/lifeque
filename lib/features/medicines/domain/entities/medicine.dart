import 'package:equatable/equatable.dart';

enum MedicineType {
  tablet,
  capsule,
  syrup,
  injection,
  drops,
  cream,
  spray,
  other,
}

enum MealTiming { beforeMeal, afterMeal, withMeal, onEmptyStomach, anytime }

enum MedicineStatus { active, completed, paused, cancelled }

class Medicine extends Equatable {
  final String id;
  final String name;
  final String? description;
  final MedicineType type;
  final MealTiming mealTiming;
  final double dosage; // e.g., 500 for 500mg
  final String dosageUnit; // e.g., "mg", "ml", "tablets"
  final int timesPerDay;
  final List<String> notificationTimes; // e.g., ["08:00", "14:00", "20:00"]
  final int durationInDays;
  final DateTime startDate;
  final DateTime? endDate;
  final MedicineStatus status;
  final String? doctorName;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medicine({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.mealTiming,
    required this.dosage,
    required this.dosageUnit,
    required this.timesPerDay,
    required this.notificationTimes,
    required this.durationInDays,
    required this.startDate,
    this.endDate,
    this.status = MedicineStatus.active,
    this.doctorName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate end date based on start date and duration
  DateTime get calculatedEndDate {
    return endDate ?? startDate.add(Duration(days: durationInDays));
  }

  // Check if medicine is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == MedicineStatus.active &&
        now.isAfter(startDate) &&
        now.isBefore(calculatedEndDate.add(const Duration(days: 1)));
  }

  // Check if medicine course is completed
  bool get isCompleted {
    final now = DateTime.now();
    return status == MedicineStatus.completed || now.isAfter(calculatedEndDate);
  }

  // Get total number of doses for the entire course
  int get totalDoses {
    return timesPerDay * durationInDays;
  }

  // Get medicine type display name
  String get typeDisplayName {
    switch (type) {
      case MedicineType.tablet:
        return 'Tablet';
      case MedicineType.capsule:
        return 'Capsule';
      case MedicineType.syrup:
        return 'Syrup';
      case MedicineType.injection:
        return 'Injection';
      case MedicineType.drops:
        return 'Drops';
      case MedicineType.cream:
        return 'Cream';
      case MedicineType.spray:
        return 'Spray';
      case MedicineType.other:
        return 'Other';
    }
  }

  // Get meal timing display name
  String get mealTimingDisplayName {
    switch (mealTiming) {
      case MealTiming.beforeMeal:
        return 'Before Meal';
      case MealTiming.afterMeal:
        return 'After Meal';
      case MealTiming.withMeal:
        return 'With Meal';
      case MealTiming.onEmptyStomach:
        return 'On Empty Stomach';
      case MealTiming.anytime:
        return 'Anytime';
    }
  }

  // Get status display name
  String get statusDisplayName {
    switch (status) {
      case MedicineStatus.active:
        return 'Active';
      case MedicineStatus.completed:
        return 'Completed';
      case MedicineStatus.paused:
        return 'Paused';
      case MedicineStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Get dosage display string
  String get dosageDisplay {
    if (dosageUnit.toLowerCase() == 'tablets' ||
        dosageUnit.toLowerCase() == 'tablet') {
      return '${dosage.toInt()} ${dosage == 1 ? 'tablet' : 'tablets'}';
    }
    return '${dosage.toString()} $dosageUnit';
  }

  // Get next dose time
  DateTime? getNextDoseTime() {
    if (!isActive) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check today's remaining doses
    for (final timeStr in notificationTimes) {
      final timeParts = timeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final doseTime = today.add(Duration(hours: hour, minutes: minute));

      if (doseTime.isAfter(now)) {
        return doseTime;
      }
    }

    // If no doses today, check tomorrow
    final tomorrow = today.add(const Duration(days: 1));
    if (tomorrow.isBefore(calculatedEndDate)) {
      final firstTimeStr = notificationTimes.first;
      final timeParts = firstTimeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      return tomorrow.add(Duration(hours: hour, minutes: minute));
    }

    return null;
  }

  // Calculate progress percentage
  double get progressPercentage {
    final now = DateTime.now();
    final daysPassed = now
        .difference(startDate)
        .inDays
        .clamp(0, durationInDays);
    return daysPassed / durationInDays;
  }

  // Get remaining days
  int get remainingDays {
    final now = DateTime.now();
    final remaining = calculatedEndDate.difference(now).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  Medicine copyWith({
    String? id,
    String? name,
    String? description,
    MedicineType? type,
    MealTiming? mealTiming,
    double? dosage,
    String? dosageUnit,
    int? timesPerDay,
    List<String>? notificationTimes,
    int? durationInDays,
    DateTime? startDate,
    DateTime? endDate,
    MedicineStatus? status,
    String? doctorName,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      mealTiming: mealTiming ?? this.mealTiming,
      dosage: dosage ?? this.dosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      notificationTimes: notificationTimes ?? this.notificationTimes,
      durationInDays: durationInDays ?? this.durationInDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      doctorName: doctorName ?? this.doctorName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    type,
    mealTiming,
    dosage,
    dosageUnit,
    timesPerDay,
    notificationTimes,
    durationInDays,
    startDate,
    endDate,
    status,
    doctorName,
    notes,
    createdAt,
    updatedAt,
  ];
}
