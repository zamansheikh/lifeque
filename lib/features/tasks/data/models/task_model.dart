import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/database_helper.dart';
import '../../domain/entities/task.dart';

part 'task_model.g.dart';

@JsonSerializable()
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

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  Map<String, dynamic> toJson() => _$TaskModelToJson(this);

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
