// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class LBn extends L {
  LBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'LifeQue';

  @override
  String get navTasks => 'কাজ';

  @override
  String get navTodoList => 'করণীয় তালিকা';

  @override
  String get navReminders => 'রিমাইন্ডার';

  @override
  String get navBirthdays => 'জন্মদিন';

  @override
  String get navExpenses => 'খরচের হিসাব';

  @override
  String get navMedicines => 'ওষুধ';

  @override
  String get navPrayerTimes => 'নামাজের সময়';

  @override
  String get navStudyTimer => 'পড়ার টাইমার';

  @override
  String get navSettings => 'সেটিংস';

  @override
  String get drawerTagline => 'আপনার ব্যক্তিগত জীবন-সহকারী';

  @override
  String get commonSave => 'সংরক্ষণ';

  @override
  String get commonCancel => 'বাতিল';

  @override
  String get commonDelete => 'মুছুন';

  @override
  String get commonEdit => 'সম্পাদনা';

  @override
  String get commonRetry => 'আবার চেষ্টা করুন';

  @override
  String get commonMore => 'আরও';

  @override
  String get commonDone => 'সম্পন্ন';

  @override
  String get commonToday => 'আজ';

  @override
  String get commonTomorrow => 'আগামীকাল';

  @override
  String get commonYesterday => 'গতকাল';

  @override
  String get commonNow => 'এখন';

  @override
  String get commonOff => 'বন্ধ';

  @override
  String get commonNone => 'নেই';

  @override
  String get settingsTitle => 'সেটিংস';

  @override
  String get settingsSectionGeneral => 'সাধারণ';

  @override
  String get settingsSectionApp => 'অ্যাপ';

  @override
  String get settingsSectionLegal => 'আইনগত';

  @override
  String get settingsNavigationOrder => 'মেনুর ক্রম';

  @override
  String settingsNavigationOrderSubtitle(String page) {
    return 'হোম: $page';
  }

  @override
  String get settingsLanguage => 'ভাষা';

  @override
  String get settingsCheckUpdates => 'আপডেট দেখুন';

  @override
  String get settingsCheckUpdatesSubtitle => 'নতুন সংস্করণ এসেছে কি না দেখুন';

  @override
  String get settingsAbout => 'লাইফকিউ সম্পর্কে';

  @override
  String get settingsAboutSubtitle => 'সংস্করণ, নির্মাতা ও লিংক';

  @override
  String get settingsPrivacy => 'গোপনীয়তা নীতি';

  @override
  String get settingsPrivacySubtitle => 'আপনার তথ্য কীভাবে ব্যবহার করি';

  @override
  String get settingsTerms => 'ব্যবহারের শর্তাবলি';

  @override
  String get settingsTermsSubtitle => 'অ্যাপ ব্যবহারের শর্ত';

  @override
  String get settingsMadeBy => '❤️ দিয়ে তৈরি — জামান শেখ';

  @override
  String get navOrderTitle => 'মেনুর ক্রম';

  @override
  String get navOrderSubtitle => 'সাজাতে টেনে আনুন। প্রথমটিই হোম পেজ।';

  @override
  String navOrderHomePage(String page) {
    return 'হোম পেজ:  $page';
  }

  @override
  String get navOrderHomeBadge => 'হোম পেজ';

  @override
  String get navOrderSave => 'ক্রম সংরক্ষণ';

  @override
  String get navOrderSaved => 'মেনুর ক্রম সংরক্ষিত হয়েছে';

  @override
  String languageComingSoon(String language) {
    return '$language · শীঘ্রই আসছে';
  }

  @override
  String languageSet(String language) {
    return 'ভাষা $language করা হয়েছে';
  }

  @override
  String languageSavedPending(String language) {
    return '$language সংরক্ষিত হয়েছে। অনুবাদ যুক্ত না হওয়া পর্যন্ত অ্যাপ ইংরেজিতেই থাকবে।';
  }

  @override
  String get tasksTabActive => 'চলমান';

  @override
  String get tasksTabAll => 'সব';

  @override
  String get tasksTabDone => 'সম্পন্ন';

  @override
  String get tasksGroupDueToday => 'আজকের মধ্যে';

  @override
  String get tasksGroupNext7Days => 'আগামী ৭ দিন';

  @override
  String get tasksGroupLater => 'পরে';

  @override
  String get tasksGroupOverdue => 'সময় পেরিয়ে গেছে';

  @override
  String get tasksGroupInProgress => 'চলছে';

  @override
  String get tasksGroupNotStarted => 'এখনো শুরু হয়নি';

  @override
  String get tasksGroupCompleted => 'সম্পন্ন';

  @override
  String get tasksEmptyTitle => 'এখনো কোনো কাজ নেই';

  @override
  String get tasksEmptyBody =>
      'শুরু ও শেষের তারিখ দিয়ে কিছু যোগ করুন — চলাকালীন সেটি এখানে দেখা যাবে।';

  @override
  String get tasksAllDoneTitle => 'এই মুহূর্তে কিছু নেই';

  @override
  String get tasksAllDoneBody =>
      'সময়সীমা আছে এমন সব কাজ হয় শেষ, নয়তো এখনো শুরু হয়নি। বাকিগুলো দেখতে ‘সব’ ট্যাবে যান।';

  @override
  String get tasksTapPlus => 'যোগ করতে + চাপুন';

  @override
  String get tasksNoCompletedTitle => 'এখনো কোনো কাজ শেষ হয়নি';

  @override
  String get tasksNoCompletedBody => 'কাজ শেষ করলে সেগুলো এখানে দেখা যাবে।';

  @override
  String get tasksFirstRunTitle => 'লাইফকিউ-তে স্বাগতম';

  @override
  String get tasksFirstRunBody =>
      'যেকোনো একটি দিয়ে শুরু করুন। সবগুলোই মেনুতেও আছে।';

  @override
  String get tasksStartTask => 'প্রথম কাজটি যোগ করুন';

  @override
  String get tasksStartTaskSub => 'সময়সীমা আছে এমন কিছু';

  @override
  String get tasksStartPrayer => 'নামাজের সময় ঠিক করুন';

  @override
  String get tasksStartPrayerSub => 'ওয়াক্ত, জামাত ও হোম স্ক্রিনের উইজেট';

  @override
  String get tasksStartBirthday => 'একটি জন্মদিন সংরক্ষণ করুন';

  @override
  String get tasksStartBirthdaySub => 'প্রতি বছর একদিন আগে মনে করিয়ে দেবে';

  @override
  String get tasksStartTodo => 'করণীয় তালিকা শুরু করুন';

  @override
  String get tasksStartTodoSub => 'ছোট ছোট কাজ, একে একে টিক দিন';

  @override
  String get tasksDeleteTitle => 'কাজটি মুছবেন?';

  @override
  String tasksDeleteBody(String title) {
    return '“$title” মুছে ফেলা হবে।';
  }

  @override
  String get tasksMedicinesTooltip => 'ওষুধ';

  @override
  String get taskCardDone => 'সম্পন্ন';

  @override
  String taskCardStartsIn(String time) {
    return 'শুরু $time পরে';
  }

  @override
  String taskCardLeft(String time) {
    return '$time বাকি';
  }

  @override
  String taskCardOver(String time) {
    return '$time পেরিয়েছে';
  }

  @override
  String taskUnitDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString দিন';
  }

  @override
  String taskUnitHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ঘণ্টা';
  }

  @override
  String taskUnitMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString মিনিট';
  }

  @override
  String taskUnitSeconds(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString সে.';
  }

  @override
  String get taskFormNewTitle => 'নতুন কাজ';

  @override
  String get taskFormEditTitle => 'কাজ সম্পাদনা';

  @override
  String get taskFormTitleHint => 'কী করতে হবে?';

  @override
  String get taskFormTitleEmpty => 'একটি নাম দিন';

  @override
  String get taskFormDue => 'শেষ সময়';

  @override
  String get taskFormStarts => 'শুরু';

  @override
  String get taskFormPresetToday => 'আজ';

  @override
  String get taskFormPresetTomorrow => 'আগামীকাল';

  @override
  String get taskFormPresetWeek => 'এক সপ্তাহে';

  @override
  String get taskFormEndBeforeStart => 'শেষের সময় শুরুর পরে হতে হবে।';

  @override
  String get taskFormRemindMe => 'মনে করিয়ে দিন';

  @override
  String get taskFormModeBeforeDue => 'শেষ হওয়ার আগে';

  @override
  String get taskFormModeAtTime => 'নির্দিষ্ট সময়ে';

  @override
  String get taskFormModeDaily => 'প্রতিদিন';

  @override
  String get taskFormAt => 'সময়';

  @override
  String get taskFormPickTime => 'সময় বেছে নিন';

  @override
  String taskFormEveryDayAt(String time) {
    return 'প্রতিদিন $time';
  }

  @override
  String get taskFormMoreOptions => 'আরও অপশন';

  @override
  String get taskFormNotesHint => 'নোট (ঐচ্ছিক)';

  @override
  String get taskFormPinTitle => 'নোটিফিকেশন বারে রেখে দিন';

  @override
  String get taskFormPinSubtitle => 'চলমান নোটিফিকেশন, এক নজরেই দেখা যাবে';

  @override
  String get taskFormCreate => 'কাজ তৈরি করুন';

  @override
  String get taskFormSaveChanges => 'পরিবর্তন সংরক্ষণ';

  @override
  String get taskFormNeedReminderTime => 'কখন মনে করিয়ে দেব, সময়টি বেছে নিন।';

  @override
  String get taskFormNeedDailyTime =>
      'দিনের কোন সময়ে মনে করিয়ে দেব, বেছে নিন।';

  @override
  String get beforeEnd10Minutes => '১০ মিনিট';

  @override
  String get beforeEnd30Minutes => '৩০ মিনিট';

  @override
  String get beforeEnd1Hour => '১ ঘণ্টা';

  @override
  String get beforeEnd2Hours => '২ ঘণ্টা';

  @override
  String get beforeEnd1Day => '১ দিন';

  @override
  String get pinBeforeTitle => 'রিমাইন্ডারের আগে পিন করুন';

  @override
  String get pinBeforeBody => 'রিমাইন্ডার বাজা পর্যন্ত পিন করা থাকবে';

  @override
  String get pinAfterTitle => 'রিমাইন্ডারের পরে পিন করুন';

  @override
  String get pinAfterBody => 'রিমাইন্ডার বাজার পরে পিন হবে';

  @override
  String get detailTask => 'কাজ';

  @override
  String get detailReminder => 'রিমাইন্ডার';

  @override
  String get detailBirthday => 'জন্মদিন';

  @override
  String get detailGeneric => 'বিস্তারিত';

  @override
  String get detailNotFound => 'কাজটি পাওয়া যায়নি';

  @override
  String get detailSectionTimeLeft => 'বাকি সময়';

  @override
  String get detailSectionCountdown => 'কাউন্টডাউন';

  @override
  String get detailSectionTimeline => 'সময়রেখা';

  @override
  String get detailSectionDetails => 'বিস্তারিত';

  @override
  String get detailSectionReminders => 'রিমাইন্ডার';

  @override
  String get detailSectionAbout => 'পরিচিতি';

  @override
  String get detailSectionWhen => 'কখন';

  @override
  String get detailSectionToday => 'আজ';

  @override
  String get detailUntilDeadline => 'শেষ সময় পর্যন্ত';

  @override
  String get detailDeadlinePassed => 'শেষ সময় পেরিয়ে গেছে';

  @override
  String get detailTimeElapsed => 'সময় পেরিয়েছে';

  @override
  String get detailDaysLeft => 'দিন বাকি';

  @override
  String get detailDaysTotal => 'মোট দিন';

  @override
  String get detailStarted => 'শুরু হয়েছে';

  @override
  String get detailDue => 'শেষ সময়';

  @override
  String get detailWasDue => 'শেষ হওয়ার কথা ছিল';

  @override
  String get detailReminderRow => 'রিমাইন্ডার';

  @override
  String get detailPinned => 'পিন করা';

  @override
  String get detailPinnedValue => 'নোটিফিকেশন বারে আছে';

  @override
  String get detailCreated => 'তৈরি হয়েছে';

  @override
  String get detailLastEdited => 'সর্বশেষ সম্পাদনা';

  @override
  String get detailStatusCompleted => 'সম্পন্ন';

  @override
  String get detailStatusOverdue => 'সময় পেরিয়ে গেছে';

  @override
  String get detailStatusInProgress => 'চলছে';

  @override
  String get detailStatusNotStarted => 'এখনো শুরু হয়নি';

  @override
  String detailReminderBefore(String option) {
    return '$option আগে';
  }

  @override
  String detailReminderDaily(String time) {
    return 'প্রতিদিন $time';
  }

  @override
  String get detailReminderAtTime => 'নির্দিষ্ট সময়ে';

  @override
  String get detailReminderBeforeDue => 'শেষ হওয়ার আগে';

  @override
  String get detailUntilItFires => 'বাজার আগ পর্যন্ত';

  @override
  String get detailAlreadyFired => 'এই রিমাইন্ডার ইতিমধ্যে বেজে গেছে';

  @override
  String get detailStatusDone => 'সম্পন্ন';

  @override
  String get detailStatusPassed => 'সময় পেরিয়ে গেছে';

  @override
  String get detailStatusAnyMinute => 'যেকোনো মুহূর্তে';

  @override
  String get detailStatusWaiting => 'অপেক্ষায়';

  @override
  String get detailRowDate => 'তারিখ';

  @override
  String get detailRowTime => 'সময়';

  @override
  String get remindersTitle => 'রিমাইন্ডার';

  @override
  String get remindersEmptyTitle => 'কোনো রিমাইন্ডার নেই';

  @override
  String get remindersEmptyBody =>
      'যেসব কথা ভুলে যান, সেগুলোর জন্য রিমাইন্ডার দিয়ে রাখুন।';

  @override
  String get remindersSetOne => 'রিমাইন্ডার দিন';

  @override
  String get remindersNewOne => 'নতুন রিমাইন্ডার';

  @override
  String get remindersNothingPending => 'কিছু বাকি নেই';

  @override
  String get remindersAllCaughtUp => 'সব সেরে ফেলেছেন';

  @override
  String get remindersAllDoneBody => 'কিছু বাকি নেই — এখানকার সব শেষ।';

  @override
  String get remindersNextUp => 'পরবর্তী রিমাইন্ডার';

  @override
  String get remindersGroupMissed => 'মিস হয়েছে';

  @override
  String get remindersGroupToday => 'আজ';

  @override
  String get remindersGroupTomorrow => 'আগামীকাল';

  @override
  String get remindersGroupLater => 'পরে';

  @override
  String remindersDoneCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countStringটি সম্পন্ন';
  }

  @override
  String get remindersDeleteTitle => 'এই রিমাইন্ডারটি মুছবেন?';

  @override
  String get remindersKeepIt => 'থাক';

  @override
  String get birthdaysTitle => 'জন্মদিন';

  @override
  String get birthdaysEmptyTitle => 'কোনো জন্মদিন সংরক্ষিত নেই';

  @override
  String get birthdaysEmptyBody =>
      'যাঁদের শুভেচ্ছা জানাতে চান তাঁদের যোগ করুন — কার জন্মদিন সামনে, এই পাতা বলে দেবে।';

  @override
  String get birthdaysAddOne => 'একটি জন্মদিন যোগ করুন';

  @override
  String get birthdaysAdd => 'জন্মদিন যোগ করুন';

  @override
  String get birthdaysEveryone => 'সবাই';

  @override
  String birthdaysMatching(String query) {
    return '“$query” মিলেছে';
  }

  @override
  String get birthdaysNoMatch => 'এই নামে কাউকে পাওয়া যায়নি';

  @override
  String get birthdaysSearchHint => 'নাম দিয়ে খুঁজুন';

  @override
  String get birthdaysClearSearch => 'খোঁজা বাতিল করুন';

  @override
  String get birthdaysNextUp => 'পরবর্তী';

  @override
  String get birthdaysToday => 'আজ জন্মদিন';

  @override
  String birthdaysInDays(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString দিন পরে';
  }

  @override
  String get birthdaysRemindersOn => 'রিমাইন্ডার চালু';

  @override
  String get birthdaysRemindersOff => 'রিমাইন্ডার বন্ধ';

  @override
  String get birthdaysDeleteTitle => 'এই জন্মদিনটি মুছবেন?';

  @override
  String birthdaysTurning(int age) {
    final intl.NumberFormat ageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String ageString = ageNumberFormat.format(age);

    return '$ageString বছর পূর্ণ হবে';
  }

  @override
  String birthdaysTodayLine(int age) {
    final intl.NumberFormat ageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String ageString = ageNumberFormat.format(age);

    return 'আজই সেই দিন — $ageString বছর পূর্ণ হলো।';
  }

  @override
  String get birthdaysUntilBigDay => 'বিশেষ দিনটির আগ পর্যন্ত';

  @override
  String get birthdaysYearsOldNow => 'বছর বয়স এখন';

  @override
  String get birthdaysDaysToGo => 'দিন বাকি';

  @override
  String get birthdaysTheBigDay => 'আজই সেই দিন';

  @override
  String get birthdaysNoReminders =>
      'এই জন্মদিনের জন্য কোনো রিমাইন্ডার দেওয়া নেই।';

  @override
  String get birthdaysBorn => 'জন্ম';

  @override
  String get birthdaysNext => 'পরবর্তী জন্মদিন';

  @override
  String get birthdaysSaved => 'সংরক্ষিত';

  @override
  String get birthdaysTomorrow => 'আগামীকাল জন্মদিন';

  @override
  String get commonSomethingWrong => 'কিছু একটা সমস্যা হয়েছে';

  @override
  String get commonMenu => 'মেনু';

  @override
  String get commonDetails => 'বিস্তারিত';

  @override
  String get commonSearch => 'খুঁজুন';

  @override
  String get countdownDays => 'দিন';

  @override
  String get countdownHours => 'ঘণ্টা';

  @override
  String get countdownMinutes => 'মিনিট';

  @override
  String get countdownSeconds => 'সেকেন্ড';

  @override
  String get todosTitle => 'করণীয় তালিকা';

  @override
  String get todosTabAll => 'সব';

  @override
  String get todosTabToday => 'আজ';

  @override
  String get todosTabUpcoming => 'আসন্ন';

  @override
  String get todosTabDone => 'সম্পন্ন';

  @override
  String get todosNew => 'নতুন করণীয়';

  @override
  String get todosGroupOverdue => 'সময় পেরিয়ে গেছে';

  @override
  String get todosGroupToday => 'আজ';

  @override
  String get todosGroupTomorrow => 'আগামীকাল';

  @override
  String get todosGroupThisWeek => 'এই সপ্তাহে';

  @override
  String get todosGroupLater => 'পরে';

  @override
  String get todosGroupNoDate => 'তারিখ নেই';

  @override
  String get todosGroupCompleted => 'সম্পন্ন';

  @override
  String get todosSearchHint => 'করণীয় খুঁজুন';

  @override
  String get todosClearSearch => 'খোঁজা বাতিল করুন';

  @override
  String get todosAnyCategory => 'যেকোনো ধরন';

  @override
  String get todosNothingMatched => 'কিছু মেলেনি';

  @override
  String get todosNothingMatchedBody =>
      'অন্য শব্দে খুঁজুন, অথবা ধরনের ফিল্টার সরিয়ে দিন।';

  @override
  String get todosNothingFinished => 'এখনো কিছু শেষ হয়নি';

  @override
  String get todosNothingToday => 'আজ কিছু করার নেই';

  @override
  String get todosNothingAhead => 'সামনে কিছু নির্ধারিত নেই';

  @override
  String get todosAllClear => 'সব পরিষ্কার';

  @override
  String get todosNothingInView => 'এই তালিকায় কিছু নেই।';

  @override
  String get todosNothingLeft => 'কিছুই বাকি নেই — উপভোগ করুন';

  @override
  String get todosEmptyTitle => 'আপনার তালিকা খালি';

  @override
  String get todosEmptyBody =>
      'যা করতে হবে তা যোগ করুন। তারিখ ও রিমাইন্ডার দিলে সময়মতো মনে করিয়ে দেবে।';

  @override
  String get todosAddFirst => 'প্রথম করণীয়টি যোগ করুন';

  @override
  String get todosDeleteTitle => 'এই করণীয়টি মুছবেন?';

  @override
  String get todosKeepIt => 'থাক';

  @override
  String get todoDetailTitle => 'করণীয়';

  @override
  String get todoRowCategory => 'ধরন';

  @override
  String get todoRowPriority => 'গুরুত্ব';

  @override
  String get todoRowDue => 'শেষ সময়';

  @override
  String get todoRowNoDue => 'কোনো সময়সীমা নেই';

  @override
  String get todoRowReminder => 'রিমাইন্ডার';

  @override
  String get todoRowCreated => 'তৈরি হয়েছে';

  @override
  String get todoRowCompleted => 'সম্পন্ন হয়েছে';

  @override
  String get todoStatusDone => 'সম্পন্ন';

  @override
  String get todoStatusOverdue => 'সময় পেরিয়ে গেছে';

  @override
  String get todoStatusDueToday => 'আজকের মধ্যে';

  @override
  String get todoStatusDueTomorrow => 'আগামীকালের মধ্যে';

  @override
  String todoStatusPriority(String priority) {
    return 'গুরুত্ব: $priority';
  }

  @override
  String todoAtTime(String day, String time) {
    return '$day $time';
  }

  @override
  String get priorityLow => 'কম';

  @override
  String get priorityMedium => 'মাঝারি';

  @override
  String get priorityHigh => 'বেশি';

  @override
  String get priorityUrgent => 'জরুরি';

  @override
  String get categoryPersonal => 'ব্যক্তিগত';

  @override
  String get categoryWork => 'কাজ';

  @override
  String get categoryShopping => 'কেনাকাটা';

  @override
  String get categoryHealth => 'স্বাস্থ্য';

  @override
  String get categoryEducation => 'পড়াশোনা';

  @override
  String get categoryFinance => 'আর্থিক';

  @override
  String get categoryTravel => 'ভ্রমণ';

  @override
  String get categoryHome => 'বাসা';

  @override
  String get categoryOther => 'অন্যান্য';

  @override
  String todosDeleteBody(String title) {
    return '“$title” এবং এর রিমাইন্ডার মুছে যাবে। এটি আর ফেরানো যাবে না।';
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

    return '$daysString দিনে';
  }

  @override
  String birthdaysInMonthsShort(int months) {
    final intl.NumberFormat monthsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String monthsString = monthsNumberFormat.format(months);

    return '$monthsString মাসে';
  }

  @override
  String get birthdayOptOneDay => '১ দিন আগে (উপহারের প্রস্তুতি)';

  @override
  String get birthdayOptOneDayBody => 'উপহার গোছানোর কথা মনে করিয়ে দেবে';

  @override
  String get birthdayOptTwoHours => '২ ঘণ্টা আগে';

  @override
  String get birthdayOptTwoHoursBody => 'শেষ প্রস্তুতির জন্য';

  @override
  String get birthdayOptTenMinutes => '১০ মিনিট আগে';

  @override
  String get birthdayOptTenMinutesBody => 'উদযাপনের সময় প্রায় হয়ে এসেছে';

  @override
  String get birthdayOptExact => 'ঠিক রাত ১২টায়';

  @override
  String get birthdayOptExactBody => 'জন্মদিন শুরুর মুহূর্তে';

  @override
  String get prayerFajr => 'ফজর';

  @override
  String get prayerDhuhr => 'জোহর';

  @override
  String get prayerAsr => 'আসর';

  @override
  String get prayerMaghrib => 'মাগরিব';

  @override
  String get prayerIsha => 'এশা';

  @override
  String get prayerTahajjud => 'তাহাজ্জুদ';

  @override
  String get prayerSunrise => 'সূর্যোদয়';

  @override
  String get prayerNavPrayer => 'নামাজ';

  @override
  String get prayerNavCalendar => 'ক্যালেন্ডার';

  @override
  String get prayerNavTasbih => 'তাসবিহ';

  @override
  String get prayerNavLearn => 'শিখুন';

  @override
  String get prayerNavMore => 'আরও';

  @override
  String get salatTimesTitle => 'নামাজের সময়সূচি';

  @override
  String get salatSetAlarm => 'অ্যালার্ম দিন';

  @override
  String get salatSetJamaat => 'জামাতের সময় দিন';

  @override
  String salatJamaatAt(String time) {
    return 'জামাত $time';
  }

  @override
  String salatTill(String time) {
    return '$time পর্যন্ত';
  }

  @override
  String get salatNowBadge => 'এখন';

  @override
  String get gaugeWaqtEndsIn => 'ওয়াক্ত শেষ হতে বাকি';

  @override
  String get gaugeStartsIn => 'শুরু হতে বাকি';

  @override
  String get gaugeBeginsIn => 'শুরু হতে বাকি';

  @override
  String gaugeStartsAt(String time) {
    return 'শুরু $time-এ';
  }

  @override
  String gaugeBeginsAt(String time) {
    return 'শুরু $time-এ';
  }

  @override
  String get gaugeEndsAtFajr => 'ফজর পর্যন্ত বাকি';

  @override
  String get prohibitedCardTitle => 'নামাজের নিষিদ্ধ সময়';

  @override
  String get prohibitedSeeReference => 'দলিল দেখুন';

  @override
  String get prohibitedSubtitle => 'এই সময়গুলোতে নামাজ পড়া নিষেধ।';

  @override
  String prohibitedActiveNow(String left) {
    return 'এখন চলছে · $left বাকি — এই সময়ে নামাজ পড়া নিষেধ।';
  }

  @override
  String prohibitedNext(String window, String time) {
    return 'এই সময়গুলোতে নামাজ পড়া নিষেধ · পরবর্তী: $window $time';
  }

  @override
  String get prohibitedNowTitle => 'এখন নামাজ পড়া নিষেধ';

  @override
  String prohibitedNowBody(String window, String time, String left) {
    return '$window · শেষ $time-এ ($left বাকি)';
  }

  @override
  String get prohibitedDismiss => 'বন্ধ করুন';

  @override
  String get prohibitedSunrise => 'সূর্য ওঠার সময়';

  @override
  String get prohibitedZawal => 'সূর্য ঠিক মাথার ওপরে থাকার সময়';

  @override
  String get prohibitedSunset => 'সূর্য ডোবার সময়';

  @override
  String get prohibitedMorning => 'সকাল';

  @override
  String get prohibitedNoon => 'দুপুর';

  @override
  String get prohibitedEvening => 'সন্ধ্যা';

  @override
  String get restrictedTimesTitle => 'নিষিদ্ধ সময়';

  @override
  String get nafalTitle => 'নফল নামাজের সময়';

  @override
  String get nafalIshraq => 'ইশরাক / দুহা';

  @override
  String get nafalZawalStart => 'যাওয়াল শুরু';

  @override
  String get nafalAwabin => 'আওয়াবিন';

  @override
  String nafalAfterMaghrib(String time) {
    return 'মাগরিবের পর – $time';
  }

  @override
  String nafalAfterIsha(String time) {
    return 'এশার পর – $time';
  }

  @override
  String nafalLastThird(String time) {
    return 'রাতের শেষ তৃতীয়াংশ শুরু: $time';
  }

  @override
  String get progressAllFive => 'আজ পাঁচ ওয়াক্তই পড়া হয়েছে';

  @override
  String get progressLoggedToday => 'আজ পড়া নামাজ';

  @override
  String get progressLogged => 'পড়া নামাজ';

  @override
  String get progressViewStats => 'পরিসংখ্যান দেখুন';

  @override
  String get progressNoStreak => 'এখনো ধারাবাহিকতা নেই';

  @override
  String progressStreak(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString দিন ধারাবাহিক';
  }

  @override
  String get prayerBackToToday => 'আজকে ফিরে যান';

  @override
  String get prayerSettingsTitle => 'নামাজের সেটিংস';

  @override
  String get prayerSettingsSubtitle => 'নামাজের সময় কীভাবে হিসাব হয়';

  @override
  String get prayerSectionMethod => 'গণনার পদ্ধতি';

  @override
  String get prayerSectionMadhab => 'মাযহাব — আসরের জন্য';

  @override
  String get prayerSectionLocation => 'অবস্থান';

  @override
  String get prayerSetLocationManually => 'নিজে অবস্থান নির্ধারণ করুন';

  @override
  String get prayerSetLocation => 'অবস্থান নির্ধারণ';

  @override
  String get prayerLocationName => 'স্থানের নাম';

  @override
  String get prayerLatitude => 'অক্ষাংশ';

  @override
  String get prayerLongitude => 'দ্রাঘিমাংশ';

  @override
  String get prayerCurrentLocation => 'বর্তমান অবস্থান';

  @override
  String get prayerDefaultLocationNote =>
      'ডিফল্ট অবস্থান (ঢাকা) ব্যবহার হচ্ছে। নিজের অবস্থান দিতে পিন-এ চাপুন।';

  @override
  String get prayerUnableToCompute => 'নামাজের সময় হিসাব করা যায়নি';

  @override
  String prayerAlarmSetFor(String prayer, String time, String day) {
    return '$prayer-এর অ্যালার্ম $day $time-এ দেওয়া হলো';
  }

  @override
  String prayerAlarmSet(String prayer) {
    return '$prayer-এর অ্যালার্ম দেওয়া হলো';
  }

  @override
  String prayerAlarmOff(String prayer) {
    return '$prayer-এর অ্যালার্ম বন্ধ করা হলো';
  }

  @override
  String get prayerDayToday => 'আজ';

  @override
  String get prayerDayTomorrow => 'আগামীকাল';

  @override
  String get madhabHanafi => 'হানাফি';

  @override
  String get madhabHanafiNote => 'আসর দেরিতে';

  @override
  String get madhabShafi => 'শাফিঈ';

  @override
  String get madhabShafiNote => 'আসর আগে';

  @override
  String get ramadanMode => 'রমজান মোড';

  @override
  String ramadanDay(int day) {
    final intl.NumberFormat dayNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dayString = dayNumberFormat.format(day);

    return 'রমজান · দিন $dayString';
  }

  @override
  String get prohibitedAllPassed =>
      'এই সময়গুলোতে নামাজ পড়া নিষেধ · আজকের সবগুলোই পেরিয়ে গেছে।';

  @override
  String get reminderFormNew => 'নতুন রিমাইন্ডার';

  @override
  String get reminderFormEdit => 'রিমাইন্ডার সম্পাদনা';

  @override
  String get reminderFormTitleLabel => 'আমাকে মনে করিয়ে দিন…';

  @override
  String get reminderFormTitleEmpty => 'কী মনে করিয়ে দেব লিখুন';

  @override
  String get reminderFormNote => 'একটি নোট যোগ করুন';

  @override
  String get reminderFormNoteHint => 'মনে রাখার মতো কিছু';

  @override
  String get reminderFormInAnHour => 'এক ঘণ্টা পরে';

  @override
  String get reminderFormThisEvening => 'আজ সন্ধ্যায়';

  @override
  String get reminderFormTomorrow9 => 'আগামীকাল সকাল ৯টা';

  @override
  String get reminderFormPick => 'বেছে নিন…';

  @override
  String get reminderFormKeepShade => 'নোটিফিকেশন বারে রেখে দিন';

  @override
  String get reminderFormOnDate => 'কোন দিন';

  @override
  String get reminderFormAtTime => 'কখন';

  @override
  String get reminderFormFutureTime => 'ভবিষ্যতের একটি সময় বেছে নিন';

  @override
  String get birthdayFormNew => 'নতুন জন্মদিন';

  @override
  String get birthdayFormEdit => 'জন্মদিন সম্পাদনা';

  @override
  String get birthdayFormNameLabel => 'কার জন্মদিন?';

  @override
  String get birthdayFormNameEmpty => 'তাঁর নাম লিখুন';

  @override
  String get birthdayFormNoteHint => 'উপহারের ভাবনা, পরিচয়ের সূত্র…';

  @override
  String get birthdayFormDob => 'জন্মতারিখ';

  @override
  String birthdayFormTurning(int age) {
    final intl.NumberFormat ageNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String ageString = ageNumberFormat.format(age);

    return 'পরের জন্মদিনে $ageString বছর হবে';
  }

  @override
  String get birthdayFormSetYear => 'বয়স দেখাতে জন্মসাল দিন';

  @override
  String get birthdayFormNoReminders =>
      'কোনো রিমাইন্ডার নেই — তারিখটি কেবল দেখে নেওয়ার জন্য সংরক্ষিত থাকবে।';

  @override
  String get birthdayFormDayBefore => 'আগের দিন';

  @override
  String get birthdayFormTwoHours => 'দুই ঘণ্টা আগে';

  @override
  String get birthdayFormTenMinutes => 'দশ মিনিট আগে';

  @override
  String get birthdayFormMidnight => 'সেদিন, রাত ১২টায়';

  @override
  String get todoFormNew => 'নতুন করণীয়';

  @override
  String get todoFormEdit => 'করণীয় সম্পাদনা';

  @override
  String get todoFormTitleLabel => 'কী করতে হবে?';

  @override
  String get todoFormTitleEmpty => 'একটি নাম দিন';

  @override
  String get todoFormNoteHint => 'মনে রাখার মতো বিস্তারিত';

  @override
  String get todoFormPriority => 'গুরুত্ব';

  @override
  String get todoFormCategory => 'ধরন';

  @override
  String get todoFormNoDate => 'তারিখ নেই';

  @override
  String get todoFormDueDate => 'শেষ তারিখ';

  @override
  String get todoFormDueTime => 'শেষ সময়';

  @override
  String get todoFormAtDueTime => 'শেষ সময়ে';

  @override
  String get todoFormDayBefore => 'একদিন আগে';

  @override
  String get todoFormPassed =>
      'এই সময় পেরিয়ে গেছে — পরের কোনো সময় দিন, নইলে রিমাইন্ডার বাজবে না।';

  @override
  String todoFormNotificationOn(String when) {
    return 'নোটিফিকেশন $when';
  }

  @override
  String get medTitle => 'ওষুধ';

  @override
  String get medAdd => 'ওষুধ যোগ করুন';

  @override
  String get medEdit => 'ওষুধ সম্পাদনা';

  @override
  String get medDetailTitle => 'ওষুধ';

  @override
  String get medEmptyTitle => 'এখনো কোনো ওষুধ নেই';

  @override
  String get medViewAll => 'সব ওষুধ দেখুন';

  @override
  String get medQuickAdd => 'দ্রুত যোগ করুন';

  @override
  String get medRefresh => 'রিফ্রেশ';

  @override
  String get medNameLabel => 'ওষুধের নাম';

  @override
  String get medNameEmpty => 'ওষুধের নাম লিখুন';

  @override
  String get medDosage => 'মাত্রা';

  @override
  String get medDuration => 'কত দিন';

  @override
  String get medStartDate => 'শুরুর তারিখ';

  @override
  String get medTimesPerDay => 'দিনে কতবার:';

  @override
  String get medNotificationTimes => 'নোটিফিকেশনের সময়:';

  @override
  String get medMealTiming => 'খাবারের সঙ্গে';

  @override
  String get medBeforeMeal => 'খাবারের আগে';

  @override
  String get medAfterMeal => 'খাবারের পরে';

  @override
  String get medWithMeal => 'খাবারের সঙ্গে';

  @override
  String get medEmptyStomach => 'খালি পেটে';

  @override
  String get medAnytime => 'যেকোনো সময়';

  @override
  String get medTablet => 'ট্যাবলেট';

  @override
  String get medCapsule => 'ক্যাপসুল';

  @override
  String get medInjection => 'ইনজেকশন';

  @override
  String get medDoctor => 'ডাক্তার';

  @override
  String get medDoctorName => 'ডাক্তারের নাম';

  @override
  String get medDescription => 'বিবরণ';

  @override
  String get medAdditionalInfo => 'অতিরিক্ত তথ্য (ঐচ্ছিক)';

  @override
  String get medDeleteTitle => 'ওষুধ মুছুন';

  @override
  String get medDeleteBody => 'এই ওষুধ ও এর সব ডোজ মুছে ফেলবেন?';

  @override
  String get medSectionCourse => 'এই কোর্স';

  @override
  String get medSectionDoseHistory => 'ডোজের ইতিহাস';

  @override
  String get medDosesTaken => 'যত ডোজ নেওয়া হয়েছে';

  @override
  String medDayOf(int day, int total) {
    final intl.NumberFormat dayNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String dayString = dayNumberFormat.format(day);
    final intl.NumberFormat totalNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String totalString = totalNumberFormat.format(total);

    return '$totalString দিনের $dayString নম্বর দিন';
  }

  @override
  String get medNoDoses => 'এখনো কোনো ডোজ রেকর্ড হয়নি।';

  @override
  String get medStatusOnCourse => 'কোর্স চলছে';

  @override
  String get medStatusFinished => 'কোর্স শেষ';

  @override
  String get medStatusNotStarted => 'এখনো শুরু হয়নি';

  @override
  String get medDoseTaken => 'নেওয়া হয়েছে';

  @override
  String get medDoseToCome => 'বাকি আছে';

  @override
  String get medDoseSkipped => 'বাদ দেওয়া';

  @override
  String get medDoseMissed => 'মিস হয়েছে';

  @override
  String get medType => 'ধরন';

  @override
  String get medTiming => 'সময়';

  @override
  String get medStarted => 'শুরু';

  @override
  String get medEnds => 'শেষ';

  @override
  String get medNotes => 'নোট';

  @override
  String medTimesADay(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'দিনে $countString বার';
  }

  @override
  String get medNotFound => 'ওষুধটি পাওয়া যায়নি';

  @override
  String get medUnexpectedError => 'অপ্রত্যাশিত সমস্যা হয়েছে';

  @override
  String get studyTitle => 'পড়ার টাইমার';

  @override
  String get studySettings => 'টাইমারের সেটিংস';

  @override
  String get studyYourPlan => 'আপনার পরিকল্পনা';

  @override
  String get studyReady => 'শুরু করতে প্রস্তুত';

  @override
  String get studyStart => 'পড়া শুরু করুন';

  @override
  String get studyResume => 'চালিয়ে যান';

  @override
  String get studyKeepGoing => 'চালিয়ে যান';

  @override
  String get studyPaused => 'বিরতি দেওয়া';

  @override
  String get studyFocused => 'মনোযোগে';

  @override
  String get studyFocusBlock => 'পড়ার ধাপ';

  @override
  String get studyShortBreak => 'ছোট বিরতি';

  @override
  String get studyLongBreak => 'লম্বা বিরতি';

  @override
  String get studyBlocks => 'ধাপ';

  @override
  String get studyBlocksBeforeLong => 'লম্বা বিরতির আগে কয় ধাপ';

  @override
  String get studyAdjust => 'পরিবর্তন করুন';

  @override
  String get studyEndSession => 'সেশন শেষ করুন';

  @override
  String get studyEndSessionTitle => 'এই সেশন শেষ করবেন?';

  @override
  String get studyAlarmNote =>
      'প্রতিটি ধাপ ও বিরতির জন্য অ্যালার্ম দেওয়া আছে, তাই ফোন রেখে দিতে পারেন।';

  @override
  String get studyRunningNote =>
      'একটি সেশন চলছে — পরেরবার শুরু করলে এগুলো কার্যকর হবে।';

  @override
  String studyThenNext(String phase) {
    return 'এরপর $phase';
  }

  @override
  String studyMinutesToStart(int minutes) {
    final intl.NumberFormat minutesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String minutesString = minutesNumberFormat.format(minutes);

    return '$minutesString মিনিট দিয়ে শুরু';
  }

  @override
  String get expTitle => 'খরচের হিসাব';

  @override
  String get expLoading => 'আপনার খরচ লোড হচ্ছে…';

  @override
  String get expShoppingLists => 'কেনাকাটার তালিকা';

  @override
  String get expNewList => 'নতুন তালিকা';

  @override
  String get expNewShoppingList => 'নতুন কেনাকাটার তালিকা';

  @override
  String get expEditList => 'তালিকা সম্পাদনা';

  @override
  String get expCreateList => 'একটি তালিকা তৈরি করুন';

  @override
  String get expStartFirstList => 'প্রথম তালিকাটি শুরু করুন';

  @override
  String get expListName => 'তালিকার নাম';

  @override
  String get expGiveListName => 'তালিকাটির একটি নাম দিন';

  @override
  String get expListTotal => 'তালিকার মোট';

  @override
  String get expListSaved => 'তালিকা সংরক্ষিত হয়েছে';

  @override
  String get expListUpdated => 'তালিকা হালনাগাদ হয়েছে';

  @override
  String get expDeleteListTitle => 'এই তালিকাটি মুছবেন?';

  @override
  String get expAddItem => 'একটি জিনিস যোগ করুন';

  @override
  String get expItemName => 'জিনিসের নাম';

  @override
  String get expUntitledItem => 'নামহীন জিনিস';

  @override
  String get expEditingItem => 'জিনিস সম্পাদনা';

  @override
  String get expRemoveItem => 'জিনিসটি সরান';

  @override
  String get expNeedOneItem => 'সংরক্ষণের আগে অন্তত একটি জিনিস যোগ করুন';

  @override
  String get expItemHelp => 'নাম লিখুন, দাম জানা থাকলে দিন, তারপর + চাপুন';

  @override
  String get expBought => 'কেনা হয়েছে';

  @override
  String get expNotBought => 'কেনা হয়নি';

  @override
  String get expAllBought => 'সব কেনা হয়েছে';

  @override
  String get expTapWhenBought => 'কেনা হলে চাপুন';

  @override
  String get expPlanned => 'পরিকল্পিত';

  @override
  String get expPurchased => 'কেনা হয়েছে';

  @override
  String get expSearchHint => 'তালিকা ও জিনিস খুঁজুন…';

  @override
  String get expSearchResults => 'খোঁজার ফলাফল';

  @override
  String get expNothingMatched => 'কিছু মেলেনি';

  @override
  String get expPickMonth => 'মাস বেছে নিন';

  @override
  String get expPreviousMonth => 'আগের মাস';

  @override
  String get expNextMonth => 'পরের মাস';

  @override
  String get expBudget => 'বাজেট';

  @override
  String get expMonthlyBudget => 'মাসিক বাজেট';

  @override
  String get expSetBudget => 'বাজেট নির্ধারণ';

  @override
  String get expEditBudget => 'বাজেট সম্পাদনা';

  @override
  String get expUpdateBudget => 'বাজেট হালনাগাদ';

  @override
  String get expNoBudgetSet => 'কোনো বাজেট দেওয়া নেই';

  @override
  String get expNoBudgetThisMonth => 'এই মাসের জন্য বাজেট দেওয়া নেই';

  @override
  String get expBudgetAmount => 'বাজেটের পরিমাণ';

  @override
  String get expEnterAmount => 'পরিমাণ লিখুন';

  @override
  String get expInvalidAmount => 'পরিমাণটি সঠিক নয়';

  @override
  String get expNeedAmount => 'বাজেটের পরিমাণ লিখুন';

  @override
  String get expNeedValidAmount => '০-এর বেশি একটি সঠিক পরিমাণ লিখুন';

  @override
  String get expCategoryBudgets => 'ধরনভিত্তিক বাজেট';

  @override
  String get expSelectCategory => 'ধরন বেছে নিন';

  @override
  String get expCategoryName => 'ধরনের নাম';

  @override
  String get expAddCustomCategory => 'নিজের ধরন যোগ করুন';

  @override
  String get expCreateCustomCategory => 'নিজের ধরন তৈরি করুন';

  @override
  String get expDeleteCategory => 'ধরন মুছুন';

  @override
  String get expCategoryExists => 'এই নামে একটি ধরন আগে থেকেই আছে';

  @override
  String get expCategoryOverBudget =>
      'ধরনভিত্তিক বাজেট মাসিক বাজেটের বেশি — কমিয়ে দিন।';

  @override
  String get expUnallocated => 'অবণ্টিত';

  @override
  String get expOnTrack => 'ঠিক পথে';

  @override
  String get expGoodProgress => 'ভালো এগোচ্ছে';

  @override
  String get expHalfway => 'অর্ধেক পথ';

  @override
  String get expSpendingCautiously => 'সাবধানে খরচ';

  @override
  String get expAlmostAtLimit => 'সীমার প্রায় কাছে';

  @override
  String get expOverBudget => 'বাজেট ছাড়িয়ে গেছে!';

  @override
  String get expBudgetExceeded => 'বাজেট ছাড়িয়ে গেছে';

  @override
  String get expBudgetMet => 'ঠিক বাজেটেই হয়েছে! দারুণ!';

  @override
  String get expNoteOptional => 'নোট (ঐচ্ছিক)';

  @override
  String get expRequired => 'আবশ্যক';

  @override
  String get expInvalid => 'সঠিক নয়';

  @override
  String get expCreate => 'তৈরি করুন';

  @override
  String get expUpdate => 'হালনাগাদ';

  @override
  String get expEndSession => 'শেষ করুন';

  @override
  String get medEmptyBody => 'প্রতিদিনের ডোজ হিসাব রাখতে প্রথম ওষুধটি যোগ করুন';

  @override
  String get remindersEmptyBodyLong =>
      'যা মাথায় রাখতে চান না তার জন্য দিন — একটি ফোন করা, একটি বিল দেওয়া, ময়লা বের করা।';

  @override
  String get studyEndSessionBody =>
      'কাউন্টডাউন থেমে যাবে এবং বাকি সব অ্যালার্ম বাতিল হবে।';

  @override
  String get expListsHelp =>
      'কী কিনবেন আর তার দাম লিখে রাখুন, কেনা হলে টিক দিন।';

  @override
  String get widgetLocationNote =>
      'আগে আপনার অবস্থান দিন — তাহলে এগুলোতে আপনার নিজের নামাজের সময় দেখাবে।';
}
