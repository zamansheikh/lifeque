import '../../domain/entities/medicine_dose.dart';

class MedicineDoseModel extends MedicineDose {
  const MedicineDoseModel({
    required super.id,
    required super.medicineId,
    required super.scheduledTime,
    super.status = DoseStatus.pending,
    super.takenAt,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory MedicineDoseModel.fromJson(Map<String, dynamic> json) {
    return MedicineDoseModel(
      id: json['id'],
      medicineId: json['medicineId'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      status: DoseStatus.values.firstWhere(
        (e) => e.toString() == 'DoseStatus.${json['status']}',
        orElse: () => DoseStatus.pending,
      ),
      takenAt: json['takenAt'] != null ? DateTime.parse(json['takenAt']) : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineId': medicineId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'status': status.toString().split('.').last,
      'takenAt': takenAt?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Add fromMap method for database compatibility - handles database column names
  factory MedicineDoseModel.fromMap(Map<String, dynamic> map) {
    // Convert database column names to JSON format for consistency
    final json = {
      'id': map['id'],
      'medicineId': map['medicineId'],
      'scheduledTime': map['scheduledTime'] is int 
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduledTime']).toIso8601String()
          : map['scheduledTime'],
      'status': map['status'],
      'takenAt': map['takenAt'] != null 
          ? (map['takenAt'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(map['takenAt']).toIso8601String()
              : map['takenAt'])
          : null,
      'notes': map['notes'],
      'createdAt': map['createdAt'] is int 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt']).toIso8601String()
          : map['createdAt'],
      'updatedAt': map['updatedAt'] is int 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']).toIso8601String()
          : map['updatedAt'],
    };
    return MedicineDoseModel.fromJson(json);
  }
  Map<String, dynamic> toMap() => toJson();

  factory MedicineDoseModel.fromEntity(MedicineDose dose) {
    return MedicineDoseModel(
      id: dose.id,
      medicineId: dose.medicineId,
      scheduledTime: dose.scheduledTime,
      status: dose.status,
      takenAt: dose.takenAt,
      notes: dose.notes,
      createdAt: dose.createdAt,
      updatedAt: dose.updatedAt,
    );
  }

  MedicineDose toEntity() {
    return MedicineDose(
      id: id,
      medicineId: medicineId,
      scheduledTime: scheduledTime,
      status: status,
      takenAt: takenAt,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
