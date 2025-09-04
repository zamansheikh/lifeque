import 'dart:convert';
import '../../domain/entities/medicine.dart';

class MedicineModel extends Medicine {
  const MedicineModel({
    required super.id,
    required super.name,
    super.description,
    required super.type,
    required super.mealTiming,
    required super.dosage,
    required super.dosageUnit,
    required super.timesPerDay,
    required super.notificationTimes,
    required super.durationInDays,
    required super.startDate,
    super.endDate,
    super.status = MedicineStatus.active,
    super.doctorName,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: MedicineType.values.firstWhere(
        (e) => e.toString() == 'MedicineType.${json['type']}',
        orElse: () => MedicineType.tablet,
      ),
      mealTiming: MealTiming.values.firstWhere(
        (e) => e.toString() == 'MealTiming.${json['mealTiming']}',
        orElse: () => MealTiming.anytime,
      ),
      dosage: json['dosage'].toDouble(),
      dosageUnit: json['dosageUnit'],
      timesPerDay: json['timesPerDay'],
      notificationTimes: _parseNotificationTimes(json['notificationTimes']),
      durationInDays: json['durationInDays'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: MedicineStatus.values.firstWhere(
        (e) => e.toString() == 'MedicineStatus.${json['status']}',
        orElse: () => MedicineStatus.active,
      ),
      doctorName: json['doctorName'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Helper method to parse notification times from either List or JSON string
  static List<String> _parseNotificationTimes(dynamic notificationTimes) {
    if (notificationTimes == null) {
      return <String>[];
    }

    if (notificationTimes is List) {
      return List<String>.from(notificationTimes);
    }

    if (notificationTimes is String) {
      try {
        final decoded = jsonDecode(notificationTimes);
        if (decoded is List) {
          return List<String>.from(decoded);
        }
      } catch (e) {
        // If it's not valid JSON, treat as a single time string
        return [notificationTimes];
      }
    }

    return <String>[];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'mealTiming': mealTiming.toString().split('.').last,
      'dosage': dosage,
      'dosageUnit': dosageUnit,
      'timesPerDay': timesPerDay,
      'notificationTimes': notificationTimes,
      'durationInDays': durationInDays,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status.toString().split('.').last,
      'doctorName': doctorName,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Add fromMap method for database compatibility - handles database column names
  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    // Convert database column names to JSON format for consistency
    final json = {
      'id': map['id'],
      'name': map['name'],
      'description': map['description'],
      'type': map['type'],
      'mealTiming': map['mealTiming'],
      'dosage': map['dosage'],
      'dosageUnit': map['dosageUnit'],
      'timesPerDay': map['timesPerDay'],
      'notificationTimes':
          map['notificationTimes'], // Will be handled by _parseNotificationTimes
      'durationInDays': map['durationInDays'],
      'startDate': map['startDate'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              map['startDate'],
            ).toIso8601String()
          : map['startDate'],
      'endDate': map['endDate'] != null
          ? (map['endDate'] is int
                ? DateTime.fromMillisecondsSinceEpoch(
                    map['endDate'],
                  ).toIso8601String()
                : map['endDate'])
          : null,
      'status': map['status'],
      'doctorName': map['doctorName'],
      'notes': map['notes'],
      'createdAt': map['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              map['createdAt'],
            ).toIso8601String()
          : map['createdAt'],
      'updatedAt': map['updatedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              map['updatedAt'],
            ).toIso8601String()
          : map['updatedAt'],
    };
    return MedicineModel.fromJson(json);
  }
  Map<String, dynamic> toMap() => toJson();

  factory MedicineModel.fromEntity(Medicine medicine) {
    return MedicineModel(
      id: medicine.id,
      name: medicine.name,
      description: medicine.description,
      type: medicine.type,
      mealTiming: medicine.mealTiming,
      dosage: medicine.dosage,
      dosageUnit: medicine.dosageUnit,
      timesPerDay: medicine.timesPerDay,
      notificationTimes: medicine.notificationTimes,
      durationInDays: medicine.durationInDays,
      startDate: medicine.startDate,
      endDate: medicine.endDate,
      status: medicine.status,
      doctorName: medicine.doctorName,
      notes: medicine.notes,
      createdAt: medicine.createdAt,
      updatedAt: medicine.updatedAt,
    );
  }

  Medicine toEntity() {
    return Medicine(
      id: id,
      name: name,
      description: description,
      type: type,
      mealTiming: mealTiming,
      dosage: dosage,
      dosageUnit: dosageUnit,
      timesPerDay: timesPerDay,
      notificationTimes: notificationTimes,
      durationInDays: durationInDays,
      startDate: startDate,
      endDate: endDate,
      status: status,
      doctorName: doctorName,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
