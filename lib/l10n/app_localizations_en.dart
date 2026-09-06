// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'LifeQue';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navTodoList => 'To Do List';

  @override
  String get navReminders => 'Reminders';

  @override
  String get navBirthdays => 'Birthdays';

  @override
  String get navExpenses => 'Expense Tracker';

  @override
  String get navMedicines => 'Medicines';

  @override
  String get navPrayerTimes => 'Prayer Times';

  @override
  String get navStudyTimer => 'Study Timer';

  @override
  String get navSettings => 'Settings';

  @override
  String get drawerTagline => 'Your Personal Life Manager';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonMore => 'More';

  @override
  String get commonDone => 'Done';

  @override
  String get commonToday => 'Today';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonNow => 'Now';

  @override
  String get commonOff => 'Off';

  @override
  String get commonNone => 'None';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsNavigationOrder => 'Navigation Order';

  @override
  String settingsNavigationOrderSubtitle(String page) {
    return 'Home: $page';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCheckUpdates => 'Check for Updates';

  @override
  String get settingsCheckUpdatesSubtitle =>
      'See if a newer version is available';

  @override
  String get settingsAbout => 'About LifeQue';

  @override
  String get settingsAboutSubtitle => 'Version info, developer & links';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsPrivacySubtitle => 'How we handle your data';

  @override
  String get settingsTerms => 'Terms & Conditions';

  @override
  String get settingsTermsSubtitle => 'Usage terms of the app';

  @override
  String get settingsMadeBy => 'Made with ❤️ by Zaman Sheikh';

  @override
  String get navOrderTitle => 'Navigation Order';

  @override
  String get navOrderSubtitle => 'Drag to reorder. First item = home page.';

  @override
  String navOrderHomePage(String page) {
    return 'Home page:  $page';
  }

  @override
  String get navOrderHomeBadge => 'Home page';

  @override
  String get navOrderSave => 'Save Order';

  @override
  String get navOrderSaved => 'Navigation order saved';

  @override
  String languageComingSoon(String language) {
    return '$language · coming soon';
  }

  @override
  String languageSet(String language) {
    return 'Language set to $language';
  }

  @override
  String languageSavedPending(String language) {
    return '$language is saved. The app stays in English until the translation ships.';
  }

  @override
  String get tasksTabActive => 'Active';

  @override
  String get tasksTabAll => 'All';

  @override
  String get tasksTabDone => 'Done';

  @override
  String get tasksGroupDueToday => 'Due today';

  @override
  String get tasksGroupNext7Days => 'Next 7 days';

  @override
  String get tasksGroupLater => 'Later';

  @override
  String get tasksGroupOverdue => 'Overdue';

  @override
  String get tasksGroupInProgress => 'In progress';

  @override
  String get tasksGroupNotStarted => 'Not started yet';

  @override
  String get tasksGroupCompleted => 'Completed';

  @override
  String get tasksEmptyTitle => 'No tasks yet';

  @override
  String get tasksEmptyBody =>
      'Add something with a start and an end date, and it will show up here while it is running.';

  @override
  String get tasksAllDoneTitle => 'Nothing on right now';

  @override
  String get tasksAllDoneBody =>
      'Everything with a deadline is either finished or not started yet. Check All Tasks to see the rest.';

  @override
  String get tasksTapPlus => 'Tap + to add one';

  @override
  String get tasksNoCompletedTitle => 'No completed tasks yet';

  @override
  String get tasksNoCompletedBody => 'Complete some tasks to see them here.';

  @override
  String get tasksFirstRunTitle => 'Welcome to LifeQue';

  @override
  String get tasksFirstRunBody =>
      'Pick somewhere to start. Everything here is also in the menu.';

  @override
  String get tasksStartTask => 'Add your first task';

  @override
  String get tasksStartTaskSub => 'Something with a deadline to work towards';

  @override
  String get tasksStartPrayer => 'Set up prayer times';

  @override
  String get tasksStartPrayerSub =>
      'Waqt times, jamaat and a home-screen widget';

  @override
  String get tasksStartBirthday => 'Save a birthday';

  @override
  String get tasksStartBirthdaySub => 'Be reminded a day before, every year';

  @override
  String get tasksStartTodo => 'Start a to-do list';

  @override
  String get tasksStartTodoSub => 'The small things, ticked off as you go';

  @override
  String get tasksDeleteTitle => 'Delete task?';

  @override
  String tasksDeleteBody(String title) {
    return '“$title” will be removed.';
  }

  @override
  String get tasksMedicinesTooltip => 'Medicines';

  @override
  String get taskCardDone => 'Done';

  @override
  String taskCardStartsIn(String time) {
    return 'starts in $time';
  }

  @override
  String taskCardLeft(String time) {
    return '$time left';
  }

  @override
  String taskCardOver(String time) {
    return '$time over';
  }

  @override
  String taskUnitDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '${countString}d';
  }

  @override
  String taskUnitHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '${countString}h';
  }

  @override
  String taskUnitMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '${countString}m';
  }

  @override
  String taskUnitSeconds(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '${countString}s';
  }

  @override
  String get taskFormNewTitle => 'New task';

  @override
  String get taskFormEditTitle => 'Edit task';

  @override
  String get taskFormTitleHint => 'What needs to be done?';

  @override
  String get taskFormTitleEmpty => 'Give it a name';

  @override
  String get taskFormDue => 'Due';

  @override
  String get taskFormStarts => 'Starts';

  @override
  String get taskFormPresetToday => 'Today';

  @override
  String get taskFormPresetTomorrow => 'Tomorrow';

  @override
  String get taskFormPresetWeek => 'In a week';

  @override
  String get taskFormEndBeforeStart =>
      'The due time needs to be after the start.';

  @override
  String get taskFormRemindMe => 'Remind me';

  @override
  String get taskFormModeBeforeDue => 'Before it is due';

  @override
  String get taskFormModeAtTime => 'At a set time';

  @override
  String get taskFormModeDaily => 'Every day';

  @override
  String get taskFormAt => 'At';

  @override
  String get taskFormPickTime => 'Pick a time';

  @override
  String taskFormEveryDayAt(String time) {
    return '$time every day';
  }

  @override
  String get taskFormMoreOptions => 'More options';

  @override
  String get taskFormNotesHint => 'Notes (optional)';

  @override
  String get taskFormPinTitle => 'Keep it in the notification shade';

  @override
  String get taskFormPinSubtitle =>
      'An ongoing notification you can see at a glance';

  @override
  String get taskFormCreate => 'Create task';

  @override
  String get taskFormSaveChanges => 'Save changes';

  @override
  String get taskFormNeedReminderTime =>
      'Pick the time you want to be reminded.';

  @override
  String get taskFormNeedDailyTime => 'Pick the time of day for the reminder.';

  @override
  String get beforeEnd10Minutes => '10 minutes';

  @override
  String get beforeEnd30Minutes => '30 minutes';

  @override
  String get beforeEnd1Hour => '1 hour';

  @override
  String get beforeEnd2Hours => '2 hours';

  @override
  String get beforeEnd1Day => '1 day';

  @override
  String get pinBeforeTitle => 'Pin before the reminder';

  @override
  String get pinBeforeBody => 'Stays pinned until the reminder fires';

  @override
  String get pinAfterTitle => 'Pin after the reminder';

  @override
  String get pinAfterBody => 'Pins once the reminder has fired';

  @override
  String get detailTask => 'Task';

  @override
  String get detailReminder => 'Reminder';

  @override
  String get detailBirthday => 'Birthday';

  @override
  String get detailGeneric => 'Details';

  @override
  String get detailNotFound => 'Task not found';

  @override
  String get detailSectionTimeLeft => 'TIME LEFT';

  @override
  String get detailSectionCountdown => 'COUNTDOWN';

  @override
  String get detailSectionTimeline => 'TIMELINE';

  @override
  String get detailSectionDetails => 'DETAILS';

  @override
  String get detailSectionReminders => 'REMINDERS';

  @override
  String get detailSectionAbout => 'ABOUT';

  @override
  String get detailSectionWhen => 'WHEN';

  @override
  String get detailSectionToday => 'TODAY';

  @override
  String get detailUntilDeadline => 'Until the deadline';

  @override
  String get detailDeadlinePassed => 'The deadline has passed';

  @override
  String get detailTimeElapsed => 'Time elapsed';

  @override
  String get detailDaysLeft => 'days left';

  @override
  String get detailDaysTotal => 'days total';

  @override
  String get detailStarted => 'Started';

  @override
  String get detailDue => 'Due';

  @override
  String get detailWasDue => 'Was due';

  @override
  String get detailReminderRow => 'Reminder';

  @override
  String get detailPinned => 'Pinned';

  @override
  String get detailPinnedValue => 'Kept in the shade';

  @override
  String get detailCreated => 'Created';

  @override
  String get detailLastEdited => 'Last edited';

  @override
  String get detailStatusCompleted => 'Completed';

  @override
  String get detailStatusOverdue => 'Overdue';

  @override
  String get detailStatusInProgress => 'In progress';

  @override
  String get detailStatusNotStarted => 'Not started yet';

  @override
  String detailReminderBefore(String option) {
    return '$option before';
  }

  @override
  String detailReminderDaily(String time) {
    return '$time daily';
  }

  @override
  String get detailReminderAtTime => 'At a set time';

  @override
  String get detailReminderBeforeDue => 'Before it is due';

  @override
  String get detailUntilItFires => 'Until it goes off';

  @override
  String get detailAlreadyFired => 'This reminder has already gone off';

  @override
  String get detailStatusDone => 'Done';

  @override
  String get detailStatusPassed => 'Already passed';

  @override
  String get detailStatusAnyMinute => 'Any minute now';

  @override
  String get detailStatusWaiting => 'Waiting';

  @override
  String get detailRowDate => 'Date';

  @override
  String get detailRowTime => 'Time';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get remindersEmptyTitle => 'No reminders set';

  @override
  String get remindersEmptyBody =>
      'Set a reminder for the things you would otherwise forget.';

  @override
  String get remindersSetOne => 'Set a reminder';

  @override
  String get remindersNewOne => 'New reminder';

  @override
  String get remindersNothingPending => 'Nothing pending';

  @override
  String get remindersAllCaughtUp => 'You\'re all caught up';

  @override
  String get remindersAllDoneBody =>
      'Nothing pending — everything here is done.';

  @override
  String get remindersNextUp => 'Next reminder';

  @override
  String get remindersGroupMissed => 'Missed';

  @override
  String get remindersGroupToday => 'Today';

  @override
  String get remindersGroupTomorrow => 'Tomorrow';

  @override
  String get remindersGroupLater => 'Later';

  @override
  String remindersDoneCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString done';
  }

  @override
  String get remindersDeleteTitle => 'Delete this reminder?';

  @override
  String get remindersKeepIt => 'Keep it';

  @override
  String get birthdaysTitle => 'Birthdays';

  @override
  String get birthdaysEmptyTitle => 'No birthdays saved';

  @override
  String get birthdaysEmptyBody =>
      'Add the people you keep meaning to wish and this page will tell you who is next.';

  @override
  String get birthdaysAddOne => 'Add a birthday';

  @override
  String get birthdaysAdd => 'Add birthday';

  @override
  String get birthdaysEveryone => 'Everyone';

  @override
  String birthdaysMatching(String query) {
    return 'Matching “$query”';
  }

  @override
  String get birthdaysNoMatch => 'Nobody by that name';

  @override
  String get birthdaysSearchHint => 'Search by name';

  @override
  String get birthdaysClearSearch => 'Clear search';

  @override
  String get birthdaysNextUp => 'Next up';

  @override
  String get birthdaysToday => 'Birthday today';

  @override
  String birthdaysInDays(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'In $daysString days';
  }

  @override
  String get birthdaysRemindersOn => 'Reminders on';

  @override
  String get birthdaysRemindersOff => 'Reminders off';

  @override
  String get birthdaysDeleteTitle => 'Remove this birthday?';

  @override
  String birthdaysTurning(int age) {
    final intl.NumberFormat ageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String ageString = ageNumberFormat.format(age);

    return 'turning $ageString';
  }

  @override
  String birthdaysTodayLine(int age) {
    final intl.NumberFormat ageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String ageString = ageNumberFormat.format(age);

    return 'It is today — they turn $ageString.';
  }

  @override
  String get birthdaysUntilBigDay => 'Until the big day';

  @override
  String get birthdaysYearsOldNow => 'years old now';

  @override
  String get birthdaysDaysToGo => 'days to go';

  @override
  String get birthdaysTheBigDay => 'the big day';

  @override
  String get birthdaysNoReminders => 'No reminders set for this birthday.';

  @override
  String get birthdaysBorn => 'Born';

  @override
  String get birthdaysNext => 'Next birthday';

  @override
  String get birthdaysSaved => 'Saved';

  @override
  String get birthdaysTomorrow => 'Birthday tomorrow';

  @override
  String get commonSomethingWrong => 'Something went wrong';

  @override
  String get commonMenu => 'Menu';

  @override
  String get commonDetails => 'Details';

  @override
  String get commonSearch => 'Search';

  @override
  String get countdownDays => 'days';

  @override
  String get countdownHours => 'hrs';

  @override
  String get countdownMinutes => 'min';

  @override
  String get countdownSeconds => 'sec';

  @override
  String get todosTitle => 'To Do List';

  @override
  String get todosTabAll => 'All';

  @override
  String get todosTabToday => 'Today';

  @override
  String get todosTabUpcoming => 'Upcoming';

  @override
  String get todosTabDone => 'Done';

  @override
  String get todosNew => 'New to-do';

  @override
  String get todosGroupOverdue => 'Overdue';

  @override
  String get todosGroupToday => 'Today';

  @override
  String get todosGroupTomorrow => 'Tomorrow';

  @override
  String get todosGroupThisWeek => 'This week';

  @override
  String get todosGroupLater => 'Later';

  @override
  String get todosGroupNoDate => 'No date';

  @override
  String get todosGroupCompleted => 'Completed';

  @override
  String get todosSearchHint => 'Search your to-dos';

  @override
  String get todosClearSearch => 'Clear search';

  @override
  String get todosAnyCategory => 'Any category';

  @override
  String get todosNothingMatched => 'Nothing matched';

  @override
  String get todosNothingMatchedBody =>
      'Try a different word, or clear the category filter.';

  @override
  String get todosNothingFinished => 'Nothing finished yet';

  @override
  String get todosNothingToday => 'Nothing due today';

  @override
  String get todosNothingAhead => 'Nothing scheduled ahead';

  @override
  String get todosAllClear => 'All clear';

  @override
  String get todosNothingInView => 'Nothing to do in this view.';

  @override
  String get todosNothingLeft => 'Nothing left — enjoy it';

  @override
  String get todosEmptyTitle => 'Your list is empty';

  @override
  String get todosEmptyBody =>
      'Add something you need to get done. Give it a due date and a reminder, and the app will nudge you when it matters.';

  @override
  String get todosAddFirst => 'Add your first to-do';

  @override
  String get todosDeleteTitle => 'Delete this to-do?';

  @override
  String get todosKeepIt => 'Keep it';

  @override
  String get todoDetailTitle => 'To-do';

  @override
  String get todoRowCategory => 'Category';

  @override
  String get todoRowPriority => 'Priority';

  @override
  String get todoRowDue => 'Due';

  @override
  String get todoRowNoDue => 'No due date';

  @override
  String get todoRowReminder => 'Reminder';

  @override
  String get todoRowCreated => 'Created';

  @override
  String get todoRowCompleted => 'Completed';

  @override
  String get todoStatusDone => 'Done';

  @override
  String get todoStatusOverdue => 'Overdue';

  @override
  String get todoStatusDueToday => 'Due today';

  @override
  String get todoStatusDueTomorrow => 'Due tomorrow';

  @override
  String todoStatusPriority(String priority) {
    return '$priority priority';
  }

  @override
  String todoAtTime(String day, String time) {
    return '$day at $time';
  }

  @override
  String get priorityLow => 'Low';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityUrgent => 'Urgent';

  @override
  String get categoryPersonal => 'Personal';

  @override
  String get categoryWork => 'Work';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryFinance => 'Finance';

  @override
  String get categoryTravel => 'Travel';

  @override
  String get categoryHome => 'Home';

  @override
  String get categoryOther => 'Other';

  @override
  String todosDeleteBody(String title) {
    return '“$title” and its reminder will be removed. This can\'t be undone.';
  }

  @override
  String reminderAtTime(String day, String time) {
    return '$day, $time';
  }

  @override
  String birthdaysInDaysShort(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'in $daysString d';
  }

  @override
  String birthdaysInMonthsShort(int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return 'in $monthsString mo';
  }

  @override
  String get birthdayOptOneDay => '1 day before (gift prep)';

  @override
  String get birthdayOptOneDayBody => 'Get reminded to prepare gifts';

  @override
  String get birthdayOptTwoHours => '2 hours before';

  @override
  String get birthdayOptTwoHoursBody => 'Final preparation reminder';

  @override
  String get birthdayOptTenMinutes => '10 minutes before';

  @override
  String get birthdayOptTenMinutesBody => 'Almost time to celebrate';

  @override
  String get birthdayOptExact => 'At exactly 12:00 AM';

  @override
  String get birthdayOptExactBody => 'Birthday celebration time';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get prayerTahajjud => 'Tahajjud';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerNavPrayer => 'Prayer';

  @override
  String get prayerNavCalendar => 'Calendar';

  @override
  String get prayerNavTasbih => 'Tasbih';

  @override
  String get prayerNavLearn => 'Learn';

  @override
  String get prayerNavMore => 'More';

  @override
  String get salatTimesTitle => 'Salat Times';

  @override
  String get salatSetAlarm => 'Set Alarm';

  @override
  String get salatSetJamaat => 'Set jamaat';

  @override
  String salatJamaatAt(String time) {
    return 'Jamaat $time';
  }

  @override
  String salatTill(String time) {
    return 'till $time';
  }

  @override
  String get salatNowBadge => 'NOW';

  @override
  String get gaugeWaqtEndsIn => 'Waqt ends in';

  @override
  String get gaugeStartsIn => 'Starts in';

  @override
  String get gaugeBeginsIn => 'Begins in';

  @override
  String gaugeStartsAt(String time) {
    return 'Starts at $time';
  }

  @override
  String gaugeBeginsAt(String time) {
    return 'Begins at $time';
  }

  @override
  String get gaugeEndsAtFajr => 'Ends at Fajr, in';

  @override
  String get prohibitedCardTitle => 'Prohibited Times for Prayer';

  @override
  String get prohibitedSeeReference => 'See Reference';

  @override
  String get prohibitedSubtitle => 'Salat is prohibited during these times.';

  @override
  String prohibitedActiveNow(String left) {
    return 'Active now · $left left — salat is prohibited during these times.';
  }

  @override
  String prohibitedNext(String window, String time) {
    return 'Salat is prohibited during these times · next: $window $time';
  }

  @override
  String get prohibitedNowTitle => 'Salat is prohibited right now';

  @override
  String prohibitedNowBody(String window, String time, String left) {
    return '$window · ends at $time (in $left)';
  }

  @override
  String get prohibitedDismiss => 'Dismiss';

  @override
  String get prohibitedSunrise => 'While the sun rises';

  @override
  String get prohibitedZawal => 'While the sun is at its peak';

  @override
  String get prohibitedSunset => 'While the sun sets';

  @override
  String get prohibitedMorning => 'Morning';

  @override
  String get prohibitedNoon => 'Noon';

  @override
  String get prohibitedEvening => 'Evening';

  @override
  String get restrictedTimesTitle => 'Restricted Times';

  @override
  String get nafalTitle => 'Nafal Prayer Time';

  @override
  String get nafalIshraq => 'Ishraq / Duha';

  @override
  String get nafalZawalStart => 'Zawal Start';

  @override
  String get nafalAwabin => 'Awabin';

  @override
  String nafalAfterMaghrib(String time) {
    return 'After Maghrib – $time';
  }

  @override
  String nafalAfterIsha(String time) {
    return 'After Isha – $time';
  }

  @override
  String nafalLastThird(String time) {
    return 'Last ⅓ of night begins: $time';
  }

  @override
  String get progressAllFive => 'All five prayed today';

  @override
  String get progressLoggedToday => 'Prayers logged today';

  @override
  String get progressLogged => 'Prayers logged';

  @override
  String get progressViewStats => 'View stats';

  @override
  String get progressNoStreak => 'No streak yet';

  @override
  String progressStreak(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString-day streak';
  }

  @override
  String get prayerBackToToday => 'Back to today';

  @override
  String get prayerSettingsTitle => 'Prayer settings';

  @override
  String get prayerSettingsSubtitle => 'How prayer times are calculated';

  @override
  String get prayerSectionMethod => 'CALCULATION METHOD';

  @override
  String get prayerSectionMadhab => 'MADHAB — FOR ASR';

  @override
  String get prayerSectionLocation => 'LOCATION';

  @override
  String get prayerSetLocationManually => 'Set location manually';

  @override
  String get prayerSetLocation => 'Set Location';

  @override
  String get prayerLocationName => 'Location Name';

  @override
  String get prayerLatitude => 'Latitude';

  @override
  String get prayerLongitude => 'Longitude';

  @override
  String get prayerCurrentLocation => 'Current Location';

  @override
  String get prayerDefaultLocationNote =>
      'Using default location (Dhaka). Tap the location pin to set yours.';

  @override
  String get prayerUnableToCompute => 'Unable to compute prayer times';

  @override
  String prayerAlarmSetFor(String prayer, String time, String day) {
    return '$prayer alarm set for $time $day';
  }

  @override
  String prayerAlarmSet(String prayer) {
    return '$prayer alarm set';
  }

  @override
  String prayerAlarmOff(String prayer) {
    return '$prayer alarm turned off';
  }

  @override
  String get prayerDayToday => 'today';

  @override
  String get prayerDayTomorrow => 'tomorrow';

  @override
  String get madhabHanafi => 'Hanafi';

  @override
  String get madhabHanafiNote => 'Later Asr';

  @override
  String get madhabShafi => 'Shafi';

  @override
  String get madhabShafiNote => 'Earlier Asr';

  @override
  String get ramadanMode => 'RAMADAN MODE';

  @override
  String ramadanDay(int day) {
    final intl.NumberFormat dayNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dayString = dayNumberFormat.format(day);

    return 'RAMADAN · DAY $dayString';
  }

  @override
  String get prohibitedAllPassed =>
      'Salat is prohibited during these times · all have passed today.';

  @override
  String get reminderFormNew => 'New reminder';

  @override
  String get reminderFormEdit => 'Edit reminder';

  @override
  String get reminderFormTitleLabel => 'Remind me to…';

  @override
  String get reminderFormTitleEmpty => 'Say what to remind you about';

  @override
  String get reminderFormNote => 'Add a note';

  @override
  String get reminderFormNoteHint => 'Anything worth remembering';

  @override
  String get reminderFormInAnHour => 'In an hour';

  @override
  String get reminderFormThisEvening => 'This evening';

  @override
  String get reminderFormTomorrow9 => 'Tomorrow 9am';

  @override
  String get reminderFormPick => 'Pick…';

  @override
  String get reminderFormKeepShade => 'Keep it in the shade';

  @override
  String get reminderFormOnDate => 'Remind me on';

  @override
  String get reminderFormAtTime => 'Remind me at';

  @override
  String get reminderFormFutureTime => 'Pick a time in the future';

  @override
  String get birthdayFormNew => 'New birthday';

  @override
  String get birthdayFormEdit => 'Edit birthday';

  @override
  String get birthdayFormNameLabel => 'Whose birthday?';

  @override
  String get birthdayFormNameEmpty => 'Add their name';

  @override
  String get birthdayFormNoteHint => 'Gift ideas, how you know them…';

  @override
  String get birthdayFormDob => 'Date of birth';

  @override
  String birthdayFormTurning(int age) {
    final intl.NumberFormat ageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String ageString = ageNumberFormat.format(age);

    return 'Turning $ageString on their next birthday';
  }

  @override
  String get birthdayFormSetYear => 'Set the year of birth to show their age';

  @override
  String get birthdayFormNoReminders =>
      'No reminders — the date is just saved here for you to look up.';

  @override
  String get birthdayFormDayBefore => 'The day before';

  @override
  String get birthdayFormTwoHours => 'Two hours before';

  @override
  String get birthdayFormTenMinutes => 'Ten minutes before';

  @override
  String get birthdayFormMidnight => 'On the day, at midnight';

  @override
  String get todoFormNew => 'New to-do';

  @override
  String get todoFormEdit => 'Edit to-do';

  @override
  String get todoFormTitleLabel => 'What needs doing?';

  @override
  String get todoFormTitleEmpty => 'Give it a name';

  @override
  String get todoFormNoteHint => 'Any detail worth remembering';

  @override
  String get todoFormPriority => 'Priority';

  @override
  String get todoFormCategory => 'Category';

  @override
  String get todoFormNoDate => 'No date';

  @override
  String get todoFormDueDate => 'Due date';

  @override
  String get todoFormDueTime => 'Due time';

  @override
  String get todoFormAtDueTime => 'At due time';

  @override
  String get todoFormDayBefore => 'A day before';

  @override
  String get todoFormPassed =>
      'That time has already passed — pick a later one or the reminder will not fire.';

  @override
  String todoFormNotificationOn(String when) {
    return 'Notification on $when';
  }

  @override
  String get medTitle => 'Medications';

  @override
  String get medAdd => 'Add Medicine';

  @override
  String get medEdit => 'Edit Medicine';

  @override
  String get medDetailTitle => 'Medicine';

  @override
  String get medEmptyTitle => 'No medications yet';

  @override
  String get medViewAll => 'View All Medicines';

  @override
  String get medQuickAdd => 'Quick Add';

  @override
  String get medRefresh => 'Refresh';

  @override
  String get medNameLabel => 'Medicine Name';

  @override
  String get medNameEmpty => 'Please enter medicine name';

  @override
  String get medDosage => 'Dosage';

  @override
  String get medDuration => 'Duration (days)';

  @override
  String get medStartDate => 'Start Date';

  @override
  String get medTimesPerDay => 'Times per day:';

  @override
  String get medNotificationTimes => 'Notification Times:';

  @override
  String get medMealTiming => 'Meal Timing';

  @override
  String get medBeforeMeal => 'Before Meal';

  @override
  String get medAfterMeal => 'After Meal';

  @override
  String get medWithMeal => 'With Meal';

  @override
  String get medEmptyStomach => 'Empty Stomach';

  @override
  String get medAnytime => 'Anytime';

  @override
  String get medTablet => 'Tablet';

  @override
  String get medCapsule => 'Capsule';

  @override
  String get medInjection => 'Injection';

  @override
  String get medDoctor => 'Doctor';

  @override
  String get medDoctorName => 'Doctor Name';

  @override
  String get medDescription => 'Description';

  @override
  String get medAdditionalInfo => 'Additional Info (Optional)';

  @override
  String get medDeleteTitle => 'Delete Medicine';

  @override
  String get medDeleteBody =>
      'Are you sure you want to delete this medicine and its doses?';

  @override
  String get medSectionCourse => 'THIS COURSE';

  @override
  String get medSectionDoseHistory => 'DOSE HISTORY';

  @override
  String get medDosesTaken => 'Doses taken';

  @override
  String medDayOf(int day, int total) {
    final intl.NumberFormat dayNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dayString = dayNumberFormat.format(day);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'Day $dayString of $totalString';
  }

  @override
  String get medNoDoses => 'No doses recorded yet.';

  @override
  String get medStatusOnCourse => 'On this course';

  @override
  String get medStatusFinished => 'Course finished';

  @override
  String get medStatusNotStarted => 'Not started yet';

  @override
  String get medDoseTaken => 'Taken';

  @override
  String get medDoseToCome => 'To come';

  @override
  String get medDoseSkipped => 'Skipped';

  @override
  String get medDoseMissed => 'Missed';

  @override
  String get medType => 'Type';

  @override
  String get medTiming => 'Timing';

  @override
  String get medStarted => 'Started';

  @override
  String get medEnds => 'Ends';

  @override
  String get medNotes => 'Notes';

  @override
  String medTimesADay(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString× a day';
  }

  @override
  String get medNotFound => 'Medicine not found';

  @override
  String get medUnexpectedError => 'An unexpected error occurred';

  @override
  String get studyTitle => 'Study Timer';

  @override
  String get studySettings => 'Timer settings';

  @override
  String get studyYourPlan => 'Your plan';

  @override
  String get studyReady => 'Ready when you are';

  @override
  String get studyStart => 'Start focusing';

  @override
  String get studyResume => 'Resume';

  @override
  String get studyKeepGoing => 'Keep going';

  @override
  String get studyPaused => 'Paused';

  @override
  String get studyFocused => 'Focused';

  @override
  String get studyFocusBlock => 'Focus block';

  @override
  String get studyShortBreak => 'Short break';

  @override
  String get studyLongBreak => 'Long break';

  @override
  String get studyBlocks => 'Blocks';

  @override
  String get studyBlocksBeforeLong => 'Blocks before a long break';

  @override
  String get studyAdjust => 'Adjust';

  @override
  String get studyEndSession => 'End session';

  @override
  String get studyEndSessionTitle => 'End this session?';

  @override
  String get studyAlarmNote =>
      'Alarms are set for every block and break, so you can put the phone down.';

  @override
  String get studyRunningNote =>
      'A session is running — these take effect the next time you start.';

  @override
  String studyThenNext(String phase) {
    return 'Then $phase';
  }

  @override
  String studyMinutesToStart(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString min to start';
  }

  @override
  String get expTitle => 'Expense Tracker';

  @override
  String get expLoading => 'Loading your expenses…';

  @override
  String get expShoppingLists => 'Shopping lists';

  @override
  String get expNewList => 'New list';

  @override
  String get expNewShoppingList => 'New shopping list';

  @override
  String get expEditList => 'Edit list';

  @override
  String get expCreateList => 'Create a list';

  @override
  String get expStartFirstList => 'Start your first list';

  @override
  String get expListName => 'List name';

  @override
  String get expGiveListName => 'Give this list a name';

  @override
  String get expListTotal => 'List total';

  @override
  String get expListSaved => 'List saved';

  @override
  String get expListUpdated => 'List updated';

  @override
  String get expDeleteListTitle => 'Delete this list?';

  @override
  String get expAddItem => 'Add an item';

  @override
  String get expItemName => 'Item name';

  @override
  String get expUntitledItem => 'Untitled item';

  @override
  String get expEditingItem => 'Editing item';

  @override
  String get expRemoveItem => 'Remove item';

  @override
  String get expNeedOneItem => 'Add at least one item before saving';

  @override
  String get expItemHelp => 'Type a name, add a price if you know it, press +';

  @override
  String get expBought => 'Already bought';

  @override
  String get expNotBought => 'Not bought';

  @override
  String get expAllBought => 'All bought';

  @override
  String get expTapWhenBought => 'Tap when bought';

  @override
  String get expPlanned => 'Planned';

  @override
  String get expPurchased => 'Purchased';

  @override
  String get expSearchHint => 'Search lists and items…';

  @override
  String get expSearchResults => 'Search results';

  @override
  String get expNothingMatched => 'Nothing matched';

  @override
  String get expPickMonth => 'Pick a month';

  @override
  String get expPreviousMonth => 'Previous month';

  @override
  String get expNextMonth => 'Next month';

  @override
  String get expBudget => 'Budget';

  @override
  String get expMonthlyBudget => 'Monthly Budget';

  @override
  String get expSetBudget => 'Set Budget';

  @override
  String get expEditBudget => 'Edit Budget';

  @override
  String get expUpdateBudget => 'Update Budget';

  @override
  String get expNoBudgetSet => 'No budget set';

  @override
  String get expNoBudgetThisMonth => 'No budget set for this month';

  @override
  String get expBudgetAmount => 'Budget Amount';

  @override
  String get expEnterAmount => 'Enter amount';

  @override
  String get expInvalidAmount => 'Invalid amount';

  @override
  String get expNeedAmount => 'Please enter a budget amount';

  @override
  String get expNeedValidAmount => 'Please enter a valid amount greater than 0';

  @override
  String get expCategoryBudgets => 'Category Budgets';

  @override
  String get expSelectCategory => 'Select Category';

  @override
  String get expCategoryName => 'Category Name';

  @override
  String get expAddCustomCategory => 'Add Custom Category';

  @override
  String get expCreateCustomCategory => 'Create Custom Category';

  @override
  String get expDeleteCategory => 'Delete Category';

  @override
  String get expCategoryExists => 'Category name already exists';

  @override
  String get expCategoryOverBudget =>
      'Category budgets exceed monthly budget — please reduce.';

  @override
  String get expUnallocated => 'Unallocated';

  @override
  String get expOnTrack => 'On track';

  @override
  String get expGoodProgress => 'Good progress';

  @override
  String get expHalfway => 'Halfway through';

  @override
  String get expSpendingCautiously => 'Spending cautiously';

  @override
  String get expAlmostAtLimit => 'Almost at limit';

  @override
  String get expOverBudget => 'Over budget!';

  @override
  String get expBudgetExceeded => 'Budget exceeded';

  @override
  String get expBudgetMet => 'Budget exactly met! Great job!';

  @override
  String get expNoteOptional => 'Note (optional)';

  @override
  String get expRequired => 'Required';

  @override
  String get expInvalid => 'Invalid';

  @override
  String get expCreate => 'Create';

  @override
  String get expUpdate => 'Update';

  @override
  String get expEndSession => 'End session';

  @override
  String get medEmptyBody =>
      'Add your first medication to start tracking your daily doses';

  @override
  String get remindersEmptyBodyLong =>
      'Set one for anything you\'d rather not keep in your head — a call to make, a bill to pay, a bin to put out.';

  @override
  String get studyEndSessionBody =>
      'The countdown stops and every alarm for the rest of the session is cancelled.';

  @override
  String get expListsHelp =>
      'Write down what you plan to buy with a price for each item, then tick things off as you buy them.';

  @override
  String get widgetLocationNote =>
      'Set your location first and these will fill in with your own prayer times.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutTagline =>
      'A beautiful and intuitive app to manage your daily tasks and medicine reminders.';

  @override
  String get aboutDevelopedBy => 'Developed by';

  @override
  String get commonClose => 'Close';

  @override
  String get tasbihTitle => 'Tasbih';

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String tasbihRound(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'Round $numberString';
  }

  @override
  String get tasbihTapToBegin => 'tap to begin';

  @override
  String tasbihCounted(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString counted';
  }

  @override
  String get tasbihReset => 'Reset';

  @override
  String get tasbihSubhanAllah => 'SubhanAllah';

  @override
  String get tasbihAlhamdulillah => 'Alhamdulillah';

  @override
  String get tasbihAllahuAkbar => 'Allahu Akbar';

  @override
  String get tasbihSubhanAllahMeaning => 'SubhanAllah — Glory be to Allah';

  @override
  String get tasbihAlhamdulillahMeaning =>
      'Alhamdulillah — All praise is for Allah';

  @override
  String get tasbihAllahuAkbarMeaning => 'Allahu Akbar — Allah is the Greatest';

  @override
  String get tasbihResetTitle => 'Start this round again?';

  @override
  String tasbihResetBody(int round) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'This clears round $roundString and starts again from SubhanAllah.';
  }

  @override
  String get tasbihTapToCount => 'tap to count';

  @override
  String tasbihTimes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString×';
  }

  @override
  String get qiblaCompass => 'Qibla Compass';

  @override
  String qiblaFromNorth(String km) {
    return 'from North · $km km to Makkah';
  }

  @override
  String get qiblaNoCompass =>
      'No compass on this device — bearing shown above';

  @override
  String get restrictedSubtitle => 'Times when Salah is discouraged';

  @override
  String get restrictedActiveSubtitle => 'Avoid voluntary prayer right now';

  @override
  String get restrictedTodayWindows => 'Today\'s restricted windows';

  @override
  String get restrictedActive => 'ACTIVE';

  @override
  String get restrictedPassed => 'PASSED';

  @override
  String get restrictedUpcoming => 'UPCOMING';

  @override
  String get restrictedWindowSunrise => 'Sunrise period';

  @override
  String get restrictedWindowZawal => 'Zawal (midday)';

  @override
  String get restrictedWindowSunset => 'Sunset period';

  @override
  String restrictedAboutMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return 'about $minutesString minutes';
  }

  @override
  String get restrictedWhy => 'Why these times?';

  @override
  String get restrictedWhyBody =>
      'Three short windows each day — sunrise, midday (Zawal) and sunset — are makruh for voluntary prayer. Their exact lengths are listed above. Only a missed Asr may still be offered during the sunset window, since delaying it further would lose the Asr altogether.';

  @override
  String get restrictedEvidence => 'Evidence';

  @override
  String get restrictedHadith1 =>
      'Uqbah ibn Amir (may Allah be pleased with him) said: there were three times at which the Messenger of Allah ﷺ forbade us to pray, or to bury our dead — when the sun begins to rise until it has fully risen; when it stands at its zenith at midday until it passes the meridian; and when the sun begins to set until it has set.';

  @override
  String get restrictedHadith1Ref => 'Sahih Muslim 831';

  @override
  String get restrictedHadith2 =>
      'Whoever catches one rak\'ah of Asr before the sun sets has caught the Asr.';

  @override
  String get restrictedHadith2Ref => 'Sahih al-Bukhari 579';

  @override
  String get restrictedScholarNote =>
      'Rulings differ between the schools. Check with a scholar you trust for your own situation.';

  @override
  String get methodKarachi => 'University of Islamic Sciences, Karachi';

  @override
  String get methodMwl => 'Muslim World League';

  @override
  String get methodEgyptian => 'Egyptian General Authority';

  @override
  String get methodUmmAlQura => 'Umm al-Qura, Makkah';

  @override
  String get methodDubai => 'Dubai';

  @override
  String get methodQatar => 'Qatar';

  @override
  String get methodKuwait => 'Kuwait';

  @override
  String get methodMoonsighting => 'Moonsighting Committee';

  @override
  String get methodSingapore => 'Singapore';

  @override
  String get methodIsna => 'ISNA (North America)';

  @override
  String get methodTurkey => 'Turkey';

  @override
  String get methodTehran => 'Tehran';

  @override
  String get alarmSheetTitle => 'Prayer alarms';

  @override
  String get alarmSheetSubtitle => 'A reminder for each waqt';

  @override
  String get alarmSheetWhen => 'When each alarm rings';

  @override
  String get alarmSheetSound => 'Adhan sound';

  @override
  String get alarmSheetRingsFor => 'Rings for';

  @override
  String get alarmSheetPaused => 'All alarms are paused';

  @override
  String get alarmNone => 'No alarm';

  @override
  String get alarmMeasuredFrom => 'Measured from';

  @override
  String get alarmAnchorWaqt => 'Waqt';

  @override
  String get alarmAnchorJamaat => 'Jamaat';

  @override
  String get alarmAtWaqt => 'At waqt';

  @override
  String get alarmAtJamaat => 'At jamaat';

  @override
  String alarmMinBeforeWaqt(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString min before waqt';
  }

  @override
  String alarmMinAfterWaqt(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString min after waqt';
  }

  @override
  String alarmMinBeforeJamaat(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString min before jamaat';
  }

  @override
  String alarmMinAfterJamaat(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString min after jamaat';
  }

  @override
  String get alarmVibrate => 'Vibrate';

  @override
  String get alarmVibrateBody => 'Buzz while the adhan plays';

  @override
  String get alarmSoundFailed => 'Could not play this sound';

  @override
  String get alarmSound1 => 'Alarm Sound 1';

  @override
  String get alarmSound2 => 'Alarm Sound 2';

  @override
  String get alarmSound3 => 'Alarm Sound 3';

  @override
  String alarmMinutes(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString min';
  }

  @override
  String get calFullMonth => 'Full month';

  @override
  String get calShare => 'Share';

  @override
  String get calShareMonth => 'Share month';

  @override
  String get calShareTimetable => 'Share timetable';

  @override
  String get calPreparing => 'Preparing…';

  @override
  String get calDate => 'DATE';

  @override
  String get calToday => 'TODAY';

  @override
  String get calTodayRow => 'Today';

  @override
  String get calJumuah => '= Jumu\'ah';

  @override
  String get calShareFailed => 'Could not share the timetable';

  @override
  String get calEncodeFailed => 'Could not encode the timetable';

  @override
  String get calTimetableTitle => 'Prayer timetable';

  @override
  String get calVerifyNote =>
      'Times are indicative — verify with your local mosque.';

  @override
  String get dowMon => 'M';

  @override
  String get dowTue => 'T';

  @override
  String get dowWed => 'W';

  @override
  String get dowThu => 'T';

  @override
  String get dowFri => 'F';

  @override
  String get dowSat => 'S';

  @override
  String get dowSun => 'S';

  @override
  String get shareTodayTimes => 'Share today\'s times';

  @override
  String get shareImage => 'Share image';

  @override
  String get shareCardTitle => 'Prayer Times';

  @override
  String get shareSunrise => 'SUNRISE';

  @override
  String get shareSahriEnds => 'SAHRI ENDS';

  @override
  String get shareIftar => 'IFTAR';

  @override
  String get shareFailed => 'Could not share the card';

  @override
  String get shareEncodeFailed => 'Could not encode the card';

  @override
  String shareCaption(String date) {
    return 'Prayer times · $date';
  }

  @override
  String shareMonthCaption(String location) {
    return 'Prayer timetable · $location';
  }

  @override
  String get calFridayNote =>
      '✦ Friday (Jumu\'ah) · times are indicative — verify with your local mosque';

  @override
  String get calHijriBangla => 'HIJRI · BANGLA';

  @override
  String calMonthShareCaption(String month, String location) {
    return '$month prayer timetable · $location';
  }

  @override
  String calTimetableHeader(String location, String madhab) {
    return 'Prayer timetable · $location · $madhab';
  }

  @override
  String get qiblaHoldFlat => 'hold your phone flat';

  @override
  String get qiblaAligned => '✓ Aligned — you are facing the Qibla';

  @override
  String get qiblaAlignHint => '✓ Aligned when the Kaaba points up';

  @override
  String get statsTitle => 'Prayer Stats';

  @override
  String get statsDayStreak => 'day streak';

  @override
  String statsOfThisWeek(int total) {
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return 'of $totalString this week';
  }

  @override
  String get statsThisWeek => 'This week';

  @override
  String get statsLast30 => 'Last 30 days';

  @override
  String get statsEachDot => 'each dot = 1 day';

  @override
  String get stats30DayRate => '30-day rate';

  @override
  String get moreTitle => 'More';

  @override
  String get morePrayerStats => 'Prayer stats';

  @override
  String get morePrayerStatsSub => 'Streak, weekly & 30-day history';

  @override
  String get morePrayerAlarms => 'Prayer alarms';

  @override
  String get morePrayerAlarmsSub => 'Per-prayer timing, adhan sound & duration';

  @override
  String get moreWidget => 'Home-screen widget';

  @override
  String get moreWidgetSub => 'Prayer times on your home screen';

  @override
  String get moreAdhanVoice => 'Adhan voice';

  @override
  String get moreSettings => 'Settings';

  @override
  String get moreCalculationMethod => 'Calculation method';

  @override
  String get moreMadhabAsr => 'Madhab (Asr)';

  @override
  String get moreLocation => 'Location';

  @override
  String get moreRamadanMode => 'Ramadan mode';

  @override
  String get moreNotSet => 'Not set';

  @override
  String get moreCustom => 'Custom';

  @override
  String get soundTraditional => 'Traditional alarm tone';

  @override
  String get soundGentle => 'Gentle wake-up tone';

  @override
  String get soundMelodic => 'Melodic alarm tone';

  @override
  String get methodKarachiShort => 'Karachi';

  @override
  String get methodEgyptianShort => 'Egyptian';

  @override
  String get methodUmmAlQuraShort => 'Umm al-Qura';

  @override
  String get resourcesTitle => 'Islamic Resources';

  @override
  String get resSalahGuide => 'Salah Guide';

  @override
  String get resSalahGuideSub => 'Step-by-step prayer instructions';

  @override
  String get resWaqtRakah => 'Waqt & Rakah Table';

  @override
  String get resWaqtRakahSub => 'Prayer times and rak\'ah counts';

  @override
  String get resSurahs => 'Necessary Surahs';

  @override
  String get resSurahsSub => 'Essential Qur\'anic chapters';

  @override
  String get resAfterPrayer => 'After-prayer Adhkar';

  @override
  String get resAfterPrayerSub => 'What to recite after the salam';

  @override
  String get resDuas => 'Du\'a & Adhkar';

  @override
  String get resDuasSub => 'Supplications & remembrances';

  @override
  String get waqtTitle => 'Waqt & Rakah Table';

  @override
  String get waqtSectionTimes => 'Prayer Times (Waqt)';

  @override
  String get waqtSectionRakah => 'Rak\'ah Count Table';

  @override
  String get waqtSectionWudu => 'Wudu & Tayammum Notes';

  @override
  String get waqtColPrayer => 'Prayer';

  @override
  String get waqtColFard => 'Fard';

  @override
  String get waqtColExtra => 'Extra';

  @override
  String get waqtFajrRange => 'True dawn → Sunrise';

  @override
  String get waqtDhuhrRange => 'Midday → Shadow = object';

  @override
  String get waqtAsrRange => 'Shadow doubles → Sunset';

  @override
  String get waqtMaghribRange => 'Sunset → Twilight gone';

  @override
  String get waqtIshaRange => 'End of twilight → Fajr';

  @override
  String get waqtJumuahNote => 'Replaces Dhuhr on Friday';

  @override
  String get wuduInvalidated => 'Wudu invalidated by';

  @override
  String get wuduInvalidatedBody =>
      'Urination, defecation, deep sleep, passing wind, unconsciousness';

  @override
  String get ghuslRequired => 'Ghusl required after';

  @override
  String get ghuslRequiredBody =>
      'Janabah (major impurity), menstruation, post-natal bleeding';

  @override
  String get tayammumAllowed => 'Tayammum allowed when';

  @override
  String get tayammumAllowedBody =>
      'No water available or using water is harmful — use clean dust or earth';

  @override
  String get masahKhuffayn => 'Masah on Khuffayn';

  @override
  String get masahKhuffaynBody =>
      'Wipe over leather socks: 1 day (resident), 3 days (traveller)';

  @override
  String get adhkarTitle => 'After-prayer Adhkar';

  @override
  String get adhkarSubtitle => 'Recited after the salam of every fard prayer.';

  @override
  String get adhkarSectionAfterSalam => 'AFTER SALAM';

  @override
  String get adhkarSectionTasbih => 'TASBIH';

  @override
  String get adhkarSectionProtection => 'PROTECTION';

  @override
  String get adhkarAstaghfirullah =>
      'Astaghfirullah — I seek the forgiveness of Allah.';

  @override
  String get adhkarAllahummaAntas =>
      'O Allah, You are Peace and from You is peace. Blessed are You, O Owner of Majesty and Honour.';

  @override
  String get adhkarTasbihCounts =>
      'SubhanAllah 33× · Alhamdulillah 33× · Allahu Akbar 34×';

  @override
  String get adhkarAyatulKursi =>
      'Recite Ayat al-Kursi (2:255) after each prayer.';

  @override
  String get prayerJumuah => 'Jumu\'ah';

  @override
  String get waqtWitr => 'Witr';

  @override
  String get waqtColPreSunnah => 'Pre\nSunnah';

  @override
  String get waqtColPostSunnah => 'Post\nSunnah';

  @override
  String get waqtColTotal => 'Rakah\nTotal';
}
