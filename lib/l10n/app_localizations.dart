import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// Product name. Not translated.
  ///
  /// In en, this message translates to:
  /// **'LifeQue'**
  String get appName;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navTodoList.
  ///
  /// In en, this message translates to:
  /// **'To Do List'**
  String get navTodoList;

  /// No description provided for @navReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get navReminders;

  /// No description provided for @navBirthdays.
  ///
  /// In en, this message translates to:
  /// **'Birthdays'**
  String get navBirthdays;

  /// No description provided for @navExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expense Tracker'**
  String get navExpenses;

  /// No description provided for @navMedicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get navMedicines;

  /// No description provided for @navPrayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get navPrayerTimes;

  /// No description provided for @navStudyTimer.
  ///
  /// In en, this message translates to:
  /// **'Study Timer'**
  String get navStudyTimer;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @drawerTagline.
  ///
  /// In en, this message translates to:
  /// **'Your Personal Life Manager'**
  String get drawerTagline;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get commonTomorrow;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get commonNow;

  /// No description provided for @commonOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get commonOff;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsSectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsSectionApp;

  /// No description provided for @settingsSectionLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsSectionLegal;

  /// No description provided for @settingsNavigationOrder.
  ///
  /// In en, this message translates to:
  /// **'Navigation Order'**
  String get settingsNavigationOrder;

  /// No description provided for @settingsNavigationOrderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Home: {page}'**
  String settingsNavigationOrderSubtitle(String page);

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsCheckUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get settingsCheckUpdates;

  /// No description provided for @settingsCheckUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See if a newer version is available'**
  String get settingsCheckUpdatesSubtitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About LifeQue'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version info, developer & links'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get settingsTerms;

  /// No description provided for @settingsTermsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Usage terms of the app'**
  String get settingsTermsSubtitle;

  /// No description provided for @settingsMadeBy.
  ///
  /// In en, this message translates to:
  /// **'Made with ❤️ by Zaman Sheikh'**
  String get settingsMadeBy;

  /// No description provided for @navOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation Order'**
  String get navOrderTitle;

  /// No description provided for @navOrderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. First item = home page.'**
  String get navOrderSubtitle;

  /// No description provided for @navOrderHomePage.
  ///
  /// In en, this message translates to:
  /// **'Home page:  {page}'**
  String navOrderHomePage(String page);

  /// No description provided for @navOrderHomeBadge.
  ///
  /// In en, this message translates to:
  /// **'Home page'**
  String get navOrderHomeBadge;

  /// No description provided for @navOrderSave.
  ///
  /// In en, this message translates to:
  /// **'Save Order'**
  String get navOrderSave;

  /// No description provided for @navOrderSaved.
  ///
  /// In en, this message translates to:
  /// **'Navigation order saved'**
  String get navOrderSaved;

  /// No description provided for @languageComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{language} · coming soon'**
  String languageComingSoon(String language);

  /// No description provided for @languageSet.
  ///
  /// In en, this message translates to:
  /// **'Language set to {language}'**
  String languageSet(String language);

  /// No description provided for @languageSavedPending.
  ///
  /// In en, this message translates to:
  /// **'{language} is saved. The app stays in English until the translation ships.'**
  String languageSavedPending(String language);

  /// No description provided for @tasksTabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tasksTabActive;

  /// No description provided for @tasksTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tasksTabAll;

  /// No description provided for @tasksTabDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tasksTabDone;

  /// No description provided for @tasksGroupDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get tasksGroupDueToday;

  /// No description provided for @tasksGroupNext7Days.
  ///
  /// In en, this message translates to:
  /// **'Next 7 days'**
  String get tasksGroupNext7Days;

  /// No description provided for @tasksGroupLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get tasksGroupLater;

  /// No description provided for @tasksGroupOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get tasksGroupOverdue;

  /// No description provided for @tasksGroupInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get tasksGroupInProgress;

  /// No description provided for @tasksGroupNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get tasksGroupNotStarted;

  /// No description provided for @tasksGroupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tasksGroupCompleted;

  /// No description provided for @tasksEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get tasksEmptyTitle;

  /// No description provided for @tasksEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add something with a start and an end date, and it will show up here while it is running.'**
  String get tasksEmptyBody;

  /// No description provided for @tasksAllDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing on right now'**
  String get tasksAllDoneTitle;

  /// No description provided for @tasksAllDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Everything with a deadline is either finished or not started yet. Check All Tasks to see the rest.'**
  String get tasksAllDoneBody;

  /// No description provided for @tasksTapPlus.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add one'**
  String get tasksTapPlus;

  /// No description provided for @tasksNoCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet'**
  String get tasksNoCompletedTitle;

  /// No description provided for @tasksNoCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'Complete some tasks to see them here.'**
  String get tasksNoCompletedBody;

  /// No description provided for @tasksFirstRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to LifeQue'**
  String get tasksFirstRunTitle;

  /// No description provided for @tasksFirstRunBody.
  ///
  /// In en, this message translates to:
  /// **'Pick somewhere to start. Everything here is also in the menu.'**
  String get tasksFirstRunBody;

  /// No description provided for @tasksStartTask.
  ///
  /// In en, this message translates to:
  /// **'Add your first task'**
  String get tasksStartTask;

  /// No description provided for @tasksStartTaskSub.
  ///
  /// In en, this message translates to:
  /// **'Something with a deadline to work towards'**
  String get tasksStartTaskSub;

  /// No description provided for @tasksStartPrayer.
  ///
  /// In en, this message translates to:
  /// **'Set up prayer times'**
  String get tasksStartPrayer;

  /// No description provided for @tasksStartPrayerSub.
  ///
  /// In en, this message translates to:
  /// **'Waqt times, jamaat and a home-screen widget'**
  String get tasksStartPrayerSub;

  /// No description provided for @tasksStartBirthday.
  ///
  /// In en, this message translates to:
  /// **'Save a birthday'**
  String get tasksStartBirthday;

  /// No description provided for @tasksStartBirthdaySub.
  ///
  /// In en, this message translates to:
  /// **'Be reminded a day before, every year'**
  String get tasksStartBirthdaySub;

  /// No description provided for @tasksStartTodo.
  ///
  /// In en, this message translates to:
  /// **'Start a to-do list'**
  String get tasksStartTodo;

  /// No description provided for @tasksStartTodoSub.
  ///
  /// In en, this message translates to:
  /// **'The small things, ticked off as you go'**
  String get tasksStartTodoSub;

  /// No description provided for @tasksDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get tasksDeleteTitle;

  /// No description provided for @tasksDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'“{title}” will be removed.'**
  String tasksDeleteBody(String title);

  /// No description provided for @tasksMedicinesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get tasksMedicinesTooltip;

  /// No description provided for @taskCardDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskCardDone;

  /// No description provided for @taskCardStartsIn.
  ///
  /// In en, this message translates to:
  /// **'starts in {time}'**
  String taskCardStartsIn(String time);

  /// No description provided for @taskCardLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String taskCardLeft(String time);

  /// No description provided for @taskCardOver.
  ///
  /// In en, this message translates to:
  /// **'{time} over'**
  String taskCardOver(String time);

  /// No description provided for @taskUnitDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String taskUnitDays(int count);

  /// No description provided for @taskUnitHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String taskUnitHours(int count);

  /// No description provided for @taskUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String taskUnitMinutes(int count);

  /// No description provided for @taskUnitSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count}s'**
  String taskUnitSeconds(int count);

  /// No description provided for @taskFormNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get taskFormNewTitle;

  /// No description provided for @taskFormEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get taskFormEditTitle;

  /// No description provided for @taskFormTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What needs to be done?'**
  String get taskFormTitleHint;

  /// No description provided for @taskFormTitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Give it a name'**
  String get taskFormTitleEmpty;

  /// No description provided for @taskFormDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get taskFormDue;

  /// No description provided for @taskFormStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get taskFormStarts;

  /// No description provided for @taskFormPresetToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get taskFormPresetToday;

  /// No description provided for @taskFormPresetTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get taskFormPresetTomorrow;

  /// No description provided for @taskFormPresetWeek.
  ///
  /// In en, this message translates to:
  /// **'In a week'**
  String get taskFormPresetWeek;

  /// No description provided for @taskFormEndBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'The due time needs to be after the start.'**
  String get taskFormEndBeforeStart;

  /// No description provided for @taskFormRemindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get taskFormRemindMe;

  /// No description provided for @taskFormModeBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'Before it is due'**
  String get taskFormModeBeforeDue;

  /// No description provided for @taskFormModeAtTime.
  ///
  /// In en, this message translates to:
  /// **'At a set time'**
  String get taskFormModeAtTime;

  /// No description provided for @taskFormModeDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get taskFormModeDaily;

  /// No description provided for @taskFormAt.
  ///
  /// In en, this message translates to:
  /// **'At'**
  String get taskFormAt;

  /// No description provided for @taskFormPickTime.
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get taskFormPickTime;

  /// No description provided for @taskFormEveryDayAt.
  ///
  /// In en, this message translates to:
  /// **'{time} every day'**
  String taskFormEveryDayAt(String time);

  /// No description provided for @taskFormMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get taskFormMoreOptions;

  /// No description provided for @taskFormNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get taskFormNotesHint;

  /// No description provided for @taskFormPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep it in the notification shade'**
  String get taskFormPinTitle;

  /// No description provided for @taskFormPinSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An ongoing notification you can see at a glance'**
  String get taskFormPinSubtitle;

  /// No description provided for @taskFormCreate.
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get taskFormCreate;

  /// No description provided for @taskFormSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get taskFormSaveChanges;

  /// No description provided for @taskFormNeedReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Pick the time you want to be reminded.'**
  String get taskFormNeedReminderTime;

  /// No description provided for @taskFormNeedDailyTime.
  ///
  /// In en, this message translates to:
  /// **'Pick the time of day for the reminder.'**
  String get taskFormNeedDailyTime;

  /// No description provided for @beforeEnd10Minutes.
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get beforeEnd10Minutes;

  /// No description provided for @beforeEnd30Minutes.
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get beforeEnd30Minutes;

  /// No description provided for @beforeEnd1Hour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get beforeEnd1Hour;

  /// No description provided for @beforeEnd2Hours.
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get beforeEnd2Hours;

  /// No description provided for @beforeEnd1Day.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get beforeEnd1Day;

  /// No description provided for @pinBeforeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pin before the reminder'**
  String get pinBeforeTitle;

  /// No description provided for @pinBeforeBody.
  ///
  /// In en, this message translates to:
  /// **'Stays pinned until the reminder fires'**
  String get pinBeforeBody;

  /// No description provided for @pinAfterTitle.
  ///
  /// In en, this message translates to:
  /// **'Pin after the reminder'**
  String get pinAfterTitle;

  /// No description provided for @pinAfterBody.
  ///
  /// In en, this message translates to:
  /// **'Pins once the reminder has fired'**
  String get pinAfterBody;

  /// No description provided for @detailTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get detailTask;

  /// No description provided for @detailReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get detailReminder;

  /// No description provided for @detailBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get detailBirthday;

  /// No description provided for @detailGeneric.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailGeneric;

  /// No description provided for @detailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task not found'**
  String get detailNotFound;

  /// No description provided for @detailSectionTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'TIME LEFT'**
  String get detailSectionTimeLeft;

  /// No description provided for @detailSectionCountdown.
  ///
  /// In en, this message translates to:
  /// **'COUNTDOWN'**
  String get detailSectionCountdown;

  /// No description provided for @detailSectionTimeline.
  ///
  /// In en, this message translates to:
  /// **'TIMELINE'**
  String get detailSectionTimeline;

  /// No description provided for @detailSectionDetails.
  ///
  /// In en, this message translates to:
  /// **'DETAILS'**
  String get detailSectionDetails;

  /// No description provided for @detailSectionReminders.
  ///
  /// In en, this message translates to:
  /// **'REMINDERS'**
  String get detailSectionReminders;

  /// No description provided for @detailSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get detailSectionAbout;

  /// No description provided for @detailSectionWhen.
  ///
  /// In en, this message translates to:
  /// **'WHEN'**
  String get detailSectionWhen;

  /// No description provided for @detailSectionToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get detailSectionToday;

  /// No description provided for @detailUntilDeadline.
  ///
  /// In en, this message translates to:
  /// **'Until the deadline'**
  String get detailUntilDeadline;

  /// No description provided for @detailDeadlinePassed.
  ///
  /// In en, this message translates to:
  /// **'The deadline has passed'**
  String get detailDeadlinePassed;

  /// No description provided for @detailTimeElapsed.
  ///
  /// In en, this message translates to:
  /// **'Time elapsed'**
  String get detailTimeElapsed;

  /// No description provided for @detailDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'days left'**
  String get detailDaysLeft;

  /// No description provided for @detailDaysTotal.
  ///
  /// In en, this message translates to:
  /// **'days total'**
  String get detailDaysTotal;

  /// No description provided for @detailStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get detailStarted;

  /// No description provided for @detailDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get detailDue;

  /// No description provided for @detailWasDue.
  ///
  /// In en, this message translates to:
  /// **'Was due'**
  String get detailWasDue;

  /// No description provided for @detailReminderRow.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get detailReminderRow;

  /// No description provided for @detailPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get detailPinned;

  /// No description provided for @detailPinnedValue.
  ///
  /// In en, this message translates to:
  /// **'Kept in the shade'**
  String get detailPinnedValue;

  /// No description provided for @detailCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get detailCreated;

  /// No description provided for @detailLastEdited.
  ///
  /// In en, this message translates to:
  /// **'Last edited'**
  String get detailLastEdited;

  /// No description provided for @detailStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get detailStatusCompleted;

  /// No description provided for @detailStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get detailStatusOverdue;

  /// No description provided for @detailStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get detailStatusInProgress;

  /// No description provided for @detailStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get detailStatusNotStarted;

  /// No description provided for @detailReminderBefore.
  ///
  /// In en, this message translates to:
  /// **'{option} before'**
  String detailReminderBefore(String option);

  /// No description provided for @detailReminderDaily.
  ///
  /// In en, this message translates to:
  /// **'{time} daily'**
  String detailReminderDaily(String time);

  /// No description provided for @detailReminderAtTime.
  ///
  /// In en, this message translates to:
  /// **'At a set time'**
  String get detailReminderAtTime;

  /// No description provided for @detailReminderBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'Before it is due'**
  String get detailReminderBeforeDue;

  /// No description provided for @detailUntilItFires.
  ///
  /// In en, this message translates to:
  /// **'Until it goes off'**
  String get detailUntilItFires;

  /// No description provided for @detailAlreadyFired.
  ///
  /// In en, this message translates to:
  /// **'This reminder has already gone off'**
  String get detailAlreadyFired;

  /// No description provided for @detailStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get detailStatusDone;

  /// No description provided for @detailStatusPassed.
  ///
  /// In en, this message translates to:
  /// **'Already passed'**
  String get detailStatusPassed;

  /// No description provided for @detailStatusAnyMinute.
  ///
  /// In en, this message translates to:
  /// **'Any minute now'**
  String get detailStatusAnyMinute;

  /// No description provided for @detailStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get detailStatusWaiting;

  /// No description provided for @detailRowDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get detailRowDate;

  /// No description provided for @detailRowTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get detailRowTime;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @remindersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders set'**
  String get remindersEmptyTitle;

  /// No description provided for @remindersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Set a reminder for the things you would otherwise forget.'**
  String get remindersEmptyBody;

  /// No description provided for @remindersSetOne.
  ///
  /// In en, this message translates to:
  /// **'Set a reminder'**
  String get remindersSetOne;

  /// No description provided for @remindersNewOne.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get remindersNewOne;

  /// No description provided for @remindersNothingPending.
  ///
  /// In en, this message translates to:
  /// **'Nothing pending'**
  String get remindersNothingPending;

  /// No description provided for @remindersAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get remindersAllCaughtUp;

  /// No description provided for @remindersAllDoneBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing pending — everything here is done.'**
  String get remindersAllDoneBody;

  /// No description provided for @remindersNextUp.
  ///
  /// In en, this message translates to:
  /// **'Next reminder'**
  String get remindersNextUp;

  /// No description provided for @remindersGroupMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get remindersGroupMissed;

  /// No description provided for @remindersGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get remindersGroupToday;

  /// No description provided for @remindersGroupTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get remindersGroupTomorrow;

  /// No description provided for @remindersGroupLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get remindersGroupLater;

  /// No description provided for @remindersDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{count} done'**
  String remindersDoneCount(int count);

  /// No description provided for @remindersDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this reminder?'**
  String get remindersDeleteTitle;

  /// No description provided for @remindersKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get remindersKeepIt;

  /// No description provided for @birthdaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Birthdays'**
  String get birthdaysTitle;

  /// No description provided for @birthdaysEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No birthdays saved'**
  String get birthdaysEmptyTitle;

  /// No description provided for @birthdaysEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add the people you keep meaning to wish and this page will tell you who is next.'**
  String get birthdaysEmptyBody;

  /// No description provided for @birthdaysAddOne.
  ///
  /// In en, this message translates to:
  /// **'Add a birthday'**
  String get birthdaysAddOne;

  /// No description provided for @birthdaysAdd.
  ///
  /// In en, this message translates to:
  /// **'Add birthday'**
  String get birthdaysAdd;

  /// No description provided for @birthdaysEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get birthdaysEveryone;

  /// No description provided for @birthdaysMatching.
  ///
  /// In en, this message translates to:
  /// **'Matching “{query}”'**
  String birthdaysMatching(String query);

  /// No description provided for @birthdaysNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Nobody by that name'**
  String get birthdaysNoMatch;

  /// No description provided for @birthdaysSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name'**
  String get birthdaysSearchHint;

  /// No description provided for @birthdaysClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get birthdaysClearSearch;

  /// No description provided for @birthdaysNextUp.
  ///
  /// In en, this message translates to:
  /// **'Next up'**
  String get birthdaysNextUp;

  /// No description provided for @birthdaysToday.
  ///
  /// In en, this message translates to:
  /// **'Birthday today'**
  String get birthdaysToday;

  /// No description provided for @birthdaysInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String birthdaysInDays(int days);

  /// No description provided for @birthdaysRemindersOn.
  ///
  /// In en, this message translates to:
  /// **'Reminders on'**
  String get birthdaysRemindersOn;

  /// No description provided for @birthdaysRemindersOff.
  ///
  /// In en, this message translates to:
  /// **'Reminders off'**
  String get birthdaysRemindersOff;

  /// No description provided for @birthdaysDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this birthday?'**
  String get birthdaysDeleteTitle;

  /// No description provided for @birthdaysTurning.
  ///
  /// In en, this message translates to:
  /// **'turning {age}'**
  String birthdaysTurning(int age);

  /// No description provided for @birthdaysTodayLine.
  ///
  /// In en, this message translates to:
  /// **'It is today — they turn {age}.'**
  String birthdaysTodayLine(int age);

  /// No description provided for @birthdaysUntilBigDay.
  ///
  /// In en, this message translates to:
  /// **'Until the big day'**
  String get birthdaysUntilBigDay;

  /// No description provided for @birthdaysYearsOldNow.
  ///
  /// In en, this message translates to:
  /// **'years old now'**
  String get birthdaysYearsOldNow;

  /// No description provided for @birthdaysDaysToGo.
  ///
  /// In en, this message translates to:
  /// **'days to go'**
  String get birthdaysDaysToGo;

  /// No description provided for @birthdaysTheBigDay.
  ///
  /// In en, this message translates to:
  /// **'the big day'**
  String get birthdaysTheBigDay;

  /// No description provided for @birthdaysNoReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders set for this birthday.'**
  String get birthdaysNoReminders;

  /// No description provided for @birthdaysBorn.
  ///
  /// In en, this message translates to:
  /// **'Born'**
  String get birthdaysBorn;

  /// No description provided for @birthdaysNext.
  ///
  /// In en, this message translates to:
  /// **'Next birthday'**
  String get birthdaysNext;

  /// No description provided for @birthdaysSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get birthdaysSaved;

  /// No description provided for @birthdaysTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Birthday tomorrow'**
  String get birthdaysTomorrow;

  /// No description provided for @commonSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWrong;

  /// No description provided for @commonMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get commonMenu;

  /// No description provided for @commonDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get commonDetails;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @countdownDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get countdownDays;

  /// No description provided for @countdownHours.
  ///
  /// In en, this message translates to:
  /// **'hrs'**
  String get countdownHours;

  /// No description provided for @countdownMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get countdownMinutes;

  /// No description provided for @countdownSeconds.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get countdownSeconds;

  /// No description provided for @todosTitle.
  ///
  /// In en, this message translates to:
  /// **'To Do List'**
  String get todosTitle;

  /// No description provided for @todosTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get todosTabAll;

  /// No description provided for @todosTabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todosTabToday;

  /// No description provided for @todosTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get todosTabUpcoming;

  /// No description provided for @todosTabDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get todosTabDone;

  /// No description provided for @todosNew.
  ///
  /// In en, this message translates to:
  /// **'New to-do'**
  String get todosNew;

  /// No description provided for @todosGroupOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get todosGroupOverdue;

  /// No description provided for @todosGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todosGroupToday;

  /// No description provided for @todosGroupTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get todosGroupTomorrow;

  /// No description provided for @todosGroupThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get todosGroupThisWeek;

  /// No description provided for @todosGroupLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get todosGroupLater;

  /// No description provided for @todosGroupNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get todosGroupNoDate;

  /// No description provided for @todosGroupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get todosGroupCompleted;

  /// No description provided for @todosSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your to-dos'**
  String get todosSearchHint;

  /// No description provided for @todosClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get todosClearSearch;

  /// No description provided for @todosAnyCategory.
  ///
  /// In en, this message translates to:
  /// **'Any category'**
  String get todosAnyCategory;

  /// No description provided for @todosNothingMatched.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched'**
  String get todosNothingMatched;

  /// No description provided for @todosNothingMatchedBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different word, or clear the category filter.'**
  String get todosNothingMatchedBody;

  /// No description provided for @todosNothingFinished.
  ///
  /// In en, this message translates to:
  /// **'Nothing finished yet'**
  String get todosNothingFinished;

  /// No description provided for @todosNothingToday.
  ///
  /// In en, this message translates to:
  /// **'Nothing due today'**
  String get todosNothingToday;

  /// No description provided for @todosNothingAhead.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled ahead'**
  String get todosNothingAhead;

  /// No description provided for @todosAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get todosAllClear;

  /// No description provided for @todosNothingInView.
  ///
  /// In en, this message translates to:
  /// **'Nothing to do in this view.'**
  String get todosNothingInView;

  /// No description provided for @todosNothingLeft.
  ///
  /// In en, this message translates to:
  /// **'Nothing left — enjoy it'**
  String get todosNothingLeft;

  /// No description provided for @todosEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your list is empty'**
  String get todosEmptyTitle;

  /// No description provided for @todosEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add something you need to get done. Give it a due date and a reminder, and the app will nudge you when it matters.'**
  String get todosEmptyBody;

  /// No description provided for @todosAddFirst.
  ///
  /// In en, this message translates to:
  /// **'Add your first to-do'**
  String get todosAddFirst;

  /// No description provided for @todosDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this to-do?'**
  String get todosDeleteTitle;

  /// No description provided for @todosKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get todosKeepIt;

  /// No description provided for @todoDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'To-do'**
  String get todoDetailTitle;

  /// No description provided for @todoRowCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get todoRowCategory;

  /// No description provided for @todoRowPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get todoRowPriority;

  /// No description provided for @todoRowDue.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get todoRowDue;

  /// No description provided for @todoRowNoDue.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get todoRowNoDue;

  /// No description provided for @todoRowReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get todoRowReminder;

  /// No description provided for @todoRowCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get todoRowCreated;

  /// No description provided for @todoRowCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get todoRowCompleted;

  /// No description provided for @todoStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get todoStatusDone;

  /// No description provided for @todoStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get todoStatusOverdue;

  /// No description provided for @todoStatusDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get todoStatusDueToday;

  /// No description provided for @todoStatusDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get todoStatusDueTomorrow;

  /// No description provided for @todoStatusPriority.
  ///
  /// In en, this message translates to:
  /// **'{priority} priority'**
  String todoStatusPriority(String priority);

  /// No description provided for @todoAtTime.
  ///
  /// In en, this message translates to:
  /// **'{day} at {time}'**
  String todoAtTime(String day, String time);

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get priorityUrgent;

  /// No description provided for @categoryPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get categoryPersonal;

  /// No description provided for @categoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryWork;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categoryFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get categoryFinance;

  /// No description provided for @categoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryTravel;

  /// No description provided for @categoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get categoryHome;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @todosDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'“{title}” and its reminder will be removed. This can\'t be undone.'**
  String todosDeleteBody(String title);

  /// No description provided for @reminderAtTime.
  ///
  /// In en, this message translates to:
  /// **'{day}, {time}'**
  String reminderAtTime(String day, String time);

  /// No description provided for @birthdaysInDaysShort.
  ///
  /// In en, this message translates to:
  /// **'in {days} d'**
  String birthdaysInDaysShort(int days);

  /// No description provided for @birthdaysInMonthsShort.
  ///
  /// In en, this message translates to:
  /// **'in {months} mo'**
  String birthdaysInMonthsShort(int months);

  /// No description provided for @birthdayOptOneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day before (gift prep)'**
  String get birthdayOptOneDay;

  /// No description provided for @birthdayOptOneDayBody.
  ///
  /// In en, this message translates to:
  /// **'Get reminded to prepare gifts'**
  String get birthdayOptOneDayBody;

  /// No description provided for @birthdayOptTwoHours.
  ///
  /// In en, this message translates to:
  /// **'2 hours before'**
  String get birthdayOptTwoHours;

  /// No description provided for @birthdayOptTwoHoursBody.
  ///
  /// In en, this message translates to:
  /// **'Final preparation reminder'**
  String get birthdayOptTwoHoursBody;

  /// No description provided for @birthdayOptTenMinutes.
  ///
  /// In en, this message translates to:
  /// **'10 minutes before'**
  String get birthdayOptTenMinutes;

  /// No description provided for @birthdayOptTenMinutesBody.
  ///
  /// In en, this message translates to:
  /// **'Almost time to celebrate'**
  String get birthdayOptTenMinutesBody;

  /// No description provided for @birthdayOptExact.
  ///
  /// In en, this message translates to:
  /// **'At exactly 12:00 AM'**
  String get birthdayOptExact;

  /// No description provided for @birthdayOptExactBody.
  ///
  /// In en, this message translates to:
  /// **'Birthday celebration time'**
  String get birthdayOptExactBody;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @prayerTahajjud.
  ///
  /// In en, this message translates to:
  /// **'Tahajjud'**
  String get prayerTahajjud;

  /// No description provided for @prayerSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunrise;

  /// No description provided for @prayerNavPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get prayerNavPrayer;

  /// No description provided for @prayerNavCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get prayerNavCalendar;

  /// No description provided for @prayerNavTasbih.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get prayerNavTasbih;

  /// No description provided for @prayerNavLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get prayerNavLearn;

  /// No description provided for @prayerNavMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get prayerNavMore;

  /// No description provided for @salatTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Salat Times'**
  String get salatTimesTitle;

  /// No description provided for @salatSetAlarm.
  ///
  /// In en, this message translates to:
  /// **'Set Alarm'**
  String get salatSetAlarm;

  /// No description provided for @salatSetJamaat.
  ///
  /// In en, this message translates to:
  /// **'Set jamaat'**
  String get salatSetJamaat;

  /// No description provided for @salatJamaatAt.
  ///
  /// In en, this message translates to:
  /// **'Jamaat {time}'**
  String salatJamaatAt(String time);

  /// No description provided for @salatTill.
  ///
  /// In en, this message translates to:
  /// **'till {time}'**
  String salatTill(String time);

  /// No description provided for @salatNowBadge.
  ///
  /// In en, this message translates to:
  /// **'NOW'**
  String get salatNowBadge;

  /// No description provided for @gaugeWaqtEndsIn.
  ///
  /// In en, this message translates to:
  /// **'Waqt ends in'**
  String get gaugeWaqtEndsIn;

  /// No description provided for @gaugeStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in'**
  String get gaugeStartsIn;

  /// No description provided for @gaugeBeginsIn.
  ///
  /// In en, this message translates to:
  /// **'Begins in'**
  String get gaugeBeginsIn;

  /// No description provided for @gaugeStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at {time}'**
  String gaugeStartsAt(String time);

  /// No description provided for @gaugeBeginsAt.
  ///
  /// In en, this message translates to:
  /// **'Begins at {time}'**
  String gaugeBeginsAt(String time);

  /// No description provided for @gaugeEndsAtFajr.
  ///
  /// In en, this message translates to:
  /// **'Ends at Fajr, in'**
  String get gaugeEndsAtFajr;

  /// No description provided for @prohibitedCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Prohibited Times for Prayer'**
  String get prohibitedCardTitle;

  /// No description provided for @prohibitedSeeReference.
  ///
  /// In en, this message translates to:
  /// **'See Reference'**
  String get prohibitedSeeReference;

  /// No description provided for @prohibitedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Salat is prohibited during these times.'**
  String get prohibitedSubtitle;

  /// No description provided for @prohibitedActiveNow.
  ///
  /// In en, this message translates to:
  /// **'Active now · {left} left — salat is prohibited during these times.'**
  String prohibitedActiveNow(String left);

  /// No description provided for @prohibitedNext.
  ///
  /// In en, this message translates to:
  /// **'Salat is prohibited during these times · next: {window} {time}'**
  String prohibitedNext(String window, String time);

  /// No description provided for @prohibitedNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Salat is prohibited right now'**
  String get prohibitedNowTitle;

  /// No description provided for @prohibitedNowBody.
  ///
  /// In en, this message translates to:
  /// **'{window} · ends at {time} (in {left})'**
  String prohibitedNowBody(String window, String time, String left);

  /// No description provided for @prohibitedDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get prohibitedDismiss;

  /// No description provided for @prohibitedSunrise.
  ///
  /// In en, this message translates to:
  /// **'While the sun rises'**
  String get prohibitedSunrise;

  /// No description provided for @prohibitedZawal.
  ///
  /// In en, this message translates to:
  /// **'While the sun is at its peak'**
  String get prohibitedZawal;

  /// No description provided for @prohibitedSunset.
  ///
  /// In en, this message translates to:
  /// **'While the sun sets'**
  String get prohibitedSunset;

  /// No description provided for @prohibitedMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get prohibitedMorning;

  /// No description provided for @prohibitedNoon.
  ///
  /// In en, this message translates to:
  /// **'Noon'**
  String get prohibitedNoon;

  /// No description provided for @prohibitedEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get prohibitedEvening;

  /// No description provided for @restrictedTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Restricted Times'**
  String get restrictedTimesTitle;

  /// No description provided for @nafalTitle.
  ///
  /// In en, this message translates to:
  /// **'Nafal Prayer Time'**
  String get nafalTitle;

  /// No description provided for @nafalIshraq.
  ///
  /// In en, this message translates to:
  /// **'Ishraq / Duha'**
  String get nafalIshraq;

  /// No description provided for @nafalZawalStart.
  ///
  /// In en, this message translates to:
  /// **'Zawal Start'**
  String get nafalZawalStart;

  /// No description provided for @nafalAwabin.
  ///
  /// In en, this message translates to:
  /// **'Awabin'**
  String get nafalAwabin;

  /// No description provided for @nafalAfterMaghrib.
  ///
  /// In en, this message translates to:
  /// **'After Maghrib – {time}'**
  String nafalAfterMaghrib(String time);

  /// No description provided for @nafalAfterIsha.
  ///
  /// In en, this message translates to:
  /// **'After Isha – {time}'**
  String nafalAfterIsha(String time);

  /// No description provided for @nafalLastThird.
  ///
  /// In en, this message translates to:
  /// **'Last ⅓ of night begins: {time}'**
  String nafalLastThird(String time);

  /// No description provided for @progressAllFive.
  ///
  /// In en, this message translates to:
  /// **'All five prayed today'**
  String get progressAllFive;

  /// No description provided for @progressLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'Prayers logged today'**
  String get progressLoggedToday;

  /// No description provided for @progressLogged.
  ///
  /// In en, this message translates to:
  /// **'Prayers logged'**
  String get progressLogged;

  /// No description provided for @progressViewStats.
  ///
  /// In en, this message translates to:
  /// **'View stats'**
  String get progressViewStats;

  /// No description provided for @progressNoStreak.
  ///
  /// In en, this message translates to:
  /// **'No streak yet'**
  String get progressNoStreak;

  /// No description provided for @progressStreak.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String progressStreak(int days);

  /// No description provided for @prayerBackToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to today'**
  String get prayerBackToToday;

  /// No description provided for @prayerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer settings'**
  String get prayerSettingsTitle;

  /// No description provided for @prayerSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How prayer times are calculated'**
  String get prayerSettingsSubtitle;

  /// No description provided for @prayerSectionMethod.
  ///
  /// In en, this message translates to:
  /// **'CALCULATION METHOD'**
  String get prayerSectionMethod;

  /// No description provided for @prayerSectionMadhab.
  ///
  /// In en, this message translates to:
  /// **'MADHAB — FOR ASR'**
  String get prayerSectionMadhab;

  /// No description provided for @prayerSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'LOCATION'**
  String get prayerSectionLocation;

  /// No description provided for @prayerSetLocationManually.
  ///
  /// In en, this message translates to:
  /// **'Set location manually'**
  String get prayerSetLocationManually;

  /// No description provided for @prayerSetLocation.
  ///
  /// In en, this message translates to:
  /// **'Set Location'**
  String get prayerSetLocation;

  /// No description provided for @prayerLocationName.
  ///
  /// In en, this message translates to:
  /// **'Location Name'**
  String get prayerLocationName;

  /// No description provided for @prayerLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get prayerLatitude;

  /// No description provided for @prayerLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get prayerLongitude;

  /// No description provided for @prayerCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get prayerCurrentLocation;

  /// No description provided for @prayerDefaultLocationNote.
  ///
  /// In en, this message translates to:
  /// **'Using default location (Dhaka). Tap the location pin to set yours.'**
  String get prayerDefaultLocationNote;

  /// No description provided for @prayerUnableToCompute.
  ///
  /// In en, this message translates to:
  /// **'Unable to compute prayer times'**
  String get prayerUnableToCompute;

  /// No description provided for @prayerAlarmSetFor.
  ///
  /// In en, this message translates to:
  /// **'{prayer} alarm set for {time} {day}'**
  String prayerAlarmSetFor(String prayer, String time, String day);

  /// No description provided for @prayerAlarmSet.
  ///
  /// In en, this message translates to:
  /// **'{prayer} alarm set'**
  String prayerAlarmSet(String prayer);

  /// No description provided for @prayerAlarmOff.
  ///
  /// In en, this message translates to:
  /// **'{prayer} alarm turned off'**
  String prayerAlarmOff(String prayer);

  /// No description provided for @prayerDayToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get prayerDayToday;

  /// No description provided for @prayerDayTomorrow.
  ///
  /// In en, this message translates to:
  /// **'tomorrow'**
  String get prayerDayTomorrow;

  /// No description provided for @madhabHanafi.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get madhabHanafi;

  /// No description provided for @madhabHanafiNote.
  ///
  /// In en, this message translates to:
  /// **'Later Asr'**
  String get madhabHanafiNote;

  /// No description provided for @madhabShafi.
  ///
  /// In en, this message translates to:
  /// **'Shafi'**
  String get madhabShafi;

  /// No description provided for @madhabShafiNote.
  ///
  /// In en, this message translates to:
  /// **'Earlier Asr'**
  String get madhabShafiNote;

  /// No description provided for @ramadanMode.
  ///
  /// In en, this message translates to:
  /// **'RAMADAN MODE'**
  String get ramadanMode;

  /// No description provided for @ramadanDay.
  ///
  /// In en, this message translates to:
  /// **'RAMADAN · DAY {day}'**
  String ramadanDay(int day);

  /// No description provided for @prohibitedAllPassed.
  ///
  /// In en, this message translates to:
  /// **'Salat is prohibited during these times · all have passed today.'**
  String get prohibitedAllPassed;

  /// No description provided for @reminderFormNew.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get reminderFormNew;

  /// No description provided for @reminderFormEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get reminderFormEdit;

  /// No description provided for @reminderFormTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Remind me to…'**
  String get reminderFormTitleLabel;

  /// No description provided for @reminderFormTitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Say what to remind you about'**
  String get reminderFormTitleEmpty;

  /// No description provided for @reminderFormNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get reminderFormNote;

  /// No description provided for @reminderFormNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Anything worth remembering'**
  String get reminderFormNoteHint;

  /// No description provided for @reminderFormInAnHour.
  ///
  /// In en, this message translates to:
  /// **'In an hour'**
  String get reminderFormInAnHour;

  /// No description provided for @reminderFormThisEvening.
  ///
  /// In en, this message translates to:
  /// **'This evening'**
  String get reminderFormThisEvening;

  /// No description provided for @reminderFormTomorrow9.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow 9am'**
  String get reminderFormTomorrow9;

  /// No description provided for @reminderFormPick.
  ///
  /// In en, this message translates to:
  /// **'Pick…'**
  String get reminderFormPick;

  /// No description provided for @reminderFormKeepShade.
  ///
  /// In en, this message translates to:
  /// **'Keep it in the shade'**
  String get reminderFormKeepShade;

  /// No description provided for @reminderFormOnDate.
  ///
  /// In en, this message translates to:
  /// **'Remind me on'**
  String get reminderFormOnDate;

  /// No description provided for @reminderFormAtTime.
  ///
  /// In en, this message translates to:
  /// **'Remind me at'**
  String get reminderFormAtTime;

  /// No description provided for @reminderFormFutureTime.
  ///
  /// In en, this message translates to:
  /// **'Pick a time in the future'**
  String get reminderFormFutureTime;

  /// No description provided for @birthdayFormNew.
  ///
  /// In en, this message translates to:
  /// **'New birthday'**
  String get birthdayFormNew;

  /// No description provided for @birthdayFormEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit birthday'**
  String get birthdayFormEdit;

  /// No description provided for @birthdayFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Whose birthday?'**
  String get birthdayFormNameLabel;

  /// No description provided for @birthdayFormNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add their name'**
  String get birthdayFormNameEmpty;

  /// No description provided for @birthdayFormNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Gift ideas, how you know them…'**
  String get birthdayFormNoteHint;

  /// No description provided for @birthdayFormDob.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get birthdayFormDob;

  /// No description provided for @birthdayFormTurning.
  ///
  /// In en, this message translates to:
  /// **'Turning {age} on their next birthday'**
  String birthdayFormTurning(int age);

  /// No description provided for @birthdayFormSetYear.
  ///
  /// In en, this message translates to:
  /// **'Set the year of birth to show their age'**
  String get birthdayFormSetYear;

  /// No description provided for @birthdayFormNoReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders — the date is just saved here for you to look up.'**
  String get birthdayFormNoReminders;

  /// No description provided for @birthdayFormDayBefore.
  ///
  /// In en, this message translates to:
  /// **'The day before'**
  String get birthdayFormDayBefore;

  /// No description provided for @birthdayFormTwoHours.
  ///
  /// In en, this message translates to:
  /// **'Two hours before'**
  String get birthdayFormTwoHours;

  /// No description provided for @birthdayFormTenMinutes.
  ///
  /// In en, this message translates to:
  /// **'Ten minutes before'**
  String get birthdayFormTenMinutes;

  /// No description provided for @birthdayFormMidnight.
  ///
  /// In en, this message translates to:
  /// **'On the day, at midnight'**
  String get birthdayFormMidnight;

  /// No description provided for @todoFormNew.
  ///
  /// In en, this message translates to:
  /// **'New to-do'**
  String get todoFormNew;

  /// No description provided for @todoFormEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit to-do'**
  String get todoFormEdit;

  /// No description provided for @todoFormTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'What needs doing?'**
  String get todoFormTitleLabel;

  /// No description provided for @todoFormTitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Give it a name'**
  String get todoFormTitleEmpty;

  /// No description provided for @todoFormNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Any detail worth remembering'**
  String get todoFormNoteHint;

  /// No description provided for @todoFormPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get todoFormPriority;

  /// No description provided for @todoFormCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get todoFormCategory;

  /// No description provided for @todoFormNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get todoFormNoDate;

  /// No description provided for @todoFormDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get todoFormDueDate;

  /// No description provided for @todoFormDueTime.
  ///
  /// In en, this message translates to:
  /// **'Due time'**
  String get todoFormDueTime;

  /// No description provided for @todoFormAtDueTime.
  ///
  /// In en, this message translates to:
  /// **'At due time'**
  String get todoFormAtDueTime;

  /// No description provided for @todoFormDayBefore.
  ///
  /// In en, this message translates to:
  /// **'A day before'**
  String get todoFormDayBefore;

  /// No description provided for @todoFormPassed.
  ///
  /// In en, this message translates to:
  /// **'That time has already passed — pick a later one or the reminder will not fire.'**
  String get todoFormPassed;

  /// No description provided for @todoFormNotificationOn.
  ///
  /// In en, this message translates to:
  /// **'Notification on {when}'**
  String todoFormNotificationOn(String when);

  /// No description provided for @medTitle.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medTitle;

  /// No description provided for @medAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Medicine'**
  String get medAdd;

  /// No description provided for @medEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Medicine'**
  String get medEdit;

  /// No description provided for @medDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medDetailTitle;

  /// No description provided for @medEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No medications yet'**
  String get medEmptyTitle;

  /// No description provided for @medViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All Medicines'**
  String get medViewAll;

  /// No description provided for @medQuickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get medQuickAdd;

  /// No description provided for @medRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get medRefresh;

  /// No description provided for @medNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Medicine Name'**
  String get medNameLabel;

  /// No description provided for @medNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please enter medicine name'**
  String get medNameEmpty;

  /// No description provided for @medDosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get medDosage;

  /// No description provided for @medDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration (days)'**
  String get medDuration;

  /// No description provided for @medStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get medStartDate;

  /// No description provided for @medTimesPerDay.
  ///
  /// In en, this message translates to:
  /// **'Times per day:'**
  String get medTimesPerDay;

  /// No description provided for @medNotificationTimes.
  ///
  /// In en, this message translates to:
  /// **'Notification Times:'**
  String get medNotificationTimes;

  /// No description provided for @medMealTiming.
  ///
  /// In en, this message translates to:
  /// **'Meal Timing'**
  String get medMealTiming;

  /// No description provided for @medBeforeMeal.
  ///
  /// In en, this message translates to:
  /// **'Before Meal'**
  String get medBeforeMeal;

  /// No description provided for @medAfterMeal.
  ///
  /// In en, this message translates to:
  /// **'After Meal'**
  String get medAfterMeal;

  /// No description provided for @medWithMeal.
  ///
  /// In en, this message translates to:
  /// **'With Meal'**
  String get medWithMeal;

  /// No description provided for @medEmptyStomach.
  ///
  /// In en, this message translates to:
  /// **'Empty Stomach'**
  String get medEmptyStomach;

  /// No description provided for @medAnytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get medAnytime;

  /// No description provided for @medTablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get medTablet;

  /// No description provided for @medCapsule.
  ///
  /// In en, this message translates to:
  /// **'Capsule'**
  String get medCapsule;

  /// No description provided for @medInjection.
  ///
  /// In en, this message translates to:
  /// **'Injection'**
  String get medInjection;

  /// No description provided for @medDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get medDoctor;

  /// No description provided for @medDoctorName.
  ///
  /// In en, this message translates to:
  /// **'Doctor Name'**
  String get medDoctorName;

  /// No description provided for @medDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get medDescription;

  /// No description provided for @medAdditionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Info (Optional)'**
  String get medAdditionalInfo;

  /// No description provided for @medDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Medicine'**
  String get medDeleteTitle;

  /// No description provided for @medDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this medicine and its doses?'**
  String get medDeleteBody;

  /// No description provided for @medSectionCourse.
  ///
  /// In en, this message translates to:
  /// **'THIS COURSE'**
  String get medSectionCourse;

  /// No description provided for @medSectionDoseHistory.
  ///
  /// In en, this message translates to:
  /// **'DOSE HISTORY'**
  String get medSectionDoseHistory;

  /// No description provided for @medDosesTaken.
  ///
  /// In en, this message translates to:
  /// **'Doses taken'**
  String get medDosesTaken;

  /// No description provided for @medDayOf.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String medDayOf(int day, int total);

  /// No description provided for @medNoDoses.
  ///
  /// In en, this message translates to:
  /// **'No doses recorded yet.'**
  String get medNoDoses;

  /// No description provided for @medStatusOnCourse.
  ///
  /// In en, this message translates to:
  /// **'On this course'**
  String get medStatusOnCourse;

  /// No description provided for @medStatusFinished.
  ///
  /// In en, this message translates to:
  /// **'Course finished'**
  String get medStatusFinished;

  /// No description provided for @medStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get medStatusNotStarted;

  /// No description provided for @medDoseTaken.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get medDoseTaken;

  /// No description provided for @medDoseToCome.
  ///
  /// In en, this message translates to:
  /// **'To come'**
  String get medDoseToCome;

  /// No description provided for @medDoseSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get medDoseSkipped;

  /// No description provided for @medDoseMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get medDoseMissed;

  /// No description provided for @medType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get medType;

  /// No description provided for @medTiming.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get medTiming;

  /// No description provided for @medStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get medStarted;

  /// No description provided for @medEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get medEnds;

  /// No description provided for @medNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get medNotes;

  /// No description provided for @medTimesADay.
  ///
  /// In en, this message translates to:
  /// **'{count}× a day'**
  String medTimesADay(int count);

  /// No description provided for @medNotFound.
  ///
  /// In en, this message translates to:
  /// **'Medicine not found'**
  String get medNotFound;

  /// No description provided for @medUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get medUnexpectedError;

  /// No description provided for @studyTitle.
  ///
  /// In en, this message translates to:
  /// **'Study Timer'**
  String get studyTitle;

  /// No description provided for @studySettings.
  ///
  /// In en, this message translates to:
  /// **'Timer settings'**
  String get studySettings;

  /// No description provided for @studyYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get studyYourPlan;

  /// No description provided for @studyReady.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are'**
  String get studyReady;

  /// No description provided for @studyStart.
  ///
  /// In en, this message translates to:
  /// **'Start focusing'**
  String get studyStart;

  /// No description provided for @studyResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get studyResume;

  /// No description provided for @studyKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get studyKeepGoing;

  /// No description provided for @studyPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get studyPaused;

  /// No description provided for @studyFocused.
  ///
  /// In en, this message translates to:
  /// **'Focused'**
  String get studyFocused;

  /// No description provided for @studyFocusBlock.
  ///
  /// In en, this message translates to:
  /// **'Focus block'**
  String get studyFocusBlock;

  /// No description provided for @studyShortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short break'**
  String get studyShortBreak;

  /// No description provided for @studyLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Long break'**
  String get studyLongBreak;

  /// No description provided for @studyBlocks.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get studyBlocks;

  /// No description provided for @studyBlocksBeforeLong.
  ///
  /// In en, this message translates to:
  /// **'Blocks before a long break'**
  String get studyBlocksBeforeLong;

  /// No description provided for @studyAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get studyAdjust;

  /// No description provided for @studyEndSession.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get studyEndSession;

  /// No description provided for @studyEndSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'End this session?'**
  String get studyEndSessionTitle;

  /// No description provided for @studyAlarmNote.
  ///
  /// In en, this message translates to:
  /// **'Alarms are set for every block and break, so you can put the phone down.'**
  String get studyAlarmNote;

  /// No description provided for @studyRunningNote.
  ///
  /// In en, this message translates to:
  /// **'A session is running — these take effect the next time you start.'**
  String get studyRunningNote;

  /// No description provided for @studyThenNext.
  ///
  /// In en, this message translates to:
  /// **'Then {phase}'**
  String studyThenNext(String phase);

  /// No description provided for @studyMinutesToStart.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min to start'**
  String studyMinutesToStart(int minutes);

  /// No description provided for @expTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Tracker'**
  String get expTitle;

  /// No description provided for @expLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your expenses…'**
  String get expLoading;

  /// No description provided for @expShoppingLists.
  ///
  /// In en, this message translates to:
  /// **'Shopping lists'**
  String get expShoppingLists;

  /// No description provided for @expNewList.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get expNewList;

  /// No description provided for @expNewShoppingList.
  ///
  /// In en, this message translates to:
  /// **'New shopping list'**
  String get expNewShoppingList;

  /// No description provided for @expEditList.
  ///
  /// In en, this message translates to:
  /// **'Edit list'**
  String get expEditList;

  /// No description provided for @expCreateList.
  ///
  /// In en, this message translates to:
  /// **'Create a list'**
  String get expCreateList;

  /// No description provided for @expStartFirstList.
  ///
  /// In en, this message translates to:
  /// **'Start your first list'**
  String get expStartFirstList;

  /// No description provided for @expListName.
  ///
  /// In en, this message translates to:
  /// **'List name'**
  String get expListName;

  /// No description provided for @expGiveListName.
  ///
  /// In en, this message translates to:
  /// **'Give this list a name'**
  String get expGiveListName;

  /// No description provided for @expListTotal.
  ///
  /// In en, this message translates to:
  /// **'List total'**
  String get expListTotal;

  /// No description provided for @expListSaved.
  ///
  /// In en, this message translates to:
  /// **'List saved'**
  String get expListSaved;

  /// No description provided for @expListUpdated.
  ///
  /// In en, this message translates to:
  /// **'List updated'**
  String get expListUpdated;

  /// No description provided for @expDeleteListTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this list?'**
  String get expDeleteListTitle;

  /// No description provided for @expAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get expAddItem;

  /// No description provided for @expItemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get expItemName;

  /// No description provided for @expUntitledItem.
  ///
  /// In en, this message translates to:
  /// **'Untitled item'**
  String get expUntitledItem;

  /// No description provided for @expEditingItem.
  ///
  /// In en, this message translates to:
  /// **'Editing item'**
  String get expEditingItem;

  /// No description provided for @expRemoveItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get expRemoveItem;

  /// No description provided for @expNeedOneItem.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item before saving'**
  String get expNeedOneItem;

  /// No description provided for @expItemHelp.
  ///
  /// In en, this message translates to:
  /// **'Type a name, add a price if you know it, press +'**
  String get expItemHelp;

  /// No description provided for @expBought.
  ///
  /// In en, this message translates to:
  /// **'Already bought'**
  String get expBought;

  /// No description provided for @expNotBought.
  ///
  /// In en, this message translates to:
  /// **'Not bought'**
  String get expNotBought;

  /// No description provided for @expAllBought.
  ///
  /// In en, this message translates to:
  /// **'All bought'**
  String get expAllBought;

  /// No description provided for @expTapWhenBought.
  ///
  /// In en, this message translates to:
  /// **'Tap when bought'**
  String get expTapWhenBought;

  /// No description provided for @expPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get expPlanned;

  /// No description provided for @expPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get expPurchased;

  /// No description provided for @expSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search lists and items…'**
  String get expSearchHint;

  /// No description provided for @expSearchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get expSearchResults;

  /// No description provided for @expNothingMatched.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched'**
  String get expNothingMatched;

  /// No description provided for @expPickMonth.
  ///
  /// In en, this message translates to:
  /// **'Pick a month'**
  String get expPickMonth;

  /// No description provided for @expPreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get expPreviousMonth;

  /// No description provided for @expNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get expNextMonth;

  /// No description provided for @expBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get expBudget;

  /// No description provided for @expMonthlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Monthly Budget'**
  String get expMonthlyBudget;

  /// No description provided for @expSetBudget.
  ///
  /// In en, this message translates to:
  /// **'Set Budget'**
  String get expSetBudget;

  /// No description provided for @expEditBudget.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get expEditBudget;

  /// No description provided for @expUpdateBudget.
  ///
  /// In en, this message translates to:
  /// **'Update Budget'**
  String get expUpdateBudget;

  /// No description provided for @expNoBudgetSet.
  ///
  /// In en, this message translates to:
  /// **'No budget set'**
  String get expNoBudgetSet;

  /// No description provided for @expNoBudgetThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No budget set for this month'**
  String get expNoBudgetThisMonth;

  /// No description provided for @expBudgetAmount.
  ///
  /// In en, this message translates to:
  /// **'Budget Amount'**
  String get expBudgetAmount;

  /// No description provided for @expEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get expEnterAmount;

  /// No description provided for @expInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get expInvalidAmount;

  /// No description provided for @expNeedAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a budget amount'**
  String get expNeedAmount;

  /// No description provided for @expNeedValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount greater than 0'**
  String get expNeedValidAmount;

  /// No description provided for @expCategoryBudgets.
  ///
  /// In en, this message translates to:
  /// **'Category Budgets'**
  String get expCategoryBudgets;

  /// No description provided for @expSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get expSelectCategory;

  /// No description provided for @expCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get expCategoryName;

  /// No description provided for @expAddCustomCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Category'**
  String get expAddCustomCategory;

  /// No description provided for @expCreateCustomCategory.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Category'**
  String get expCreateCustomCategory;

  /// No description provided for @expDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get expDeleteCategory;

  /// No description provided for @expCategoryExists.
  ///
  /// In en, this message translates to:
  /// **'Category name already exists'**
  String get expCategoryExists;

  /// No description provided for @expCategoryOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Category budgets exceed monthly budget — please reduce.'**
  String get expCategoryOverBudget;

  /// No description provided for @expUnallocated.
  ///
  /// In en, this message translates to:
  /// **'Unallocated'**
  String get expUnallocated;

  /// No description provided for @expOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get expOnTrack;

  /// No description provided for @expGoodProgress.
  ///
  /// In en, this message translates to:
  /// **'Good progress'**
  String get expGoodProgress;

  /// No description provided for @expHalfway.
  ///
  /// In en, this message translates to:
  /// **'Halfway through'**
  String get expHalfway;

  /// No description provided for @expSpendingCautiously.
  ///
  /// In en, this message translates to:
  /// **'Spending cautiously'**
  String get expSpendingCautiously;

  /// No description provided for @expAlmostAtLimit.
  ///
  /// In en, this message translates to:
  /// **'Almost at limit'**
  String get expAlmostAtLimit;

  /// No description provided for @expOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget!'**
  String get expOverBudget;

  /// No description provided for @expBudgetExceeded.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded'**
  String get expBudgetExceeded;

  /// No description provided for @expBudgetMet.
  ///
  /// In en, this message translates to:
  /// **'Budget exactly met! Great job!'**
  String get expBudgetMet;

  /// No description provided for @expNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get expNoteOptional;

  /// No description provided for @expRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get expRequired;

  /// No description provided for @expInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get expInvalid;

  /// No description provided for @expCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get expCreate;

  /// No description provided for @expUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get expUpdate;

  /// No description provided for @expEndSession.
  ///
  /// In en, this message translates to:
  /// **'End session'**
  String get expEndSession;

  /// No description provided for @medEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first medication to start tracking your daily doses'**
  String get medEmptyBody;

  /// No description provided for @remindersEmptyBodyLong.
  ///
  /// In en, this message translates to:
  /// **'Set one for anything you\'d rather not keep in your head — a call to make, a bill to pay, a bin to put out.'**
  String get remindersEmptyBodyLong;

  /// No description provided for @studyEndSessionBody.
  ///
  /// In en, this message translates to:
  /// **'The countdown stops and every alarm for the rest of the session is cancelled.'**
  String get studyEndSessionBody;

  /// No description provided for @expListsHelp.
  ///
  /// In en, this message translates to:
  /// **'Write down what you plan to buy with a price for each item, then tick things off as you buy them.'**
  String get expListsHelp;

  /// No description provided for @widgetLocationNote.
  ///
  /// In en, this message translates to:
  /// **'Set your location first and these will fill in with your own prayer times.'**
  String get widgetLocationNote;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'A beautiful and intuitive app to manage your daily tasks and medicine reminders.'**
  String get aboutTagline;

  /// No description provided for @aboutDevelopedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed by'**
  String get aboutDevelopedBy;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @tasbihTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbihTitle;

  /// No description provided for @qiblaTitle.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qiblaTitle;

  /// No description provided for @tasbihRound.
  ///
  /// In en, this message translates to:
  /// **'Round {number}'**
  String tasbihRound(int number);

  /// No description provided for @tasbihTapToBegin.
  ///
  /// In en, this message translates to:
  /// **'tap to begin'**
  String get tasbihTapToBegin;

  /// No description provided for @tasbihCounted.
  ///
  /// In en, this message translates to:
  /// **'{count} counted'**
  String tasbihCounted(int count);

  /// No description provided for @tasbihReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get tasbihReset;

  /// No description provided for @tasbihSubhanAllah.
  ///
  /// In en, this message translates to:
  /// **'SubhanAllah'**
  String get tasbihSubhanAllah;

  /// No description provided for @tasbihAlhamdulillah.
  ///
  /// In en, this message translates to:
  /// **'Alhamdulillah'**
  String get tasbihAlhamdulillah;

  /// No description provided for @tasbihAllahuAkbar.
  ///
  /// In en, this message translates to:
  /// **'Allahu Akbar'**
  String get tasbihAllahuAkbar;

  /// No description provided for @tasbihSubhanAllahMeaning.
  ///
  /// In en, this message translates to:
  /// **'SubhanAllah — Glory be to Allah'**
  String get tasbihSubhanAllahMeaning;

  /// No description provided for @tasbihAlhamdulillahMeaning.
  ///
  /// In en, this message translates to:
  /// **'Alhamdulillah — All praise is for Allah'**
  String get tasbihAlhamdulillahMeaning;

  /// No description provided for @tasbihAllahuAkbarMeaning.
  ///
  /// In en, this message translates to:
  /// **'Allahu Akbar — Allah is the Greatest'**
  String get tasbihAllahuAkbarMeaning;

  /// No description provided for @tasbihResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Start this round again?'**
  String get tasbihResetTitle;

  /// No description provided for @tasbihResetBody.
  ///
  /// In en, this message translates to:
  /// **'This clears round {round} and starts again from SubhanAllah.'**
  String tasbihResetBody(int round);

  /// No description provided for @tasbihTapToCount.
  ///
  /// In en, this message translates to:
  /// **'tap to count'**
  String get tasbihTapToCount;

  /// No description provided for @tasbihTimes.
  ///
  /// In en, this message translates to:
  /// **'{count}×'**
  String tasbihTimes(int count);

  /// No description provided for @qiblaCompass.
  ///
  /// In en, this message translates to:
  /// **'Qibla Compass'**
  String get qiblaCompass;

  /// No description provided for @qiblaFromNorth.
  ///
  /// In en, this message translates to:
  /// **'from North · {km} km to Makkah'**
  String qiblaFromNorth(String km);

  /// No description provided for @qiblaNoCompass.
  ///
  /// In en, this message translates to:
  /// **'No compass on this device — bearing shown above'**
  String get qiblaNoCompass;

  /// No description provided for @restrictedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Times when Salah is discouraged'**
  String get restrictedSubtitle;

  /// No description provided for @restrictedActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Avoid voluntary prayer right now'**
  String get restrictedActiveSubtitle;

  /// No description provided for @restrictedTodayWindows.
  ///
  /// In en, this message translates to:
  /// **'Today\'s restricted windows'**
  String get restrictedTodayWindows;

  /// No description provided for @restrictedActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get restrictedActive;

  /// No description provided for @restrictedPassed.
  ///
  /// In en, this message translates to:
  /// **'PASSED'**
  String get restrictedPassed;

  /// No description provided for @restrictedUpcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get restrictedUpcoming;

  /// No description provided for @restrictedWindowSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise period'**
  String get restrictedWindowSunrise;

  /// No description provided for @restrictedWindowZawal.
  ///
  /// In en, this message translates to:
  /// **'Zawal (midday)'**
  String get restrictedWindowZawal;

  /// No description provided for @restrictedWindowSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset period'**
  String get restrictedWindowSunset;

  /// No description provided for @restrictedAboutMinutes.
  ///
  /// In en, this message translates to:
  /// **'about {minutes} minutes'**
  String restrictedAboutMinutes(int minutes);

  /// No description provided for @restrictedWhy.
  ///
  /// In en, this message translates to:
  /// **'Why these times?'**
  String get restrictedWhy;

  /// No description provided for @restrictedWhyBody.
  ///
  /// In en, this message translates to:
  /// **'Three short windows each day — sunrise, midday (Zawal) and sunset — are makruh for voluntary prayer. Their exact lengths are listed above. Only a missed Asr may still be offered during the sunset window, since delaying it further would lose the Asr altogether.'**
  String get restrictedWhyBody;

  /// No description provided for @restrictedEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence'**
  String get restrictedEvidence;

  /// No description provided for @restrictedHadith1.
  ///
  /// In en, this message translates to:
  /// **'Uqbah ibn Amir (may Allah be pleased with him) said: there were three times at which the Messenger of Allah ﷺ forbade us to pray, or to bury our dead — when the sun begins to rise until it has fully risen; when it stands at its zenith at midday until it passes the meridian; and when the sun begins to set until it has set.'**
  String get restrictedHadith1;

  /// No description provided for @restrictedHadith1Ref.
  ///
  /// In en, this message translates to:
  /// **'Sahih Muslim 831'**
  String get restrictedHadith1Ref;

  /// No description provided for @restrictedHadith2.
  ///
  /// In en, this message translates to:
  /// **'Whoever catches one rak\'ah of Asr before the sun sets has caught the Asr.'**
  String get restrictedHadith2;

  /// No description provided for @restrictedHadith2Ref.
  ///
  /// In en, this message translates to:
  /// **'Sahih al-Bukhari 579'**
  String get restrictedHadith2Ref;

  /// No description provided for @restrictedScholarNote.
  ///
  /// In en, this message translates to:
  /// **'Rulings differ between the schools. Check with a scholar you trust for your own situation.'**
  String get restrictedScholarNote;

  /// No description provided for @methodKarachi.
  ///
  /// In en, this message translates to:
  /// **'University of Islamic Sciences, Karachi'**
  String get methodKarachi;

  /// No description provided for @methodMwl.
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get methodMwl;

  /// No description provided for @methodEgyptian.
  ///
  /// In en, this message translates to:
  /// **'Egyptian General Authority'**
  String get methodEgyptian;

  /// No description provided for @methodUmmAlQura.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura, Makkah'**
  String get methodUmmAlQura;

  /// No description provided for @methodDubai.
  ///
  /// In en, this message translates to:
  /// **'Dubai'**
  String get methodDubai;

  /// No description provided for @methodQatar.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get methodQatar;

  /// No description provided for @methodKuwait.
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get methodKuwait;

  /// No description provided for @methodMoonsighting.
  ///
  /// In en, this message translates to:
  /// **'Moonsighting Committee'**
  String get methodMoonsighting;

  /// No description provided for @methodSingapore.
  ///
  /// In en, this message translates to:
  /// **'Singapore'**
  String get methodSingapore;

  /// No description provided for @methodIsna.
  ///
  /// In en, this message translates to:
  /// **'ISNA (North America)'**
  String get methodIsna;

  /// No description provided for @methodTurkey.
  ///
  /// In en, this message translates to:
  /// **'Turkey'**
  String get methodTurkey;

  /// No description provided for @methodTehran.
  ///
  /// In en, this message translates to:
  /// **'Tehran'**
  String get methodTehran;

  /// No description provided for @alarmSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer alarms'**
  String get alarmSheetTitle;

  /// No description provided for @alarmSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A reminder for each waqt'**
  String get alarmSheetSubtitle;

  /// No description provided for @alarmSheetWhen.
  ///
  /// In en, this message translates to:
  /// **'When each alarm rings'**
  String get alarmSheetWhen;

  /// No description provided for @alarmSheetSound.
  ///
  /// In en, this message translates to:
  /// **'Adhan sound'**
  String get alarmSheetSound;

  /// No description provided for @alarmSheetRingsFor.
  ///
  /// In en, this message translates to:
  /// **'Rings for'**
  String get alarmSheetRingsFor;

  /// No description provided for @alarmSheetPaused.
  ///
  /// In en, this message translates to:
  /// **'All alarms are paused'**
  String get alarmSheetPaused;

  /// No description provided for @alarmNone.
  ///
  /// In en, this message translates to:
  /// **'No alarm'**
  String get alarmNone;

  /// No description provided for @alarmMeasuredFrom.
  ///
  /// In en, this message translates to:
  /// **'Measured from'**
  String get alarmMeasuredFrom;

  /// No description provided for @alarmAnchorWaqt.
  ///
  /// In en, this message translates to:
  /// **'Waqt'**
  String get alarmAnchorWaqt;

  /// No description provided for @alarmAnchorJamaat.
  ///
  /// In en, this message translates to:
  /// **'Jamaat'**
  String get alarmAnchorJamaat;

  /// No description provided for @alarmAtWaqt.
  ///
  /// In en, this message translates to:
  /// **'At waqt'**
  String get alarmAtWaqt;

  /// No description provided for @alarmAtJamaat.
  ///
  /// In en, this message translates to:
  /// **'At jamaat'**
  String get alarmAtJamaat;

  /// No description provided for @alarmMinBeforeWaqt.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before waqt'**
  String alarmMinBeforeWaqt(int minutes);

  /// No description provided for @alarmMinAfterWaqt.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min after waqt'**
  String alarmMinAfterWaqt(int minutes);

  /// No description provided for @alarmMinBeforeJamaat.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min before jamaat'**
  String alarmMinBeforeJamaat(int minutes);

  /// No description provided for @alarmMinAfterJamaat.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min after jamaat'**
  String alarmMinAfterJamaat(int minutes);

  /// No description provided for @alarmVibrate.
  ///
  /// In en, this message translates to:
  /// **'Vibrate'**
  String get alarmVibrate;

  /// No description provided for @alarmVibrateBody.
  ///
  /// In en, this message translates to:
  /// **'Buzz while the adhan plays'**
  String get alarmVibrateBody;

  /// No description provided for @alarmSoundFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not play this sound'**
  String get alarmSoundFailed;

  /// No description provided for @alarmSound1.
  ///
  /// In en, this message translates to:
  /// **'Alarm Sound 1'**
  String get alarmSound1;

  /// No description provided for @alarmSound2.
  ///
  /// In en, this message translates to:
  /// **'Alarm Sound 2'**
  String get alarmSound2;

  /// No description provided for @alarmSound3.
  ///
  /// In en, this message translates to:
  /// **'Alarm Sound 3'**
  String get alarmSound3;

  /// No description provided for @alarmMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String alarmMinutes(int minutes);

  /// No description provided for @calFullMonth.
  ///
  /// In en, this message translates to:
  /// **'Full month'**
  String get calFullMonth;

  /// No description provided for @calShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get calShare;

  /// No description provided for @calShareMonth.
  ///
  /// In en, this message translates to:
  /// **'Share month'**
  String get calShareMonth;

  /// No description provided for @calShareTimetable.
  ///
  /// In en, this message translates to:
  /// **'Share timetable'**
  String get calShareTimetable;

  /// No description provided for @calPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing…'**
  String get calPreparing;

  /// No description provided for @calDate.
  ///
  /// In en, this message translates to:
  /// **'DATE'**
  String get calDate;

  /// No description provided for @calToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get calToday;

  /// No description provided for @calTodayRow.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calTodayRow;

  /// No description provided for @calJumuah.
  ///
  /// In en, this message translates to:
  /// **'= Jumu\'ah'**
  String get calJumuah;

  /// No description provided for @calShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the timetable'**
  String get calShareFailed;

  /// No description provided for @calEncodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not encode the timetable'**
  String get calEncodeFailed;

  /// No description provided for @calTimetableTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer timetable'**
  String get calTimetableTitle;

  /// No description provided for @calVerifyNote.
  ///
  /// In en, this message translates to:
  /// **'Times are indicative — verify with your local mosque.'**
  String get calVerifyNote;

  /// No description provided for @dowMon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get dowMon;

  /// No description provided for @dowTue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get dowTue;

  /// No description provided for @dowWed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get dowWed;

  /// No description provided for @dowThu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get dowThu;

  /// No description provided for @dowFri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get dowFri;

  /// No description provided for @dowSat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get dowSat;

  /// No description provided for @dowSun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get dowSun;

  /// No description provided for @shareTodayTimes.
  ///
  /// In en, this message translates to:
  /// **'Share today\'s times'**
  String get shareTodayTimes;

  /// No description provided for @shareImage.
  ///
  /// In en, this message translates to:
  /// **'Share image'**
  String get shareImage;

  /// No description provided for @shareCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get shareCardTitle;

  /// No description provided for @shareSunrise.
  ///
  /// In en, this message translates to:
  /// **'SUNRISE'**
  String get shareSunrise;

  /// No description provided for @shareSahriEnds.
  ///
  /// In en, this message translates to:
  /// **'SAHRI ENDS'**
  String get shareSahriEnds;

  /// No description provided for @shareIftar.
  ///
  /// In en, this message translates to:
  /// **'IFTAR'**
  String get shareIftar;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share the card'**
  String get shareFailed;

  /// No description provided for @shareEncodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not encode the card'**
  String get shareEncodeFailed;

  /// No description provided for @shareCaption.
  ///
  /// In en, this message translates to:
  /// **'Prayer times · {date}'**
  String shareCaption(String date);

  /// No description provided for @shareMonthCaption.
  ///
  /// In en, this message translates to:
  /// **'Prayer timetable · {location}'**
  String shareMonthCaption(String location);

  /// No description provided for @calFridayNote.
  ///
  /// In en, this message translates to:
  /// **'✦ Friday (Jumu\'ah) · times are indicative — verify with your local mosque'**
  String get calFridayNote;

  /// No description provided for @calHijriBangla.
  ///
  /// In en, this message translates to:
  /// **'HIJRI · BANGLA'**
  String get calHijriBangla;

  /// No description provided for @calMonthShareCaption.
  ///
  /// In en, this message translates to:
  /// **'{month} prayer timetable · {location}'**
  String calMonthShareCaption(String month, String location);

  /// No description provided for @calTimetableHeader.
  ///
  /// In en, this message translates to:
  /// **'Prayer timetable · {location} · {madhab}'**
  String calTimetableHeader(String location, String madhab);

  /// No description provided for @qiblaHoldFlat.
  ///
  /// In en, this message translates to:
  /// **'hold your phone flat'**
  String get qiblaHoldFlat;

  /// No description provided for @qiblaAligned.
  ///
  /// In en, this message translates to:
  /// **'✓ Aligned — you are facing the Qibla'**
  String get qiblaAligned;

  /// No description provided for @qiblaAlignHint.
  ///
  /// In en, this message translates to:
  /// **'✓ Aligned when the Kaaba points up'**
  String get qiblaAlignHint;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer Stats'**
  String get statsTitle;

  /// No description provided for @statsDayStreak.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get statsDayStreak;

  /// No description provided for @statsOfThisWeek.
  ///
  /// In en, this message translates to:
  /// **'of {total} this week'**
  String statsOfThisWeek(int total);

  /// No description provided for @statsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get statsThisWeek;

  /// No description provided for @statsLast30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get statsLast30;

  /// No description provided for @statsEachDot.
  ///
  /// In en, this message translates to:
  /// **'each dot = 1 day'**
  String get statsEachDot;

  /// No description provided for @stats30DayRate.
  ///
  /// In en, this message translates to:
  /// **'30-day rate'**
  String get stats30DayRate;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @morePrayerStats.
  ///
  /// In en, this message translates to:
  /// **'Prayer stats'**
  String get morePrayerStats;

  /// No description provided for @morePrayerStatsSub.
  ///
  /// In en, this message translates to:
  /// **'Streak, weekly & 30-day history'**
  String get morePrayerStatsSub;

  /// No description provided for @morePrayerAlarms.
  ///
  /// In en, this message translates to:
  /// **'Prayer alarms'**
  String get morePrayerAlarms;

  /// No description provided for @morePrayerAlarmsSub.
  ///
  /// In en, this message translates to:
  /// **'Per-prayer timing, adhan sound & duration'**
  String get morePrayerAlarmsSub;

  /// No description provided for @moreWidget.
  ///
  /// In en, this message translates to:
  /// **'Home-screen widget'**
  String get moreWidget;

  /// No description provided for @moreWidgetSub.
  ///
  /// In en, this message translates to:
  /// **'Prayer times on your home screen'**
  String get moreWidgetSub;

  /// No description provided for @moreAdhanVoice.
  ///
  /// In en, this message translates to:
  /// **'Adhan voice'**
  String get moreAdhanVoice;

  /// No description provided for @moreSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get moreSettings;

  /// No description provided for @moreCalculationMethod.
  ///
  /// In en, this message translates to:
  /// **'Calculation method'**
  String get moreCalculationMethod;

  /// No description provided for @moreMadhabAsr.
  ///
  /// In en, this message translates to:
  /// **'Madhab (Asr)'**
  String get moreMadhabAsr;

  /// No description provided for @moreLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get moreLocation;

  /// No description provided for @moreRamadanMode.
  ///
  /// In en, this message translates to:
  /// **'Ramadan mode'**
  String get moreRamadanMode;

  /// No description provided for @moreNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get moreNotSet;

  /// No description provided for @moreCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get moreCustom;

  /// No description provided for @soundTraditional.
  ///
  /// In en, this message translates to:
  /// **'Traditional alarm tone'**
  String get soundTraditional;

  /// No description provided for @soundGentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle wake-up tone'**
  String get soundGentle;

  /// No description provided for @soundMelodic.
  ///
  /// In en, this message translates to:
  /// **'Melodic alarm tone'**
  String get soundMelodic;

  /// No description provided for @methodKarachiShort.
  ///
  /// In en, this message translates to:
  /// **'Karachi'**
  String get methodKarachiShort;

  /// No description provided for @methodEgyptianShort.
  ///
  /// In en, this message translates to:
  /// **'Egyptian'**
  String get methodEgyptianShort;

  /// No description provided for @methodUmmAlQuraShort.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura'**
  String get methodUmmAlQuraShort;

  /// No description provided for @resourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Islamic Resources'**
  String get resourcesTitle;

  /// No description provided for @resSalahGuide.
  ///
  /// In en, this message translates to:
  /// **'Salah Guide'**
  String get resSalahGuide;

  /// No description provided for @resSalahGuideSub.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step prayer instructions'**
  String get resSalahGuideSub;

  /// No description provided for @resWaqtRakah.
  ///
  /// In en, this message translates to:
  /// **'Waqt & Rakah Table'**
  String get resWaqtRakah;

  /// No description provided for @resWaqtRakahSub.
  ///
  /// In en, this message translates to:
  /// **'Prayer times and rak\'ah counts'**
  String get resWaqtRakahSub;

  /// No description provided for @resSurahs.
  ///
  /// In en, this message translates to:
  /// **'Necessary Surahs'**
  String get resSurahs;

  /// No description provided for @resSurahsSub.
  ///
  /// In en, this message translates to:
  /// **'Essential Qur\'anic chapters'**
  String get resSurahsSub;

  /// No description provided for @resAfterPrayer.
  ///
  /// In en, this message translates to:
  /// **'After-prayer Adhkar'**
  String get resAfterPrayer;

  /// No description provided for @resAfterPrayerSub.
  ///
  /// In en, this message translates to:
  /// **'What to recite after the salam'**
  String get resAfterPrayerSub;

  /// No description provided for @resDuas.
  ///
  /// In en, this message translates to:
  /// **'Du\'a & Adhkar'**
  String get resDuas;

  /// No description provided for @resDuasSub.
  ///
  /// In en, this message translates to:
  /// **'Supplications & remembrances'**
  String get resDuasSub;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return LBn();
    case 'en':
      return LEn();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
