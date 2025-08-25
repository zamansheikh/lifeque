import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/task.dart';

part 'task_model.g.dart';

@JsonSerializable()
class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.startDate,
    required super.endDate,
    super.isCompleted,
    super.isNotificationEnabled,
    super.notificationTime,
    super.isPinnedToNotification,
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
      startDate: task.startDate,
      endDate: task.endDate,
      isCompleted: task.isCompleted,
      isNotificationEnabled: task.isNotificationEnabled,
      notificationTime: task.notificationTime,
      isPinnedToNotification: task.isPinnedToNotification,
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
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
      'isNotificationEnabled': isNotificationEnabled ? 1 : 0,
      'notificationTime': notificationTime?.millisecondsSinceEpoch,
      'isPinnedToNotification': isPinnedToNotification ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      isCompleted: map['isCompleted'] == 1,
      isNotificationEnabled: map['isNotificationEnabled'] == 1,
      notificationTime: map['notificationTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['notificationTime'])
          : null,
      isPinnedToNotification: map['isPinnedToNotification'] == 1,
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
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    bool? isNotificationEnabled,
    DateTime? notificationTime,
    bool? isPinnedToNotification,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
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
}
