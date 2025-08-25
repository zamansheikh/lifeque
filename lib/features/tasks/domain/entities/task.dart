import 'package:equatable/equatable.dart';

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final bool isNotificationEnabled;
  final DateTime? notificationTime;
  final bool isPinnedToNotification;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    this.isNotificationEnabled = true,
    this.notificationTime,
    this.isPinnedToNotification = false,
    required this.createdAt,
    this.updatedAt,
  });

  int get daysLeft {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  int get hoursLeft {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inHours;
  }

  int get minutesLeft {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inMinutes;
  }

  int get secondsLeft {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inSeconds;
  }

  String get timeLeftFormatted {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return "Overdue";

    final difference = endDate.difference(now);
    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    if (days > 0) {
      return "${days}d ${hours}h ${minutes}m";
    } else if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }

  double get progressPercentage {
    final now = DateTime.now();
    final totalDuration = endDate.difference(startDate).inMilliseconds;
    final elapsedDuration = now.difference(startDate).inMilliseconds;

    if (totalDuration <= 0) return 1.0;
    if (elapsedDuration <= 0) return 0.0;
    if (elapsedDuration >= totalDuration) return 1.0;

    return elapsedDuration / totalDuration;
  }

  bool get isOverdue {
    return DateTime.now().isAfter(endDate) && !isCompleted;
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate) && !isCompleted;
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    bool? isNotificationEnabled,
    DateTime? notificationTime,
    bool? isPinnedToNotification,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      isPinnedToNotification:
          isPinnedToNotification ?? this.isPinnedToNotification,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    startDate,
    endDate,
    isCompleted,
    isNotificationEnabled,
    notificationTime,
    isPinnedToNotification,
    createdAt,
    updatedAt,
  ];
}
