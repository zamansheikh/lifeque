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
}
