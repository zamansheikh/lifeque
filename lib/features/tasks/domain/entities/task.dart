import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

enum TaskType {
  task, // Traditional task with start and end dates
  reminder, // Simple reminder with just notification time
  birthday, // Birthday reminder with yearly repetition
}

/// How a simple item comes back after it is done. Stored by index — append
/// only.
enum RepeatRule {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  /// [from] moved one period on. A month-end date stays in range: the 31st
  /// becomes the 30th or the 28th rather than spilling into the next month.
  DateTime step(DateTime from) {
    DateTime months(int n) {
      final first = DateTime(from.year, from.month + n);
      final last = DateTime(first.year, first.month + 1, 0).day;
      return DateTime(
        first.year,
        first.month,
        from.day > last ? last : from.day,
        from.hour,
        from.minute,
      );
    }

    return switch (this) {
      RepeatRule.none => from,
      RepeatRule.daily => DateTime(
        from.year,
        from.month,
        from.day + 1,
        from.hour,
        from.minute,
      ),
      RepeatRule.weekly => DateTime(
        from.year,
        from.month,
        from.day + 7,
        from.hour,
        from.minute,
      ),
      RepeatRule.monthly => months(1),
      RepeatRule.yearly => months(12),
    };
  }
}

/// How much an item matters. Stored by index — append only.
enum TaskPriority { low, normal, high, urgent }

/// What an item is about. Stored by index — append only. Same set the to-do
/// list used, so migrated to-dos keep theirs.
enum TaskCategory {
  personal,
  work,
  shopping,
  health,
  education,
  finance,
  travel,
  home,
  other,
}

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

enum BirthdayNotificationOption {
  oneDayBefore, // 1 day before (for gift preparation)
  twoHoursBefore, // 2 hours before
  tenMinutesBefore, // 10 minutes before
  exactTime, // Exactly at 12:00 AM on birthday
}

extension BirthdayNotificationOptionExtension on BirthdayNotificationOption {
  String get displayName {
    switch (this) {
      case BirthdayNotificationOption.oneDayBefore:
        return '1 day before (gift prep)';
      case BirthdayNotificationOption.twoHoursBefore:
        return '2 hours before';
      case BirthdayNotificationOption.tenMinutesBefore:
        return '10 minutes before';
      case BirthdayNotificationOption.exactTime:
        return 'At exactly 12:00 AM';
    }
  }

  String get description {
    switch (this) {
      case BirthdayNotificationOption.oneDayBefore:
        return 'Get reminder to prepare gifts';
      case BirthdayNotificationOption.twoHoursBefore:
        return 'Final preparation reminder';
      case BirthdayNotificationOption.tenMinutesBefore:
        return 'Almost time to celebrate!';
      case BirthdayNotificationOption.exactTime:
        return 'Birthday celebration time!';
    }
  }
}

enum PinNotificationTiming {
  beforeNotification, // Pin before notification is shown (current behavior)
  afterNotification, // Pin after notification is shown
}

extension PinNotificationTimingExtension on PinNotificationTiming {
  String get displayName {
    switch (this) {
      case PinNotificationTiming.beforeNotification:
        return 'Pin Before Notification';
      case PinNotificationTiming.afterNotification:
        return 'Pin After Notification';
    }
  }

  String get description {
    switch (this) {
      case PinNotificationTiming.beforeNotification:
        return 'Keep pinned until notification time';
      case PinNotificationTiming.afterNotification:
        return 'Pin after notification is shown';
    }
  }
}

class Task extends Equatable {
  final String id;
  final String title;
  final String? description;
  final TaskType taskType;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;
  final bool isNotificationEnabled;
  final NotificationType notificationType;
  final DateTime? notificationTime; // For specificTime type
  final TimeOfDay? dailyNotificationTime; // For daily type
  final BeforeEndOption? beforeEndOption; // For beforeEnd type
  final bool isPinnedToNotification;
  final PinNotificationTiming pinNotificationTiming;
  final List<BirthdayNotificationOption>
  birthdayNotificationSchedule; // For birthday multiple notifications
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Since tasks, reminders and to-dos became one list. Defaults keep every
  /// item stored before then reading as it did.
  final TaskPriority priority;
  final TaskCategory? category;

  /// False for a simple item with no date — "someday". Its [endDate] then
  /// holds nothing meaningful.
  final bool hasDueDate;
  final DateTime? completedAt;

  /// Simple items only: done means "move to the next one", not finished.
  final RepeatRule repeat;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.taskType = TaskType.task,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    this.isNotificationEnabled = true,
    this.notificationType = NotificationType.specificTime,
    this.notificationTime,
    this.dailyNotificationTime,
    this.beforeEndOption,
    this.isPinnedToNotification = false,
    this.pinNotificationTiming = PinNotificationTiming.beforeNotification,
    this.birthdayNotificationSchedule = const [],
    required this.createdAt,
    this.updatedAt,
    this.priority = TaskPriority.normal,
    this.category,
    this.hasDueDate = true,
    this.completedAt,
    this.repeat = RepeatRule.none,
  });

  /// A simple item that comes back.
  bool get repeats => isSimple && repeat != RepeatRule.none;

  /// This item ticked off on a repeat: due date and reminder moved to the
  /// next occurrence after [now] — by the same number of periods, so a
  /// reminder set an hour before it is due stays an hour before — and left
  /// open, with [completedAt] recording the tick.
  Task rolledForward(DateTime now) {
    final anchor = planDate;
    if (!repeats || anchor == null) return this;
    var steps = 0;
    var next = anchor;
    do {
      next = repeat.step(next);
      steps++;
    } while (!next.isAfter(now) && steps < 10000);

    DateTime shift(DateTime d) {
      for (var i = 0; i < steps; i++) {
        d = repeat.step(d);
      }
      return d;
    }

    final due = dueDate == null ? null : shift(dueDate!);
    final reminder = reminderAt == null ? null : shift(reminderAt!);
    final at = due ?? reminder!;
    return copyWith(
      startDate: at,
      endDate: at,
      notificationTime: reminder,
      isCompleted: false,
      completedAt: now,
      updatedAt: now,
    );
  }

  /// Ticked off: finished, or for a repeating item, moved on.
  Task done(DateTime now) => repeats
      ? rolledForward(now)
      : copyWith(isCompleted: true, completedAt: now, updatedAt: now);

  // ── The unified list ──────────────────────────────────────────────────
  // A simple item (stored as [TaskType.reminder]) may have a due date, a
  // reminder time, both, or neither. Ranged tasks and birthdays keep their
  // own meaning of the dates.

  /// A simple item: not a ranged task, not a birthday.
  bool get isSimple => taskType == TaskType.reminder;

  /// When the reminder rings, if it has one.
  DateTime? get reminderAt =>
      isSimple && isNotificationEnabled ? (notificationTime ?? endDate) : null;

  /// The day it is due, if it has one.
  DateTime? get dueDate => isSimple ? (hasDueDate ? endDate : null) : endDate;

  /// The moment that places it in the list: due date, else reminder time.
  /// Null for an undated item.
  DateTime? get planDate => isSimple ? (dueDate ?? reminderAt) : endDate;

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

    // For birthdays, check if the next birthday occurrence is in the future
    if (taskType == TaskType.birthday) {
      // Birthdays are always active unless completed
      // (they recur yearly, so there's always a "next" birthday)
      return !isCompleted;
    }

    // For reminders, they are active when not completed
    // and the notification time hasn't passed yet
    if (taskType == TaskType.reminder) {
      final endDateTz = tz.TZDateTime.from(endDate, tz.local);
      return !isCompleted && now.isBefore(endDateTz);
    }

    // For traditional tasks, check if we're between start and end dates
    final startDateTz = tz.TZDateTime.from(startDate, tz.local);
    final endDateTz = tz.TZDateTime.from(endDate, tz.local);
    return now.isAfter(startDateTz) && now.isBefore(endDateTz) && !isCompleted;
  }

  /// The next birthday on or after [now]'s date. Birth date is in [endDate].
  ///
  /// Takes the date as an argument so callers that reason about a given day
  /// (the daily nudge, its tests) agree with themselves instead of with the
  /// wall clock.
  DateTime nextBirthdayFrom(DateTime now) {
    final birthdayDate = endDate;
    final thisYearBirthday = DateTime(
      now.year,
      birthdayDate.month,
      birthdayDate.day,
    );

    // If this year's birthday has passed, return next year's. Compared by
    // date, not by instant: thisYearBirthday is midnight, so any time after
    // midnight on the day itself used to push the answer a full year out —
    // a birthday today read as "in 365 days".
    final today = DateTime(now.year, now.month, now.day);
    if (today.isAfter(thisYearBirthday)) {
      return DateTime(now.year + 1, birthdayDate.month, birthdayDate.day);
    }
    return thisYearBirthday;
  }

  /// Get the next occurrence date for sorting purposes
  /// - For tasks: returns end date (deadline)
  /// - For birthdays: returns next birthday date
  /// - For reminders: returns notification time or end date
  DateTime get nextOccurrence {
    final now = DateTime.now();

    if (taskType == TaskType.birthday) return nextBirthdayFrom(now);

    if (taskType == TaskType.reminder) {
      // For reminders, use notification time if available, otherwise end date
      return notificationTime ?? endDate;
    }

    // For traditional tasks, use end date
    return endDate;
  }

  Task copyWith({
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
    PinNotificationTiming? pinNotificationTiming,
    List<BirthdayNotificationOption>? birthdayNotificationSchedule,
    DateTime? createdAt,
    DateTime? updatedAt,
    TaskPriority? priority,
    TaskCategory? category,
    bool clearCategory = false,
    bool? hasDueDate,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    RepeatRule? repeat,
  }) {
    return Task(
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
      pinNotificationTiming:
          pinNotificationTiming ?? this.pinNotificationTiming,
      birthdayNotificationSchedule:
          birthdayNotificationSchedule ?? this.birthdayNotificationSchedule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priority: priority ?? this.priority,
      category: clearCategory ? null : (category ?? this.category),
      hasDueDate: hasDueDate ?? this.hasDueDate,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      repeat: repeat ?? this.repeat,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    taskType,
    startDate,
    endDate,
    isCompleted,
    isNotificationEnabled,
    notificationType,
    notificationTime,
    dailyNotificationTime,
    beforeEndOption,
    isPinnedToNotification,
    pinNotificationTiming,
    birthdayNotificationSchedule,
    createdAt,
    updatedAt,
    priority,
    category,
    hasDueDate,
    completedAt,
    repeat,
  ];

  // Helper method to get the actual notification DateTime based on type
  DateTime? getScheduledNotificationTime() {
    // Simple items ring at their reminder time. Older reminders stored it
    // only in endDate; newer ones may be due on a different day than they
    // remind, so notificationTime wins when it is there.
    if (taskType == TaskType.reminder) {
      return isNotificationEnabled ? (notificationTime ?? endDate) : null;
    }

    switch (notificationType) {
      case NotificationType.specificTime:
        return notificationTime;
      case NotificationType.daily:
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

  // Helper method to get all birthday notification times
  List<DateTime> getBirthdayNotificationTimes() {
    if (taskType != TaskType.birthday || birthdayNotificationSchedule.isEmpty) {
      return [];
    }

    final birthdayDate = startDate; // Birth date
    final now = tz.TZDateTime.now(tz.local);
    final currentYear = now.year;

    // Calculate this year's birthday
    final thisYearBirthday = tz.TZDateTime(
      tz.local,
      currentYear,
      birthdayDate.month,
      birthdayDate.day,
    );

    // If this year's birthday has passed, calculate next year's
    final targetBirthday = thisYearBirthday.isAfter(now)
        ? thisYearBirthday
        : tz.TZDateTime(
            tz.local,
            currentYear + 1,
            birthdayDate.month,
            birthdayDate.day,
          );

    List<DateTime> notificationTimes = [];

    for (final option in birthdayNotificationSchedule) {
      late tz.TZDateTime notificationTime;

      switch (option) {
        case BirthdayNotificationOption.oneDayBefore:
          notificationTime = targetBirthday.subtract(const Duration(days: 1));
          // Set to 9 AM for gift preparation reminder
          notificationTime = tz.TZDateTime(
            tz.local,
            notificationTime.year,
            notificationTime.month,
            notificationTime.day,
            9, // 9 AM
            0,
          );
          break;
        case BirthdayNotificationOption.twoHoursBefore:
          notificationTime = targetBirthday.subtract(const Duration(hours: 2));
          // 10 PM the night before
          break;
        case BirthdayNotificationOption.tenMinutesBefore:
          notificationTime = targetBirthday.subtract(
            const Duration(minutes: 10),
          );
          // 11:50 PM the night before
          break;
        case BirthdayNotificationOption.exactTime:
          notificationTime = targetBirthday;
          // Exactly at 12:00 AM on birthday
          break;
      }

      // Only add future notification times
      if (notificationTime.isAfter(now)) {
        notificationTimes.add(notificationTime);
      }
    }

    debugPrint('🎂 Birthday notification times for $title: $notificationTimes');
    return notificationTimes;
  }
}
