import 'package:flutter/material.dart';
import '../../../../core/utils/database_helper.dart';
import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    super.taskType,
    required super.startDate,
    required super.endDate,
    super.isCompleted,
    super.isNotificationEnabled,
    super.notificationType,
    super.notificationTime,
    super.dailyNotificationTime,
    super.beforeEndOption,
    super.isPinnedToNotification,
    super.birthdayNotificationSchedule,
    required super.createdAt,
    super.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      taskType: json['taskType'] != null 
          ? TaskType.values.firstWhere((e) => e.toString() == json['taskType'], orElse: () => TaskType.task)
          : TaskType.task,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isNotificationEnabled: json['isNotificationEnabled'] as bool? ?? true,
      notificationType: json['notificationType'] != null
          ? NotificationType.values.firstWhere((e) => e.toString() == json['notificationType'], orElse: () => NotificationType.specificTime)
          : NotificationType.specificTime,
      notificationTime: json['notificationTime'] != null 
          ? DateTime.parse(json['notificationTime'] as String)
          : null,
      dailyNotificationTime: (json['dailyNotificationHour'] != null && json['dailyNotificationMinute'] != null)
          ? TimeOfDay(hour: json['dailyNotificationHour'] as int, minute: json['dailyNotificationMinute'] as int)
          : null,
      beforeEndOption: json['beforeEndOption'] != null
          ? BeforeEndOption.values.firstWhere((e) => e.toString() == json['beforeEndOption'], orElse: () => BeforeEndOption.tenMinutes)
          : null,
      isPinnedToNotification: json['isPinnedToNotification'] as bool? ?? false,
      birthdayNotificationSchedule: json['birthdayNotificationSchedule'] != null
          ? (json['birthdayNotificationSchedule'] as List).map((e) => 
              BirthdayNotificationOption.values.firstWhere((opt) => opt.toString() == e, orElse: () => BirthdayNotificationOption.exactTime)
            ).toList()
          : <BirthdayNotificationOption>[],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'taskType': taskType.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isCompleted': isCompleted,
      'isNotificationEnabled': isNotificationEnabled,
      'notificationType': notificationType.toString(),
      'notificationTime': notificationTime?.toIso8601String(),
      'dailyNotificationHour': dailyNotificationTime?.hour,
      'dailyNotificationMinute': dailyNotificationTime?.minute,
      'beforeEndOption': beforeEndOption?.toString(),
      'isPinnedToNotification': isPinnedToNotification,
      'birthdayNotificationSchedule': birthdayNotificationSchedule.map((e) => e.toString()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      taskType: task.taskType,
      startDate: task.startDate,
      endDate: task.endDate,
      isCompleted: task.isCompleted,
      isNotificationEnabled: task.isNotificationEnabled,
      notificationType: task.notificationType,
      notificationTime: task.notificationTime,
      dailyNotificationTime: task.dailyNotificationTime,
      beforeEndOption: task.beforeEndOption,
      isPinnedToNotification: task.isPinnedToNotification,
      birthdayNotificationSchedule: task.birthdayNotificationSchedule,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
    );
  }

  // Database methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'taskType': taskType.index,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
      'isNotificationEnabled': isNotificationEnabled ? 1 : 0,
      'notificationType': notificationType.index,
      'notificationTime': notificationTime?.millisecondsSinceEpoch,
      'dailyNotificationHour': dailyNotificationTime?.hour,
      'dailyNotificationMinute': dailyNotificationTime?.minute,
      'beforeEndOption': beforeEndOption?.index,
      'isPinnedToNotification': isPinnedToNotification ? 1 : 0,
      DatabaseHelper.columnBirthdayNotificationSchedule: birthdayNotificationSchedule.map((e) => e.index).join(','),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      taskType: map['taskType'] != null
          ? TaskType.values[map['taskType']]
          : TaskType.task,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      isCompleted: map['isCompleted'] == 1,
      isNotificationEnabled: map['isNotificationEnabled'] == 1,
      notificationType: map['notificationType'] != null
          ? NotificationType.values[map['notificationType']]
          : NotificationType.specificTime,
      notificationTime: map['notificationTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['notificationTime'])
          : null,
      dailyNotificationTime:
          (map['dailyNotificationHour'] != null &&
              map['dailyNotificationMinute'] != null)
          ? TimeOfDay(
              hour: map['dailyNotificationHour'],
              minute: map['dailyNotificationMinute'],
            )
          : null,
      beforeEndOption: map['beforeEndOption'] != null
          ? BeforeEndOption.values[map['beforeEndOption']]
          : null,
      isPinnedToNotification: map['isPinnedToNotification'] == 1,
      birthdayNotificationSchedule: map[DatabaseHelper.columnBirthdayNotificationSchedule] != null && map[DatabaseHelper.columnBirthdayNotificationSchedule].toString().isNotEmpty
          ? map[DatabaseHelper.columnBirthdayNotificationSchedule].toString().split(',').map((e) => BirthdayNotificationOption.values[int.parse(e)]).toList()
          : <BirthdayNotificationOption>[],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
    );
  }

  @override
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskType? taskType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    bool? isNotificationEnabled,
    NotificationType? notificationType,
    DateTime? notificationTime,
    TimeOfDay? dailyNotificationTime,
    BeforeEndOption? beforeEndOption,
    bool? isPinnedToNotification,
    List<BirthdayNotificationOption>? birthdayNotificationSchedule,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
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
      birthdayNotificationSchedule: birthdayNotificationSchedule ?? this.birthdayNotificationSchedule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
