import 'package:equatable/equatable.dart';

enum DoseStatus { pending, taken, skipped, missed }

class MedicineDose extends Equatable {
  final String id;
  final String medicineId;
  final DateTime scheduledTime;
  final DoseStatus status;
  final DateTime? takenAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicineDose({
    required this.id,
    required this.medicineId,
    required this.scheduledTime,
    this.status = DoseStatus.pending,
    this.takenAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Check if dose is overdue
  bool get isOverdue {
    if (status != DoseStatus.pending) return false;
    return DateTime.now().isAfter(scheduledTime.add(const Duration(hours: 1)));
  }

  // Check if dose is due soon (within 30 minutes)
  bool get isDueSoon {
    if (status != DoseStatus.pending) return false;
    final now = DateTime.now();
    final timeDiff = scheduledTime.difference(now);
    return timeDiff.inMinutes <= 30 && timeDiff.inMinutes >= 0;
  }

  // Get status display name
  String get statusDisplayName {
    switch (status) {
      case DoseStatus.pending:
        return 'Pending';
      case DoseStatus.taken:
        return 'Taken';
      case DoseStatus.skipped:
        return 'Skipped';
      case DoseStatus.missed:
        return 'Missed';
    }
  }

  // Get status color
  int get statusColor {
    switch (status) {
      case DoseStatus.pending:
        return 0xFFFF9800; // Orange
      case DoseStatus.taken:
        return 0xFF4CAF50; // Green
      case DoseStatus.skipped:
        return 0xFF9E9E9E; // Grey
      case DoseStatus.missed:
        return 0xFFF44336; // Red
    }
  }

  // Get status icon
  String get statusIcon {
    switch (status) {
      case DoseStatus.pending:
        return '⏰';
      case DoseStatus.taken:
        return '✅';
      case DoseStatus.skipped:
        return '⏭️';
      case DoseStatus.missed:
        return '❌';
    }
  }

  // Get formatted time
  String get formattedTime {
    final hour = scheduledTime.hour.toString().padLeft(2, '0');
    final minute = scheduledTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Get formatted date
  String get formattedDate {
    return '${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year}';
  }

  MedicineDose copyWith({
    String? id,
    String? medicineId,
    DateTime? scheduledTime,
    DoseStatus? status,
    DateTime? takenAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicineDose(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      takenAt: takenAt ?? this.takenAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    medicineId,
    scheduledTime,
    status,
    takenAt,
    notes,
    createdAt,
    updatedAt,
  ];
}
