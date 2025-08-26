import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

enum NotificationType {
  specificTime, // At a specific date and time
  daily, // Daily at a specific time
  beforeEnd, // X minutes/hours before end time
}

enum BeforeEndOption {
  tenMinutes, // 10 minutes before
  thirtyMinutes, // 30 minutes before
  oneHour, // 1 hour before
  twoHours, // 2 hours before
  oneDay, // 1 day before
}

extension BeforeEndOptionExtension on BeforeEndOption {
  String get displayName {
    switch (this) {
      case BeforeEndOption.tenMinutes:
        return '10 minutes';
      case BeforeEndOption.thirtyMinutes:
        return '30 minutes';
      case BeforeEndOption.oneHour:
        return '1 hour';
      case BeforeEndOption.twoHours:
        return '2 hours';
      case BeforeEndOption.oneDay:
        return '1 day';
    }
  }
}

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final bool isNotificationEnabled;
  final NotificationType notificationType;
  final DateTime? notificationTime; // For specificTime type
  final TimeOfDay? dailyNotificationTime; // For daily type
  final BeforeEndOption? beforeEndOption; // For beforeEnd type
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
    this.notificationType = NotificationType.specificTime,
    this.notificationTime,
    this.dailyNotificationTime,
    this.beforeEndOption,
    this.isPinnedToNotification = false,
    required this.createdAt,
    this.updatedAt,
  });

  int get daysLeft {
    final now = tz.TZDateTime.now(tz.local);
    final endDateTz = tz.TZDateTime.from(endDate, tz.local);
    if (now.isAfter(endDateTz)) return 0;
    return endDateTz.difference(now).inDays;
  }

  int get hoursLeft {
    final now = tz.TZDateTime.now(tz.local);
    final endDateTz = tz.TZDateTime.from(endDate, tz.local);
    if (now.isAfter(endDateTz)) return 0;
    return endDateTz.difference(now).inHours;
  }

  int get minutesLeft {
    final now = tz.TZDateTime.now(tz.local);
    final endDateTz = tz.TZDateTime.from(endDate, tz.local);
    if (now.isAfter(endDateTz)) return 0;
    return endDateTz.difference(now).inMinutes;
  }

  int get secondsLeft {
    final now = tz.TZDateTime.now(tz.local);
    final endDateTz = tz.TZDateTime.from(endDate, tz.local);
    if (now.isAfter(endDateTz)) return 0;
    return endDateTz.difference(now).inSeconds;
  }

  String get timeLeftFormatted {
    final now = tz.TZDateTime.now(tz.local);
    final endDateTz = tz.TZDateTime.from(endDate, tz.local);
    if (now.isAfter(endDateTz)) return "Overdue";

    final difference = endDateTz.difference(now);
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
    final now = tz.TZDateTime.now(tz.local);
    final startDateTz = tz.TZDateTime.from(startDate, tz.local);
    final endDateTz = tz.TZDateTime.from(endDate, tz.local);

    final totalDuration = endDateTz.difference(startDateTz).inMilliseconds;
    final elapsedDuration = now.difference(startDateTz).inMilliseconds;

    if (totalDuration <= 0) return 1.0;
    if (elapsedDuration <= 0) return 0.0;
    if (elapsedDuration >= totalDuration) return 1.0;

    return elapsedDuration / totalDuration;
  }

  bool get isOverdue {
    final now = tz.TZDateTime.now(tz.local);
    final endDateTz = tz.TZDateTime.from(endDate, tz.local);
    return now.isAfter(endDateTz) && !isCompleted;
  }

  bool get isActive {
    final now = tz.TZDateTime.now(tz.local);
    final startDateTz = tz.TZDateTime.from(startDate, tz.local);
    final endDateTz = tz.TZDateTime.from(endDate, tz.local);
    return now.isAfter(startDateTz) && now.isBefore(endDateTz) && !isCompleted;
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    bool? isNotificationEnabled,
    NotificationType? notificationType,
    DateTime? notificationTime,
    TimeOfDay? dailyNotificationTime,
    BeforeEndOption? beforeEndOption,
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
      notificationType: notificationType ?? this.notificationType,
      notificationTime: notificationTime ?? this.notificationTime,
      dailyNotificationTime:
          dailyNotificationTime ?? this.dailyNotificationTime,
      beforeEndOption: beforeEndOption ?? this.beforeEndOption,
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
    notificationType,
    notificationTime,
    dailyNotificationTime,
    beforeEndOption,
    isPinnedToNotification,
    createdAt,
    updatedAt,
  ];

  // Helper method to get the actual notification DateTime based on type
  DateTime? getScheduledNotificationTime() {
    debugPrint('🕒 getScheduledNotificationTime called for $title');
    debugPrint('🕒 notificationType: $notificationType');

    switch (notificationType) {
      case NotificationType.specificTime:
        debugPrint('🕒 specificTime - notificationTime: $notificationTime');
        return notificationTime;
      case NotificationType.daily:
        debugPrint('🕒 daily - dailyNotificationTime: $dailyNotificationTime');
        if (dailyNotificationTime != null) {
          // Use timezone-aware current time for proper calculation
          final now = tz.TZDateTime.now(tz.local);
          var scheduled = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            dailyNotificationTime!.hour,
            dailyNotificationTime!.minute,
          );
          // If the time has already passed today, schedule for tomorrow
          if (scheduled.isBefore(now)) {
            scheduled = scheduled.add(const Duration(days: 1));
          }
          debugPrint('🕒 daily scheduled time (timezone-aware): $scheduled');
          return scheduled;
        }
        return null;
      case NotificationType.beforeEnd:
        debugPrint('🕒 beforeEnd - beforeEndOption: $beforeEndOption');
        debugPrint('🕒 beforeEnd - endDate: $endDate');
        if (beforeEndOption != null) {
          // Convert endDate to timezone-aware DateTime for proper calculation
          final endDateTz = tz.TZDateTime.from(endDate, tz.local);
          tz.TZDateTime result;
          switch (beforeEndOption!) {
            case BeforeEndOption.tenMinutes:
              result = endDateTz.subtract(const Duration(minutes: 10));
              break;
            case BeforeEndOption.thirtyMinutes:
              result = endDateTz.subtract(const Duration(minutes: 30));
              break;
            case BeforeEndOption.oneHour:
              result = endDateTz.subtract(const Duration(hours: 1));
              break;
            case BeforeEndOption.twoHours:
              result = endDateTz.subtract(const Duration(hours: 2));
              break;
            case BeforeEndOption.oneDay:
              result = endDateTz.subtract(const Duration(days: 1));
              break;
          }
          debugPrint('🕒 beforeEnd scheduled time (timezone-aware): $result');
          return result;
        }
        return null;
    }
  }
}
